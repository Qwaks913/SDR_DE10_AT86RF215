#ifndef SPI_H
#define SPI_H

#include <stdint.h>

// SPI device path and parameters
#define SPI_DEV       "/dev/spidev0.0"
#define SPI_HZ        2000000
#define SPI_MODE_CFG  SPI_MODE_0
#define SPI_BPW       8

// Transceiver register addresses
#define R_RST      0x0005
#define R_PN       0x000D
#define R_VN       0x000E
#define R09_IRQS   0x0000
#define R09_STATE  0x0102
#define R_IQIFC1   0x000B
#define R09_CS     0x0104
#define R09_CCF0L  0x0105
#define R09_CCF0H  0x0106
#define R09_CNL    0x0107
#define R09_CNM    0x0108
#define R09_RXBWC  0x0109
#define R09_RXDFE  0x010A
#define R09_AGCC   0x010B
#define RF09_AGCS  0x010C      /* RF09 - AGC Status / Gain Control */
#define R09_CMD    0x0103

// Initialize SPI device, configure transceiver pins
void spi_init(void);
void spi_close(void);

// Reset and configure the RF transceiver via SPI
void transceiver_init(void);

// Basic SPI register access
int w8(uint16_t addr, uint8_t val);
uint8_t r8(uint16_t addr);

// Debug helper: dump IRQ and STATE registers
void dump_irq_state(const char *tag);

#endif // SPI_H
