; cpu starts in real mode and bios loads this code at address 0x7c00
; set the origin at adress 0x7C00
; all labels and addresses are relative to this
[ORG 0x7C00]

; set code as 16 bits
[BITS 16]

; 0x08: points to the 2nd entry in the GDT table (the code segment descriptor)
; 0x10: points to the 3rd entry in the GDT table (the data segment descriptor)
OFFSET_CODE equ 0x08
OFFSET_DATA equ 0x10

; first enter real mode where the CPU has
; less than 1 MB of RAM available for use
real_mode:
    ; disable bios interrupts
    cli
    ; clear ax which is a 16-bit register in the x86 cpu (ax = 0x0000)
    ; ax is composed of ah = high byte (bits 8–15) and al = low byte (bits 0–7)
    xor ax, ax
    ; sets the data segment register to 0x0000
    mov ds, ax
    ; sets es = 0x0000
    mov es, ax
    ; sets SS (stack segment) = 0
    mov ss, ax
    ; sets stack pointer (sp) to 0x7C00
    mov sp, 0x7C00
    ; enable bios interrupts
    sti


load_protected_mode:
    ; disable bios interrupts
    cli

    ; read port 0x92 (system control port A)
    in al, 0x92
    ; set bit 1
    or al, 00000010b
    ; write back, now A20 is enabled
    out 0x92, al

    ; load the gdt register (gdtr) that point the gdt table 
    lgdt [gdt_register]

    ; copy control register bit 0 value in eax
    mov eax, cr0
    ; set it to 1
    or al, 1
    ; copy value to cr0 to enable protected mode
    mov cr0, eax

    ; load cs = OFFSET_CODE (the code segment from the GDT) and then execute protected_mode
    ; this is necessary because after setting cr0, the CPU is in protected mode 
    ; but still using the old real mode cs
    jmp OFFSET_CODE:protected_mode


; setup basic flat model (GDT table)
; a null descriptor
; a code segment (r - x) that take all RAM space
; a data segment (r w -) that take all RAM space
; both code and data segments overlaps in available memory
gdt_start:
    ; null descriptor (8 bytes)
    dd 0x0
    dd 0x0

    ; code segment
    dw 0xFFFF ; limit (16 bits, 4 GiB address space in 32 bit mode)
    dw 0x0000 ; base (16 bits)
    db 0x00 ; base (8 bits)
    db 10011010b ; access byte (8 bits, ring 0)
    db 11001111b ; flags (4 bits) + limit (4 bits)
    db 0x00 ; base (8 bits)

    ; data segment
    dw 0xFFFF ; limit (16 bits, 4 GiB address space in 32 bit mode)
    dw 0x0000 ; base (16 bits)
    db 0x00 ; base (8 bits)
    db 10010010b ; access byte (8 bits, ring 0)
    db 11001111b ; flags (4 bits) + limit (4 bits)
    db 0x00 ; base (8 bits)


gdt_end:


; GDT descriptor that point GDT table with table adress and size
gdt_register:
    dw gdt_end - gdt_start - 1 ; size (limit)
    dd gdt_start ; base address


; set code as 32 bits
[BITS 32]

; enter protected mode where the CPU has
; a maximum of 4GB of RAM
; enables the system to enforce memory, hardware I/O protection and instruction via rings
protected_mode:
    ; load the data segment selector (0x10) into AX
    mov ax, OFFSET_DATA
    ; set ds, es, fs, ss, gs to our flat data segment
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov ss, ax
    mov gs, ax

    ; set base pointer and stack pointer to 0x9C00 which is far enough
    ; from 0x7C00 to avoid overlap
    ; stack grows down from higher adresses to lower (RAM is lower to higher)
    mov ebp, 0x9C00        
    mov esp, ebp

    ; infinite loop
    jmp $


; fill remaining bytes -2  with zeros
; $ = current address, $$ = start of section (0x7C00)
times 510-($-$$) db 0
; boot sector 0xAA55 to be recognized as bootable disk
db 0x55
db 0xAA
