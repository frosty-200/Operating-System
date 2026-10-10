[BITS 16]
[ORG 0x7e00]

start:
    mov [DriveId],dl

    mov eax,0x80000000
    cpuid
    cmp eax,0x80000001
    jb NotSupport

    mov eax,0x80000001
    cpuid
    test edx,(1<<29)
    jz NotSupport
    test edx,(1<<26)
    jz NotSupport

LoadKernel:
    mov si,ReadPacket
    mov word[si],0x10
    mov word[si+2],100
    mov word[si+4],0
    mov word[si+6],0x1000
    mov dword[si+8],6
    mov dword[si+0xc],0
    mov dl,[DriveId]
    mov ah,0x42
    int 0x13
    jc  ReadError

LoadUser:
    mov si,ReadPacket
    mov word[si],0x10
    mov word[si+2],10
    mov word[si+4],0
    mov word[si+6],0x2000
    mov dword[si+8],106
    mov dword[si+0xc],0
    mov dl,[DriveId]
    mov ah,0x42
    int 0x13
    jc  ReadError

LoadUser2:
    mov si,ReadPacket
    mov word[si],0x10
    mov word[si+2],10
    mov word[si+4],0
    mov word[si+6],0x3000
    mov dword[si+8],116
    mov dword[si+0xc],0
    mov dl,[DriveId]
    mov ah,0x42
    int 0x13
    jc  ReadError
    
LoadUser3:
    mov si,ReadPacket
    mov word[si],0x10
    mov word[si+2],10
    mov word[si+4],0
    mov word[si+6],0x4000
    mov dword[si+8],126
    mov dword[si+0xc],0
    mov dl,[DriveId]
    mov ah,0x42
    int 0x13
    jc  ReadError
    
LoadUser4:
	mov si, ReadPacket
	mov word[si], 0x10
	mov word[si+2], 10
	mov word[si+4], 0
	mov word[si+6], 0x5000
	mov dword[si+8], 136
	mov dword[si+0xc], 0
	mov dl, [DriveId]
	mov ah, 0x42
	int 0x13
	jc ReadError

GetMemInfoStart:
	xor ax, ax
	mov es, ax
    	mov eax,0xe820
    	mov edx,0x534d4150
    	mov ecx,20
    	mov dword[0x9000],0
    	mov edi,0x9008
    	xor ebx,ebx
   	int 0x15
   	jc NotSupport

GetMemInfo:
    add edi,20
    inc dword[0x9000]   
    test ebx,ebx
    jz GetMemDone

    mov eax,0xe820
    mov edx,0x534d4150
    mov ecx,20
    int 0x15
    jnc GetMemInfo


GetMemDone:
TestA20:
    mov ax,0xffff
    mov es,ax
    mov word[ds:0x7c00],0xa200
    cmp word[es:0x7c10],0xa200
    jne SetA20LineDone
    mov word[0x7c00],0xb200
    cmp word[es:0x7c10],0xb200
    je End
    
SetA20LineDone:
    xor ax,ax
    mov es,ax

SetVideoMode:
    mov ax,3
    int 0x10
    
    cli
    lgdt [Gdt32Ptr]
    lidt [Idt32Ptr]

    mov eax,cr0
    or eax,1
    mov cr0,eax

    jmp 8:PMEntry

ReadError:
NotSupport:
End:
    hlt
    jmp End


[BITS 32]
PMEntry:
    mov ax,0x10
    mov ds,ax
    mov es,ax
    mov ss,ax
    mov esp,0x7c00
    cld

    ; zero PML4 (0x70000) and PDPT (0x71000) - 2 pages = 0x2000 bytes
    mov edi,0x70000
    xor eax,eax
    mov ecx,0x2000/4
    rep stosd			
    ; ---- walk E820 map to find highest physical address ----
    mov dword[MaxAddrLow],0
    mov dword[MaxAddrHigh],0

    mov ecx,[0x9000]      ; number of E820 entries
    mov esi,0x9008        ; first entry
    test ecx,ecx
    jz DoneE820

E820Loop:
    mov eax,[esi]         ; region base (low)
    mov edx,[esi+4]       ; region base (high)
    add eax,[esi+8]       ; + length (low)
    adc edx,[esi+12]      ; + length (high), with carry
    			  ; edx:eax = end address of this region

    cmp edx,[MaxAddrHigh]
    ja NewMax
    jb NotMax
    cmp eax,[MaxAddrLow]
    jbe NotMax
NewMax:
    mov [MaxAddrHigh],edx
    mov [MaxAddrLow],eax
NotMax:
    add esi,20
    dec ecx
    jnz E820Loop
DoneE820:

    ; ---- convert max address to a GB count (rounded up) ----
    mov edx,[MaxAddrHigh]
    mov eax,[MaxAddrLow]
    mov ecx,eax
    shl edx,2             ; high dword * 4 = whole GBs from bits above 32
    shr eax,30            ; whole GBs from low dword (0-3)
    add edx,eax
    and ecx,0x3FFFFFFF    ; leftover bits within a GB
    jz NoRoundUp
    inc edx               ; partial GB -> round up
NoRoundUp:

    cmp edx,4
    jae NumGBOk1
    mov edx,4             ; always map at least 4GB
NumGBOk1:
    cmp edx,512
    jbe NumGBOk2
    mov edx,512           ; one PDPT tops out at 512GB
NumGBOk2:
    mov [NumGB],edx

    ; ---- fill the PDPT with 1GB identity-mapped pages ----
    mov ecx,[NumGB]
    xor esi,esi
    mov edi,0x71000
BuildPDPT:
    mov eax,esi
    mov edx,eax
    and eax,3
    shl eax,30
    or eax,10000011b      ; present + writable + PS(1GB page)
    shr edx,2
    mov [edi],eax
    mov [edi+4],edx
    add edi,8
    inc esi
    loop BuildPDPT

    ; ---- point PML4 entries at the PDPT ----
    mov dword[0x70000],0x71003
    mov eax,(0xffff800000000000>>39)
    and eax,0x1ff
    mov dword[0x70000+eax*8],0x71003

    lgdt [Gdt64Ptr]
    mov eax,cr4
    or eax,(1<<5)
    mov cr4,eax
    mov eax,0x70000
    mov cr3,eax
    mov ecx,0xc0000080
    rdmsr
    or eax,(1<<8)
    wrmsr
    mov eax,cr0
    or eax,(1<<31)
    mov cr0,eax
    jmp 8:LMEntry
PEnd:
    hlt
    jmp PEnd

[BITS 64]
LMEntry:
    mov rsp,0x7c00

    cld
    mov rdi,0x200000
    mov rsi,0x10000
    mov rcx,51200/8
    rep movsq

    mov rax,0xffff800000200000
    jmp rax
    
LEnd:
    hlt
    jmp LEnd
    
    

DriveId:    db 0
ReadPacket: times 16 db 0

Gdt32:
    dq 0
Code32:
    dw 0xffff
    dw 0
    db 0
    db 0x9a
    db 0xcf
    db 0
Data32:
    dw 0xffff
    dw 0
    db 0
    db 0x92
    db 0xcf
    db 0
    
Gdt32Len: equ $-Gdt32

Gdt32Ptr: dw Gdt32Len-1
          dd Gdt32

Idt32Ptr: dw 0
          dd 0


Gdt64:
    dq 0
    dq 0x0020980000000000

Gdt64Len: equ $-Gdt64


Gdt64Ptr: dw Gdt64Len-1
          dd Gdt64
         
         
MaxAddrLow:  dd 0
MaxAddrHigh: dd 0
NumGB:       dd 0
