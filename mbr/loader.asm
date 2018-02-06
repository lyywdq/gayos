%include "boot.inc"
LOADER_BASE_ADDR equ 0x1000
section loader vstart=LOADER_BASE_ADDR

jmp loader_start

times 512-($-$$) db 0

gdt_addr:
GDT_BASE:   dd 0x00000000
            dd 0x00000000
CODE_DESC:  dd 0x0000FFFF
            dd DESC_CODE_HIGH4
DATA_DESC:  dd 0x0000FFFF
            dd DESC_DATA_HIGH4
DISPLAY_DESC:   dd 0x8000FFFF
                dd DESC_DISPLAY_HIGH4

times 60 dq 0

GDT_SIZE equ $ - GDT_BASE
GDT_LIMIT equ GDT_SIZE - 1

gdt_ptr dw GDT_LIMIT
        dd GDT_BASE
memory_table_size dw 0


KERNEL_CS equ 0x8
KERNEL_DS equ 0x10
KERNEL_DISPLAY equ 0x18


loader_start:
    mov si,message
    call fast_print_string
    call get_memory

;¿ªA20
mov dx,0x92
in al,dx
or al,0000_0010B
out dx,al

lgdt [gdt_ptr]

;¿ªPE
mov eax,cr0
or eax,0x1
mov cr0,eax

jmp dword KERNEL_CS:p_mode_start


message:	db	"<IN LOADER>",0
fast_print_string:
	;si:address of string
	push ds;
	mov bx,0x0;
	mov dl,0x20;
	mov ax,0;
	mov ds,ax;
do_char_print:
	mov dh,[si];
	cmp dh,0;
	je print_string_ret
	mov [gs:bx],dh;	
	inc bx;
	mov [gs:bx],dl;
	inc bx;

	inc si;
	jmp do_char_print
print_string_ret:
	pop ds;
	ret

;e820
;0 addr low32
;4 addr high32
;8 len low32
;12 len high32
;16 type
AddressRangeMemory equ 1
get_memory:
    xor ebx,ebx;
    mov ax,0x3000;
    mov es,ax;
    mov edi,0x0;

.continue_get_memory:
    mov edx,0x534d4150;
    mov ecx,0x14;
    mov eax,0xE820;
    int 0x15;
    add di,0x14;
    cmp ebx,0x0;
    jne .continue_get_memory

    mov word [memory_table_size],di;


    ret;

    


[bits 32]
p_mode_start:
    mov ax,KERNEL_DS
    mov ds,ax
    mov es,ax
    mov ss,ax
    mov esp,LOADER_BASE_ADDR
    mov ax,KERNEL_DISPLAY
    mov gs,ax

    mov byte [gs:0x0],'I';
    mov byte [gs:0x2],'N';
    mov byte [gs:0x4],' ';
    mov byte [gs:0x6],'P';
    mov byte [gs:0x8],'R';
    mov byte [gs:0x10],'O';
    mov byte [gs:0x12],'T';
    mov byte [gs:0x14],'E';
    mov byte [gs:0x16],'C';
    mov byte [gs:0x18],'T';

    mov esi,test_val;
    mov edi,0;
    call print_32

    jmp $

test_val dd 0x12345678
;esi value address
;edi display address
print_32:
    mov ecx,0x4;
    .again:
    mov byte al,[esi + ecx - 1];

    mov ah,al;
    shr ah,4;
    cmp ah,0xa;
    jb .v0
    add ah,'A';
    jmp .next
    .v0:
    add ah,'0';
    .next:
    mov byte [gs:edi],ah;
    inc edi;
    inc edi;

    mov ah,al;
    and ah,0x0f;
    cmp ah,0xa;
    jb .v02
    add ah,'A';
    jmp .next2
    .v02:
    add ah,'0';
    .next2:
    mov byte [gs:edi],ah;
    inc edi;
    inc edi;

    loop .again
    
    ret;
    



