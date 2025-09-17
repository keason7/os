#include "idt.h"

// create a 16 bits aligned idt (address divisible by 16) for performances
__attribute__((aligned(0x10))) static idt_64 idt[IDT_MAX_DESCRIPTOR];

// idt indexes where each slot is associated to a function to call for an interrupt
static bool vectors[IDT_MAX_DESCRIPTOR];

// idt register
static idtr_64 idtr;

// array of assembly functions pointers
extern void* stub_table_isr[];

/**
 * @brief Sets an entry in the idt for a given vector
 *
 * @param vector The interrupt vector number [0, 255] corresponding to the IDT entry.
 * @param isr Pointer to the interrupt service routine (isr) function.
 * @param flags Descriptor flags for the IDT entry (ex: 0x8E for interrupt gate).
 */
void set_descriptor_idt(uint8_t vector, void* isr, uint8_t flags) {
	idt_64* descriptor = &idt[vector];

	descriptor->offset_low = (uint64_t)isr & 0xFFFF;
	descriptor->segment_selector = 0x08;
	descriptor->ist = 0;
	descriptor->attributes = flags;
	descriptor->offset_mid = ((uint64_t)isr >> 16) & 0xFFFF;
	descriptor->offset_high = ((uint64_t)isr >> 32) & 0xFFFFFFFF;
	descriptor->reserved = 0;
}

/**
 * @brief Initialize an idt table to handle interrupts.
 */
void initialize_idt(void) {
	idtr.size = sizeof(idt) * IDT_MAX_DESCRIPTOR - 1;
	idtr.offset = (uint64_t)&idt[0];

	for (uint8_t vector = 0; vector < IDT_CPU_EXCEPTION_COUNT; vector++) {
		set_descriptor_idt(vector, stub_table_isr[vector], 0x8E);
		vectors[vector] = true;
	}

	// load idt in memory and enable interrupts
	__asm__ volatile("lidt %0" : : "m"(idtr));
	__asm__ volatile("sti");
}
