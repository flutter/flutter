default	rel
%define XMMWORD
%define YMMWORD
%define ZMMWORD
section	.text code align=64

EXTERN	OPENSSL_ia32cap_P

global	asm_RC4

ALIGN	16
asm_RC4:
	mov	QWORD[8+rsp],rdi	;WIN64 prologue
	mov	QWORD[16+rsp],rsi
	mov	rax,rsp
$L$SEH_begin_asm_RC4:
	mov	rdi,rcx
	mov	rsi,rdx
	mov	rdx,r8
	mov	rcx,r9


	or	rsi,rsi
	jne	NEAR $L$entry
	mov	rdi,QWORD[8+rsp]	;WIN64 epilogue
	mov	rsi,QWORD[16+rsp]
	DB	0F3h,0C3h		;repret
$L$entry:
	push	rbx
	push	r12
	push	r13
$L$prologue:
	mov	r11,rsi
	mov	r12,rdx
	mov	r13,rcx
	xor	r10,r10
	xor	rcx,rcx

	lea	rdi,[8+rdi]
	mov	r10b,BYTE[((-8))+rdi]
	mov	cl,BYTE[((-4))+rdi]
	cmp	DWORD[256+rdi],-1
	je	NEAR $L$RC4_CHAR
	mov	r8d,DWORD[OPENSSL_ia32cap_P]
	xor	rbx,rbx
	inc	r10b
	sub	rbx,r10
	sub	r13,r12
	mov	eax,DWORD[r10*4+rdi]
	test	r11,-16
	jz	NEAR $L$loop1
	bt	r8d,30
	jc	NEAR $L$intel
	and	rbx,7
	lea	rsi,[1+r10]
	jz	NEAR $L$oop8
	sub	r11,rbx
$L$oop8_warmup:
	add	cl,al
	mov	edx,DWORD[rcx*4+rdi]
	mov	DWORD[rcx*4+rdi],eax
	mov	DWORD[r10*4+rdi],edx
	add	al,dl
	inc	r10b
	mov	edx,DWORD[rax*4+rdi]
	mov	eax,DWORD[r10*4+rdi]
	xor	dl,BYTE[r12]
	mov	BYTE[r13*1+r12],dl
	lea	r12,[1+r12]
	dec	rbx
	jnz	NEAR $L$oop8_warmup

	lea	rsi,[1+r10]
	jmp	NEAR $L$oop8
ALIGN	16
$L$oop8:
	add	cl,al
	mov	edx,DWORD[rcx*4+rdi]
	mov	DWORD[rcx*4+rdi],eax
	mov	ebx,DWORD[rsi*4+rdi]
	ror	r8,8
	mov	DWORD[r10*4+rdi],edx
	add	dl,al
	mov	r8b,BYTE[rdx*4+rdi]
	add	cl,bl
	mov	edx,DWORD[rcx*4+rdi]
	mov	DWORD[rcx*4+rdi],ebx
	mov	eax,DWORD[4+rsi*4+rdi]
	ror	r8,8
	mov	DWORD[4+r10*4+rdi],edx
	add	dl,bl
	mov	r8b,BYTE[rdx*4+rdi]
	add	cl,al
	mov	edx,DWORD[rcx*4+rdi]
	mov	DWORD[rcx*4+rdi],eax
	mov	ebx,DWORD[8+rsi*4+rdi]
	ror	r8,8
	mov	DWORD[8+r10*4+rdi],edx
	add	dl,al
	mov	r8b,BYTE[rdx*4+rdi]
	add	cl,bl
	mov	edx,DWORD[rcx*4+rdi]
	mov	DWORD[rcx*4+rdi],ebx
	mov	eax,DWORD[12+rsi*4+rdi]
	ror	r8,8
	mov	DWORD[12+r10*4+rdi],edx
	add	dl,bl
	mov	r8b,BYTE[rdx*4+rdi]
	add	cl,al
	mov	edx,DWORD[rcx*4+rdi]
	mov	DWORD[rcx*4+rdi],eax
	mov	ebx,DWORD[16+rsi*4+rdi]
	ror	r8,8
	mov	DWORD[16+r10*4+rdi],edx
	add	dl,al
	mov	r8b,BYTE[rdx*4+rdi]
	add	cl,bl
	mov	edx,DWORD[rcx*4+rdi]
	mov	DWORD[rcx*4+rdi],ebx
	mov	eax,DWORD[20+rsi*4+rdi]
	ror	r8,8
	mov	DWORD[20+r10*4+rdi],edx
	add	dl,bl
	mov	r8b,BYTE[rdx*4+rdi]
	add	cl,al
	mov	edx,DWORD[rcx*4+rdi]
	mov	DWORD[rcx*4+rdi],eax
	mov	ebx,DWORD[24+rsi*4+rdi]
	ror	r8,8
	mov	DWORD[24+r10*4+rdi],edx
	add	dl,al
	mov	r8b,BYTE[rdx*4+rdi]
	add	sil,8
	add	cl,bl
	mov	edx,DWORD[rcx*4+rdi]
	mov	DWORD[rcx*4+rdi],ebx
	mov	eax,DWORD[((-4))+rsi*4+rdi]
	ror	r8,8
	mov	DWORD[28+r10*4+rdi],edx
	add	dl,bl
	mov	r8b,BYTE[rdx*4+rdi]
	add	r10b,8
	ror	r8,8
	sub	r11,8

	xor	r8,QWORD[r12]
	mov	QWORD[r13*1+r12],r8
	lea	r12,[8+r12]

	test	r11,-8
	jnz	NEAR $L$oop8
	cmp	r11,0
	jne	NEAR $L$loop1
	jmp	NEAR $L$exit

