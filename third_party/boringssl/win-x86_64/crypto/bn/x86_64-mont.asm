default	rel
%define XMMWORD
%define YMMWORD
%define ZMMWORD
section	.text code align=64


EXTERN	OPENSSL_ia32cap_P

global	bn_mul_mont

ALIGN	16
bn_mul_mont:
	mov	QWORD[8+rsp],rdi	;WIN64 prologue
	mov	QWORD[16+rsp],rsi
	mov	rax,rsp
$L$SEH_begin_bn_mul_mont:
	mov	rdi,rcx
	mov	rsi,rdx
	mov	rdx,r8
	mov	rcx,r9
	mov	r8,QWORD[40+rsp]
	mov	r9,QWORD[48+rsp]


	test	r9d,3
	jnz	NEAR $L$mul_enter
	cmp	r9d,8
	jb	NEAR $L$mul_enter
	cmp	rdx,rsi
	jne	NEAR $L$mul4x_enter
	test	r9d,7
	jz	NEAR $L$sqr8x_enter
	jmp	NEAR $L$mul4x_enter

ALIGN	16
$L$mul_enter:
	push	rbx
	push	rbp
	push	r12
	push	r13
	push	r14
	push	r15

	mov	r9d,r9d
	lea	r10,[2+r9]
	mov	r11,rsp
	neg	r10
	lea	rsp,[r10*8+rsp]
	and	rsp,-1024

	mov	QWORD[8+r9*8+rsp],r11
$L$mul_body:
	mov	r12,rdx
	mov	r8,QWORD[r8]
	mov	rbx,QWORD[r12]
	mov	rax,QWORD[rsi]

	xor	r14,r14
	xor	r15,r15

	mov	rbp,r8
	mul	rbx
	mov	r10,rax
	mov	rax,QWORD[rcx]

	imul	rbp,r10
	mov	r11,rdx

	mul	rbp
	add	r10,rax
	mov	rax,QWORD[8+rsi]
	adc	rdx,0
	mov	r13,rdx

	lea	r15,[1+r15]
	jmp	NEAR $L$1st_enter

ALIGN	16
$L$1st:
	add	r13,rax
	mov	rax,QWORD[r15*8+rsi]
	adc	rdx,0
	add	r13,r11
	mov	r11,r10
	adc	rdx,0
	mov	QWORD[((-16))+r15*8+rsp],r13
	mov	r13,rdx

$L$1st_enter:
	mul	rbx
	add	r11,rax
	mov	rax,QWORD[r15*8+rcx]
	adc	rdx,0
	lea	r15,[1+r15]
	mov	r10,rdx

	mul	rbp
	cmp	r15,r9
	jne	NEAR $L$1st

	add	r13,rax
	mov	rax,QWORD[rsi]
	adc	rdx,0
	add	r13,r11
	adc	rdx,0
	mov	QWORD[((-16))+r15*8+rsp],r13
	mov	r13,rdx
	mov	r11,r10

	xor	rdx,rdx
	add	r13,r11
	adc	rdx,0
	mov	QWORD[((-8))+r9*8+rsp],r13
	mov	QWORD[r9*8+rsp],rdx

	lea	r14,[1+r14]
	jmp	NEAR $L$outer
ALIGN	16
$L$outer:
	mov	rbx,QWORD[r14*8+r12]
	xor	r15,r15
	mov	rbp,r8
	mov	r10,QWORD[rsp]
	mul	rbx
	add	r10,rax
	mov	rax,QWORD[rcx]
	adc	rdx,0

	imul	rbp,r10
	mov	r11,rdx

	mul	rbp
	add	r10,rax
	mov	rax,QWORD[8+rsi]
	adc	rdx,0
	mov	r10,QWORD[8+rsp]
	mov	r13,rdx

	lea	r15,[1+r15]
	jmp	NEAR $L$inner_enter

ALIGN	16
$L$inner:
	add	r13,rax
	mov	rax,QWORD[r15*8+rsi]
	adc	rdx,0
	add	r13,r10
	mov	r10,QWORD[r15*8+rsp]
	adc	rdx,0
	mov	QWORD[((-16))+r15*8+rsp],r13
	mov	r13,rdx

