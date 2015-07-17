default	rel
%define XMMWORD
%define YMMWORD
%define ZMMWORD
section	.text code align=64





global	CRYPTO_rdrand

ALIGN	16
CRYPTO_rdrand:
	mov	QWORD[8+rsp],rdi	;WIN64 prologue
	mov	QWORD[16+rsp],rsi
	mov	rax,rsp
$L$SEH_begin_CRYPTO_rdrand:
	mov	rdi,rcx


	xor	rax,rax


DB	0x48,0x0f,0xc7,0xf1

	adc	rax,rax
	mov	QWORD[rdi],rcx
	mov	rdi,QWORD[8+rsp]	;WIN64 epilogue
	mov	rsi,QWORD[16+rsp]
	DB	0F3h,0C3h		;repret





global	CRYPTO_rdrand_multiple8_buf

ALIGN	16
CRYPTO_rdrand_multiple8_buf:
	mov	QWORD[8+rsp],rdi	;WIN64 prologue
	mov	QWORD[16+rsp],rsi
	mov	rax,rsp
$L$SEH_begin_CRYPTO_rdrand_multiple8_buf:
	mov	rdi,rcx
	mov	rsi,rdx


	test	rsi,rsi
	jz	NEAR $L$out
	mov	rdx,8
$L$loop:


DB	0x48,0x0f,0xc7,0xf1
	jnc	NEAR $L$err
	mov	QWORD[rdi],rcx
	add	rdi,rdx
	sub	rsi,rdx
	jnz	NEAR $L$loop
$L$out:
	mov	rax,1
	mov	rdi,QWORD[8+rsp]	;WIN64 epilogue
	mov	rsi,QWORD[16+rsp]
	DB	0F3h,0C3h		;repret
$L$err:
	xor	rax,rax
	mov	rdi,QWORD[8+rsp]	;WIN64 epilogue
	mov	rsi,QWORD[16+rsp]
	DB	0F3h,0C3h		;repret