ALIGN	16
$L$intel:
	test	r11,-32
	jz	NEAR $L$loop1
	and	rbx,15
	jz	NEAR $L$oop16_is_hot
	sub	r11,rbx
$L$oop16_warmup:
	add	cl,al
	mov	edx,DWORD[rcx*4+rdi]
	mov	DWORD[rcx*4+rdi],eax
	mov	DWORD[r10*4+rdi],edx
	add	al,dl
	inc	r10b
	mov	edx,DWORD[rax*4+rdi]
	mov	eax,DWORD[r10*4+rdi]
	xor	dl,BYTE[r12]
	mov	BYTE[r13*1+r12],dl
	lea	r12,[1+r12]
	dec	rbx
	jnz	NEAR $L$oop16_warmup

	mov	rbx,rcx
	xor	rcx,rcx
	mov	cl,bl

$L$oop16_is_hot:
	lea	rsi,[r10*4+rdi]
	add	cl,al
	mov	edx,DWORD[rcx*4+rdi]
	pxor	xmm0,xmm0
	mov	DWORD[rcx*4+rdi],eax
	add	al,dl
	mov	ebx,DWORD[4+rsi]
	movzx	eax,al
	mov	DWORD[rsi],edx
	add	cl,bl
	pinsrw	xmm0,WORD[rax*4+rdi],0
	jmp	NEAR $L$oop16_enter
ALIGN	16
$L$oop16:
	add	cl,al
	mov	edx,DWORD[rcx*4+rdi]
	pxor	xmm2,xmm0
	psllq	xmm1,8
	pxor	xmm0,xmm0
	mov	DWORD[rcx*4+rdi],eax
	add	al,dl
	mov	ebx,DWORD[4+rsi]
	movzx	eax,al
	mov	DWORD[rsi],edx
	pxor	xmm2,xmm1
	add	cl,bl
	pinsrw	xmm0,WORD[rax*4+rdi],0
	movdqu	XMMWORD[r13*1+r12],xmm2
	lea	r12,[16+r12]
