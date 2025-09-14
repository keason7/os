#include "vga.h"

#include "serial/serial.h"

// VGA mode 3 text buffer address and window size
#define VGA_ADDRESS 0xB8000
#define VGA_COLS 80
#define VGA_ROWS 25

// port to select VGA register for the text mode cursor
#define VGA_PORT_INDEX 0x3D4
// port to read / write selected register data for the text mode cursor
#define VGA_PORT_DATA 0x3D5

enum vga_color {
	VGA_COLOR_BLACK = 0,
	VGA_COLOR_BLUE = 1,
	VGA_COLOR_GREEN = 2,
	VGA_COLOR_CYAN = 3,
	VGA_COLOR_RED = 4,
	VGA_COLOR_MAGENTA = 5,
	VGA_COLOR_BROWN = 6,
	VGA_COLOR_LIGHT_GREY = 7,
	VGA_COLOR_DARK_GREY = 8,
	VGA_COLOR_LIGHT_BLUE = 9,
	VGA_COLOR_LIGHT_GREEN = 10,
	VGA_COLOR_LIGHT_CYAN = 11,
	VGA_COLOR_LIGHT_RED = 12,
	VGA_COLOR_LIGHT_MAGENTA = 13,
	VGA_COLOR_LIGHT_BROWN = 14,
	VGA_COLOR_WHITE = 15,
};

static uint16_t *vga_buffer = (uint16_t *)VGA_ADDRESS;
static uint8_t cursor_row = 0;
static uint8_t cursor_col = 0;

// first 8 bits: char, last 8 bits: foreground and background
// << 8: foreground bits
// << 12: background bits
static uint16_t text_color = VGA_COLOR_BLACK << 12 | VGA_COLOR_WHITE << 8 | 0x0000;

/**
 * @brief Enable VGA text mode cursor. Character cell is 16x16 px.
 *
 * @param cursor_start Vertical start px of cursor within cell.
 * @param cursor_end Vertical end px of cursor within cell.
 */
void enable_cursor(uint8_t cursor_start, uint8_t cursor_end) {
	// select cursor start register
	outb(VGA_PORT_INDEX, 0x0A);
	// preserve top 2 bits (reserved) and set cursor start
	outb(VGA_PORT_DATA, (inb(VGA_PORT_DATA) & 0xC0) | cursor_start);

	// select cursor end register
	outb(VGA_PORT_INDEX, 0x0B);
	// preserve top 3 bits and set cursor end
	outb(VGA_PORT_DATA, (inb(VGA_PORT_DATA) & 0xE0) | cursor_end);
}

/**
 * @brief Disable VGA text mode cursor.
 */
void disable_cursor() {
	// writing 0x20 to the cursor start register disables the cursor
	outb(VGA_PORT_INDEX, 0x0A);
	outb(VGA_PORT_DATA, 0x20);
}

/**
 * @brief Update the cursor position on screen.
 *
 * @param x Column index.
 * @param y Row index.
 *
 * Converts the 2D coordinates into a linear offset and writes
 * to the VGA cursor position registers.
 */
void update_cursor(int x, int y) {
	uint16_t cursor_pos = y * VGA_COLS + x;

	// select low byte of cursor position register
	outb(VGA_PORT_INDEX, 0x0F);
	// set low 8 bits (column)
	outb(VGA_PORT_DATA, (uint8_t)(cursor_pos & 0xFF));
	// high byte of cursor position register
	outb(VGA_PORT_INDEX, 0x0E);
	// set high 8 bits (row)
	outb(VGA_PORT_DATA, (uint8_t)((cursor_pos >> 8) & 0xFF));
}

/**
 * @brief Scroll rows to delete first one and have a new last one.
 */
void scroll_screen(void) {
	// copy each row except first one and copy it to previous row
	for (int row = 1; row < VGA_ROWS; row++) {
		for (int col = 0; col < VGA_COLS; col++) {
			vga_buffer[(row - 1) * VGA_COLS + col] = vga_buffer[row * VGA_COLS + col];
		}
	}

	// clear last row
	for (int col = 0; col < VGA_COLS; col++) {
		vga_buffer[(VGA_ROWS - 1) * VGA_COLS + col] = ' ' | text_color;
		;
	}

	// move cursor to start of last row
	cursor_row = VGA_ROWS - 1;
	cursor_col = 0;
}

/**
 * @brief Print a character to the VGA screen at current cursor position.
 *
 * @param c Input character.
 */
void putc(char c) {
	if (c == '\n') {
		cursor_row++;
		cursor_col = 0;
	} else {
		// 16 bits: last 8 bits = text_color, first 8 bits = c
		vga_buffer[cursor_row * VGA_COLS + cursor_col] = c | text_color;
		cursor_col++;
		if (cursor_col >= VGA_COLS) {
			cursor_col = 0;
			cursor_row++;
		}
	}

	if (cursor_row >= VGA_ROWS) {
		scroll_screen();
	}
	update_cursor(cursor_col, cursor_row);
}

/**
 * @brief Write a null-terminated string to the VGA text buffer.
 * Print characters in memory one by one until the last \0 which stops the loop.
 *
 * @param str A pointer to a null-terminated string to print.
 */
void puts(const char *str) {
	while (*str) {
		putc(*str++);
	}
	update_cursor(cursor_col, cursor_row);
}

/**
 * @brief Clear the entire screen and reset cursor.
 *
 * This function fills the VGA text buffer with blank spaces
 * using the current text color and moves the cursor to (0, 0).
 */
void clear_screen(void) {
	// disable existing cursor
	disable_cursor();

	for (int i = 0; i < VGA_COLS * VGA_ROWS; i++) {
		// set blank char and it's color attribut (8 bits + 8 bits)
		vga_buffer[i] = ' ' | text_color;
	}
	cursor_row = 0;
	cursor_col = 0;

	// cursor thin line under character
	enable_cursor(15, 15);
	// set position to (0, 0)
	update_cursor(cursor_col, cursor_row);

	puts("Hi there\n");
}
