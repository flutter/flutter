default	rel
%define XMMWORD
%define YMMWORD
%define ZMMWORD
section	.text code align=64


EXTERN	OPENSSL_ia32cap_P

global	rsaz_512_sqr

ALIGN	32
rsaz_512_sqr:
	mov	QWORD[8+rsp],rdi	;WIN64 prologue
	mov	QWORD[16+rsp],rsi
	mov	rax,rsp
$L$SEH_begin_rsaz_512_sqr:
	mov	rdi,rcx
	mov	rsi,rdx
	mov	rdx,r8
	mov	rcx,r9
	mov	r8,QWORD[40+rsp]


	push	rbx
	push	rbp
	push	r12
	push	r13
	push	r14
	push	r15

	sub	rsp,128+24
$L$sqr_body:
	mov	rbp,rdx
	mov	rdx,QWORD[rsi]
	mov	rax,QWORD[8+rsi]
	mov	QWORD[128+rsp],rcx
	jmp	NEAR $L$oop_sqr

ALIGN	32
$L$oop_sqr:
	mov	DWORD[((128+8))+rsp],r8d

	mov	rbx,rdx
	mul	rdx
	mov	r8,rax
	mov	rax,QWORD[16+rsi]
	mov	r9,rdx

	mul	rbx
	add	r9,rax
	mov	rax,QWORD[24+rsi]
	mov	r10,rdx
	adc	r10,0

	mul	rbx
	add	r10,rax
	mov	rax,QWORD[32+rsi]
	mov	r11,rdx
	adc	r11,0

	mul	rbx
	add	r11,rax
	mov	rax,QWORD[40+rsi]
	mov	r12,rdx
	adc	r12,0

	mul	rbx
	add	r12,rax
	mov	rax,QWORD[48+rsi]
	mov	r13,rdx
	adc	r13,0

	mul	rbx
	add	r13,rax
	mov	rax,QWORD[56+rsi]
	mov	r14,rdx
	adc	r14,0

	mul	rbx
	add	r14,rax
	mov	rax,rbx
	mov	r15,rdx
	adc	r15,0

	add	r8,r8
	mov	rcx,r9
	adc	r9,r9

	mul	rax
	mov	QWORD[rsp],rax
	add	r8,rdx
	adc	r9,0

	mov	QWORD[8+rsp],r8
	shr	rcx,63


	mov	r8,QWORD[8+rsi]
	mov	rax,QWORD[16+rsi]
	mul	r8
	add	r10,rax
	mov	rax,QWORD[24+rsi]
	mov	rbx,rdx
	adc	rbx,0

	mul	r8
	add	r11,rax
	mov	rax,QWORD[32+rsi]
	adc	rdx,0
	add	r11,rbx
	mov	rbx,rdx
	adc	rbx,0

	mul	r8
	add	r12,rax
	mov	rax,QWORD[40+rsi]
	adc	rdx,0
	add	r12,rbx
	mov	rbx,rdx
	adc	rbx,0

	mul	r8
	add	r13,rax
	mov	rax,QWORD[48+rsi]
	adc	rdx,0
	add	r13,rbx
	mov	rbx,rdx
	adc	rbx,0

	mul	r8
	add	r14,rax
	mov	rax,QWORD[56+rsi]
	adc	rdx,0
	add	r14,rbx
	mov	rbx,rdx
	adc	rbx,0

	mul	r8
	add	r15,rax
	mov	rax,r8
	adc	rdx,0
	add	r15,rbx
	mov	r8,rdx
	mov	rdx,r10
	adc	r8,0

	add	rdx,rdx
	lea	r10,[r10*2+rcx]
	mov	rbx,r11
	adc	r11,r11

	mul	rax
	add	r9,rax
	adc	r10,rdx
	adc	r11,0

	mov	QWORD[16+rsp],r9
	mov	QWORD[24+rsp],r10
	shr	rbx,63


	mov	r9,QWORD[16+rsi]
	mov	rax,QWORD[24+rsi]
	mul	r9
	add	r12,rax
	mov	rax,QWORD[32+rsi]
	mov	rcx,rdx
	adc	rcx,0

	mul	r9
	add	r13,rax
	mov	rax,QWORD[40+rsi]
	adc	rdx,0
	add	r13,rcx
	mov	rcx,rdx
	adc	rcx,0

	mul	r9
	add	r14,rax
	mov	rax,QWORD[48+rsi]
	adc	rdx,0
	add	r14,rcx
	mov	rcx,rdx
	adc	rcx,0

	mul	r9
	mov	r10,r12
	lea	r12,[r12*2+rbx]
	add	r15,rax
	mov	rax,QWORD[56+rsi]
	adc	rdx,0
	add	r15,rcx
	mov	rcx,rdx
	adc	rcx,0

	mul	r9
	shr	r10,63
	add	r8,rax
	mov	rax,r9
	adc	rdx,0
	add	r8,rcx
	mov	r9,rdx
	adc	r9,0

	mov	rcx,r13
	lea	r13,[r13*2+r10]

	mul	rax
	add	r11,rax
	adc	r12,rdx
	adc	r13,0

	mov	QWORD[32+rsp],r11
	mov	QWORD[40+rsp],r12
	shr	rcx,63


	mov	r10,QWORD[24+rsi]
	mov	rax,QWORD[32+rsi]
	mul	r10
	add	r14,rax
	mov	rax,QWORD[40+rsi]
	mov	rbx,rdx
	adc	rbx,0

	mul	r10
	add	r15,rax
	mov	rax,QWORD[48+rsi]
	adc	rdx,0
	add	r15,rbx
	mov	rbx,rdx
	adc	rbx,0

	mul	r10
	mov	r12,r14
	lea	r14,[r14*2+rcx]
	add	r8,rax
	mov	rax,QWORD[56+rsi]
	adc	rdx,0
	add	r8,rbx
	mov	rbx,rdx
	adc	rbx,0

	mul	r10
	shr	r12,63
	add	r9,rax
	mov	rax,r10
	adc	rdx,0
	add	r9,rbx
	mov	r10,rdx
	adc	r10,0

	mov	rbx,r15
	lea	r15,[r15*2+r12]

	mul	rax
	add	r13,rax
	adc	r14,rdx
	adc	r15,0

	mov	QWORD[48+rsp],r13
	mov	QWORD[56+rsp],r14
	shr	rbx,63


	mov	r11,QWORD[32+rsi]
	mov	rax,QWORD[40+rsi]
	mul	r11
	add	r8,rax
	mov	rax,QWORD[48+rsi]
	mov	rcx,rdx
	adc	rcx,0

	mul	r11
	add	r9,rax
	mov	rax,QWORD[56+rsi]
	adc	rdx,0
	mov	r12,r8
	lea	r8,[r8*2+rbx]
	add	r9,rcx
	mov	rcx,rdx
	adc	rcx,0

	mul	r11
	shr	r12,63
	add	r10,rax
	mov	rax,r11
	adc	rdx,0
	add	r10,rcx
	mov	r11,rdx
	adc	r11,0

	mov	rcx,r9
	lea	r9,[r9*2+r12]

	mul	rax
	add	r15,rax
	adc	r8,rdx
	adc	r9,0

	mov	QWORD[64+rsp],r15
	mov	QWORD[72+rsp],r8
	shr	rcx,63


	mov	r12,QWORD[40+rsi]
	mov	rax,QWORD[48+rsi]
	mul	r12
	add	r10,rax
	mov	rax,QWORD[56+rsi]
	mov	rbx,rdx
	adc	rbx,0

	mul	r12
	add	r11,rax
	mov	rax,r12
	mov	r15,r10
	lea	r10,[r10*2+rcx]
	adc	rdx,0
	shr	r15,63
	add	r11,rbx
	mov	r12,rdx
	adc	r12,0

	mov	rbx,r11
	lea	r11,[r11*2+r15]

	mul	rax
	add	r9,rax
	adc	r10,rdx
	adc	r11,0

	mov	QWORD[80+rsp],r9
	mov	QWORD[88+rsp],r10


	mov	r13,QWORD[48+rsi]
	mov	rax,QWORD[56+rsi]
	mul	r13
	add	r12,rax
	mov	rax,r13
	mov	r13,rdx
	adc	r13,0

	xor	r14,r14
	shl	rbx,1
	adc	r12,r12
	adc	r13,r13
	adc	r14,r14

	mul	rax
	add	r11,rax
	adc	r12,rdx
	adc	r13,0

	mov	QWORD[96+rsp],r11
	mov	QWORD[104+rsp],r12


	mov	rax,QWORD[56+rsi]
	mul	rax
	add	r13,rax
	adc	rdx,0

	add	r14,rdx

	mov	QWORD[112+rsp],r13
	mov	QWORD[120+rsp],r14

	mov	r8,QWORD[rsp]
	mov	r9,QWORD[8+rsp]
	mov	r10,QWORD[16+rsp]
	mov	r11,QWORD[24+rsp]
	mov	r12,QWORD[32+rsp]
	mov	r13,QWORD[40+rsp]
	mov	r14,QWORD[48+rsp]
	mov	r15,QWORD[56+rsp]

	call	__rsaz_512_reduce

	add	r8,QWORD[64+rsp]
	adc	r9,QWORD[72+rsp]
	adc	r10,QWORD[80+rsp]
	adc	r11,QWORD[88+rsp]
	adc	r12,QWORD[96+rsp]
	adc	r13,QWORD[104+rsp]
	adc	r14,QWORD[112+rsp]
	adc	r15,QWORD[120+rsp]
	sbb	rcx,rcx

	call	__rsaz_512_subtract

	mov	rdx,r8
	mov	rax,r9
	mov	r8d,DWORD[((128+8))+rsp]
	mov	rsi,rdi

	dec	r8d
	jnz	NEAR $L$oop_sqr

	lea	rax,[((128+24+48))+rsp]
	mov	r15,QWORD[((-48))+rax]
	mov	r14,QWORD[((-40))+rax]
	mov	r13,QWORD[((-32))+rax]
	mov	r12,QWORD[((-24))+rax]
	mov	rbp,QWORD[((-16))+rax]
	mov	rbx,QWORD[((-8))+rax]
	lea	rsp,[rax]
