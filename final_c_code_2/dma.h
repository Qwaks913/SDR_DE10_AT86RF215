#ifndef DMA_H
#define DMA_H

#include <stdint.h>

// Initialize DMA registers and map DDR buffer; udp_mode: 0=test, 1=UDP; udp_ip: destination IP; udp_port: destination port
void dma_init(int udp_mode, const char *udp_ip, uint16_t udp_port);

// Start infinite DMA loop: program descriptor, poll, read response, print or send via UDP
void dma_loop(int udp_mode);

// Cleanup DMA resources
void dma_close(void);

// Print first 16 samples from DDR buffer
void print_data(void);

#endif // DMA_H
