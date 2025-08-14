#include "debug_txt.h"
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <sys/mman.h>

// Variables pour le mode trigger
#if DEBUG_TXT_MODE == DEBUG_MODE_TRIGGER
static int16_t pre_buffer_i[DEBUG_PRE_SAMPLES];
static int16_t pre_buffer_q[DEBUG_PRE_SAMPLES];
static size_t pre_buf_idx = 0;
static int pre_buf_full = 0;
static int triggered = 0;
static size_t post_remaining = 0;
#endif

static FILE *debug_file = NULL;

// Convert 14-bit two's complement to signed integer
static int16_t convert_14bit_2complement(uint16_t raw_value) {
    // Mask to 14 bits
    raw_value &= 0x3FFF;
    
    // Check if sign bit (bit 13) is set
    if (raw_value & 0x2000) {
        // Negative number: extend sign to 16 bits
        return (int16_t)(raw_value | 0xC000);
    } else {
        // Positive number
        return (int16_t)raw_value;
    }
}

void debug_txt_init(const char *filename) {
    if (!DEBUG_TXT) return;

    debug_file = fopen(filename, "w");
    if (!debug_file) {
        perror("Failed to open debug file");
        return;
    }

    // Write header
    fprintf(debug_file, "# IQ Data Debug Log\n");
    fprintf(debug_file, "# Format: I_value Q_value (decimal, signed 14-bit)\n");
    fprintf(debug_file, "# Each line represents one 32-bit word from DMA\n\n");

    printf("Debug TXT logging enabled, writing to: %s with trigger mode = %d\n", filename,DEBUG_TXT_MODE);

    // Reset state trigger if needed
#if DEBUG_TXT_MODE == DEBUG_MODE_TRIGGER
    pre_buf_idx = 0;
    pre_buf_full = 0;
    triggered = 0;
    post_remaining = 0;
#endif
}

void debug_txt_log_iq_data(const volatile uint8_t *ddr_buf, size_t chunk_bytes) {
    if (!DEBUG_TXT || !debug_file) return;
    // Invalidate cache
    msync((void*)ddr_buf, chunk_bytes, MS_SYNC | MS_INVALIDATE);
    const uint32_t *data_words = (const uint32_t*)ddr_buf;
    size_t num_words = chunk_bytes / sizeof(uint32_t);

#if DEBUG_TXT_MODE == DEBUG_MODE_FULL
    // Mode full : on enregistre tous les échantillons
    for (size_t i = 0; i < num_words; i++) {
        uint32_t word = data_words[i];
        uint16_t q_raw = (uint16_t)(word & 0x3FFF);
        uint16_t i_raw = (uint16_t)((word >> 16) & 0x3FFF);
        int16_t i_value = convert_14bit_2complement(i_raw);
        int16_t q_value = convert_14bit_2complement(q_raw);
        fprintf(debug_file, "%d %d\n", i_value, q_value);
    }
    fflush(debug_file);

#elif DEBUG_TXT_MODE == DEBUG_MODE_TRIGGER
    // Mode trigger : buffer circulaire + détection
    for (size_t idx = 0; idx < num_words; idx++) {
        uint32_t word = data_words[idx];
        uint16_t q_raw = (uint16_t)(word & 0x3FFF);
        uint16_t i_raw = (uint16_t)((word >> 16) & 0x3FFF);
        int16_t i_value = convert_14bit_2complement(i_raw);
        int16_t q_value = convert_14bit_2complement(q_raw);
        // Mise à jour du buffer pré-trigger
        pre_buffer_i[pre_buf_idx] = i_value;
        pre_buffer_q[pre_buf_idx] = q_value;
        pre_buf_idx = (pre_buf_idx + 1) % DEBUG_PRE_SAMPLES;
        if (pre_buf_idx == 0) pre_buf_full = 1;
        // Détection du trigger
        if (!triggered) {
            if (abs(i_value) > DEBUG_TRIGGER_THRESHOLD || abs(q_value) > DEBUG_TRIGGER_THRESHOLD) {
                // On a déclenché
                triggered = 1;
                post_remaining = DEBUG_POST_SAMPLES;
                // Ecrire le buffer pré-trigger
                size_t start = pre_buf_full ? pre_buf_idx : 0;
                size_t count = pre_buf_full ? DEBUG_PRE_SAMPLES : pre_buf_idx;
                for (size_t j = 0; j < count; j++) {
                    size_t pos = (start + j) % DEBUG_PRE_SAMPLES;
                    fprintf(debug_file, "%d %d\n", pre_buffer_i[pos], pre_buffer_q[pos]);
                }
                // Ecrire l'échantillon courant
                fprintf(debug_file, "%d %d\n", i_value, q_value);
            }
        } else {
            // En mode post-trigger, on enregistre
            fprintf(debug_file, "%d %d\n", i_value, q_value);
            if (--post_remaining == 0) {
                // Fin du trigger
                triggered = 0;
            }
        }
    }
    fflush(debug_file);
#else
    // Aucun mode
#endif
}

void debug_txt_close(void) {
    if (!DEBUG_TXT) return;
    
    if (debug_file) {
        fclose(debug_file);
        debug_file = NULL;
        printf("Debug TXT logging closed\n");
    }
}
