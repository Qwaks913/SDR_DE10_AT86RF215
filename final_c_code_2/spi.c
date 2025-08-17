#define _POSIX_C_SOURCE 200112L
#include "spi.h"
#include "config.h"
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <linux/spi/spidev.h>

// SPI device parameters
#define SPI_HZ        2000000
#define SPI_MODE_CFG  SPI_MODE_0
#define SPI_BPW       8

static int spi_fd = -1;

// Low-level SPI transfer
static int spi_transfer(const void *tx, void *rx, size_t n) {
    struct spi_ioc_transfer tr = {
        .tx_buf = (uintptr_t)tx,
        .rx_buf = (uintptr_t)rx,
        .len = n,
        .speed_hz = SPI_HZ,
        .bits_per_word = SPI_BPW
    };
    return ioctl(spi_fd, SPI_IOC_MESSAGE(1), &tr);
}

// Write 8-bit register
int w8(uint16_t addr, uint8_t val) {
    uint8_t tx[3] = { (uint8_t)(0x80 | ((addr >> 8) & 0x3F)), (uint8_t)(addr & 0xFF), val };
    return spi_transfer(tx, NULL, 3);
}

// Read 8-bit register
uint8_t r8(uint16_t addr) {
    uint8_t tx[3] = { (uint8_t)((addr >> 8) & 0x3F), (uint8_t)(addr & 0xFF), 0 };
    uint8_t rx[3] = {0};
    spi_transfer(tx, rx, 3);
    return rx[2];
}

void spi_init(void) {
    uint32_t speed = SPI_HZ;
    uint8_t mode = SPI_MODE_CFG;
    uint8_t bpw = SPI_BPW;

    spi_fd = open(SPI_DEV, O_RDWR);
    if (spi_fd < 0) {
        perror("open SPI device");
        exit(EXIT_FAILURE);
    }
    ioctl(spi_fd, SPI_IOC_WR_MODE, &mode);
    ioctl(spi_fd, SPI_IOC_WR_BITS_PER_WORD, &bpw);
    ioctl(spi_fd, SPI_IOC_WR_MAX_SPEED_HZ, &speed);
}

void spi_close(void) {
    if (spi_fd >= 0) {
        close(spi_fd);
        spi_fd = -1;
    }
}

void transceiver_init(void) {
    // Read PN/VN
    uint8_t pn = r8(R_PN);
    uint8_t vn = r8(R_VN);
    printf("Transceiver PN/VN = 0x%02X / 0x%02X\n", pn, vn);

    // Full device reset
    w8(R_RST, 0x07);
    usleep(2000);
    // Dump IRQ and state after reset
    dump_irq_state("After RESET");

    // Ensure CMV bit set in IQIFC0 (preserve other bits)
    uint8_t iqifc0 = r8(R_IQIFC0);
    if (!(iqifc0 & IQIFC0_CMV)) {
        iqifc0 |= IQIFC0_CMV;
        w8(R_IQIFC0, iqifc0);
    }

    // Minimal configuration chain
    w8(R_IQIFC1, cfg_IQIFC1);
    w8(R09_CS,    cfg_CS);
    w8(R09_CCF0L, cfg_CCF0L); w8(R09_CCF0H, cfg_CCF0H);
    w8(R09_CNL,   cfg_CNL); w8(R09_CNM,   cfg_CNM);
    w8(R09_RXBWC, cfg_RXBWC); w8(R09_RXDFE, cfg_RXDFE);
    
    // Configure AGC control and status registers
    w8(R09_AGCC, cfg_R09_AGCC);
    w8(RF09_AGCS, cfg_RF09_AGCS);
    
    if (cfg_R09_AGCC & 0x01) {
        printf("AGC enabled with target level: %d (-21 to -42 dBFS)\n", (cfg_RF09_AGCS >> 5) & 0x07);
    } else {
        printf("AGC disabled, manual gain set to: %d (0-23, 3dB steps)\n", cfg_RF09_AGCS & 0x1F);
    }
    

    // TXPREP then RX
    w8(R09_CMD, 0x03); usleep(1000);
    dump_irq_state("After TXPREP");
    w8(R09_CMD, 0x05); usleep(1000);
    dump_irq_state("After RX");
}

// Debug helper: dump IRQs and state registers
void dump_irq_state(const char *tag) {
    uint8_t irqs = r8(R09_IRQS);
    uint8_t st   = r8(R09_STATE);
    uint8_t rxdfe = r8(R09_RXDFE);
    printf("%s  IRQ=0x%02X  STATE=0x%02X (bits2-0=%u)\n",
           tag, irqs, st, st & 7);
    printf("RXDFE register: 0x%02X\n", rxdfe);
}
