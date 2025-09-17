#include "entry.h"

void kernel_entry(void) {
	initialize_idt();
	clear_screen();

	int test = 1 / 0;
}
