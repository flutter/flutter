#if defined(__x86_64__)
.text	



.globl	_bn_mul_mont
.private_extern _bn_mul_mont

.p2align	4
_bn_mul_mont:
	testl	$3,%r9d
	jnz	L$mul_enter
	cmpl	$8,%r9d
	jb	L$mul_enter
	cmpq	%rsi,%rdx
	jne	L$mul4x_enter
	testl	$7,%r9d
	jz	L$sqr8x_enter
	jmp	L$mul4x_enter

.p2align	4
L$mul_enter:
	pushq	%rbx
	pushq	%rbp
	pushq	%r12
	pushq	%r13
	pushq	%r14
	pushq	%r15

	movl	%r9d,%r9d
	leaq	2(%r9),%r10
	movq	%rsp,%r11
	negq	%r10
	leaq	(%rsp,%r10,8),%rsp
	andq	$-1024,%rsp

	movq	%r11,8(%rsp,%r9,8)
L$mul_body:
	movq	%rdx,%r12
	movq	(%r8),%r8
	movq	(%r12),%rbx
	movq	(%rsi),%rax

	xorq	%r14,%r14
	xorq	%r15,%r15

	movq	%r8,%rbp
	mulq	%rbx
	movq	%rax,%r10
	movq	(%rcx),%rax

	imulq	%r10,%rbp
	movq	%rdx,%r11

	mulq	%rbp
	addq	%rax,%r10
	movq	8(%rsi),%rax
	adcq	$0,%rdx
	movq	%rdx,%r13

	leaq	1(%r15),%r15
	jmp	L$1st_enter

.p2align	4
L$1st:
	addq	%rax,%r13
	movq	(%rsi,%r15,8),%rax
	adcq	$0,%rdx
	addq	%r11,%r13
	movq	%r10,%r11
	adcq	$0,%rdx
	movq	%r13,-16(%rsp,%r15,8)
	movq	%rdx,%r13

L$1st_enter:
	mulq	%rbx
	addq	%rax,%r11
	movq	(%rcx,%r15,8),%rax
	adcq	$0,%rdx
	leaq	1(%r15),%r15
	movq	%rdx,%r10

	mulq	%rbp
	cmpq	%r9,%r15
	jne	L$1st

	addq	%rax,%r13
	movq	(%rsi),%rax
	adcq	$0,%rdx
	addq	%r11,%r13
	adcq	$0,%rdx
	movq	%r13,-16(%rsp,%r15,8)
	movq	%rdx,%r13
	movq	%r10,%r11

	xorq	%rdx,%rdx
	addq	%r11,%r13
	adcq	$0,%rdx
	movq	%r13,-8(%rsp,%r9,8)
	movq	%rdx,(%rsp,%r9,8)

	leaq	1(%r14),%r14
	jmp	L$outer
.p2align	4
L$outer:
	movq	(%r12,%r14,8),%rbx
	xorq	%r15,%r15
	movq	%r8,%rbp
	movq	(%rsp),%r10
	mulq	%rbx
	addq	%rax,%r10
	movq	(%rcx),%rax
	adcq	$0,%rdx

	imulq	%r10,%rbp
	movq	%rdx,%r11

	mulq	%rbp
	addq	%rax,%r10
	movq	8(%rsi),%rax
	adcq	$0,%rdx
	movq	8(%rsp),%r10
	movq	%rdx,%r13

	leaq	1(%r15),%r15
	jmp	L$inner_enter

.p2align	4
L$inner:
	addq	%rax,%r13
	movq	(%rsi,%r15,8),%rax
	adcq	$0,%rdx
	addq	%r10,%r13
	movq	(%rsp,%r15,8),%r10
	adcq	$0,%rdx
	movq	%r13,-16(%rsp,%r15,8)
	movq	%rdx,%r13