$L$inner_enter:
	mul	rbx
	add	r11,rax
	mov	rax,QWORD[r15*8+rcx]
	adc	rdx,0
	add	r10,r11
	mov	r11,rdx
	adc	r11,0
	lea	r15,[1+r15]

	mul	rbp
	cmp	r15,r9
	jne	NEAR $L$inner

	add	r13,rax
	mov	rax,QWORD[rsi]
	adc	rdx,0
	add	r13,r10
	mov	r10,QWORD[r15*8+rsp]
	adc	rdx,0
	mov	QWORD[((-16))+r15*8+rsp],r13
	mov	r13,rdx

	xor	rdx,rdx
	add	r13,r11
	adc	rdx,0
	add	r13,r10
	adc	rdx,0
	mov	QWORD[((-8))+r9*8+rsp],r13
	mov	QWORD[r9*8+rsp],rdx

	lea	r14,[1+r14]
	cmp	r14,r9
	jb	NEAR $L$outer

	xor	r14,r14
	mov	rax,QWORD[rsp]
	lea	rsi,[rsp]
	mov	r15,r9
	jmp	NEAR $L$sub
ALIGN	16
$L$sub:	sbb	rax,QWORD[r14*8+rcx]
	mov	QWORD[r14*8+rdi],rax
	mov	rax,QWORD[8+r14*8+rsi]
	lea	r14,[1+r14]
	dec	r15
	jnz	NEAR $L$sub

	sbb	rax,0
	xor	r14,r14
	mov	r15,r9
ALIGN	16
$L$copy:
	mov	rsi,QWORD[r14*8+rsp]
	mov	rcx,QWORD[r14*8+rdi]
	xor	rsi,rcx
	and	rsi,rax
	xor	rsi,rcx
	mov	QWORD[r14*8+rsp],r14
	mov	QWORD[r14*8+rdi],rsi
	lea	r14,[1+r14]
	sub	r15,1
	jnz	NEAR $L$copy

	mov	rsi,QWORD[8+r9*8+rsp]
	mov	rax,1
	mov	r15,QWORD[rsi]
	mov	r14,QWORD[8+rsi]
	mov	r13,QWORD[16+rsi]
	mov	r12,QWORD[24+rsi]
	mov	rbp,QWORD[32+rsi]
	mov	rbx,QWORD[40+rsi]
	lea	rsp,[48+rsi]
$L$mul_epilogue:
	mov	rdi,QWORD[8+rsp]	;WIN64 epilogue
	mov	rsi,QWORD[16+rsp]
	DB	0F3h,0C3h		;repret
$L$SEH_end_bn_mul_mont:

ALIGN	16
bn_mul4x_mont:
	mov	QWORD[8+rsp],rdi	;WIN64 prologue
	mov	QWORD[16+rsp],rsi
	mov	rax,rsp
$L$SEH_begin_bn_mul4x_mont:
	mov	rdi,rcx
	mov	rsi,rdx
	mov	rdx,r8
	mov	rcx,r9
	mov	r8,QWORD[40+rsp]
	mov	r9,QWORD[48+rsp]


$L$mul4x_enter:
	push	rbx
	push	rbp
	push	r12
	push	r13
	push	r14
	push	r15

	mov	r9d,r9d
	lea	r10,[4+r9]
	mov	r11,rsp
	neg	r10
	lea	rsp,[r10*8+rsp]
	and	rsp,-1024

	mov	QWORD[8+r9*8+rsp],r11
$L$mul4x_body:
	mov	QWORD[16+r9*8+rsp],rdi
	mov	r12,rdx
	mov	r8,QWORD[r8]
	mov	rbx,QWORD[r12]
	mov	rax,QWORD[rsi]

	xor	r14,r14
	xor	r15,r15

	mov	rbp,r8
	mul	rbx
	mov	r10,rax
	mov	rax,QWORD[rcx]

	imul	rbp,r10
	mov	r11,rdx

	mul	rbp
	add	r10,rax
	mov	rax,QWORD[8+rsi]
	adc	rdx,0
	mov	rdi,rdx

	mul	rbx
	add	r11,rax
	mov	rax,QWORD[8+rcx]
	adc	rdx,0
	mov	r10,rdx

	mul	rbp
	add	rdi,rax
	mov	rax,QWORD[16+rsi]
	adc	rdx,0
	add	rdi,r11
	lea	r15,[4+r15]
	adc	rdx,0
	mov	QWORD[rsp],rdi
	mov	r13,rdx
	jmp	NEAR $L$1st4x
