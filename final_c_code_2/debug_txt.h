#ifndef DEBUG_TXT_H
#define DEBUG_TXT_H

#include <stdint.h>
#include <stddef.h>

// Enable/disable debug text logging
#ifndef DEBUG_TXT
#define DEBUG_TXT 0
#endif

// Modes de logging
#define DEBUG_MODE_FULL    0  // capture tous les échantillons
#define DEBUG_MODE_TRIGGER 1  // capture autour d'un trigger

#ifndef DEBUG_TXT_MODE
#define DEBUG_TXT_MODE DEBUG_MODE_TRIGGER
#endif

// Seuil et tailles pour le mode trigger
#define DEBUG_TRIGGER_THRESHOLD 100    // valeur absolue seuil pour I ou Q
#define DEBUG_PRE_SAMPLES       1000  // nombre d'échantillons avant trigger
#define DEBUG_POST_SAMPLES      1000  // nombre d'échantillons après trigger

// Initialize debug text logging (opens/creates file)
void debug_txt_init(const char *filename);

// Log IQ data from DDR buffer to text file
void debug_txt_log_iq_data(const volatile uint8_t *ddr_buf, size_t chunk_bytes);

// Close debug text file
void debug_txt_close(void);

#endif // DEBUG_TXT_H