$L$oop16_enter:
	mov	edx,DWORD[rcx*4+rdi]
	pxor	xmm1,xmm1
	mov	DWORD[rcx*4+rdi],ebx
	add	bl,dl
	mov	eax,DWORD[8+rsi]
	movzx	ebx,bl
	mov	DWORD[4+rsi],edx
	add	cl,al
	pinsrw	xmm1,WORD[rbx*4+rdi],0
	mov	edx,DWORD[rcx*4+rdi]
	mov	DWORD[rcx*4+rdi],eax
	add	al,dl
	mov	ebx,DWORD[12+rsi]
	movzx	eax,al
	mov	DWORD[8+rsi],edx
	add	cl,bl
	pinsrw	xmm0,WORD[rax*4+rdi],1
	mov	edx,DWORD[rcx*4+rdi]
	mov	DWORD[rcx*4+rdi],ebx
	add	bl,dl
	mov	eax,DWORD[16+rsi]
	movzx	ebx,bl
	mov	DWORD[12+rsi],edx
	add	cl,al
	pinsrw	xmm1,WORD[rbx*4+rdi],1
	mov	edx,DWORD[rcx*4+rdi]
	mov	DWORD[rcx*4+rdi],eax
	add	al,dl
	mov	ebx,DWORD[20+rsi]
	movzx	eax,al
	mov	DWORD[16+rsi],edx
	add	cl,bl
	pinsrw	xmm0,WORD[rax*4+rdi],2
	mov	edx,DWORD[rcx*4+rdi]
	mov	DWORD[rcx*4+rdi],ebx
	add	bl,dl
	mov	eax,DWORD[24+rsi]
	movzx	ebx,bl
	mov	DWORD[20+rsi],edx
	add	cl,al
	pinsrw	xmm1,WORD[rbx*4+rdi],2
	mov	edx,DWORD[rcx*4+rdi]
	mov	DWORD[rcx*4+rdi],eax
	add	al,dl
	mov	ebx,DWORD[28+rsi]
	movzx	eax,al
	mov	DWORD[24+rsi],edx
	add	cl,bl
	pinsrw	xmm0,WORD[rax*4+rdi],3
	mov	edx,DWORD[rcx*4+rdi]
	mov	DWORD[rcx*4+rdi],ebx
	add	bl,dl
	mov	eax,DWORD[32+rsi]
	movzx	ebx,bl
	mov	DWORD[28+rsi],edx
	add	cl,al
	pinsrw	xmm1,WORD[rbx*4+rdi],3
	mov	edx,DWORD[rcx*4+rdi]
	mov	DWORD[rcx*4+rdi],eax
	add	al,dl
	mov	ebx,DWORD[36+rsi]
	movzx	eax,al
	mov	DWORD[32+rsi],edx
	add	cl,bl
	pinsrw	xmm0,WORD[rax*4+rdi],4
	mov	edx,DWORD[rcx*4+rdi]
	mov	DWORD[rcx*4+rdi],ebx
	add	bl,dl
	mov	eax,DWORD[40+rsi]
	movzx	ebx,bl
	mov	DWORD[36+rsi],edx
	add	cl,al
	pinsrw	xmm1,WORD[rbx*4+rdi],4
	mov	edx,DWORD[rcx*4+rdi]
	mov	DWORD[rcx*4+rdi],eax
	add	al,dl
	mov	ebx,DWORD[44+rsi]
	movzx	eax,al
	mov	DWORD[40+rsi],edx
	add	cl,bl
	pinsrw	xmm0,WORD[rax*4+rdi],5
	mov	edx,DWORD[rcx*4+rdi]
	mov	DWORD[rcx*4+rdi],ebx
	add	bl,dl
	mov	eax,DWORD[48+rsi]
	movzx	ebx,bl
	mov	DWORD[44+rsi],edx
	add	cl,al
	pinsrw	xmm1,WORD[rbx*4+rdi],5
	mov	edx,DWORD[rcx*4+rdi]
	mov	DWORD[rcx*4+rdi],eax
	add	al,dl
	mov	ebx,DWORD[52+rsi]
	movzx	eax,al
	mov	DWORD[48+rsi],edx
	add	cl,bl
	pinsrw	xmm0,WORD[rax*4+rdi],6
	mov	edx,DWORD[rcx*4+rdi]
	mov	DWORD[rcx*4+rdi],ebx
	add	bl,dl
	mov	eax,DWORD[56+rsi]
	movzx	ebx,bl
	mov	DWORD[52+rsi],edx
	add	cl,al
	pinsrw	xmm1,WORD[rbx*4+rdi],6
	mov	edx,DWORD[rcx*4+rdi]
	mov	DWORD[rcx*4+rdi],eax
	add	al,dl
	mov	ebx,DWORD[60+rsi]
	movzx	eax,al
	mov	DWORD[56+rsi],edx
	add	cl,bl
	pinsrw	xmm0,WORD[rax*4+rdi],7
	add	r10b,16
	movdqu	xmm2,XMMWORD[r12]
	mov	edx,DWORD[rcx*4+rdi]
	mov	DWORD[rcx*4+rdi],ebx
	add	bl,dl
	movzx	ebx,bl
	mov	DWORD[60+rsi],edx
	lea	rsi,[r10*4+rdi]
	pinsrw	xmm1,WORD[rbx*4+rdi],7
	mov	eax,DWORD[rsi]
	mov	rbx,rcx
	xor	rcx,rcx
	sub	r11,16
	mov	cl,bl
	test	r11,-16
	jnz	NEAR $L$oop16

	psllq	xmm1,8
	pxor	xmm2,xmm0
	pxor	xmm2,xmm1
	movdqu	XMMWORD[r13*1+r12],xmm2
	lea	r12,[16+r12]

	cmp	r11,0
	jne	NEAR $L$loop1
	jmp	NEAR $L$exit

