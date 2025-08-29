; cpu starts in real mode and bios loads this code at address 0x7c00
; set the origin at adress 0x7C00
; all labels and addresses are relative to this
[ORG 0x7C00]
    ; disable bios interrupts
    cli

    ; clear ax which is a 16-bit register in the x86 cpu (ax = 0x0000)
    ; ax is composed of ah = high byte (bits 8–15) and al = low byte (bits 0–7)
    xor ax, ax
    ; sets the data segment register to 0x0000
    mov ds, ax

    ; sets SS (stack segment) = 0
    mov ss, ax
    ; sets stack pointer (sp) to 0x7C00
    mov sp, 0x7C00

    ; clear direction flag (df) which controls the behavior of string instructions
    ; df=0 (CLD): si increments after each operation: string read/write goes forward.
    ; df=1 (STD): si decrements: string goes backward.
    cld

    ; puts the value 0xB800 into ax
    ; 0xB8000 = start of video memory in text mode (color mode)
    mov ax, 0xB800
    ; sets es = 0xB800
    mov es, ax
    ; with es = 0xB800 and di = 0, es:di points to the top-left character cell of the screen.
    xor di, di

    ; load source index register (16-bit) used for string operations
    ; with the address of the message string
    mov si, msg

print_loop:
    ; load one byte of previously moved string at [DS:SI] into al register
    lodsb
    ; check for null terminator (0) that signify the end of the string
    or  al, al
    ; if al is zero, go to .done flag
    jz  .done

    ; after lodsb, al holds the character
    ; setting AH prepares ax to contain a 16-bit value where al = char and ah = attribute (color)
    mov ah, 0x02

    ; store string word: it stores the 16-bit AX into memory at es:di
    ; then, because df = 0, it increments di by 2 (word size)
    ; effect: write (character, attribute) to the VGA text buffer and move to the next screen cell
    stosw

    jmp print_loop

.done:
    ; enable bios interrupts
    sti

hang:
    ; stops the CPU until the next external interrupt occurs (saves power)
    hlt

    jmp hang

; ---------------- data ----------------
; 0 = null terminator
msg db 'Hi there', 0

; fill remaining bytes -2  with zeros
; $ = current address, $$ = start of section (0x7C00)
times 510-($-$$) db 0
; boot sector 0xAA55 to be recognized as bootable disk
db 0x55
db 0xAA