ALIGN	16
$L$1st4x:
	mul	rbx
	add	r10,rax
	mov	rax,QWORD[((-16))+r15*8+rcx]
	adc	rdx,0
	mov	r11,rdx

	mul	rbp
	add	r13,rax
	mov	rax,QWORD[((-8))+r15*8+rsi]
	adc	rdx,0
	add	r13,r10
	adc	rdx,0
	mov	QWORD[((-24))+r15*8+rsp],r13
	mov	rdi,rdx

	mul	rbx
	add	r11,rax
	mov	rax,QWORD[((-8))+r15*8+rcx]
	adc	rdx,0
	mov	r10,rdx

	mul	rbp
	add	rdi,rax
	mov	rax,QWORD[r15*8+rsi]
	adc	rdx,0
	add	rdi,r11
	adc	rdx,0
	mov	QWORD[((-16))+r15*8+rsp],rdi
	mov	r13,rdx

	mul	rbx
	add	r10,rax
	mov	rax,QWORD[r15*8+rcx]
	adc	rdx,0
	mov	r11,rdx

	mul	rbp
	add	r13,rax
	mov	rax,QWORD[8+r15*8+rsi]
	adc	rdx,0
	add	r13,r10
	adc	rdx,0
	mov	QWORD[((-8))+r15*8+rsp],r13
	mov	rdi,rdx

	mul	rbx
	add	r11,rax
	mov	rax,QWORD[8+r15*8+rcx]
	adc	rdx,0
	lea	r15,[4+r15]
	mov	r10,rdx

	mul	rbp
	add	rdi,rax
	mov	rax,QWORD[((-16))+r15*8+rsi]
	adc	rdx,0
	add	rdi,r11
	adc	rdx,0
	mov	QWORD[((-32))+r15*8+rsp],rdi
	mov	r13,rdx
	cmp	r15,r9
	jb	NEAR $L$1st4x

	mul	rbx
	add	r10,rax
	mov	rax,QWORD[((-16))+r15*8+rcx]
	adc	rdx,0
	mov	r11,rdx

	mul	rbp
	add	r13,rax
	mov	rax,QWORD[((-8))+r15*8+rsi]
	adc	rdx,0
	add	r13,r10
	adc	rdx,0
	mov	QWORD[((-24))+r15*8+rsp],r13
	mov	rdi,rdx

	mul	rbx
	add	r11,rax
	mov	rax,QWORD[((-8))+r15*8+rcx]
	adc	rdx,0
	mov	r10,rdx

	mul	rbp
	add	rdi,rax
	mov	rax,QWORD[rsi]
	adc	rdx,0
	add	rdi,r11
	adc	rdx,0
	mov	QWORD[((-16))+r15*8+rsp],rdi
	mov	r13,rdx

	xor	rdi,rdi
	add	r13,r10
	adc	rdi,0
	mov	QWORD[((-8))+r15*8+rsp],r13
	mov	QWORD[r15*8+rsp],rdi

	lea	r14,[1+r14]
ALIGN	4
$L$outer4x:
	mov	rbx,QWORD[r14*8+r12]
	xor	r15,r15
	mov	r10,QWORD[rsp]
	mov	rbp,r8
	mul	rbx
	add	r10,rax
	mov	rax,QWORD[rcx]
	adc	rdx,0

	imul	rbp,r10
	mov	r11,rdx

	mul	rbp
	add	r10,rax
	mov	rax,QWORD[8+rsi]
	adc	rdx,0
	mov	rdi,rdx

	mul	rbx
	add	r11,rax
	mov	rax,QWORD[8+rcx]
	adc	rdx,0
	add	r11,QWORD[8+rsp]
	adc	rdx,0
	mov	r10,rdx

	mul	rbp
	add	rdi,rax
	mov	rax,QWORD[16+rsi]
	adc	rdx,0
	add	rdi,r11
	lea	r15,[4+r15]
	adc	rdx,0
	mov	QWORD[rsp],rdi
	mov	r13,rdx
	jmp	NEAR $L$inner4x
