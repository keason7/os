; GDT table - setup basic flat model
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


; aligns the next code or data to an 8 bytes boundary
; if the current address is not divisible by 8, inserts padding bytes
; so the next label starts at an address that is a multiple of 8
align 8

; null descriptor (8 bytes)
; this is mandatory: index 0 is always unused
gdt_32_start:
    dd 0x0
    dd 0x0

; code segment 32 bits protected mode
gdt_32_code_segment:
    dw 0xFFFF ; limit (16 bits)
    dw 0x0000 ; base (16 bits)
    db 0x00 ; base (8 bits)
    db 10011010b ; access byte (8 bits)
    db 11001111b ; flags (4 bits) + limit (4 bits)
    db 0x00 ; base (8 bits)

; data segment 32 bits protected mode
gdt_32_data_segment:
    dw 0xFFFF ; limit (16 bits)
    dw 0x0000 ; base (16 bits)
    db 0x00 ; base (8 bits)
    db 10010010b ; access byte (8 bits)
    db 11001111b ; flags (4 bits) + limit (4 bits)
    db 0x00 ; base (8 bits)

gdt_32_end:

; GDT descriptor that point GDT table with table adress and size
gdt_32_register:
    dw gdt_32_end - gdt_32_start - 1
    dd gdt_32_start


; CODE_SEG_32: points to the 2nd entry in the GDT 32 bits table
; DATA_SEG_32: points to the 3rd entry in the GDT 32 bits table
CODE_SEG_32 equ gdt_32_code_segment - gdt_32_start
DATA_SEG_32 equ gdt_32_data_segment - gdt_32_start
