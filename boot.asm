; cpu starts in real mode and bios loads this code at address 0x7c00
; set the origin at adress 0x7C00
; all labels and addresses are relative to this
[ORG 0x7C00]
    ; clear ax which is a 16-bit register in the x86 cpu (ax = 0x0000)
    ; ax is composed of ah = high byte (bits 8–15) and al = low byte (bits 0–7)
    xor ax, ax
    ; sets the data segment register to 0x0000
    mov ds, ax

    ; load source index register (16-bit) used for string operations
    ; with the address of the message string
    mov si, msg
    ; clear direction flag (df) which controls the behavior of string instructions
    ; df=0 (CLD): si increments after each operation: string read/write goes forward.
    ; df=1 (STD): si decrements: string goes backward.
    cld

; load one byte of previously moved string at [DS:SI] into al register
ch_loop: lodsb
    ; check for null terminator (0) that signify the end of the string
    or al, al            
    ; if al is zero, go to hang flag
    jz hang

    ; set ah with the function 0x0E which is Teletype output for BIOS interrupt 0x10
    mov ah, 0x0E
    ; set bh to 0 to tell the BIOS which video page to use (=0)
    mov bh, 0
    ; call bios interrupt to print AL on screen
    int 0x10

    jmp ch_loop

; end of bootloader after the printing
hang:
    jmp hang

; 13 = carriage Return (move cursor to column 0)
; 10 = line feed (move cursor to next line)
; 0 = null terminator
msg:
    db 'Hi there', 13, 10, 0

    ; fill remaining bytes -2  with zeros
    ; $ = current address, $$ = start of section (0x7C00)
    times 510-($-$$) db 0 
    ; boot sector 0xAA55 to be recognized as bootable disk
    db 0x55
    db 0xAA
