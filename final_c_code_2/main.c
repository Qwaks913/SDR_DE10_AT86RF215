#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <unistd.h>

#include "spi.h"
#include "dma.h"
#include "config.h"

// Add handler to reset transceiver and clean up resources on exit
static void sigint_handler(int signo) {
    fprintf(stderr, "\nCaught signal %d, resetting transceiver and cleaning up...\n", signo);
    // Reset transceiver (full device reset)
    w8(R_RST, 0x07);
    usleep(2000);
    // Clean up DMA and SPI
    dma_close();
    spi_close();
    exit(EXIT_SUCCESS);
}

int main(int argc, char *argv[]) {
    // Load external configuration (registers and chunk_bytes)
    config_load(CONFIG_FILE);
    // Register handler for clean shutdown
    signal(SIGINT, sigint_handler);
    signal(SIGTERM, sigint_handler);
    int udp_mode = 0;
    const char *udp_ip = NULL;
    uint16_t udp_port = 0;
    // Usage: ./example_spi_dma test | udp [ip] [port]
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <test|udp> [ip] [port]\n", argv[0]);
        return EXIT_FAILURE;
    }
    if (strcmp(argv[1], "test") == 0) {
        udp_mode = 0;
    } else if (strcmp(argv[1], "udp") == 0) {
        udp_mode = 1;
        // optional IP and port
        if (argc >= 3) udp_ip = argv[2];
        if (argc >= 4) udp_port = (uint16_t)atoi(argv[3]);
    } else {
        fprintf(stderr, "Invalid mode '%s', choose 'test' or 'udp'\n", argv[1]);
        return EXIT_FAILURE;
    }
    // Initialize SPI and transceiver
    spi_init();
    transceiver_init();

    // Initialize DMA and start infinite transfer loop
    dma_init(udp_mode, udp_ip, udp_port);
    dma_loop(udp_mode);

    // Cleanup (never reached if dma_loop is infinite)
    dma_close();
    spi_close();

    return EXIT_SUCCESS;
}