L$inner_enter:
	mulq	%rbx
	addq	%rax,%r11
	movq	(%rcx,%r15,8),%rax
	adcq	$0,%rdx
	addq	%r11,%r10
	movq	%rdx,%r11
	adcq	$0,%r11
	leaq	1(%r15),%r15

	mulq	%rbp
	cmpq	%r9,%r15
	jne	L$inner

	addq	%rax,%r13
	movq	(%rsi),%rax
	adcq	$0,%rdx
	addq	%r10,%r13
	movq	(%rsp,%r15,8),%r10
	adcq	$0,%rdx
	movq	%r13,-16(%rsp,%r15,8)
	movq	%rdx,%r13

	xorq	%rdx,%rdx
	addq	%r11,%r13
	adcq	$0,%rdx
	addq	%r10,%r13
	adcq	$0,%rdx
	movq	%r13,-8(%rsp,%r9,8)
	movq	%rdx,(%rsp,%r9,8)

	leaq	1(%r14),%r14
	cmpq	%r9,%r14
	jb	L$outer

	xorq	%r14,%r14
	movq	(%rsp),%rax
	leaq	(%rsp),%rsi
	movq	%r9,%r15
	jmp	L$sub
.p2align	4
L$sub:	sbbq	(%rcx,%r14,8),%rax
	movq	%rax,(%rdi,%r14,8)
	movq	8(%rsi,%r14,8),%rax
	leaq	1(%r14),%r14
	decq	%r15
	jnz	L$sub

	sbbq	$0,%rax
	xorq	%r14,%r14
	movq	%r9,%r15
.p2align	4
L$copy:
	movq	(%rsp,%r14,8),%rsi
	movq	(%rdi,%r14,8),%rcx
	xorq	%rcx,%rsi
	andq	%rax,%rsi
	xorq	%rcx,%rsi
	movq	%r14,(%rsp,%r14,8)
	movq	%rsi,(%rdi,%r14,8)
	leaq	1(%r14),%r14
	subq	$1,%r15
	jnz	L$copy

	movq	8(%rsp,%r9,8),%rsi
	movq	$1,%rax
	movq	(%rsi),%r15
	movq	8(%rsi),%r14
	movq	16(%rsi),%r13
	movq	24(%rsi),%r12
	movq	32(%rsi),%rbp
	movq	40(%rsi),%rbx
	leaq	48(%rsi),%rsp
L$mul_epilogue:
	.byte	0xf3,0xc3


.p2align	4
bn_mul4x_mont:
L$mul4x_enter:
	pushq	%rbx
	pushq	%rbp
	pushq	%r12
	pushq	%r13
	pushq	%r14
	pushq	%r15

	movl	%r9d,%r9d
	leaq	4(%r9),%r10
	movq	%rsp,%r11
	negq	%r10
	leaq	(%rsp,%r10,8),%rsp
	andq	$-1024,%rsp

	movq	%r11,8(%rsp,%r9,8)
L$mul4x_body:
	movq	%rdi,16(%rsp,%r9,8)
	movq	%rdx,%r12
	movq	(%r8),%r8
	movq	(%r12),%rbx
	movq	(%rsi),%rax

	xorq	%r14,%r14
	xorq	%r15,%r15

	movq	%r8,%rbp
	mulq	%rbx
	movq	%rax,%r10
	movq	(%rcx),%rax

	imulq	%r10,%rbp
	movq	%rdx,%r11

	mulq	%rbp
	addq	%rax,%r10
	movq	8(%rsi),%rax
	adcq	$0,%rdx
	movq	%rdx,%rdi

	mulq	%rbx
	addq	%rax,%r11
	movq	8(%rcx),%rax
	adcq	$0,%rdx
	movq	%rdx,%r10

	mulq	%rbp
	addq	%rax,%rdi
	movq	16(%rsi),%rax
	adcq	$0,%rdx
	addq	%r11,%rdi
	leaq	4(%r15),%r15
	adcq	$0,%rdx
	movq	%rdi,(%rsp)
	movq	%rdx,%r13
	jmp	L$1st4x
