#if defined(__x86_64__)
.text	




.globl	_CRYPTO_rdrand
.private_extern _CRYPTO_rdrand

.p2align	4
_CRYPTO_rdrand:
	xorq	%rax,%rax


.byte	0x48, 0x0f, 0xc7, 0xf1

	adcq	%rax,%rax
	movq	%rcx,0(%rdi)
	.byte	0xf3,0xc3





.globl	_CRYPTO_rdrand_multiple8_buf
.private_extern _CRYPTO_rdrand_multiple8_buf

.p2align	4
_CRYPTO_rdrand_multiple8_buf:
	testq	%rsi,%rsi
	jz	L$out
	movq	$8,%rdx
L$loop:


.byte	0x48, 0x0f, 0xc7, 0xf1
	jnc	L$err
	movq	%rcx,0(%rdi)
	addq	%rdx,%rdi
	subq	%rdx,%rsi
	jnz	L$loop
L$out:
	movq	$1,%rax
	.byte	0xf3,0xc3
L$err:
	xorq	%rax,%rax
	.byte	0xf3,0xc3
#endif
