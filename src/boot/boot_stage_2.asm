
%include "src/boot/gdt/gdt_32.asm"
%include "src/boot/gdt/gdt_64.asm"
%include "src/boot/paging.asm"

section .boot_stage_2


[BITS 16]
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

    ; load the 32 bits gdt register (gdtr) that point the gdt table
    lgdt [gdt_32_register]

    ; copy control register bit 0 value in eax
    mov eax, cr0
    ; set it to 1
    or  eax, 1
    ; copy value to cr0 to enable protected mode
    mov cr0, eax

    ; load cs = CODE_SEG_32 (the code segment from the GDT) and then execute protected_mode
    ; this is necessary because after setting cr0, the CPU is in protected mode
    ; but still using the old real mode cs
    jmp CODE_SEG_32:protected_mode


; ensure the CPU stops gracefully if there’s an error
end_16:
    hlt
    jmp end_16


[BITS 32]
; enter protected mode where the CPU has a maximum of 4 GB of RAM
; enables the system to enforce memory, hardware I/O protection and instruction via rings
protected_mode:
    ; load the data segment selector from GDT into AX
    mov ax, DATA_SEG_32
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
    ; build paging tables
    ; PML4 address is 0x1000 and is set to cr3 so the CPU know top level location
    mov ebx, 0x1000
    call build_page_table
    mov cr3, ebx

    ; enable pae
    ; expands page tables to support 64-bit addresses
    mov edx, cr4
    or edx, (1 << 5)
    mov cr4, edx

    ; set lme
    ; tells the CPU that it is allowed to execute 64-bit instructions once paging is enabled
    mov ecx, 0xC0000080
    rdmsr
    or eax, (1 << 8)
    wrmsr

    ; enable paging
    mov eax, cr0
    or eax, (1 << 31)
    mov cr0, eax

    ; load the 64 bits gdt register (gdtr) that point the gdt table
    lgdt [gdt_64_register]

    ; far jump to load CS with 64 bits code segment selector
    ; and continue execution at label "long_mode" in long mode
    jmp CODE_SEG_64:long_mode


; ensure the CPU stops gracefully if there’s an error
end_32:
    hlt
    jmp end_32


[BITS 64]
; enter protected mode where the CPU has a maximum of 256 TB of RAM
; enables mandatory memory paging and general registers extended to
; 64 bits (and add new registers such as SSE)
long_mode:
    ; initialize registers
    mov ax, DATA_SEG_64
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; initialize stack pointer
    mov rsp, 0x00009000

    ; start kernel code
    extern kernel_entry
    call kernel_entry


; ensure the CPU stops gracefully if there’s an error
end_64:
    hlt
    jmp end_64
