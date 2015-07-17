#if defined(__x86_64__)
.text	




.globl	CRYPTO_rdrand
.hidden CRYPTO_rdrand
.type	CRYPTO_rdrand,@function
.align	16
CRYPTO_rdrand:
	xorq	%rax,%rax


.byte	0x48, 0x0f, 0xc7, 0xf1

	adcq	%rax,%rax
	movq	%rcx,0(%rdi)
	.byte	0xf3,0xc3





.globl	CRYPTO_rdrand_multiple8_buf
.hidden CRYPTO_rdrand_multiple8_buf
.type	CRYPTO_rdrand_multiple8_buf,@function
.align	16
CRYPTO_rdrand_multiple8_buf:
	testq	%rsi,%rsi
	jz	.Lout
	movq	$8,%rdx
.Lloop:


.byte	0x48, 0x0f, 0xc7, 0xf1
	jnc	.Lerr
	movq	%rcx,0(%rdi)
	addq	%rdx,%rdi
	subq	%rdx,%rsi
	jnz	.Lloop
.Lout:
	movq	$1,%rax
	.byte	0xf3,0xc3
.Lerr:
	xorq	%rax,%rax
	.byte	0xf3,0xc3
#endif