ALIGN	16
$L$inner4x:
	mul	rbx
	add	r10,rax
	mov	rax,QWORD[((-16))+r15*8+rcx]
	adc	rdx,0
	add	r10,QWORD[((-16))+r15*8+rsp]
	adc	rdx,0
	mov	r11,rdx

	mul	rbp
	add	r13,rax
	mov	rax,QWORD[((-8))+r15*8+rsi]
	adc	rdx,0
	add	r13,r10
	adc	rdx,0
	mov	QWORD[((-24))+r15*8+rsp],r13
	mov	rdi,rdx

	mul	rbx
	add	r11,rax
	mov	rax,QWORD[((-8))+r15*8+rcx]
	adc	rdx,0
	add	r11,QWORD[((-8))+r15*8+rsp]
	adc	rdx,0
	mov	r10,rdx

	mul	rbp
	add	rdi,rax
	mov	rax,QWORD[r15*8+rsi]
	adc	rdx,0
	add	rdi,r11
	adc	rdx,0
	mov	QWORD[((-16))+r15*8+rsp],rdi
	mov	r13,rdx

	mul	rbx
	add	r10,rax
	mov	rax,QWORD[r15*8+rcx]
	adc	rdx,0
	add	r10,QWORD[r15*8+rsp]
	adc	rdx,0
	mov	r11,rdx

	mul	rbp
	add	r13,rax
	mov	rax,QWORD[8+r15*8+rsi]
	adc	rdx,0
	add	r13,r10
	adc	rdx,0
	mov	QWORD[((-8))+r15*8+rsp],r13
	mov	rdi,rdx

	mul	rbx
	add	r11,rax
	mov	rax,QWORD[8+r15*8+rcx]
	adc	rdx,0
	add	r11,QWORD[8+r15*8+rsp]
	adc	rdx,0
	lea	r15,[4+r15]
	mov	r10,rdx

	mul	rbp
	add	rdi,rax
	mov	rax,QWORD[((-16))+r15*8+rsi]
	adc	rdx,0
	add	rdi,r11
	adc	rdx,0
	mov	QWORD[((-32))+r15*8+rsp],rdi
	mov	r13,rdx
	cmp	r15,r9
	jb	NEAR $L$inner4x

	mul	rbx
	add	r10,rax
	mov	rax,QWORD[((-16))+r15*8+rcx]
	adc	rdx,0
	add	r10,QWORD[((-16))+r15*8+rsp]
	adc	rdx,0
	mov	r11,rdx

	mul	rbp
	add	r13,rax
	mov	rax,QWORD[((-8))+r15*8+rsi]
	adc	rdx,0
	add	r13,r10
	adc	rdx,0
	mov	QWORD[((-24))+r15*8+rsp],r13
	mov	rdi,rdx

	mul	rbx
	add	r11,rax
	mov	rax,QWORD[((-8))+r15*8+rcx]
	adc	rdx,0
	add	r11,QWORD[((-8))+r15*8+rsp]
	adc	rdx,0
	lea	r14,[1+r14]
	mov	r10,rdx

	mul	rbp
	add	rdi,rax
	mov	rax,QWORD[rsi]
	adc	rdx,0
	add	rdi,r11
	adc	rdx,0
	mov	QWORD[((-16))+r15*8+rsp],rdi
	mov	r13,rdx

	xor	rdi,rdi
	add	r13,r10
	adc	rdi,0
	add	r13,QWORD[r9*8+rsp]
	adc	rdi,0
	mov	QWORD[((-8))+r15*8+rsp],r13
	mov	QWORD[r15*8+rsp],rdi

	cmp	r14,r9
	jb	NEAR $L$outer4x
	mov	rdi,QWORD[16+r9*8+rsp]
	mov	rax,QWORD[rsp]
	mov	rdx,QWORD[8+rsp]
	shr	r9,2
	lea	rsi,[rsp]
	xor	r14,r14

	sub	rax,QWORD[rcx]
	mov	rbx,QWORD[16+rsi]
	mov	rbp,QWORD[24+rsi]
	sbb	rdx,QWORD[8+rcx]
	lea	r15,[((-1))+r9]
	jmp	NEAR $L$sub4x