$L$sqr_epilogue:
	mov	rdi,QWORD[8+rsp]	;WIN64 epilogue
	mov	rsi,QWORD[16+rsp]
	DB	0F3h,0C3h		;repret
$L$SEH_end_rsaz_512_sqr:
global	rsaz_512_mul

ALIGN	32
rsaz_512_mul:
	mov	QWORD[8+rsp],rdi	;WIN64 prologue
	mov	QWORD[16+rsp],rsi
	mov	rax,rsp
$L$SEH_begin_rsaz_512_mul:
	mov	rdi,rcx
	mov	rsi,rdx
	mov	rdx,r8
	mov	rcx,r9
	mov	r8,QWORD[40+rsp]


	push	rbx
	push	rbp
	push	r12
	push	r13
	push	r14
	push	r15

	sub	rsp,128+24
$L$mul_body:
DB	102,72,15,110,199
DB	102,72,15,110,201
	mov	QWORD[128+rsp],r8
	mov	rbx,QWORD[rdx]
	mov	rbp,rdx
	call	__rsaz_512_mul

DB	102,72,15,126,199
DB	102,72,15,126,205

	mov	r8,QWORD[rsp]
	mov	r9,QWORD[8+rsp]
	mov	r10,QWORD[16+rsp]
	mov	r11,QWORD[24+rsp]
	mov	r12,QWORD[32+rsp]
	mov	r13,QWORD[40+rsp]
	mov	r14,QWORD[48+rsp]
	mov	r15,QWORD[56+rsp]

	call	__rsaz_512_reduce
	add	r8,QWORD[64+rsp]
	adc	r9,QWORD[72+rsp]
	adc	r10,QWORD[80+rsp]
	adc	r11,QWORD[88+rsp]
	adc	r12,QWORD[96+rsp]
	adc	r13,QWORD[104+rsp]
	adc	r14,QWORD[112+rsp]
	adc	r15,QWORD[120+rsp]
	sbb	rcx,rcx

	call	__rsaz_512_subtract

	lea	rax,[((128+24+48))+rsp]
	mov	r15,QWORD[((-48))+rax]
	mov	r14,QWORD[((-40))+rax]
	mov	r13,QWORD[((-32))+rax]
	mov	r12,QWORD[((-24))+rax]
	mov	rbp,QWORD[((-16))+rax]
	mov	rbx,QWORD[((-8))+rax]
	lea	rsp,[rax]
