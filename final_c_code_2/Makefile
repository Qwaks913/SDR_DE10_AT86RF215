# Makefile to build example_spi_dma program

CC = gcc
CFLAGS = -std=c99 -Wall -I. -D_POSIX_C_SOURCE=200112L
LDFLAGS = -lrt

# Debug flags - uncomment to enable debug TXT logging
# CFLAGS += -DDEBUG_TXT=1

SOURCES = main.c spi.c dma.c config.c debug_txt.c
OBJECTS = $(SOURCES:.c=.o)
TARGET = example_spi_dma

.PHONY: all clean debug

all: $(TARGET)

debug: CFLAGS += -DEBUG_TXT=0
debug: $(TARGET)

$(TARGET): $(OBJECTS)
	$(CC) $(CFLAGS) -o $@ $(OBJECTS) $(LDFLAGS)

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(OBJECTS) $(TARGET)
