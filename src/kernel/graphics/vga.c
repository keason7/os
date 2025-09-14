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

// first 8 bits: char, last 8 bits: foreground and background
static uint16_t text_color = 0x0F00;
static uint16_t *vga_buffer = (uint16_t *)VGA_ADDRESS;
static uint8_t cursor_row = 0;
static uint8_t cursor_col = 0;

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
 * @brief Clear the entire screen and reset cursor.
 *
 * This function fills the VGA text buffer with blank spaces
 * using the current text color and moves the cursor to (0, 0).
 */
void clear_screen(void) {
	// disable existing cursor
	disable_cursor();

	// set blank char and its color in 16 bits attribut
	uint16_t blank = ' ' | text_color;

	for (int i = 0; i < VGA_COLS * VGA_ROWS; i++) {
		vga_buffer[i] = blank;
	}
	cursor_row = 0;
	cursor_col = 0;

	// cursor thin line under character
	enable_cursor(15, 15);
	// set position to (0, 0)
	update_cursor(cursor_col, cursor_row);
}
