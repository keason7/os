MEMORY
{
    boot_stage_1 (rwx) : ORIGIN = 0x7c00, LENGTH = 512
    boot_stage_2 (rwx) : ORIGIN = 0x7e00, LENGTH = 512
    kernel (rwx) : ORIGIN = 0x8000, LENGTH = 0x10000
}

ENTRY(load_boot_stage_2)
SECTIONS
{
    .boot_stage_1 : { *(.boot_stage_1); } > boot_stage_1
    .bootsign (0x7c00 + 510) :
    {
        BYTE(0x55)
        BYTE(0xaa)
    } > boot_stage_1
    .boot_stage_2 : { *(.boot_stage_2); } > boot_stage_2
    .text : { *(.text); } > kernel
    .data : { *(.data); } > kernel
    .rodata : { *(.rodata); } > kernel
    .bss :
    {
        *(.bss)
        *(COMMON)
    } > kernel
}