ALIGN	16
$L$loop1:
	add	cl,al
	mov	edx,DWORD[rcx*4+rdi]
	mov	DWORD[rcx*4+rdi],eax
	mov	DWORD[r10*4+rdi],edx
	add	al,dl
	inc	r10b
	mov	edx,DWORD[rax*4+rdi]
	mov	eax,DWORD[r10*4+rdi]
	xor	dl,BYTE[r12]
	mov	BYTE[r13*1+r12],dl
	lea	r12,[1+r12]
	dec	r11
	jnz	NEAR $L$loop1
	jmp	NEAR $L$exit

ALIGN	16
$L$RC4_CHAR:
	add	r10b,1
	movzx	eax,BYTE[r10*1+rdi]
	test	r11,-8
	jz	NEAR $L$cloop1
	jmp	NEAR $L$cloop8
ALIGN	16
$L$cloop8:
	mov	r8d,DWORD[r12]
	mov	r9d,DWORD[4+r12]
	add	cl,al
	lea	rsi,[1+r10]
	movzx	edx,BYTE[rcx*1+rdi]
	movzx	esi,sil
	movzx	ebx,BYTE[rsi*1+rdi]
	mov	BYTE[rcx*1+rdi],al
	cmp	rcx,rsi
	mov	BYTE[r10*1+rdi],dl
	jne	NEAR $L$cmov0
	mov	rbx,rax
$L$cmov0:
	add	dl,al
	xor	r8b,BYTE[rdx*1+rdi]
	ror	r8d,8
	add	cl,bl
	lea	r10,[1+rsi]
	movzx	edx,BYTE[rcx*1+rdi]
	movzx	r10d,r10b
	movzx	eax,BYTE[r10*1+rdi]
	mov	BYTE[rcx*1+rdi],bl
	cmp	rcx,r10
	mov	BYTE[rsi*1+rdi],dl
	jne	NEAR $L$cmov1
	mov	rax,rbx
$L$cmov1:
	add	dl,bl
	xor	r8b,BYTE[rdx*1+rdi]
	ror	r8d,8
	add	cl,al
	lea	rsi,[1+r10]
	movzx	edx,BYTE[rcx*1+rdi]
	movzx	esi,sil
	movzx	ebx,BYTE[rsi*1+rdi]
	mov	BYTE[rcx*1+rdi],al
	cmp	rcx,rsi
	mov	BYTE[r10*1+rdi],dl
	jne	NEAR $L$cmov2
	mov	rbx,rax
$L$cmov2:
	add	dl,al
	xor	r8b,BYTE[rdx*1+rdi]
	ror	r8d,8
	add	cl,bl
	lea	r10,[1+rsi]
	movzx	edx,BYTE[rcx*1+rdi]
	movzx	r10d,r10b
	movzx	eax,BYTE[r10*1+rdi]
	mov	BYTE[rcx*1+rdi],bl
	cmp	rcx,r10
	mov	BYTE[rsi*1+rdi],dl
	jne	NEAR $L$cmov3
	mov	rax,rbx
$L$cmov3:
	add	dl,bl
	xor	r8b,BYTE[rdx*1+rdi]
	ror	r8d,8
	add	cl,al
	lea	rsi,[1+r10]
	movzx	edx,BYTE[rcx*1+rdi]
	movzx	esi,sil
	movzx	ebx,BYTE[rsi*1+rdi]
	mov	BYTE[rcx*1+rdi],al
	cmp	rcx,rsi
	mov	BYTE[r10*1+rdi],dl
	jne	NEAR $L$cmov4
	mov	rbx,rax
$L$cmov4:
	add	dl,al
	xor	r9b,BYTE[rdx*1+rdi]
	ror	r9d,8
	add	cl,bl
	lea	r10,[1+rsi]
	movzx	edx,BYTE[rcx*1+rdi]
	movzx	r10d,r10b
	movzx	eax,BYTE[r10*1+rdi]
	mov	BYTE[rcx*1+rdi],bl
	cmp	rcx,r10
	mov	BYTE[rsi*1+rdi],dl
	jne	NEAR $L$cmov5
	mov	rax,rbx