ALIGN	16
$L$sub4x:
	mov	QWORD[r14*8+rdi],rax
	mov	QWORD[8+r14*8+rdi],rdx
	sbb	rbx,QWORD[16+r14*8+rcx]
	mov	rax,QWORD[32+r14*8+rsi]
	mov	rdx,QWORD[40+r14*8+rsi]
	sbb	rbp,QWORD[24+r14*8+rcx]
	mov	QWORD[16+r14*8+rdi],rbx
	mov	QWORD[24+r14*8+rdi],rbp
	sbb	rax,QWORD[32+r14*8+rcx]
	mov	rbx,QWORD[48+r14*8+rsi]
	mov	rbp,QWORD[56+r14*8+rsi]
	sbb	rdx,QWORD[40+r14*8+rcx]
	lea	r14,[4+r14]
	dec	r15
	jnz	NEAR $L$sub4x

	mov	QWORD[r14*8+rdi],rax
	mov	rax,QWORD[32+r14*8+rsi]
	sbb	rbx,QWORD[16+r14*8+rcx]
	mov	QWORD[8+r14*8+rdi],rdx
	sbb	rbp,QWORD[24+r14*8+rcx]
	mov	QWORD[16+r14*8+rdi],rbx

	sbb	rax,0
DB 66h, 48h, 0fh, 6eh, 0c0h
	punpcklqdq	xmm0,xmm0
	mov	QWORD[24+r14*8+rdi],rbp
	xor	r14,r14

	mov	r15,r9
	pxor	xmm5,xmm5
	jmp	NEAR $L$copy4x
ALIGN	16
$L$copy4x:
	movdqu	xmm2,XMMWORD[r14*1+rsp]
	movdqu	xmm4,XMMWORD[16+r14*1+rsp]
	movdqu	xmm1,XMMWORD[r14*1+rdi]
	movdqu	xmm3,XMMWORD[16+r14*1+rdi]
	pxor	xmm2,xmm1
	pxor	xmm4,xmm3
	pand	xmm2,xmm0
	pand	xmm4,xmm0
	pxor	xmm2,xmm1
	pxor	xmm4,xmm3
	movdqu	XMMWORD[r14*1+rdi],xmm2
	movdqu	XMMWORD[16+r14*1+rdi],xmm4
	movdqa	XMMWORD[r14*1+rsp],xmm5
	movdqa	XMMWORD[16+r14*1+rsp],xmm5

	lea	r14,[32+r14]
	dec	r15
	jnz	NEAR $L$copy4x

	shl	r9,2
	mov	rsi,QWORD[8+r9*8+rsp]
	mov	rax,1
	mov	r15,QWORD[rsi]
	mov	r14,QWORD[8+rsi]
	mov	r13,QWORD[16+rsi]
	mov	r12,QWORD[24+rsi]
	mov	rbp,QWORD[32+rsi]
	mov	rbx,QWORD[40+rsi]
	lea	rsp,[48+rsi]
$L$mul4x_epilogue:
	mov	rdi,QWORD[8+rsp]	;WIN64 epilogue
	mov	rsi,QWORD[16+rsp]
	DB	0F3h,0C3h		;repret
$L$SEH_end_bn_mul4x_mont:
EXTERN	bn_sqr8x_internal


ALIGN	32
bn_sqr8x_mont:
	mov	QWORD[8+rsp],rdi	;WIN64 prologue
	mov	QWORD[16+rsp],rsi
	mov	rax,rsp
$L$SEH_begin_bn_sqr8x_mont:
	mov	rdi,rcx
	mov	rsi,rdx
	mov	rdx,r8
	mov	rcx,r9
	mov	r8,QWORD[40+rsp]
	mov	r9,QWORD[48+rsp]