$L$mul_epilogue:
	mov	rdi,QWORD[8+rsp]	;WIN64 epilogue
	mov	rsi,QWORD[16+rsp]
	DB	0F3h,0C3h		;repret
$L$SEH_end_rsaz_512_mul:
global	rsaz_512_mul_gather4

ALIGN	32
rsaz_512_mul_gather4:
	mov	QWORD[8+rsp],rdi	;WIN64 prologue
	mov	QWORD[16+rsp],rsi
	mov	rax,rsp
$L$SEH_begin_rsaz_512_mul_gather4:
	mov	rdi,rcx
	mov	rsi,rdx
	mov	rdx,r8
	mov	rcx,r9
	mov	r8,QWORD[40+rsp]
	mov	r9,QWORD[48+rsp]


	push	rbx
	push	rbp
	push	r12
	push	r13
	push	r14
	push	r15

	mov	r9d,r9d
	sub	rsp,128+24
$L$mul_gather4_body:
	mov	eax,DWORD[64+r9*4+rdx]
DB	102,72,15,110,199
	mov	ebx,DWORD[r9*4+rdx]
DB	102,72,15,110,201
	mov	QWORD[128+rsp],r8

	shl	rax,32
	or	rbx,rax
	mov	rax,QWORD[rsi]
	mov	rcx,QWORD[8+rsi]
	lea	rbp,[128+r9*4+rdx]
	mul	rbx
	mov	QWORD[rsp],rax
	mov	rax,rcx
	mov	r8,rdx

	mul	rbx
	movd	xmm4,DWORD[rbp]
	add	r8,rax
	mov	rax,QWORD[16+rsi]
	mov	r9,rdx
	adc	r9,0

	mul	rbx
	movd	xmm5,DWORD[64+rbp]
	add	r9,rax
	mov	rax,QWORD[24+rsi]
	mov	r10,rdx
	adc	r10,0

	mul	rbx
	pslldq	xmm5,4
	add	r10,rax
	mov	rax,QWORD[32+rsi]
	mov	r11,rdx
	adc	r11,0

	mul	rbx
	por	xmm4,xmm5
	add	r11,rax
	mov	rax,QWORD[40+rsi]
	mov	r12,rdx
	adc	r12,0

	mul	rbx
	add	r12,rax
	mov	rax,QWORD[48+rsi]
	mov	r13,rdx
	adc	r13,0

	mul	rbx
	lea	rbp,[128+rbp]
	add	r13,rax
	mov	rax,QWORD[56+rsi]
	mov	r14,rdx
	adc	r14,0

	mul	rbx
