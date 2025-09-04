; cpu starts in real mode and bios loads this code at address 0x7c00
ADDR_ORIGIN equ 0x7C00

; set the origin at adress 0x7C00
; all labels and addresses are relative to this
[ORG ADDR_ORIGIN]

; set code as 16 bits
[BITS 16]

; 0x08: points to the 2nd entry in the GDT table
; 0x10: points to the 3rd entry in the GDT table
OFFSET_32_CODE equ 0x08
OFFSET_32_DATA equ 0x10
; OFFSET_64_CODE  equ 0x18

; first enter real mode where the CPU has
; less than 1 MB of RAM available for use
real_mode:
    ; disable bios interrupts
    ; ensures no bios interrupt interferes while setting up segments and stack
    cli
    ; clear ax which is a 16 bits register in the x86 cpu (ax = 0x0000)
    ; ax is composed of ah = high byte (bits 8-15) and al = low byte (bits 0-7)
    xor ax, ax
    ; sets the data segment register to 0x0000
    mov ds, ax
    ; sets es = 0x0000
    mov es, ax
    ; sets ss (stack segment) to 0x0000
    ; stack grows down from higher adresses to lower (RAM is lower to higher)
    mov ss, ax
    ; sets stack pointer (sp) to 0x7C00
    mov sp, ADDR_ORIGIN
    ; enable bios interrupts
    sti


; setup basic flat model (GDT table)
; both code and data segments overlaps in available memory
; 1) a null descriptor
; 2) code segment(s) (r - x)
; 3) data segment(s) (r w -)
; 
; - limit (20 bits): limit_low = 0xFFFF (16 bits) and limit_high = 0xF (4 bits) to
; extend RAM to 2^20 so around 1 MB: granularity flag extend then 1 MB RAM to 4 GB
; such as: 1 MB * 4 KB = 4 GB
; 
; - base (32 bits): base_low = 0x0000 (16 bits), base_middle = 0x00 (8 bits)
; and base_high = 0x00 (8 bits)
; so the base 32 bits address is 0x00000000
; 
; - access byte:
;   - bit 7 [set to 1]: present bit which allows an entry to refer to a valid segment
;   - bits 6-5 [set to 00]: ring 0 = highest privilege (kernel)
;   - bit 4 [set to 1]: define code or data segment  
;   - bits 3 to 0: 
;       - [1010]: code segement, r - x, never accessed
;       - [0010]: data segement, r w -, never accessed
; 
; - flags
;   - bit 7 [set to 1]: granularity to extend to 4 GB RAM
;   - bit 6 [set to 1]: set 32-bit protected mode segment
;   - bit 5 [set to 0]: set 64-bit long mode segment
;   - bit 4 [set to 0]: always 0
gdt_start:
    ; null descriptor (8 bytes)
    ; this is mandatory: index 0 is always unused
    dd 0x0
    dd 0x0

    ; code segment 32 bits protected mode 
    dw 0xFFFF ; limit (16 bits)
    dw 0x0000 ; base (16 bits)
    db 0x00 ; base (8 bits)
    db 10011010b ; access byte (8 bits)
    db 11001111b ; flags (4 bits) + limit (4 bits)
    db 0x00 ; base (8 bits)

    ; data segment 32 bits protected mode
    dw 0xFFFF ; limit (16 bits)
    dw 0x0000 ; base (16 bits)
    db 0x00 ; base (8 bits)
    db 10010010b ; access byte (8 bits)
    db 11001111b ; flags (4 bits) + limit (4 bits)
    db 0x00 ; base (8 bits)

    ; ; code segment 64 bits long mode
    ; ; in long mode since paging is mandatory, base and limit
    ; ; are ignored and can be set to 0
    ; dw 0x0000 ; limit (16 bits)
    ; dw 0x0000 ; base (16 bits)
    ; db 0x00 ; base (8 bits)
    ; db 10011010b ; access byte (8 bits)
    ; db 10100000b ; flags (4 bits) + limit (4 bits)
    ; db 0x00 ; base (8 bits)

gdt_end:


; GDT descriptor that point GDT table with table adress and size
gdt_register:
    dw gdt_end - gdt_start - 1 ; size (limit)
    dd gdt_start ; base address


load_protected_mode:
    ; disable bios interrupts (not available in protected mode)
    cli

    ; enable a20 that disable wrap around
    ; example: address 0xFFFFF + 1 would wrap back to 0x00000
    ; 32 / 64 bits require to work with more than 1 MB
    ; 
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

    ; load cs = OFFSET_32_CODE (the code segment from the GDT) and then execute protected_mode
    ; this is necessary because after setting cr0, the CPU is in protected mode 
    ; but still using the old real mode cs
    jmp OFFSET_32_CODE:protected_mode


; set code as 32 bits
[BITS 32]

; enter protected mode where the CPU has a maximum of 4 GB of RAM
; enables the system to enforce memory, hardware I/O protection and instruction via rings
protected_mode:
    ; load the data segment selector from GDT into AX
    mov ax, OFFSET_32_DATA
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

    jmp $


; load_long_mode:
;     ; set cr4 bit number 5 to 1
;     ; this enable PAE (Physical Address Extension) which allows 32-bit CPU to access 
;     ; more than 4gb RAM by extending physical addr to 36 bits (64gb RAM)
;     ; PAE required to enable long mode paging
;     mov eax, cr4
;     or  eax, (1 << 5)
;     mov cr4, eax

;     mov eax, 0x00009000
;     or  eax, 0x3
;     mov dword [0x00008000], eax
;     mov dword [0x00008000 + 4], 0x0

;     mov eax, 0x0000A000
;     or  eax, 0x3
;     mov dword [0x00009000], eax
;     mov dword [0x00009000 + 4], 0x0

;     mov eax, 0x00000000
;     or  eax, 0x83
;     mov dword [0x0000A000], eax
;     mov dword [0x0000A000 + 4], 0x0

;     mov eax, 0x00200000
;     or  eax, 0x83
;     mov dword [0x0000A000 + 8], eax
;     mov dword [0x0000A000 + 4 + 8], 0x0

;     mov ecx, 0xC0000080
;     rdmsr
;     or  eax, (1 << 8)
;     wrmsr

;     mov eax, 0x00008000
;     mov cr3, eax

;     mov eax, cr0
;     or  eax, 0x80000000
;     mov cr0, eax

;     jmp OFFSET_64_CODE:long_mode


; [BITS 64]
; long_mode:
;     mov ax, OFFSET_32_DATA
;     mov ds, ax
;     mov es, ax
;     mov fs, ax
;     mov gs, ax
;     mov ss, ax

;     mov rsp, 0x00009000

;     jmp $


; fill remaining bytes - 2  with zeros so this code + zeros + signature = 512 bytes
; $ = current address, $$ = start of section (0x7C00)
times 510-($-$$) db 0
; boot sector 0xAA55 to be recognized as bootable disk
db 0x55
db 0xAA