.p2align	4
L$1st4x:
	mulq	%rbx
	addq	%rax,%r10
	movq	-16(%rcx,%r15,8),%rax
	adcq	$0,%rdx
	movq	%rdx,%r11

	mulq	%rbp
	addq	%rax,%r13
	movq	-8(%rsi,%r15,8),%rax
	adcq	$0,%rdx
	addq	%r10,%r13
	adcq	$0,%rdx
	movq	%r13,-24(%rsp,%r15,8)
	movq	%rdx,%rdi

	mulq	%rbx
	addq	%rax,%r11
	movq	-8(%rcx,%r15,8),%rax
	adcq	$0,%rdx
	movq	%rdx,%r10

	mulq	%rbp
	addq	%rax,%rdi
	movq	(%rsi,%r15,8),%rax
	adcq	$0,%rdx
	addq	%r11,%rdi
	adcq	$0,%rdx
	movq	%rdi,-16(%rsp,%r15,8)
	movq	%rdx,%r13

	mulq	%rbx
	addq	%rax,%r10
	movq	(%rcx,%r15,8),%rax
	adcq	$0,%rdx
	movq	%rdx,%r11

	mulq	%rbp
	addq	%rax,%r13
	movq	8(%rsi,%r15,8),%rax
	adcq	$0,%rdx
	addq	%r10,%r13
	adcq	$0,%rdx
	movq	%r13,-8(%rsp,%r15,8)
	movq	%rdx,%rdi

	mulq	%rbx
	addq	%rax,%r11
	movq	8(%rcx,%r15,8),%rax
	adcq	$0,%rdx
	leaq	4(%r15),%r15
	movq	%rdx,%r10

	mulq	%rbp
	addq	%rax,%rdi
	movq	-16(%rsi,%r15,8),%rax
	adcq	$0,%rdx
	addq	%r11,%rdi
	adcq	$0,%rdx
	movq	%rdi,-32(%rsp,%r15,8)
	movq	%rdx,%r13
	cmpq	%r9,%r15
	jb	L$1st4x

	mulq	%rbx
	addq	%rax,%r10
	movq	-16(%rcx,%r15,8),%rax
	adcq	$0,%rdx
	movq	%rdx,%r11

	mulq	%rbp
	addq	%rax,%r13
	movq	-8(%rsi,%r15,8),%rax
	adcq	$0,%rdx
	addq	%r10,%r13
	adcq	$0,%rdx
	movq	%r13,-24(%rsp,%r15,8)
	movq	%rdx,%rdi

	mulq	%rbx
	addq	%rax,%r11
	movq	-8(%rcx,%r15,8),%rax
	adcq	$0,%rdx
	movq	%rdx,%r10

	mulq	%rbp
	addq	%rax,%rdi
	movq	(%rsi),%rax
	adcq	$0,%rdx
	addq	%r11,%rdi
	adcq	$0,%rdx
	movq	%rdi,-16(%rsp,%r15,8)
	movq	%rdx,%r13

	xorq	%rdi,%rdi
	addq	%r10,%r13
	adcq	$0,%rdi
	movq	%r13,-8(%rsp,%r15,8)
	movq	%rdi,(%rsp,%r15,8)

	leaq	1(%r14),%r14
