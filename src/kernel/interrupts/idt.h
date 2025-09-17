#ifndef IDT_H
#define IDT_H

#include <stdbool.h>
#include <stdint.h>

// define idt table size and the number of CPU exceptions
#define IDT_MAX_DESCRIPTOR 256
#define IDT_CPU_EXCEPTION_COUNT 32

// define idtr structure for 64 bits, __attribute__((packed)) forces memory
// layout with no extra padding bits
//
// size is the size the idt in bytes
// offset is the address of the idt
typedef struct {
	uint16_t size;
	uint64_t offset;
} __attribute__((packed)) idtr_64;

// define idt structure for 64 bits
// - offset_high (bits 32-63), offset_mid (bits 16-31), offset_low (bits 0-15) define
// the 64 bits address of the ist table
// - segment_selector tells cpu which code segment to load into cs registry (kernel code segment of gdt)
// - ist enable the interrupt stack table (ist) which is a aspecial stack only for interrupts
// - attributes:
// 		- gate type (interrupt gate or trap gate)
// 		- dpl which defines the cpu privilege levels which are allowed
// 		  to access this interrupt via the int instruction
// 		- present bit, must be set to 1 for the descriptor to be valid
typedef struct {
	uint16_t offset_low;
	uint16_t segment_selector;
	uint8_t ist;
	uint8_t attributes;
	uint16_t offset_mid;
	uint32_t offset_high;
	uint32_t reserved;
} __attribute__((packed)) idt_64;

/**
 * @brief Sets an entry in the idt for a given vector
 *
 * @param vector The interrupt vector number [0, 255] corresponding to the IDT entry.
 * @param isr Pointer to the interrupt service routine (isr) function.
 * @param flags Descriptor flags for the IDT entry (ex: 0x8E for interrupt gate).
 */
void set_descriptor_idt(uint8_t vector, void* isr, uint8_t flags);

/**
 * @brief Initialize an idt table to handle interrupts.
 */
void initialize_idt(void);

#endif
