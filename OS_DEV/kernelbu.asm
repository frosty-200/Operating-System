section .data

gdt64:
    dq 0x0000000000000000   ; 0x00 null
    dq 0x0020980000000000   ; 0x08 kernel code
    dq 0x0000920000000000   ; 0x10 kernel data  ← new
    dq 0x0020f80000000000   ; 0x18 user code
    dq 0x0000f20000000000   ; 0x20 user data

TssDesc:
	dw TssLen-1
	dw 0
	db 0
	db 0x89
	db 0
	db 0
	dq 0

	;dq 0x0000920000000000
	;dq 0x0020FA0000000000
	;dq 0x0000F20000000000

gdt64Len: equ $-gdt64

gdt64_ptr:
	dw gdt64Len-1
        dq gdt64

Tss:
	dd 0
	dq 0x150000
	times 88 db 0
	dd TssLen

TssLen: equ $-Tss

section .text



;[BITS 64]
;[ORG 0x200000]
default ABS

start:
	mov rdi, Idt
	mov rax, handler0
	call SetHandler
	;mov[rdi], ax
	;shr rax, 16
	;mov [rdi + 6], ax
	;shr rax, 16
	;mov [rdi+8], eax

	mov rdi, Idt
	mov rax, Timer
	add rdi, 32*16
	call SetHandler
	mov rdi, Idt+32*16+7+16
	mov rax SIRQ
	call SetHandler

;	mov[rdi], ax
;	shr rax, 16
;	mov [rdi + 6], ax
;	shr rax, 16
;	mov [rdi+8], eax

	lgdt [gdt64_ptr]
	lidt[Idtptr]


SetTss:
	mov rax, Tss
	mov [TssDesc+2],ax
	shr rax, 16
	mov [TssDesc+4] ,al
	shr rax, 8
	mov [TssDesc+7],al
	shr rax,8
	mov [TssDesc+8], eax

	mov ax, 0x28
	ltr ax

	push 8
	push kernel_entry
	db 0x48
	retf

kernel_entry:
	mov rsp, 0x90000
	mov byte[0xb8000], 'K'
        mov byte[0xb8001], 0xa


initPIT:
	mov al, (1<<2) | (3<<4)
	out 0x43, al
	mov ax, 11931
	out 0x40, al
	mov al, ah
	out 0x40, al
	mov byte[0xb8002], 'P'
	mov byte[0xb8003], 0xa

initPIC:
	mov al, 0x11
	out 0x20, al
	out 0xa0, al

	mov al, 32
	out 0x21, al
	mov al, 40
	out 0xa1,al

	mov al,4
	out 0x21, al
	mov al,2
	out 0xa1, al

	mov al, 1
	out 0x21, al
	out 0xa1, al

	mov al, 11111110b
	out 0x21,al
	mov al, 11111111b
	out 0xa1, al

	;sti

;	push 0x18|3
;	push 0x7c00
;	push 0x2
;	push 0x10|3
;	push UserEntry
;	mov byte[0xb8004], 'O'
;	mov byte[0xb8005], 0xa
;	iretq

	mov rax, 0x20|3    ; SS  = user data, RPL=3
	push rax
	mov rax, 0x80000
	push rax
	mov rax, 0x202
	push rax
	mov rax, 0x18|3    ; CS  = user code, RPL=3
	push rax
	mov rax, UserEntry
	push rax
	mov byte [0xb8004], 'O'
	mov byte [0xb8005], 0xa
	iretq

end:
	hlt
	jmp end

SetHandler:
	mov[rdi], ax
        shr rax, 16
        mov [rdi + 6], ax
        shr rax, 16
        mov [rdi+8], eax
	ret

UserEntry:
;	mov ax, cs
;	and al ,11b
;	cmp al, 3
;	jne Uend
	inc byte[0xb8004]
	mov byte[0xb8005], 0xE


Uend:
	jmp UserEntry

handler0:
	push rax
	push rbx
	push rcx
	push rdx
	push rsi
	push rdi
	push rbp
	push r8
	push r9
        push r10
        push r11
        push r12
        push r13
        push r14
        push r15

	mov byte[0xb8008], 'D'
	mov byte[0xb8009], 0xc

	pop r15
	pop r14
        pop r13
        pop r12
        pop r11
        pop r10
        pop r9
        pop r8
        pop rbp
        pop rdi
        pop rsi
        pop rdx
        pop rcx
        pop rbx
	pop rax

	iretq


Timer:
	push rax
        push rbx
        push rcx
        push rdx
        push rsi
        push rdi
        push rbp
        push r8
        push r9
        push r10
        push r11
        push r12
        push r13
        push r14
        push r15

	inc byte[0xb8010]
	mov byte[0xb8011], 0xe

	mov al, 0x20
	out 0x20, al

	pop r15
        pop r14
        pop r13
        pop r12
        pop r11
        pop r10
        pop r9
        pop r8
	pop rbp
        pop rdi
        pop rsi
        pop rdx
        pop rcx
        pop rbx
	pop rax
	iretq

SIRQ:
	push rax
        push rbx
        push rcx
        push rdx
        push rsi
        push rdi
        push rbp
        push r8
        push r9
        push r10
        push r11
        push r12
        push r13
        push r14
        push r15

	mov al, 11
	out 0x20, al
	in al, 0x20

	test al, (1<<7)
	jz .end
	mov al, 0x20
	out 0x20, al

.end:
	pop r15
        pop r14
        pop r13
        pop r12
        pop r11
        pop r10
        pop r9
        pop r8
	pop rbp
        pop rdi
        pop rsi
        pop rdx
        pop rcx
        pop rbx
	pop rax

	iretq


Idt:
	%rep 256
		dw 0
		dw 0x8
		db 0
		db 0x8e
		dw 0
		dd 0
		dd 0
	%endrep

IdtLen: equ $-Idt

Idtptr: dw IdtLen-1
	dq Idt

