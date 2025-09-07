; cpu starts in real mode and bios loads this code at address 0x7c00
ADDR_ORIGIN equ 0x7C00

; set the origin at adress 0x7C00
; all labels and addresses are relative to this
[ORG ADDR_ORIGIN]

; set code as 16 bits
[BITS 16]

; 0x08: points to the 2nd entry in the GDT table
; 0x10: points to the 3rd entry in the GDT table
; 0x18: points to the 4th entry in the GDT table
OFFSET_32_CODE equ 0x08
OFFSET_32_DATA equ 0x10
OFFSET_64_CODE  equ 0x18

; paging tables addresses
PML4T_ADDR equ 0x3000
PDPT_ADDR equ 0x4000
PDT_ADDR equ 0x5000
PT_ADDR equ 0x6000


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

    ; code segment 64 bits long mode
    ; in long mode since paging is mandatory, base and limit
    ; are ignored and can be set to 0
    dw 0x0000 ; limit (16 bits)
    dw 0x0000 ; base (16 bits)
    db 0x00 ; base (8 bits)
    db 10011010b ; access byte (8 bits)
    db 10100000b ; flags (4 bits) + limit (4 bits)
    db 0x00 ; base (8 bits)

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
    or  eax, 1
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



load_long_mode:
    ; setup paging
    ; - PML4 (Page Map Level 4) is the top-level table (512 entries)
    ; - PDPT (Page Directory Pointer Table) is level 3 (512 entries)
    ; - PD (Page Directory) is level 2 (512 entries)
    ; - PT (Page Table) is level 1 (512 entries)
    ; each entry is 8 bytes, so 8 * 512 = 4096 so usually 4KB

    ; move PML4 table address to cr3 so the CPU know top level location
    mov edi, PML4T_ADDR
    mov cr3, edi

    ; set eax register to 0
    xor eax, eax
    ; load 4096 into the ecx register
    ; ecx will act as the counter
    mov ecx, 4096
    ; repeat the following stosd 4096 times
    ; store eax (= 0) into memory at [ES:EDI] and advance edi by 4 bytes
    ; 4096 * 4 bytes = 16384 bytes and each of the 4 tables is supposed to be 4096 bytes
    ; so it allocate with zeros, the space for PML4, PDPT, PD and PT
    rep stosd

    ; set destination index to the beginning of the PML4 table
    mov edi, PML4T_ADDR
    ; writes the PDPT address into the first PML4 entry and marks it as present and read / write
    mov dword [edi], PDPT_ADDR & 0xFFFFFFFFFF000 | 1 | 2

    ; set destination index to the beginning of the PDPT table
    mov edi, PDPT_ADDR
    ; writes the PDT address into the first PDPT entry and marks it as present and read / write
    mov dword [edi], PDT_ADDR & 0xFFFFFFFFFF000 | 1 | 2

    ; set destination index to the beginning of the PD table
    mov edi, PDT_ADDR
    ; writes the PT address into the first PDT entry and marks it as present and read / write
    mov dword [edi], PT_ADDR & 0xFFFFFFFFFF000 | 1 | 2

    ; set destination index to the beginning of the PT table to fill page table entries
    mov edi, PT_ADDR
    ; set initial page flags: present and read / write (1 | 2 = OR(00000001, 00000010) = 0000 0011)
    ; bit 0 and 1 define present and read / write of a PT entry
    mov ebx, 1 | 2
    ; 512 entries for a page
    mov ecx, 512

    ; TODO: implement more paging initialization
    ; here we setup one page (PT) as each previous level point
    ; to the next layer without initializing entries
    ; we setup one 4KB page where each entry point to 4KB memory allocation segment
    ; 512 * 4KB = 2MB of mapped memory

    ; setup PT entries
    .SetEntry:
        ; write the entry (physical address + flags)
        mov dword [edi], ebx
        ; next entry points 4096 bytes higher in physical memory
        add ebx, 0x1000
        ; move to next page table entry (8 bytes)
        add edi, 8
        ; repeat 512 times
        loop .SetEntry

    ; enable pae
    ; expands page tables to support 64-bit addresses
    mov edx, cr4
    or edx, (1 << 5 )
    mov cr4, edx

    ; set lme
    ; tells the CPU that it is allowed to execute 64-bit instructions once paging is enabled
    mov ecx, 0xC0000080
    rdmsr
    or eax, (1 << 8)
    wrmsr

    ; enable paging
    mov eax, cr0
    or eax, (1 << 31 )
    mov cr0, eax

    ; far jump to 64-bit code segment selector (OFFSET_64_CODE) and label (long_mode)
    ; this flushes the instruction pipeline and reloads CS with the 64-bit descriptor
    ; required to officially switch into long mode execution
    jmp OFFSET_64_CODE:long_mode


; set code as 64 bits
[BITS 64]

; enter protected mode where the CPU has a maximum of 256 TB of RAM
; enables mandatory memory paging and general registers extended to
; 64 bits (and add new registers such as SSE)
long_mode:
    mov ax, OFFSET_32_DATA
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    mov rsp, 0x00009000

    jmp $


; fill remaining bytes - 2  with zeros so this code + zeros + signature = 512 bytes
; $ = current address, $$ = start of section (0x7C00)
times 510-($-$$) db 0
; boot sector 0xAA55 to be recognized as bootable disk
dw 0xAA55