DB	102,72,15,126,227
	add	r14,rax
	mov	rax,QWORD[rsi]
	mov	r15,rdx
	adc	r15,0

	lea	rdi,[8+rsp]
	mov	ecx,7
	jmp	NEAR $L$oop_mul_gather

ALIGN	32
$L$oop_mul_gather:
	mul	rbx
	add	r8,rax
	mov	rax,QWORD[8+rsi]
	mov	QWORD[rdi],r8
	mov	r8,rdx
	adc	r8,0

	mul	rbx
	movd	xmm4,DWORD[rbp]
	add	r9,rax
	mov	rax,QWORD[16+rsi]
	adc	rdx,0
	add	r8,r9
	mov	r9,rdx
	adc	r9,0

	mul	rbx
	movd	xmm5,DWORD[64+rbp]
	add	r10,rax
	mov	rax,QWORD[24+rsi]
	adc	rdx,0
	add	r9,r10
	mov	r10,rdx
	adc	r10,0

	mul	rbx
	pslldq	xmm5,4
	add	r11,rax
	mov	rax,QWORD[32+rsi]
	adc	rdx,0
	add	r10,r11
	mov	r11,rdx
	adc	r11,0

	mul	rbx
	por	xmm4,xmm5
	add	r12,rax
	mov	rax,QWORD[40+rsi]
	adc	rdx,0
	add	r11,r12
	mov	r12,rdx
	adc	r12,0

	mul	rbx
	add	r13,rax
	mov	rax,QWORD[48+rsi]
	adc	rdx,0
	add	r12,r13
	mov	r13,rdx
	adc	r13,0

	mul	rbx
	add	r14,rax
	mov	rax,QWORD[56+rsi]
	adc	rdx,0
	add	r13,r14
	mov	r14,rdx
	adc	r14,0

	mul	rbx
DB	102,72,15,126,227
	add	r15,rax
	mov	rax,QWORD[rsi]
	adc	rdx,0
	add	r14,r15
	mov	r15,rdx
	adc	r15,0

	lea	rbp,[128+rbp]
	lea	rdi,[8+rdi]

	dec	ecx
	jnz	NEAR $L$oop_mul_gather

	mov	QWORD[rdi],r8
	mov	QWORD[8+rdi],r9
	mov	QWORD[16+rdi],r10
	mov	QWORD[24+rdi],r11
	mov	QWORD[32+rdi],r12
	mov	QWORD[40+rdi],r13
	mov	QWORD[48+rdi],r14
	mov	QWORD[56+rdi],r15

DB	102,72,15,126,199
DB	102,72,15,126,205

	mov	r8,QWORD[rsp]
	mov	r9,QWORD[8+rsp]
	mov	r10,QWORD[16+rsp]
	mov	r11,QWORD[24+rsp]
	mov	r12,QWORD[32+rsp]
	mov	r13,QWORD[40+rsp]
	mov	r14,QWORD[48+rsp]
	mov	r15,QWORD[56+rsp]

	call	__rsaz_512_reduce
	add	r8,QWORD[64+rsp]
	adc	r9,QWORD[72+rsp]
	adc	r10,QWORD[80+rsp]
	adc	r11,QWORD[88+rsp]
	adc	r12,QWORD[96+rsp]
	adc	r13,QWORD[104+rsp]
	adc	r14,QWORD[112+rsp]
	adc	r15,QWORD[120+rsp]
	sbb	rcx,rcx

	call	__rsaz_512_subtract

	lea	rax,[((128+24+48))+rsp]
	mov	r15,QWORD[((-48))+rax]
	mov	r14,QWORD[((-40))+rax]
	mov	r13,QWORD[((-32))+rax]
	mov	r12,QWORD[((-24))+rax]
	mov	rbp,QWORD[((-16))+rax]
	mov	rbx,QWORD[((-8))+rax]
	lea	rsp,[rax]
