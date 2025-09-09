section .boot_stage_1


; export the symbol so other files can call it
global load_boot_stage_2

; read more sectors to actually read and load in RAM the rest of the code
; 512 x 64 = 32 KB of disk
NUMBER_OF_SECTORS equ 64
SECTOR_SIZE equ 512

; cpu starts in real mode and bios loads this code
; (one sector = 512 bytes = bootloader) at address 0x7c00
BOOT_LOADER_ADDR equ 0x7c00

; address of the rest of the boot code to enter protected mode,
; long mode and load kernel
BOOT_STAGE_2_ADDR equ (BOOT_LOADER_ADDR + SECTOR_SIZE)


[BITS 16]
; first enter real mode where the CPU has
; less than 1 MB of RAM available for use
load_boot_stage_2:
    ; load address of disk address packet (dap) to si
    ; it's a data struct used by bios to specify params for
    ; disk operation (read/write sectors on disk drive)
    mov si, dap_params
    ; bios interrupt 13h (ah=0x42): extended mode (lba)
    mov ah, 0x42
    ; read first hdd (0x00: floppy, 0x80: 1st hdd, 0x81: 2nd hdd, ...)
    mov dl, 0x80
    ; bios interrupt to read specified sector using lba
    int 0x13
    ; if read failed, jumps to the label "read_disk_error"
    ; as cpu's carry flag (cf) is 1
    jc read_disk_error

switch_to_boot_stage_2:
    ; far jump to stage 2 boot code
    ; segment = 0 (flat), offset = BOOT_STAGE_2_ADDR
    jmp 0:BOOT_STAGE_2_ADDR

read_disk_error:
    ; compare the number of sectors bios should load to
    ; safety check if we bios do not read the requested number of sectors as bios may
    ; modify [dap_sectors_num] after int 0x13 to indicate how much has actually been read
    cmp word [dap_sectors_num], NUMBER_OF_SECTORS
    ; if fewer or equal, just continue anyway
    jle switch_to_boot_stage_2

; infinite halt loop (safety stop if unrecoverable error)
end:
    hlt
    jmp end


; aligns the next code or data to 4 bytes boundary
; as specified in doc
align 4

dap_params:
    db 0x10 ; size of packet = 16 bytes
    db 0 ; reserved, must be 0

dap_sectors_num:
    ; number of sectors to read (64)
    dw NUMBER_OF_SECTORS
    ; destination address
    dd BOOT_STAGE_2_ADDR
    ; starting lba sector = 1
    dq 1
