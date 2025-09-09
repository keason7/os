; TODO:
; - We are just initializing one page in lowest level might not be enought in futur dev
; - For now, addresses are stored in 32 bit (4 bytes) to each entry is half initialized


[BITS 32]
; 4096 bytes pages and tables with 512 entries
PAGE_SIZE_64 equ 0x1000
TABLE_SIZE_64 equ 0x1000
NUMBER_OF_ENTRIES equ 512

; setup paging for x86_64, with 4 level of page tables
; - PML4 (Page Map Level 4) is the top-level table
; - PDPT (Page Directory Pointer Table) is level 3
; - PD (Page Directory) is level 2
; - PT (Page Table) is level 1
;
; each page table has 512 entries of 8 bytes, so each page table weight 4 KB
; each page table point to a lower level page table
; normal pages points to 4 KB physical memory
; PD or PDPT entry can point directly to 2 MB or 1 GB pages, skipping lower levels
;
; 64 bits paging have maximum memory mapping of:
; - 512 PT_entries x 4096 B = 2 MB
; - 512 PD_entries x 2 MB = 1 GB
; - 512 PDPT_entries x 1 GB = 512 GB
; - 512 PML4_entries x 512 GB = 262 TB
; in practice it's 256 TB even if all memory does not have to be mapped here
build_page_table:
    ; saves eax, ebx, ecx, ... on the stack to restore them later with popa
    pusha

    ; set counter register ecx to the size of the table in bytes
    mov ecx, TABLE_SIZE_64
    ; edi points to the start of PML4
    mov edi, ebx
    ; zero out eax register (used by stosd)
    xor eax, eax
    ; stosd stores 4 bytes from eax (=0) into memory at edi (start of PML4)
    ; rep repeats this ecx times (4096) so it clears 16 KB
    rep stosd

    ; link first entry in PML4 table to the PDPT table
    ; reset edi to the start of PML4
    mov edi, ebx
    ; compute base address of PML4 + 4096 OR 0b11 = address of PDPT in eax
    ; 0b11 = present (bit 0) + writable (bit 1): CPU knows the page exists and can be written to
    lea eax, [edi + (TABLE_SIZE_64 | 11b)]
    ; store the 4 bytes (since we are in 32 bit mode) value at [edi] => PML4[0] = PDPT address + flags
    mov dword [edi], eax

    ; link first entry in PDPT table to the PD table
    ; move edi to PDPT[0]
    add edi, TABLE_SIZE_64
    ; increase address in eax by 4096 to compute PD address
    add eax, TABLE_SIZE_64
    ; store the 4 bytes (since we are in 32 bit mode) value at [edi] => PDPT[0] = PD address + flags
    mov dword [edi], eax

    ; link first entry in PD table to the PT table
    ; move edi to PD[0]
    add edi, TABLE_SIZE_64
    ; increase address in eax by 4096 to compute PT address
    add eax, TABLE_SIZE_64
    ; store the 4 bytes (since we are in 32 bit mode) value at [edi] => PD[0] = PT address + flags
    mov dword [edi], eax

    ; initialize a single page on the lowest layer
    ; move edi to PT[0]
    add edi, TABLE_SIZE_64
    ; store flags 0b11 to ebx
    mov ebx, 11b
    ; store the page number of entries in ecx
    mov ecx, NUMBER_OF_ENTRIES

; initialize all PT entries (PT pointed by PD[0]) where each entry is 4 KB page
; 512 × 4 KB = 2 MB of physical memory is mapped
build_page_table_set_entry:
    ; store physical memory + flag, at first iter:
    ; ebx = 0x00000003 = 0x00000000 + 0b11
    mov dword [edi], ebx
    ; each page entry maps 4096 bytes physical address, so we shift address by this value
    add ebx, PAGE_SIZE_64
    ; each entry is 8 bytes, so move to the next slot to write an address
    add edi, 8

    ; loop ecx times (number of entries)
    loop build_page_table_set_entry

    ; restores all general-purpose registers and quit
    popa
    ret
