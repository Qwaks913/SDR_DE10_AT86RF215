#define _POSIX_C_SOURCE 200112L
#include "dma.h"
#include "debug_txt.h"
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <stdint.h>
#include <string.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <time.h>
#include "config.h"    // pour config_chunk_bytes

// --- DMA definitions ---
#define DEV_MEM "/dev/mem"
#define PAGE_SIZE   4096UL
#define PAGE_MASK   (~(PAGE_SIZE - 1))
#define ALT_LWFPGASLVS_OFST   0xFF200000UL
#define DMA_REGS_BASE_PHYS    (ALT_LWFPGASLVS_OFST & PAGE_MASK)
#define DMA_REGS_SPAN         PAGE_SIZE
#define DMA_CSR_CONTROL_OFFSET      0x04  // Control register (reset)
#define DMA_CSR_STATUS_OFFSET       0x00  // Status register (busy bit)
#define DMA_CSR_RESPONSE_OFFSET     0x40
#define DMA_DESC_BASE_OFFSET        0x20
#define DMA_DESC_WRITE_ADDR_OFFSET  (DMA_DESC_BASE_OFFSET + 0x04)
#define DMA_DESC_LENGTH_OFFSET      (DMA_DESC_BASE_OFFSET + 0x08)
#define DMA_DESC_CONTROL_OFFSET     (DMA_DESC_BASE_OFFSET + 0x0C)
#define DDR_BUFFER_BASE    0x01000000UL
#define DDR_MAP_SIZE       0x01000000UL
#define CHUNK_BYTES        16384/2

#define DEFAULT_UDP_IP   "10.42.0.1"   // default PC address to receive UDP data
#define DEFAULT_UDP_PORT 5000

// Enable verbose debug printing when VERBOSE=1 at compile time
#ifndef VERBOSE
#define VERBOSE 0
#endif
#define DPRINT(fmt, ...) do { if (VERBOSE) printf(fmt, ##__VA_ARGS__); } while (0)

static int dma_fd = -1;
static volatile uint8_t *dma_regs = NULL;
static volatile uint8_t *ddr_buf = NULL;
static int udp_mode_global = 0;
static int udp_socket_fd = -1;
static char udp_ip_global[INET_ADDRSTRLEN] = DEFAULT_UDP_IP;
static uint16_t udp_port_global = DEFAULT_UDP_PORT;
static struct sockaddr_in udp_dest;

// Variables pour le compteur d'échantillons par seconde
static uint64_t samples_sent_total = 0;
static uint64_t samples_sent_last_second = 0;
static struct timespec last_print_time;

static inline void small_delay(void) {
    for (volatile int i = 0; i < 100; ++i) __asm__ volatile ("nop");
}

// Fonction pour vérifier et afficher le débit d'échantillons
static void check_and_print_sample_rate(size_t samples_in_buffer) {
    struct timespec current_time;
    if (clock_gettime(CLOCK_MONOTONIC, &current_time) != 0) {
        return; // En cas d'erreur, on continue sans afficher
    }
    
    // Calculer le temps écoulé en secondes
    double elapsed = (current_time.tv_sec - last_print_time.tv_sec) + 
                    (current_time.tv_nsec - last_print_time.tv_nsec) / 1e9;
    
    // Compter les échantillons (chaque échantillon I/Q = 4 bytes pour 2x16 bits)
    uint64_t samples_count = samples_in_buffer / 4;
    samples_sent_total += samples_count;
    samples_sent_last_second += samples_count;
    
    // Afficher le débit chaque seconde
    if (elapsed >= 1.0) {
        printf("Échantillons/sec: %llu (Total: %llu)\n", 
               (unsigned long long)samples_sent_last_second, (unsigned long long)samples_sent_total);
        samples_sent_last_second = 0;
        last_print_time = current_time;
    }
}

