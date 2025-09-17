#ifndef ENTRY_H
#define ENTRY_H

#include "graphics/vga.h"
#include "interrupts/idt.h"
#include "interrupts/isr.h"

void kernel_entry(void);

#endif
