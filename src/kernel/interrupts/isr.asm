; make it visible to linker
global stub_table_isr

; declare that exception_handler is defined in C
extern exception_handler

; isr without error code
%macro isr_no_err_stub 1
isr_stub_%+%1:
    ; move vector number (%1) into the rdi register
    mov rdi, %1
    ; set error code to 0 (rsi = error code)
    xor rsi, rsi
    ; call C exception handler function
    call exception_handler
    ; return from interrupt
    iretq
%endmacro


; isr with an error code
%macro isr_err_stub 1
isr_stub_%+%1:
    ; move vector number (%1) into the rdi register
    mov rdi, %1
    ; cpu pushed the error code on the stack, load it into rsi
    mov rsi, [rsp]
    ; call C exception handler function
    call exception_handler
    ; pop the error code from the stack manually
    add rsp, 8
    ; return from interrupt
    iretq
%endmacro

; define cpu exceptions number [0, 31] with or without error code
isr_no_err_stub 0
isr_no_err_stub 1
isr_no_err_stub 2
isr_no_err_stub 3
isr_no_err_stub 4
isr_no_err_stub 5
isr_no_err_stub 6
isr_no_err_stub 7
isr_err_stub    8
isr_no_err_stub 9
isr_err_stub    10
isr_err_stub    11
isr_err_stub    12
isr_err_stub    13
isr_err_stub    14
isr_no_err_stub 15
isr_no_err_stub 16
isr_err_stub    17
isr_no_err_stub 18
isr_no_err_stub 19
isr_no_err_stub 20
isr_no_err_stub 21
isr_no_err_stub 22
isr_no_err_stub 23
isr_no_err_stub 24
isr_no_err_stub 25
isr_no_err_stub 26
isr_no_err_stub 27
isr_no_err_stub 28
isr_no_err_stub 29
isr_err_stub    30
isr_no_err_stub 31


; define the table of isr addresses for idr
stub_table_isr:
    %assign i 0
    %rep 32
        dq isr_stub_%+i
    %assign i i+1
    %endrep
