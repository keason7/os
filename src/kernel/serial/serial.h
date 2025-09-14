#ifndef SERIAL_H
#define SERIAL_H

#include <stdint.h>

/**
 * @brief Write a byte to an I/O port.
 * This function writes the 8-bit value val to the I/O port specified by port.
 * It is commonly used for hardware communication (VGA, keyboard, ...).
 *
 * @param port The 16-bit port address to write to.
 * @param val  The 8-bit value to write.
 */
void outb(uint16_t port, uint8_t val);

/**
 * @brief Read a byte to an I/O port.
 * This function read the 8-bit value from the I/O port specified by port.
 * It is commonly used for hardware communication (VGA, keyboard, ...).
 *
 * @param port The 16-bit port address to read from.
 * @return The byte read from the port (8-bit).
 */
uint8_t inb(uint16_t port);

#endif
