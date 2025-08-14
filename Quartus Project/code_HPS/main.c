#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <errno.h>

#define DEV_MEM "/dev/mem"
// Page size for mmap alignment
#define PAGE_SIZE 4096UL
#define PAGE_MASK (~(PAGE_SIZE - 1))

// Base of lightweight HPS-to-FPGA bridge
#define ALT_LWFPGASLVS_OFST 0xFF200000UL

// Map a page covering CSR and descriptor registers
#define DMA_REGS_BASE_PHYS (ALT_LWFPGASLVS_OFST & PAGE_MASK)
#define DMA_REGS_SPAN      PAGE_SIZE

// Offsets within this mapped region
#define DMA_CSR_CONTROL_OFFSET     0x00  // CSR control register (reset, GO bits)
#define DMA_CSR_STATUS_OFFSET      0x04  // CSR status register (busy bit)
#define DMA_DESC_WRITE_ADDR_OFFSET 0x24  // Descriptor: write addr (destination)
#define DMA_DESC_LENGTH_OFFSET     0x28  // Descriptor: transfer length in bytes
#define DMA_DESC_CONTROL_OFFSET    0x2C  // Descriptor: control register (GO)

// DDR buffer parameters
#define DDR_BUFFER_BASE 0x01000000UL   // Physical base address in DDR
#define DDR_MAP_SIZE    0x01000000UL   // 16 MiB mapping size

// DMA transfer parameters
#define TOTAL_TRANSFER_BYTES  (1024)  // Desired total transfer: 8 KiB
#define MAX_DMA_BYTES         1024        // IP-limited max per descriptor

int main() {
    int fd;
    volatile uint8_t *dma_regs;
    volatile uint8_t *ddr_buf;
    uint32_t status;
    size_t transferred = 0;
    int chunk_idx = 0;

    printf("[DEBUG] Opening %s...\n", DEV_MEM);
    fd = open(DEV_MEM, O_RDWR | O_SYNC);
    if (fd < 0) {
        perror("[ERROR] open /dev/mem");
        return EXIT_FAILURE;
    }

    // Map DMA registers
    printf("[DEBUG] Mapping DMA regs at phys 0x%08lX...\n", DMA_REGS_BASE_PHYS);
    dma_regs = mmap(NULL, DMA_REGS_SPAN,
                    PROT_READ | PROT_WRITE,
                    MAP_SHARED, fd, DMA_REGS_BASE_PHYS);
    if (dma_regs == MAP_FAILED) {
        perror("[ERROR] mmap dma_regs");
        close(fd);
        return EXIT_FAILURE;
    }
    printf("[DEBUG] DMA regs mapped to %p\n", (void*)dma_regs);

    // Map DDR buffer
    printf("[DEBUG] Mapping DDR buffer at phys 0x%08lX...\n", DDR_BUFFER_BASE);
    ddr_buf = mmap(NULL, DDR_MAP_SIZE,
                   PROT_READ | PROT_WRITE,
                   MAP_SHARED, fd, DDR_BUFFER_BASE);
    if (ddr_buf == MAP_FAILED) {
        perror("[ERROR] mmap ddr_buf");
        munmap((void*)dma_regs, DMA_REGS_SPAN);
        close(fd);
        return EXIT_FAILURE;
    }
    printf("[DEBUG] DDR buffer mapped to %p\n", (void*)ddr_buf);

    // Ensure DMA is idle
    status = *((volatile uint32_t*)(dma_regs + DMA_CSR_STATUS_OFFSET));
    printf("[DEBUG] Initial DMA STATUS = 0x%08X\n", status);
    if (status & 0x01) {
        printf("[DEBUG] DMA busy, issuing reset...\n");
        *((volatile uint32_t*)(dma_regs + DMA_CSR_CONTROL_OFFSET)) = 0x02;
        for (int t = 0; t < 1000; ++t) {
            status = *((volatile uint32_t*)(dma_regs + DMA_CSR_CONTROL_OFFSET));
            if (!(status & 0x02)) break;
            usleep(100);
        }
        printf("[DEBUG] Reset complete, CONTROL = 0x%08X\n",
               *((volatile uint32_t*)(dma_regs + DMA_CSR_CONTROL_OFFSET)));
    } else {
        printf("[DEBUG] DMA idle, no reset\n");
    }

    // Chunked transfer
    while (transferred < TOTAL_TRANSFER_BYTES) {
        size_t remaining = TOTAL_TRANSFER_BYTES - transferred;
        uint32_t length = remaining > MAX_DMA_BYTES ? MAX_DMA_BYTES : remaining;
        uint32_t dest_addr = DDR_BUFFER_BASE + transferred;

        printf("[DEBUG] Chunk %d: DST=0x%08X LEN=%u\n", chunk_idx, dest_addr, length);
        // Write descriptor
        *((volatile uint32_t*)(dma_regs + DMA_DESC_WRITE_ADDR_OFFSET)) = dest_addr;
        *((volatile uint32_t*)(dma_regs + DMA_DESC_LENGTH_OFFSET))     = length;
        // Read back descriptor settings
        uint32_t rd_addr = *((volatile uint32_t*)(dma_regs + DMA_DESC_WRITE_ADDR_OFFSET));
        uint32_t rd_len  = *((volatile uint32_t*)(dma_regs + DMA_DESC_LENGTH_OFFSET));
        printf("[DEBUG] Readback DESC_WRITE_ADDR=0x%08X LEN=%u\n", rd_addr, rd_len);

        // Launch DMA for this chunk
        printf("[DEBUG] Launching DMA (GO)...\n");
        *((volatile uint32_t*)(dma_regs + DMA_DESC_CONTROL_OFFSET))    = 0x01;
        uint32_t rd_ctrl = *((volatile uint32_t*)(dma_regs + DMA_DESC_CONTROL_OFFSET));
        printf("[DEBUG] Readback DESC_CONTROL=0x%08X\n", rd_ctrl);

        // Poll until done
        printf("[DEBUG] Polling DMA status...\n");
        uint64_t poll_cnt = 0;
        do {
            status = *((volatile uint32_t*)(dma_regs + DMA_CSR_STATUS_OFFSET));
            if ((poll_cnt % 500000) == 0)
                printf("[DEBUG] POLL %lu: STATUS=0x%08X\n", poll_cnt, status);
            poll_cnt++;
        } while (status & 0x01);
        printf("[DEBUG] Chunk %d complete after %lu polls\n", chunk_idx, poll_cnt);

        transferred += length;
        chunk_idx++;
    }

    // Invalidate cache if needed
    printf("[DEBUG] Invalidating cache for buffer...\n");
    msync((void*)ddr_buf, TOTAL_TRANSFER_BYTES, MS_SYNC | MS_INVALIDATE);

    // Print first 16 samples
    printf("[DEBUG] First 16 samples:\n");
    uint64_t *data = (uint64_t*)ddr_buf;
    for (int i = 0; i < 16; ++i) {
        printf(" data[%2d] = 0x%016lX\n", i, data[i]);
    }

    // Cleanup
    munmap((void*)ddr_buf, DDR_MAP_SIZE);
    munmap((void*)dma_regs, DMA_REGS_SPAN);
    close(fd);
    return EXIT_SUCCESS;
}