$L$mul_gather4_epilogue:
	mov	rdi,QWORD[8+rsp]	;WIN64 epilogue
	mov	rsi,QWORD[16+rsp]
	DB	0F3h,0C3h		;repret
$L$SEH_end_rsaz_512_mul_gather4:
global	rsaz_512_mul_scatter4

ALIGN	32
rsaz_512_mul_scatter4:
	mov	QWORD[8+rsp],rdi	;WIN64 prologue
	mov	QWORD[16+rsp],rsi
	mov	rax,rsp
$L$SEH_begin_rsaz_512_mul_scatter4:
	mov	rdi,rcx
	mov	rsi,rdx
	mov	rdx,r8
	mov	rcx,r9
	mov	r8,QWORD[40+rsp]
	mov	r9,QWORD[48+rsp]


	push	rbx
	push	rbp
	push	r12
	push	r13
	push	r14
	push	r15

	mov	r9d,r9d
	sub	rsp,128+24
$L$mul_scatter4_body:
	lea	r8,[r9*4+r8]
DB	102,72,15,110,199
DB	102,72,15,110,202
DB	102,73,15,110,208
	mov	QWORD[128+rsp],rcx

	mov	rbp,rdi
	mov	rbx,QWORD[rdi]
	call	__rsaz_512_mul

DB	102,72,15,126,199
DB	102,72,15,126,205

	mov	r8,QWORD[rsp]
	mov	r9,QWORD[8+rsp]
	mov	r10,QWORD[16+rsp]
	mov	r11,QWORD[24+rsp]
	mov	r12,QWORD[32+rsp]
	mov	r13,QWORD[40+rsp]
	mov	r14,QWORD[48+rsp]
	mov	r15,QWORD[56+rsp]

	call	__rsaz_512_reduce
	add	r8,QWORD[64+rsp]
	adc	r9,QWORD[72+rsp]
	adc	r10,QWORD[80+rsp]
	adc	r11,QWORD[88+rsp]
	adc	r12,QWORD[96+rsp]
	adc	r13,QWORD[104+rsp]
	adc	r14,QWORD[112+rsp]
	adc	r15,QWORD[120+rsp]
DB	102,72,15,126,214
	sbb	rcx,rcx

	call	__rsaz_512_subtract

	mov	DWORD[rsi],r8d
	shr	r8,32
	mov	DWORD[128+rsi],r9d
	shr	r9,32
	mov	DWORD[256+rsi],r10d
	shr	r10,32
	mov	DWORD[384+rsi],r11d
	shr	r11,32
	mov	DWORD[512+rsi],r12d
	shr	r12,32
	mov	DWORD[640+rsi],r13d
	shr	r13,32
	mov	DWORD[768+rsi],r14d
	shr	r14,32
	mov	DWORD[896+rsi],r15d
	shr	r15,32
	mov	DWORD[64+rsi],r8d
	mov	DWORD[192+rsi],r9d
	mov	DWORD[320+rsi],r10d
	mov	DWORD[448+rsi],r11d
	mov	DWORD[576+rsi],r12d
	mov	DWORD[704+rsi],r13d
	mov	DWORD[832+rsi],r14d
	mov	DWORD[960+rsi],r15d

	lea	rax,[((128+24+48))+rsp]
	mov	r15,QWORD[((-48))+rax]
	mov	r14,QWORD[((-40))+rax]
	mov	r13,QWORD[((-32))+rax]
	mov	r12,QWORD[((-24))+rax]
	mov	rbp,QWORD[((-16))+rax]
	mov	rbx,QWORD[((-8))+rax]
	lea	rsp,[rax]
$L$mul_scatter4_epilogue:
	mov	rdi,QWORD[8+rsp]	;WIN64 epilogue
	mov	rsi,QWORD[16+rsp]
	DB	0F3h,0C3h		;repret
$L$SEH_end_rsaz_512_mul_scatter4:
global	rsaz_512_mul_by_one