$L$sqr8x_enter:
	mov	rax,rsp
	push	rbx
	push	rbp
	push	r12
	push	r13
	push	r14
	push	r15

	mov	r10d,r9d
	shl	r9d,3
	shl	r10,3+2
	neg	r9






	lea	r11,[((-64))+r9*4+rsp]
	mov	r8,QWORD[r8]
	sub	r11,rsi
	and	r11,4095
	cmp	r10,r11
	jb	NEAR $L$sqr8x_sp_alt
	sub	rsp,r11
	lea	rsp,[((-64))+r9*4+rsp]
	jmp	NEAR $L$sqr8x_sp_done

ALIGN	32
$L$sqr8x_sp_alt:
	lea	r10,[((4096-64))+r9*4]
	lea	rsp,[((-64))+r9*4+rsp]
	sub	r11,r10
	mov	r10,0
	cmovc	r11,r10
	sub	rsp,r11
$L$sqr8x_sp_done:
	and	rsp,-64
	mov	r10,r9
	neg	r9

	lea	r11,[64+r9*2+rsp]
	mov	QWORD[32+rsp],r8
	mov	QWORD[40+rsp],rax
$L$sqr8x_body:

	mov	rbp,r9
DB	102,73,15,110,211
	shr	rbp,3+2
	mov	eax,DWORD[((OPENSSL_ia32cap_P+8))]
	jmp	NEAR $L$sqr8x_copy_n

ALIGN	32
$L$sqr8x_copy_n:
	movq	xmm0,QWORD[rcx]
	movq	xmm1,QWORD[8+rcx]
	movq	xmm3,QWORD[16+rcx]
	movq	xmm4,QWORD[24+rcx]
	lea	rcx,[32+rcx]
	movdqa	XMMWORD[r11],xmm0
	movdqa	XMMWORD[16+r11],xmm1
	movdqa	XMMWORD[32+r11],xmm3
	movdqa	XMMWORD[48+r11],xmm4
	lea	r11,[64+r11]
	dec	rbp
	jnz	NEAR $L$sqr8x_copy_n

	pxor	xmm0,xmm0
DB	102,72,15,110,207
DB	102,73,15,110,218
	call	bn_sqr8x_internal

	pxor	xmm0,xmm0
	lea	rax,[48+rsp]
	lea	rdx,[64+r9*2+rsp]
	shr	r9,3+2
	mov	rsi,QWORD[40+rsp]
	jmp	NEAR $L$sqr8x_zero

ALIGN	32
$L$sqr8x_zero:
	movdqa	XMMWORD[rax],xmm0
	movdqa	XMMWORD[16+rax],xmm0
	movdqa	XMMWORD[32+rax],xmm0
	movdqa	XMMWORD[48+rax],xmm0
	lea	rax,[64+rax]
	movdqa	XMMWORD[rdx],xmm0
	movdqa	XMMWORD[16+rdx],xmm0
	movdqa	XMMWORD[32+rdx],xmm0
	movdqa	XMMWORD[48+rdx],xmm0
	lea	rdx,[64+rdx]
	dec	r9
	jnz	NEAR $L$sqr8x_zero

	mov	rax,1
	mov	r15,QWORD[((-48))+rsi]
	mov	r14,QWORD[((-40))+rsi]
	mov	r13,QWORD[((-32))+rsi]
	mov	r12,QWORD[((-24))+rsi]
	mov	rbp,QWORD[((-16))+rsi]
	mov	rbx,QWORD[((-8))+rsi]
	lea	rsp,[rsi]
$L$sqr8x_epilogue:
	mov	rdi,QWORD[8+rsp]	;WIN64 epilogue
	mov	rsi,QWORD[16+rsp]
	DB	0F3h,0C3h		;repret
$L$SEH_end_bn_sqr8x_mont:
DB	77,111,110,116,103,111,109,101,114,121,32,77,117,108,116,105
DB	112,108,105,99,97,116,105,111,110,32,102,111,114,32,120,56
DB	54,95,54,52,44,32,67,82,89,80,84,79,71,65,77,83
DB	32,98,121,32,60,97,112,112,114,111,64,111,112,101,110,115
DB	115,108,46,111,114,103,62,0
ALIGN	16
EXTERN	__imp_RtlVirtualUnwind