.p2align	2
L$outer4x:
	movq	(%r12,%r14,8),%rbx
	xorq	%r15,%r15
	movq	(%rsp),%r10
	movq	%r8,%rbp
	mulq	%rbx
	addq	%rax,%r10
	movq	(%rcx),%rax
	adcq	$0,%rdx

	imulq	%r10,%rbp
	movq	%rdx,%r11

	mulq	%rbp
	addq	%rax,%r10
	movq	8(%rsi),%rax
	adcq	$0,%rdx
	movq	%rdx,%rdi

	mulq	%rbx
	addq	%rax,%r11
	movq	8(%rcx),%rax
	adcq	$0,%rdx
	addq	8(%rsp),%r11
	adcq	$0,%rdx
	movq	%rdx,%r10

	mulq	%rbp
	addq	%rax,%rdi
	movq	16(%rsi),%rax
	adcq	$0,%rdx
	addq	%r11,%rdi
	leaq	4(%r15),%r15
	adcq	$0,%rdx
	movq	%rdi,(%rsp)
	movq	%rdx,%r13
	jmp	L$inner4x
.p2align	4
L$inner4x:
	mulq	%rbx
	addq	%rax,%r10
	movq	-16(%rcx,%r15,8),%rax
	adcq	$0,%rdx
	addq	-16(%rsp,%r15,8),%r10
	adcq	$0,%rdx
	movq	%rdx,%r11

	mulq	%rbp
	addq	%rax,%r13
	movq	-8(%rsi,%r15,8),%rax
	adcq	$0,%rdx
	addq	%r10,%r13
	adcq	$0,%rdx
	movq	%r13,-24(%rsp,%r15,8)
	movq	%rdx,%rdi

	mulq	%rbx
	addq	%rax,%r11
	movq	-8(%rcx,%r15,8),%rax
	adcq	$0,%rdx
	addq	-8(%rsp,%r15,8),%r11
	adcq	$0,%rdx
	movq	%rdx,%r10

	mulq	%rbp
	addq	%rax,%rdi
	movq	(%rsi,%r15,8),%rax
	adcq	$0,%rdx
	addq	%r11,%rdi
	adcq	$0,%rdx
	movq	%rdi,-16(%rsp,%r15,8)
	movq	%rdx,%r13

	mulq	%rbx
	addq	%rax,%r10
	movq	(%rcx,%r15,8),%rax
	adcq	$0,%rdx
	addq	(%rsp,%r15,8),%r10
	adcq	$0,%rdx
	movq	%rdx,%r11

	mulq	%rbp
	addq	%rax,%r13
	movq	8(%rsi,%r15,8),%rax
	adcq	$0,%rdx
	addq	%r10,%r13
	adcq	$0,%rdx
	movq	%r13,-8(%rsp,%r15,8)
	movq	%rdx,%rdi

	mulq	%rbx
	addq	%rax,%r11
	movq	8(%rcx,%r15,8),%rax
	adcq	$0,%rdx
	addq	8(%rsp,%r15,8),%r11
	adcq	$0,%rdx
	leaq	4(%r15),%r15
	movq	%rdx,%r10

	mulq	%rbp
	addq	%rax,%rdi
	movq	-16(%rsi,%r15,8),%rax
	adcq	$0,%rdx
	addq	%r11,%rdi
	adcq	$0,%rdx
	movq	%rdi,-32(%rsp,%r15,8)
	movq	%rdx,%r13
	cmpq	%r9,%r15
	jb	L$inner4x

	mulq	%rbx
	addq	%rax,%r10
	movq	-16(%rcx,%r15,8),%rax
	adcq	$0,%rdx
	addq	-16(%rsp,%r15,8),%r10
	adcq	$0,%rdx
	movq	%rdx,%r11

	mulq	%rbp
	addq	%rax,%r13
	movq	-8(%rsi,%r15,8),%rax
	adcq	$0,%rdx
	addq	%r10,%r13
	adcq	$0,%rdx
	movq	%r13,-24(%rsp,%r15,8)
	movq	%rdx,%rdi

	mulq	%rbx
	addq	%rax,%r11
	movq	-8(%rcx,%r15,8),%rax
	adcq	$0,%rdx
	addq	-8(%rsp,%r15,8),%r11
	adcq	$0,%rdx
	leaq	1(%r14),%r14
	movq	%rdx,%r10

	mulq	%rbp
	addq	%rax,%rdi
	movq	(%rsi),%rax
	adcq	$0,%rdx
	addq	%r11,%rdi
	adcq	$0,%rdx
	movq	%rdi,-16(%rsp,%r15,8)
	movq	%rdx,%r13

	xorq	%rdi,%rdi
	addq	%r10,%r13
	adcq	$0,%rdi
	addq	(%rsp,%r9,8),%r13
	adcq	$0,%rdi
	movq	%r13,-8(%rsp,%r15,8)
	movq	%rdi,(%rsp,%r15,8)

	cmpq	%r9,%r14
	jb	L$outer4x
	movq	16(%rsp,%r9,8),%rdi
	movq	0(%rsp),%rax
	movq	8(%rsp),%rdx
	shrq	$2,%r9
	leaq	(%rsp),%rsi
	xorq	%r14,%r14

	subq	0(%rcx),%rax
	movq	16(%rsi),%rbx
	movq	24(%rsi),%rbp
	sbbq	8(%rcx),%rdx
	leaq	-1(%r9),%r15
	jmp	L$sub4x