ALIGN	32
rsaz_512_mul_by_one:
	mov	QWORD[8+rsp],rdi	;WIN64 prologue
	mov	QWORD[16+rsp],rsi
	mov	rax,rsp
$L$SEH_begin_rsaz_512_mul_by_one:
	mov	rdi,rcx
	mov	rsi,rdx
	mov	rdx,r8
	mov	rcx,r9


	push	rbx
	push	rbp
	push	r12
	push	r13
	push	r14
	push	r15

	sub	rsp,128+24
$L$mul_by_one_body:
	mov	rbp,rdx
	mov	QWORD[128+rsp],rcx

	mov	r8,QWORD[rsi]
	pxor	xmm0,xmm0
	mov	r9,QWORD[8+rsi]
	mov	r10,QWORD[16+rsi]
	mov	r11,QWORD[24+rsi]
	mov	r12,QWORD[32+rsi]
	mov	r13,QWORD[40+rsi]
	mov	r14,QWORD[48+rsi]
	mov	r15,QWORD[56+rsi]

	movdqa	XMMWORD[rsp],xmm0
	movdqa	XMMWORD[16+rsp],xmm0
	movdqa	XMMWORD[32+rsp],xmm0
	movdqa	XMMWORD[48+rsp],xmm0
	movdqa	XMMWORD[64+rsp],xmm0
	movdqa	XMMWORD[80+rsp],xmm0
	movdqa	XMMWORD[96+rsp],xmm0
	call	__rsaz_512_reduce
	mov	QWORD[rdi],r8
	mov	QWORD[8+rdi],r9
	mov	QWORD[16+rdi],r10
	mov	QWORD[24+rdi],r11
	mov	QWORD[32+rdi],r12
	mov	QWORD[40+rdi],r13
	mov	QWORD[48+rdi],r14
	mov	QWORD[56+rdi],r15

	lea	rax,[((128+24+48))+rsp]
	mov	r15,QWORD[((-48))+rax]
	mov	r14,QWORD[((-40))+rax]
	mov	r13,QWORD[((-32))+rax]
	mov	r12,QWORD[((-24))+rax]
	mov	rbp,QWORD[((-16))+rax]
	mov	rbx,QWORD[((-8))+rax]
	lea	rsp,[rax]
$L$mul_by_one_epilogue:
	mov	rdi,QWORD[8+rsp]	;WIN64 epilogue
	mov	rsi,QWORD[16+rsp]
	DB	0F3h,0C3h		;repret
$L$SEH_end_rsaz_512_mul_by_one:

ALIGN	32
__rsaz_512_reduce:
	mov	rbx,r8
	imul	rbx,QWORD[((128+8))+rsp]
	mov	rax,QWORD[rbp]
	mov	ecx,8
	jmp	NEAR $L$reduction_loop

ALIGN	32
$L$reduction_loop:
	mul	rbx
	mov	rax,QWORD[8+rbp]
	neg	r8
	mov	r8,rdx
	adc	r8,0

	mul	rbx
	add	r9,rax
	mov	rax,QWORD[16+rbp]
	adc	rdx,0
	add	r8,r9
	mov	r9,rdx
	adc	r9,0

	mul	rbx
	add	r10,rax
	mov	rax,QWORD[24+rbp]
	adc	rdx,0
	add	r9,r10
	mov	r10,rdx
	adc	r10,0

	mul	rbx
	add	r11,rax
	mov	rax,QWORD[32+rbp]
	adc	rdx,0
	add	r10,r11
	mov	rsi,QWORD[((128+8))+rsp]


	adc	rdx,0
	mov	r11,rdx

	mul	rbx
	add	r12,rax
	mov	rax,QWORD[40+rbp]
	adc	rdx,0
	imul	rsi,r8
	add	r11,r12
	mov	r12,rdx
	adc	r12,0

	mul	rbx
	add	r13,rax
	mov	rax,QWORD[48+rbp]
	adc	rdx,0
	add	r12,r13
	mov	r13,rdx
	adc	r13,0

	mul	rbx
	add	r14,rax
	mov	rax,QWORD[56+rbp]
	adc	rdx,0
	add	r13,r14
	mov	r14,rdx
	adc	r14,0

	mul	rbx
	mov	rbx,rsi
	add	r15,rax
	mov	rax,QWORD[rbp]
	adc	rdx,0
	add	r14,r15
	mov	r15,rdx
	adc	r15,0

	dec	ecx
	jne	NEAR $L$reduction_loop

	DB	0F3h,0C3h		;repret


