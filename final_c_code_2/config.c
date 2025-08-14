#include "config.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

uint32_t config_chunk_bytes = DEFAULT_CHUNK_BYTES;
uint8_t cfg_IQIFC1 = 0x42;
uint8_t cfg_CS     = 0x08;
uint8_t cfg_CCF0L  = 0xA0;
uint8_t cfg_CCF0H  = 0x87;
uint8_t cfg_CNL    = 0x00;
uint8_t cfg_CNM    = 0x00;
uint8_t cfg_RXBWC  = 0x18;
uint8_t cfg_RXDFE  = 0x83;
uint8_t cfg_R09_AGCC = 0x11;  // AGC Control: EN=1, AVGS=1 (16 samples), other bits=0
uint8_t cfg_RF09_AGCS = 0x60;  // AGC Status/Target: TGT=3 (-30 dBFS), GCW=0

// Helper to trim whitespace
static void trim(char *s) {
    char *p = s;
    while (*p == ' ' || *p == '\t' || *p == '\n' || *p == '\r') p++;
    if (p != s) memmove(s, p, strlen(p) + 1);
    size_t len = strlen(s);
    while (len > 0 && (s[len-1] == ' ' || s[len-1] == '\t' || s[len-1] == '\n' || s[len-1] == '\r')) {
        s[len-1] = '\0'; len--;
    }
}

void config_load(const char *filename) {
    FILE *f = fopen(filename, "r");
    if (f) {
        char line[128];
        while (fgets(line, sizeof(line), f)) {
            trim(line);
            if (line[0] == '#' || line[0] == '\0') continue;
            char *eq = strchr(line, '=');
            if (!eq) continue;
            *eq = '\0';
            char *key = line;
            char *valstr = eq + 1;
            trim(key);
            trim(valstr);
            if (strcmp(key, "chunk_bytes") == 0) {
                config_chunk_bytes = (uint32_t)atoi(valstr);
            } else {
                unsigned int val = (unsigned int)strtoul(valstr, NULL, 0);
                if (strcmp(key, "IQIFC1") == 0)      cfg_IQIFC1 = (uint8_t)val;
                else if (strcmp(key, "CS") == 0)      cfg_CS     = (uint8_t)val;
                else if (strcmp(key, "CCF0L") == 0)   cfg_CCF0L  = (uint8_t)val;
                else if (strcmp(key, "CCF0H") == 0)   cfg_CCF0H  = (uint8_t)val;
                else if (strcmp(key, "CNL") == 0)     cfg_CNL    = (uint8_t)val;
                else if (strcmp(key, "CNM") == 0)     cfg_CNM    = (uint8_t)val;
                else if (strcmp(key, "RXBWC") == 0)   cfg_RXBWC  = (uint8_t)val;
                else if (strcmp(key, "RXDFE") == 0)   cfg_RXDFE  = (uint8_t)val;
                else if (strcmp(key, "R09_AGCC") == 0) cfg_R09_AGCC = (uint8_t)val;
                else if (strcmp(key, "RF09_AGCS") == 0) cfg_RF09_AGCS = (uint8_t)val;
            }
        }
        fclose(f);
    } else {
        fprintf(stderr, "Config file '%s' not found, using defaults\n", filename);
    }
    // Always show effective configuration values
    fprintf(stderr,
            "Effective config: chunk_bytes=%u, IQIFC1=0x%02X, CS=0x%02X, CCF0L=0x%02X, CCF0H=0x%02X, CNL=0x%02X, CNM=0x%02X, RXBWC=0x%02X, RXDFE=0x%02X, R09_AGCC=0x%02X, RF09_AGCS=0x%02X\n",
            config_chunk_bytes, cfg_IQIFC1, cfg_CS, cfg_CCF0L, cfg_CCF0H,
            cfg_CNL, cfg_CNM, cfg_RXBWC, cfg_RXDFE, cfg_R09_AGCC, cfg_RF09_AGCS);
}