void dma_init(int udp_mode, const char *udp_ip, uint16_t udp_port) {
    dma_fd = open(DEV_MEM, O_RDWR | O_SYNC);
    if (dma_fd < 0) {
        perror("open /dev/mem");
        exit(EXIT_FAILURE);
    }
    dma_regs = mmap(NULL, DMA_REGS_SPAN, PROT_READ|PROT_WRITE,
                    MAP_SHARED, dma_fd, DMA_REGS_BASE_PHYS);
    if (dma_regs == MAP_FAILED) {
        perror("mmap dma_regs");
        exit(EXIT_FAILURE);
    }
    ddr_buf = mmap(NULL, DDR_MAP_SIZE, PROT_READ|PROT_WRITE,
                   MAP_SHARED, dma_fd, DDR_BUFFER_BASE);
    if (ddr_buf == MAP_FAILED) {
        perror("mmap ddr_buf");
        exit(EXIT_FAILURE);
    }
    /* Setup UDP socket if in udp mode */
    udp_mode_global = udp_mode;
    if (udp_mode_global) {
        /* set destination IP and port */
        if (udp_ip) strncpy(udp_ip_global, udp_ip, INET_ADDRSTRLEN);
        // only override default if a non-zero port was provided
        if (udp_port != 0) udp_port_global = udp_port;
        udp_socket_fd = socket(AF_INET, SOCK_DGRAM, 0);
        if (udp_socket_fd < 0) {
            perror("socket"); exit(EXIT_FAILURE);
        }
        memset(&udp_dest, 0, sizeof(udp_dest));
        udp_dest.sin_family = AF_INET;
        udp_dest.sin_port = htons(udp_port_global);
        if (inet_aton(udp_ip_global, &udp_dest.sin_addr) == 0) {
            fprintf(stderr, "Invalid UDP IP address: %s\n", udp_ip_global);
            exit(EXIT_FAILURE);
        }
    }
    // Reset DMA
    *(uint32_t*)(dma_regs + DMA_CSR_CONTROL_OFFSET) = 0x02;
    small_delay();
    *(uint32_t*)(dma_regs + DMA_CSR_CONTROL_OFFSET) = 0x00;
    small_delay();

    // Initialise le logging DEBUG TXT si activé
    debug_txt_init("iq_debug.txt");
}