ALIGN	32
__rsaz_512_subtract:
	mov	QWORD[rdi],r8
	mov	QWORD[8+rdi],r9
	mov	QWORD[16+rdi],r10
	mov	QWORD[24+rdi],r11
	mov	QWORD[32+rdi],r12
	mov	QWORD[40+rdi],r13
	mov	QWORD[48+rdi],r14
	mov	QWORD[56+rdi],r15

	mov	r8,QWORD[rbp]
	mov	r9,QWORD[8+rbp]
	neg	r8
	not	r9
	and	r8,rcx
	mov	r10,QWORD[16+rbp]
	and	r9,rcx
	not	r10
	mov	r11,QWORD[24+rbp]
	and	r10,rcx
	not	r11
	mov	r12,QWORD[32+rbp]
	and	r11,rcx
	not	r12
	mov	r13,QWORD[40+rbp]
	and	r12,rcx
	not	r13
	mov	r14,QWORD[48+rbp]
	and	r13,rcx
	not	r14
	mov	r15,QWORD[56+rbp]
	and	r14,rcx
	not	r15
	and	r15,rcx

	add	r8,QWORD[rdi]
	adc	r9,QWORD[8+rdi]
	adc	r10,QWORD[16+rdi]
	adc	r11,QWORD[24+rdi]
	adc	r12,QWORD[32+rdi]
	adc	r13,QWORD[40+rdi]
	adc	r14,QWORD[48+rdi]
	adc	r15,QWORD[56+rdi]

	mov	QWORD[rdi],r8
	mov	QWORD[8+rdi],r9
	mov	QWORD[16+rdi],r10
	mov	QWORD[24+rdi],r11
	mov	QWORD[32+rdi],r12
	mov	QWORD[40+rdi],r13
	mov	QWORD[48+rdi],r14
	mov	QWORD[56+rdi],r15

	DB	0F3h,0C3h		;repret


ALIGN	32
__rsaz_512_mul:
	lea	rdi,[8+rsp]

	mov	rax,QWORD[rsi]
	mul	rbx
	mov	QWORD[rdi],rax
	mov	rax,QWORD[8+rsi]
	mov	r8,rdx

	mul	rbx
	add	r8,rax
	mov	rax,QWORD[16+rsi]
	mov	r9,rdx
	adc	r9,0

	mul	rbx
	add	r9,rax
	mov	rax,QWORD[24+rsi]
	mov	r10,rdx
	adc	r10,0

	mul	rbx
	add	r10,rax
	mov	rax,QWORD[32+rsi]
	mov	r11,rdx
	adc	r11,0

	mul	rbx
	add	r11,rax
	mov	rax,QWORD[40+rsi]
	mov	r12,rdx
	adc	r12,0

	mul	rbx
	add	r12,rax
	mov	rax,QWORD[48+rsi]
	mov	r13,rdx
	adc	r13,0

	mul	rbx
	add	r13,rax
	mov	rax,QWORD[56+rsi]
	mov	r14,rdx
	adc	r14,0

	mul	rbx
	add	r14,rax
	mov	rax,QWORD[rsi]
	mov	r15,rdx
	adc	r15,0

	lea	rbp,[8+rbp]
	lea	rdi,[8+rdi]

	mov	ecx,7
	jmp	NEAR $L$oop_mul

ALIGN	32
$L$oop_mul:
	mov	rbx,QWORD[rbp]
	mul	rbx
	add	r8,rax
	mov	rax,QWORD[8+rsi]
	mov	QWORD[rdi],r8
	mov	r8,rdx
	adc	r8,0

	mul	rbx
	add	r9,rax
	mov	rax,QWORD[16+rsi]
	adc	rdx,0
	add	r8,r9
	mov	r9,rdx
	adc	r9,0

	mul	rbx
	add	r10,rax
	mov	rax,QWORD[24+rsi]
	adc	rdx,0
	add	r9,r10
	mov	r10,rdx
	adc	r10,0

	mul	rbx
	add	r11,rax
	mov	rax,QWORD[32+rsi]
	adc	rdx,0
	add	r10,r11
	mov	r11,rdx
	adc	r11,0

	mul	rbx
	add	r12,rax
	mov	rax,QWORD[40+rsi]
	adc	rdx,0
	add	r11,r12
	mov	r12,rdx
	adc	r12,0

	mul	rbx
	add	r13,rax
	mov	rax,QWORD[48+rsi]
	adc	rdx,0
	add	r12,r13
	mov	r13,rdx
	adc	r13,0

	mul	rbx
	add	r14,rax
	mov	rax,QWORD[56+rsi]
	adc	rdx,0
	add	r13,r14
	mov	r14,rdx
	lea	rbp,[8+rbp]
	adc	r14,0

	mul	rbx
	add	r15,rax
	mov	rax,QWORD[rsi]
	adc	rdx,0
	add	r14,r15
	mov	r15,rdx
	adc	r15,0

	lea	rdi,[8+rdi]

	dec	ecx
	jnz	NEAR $L$oop_mul

	mov	QWORD[rdi],r8
	mov	QWORD[8+rdi],r9
	mov	QWORD[16+rdi],r10
	mov	QWORD[24+rdi],r11
	mov	QWORD[32+rdi],r12
	mov	QWORD[40+rdi],r13
	mov	QWORD[48+rdi],r14
	mov	QWORD[56+rdi],r15

	DB	0F3h,0C3h		;repret