.p2align	4
L$sub4x:
	movq	%rax,0(%rdi,%r14,8)
	movq	%rdx,8(%rdi,%r14,8)
	sbbq	16(%rcx,%r14,8),%rbx
	movq	32(%rsi,%r14,8),%rax
	movq	40(%rsi,%r14,8),%rdx
	sbbq	24(%rcx,%r14,8),%rbp
	movq	%rbx,16(%rdi,%r14,8)
	movq	%rbp,24(%rdi,%r14,8)
	sbbq	32(%rcx,%r14,8),%rax
	movq	48(%rsi,%r14,8),%rbx
	movq	56(%rsi,%r14,8),%rbp
	sbbq	40(%rcx,%r14,8),%rdx
	leaq	4(%r14),%r14
	decq	%r15
	jnz	L$sub4x

	movq	%rax,0(%rdi,%r14,8)
	movq	32(%rsi,%r14,8),%rax
	sbbq	16(%rcx,%r14,8),%rbx
	movq	%rdx,8(%rdi,%r14,8)
	sbbq	24(%rcx,%r14,8),%rbp
	movq	%rbx,16(%rdi,%r14,8)

	sbbq	$0,%rax
	movq	%rax,%xmm0
	punpcklqdq	%xmm0,%xmm0
	movq	%rbp,24(%rdi,%r14,8)
	xorq	%r14,%r14

	movq	%r9,%r15
	pxor	%xmm5,%xmm5
	jmp	L$copy4x
.p2align	4
L$copy4x:
	movdqu	(%rsp,%r14,1),%xmm2
	movdqu	16(%rsp,%r14,1),%xmm4
	movdqu	(%rdi,%r14,1),%xmm1
	movdqu	16(%rdi,%r14,1),%xmm3
	pxor	%xmm1,%xmm2
	pxor	%xmm3,%xmm4
	pand	%xmm0,%xmm2
	pand	%xmm0,%xmm4
	pxor	%xmm1,%xmm2
	pxor	%xmm3,%xmm4
	movdqu	%xmm2,(%rdi,%r14,1)
	movdqu	%xmm4,16(%rdi,%r14,1)
	movdqa	%xmm5,(%rsp,%r14,1)
	movdqa	%xmm5,16(%rsp,%r14,1)

	leaq	32(%r14),%r14
	decq	%r15
	jnz	L$copy4x

	shlq	$2,%r9
	movq	8(%rsp,%r9,8),%rsi
	movq	$1,%rax
	movq	(%rsi),%r15
	movq	8(%rsi),%r14
	movq	16(%rsi),%r13
	movq	24(%rsi),%r12
	movq	32(%rsi),%rbp
	movq	40(%rsi),%rbx
	leaq	48(%rsi),%rsp
L$mul4x_epilogue:
	.byte	0xf3,0xc3