$L$cmov5:
	add	dl,bl
	xor	r9b,BYTE[rdx*1+rdi]
	ror	r9d,8
	add	cl,al
	lea	rsi,[1+r10]
	movzx	edx,BYTE[rcx*1+rdi]
	movzx	esi,sil
	movzx	ebx,BYTE[rsi*1+rdi]
	mov	BYTE[rcx*1+rdi],al
	cmp	rcx,rsi
	mov	BYTE[r10*1+rdi],dl
	jne	NEAR $L$cmov6
	mov	rbx,rax
$L$cmov6:
	add	dl,al
	xor	r9b,BYTE[rdx*1+rdi]
	ror	r9d,8
	add	cl,bl
	lea	r10,[1+rsi]
	movzx	edx,BYTE[rcx*1+rdi]
	movzx	r10d,r10b
	movzx	eax,BYTE[r10*1+rdi]
	mov	BYTE[rcx*1+rdi],bl
	cmp	rcx,r10
	mov	BYTE[rsi*1+rdi],dl
	jne	NEAR $L$cmov7
	mov	rax,rbx
$L$cmov7:
	add	dl,bl
	xor	r9b,BYTE[rdx*1+rdi]
	ror	r9d,8
	lea	r11,[((-8))+r11]
	mov	DWORD[r13],r8d
	lea	r12,[8+r12]
	mov	DWORD[4+r13],r9d
	lea	r13,[8+r13]

	test	r11,-8
	jnz	NEAR $L$cloop8
	cmp	r11,0
	jne	NEAR $L$cloop1
	jmp	NEAR $L$exit
ALIGN	16
$L$cloop1:
	add	cl,al
	movzx	ecx,cl
	movzx	edx,BYTE[rcx*1+rdi]
	mov	BYTE[rcx*1+rdi],al
	mov	BYTE[r10*1+rdi],dl
	add	dl,al
	add	r10b,1
	movzx	edx,dl
	movzx	r10d,r10b
	movzx	edx,BYTE[rdx*1+rdi]
	movzx	eax,BYTE[r10*1+rdi]
	xor	dl,BYTE[r12]
	lea	r12,[1+r12]
	mov	BYTE[r13],dl
	lea	r13,[1+r13]
	sub	r11,1
	jnz	NEAR $L$cloop1
	jmp	NEAR $L$exit

ALIGN	16
$L$exit:
	sub	r10b,1
	mov	DWORD[((-8))+rdi],r10d
	mov	DWORD[((-4))+rdi],ecx

	mov	r13,QWORD[rsp]
	mov	r12,QWORD[8+rsp]
	mov	rbx,QWORD[16+rsp]
	add	rsp,24
$L$epilogue:
	mov	rdi,QWORD[8+rsp]	;WIN64 epilogue
	mov	rsi,QWORD[16+rsp]
	DB	0F3h,0C3h		;repret
$L$SEH_end_asm_RC4:
global	asm_RC4_set_key

ALIGN	16
asm_RC4_set_key:
	mov	QWORD[8+rsp],rdi	;WIN64 prologue
	mov	QWORD[16+rsp],rsi
	mov	rax,rsp
$L$SEH_begin_asm_RC4_set_key:
	mov	rdi,rcx
	mov	rsi,rdx
	mov	rdx,r8


	lea	rdi,[8+rdi]
	lea	rdx,[rsi*1+rdx]
	neg	rsi
	mov	rcx,rsi
	xor	eax,eax
	xor	r9,r9
	xor	r10,r10
	xor	r11,r11

	mov	r8d,DWORD[OPENSSL_ia32cap_P]
	bt	r8d,20
	jc	NEAR $L$c1stloop
	jmp	NEAR $L$w1stloop

ALIGN	16
$L$w1stloop:
	mov	DWORD[rax*4+rdi],eax
	add	al,1
	jnc	NEAR $L$w1stloop

	xor	r9,r9
	xor	r8,r8
ALIGN	16
$L$w2ndloop:
	mov	r10d,DWORD[r9*4+rdi]
	add	r8b,BYTE[rsi*1+rdx]
	add	r8b,r10b
	add	rsi,1
	mov	r11d,DWORD[r8*4+rdi]
	cmovz	rsi,rcx
	mov	DWORD[r8*4+rdi],r10d
	mov	DWORD[r9*4+rdi],r11d
	add	r9b,1
	jnc	NEAR $L$w2ndloop
	jmp	NEAR $L$exit_key

ALIGN	16
$L$c1stloop:
	mov	BYTE[rax*1+rdi],al
	add	al,1
	jnc	NEAR $L$c1stloop

	xor	r9,r9
	xor	r8,r8