global	rsaz_512_scatter4

ALIGN	16
rsaz_512_scatter4:
	lea	rcx,[r8*4+rcx]
	mov	r9d,8
	jmp	NEAR $L$oop_scatter
ALIGN	16
$L$oop_scatter:
	mov	rax,QWORD[rdx]
	lea	rdx,[8+rdx]
	mov	DWORD[rcx],eax
	shr	rax,32
	mov	DWORD[64+rcx],eax
	lea	rcx,[128+rcx]
	dec	r9d
	jnz	NEAR $L$oop_scatter
	DB	0F3h,0C3h		;repret


global	rsaz_512_gather4

ALIGN	16
rsaz_512_gather4:
	lea	rdx,[r8*4+rdx]
	mov	r9d,8
	jmp	NEAR $L$oop_gather
ALIGN	16
$L$oop_gather:
	mov	eax,DWORD[rdx]
	mov	r8d,DWORD[64+rdx]
	lea	rdx,[128+rdx]
	shl	r8,32
	or	rax,r8
	mov	QWORD[rcx],rax
	lea	rcx,[8+rcx]
	dec	r9d
	jnz	NEAR $L$oop_gather
	DB	0F3h,0C3h		;repret

EXTERN	__imp_RtlVirtualUnwind

ALIGN	16
se_handler:
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

	lea	rax,[((128+24+48))+rax]

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
	DD	$L$SEH_begin_rsaz_512_sqr wrt ..imagebase
	DD	$L$SEH_end_rsaz_512_sqr wrt ..imagebase
	DD	$L$SEH_info_rsaz_512_sqr wrt ..imagebase

	DD	$L$SEH_begin_rsaz_512_mul wrt ..imagebase
	DD	$L$SEH_end_rsaz_512_mul wrt ..imagebase
	DD	$L$SEH_info_rsaz_512_mul wrt ..imagebase

	DD	$L$SEH_begin_rsaz_512_mul_gather4 wrt ..imagebase
	DD	$L$SEH_end_rsaz_512_mul_gather4 wrt ..imagebase
	DD	$L$SEH_info_rsaz_512_mul_gather4 wrt ..imagebase

	DD	$L$SEH_begin_rsaz_512_mul_scatter4 wrt ..imagebase
	DD	$L$SEH_end_rsaz_512_mul_scatter4 wrt ..imagebase
	DD	$L$SEH_info_rsaz_512_mul_scatter4 wrt ..imagebase

	DD	$L$SEH_begin_rsaz_512_mul_by_one wrt ..imagebase
	DD	$L$SEH_end_rsaz_512_mul_by_one wrt ..imagebase
	DD	$L$SEH_info_rsaz_512_mul_by_one wrt ..imagebase

section	.xdata rdata align=8
ALIGN	8
$L$SEH_info_rsaz_512_sqr:
DB	9,0,0,0
	DD	se_handler wrt ..imagebase
	DD	$L$sqr_body wrt ..imagebase,$L$sqr_epilogue wrt ..imagebase
$L$SEH_info_rsaz_512_mul:
DB	9,0,0,0
	DD	se_handler wrt ..imagebase
	DD	$L$mul_body wrt ..imagebase,$L$mul_epilogue wrt ..imagebase
$L$SEH_info_rsaz_512_mul_gather4:
DB	9,0,0,0
	DD	se_handler wrt ..imagebase
	DD	$L$mul_gather4_body wrt ..imagebase,$L$mul_gather4_epilogue wrt ..imagebase
$L$SEH_info_rsaz_512_mul_scatter4:
DB	9,0,0,0
	DD	se_handler wrt ..imagebase
	DD	$L$mul_scatter4_body wrt ..imagebase,$L$mul_scatter4_epilogue wrt ..imagebase
$L$SEH_info_rsaz_512_mul_by_one:
DB	9,0,0,0
	DD	se_handler wrt ..imagebase
	DD	$L$mul_by_one_body wrt ..imagebase,$L$mul_by_one_epilogue wrt ..imagebase