ALIGN	16
mul_handler:
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

	mov	rsi,QWORD[8+r9]
	mov	r11,QWORD[56+r9]

	mov	r10d,DWORD[r11]
	lea	r10,[r10*1+rsi]
	cmp	rbx,r10
	jb	NEAR $L$common_seh_tail

	mov	rax,QWORD[152+r8]

	mov	r10d,DWORD[4+r11]
	lea	r10,[r10*1+rsi]
	cmp	rbx,r10
	jae	NEAR $L$common_seh_tail

	mov	r10,QWORD[192+r8]
	mov	rax,QWORD[8+r10*8+rax]
	lea	rax,[48+rax]

	mov	rbx,QWORD[((-8))+rax]
	mov	rbp,QWORD[((-16))+rax]
	mov	r12,QWORD[((-24))+rax]
	mov	r13,QWORD[((-32))+rax]
	mov	r14,QWORD[((-40))+rax]
	mov	r15,QWORD[((-48))+rax]
	mov	QWORD[144+r8],rbx
	mov	QWORD[160+r8],rbp
	mov	QWORD[216+r8],r12
	mov	QWORD[224+r8],r13
	mov	QWORD[232+r8],r14
	mov	QWORD[240+r8],r15

	jmp	NEAR $L$common_seh_tail



ALIGN	16
sqr_handler:
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

	mov	rsi,QWORD[8+r9]
	mov	r11,QWORD[56+r9]

	mov	r10d,DWORD[r11]
	lea	r10,[r10*1+rsi]
	cmp	rbx,r10
	jb	NEAR $L$common_seh_tail

	mov	rax,QWORD[152+r8]

	mov	r10d,DWORD[4+r11]
	lea	r10,[r10*1+rsi]
	cmp	rbx,r10
	jae	NEAR $L$common_seh_tail

	mov	rax,QWORD[40+rax]

	mov	rbx,QWORD[((-8))+rax]
	mov	rbp,QWORD[((-16))+rax]
	mov	r12,QWORD[((-24))+rax]
	mov	r13,QWORD[((-32))+rax]
	mov	r14,QWORD[((-40))+rax]
	mov	r15,QWORD[((-48))+rax]
	mov	QWORD[144+r8],rbx
	mov	QWORD[160+r8],rbp
	mov	QWORD[216+r8],r12
	mov	QWORD[224+r8],r13
	mov	QWORD[232+r8],r14
	mov	QWORD[240+r8],r15

$L$common_seh_tail:
	mov	rdi,QWORD[8+rax]
	mov	rsi,QWORD[16+rax]
	mov	QWORD[152+r8],rax
	mov	QWORD[168+r8],rsi
	mov	QWORD[176+r8],rdi

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
	DD	$L$SEH_begin_bn_mul_mont wrt ..imagebase
	DD	$L$SEH_end_bn_mul_mont wrt ..imagebase
	DD	$L$SEH_info_bn_mul_mont wrt ..imagebase

	DD	$L$SEH_begin_bn_mul4x_mont wrt ..imagebase
	DD	$L$SEH_end_bn_mul4x_mont wrt ..imagebase
	DD	$L$SEH_info_bn_mul4x_mont wrt ..imagebase

	DD	$L$SEH_begin_bn_sqr8x_mont wrt ..imagebase
	DD	$L$SEH_end_bn_sqr8x_mont wrt ..imagebase
	DD	$L$SEH_info_bn_sqr8x_mont wrt ..imagebase
section	.xdata rdata align=8
ALIGN	8
$L$SEH_info_bn_mul_mont:
DB	9,0,0,0
	DD	mul_handler wrt ..imagebase
	DD	$L$mul_body wrt ..imagebase,$L$mul_epilogue wrt ..imagebase
$L$SEH_info_bn_mul4x_mont:
DB	9,0,0,0
	DD	mul_handler wrt ..imagebase
	DD	$L$mul4x_body wrt ..imagebase,$L$mul4x_epilogue wrt ..imagebase
$L$SEH_info_bn_sqr8x_mont:
DB	9,0,0,0
	DD	sqr_handler wrt ..imagebase
	DD	$L$sqr8x_body wrt ..imagebase,$L$sqr8x_epilogue wrt ..imagebase
