#include <stdint.h>
#include <stddef.h>

#define CONFIG_FILE "config.txt"
#define DEFAULT_CHUNK_BYTES (16384/2)

// Configuration values loaded from external file
extern uint32_t config_chunk_bytes;
extern uint8_t cfg_IQIFC1;
extern uint8_t cfg_CS;
extern uint8_t cfg_CCF0L;
extern uint8_t cfg_CCF0H;
extern uint8_t cfg_CNL;
extern uint8_t cfg_CNM;
extern uint8_t cfg_RXBWC;
extern uint8_t cfg_RXDFE;
extern uint8_t cfg_R09_AGCC;  // AGC Control register
extern uint8_t cfg_RF09_AGCS; // AGC Status/Target register

// Load configuration (chunk_bytes and register values) from file
void config_load(const char *filename);