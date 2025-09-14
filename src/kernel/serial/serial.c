#include "serial.h"

/**
 * @brief Write a byte to an I/O port.
 * This function writes the 8-bit value val to the I/O port specified by port.
 * It is commonly used for hardware communication (VGA, keyboard, ...).
 *
 * @param port The 16-bit port address to write to.
 * @param val  The 8-bit value to write.
 */
void outb(uint16_t port, uint8_t val) {
	/**
	 * __asm__ allows embedding assembly directly in C/C++
	 * volatile prevents the compiler from optimizing away or reordering this instruction
	 *
	 * Assembly instruction:
	 * "outb %b0, %w1": send a byte to a hardware I/O port where:
	 *      - %b0 is the 1st input (val), treated as 8-bit (the b is for byte)
	 *      - %w1 is the 2nd input (port), treated as 16-bit (the w is for word)
	 * "a"(val): put val into AL register (8-bit)
	 * "Nd"(port): set port either as an immediate constant (N) or in the DX register (d) if it’s a variable
	 * "memory": prevents it from reordering memory reads / writes around this instruction
	 */
	__asm__ volatile("outb %b0, %w1" : : "a"(val), "Nd"(port) : "memory");
}

/**
 * @brief Read a byte to an I/O port.
 * This function read the 8-bit value from the I/O port specified by port.
 * It is commonly used for hardware communication (VGA, keyboard, ...).
 *
 * @param port The 16-bit port address to read from.
 * @return The byte read from the port (8-bit).
 */
uint8_t inb(uint16_t port) {
	/**
	 * __asm__ allows embedding assembly directly in C/C++
	 * volatile prevents the compiler from optimizing away or reordering this instruction
	 *
	 * Assembly instruction:
	 * "inb %w1, %b0": read a byte from hardware I/O port where:
	 *      - %w1 is the port number (16-bit, the w stands for word)
	 *      - %b0 is the destination register (8-bit, the b stands for byte)
	 * "=a"(val): store the result in the AL register (8-bit) in val
	 * "Nd"(port): set port either as an immediate constant (N) or in the DX register (d) if it’s a variable
	 * "memory": prevents it from reordering memory reads / writes around this instruction
	 */
	uint8_t val;
	__asm__ volatile("inb %w1, %b0" : "=a"(val) : "Nd"(port) : "memory");
	return val;
}