ALIGN	16
$L$c2ndloop:
	mov	r10b,BYTE[r9*1+rdi]
	add	r8b,BYTE[rsi*1+rdx]
	add	r8b,r10b
	add	rsi,1
	mov	r11b,BYTE[r8*1+rdi]
	jnz	NEAR $L$cnowrap
	mov	rsi,rcx
$L$cnowrap:
	mov	BYTE[r8*1+rdi],r10b
	mov	BYTE[r9*1+rdi],r11b
	add	r9b,1
	jnc	NEAR $L$c2ndloop
	mov	DWORD[256+rdi],-1

ALIGN	16
$L$exit_key:
	xor	eax,eax
	mov	DWORD[((-8))+rdi],eax
	mov	DWORD[((-4))+rdi],eax
	mov	rdi,QWORD[8+rsp]	;WIN64 epilogue
	mov	rsi,QWORD[16+rsp]
	DB	0F3h,0C3h		;repret
$L$SEH_end_asm_RC4_set_key:
EXTERN	__imp_RtlVirtualUnwind

ALIGN	16
stream_se_handler:
	push	rsi
	push	rdi
	push	rbx
	push	rbp
	push	r12
	push	r13
	push	r14
	push	r15
	pushfq
	sub	rsp,64

	mov	rax,QWORD[120+r8]
	mov	rbx,QWORD[248+r8]

	lea	r10,[$L$prologue]
	cmp	rbx,r10
	jb	NEAR $L$in_prologue

	mov	rax,QWORD[152+r8]

	lea	r10,[$L$epilogue]
	cmp	rbx,r10
	jae	NEAR $L$in_prologue

	lea	rax,[24+rax]

	mov	rbx,QWORD[((-8))+rax]
	mov	r12,QWORD[((-16))+rax]
	mov	r13,QWORD[((-24))+rax]
	mov	QWORD[144+r8],rbx
	mov	QWORD[216+r8],r12
	mov	QWORD[224+r8],r13

$L$in_prologue:
	mov	rdi,QWORD[8+rax]
	mov	rsi,QWORD[16+rax]
	mov	QWORD[152+r8],rax
	mov	QWORD[168+r8],rsi
	mov	QWORD[176+r8],rdi

	jmp	NEAR $L$common_seh_exit



ALIGN	16
key_se_handler:
	push	rsi
	push	rdi
	push	rbx
	push	rbp
	push	r12
	push	r13
	push	r14
	push	r15
	pushfq
	sub	rsp,64

	mov	rax,QWORD[152+r8]
	mov	rdi,QWORD[8+rax]
	mov	rsi,QWORD[16+rax]
	mov	QWORD[168+r8],rsi
	mov	QWORD[176+r8],rdi

$L$common_seh_exit:

	mov	rdi,QWORD[40+r9]
	mov	rsi,r8
	mov	ecx,154
	DD	0xa548f3fc

	mov	rsi,r9
	xor	rcx,rcx
	mov	rdx,QWORD[8+rsi]
	mov	r8,QWORD[rsi]
	mov	r9,QWORD[16+rsi]
	mov	r10,QWORD[40+rsi]
	lea	r11,[56+rsi]
	lea	r12,[24+rsi]
	mov	QWORD[32+rsp],r10
	mov	QWORD[40+rsp],r11
	mov	QWORD[48+rsp],r12
	mov	QWORD[56+rsp],rcx
	call	QWORD[__imp_RtlVirtualUnwind]

	mov	eax,1
	add	rsp,64
	popfq
	pop	r15
	pop	r14
	pop	r13
	pop	r12
	pop	rbp
	pop	rbx
	pop	rdi
	pop	rsi
	DB	0F3h,0C3h		;repret


section	.pdata rdata align=4
ALIGN	4
	DD	$L$SEH_begin_asm_RC4 wrt ..imagebase
	DD	$L$SEH_end_asm_RC4 wrt ..imagebase
	DD	$L$SEH_info_asm_RC4 wrt ..imagebase

	DD	$L$SEH_begin_asm_RC4_set_key wrt ..imagebase
	DD	$L$SEH_end_asm_RC4_set_key wrt ..imagebase
	DD	$L$SEH_info_asm_RC4_set_key wrt ..imagebase

section	.xdata rdata align=8
ALIGN	8
$L$SEH_info_asm_RC4:
DB	9,0,0,0
	DD	stream_se_handler wrt ..imagebase
$L$SEH_info_asm_RC4_set_key:
DB	9,0,0,0
	DD	key_se_handler wrt ..imagebase