.p2align	5
bn_sqr8x_mont:
L$sqr8x_enter:
	movq	%rsp,%rax
	pushq	%rbx
	pushq	%rbp
	pushq	%r12
	pushq	%r13
	pushq	%r14
	pushq	%r15

	movl	%r9d,%r10d
	shll	$3,%r9d
	shlq	$3+2,%r10
	negq	%r9






	leaq	-64(%rsp,%r9,4),%r11
	movq	(%r8),%r8
	subq	%rsi,%r11
	andq	$4095,%r11
	cmpq	%r11,%r10
	jb	L$sqr8x_sp_alt
	subq	%r11,%rsp
	leaq	-64(%rsp,%r9,4),%rsp
	jmp	L$sqr8x_sp_done

.p2align	5
L$sqr8x_sp_alt:
	leaq	4096-64(,%r9,4),%r10
	leaq	-64(%rsp,%r9,4),%rsp
	subq	%r10,%r11
	movq	$0,%r10
	cmovcq	%r10,%r11
	subq	%r11,%rsp
L$sqr8x_sp_done:
	andq	$-64,%rsp
	movq	%r9,%r10
	negq	%r9

	leaq	64(%rsp,%r9,2),%r11
	movq	%r8,32(%rsp)
	movq	%rax,40(%rsp)
L$sqr8x_body:

	movq	%r9,%rbp
.byte	102,73,15,110,211
	shrq	$3+2,%rbp
	movl	_OPENSSL_ia32cap_P+8(%rip),%eax
	jmp	L$sqr8x_copy_n

.p2align	5
L$sqr8x_copy_n:
	movq	0(%rcx),%xmm0
	movq	8(%rcx),%xmm1
	movq	16(%rcx),%xmm3
	movq	24(%rcx),%xmm4
	leaq	32(%rcx),%rcx
	movdqa	%xmm0,0(%r11)
	movdqa	%xmm1,16(%r11)
	movdqa	%xmm3,32(%r11)
	movdqa	%xmm4,48(%r11)
	leaq	64(%r11),%r11
	decq	%rbp
	jnz	L$sqr8x_copy_n

	pxor	%xmm0,%xmm0
.byte	102,72,15,110,207
.byte	102,73,15,110,218
	call	_bn_sqr8x_internal

	pxor	%xmm0,%xmm0
	leaq	48(%rsp),%rax
	leaq	64(%rsp,%r9,2),%rdx
	shrq	$3+2,%r9
	movq	40(%rsp),%rsi
	jmp	L$sqr8x_zero

.p2align	5
L$sqr8x_zero:
	movdqa	%xmm0,0(%rax)
	movdqa	%xmm0,16(%rax)
	movdqa	%xmm0,32(%rax)
	movdqa	%xmm0,48(%rax)
	leaq	64(%rax),%rax
	movdqa	%xmm0,0(%rdx)
	movdqa	%xmm0,16(%rdx)
	movdqa	%xmm0,32(%rdx)
	movdqa	%xmm0,48(%rdx)
	leaq	64(%rdx),%rdx
	decq	%r9
	jnz	L$sqr8x_zero

	movq	$1,%rax
	movq	-48(%rsi),%r15
	movq	-40(%rsi),%r14
	movq	-32(%rsi),%r13
	movq	-24(%rsi),%r12
	movq	-16(%rsi),%rbp
	movq	-8(%rsi),%rbx
	leaq	(%rsi),%rsp
L$sqr8x_epilogue:
	.byte	0xf3,0xc3

.byte	77,111,110,116,103,111,109,101,114,121,32,77,117,108,116,105,112,108,105,99,97,116,105,111,110,32,102,111,114,32,120,56,54,95,54,52,44,32,67,82,89,80,84,79,71,65,77,83,32,98,121,32,60,97,112,112,114,111,64,111,112,101,110,115,115,108,46,111,114,103,62,0
.p2align	4
#endif