void dma_loop(int udp_mode) {
    static uint64_t seq_counter = 0;
    size_t buf_size = config_chunk_bytes;
    uintptr_t buf_addr[2] = { DDR_BUFFER_BASE, DDR_BUFFER_BASE + buf_size };
    uint8_t *buf_ptr[2] = { (uint8_t*)ddr_buf, (uint8_t*)(ddr_buf + buf_size) };
    int current = 0, next = 1;
    
    // Initialiser le timer pour le compteur d'échantillons
    if (udp_mode && clock_gettime(CLOCK_MONOTONIC, &last_print_time) != 0) {
        perror("clock_gettime");
    }
    samples_sent_total = 0;
    samples_sent_last_second = 0;

    // Pré-remplissage du buffer courant
    DPRINT("Pre-filling buffer %d\n", current);
    *(uint32_t*)(dma_regs + DMA_DESC_WRITE_ADDR_OFFSET) = buf_addr[current];
    *(uint32_t*)(dma_regs + DMA_DESC_LENGTH_OFFSET) = buf_size;
    small_delay();
    *(uint32_t*)(dma_regs + DMA_DESC_CONTROL_OFFSET) = 0x80000000;
    // Attendre la fin de la première DMA
    uint32_t status = *(uint32_t*)(dma_regs + DMA_CSR_STATUS_OFFSET);
    while (status & 0x01) {
        status = *(uint32_t*)(dma_regs + DMA_CSR_STATUS_OFFSET);
        small_delay();
    }
    // Vider registres response pour autoriser le prochain transfert
    (void)*(volatile uint32_t*)(dma_regs + DMA_CSR_RESPONSE_OFFSET);
    (void)*(volatile uint32_t*)(dma_regs + DMA_CSR_RESPONSE_OFFSET + 4);

    // Boucle principale ping-pong
    while (1) {
        // Lancer la DMA sur le buffer 'next'
        DPRINT("Programming buffer %d for DMA\n", next);
        *(uint32_t*)(dma_regs + DMA_DESC_WRITE_ADDR_OFFSET) = buf_addr[next];
        *(uint32_t*)(dma_regs + DMA_DESC_LENGTH_OFFSET) = buf_size;
        small_delay();
        *(uint32_t*)(dma_regs + DMA_DESC_CONTROL_OFFSET) = 0x80000000;

        // Traitement du buffer 'current'
        debug_txt_log_iq_data(buf_ptr[current], buf_size);
        if (udp_mode_global) {
            // Conversion en big-endian et envoi
            uint32_t *in_words = (uint32_t*)buf_ptr[current];
            size_t num_words = buf_size / sizeof(uint32_t);
            uint32_t out_words[num_words];
            for (size_t wi = 0; wi < num_words; ++wi) {
                out_words[wi] = htonl(in_words[wi]);
            }
            uint32_t seq_hi = (uint32_t)(seq_counter >> 32);
            uint32_t seq_lo = (uint32_t)(seq_counter & 0xFFFFFFFFU);
            seq_counter++;
            uint32_t net_hi = htonl(seq_hi);
            uint32_t net_lo = htonl(seq_lo);
            size_t pkt_size = 8 + buf_size;
            uint8_t pkt[pkt_size];
            memcpy(pkt, &net_hi, 4);
            memcpy(pkt + 4, &net_lo, 4);
            memcpy(pkt + 8, out_words, buf_size);
            ssize_t sent = sendto(udp_socket_fd, pkt, pkt_size, 0,
                                  (struct sockaddr*)&udp_dest, sizeof(udp_dest));
            if (sent < 0) perror("sendto");
            else {
                // Compter les échantillons envoyés et afficher le débit
                check_and_print_sample_rate(buf_size);
            }
        } else {
            print_data();  // affiche depuis le début du DDR (buffer 0)
        }

        // Attendre la fin de la DMA sur 'next'
        status = *(uint32_t*)(dma_regs + DMA_CSR_STATUS_OFFSET);
        while (status & 0x01) {
            status = *(uint32_t*)(dma_regs + DMA_CSR_STATUS_OFFSET);
            small_delay();
        }
        // Vider registres response pour autoriser le prochain transfert
        (void)*(volatile uint32_t*)(dma_regs + DMA_CSR_RESPONSE_OFFSET);
        (void)*(volatile uint32_t*)(dma_regs + DMA_CSR_RESPONSE_OFFSET + 4);

        // basculement des indices ping-pong
        current ^= 1;
        next ^= 1;
    }
}

// Invalidate cache and print first 16 samples as two 32-bit words in binary
void print_data(void) {
    uint64_t *data = (uint64_t*)ddr_buf;
    printf("First 16 samples (each word: low=first IQ, high=second IQ):\n");
    for (int i = 0; i < 16; ++i) {
        uint32_t low  = (uint32_t)(data[i] & 0xFFFFFFFF);
        uint32_t high = (uint32_t)(data[i] >> 32);
        char binlow[33], binhigh[33];
        for (int b = 0; b < 32; ++b) {
            binlow[b]  = (low  & (1u << (31 - b))) ? '1' : '0';
            binhigh[b] = (high & (1u << (31 - b))) ? '1' : '0';
        }
        binlow[32] = '\0'; binhigh[32] = '\0';
        printf(" data[%2d] low  = 0b%s\n", i, binlow);
        printf(" data[%2d] high = 0b%s\n", i, binhigh);
    }
}

void dma_close(void) {
    if (ddr_buf) munmap((void*)ddr_buf, DDR_MAP_SIZE);
    if (dma_regs) munmap((void*)dma_regs, DMA_REGS_SPAN);
    if (dma_fd >= 0) close(dma_fd);
    if (udp_mode_global && udp_socket_fd >= 0) close(udp_socket_fd);

    // Ferme le fichier de debug si activé
    debug_txt_close();
}
