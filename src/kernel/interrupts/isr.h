#ifndef ISR_H
#define ISR_H

#include <stdint.h>

#include "graphics/vga.h"
#include "idt.h"

/**
 * @brief Handles cpu exceptions triggered by the interrupt vector.
 *
 * @param vector The interrupt vector number that identifies the exception type.
 * @param error_code The cpu provided error code (if available) for the exception.
 *
 * @note This function is marked as noreturn because it halts the cpu with hlt.
 */
void exception_handler(uint64_t vector, uint64_t error_code);

#endif
