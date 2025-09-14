#ifndef VGA_H
#define VGA_H

#include <stdint.h>

/**
 * @brief Enable VGA text mode cursor. Character cell is 16x16 px.
 *
 * @param cursor_start Vertical start px of cursor within cell.
 * @param cursor_end Vertical end px of cursor within cell.
 */
void enable_cursor(uint8_t cursor_start, uint8_t cursor_end);

/**
 * @brief Disable VGA text mode cursor.
 */
void disable_cursor();

/**
 * @brief Update the cursor position on screen.
 *
 * @param x Column index.
 * @param y Row index.
 *
 * Converts the 2D coordinates into a linear offset and writes
 * to the VGA cursor position registers.
 */
void update_cursor(int x, int y);

/**
 * @brief Scroll rows to delete first one and have a new last one.
 */
void scroll_screen(void);

/**
 * @brief Print a character to the VGA screen at current cursor position.
 *
 * @param c Input character.
 */
static void putc(char c);

/**
 * @brief Write a null-terminated string to the VGA text buffer.
 * Print characters in memory one by one until the last \0 which stops the loop.
 *
 * @param str A pointer to a null-terminated string to print.
 */
static void puts(const char *str);

/**
 * @brief Clear the entire screen and reset cursor.
 *
 * This function fills the VGA text buffer with blank spaces
 * using the current text color and moves the cursor to (0, 0).
 */
void clear_screen(void);

#endif
