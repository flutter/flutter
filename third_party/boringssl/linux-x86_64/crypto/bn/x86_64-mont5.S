#if defined(__x86_64__)
.text	

.extern	OPENSSL_ia32cap_P
.hidden OPENSSL_ia32cap_P

.globl	bn_mul_mont_gather5
.hidden bn_mul_mont_gather5
.type	bn_mul_mont_gather5,@function
.align	64
bn_mul_mont_gather5:
	testl	$7,%r9d
	jnz	.Lmul_enter
	jmp	.Lmul4x_enter

.align	16
.Lmul_enter:
	movl	%r9d,%r9d
	movq	%rsp,%rax
	movl	8(%rsp),%r10d
	pushq	%rbx
	pushq	%rbp
	pushq	%r12
	pushq	%r13
	pushq	%r14
	pushq	%r15
	leaq	2(%r9),%r11
	negq	%r11
	leaq	(%rsp,%r11,8),%rsp
	andq	$-1024,%rsp

	movq	%rax,8(%rsp,%r9,8)
.Lmul_body:
	movq	%rdx,%r12
	movq	%r10,%r11
	shrq	$3,%r10
	andq	$7,%r11
	notq	%r10
	leaq	.Lmagic_masks(%rip),%rax
	andq	$3,%r10
	leaq	96(%r12,%r11,8),%r12
	movq	0(%rax,%r10,8),%xmm4
	movq	8(%rax,%r10,8),%xmm5
	movq	16(%rax,%r10,8),%xmm6
	movq	24(%rax,%r10,8),%xmm7

	movq	-96(%r12),%xmm0
	movq	-32(%r12),%xmm1
	pand	%xmm4,%xmm0
	movq	32(%r12),%xmm2
	pand	%xmm5,%xmm1
	movq	96(%r12),%xmm3
	pand	%xmm6,%xmm2
	por	%xmm1,%xmm0
	pand	%xmm7,%xmm3
	por	%xmm2,%xmm0
	leaq	256(%r12),%r12
	por	%xmm3,%xmm0

.byte	102,72,15,126,195

	movq	(%r8),%r8
	movq	(%rsi),%rax

	xorq	%r14,%r14
	xorq	%r15,%r15

	movq	-96(%r12),%xmm0
	movq	-32(%r12),%xmm1
	pand	%xmm4,%xmm0
	movq	32(%r12),%xmm2
	pand	%xmm5,%xmm1

	movq	%r8,%rbp
	mulq	%rbx
	movq	%rax,%r10
	movq	(%rcx),%rax

	movq	96(%r12),%xmm3
	pand	%xmm6,%xmm2
	por	%xmm1,%xmm0
	pand	%xmm7,%xmm3

	imulq	%r10,%rbp
	movq	%rdx,%r11

	por	%xmm2,%xmm0
	leaq	256(%r12),%r12
	por	%xmm3,%xmm0

	mulq	%rbp
	addq	%rax,%r10
	movq	8(%rsi),%rax
	adcq	$0,%rdx
	movq	%rdx,%r13

	leaq	1(%r15),%r15
	jmp	.L1st_enter

.align	16
.L1st:
	addq	%rax,%r13
	movq	(%rsi,%r15,8),%rax
	adcq	$0,%rdx
	addq	%r11,%r13
	movq	%r10,%r11
	adcq	$0,%rdx
	movq	%r13,-16(%rsp,%r15,8)
	movq	%rdx,%r13

.L1st_enter:
	mulq	%rbx
	addq	%rax,%r11
	movq	(%rcx,%r15,8),%rax
	adcq	$0,%rdx
	leaq	1(%r15),%r15
	movq	%rdx,%r10

	mulq	%rbp
	cmpq	%r9,%r15
	jne	.L1st

.byte	102,72,15,126,195

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
	jmp	.Louter
.align	16
.Louter:
	xorq	%r15,%r15
	movq	%r8,%rbp
	movq	(%rsp),%r10

	movq	-96(%r12),%xmm0
	movq	-32(%r12),%xmm1
	pand	%xmm4,%xmm0
	movq	32(%r12),%xmm2
	pand	%xmm5,%xmm1

	mulq	%rbx
	addq	%rax,%r10
	movq	(%rcx),%rax
	adcq	$0,%rdx

	movq	96(%r12),%xmm3
	pand	%xmm6,%xmm2
	por	%xmm1,%xmm0
	pand	%xmm7,%xmm3

	imulq	%r10,%rbp
	movq	%rdx,%r11

	por	%xmm2,%xmm0
	leaq	256(%r12),%r12
	por	%xmm3,%xmm0

	mulq	%rbp
	addq	%rax,%r10
	movq	8(%rsi),%rax
	adcq	$0,%rdx
	movq	8(%rsp),%r10
	movq	%rdx,%r13

	leaq	1(%r15),%r15
	jmp	.Linner_enter

.align	16
.Linner:
	addq	%rax,%r13
	movq	(%rsi,%r15,8),%rax
	adcq	$0,%rdx
	addq	%r10,%r13
	movq	(%rsp,%r15,8),%r10
	adcq	$0,%rdx
	movq	%r13,-16(%rsp,%r15,8)
	movq	%rdx,%r13

.Linner_enter:
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
	jne	.Linner

.byte	102,72,15,126,195

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
	jb	.Louter

	xorq	%r14,%r14
	movq	(%rsp),%rax
	leaq	(%rsp),%rsi
	movq	%r9,%r15
	jmp	.Lsub
.align	16
.Lsub:	sbbq	(%rcx,%r14,8),%rax
	movq	%rax,(%rdi,%r14,8)
	movq	8(%rsi,%r14,8),%rax
	leaq	1(%r14),%r14
	decq	%r15
	jnz	.Lsub

	sbbq	$0,%rax
	xorq	%r14,%r14
	movq	%r9,%r15
.align	16
.Lcopy:
	movq	(%rsp,%r14,8),%rsi
	movq	(%rdi,%r14,8),%rcx
	xorq	%rcx,%rsi
	andq	%rax,%rsi
	xorq	%rcx,%rsi
	movq	%r14,(%rsp,%r14,8)
	movq	%rsi,(%rdi,%r14,8)
	leaq	1(%r14),%r14
	subq	$1,%r15
	jnz	.Lcopy

	movq	8(%rsp,%r9,8),%rsi
	movq	$1,%rax
	movq	-48(%rsi),%r15
	movq	-40(%rsi),%r14
	movq	-32(%rsi),%r13
	movq	-24(%rsi),%r12
	movq	-16(%rsi),%rbp
	movq	-8(%rsi),%rbx
	leaq	(%rsi),%rsp
.Lmul_epilogue:
	.byte	0xf3,0xc3
.size	bn_mul_mont_gather5,.-bn_mul_mont_gather5
.type	bn_mul4x_mont_gather5,@function
.align	32
bn_mul4x_mont_gather5:
.Lmul4x_enter:
.byte	0x67
	movq	%rsp,%rax
	pushq	%rbx
	pushq	%rbp
	pushq	%r12
	pushq	%r13
	pushq	%r14
	pushq	%r15
.byte	0x67
	movl	%r9d,%r10d
	shll	$3,%r9d
	shll	$3+2,%r10d
	negq	%r9








	leaq	-64(%rsp,%r9,2),%r11
	subq	%rsi,%r11
	andq	$4095,%r11
	cmpq	%r11,%r10
	jb	.Lmul4xsp_alt
	subq	%r11,%rsp
	leaq	-64(%rsp,%r9,2),%rsp
	jmp	.Lmul4xsp_done

.align	32
.Lmul4xsp_alt:
	leaq	4096-64(,%r9,2),%r10
	leaq	-64(%rsp,%r9,2),%rsp
	subq	%r10,%r11
	movq	$0,%r10
	cmovcq	%r10,%r11
	subq	%r11,%rsp
.Lmul4xsp_done:
	andq	$-64,%rsp
	negq	%r9

	movq	%rax,40(%rsp)
.Lmul4x_body:

	call	mul4x_internal

	movq	40(%rsp),%rsi
	movq	$1,%rax
	movq	-48(%rsi),%r15
	movq	-40(%rsi),%r14
	movq	-32(%rsi),%r13
	movq	-24(%rsi),%r12
	movq	-16(%rsi),%rbp
	movq	-8(%rsi),%rbx
	leaq	(%rsi),%rsp
.Lmul4x_epilogue:
	.byte	0xf3,0xc3
.size	bn_mul4x_mont_gather5,.-bn_mul4x_mont_gather5

.type	mul4x_internal,@function
.align	32
mul4x_internal:
	shlq	$5,%r9
	movl	8(%rax),%r10d
	leaq	256(%rdx,%r9,1),%r13
	shrq	$5,%r9
	movq	%r10,%r11
	shrq	$3,%r10
	andq	$7,%r11
	notq	%r10
	leaq	.Lmagic_masks(%rip),%rax
	andq	$3,%r10
	leaq	96(%rdx,%r11,8),%r12
	movq	0(%rax,%r10,8),%xmm4
	movq	8(%rax,%r10,8),%xmm5
	addq	$7,%r11
	movq	16(%rax,%r10,8),%xmm6
	movq	24(%rax,%r10,8),%xmm7
	andq	$7,%r11

	movq	-96(%r12),%xmm0
	leaq	256(%r12),%r14
	movq	-32(%r12),%xmm1
	pand	%xmm4,%xmm0
	movq	32(%r12),%xmm2
	pand	%xmm5,%xmm1
	movq	96(%r12),%xmm3
	pand	%xmm6,%xmm2
.byte	0x67
	por	%xmm1,%xmm0
	movq	-96(%r14),%xmm1
.byte	0x67
	pand	%xmm7,%xmm3
.byte	0x67
	por	%xmm2,%xmm0
	movq	-32(%r14),%xmm2
.byte	0x67
	pand	%xmm4,%xmm1
.byte	0x67
	por	%xmm3,%xmm0
	movq	32(%r14),%xmm3

.byte	102,72,15,126,195
	movq	96(%r14),%xmm0
	movq	%r13,16+8(%rsp)
	movq	%rdi,56+8(%rsp)

	movq	(%r8),%r8
	movq	(%rsi),%rax
	leaq	(%rsi,%r9,1),%rsi
	negq	%r9

	movq	%r8,%rbp
	mulq	%rbx
	movq	%rax,%r10
	movq	(%rcx),%rax

	pand	%xmm5,%xmm2
	pand	%xmm6,%xmm3
	por	%xmm2,%xmm1

	imulq	%r10,%rbp







	leaq	64+8(%rsp,%r11,8),%r14
	movq	%rdx,%r11

	pand	%xmm7,%xmm0
	por	%xmm3,%xmm1
	leaq	512(%r12),%r12
	por	%xmm1,%xmm0

	mulq	%rbp
	addq	%rax,%r10
	movq	8(%rsi,%r9,1),%rax
	adcq	$0,%rdx
	movq	%rdx,%rdi

	mulq	%rbx
	addq	%rax,%r11
	movq	16(%rcx),%rax
	adcq	$0,%rdx
	movq	%rdx,%r10

	mulq	%rbp
	addq	%rax,%rdi
	movq	16(%rsi,%r9,1),%rax
	adcq	$0,%rdx
	addq	%r11,%rdi
	leaq	32(%r9),%r15
	leaq	64(%rcx),%rcx
	adcq	$0,%rdx
	movq	%rdi,(%r14)
	movq	%rdx,%r13
	jmp	.L1st4x

.align	32
.L1st4x:
	mulq	%rbx
	addq	%rax,%r10
	movq	-32(%rcx),%rax
	leaq	32(%r14),%r14
	adcq	$0,%rdx
	movq	%rdx,%r11

	mulq	%rbp
	addq	%rax,%r13
	movq	-8(%rsi,%r15,1),%rax
	adcq	$0,%rdx
	addq	%r10,%r13
	adcq	$0,%rdx
	movq	%r13,-24(%r14)
	movq	%rdx,%rdi

	mulq	%rbx
	addq	%rax,%r11
	movq	-16(%rcx),%rax
	adcq	$0,%rdx
	movq	%rdx,%r10

	mulq	%rbp
	addq	%rax,%rdi
	movq	(%rsi,%r15,1),%rax
	adcq	$0,%rdx
	addq	%r11,%rdi
	adcq	$0,%rdx
	movq	%rdi,-16(%r14)
	movq	%rdx,%r13

	mulq	%rbx
	addq	%rax,%r10
	movq	0(%rcx),%rax
	adcq	$0,%rdx
	movq	%rdx,%r11

	mulq	%rbp
	addq	%rax,%r13
	movq	8(%rsi,%r15,1),%rax
	adcq	$0,%rdx
	addq	%r10,%r13
	adcq	$0,%rdx
	movq	%r13,-8(%r14)
	movq	%rdx,%rdi

	mulq	%rbx
	addq	%rax,%r11
	movq	16(%rcx),%rax
	adcq	$0,%rdx
	movq	%rdx,%r10

	mulq	%rbp
	addq	%rax,%rdi
	movq	16(%rsi,%r15,1),%rax
	adcq	$0,%rdx
	addq	%r11,%rdi
	leaq	64(%rcx),%rcx
	adcq	$0,%rdx
	movq	%rdi,(%r14)
	movq	%rdx,%r13

	addq	$32,%r15
	jnz	.L1st4x

	mulq	%rbx
	addq	%rax,%r10
	movq	-32(%rcx),%rax
	leaq	32(%r14),%r14
	adcq	$0,%rdx
	movq	%rdx,%r11

	mulq	%rbp
	addq	%rax,%r13
	movq	-8(%rsi),%rax
	adcq	$0,%rdx
	addq	%r10,%r13
	adcq	$0,%rdx
	movq	%r13,-24(%r14)
	movq	%rdx,%rdi

	mulq	%rbx
	addq	%rax,%r11
	movq	-16(%rcx),%rax
	adcq	$0,%rdx
	movq	%rdx,%r10

	mulq	%rbp
	addq	%rax,%rdi
	movq	(%rsi,%r9,1),%rax
	adcq	$0,%rdx
	addq	%r11,%rdi
	adcq	$0,%rdx
	movq	%rdi,-16(%r14)
	movq	%rdx,%r13

.byte	102,72,15,126,195
	leaq	(%rcx,%r9,2),%rcx

	xorq	%rdi,%rdi
	addq	%r10,%r13
	adcq	$0,%rdi
	movq	%r13,-8(%r14)

	jmp	.Louter4x

.align	32
.Louter4x:
	movq	(%r14,%r9,1),%r10
	movq	%r8,%rbp
	mulq	%rbx
	addq	%rax,%r10
	movq	(%rcx),%rax
	adcq	$0,%rdx

	movq	-96(%r12),%xmm0
	movq	-32(%r12),%xmm1
	pand	%xmm4,%xmm0
	movq	32(%r12),%xmm2
	pand	%xmm5,%xmm1
	movq	96(%r12),%xmm3

	imulq	%r10,%rbp
.byte	0x67
	movq	%rdx,%r11
	movq	%rdi,(%r14)

	pand	%xmm6,%xmm2
	por	%xmm1,%xmm0
	pand	%xmm7,%xmm3
	por	%xmm2,%xmm0
	leaq	(%r14,%r9,1),%r14
	leaq	256(%r12),%r12
	por	%xmm3,%xmm0

	mulq	%rbp
	addq	%rax,%r10
	movq	8(%rsi,%r9,1),%rax
	adcq	$0,%rdx
	movq	%rdx,%rdi

	mulq	%rbx
	addq	%rax,%r11
	movq	16(%rcx),%rax
	adcq	$0,%rdx
	addq	8(%r14),%r11
	adcq	$0,%rdx
	movq	%rdx,%r10

	mulq	%rbp
	addq	%rax,%rdi
	movq	16(%rsi,%r9,1),%rax
	adcq	$0,%rdx
	addq	%r11,%rdi
	leaq	32(%r9),%r15
	leaq	64(%rcx),%rcx
	adcq	$0,%rdx
	movq	%rdx,%r13
	jmp	.Linner4x

.align	32
.Linner4x:
	mulq	%rbx
	addq	%rax,%r10
	movq	-32(%rcx),%rax
	adcq	$0,%rdx
	addq	16(%r14),%r10
	leaq	32(%r14),%r14
	adcq	$0,%rdx
	movq	%rdx,%r11

	mulq	%rbp
	addq	%rax,%r13
	movq	-8(%rsi,%r15,1),%rax
	adcq	$0,%rdx
	addq	%r10,%r13
	adcq	$0,%rdx
	movq	%rdi,-32(%r14)
	movq	%rdx,%rdi

	mulq	%rbx
	addq	%rax,%r11
	movq	-16(%rcx),%rax
	adcq	$0,%rdx
	addq	-8(%r14),%r11
	adcq	$0,%rdx
	movq	%rdx,%r10

	mulq	%rbp
	addq	%rax,%rdi
	movq	(%rsi,%r15,1),%rax
	adcq	$0,%rdx
	addq	%r11,%rdi
	adcq	$0,%rdx
	movq	%r13,-24(%r14)
	movq	%rdx,%r13

	mulq	%rbx
	addq	%rax,%r10
	movq	0(%rcx),%rax
	adcq	$0,%rdx
	addq	(%r14),%r10
	adcq	$0,%rdx
	movq	%rdx,%r11

	mulq	%rbp
	addq	%rax,%r13
	movq	8(%rsi,%r15,1),%rax
	adcq	$0,%rdx
	addq	%r10,%r13
	adcq	$0,%rdx
	movq	%rdi,-16(%r14)
	movq	%rdx,%rdi

	mulq	%rbx
	addq	%rax,%r11
	movq	16(%rcx),%rax
	adcq	$0,%rdx
	addq	8(%r14),%r11
	adcq	$0,%rdx
	movq	%rdx,%r10

	mulq	%rbp
	addq	%rax,%rdi
	movq	16(%rsi,%r15,1),%rax
	adcq	$0,%rdx
	addq	%r11,%rdi
	leaq	64(%rcx),%rcx
	adcq	$0,%rdx
	movq	%r13,-8(%r14)
	movq	%rdx,%r13

	addq	$32,%r15
	jnz	.Linner4x

	mulq	%rbx
	addq	%rax,%r10
	movq	-32(%rcx),%rax
	adcq	$0,%rdx
	addq	16(%r14),%r10
	leaq	32(%r14),%r14
	adcq	$0,%rdx
	movq	%rdx,%r11

	mulq	%rbp
	addq	%rax,%r13
	movq	-8(%rsi),%rax
	adcq	$0,%rdx
	addq	%r10,%r13
	adcq	$0,%rdx
	movq	%rdi,-32(%r14)
	movq	%rdx,%rdi

	mulq	%rbx
	addq	%rax,%r11
	movq	%rbp,%rax
	movq	-16(%rcx),%rbp
	adcq	$0,%rdx
	addq	-8(%r14),%r11
	adcq	$0,%rdx
	movq	%rdx,%r10

	mulq	%rbp
	addq	%rax,%rdi
	movq	(%rsi,%r9,1),%rax
	adcq	$0,%rdx
	addq	%r11,%rdi
	adcq	$0,%rdx
	movq	%r13,-24(%r14)
	movq	%rdx,%r13

.byte	102,72,15,126,195
	movq	%rdi,-16(%r14)
	leaq	(%rcx,%r9,2),%rcx

	xorq	%rdi,%rdi
	addq	%r10,%r13
	adcq	$0,%rdi
	addq	(%r14),%r13
	adcq	$0,%rdi
	movq	%r13,-8(%r14)

	cmpq	16+8(%rsp),%r12
	jb	.Louter4x
	subq	%r13,%rbp
	adcq	%r15,%r15
	orq	%r15,%rdi
	xorq	$1,%rdi
	leaq	(%r14,%r9,1),%rbx
	leaq	(%rcx,%rdi,8),%rbp
	movq	%r9,%rcx
	sarq	$3+2,%rcx
	movq	56+8(%rsp),%rdi
	jmp	.Lsqr4x_sub
.size	mul4x_internal,.-mul4x_internal
.globl	bn_power5
.hidden bn_power5
.type	bn_power5,@function
.align	32
bn_power5:
	movq	%rsp,%rax
	pushq	%rbx
	pushq	%rbp
	pushq	%r12
	pushq	%r13
	pushq	%r14
	pushq	%r15
	movl	%r9d,%r10d
	shll	$3,%r9d
	shll	$3+2,%r10d
	negq	%r9
	movq	(%r8),%r8







	leaq	-64(%rsp,%r9,2),%r11
	subq	%rsi,%r11
	andq	$4095,%r11
	cmpq	%r11,%r10
	jb	.Lpwr_sp_alt
	subq	%r11,%rsp
	leaq	-64(%rsp,%r9,2),%rsp
	jmp	.Lpwr_sp_done

.align	32
.Lpwr_sp_alt:
	leaq	4096-64(,%r9,2),%r10
	leaq	-64(%rsp,%r9,2),%rsp
	subq	%r10,%r11
	movq	$0,%r10
	cmovcq	%r10,%r11
	subq	%r11,%rsp
.Lpwr_sp_done:
	andq	$-64,%rsp
	movq	%r9,%r10
	negq	%r9










	movq	%r8,32(%rsp)
	movq	%rax,40(%rsp)
.Lpower5_body:
.byte	102,72,15,110,207
.byte	102,72,15,110,209
.byte	102,73,15,110,218
.byte	102,72,15,110,226

	call	__bn_sqr8x_internal
	call	__bn_sqr8x_internal
	call	__bn_sqr8x_internal
	call	__bn_sqr8x_internal
	call	__bn_sqr8x_internal

.byte	102,72,15,126,209
.byte	102,72,15,126,226
	movq	%rsi,%rdi
	movq	40(%rsp),%rax
	leaq	32(%rsp),%r8

	call	mul4x_internal

	movq	40(%rsp),%rsi
	movq	$1,%rax
	movq	-48(%rsi),%r15
	movq	-40(%rsi),%r14
	movq	-32(%rsi),%r13
	movq	-24(%rsi),%r12
	movq	-16(%rsi),%rbp
	movq	-8(%rsi),%rbx
	leaq	(%rsi),%rsp
.Lpower5_epilogue:
	.byte	0xf3,0xc3
.size	bn_power5,.-bn_power5

.globl	bn_sqr8x_internal
.hidden bn_sqr8x_internal
.hidden	bn_sqr8x_internal
.type	bn_sqr8x_internal,@function
.align	32
bn_sqr8x_internal:
__bn_sqr8x_internal:









































































	leaq	32(%r10),%rbp
	leaq	(%rsi,%r9,1),%rsi

	movq	%r9,%rcx


	movq	-32(%rsi,%rbp,1),%r14
	leaq	48+8(%rsp,%r9,2),%rdi
	movq	-24(%rsi,%rbp,1),%rax
	leaq	-32(%rdi,%rbp,1),%rdi
	movq	-16(%rsi,%rbp,1),%rbx
	movq	%rax,%r15

	mulq	%r14
	movq	%rax,%r10
	movq	%rbx,%rax
	movq	%rdx,%r11
	movq	%r10,-24(%rdi,%rbp,1)

	mulq	%r14
	addq	%rax,%r11
	movq	%rbx,%rax
	adcq	$0,%rdx
	movq	%r11,-16(%rdi,%rbp,1)
	movq	%rdx,%r10


	movq	-8(%rsi,%rbp,1),%rbx
	mulq	%r15
	movq	%rax,%r12
	movq	%rbx,%rax
	movq	%rdx,%r13

	leaq	(%rbp),%rcx
	mulq	%r14
	addq	%rax,%r10
	movq	%rbx,%rax
	movq	%rdx,%r11
	adcq	$0,%r11
	addq	%r12,%r10
	adcq	$0,%r11
	movq	%r10,-8(%rdi,%rcx,1)
	jmp	.Lsqr4x_1st

.align	32
.Lsqr4x_1st:
	movq	(%rsi,%rcx,1),%rbx
	mulq	%r15
	addq	%rax,%r13
	movq	%rbx,%rax
	movq	%rdx,%r12
	adcq	$0,%r12

	mulq	%r14
	addq	%rax,%r11
	movq	%rbx,%rax
	movq	8(%rsi,%rcx,1),%rbx
	movq	%rdx,%r10
	adcq	$0,%r10
	addq	%r13,%r11
	adcq	$0,%r10


	mulq	%r15
	addq	%rax,%r12
	movq	%rbx,%rax
	movq	%r11,(%rdi,%rcx,1)
	movq	%rdx,%r13
	adcq	$0,%r13

	mulq	%r14
	addq	%rax,%r10
	movq	%rbx,%rax
	movq	16(%rsi,%rcx,1),%rbx
	movq	%rdx,%r11
	adcq	$0,%r11
	addq	%r12,%r10
	adcq	$0,%r11

	mulq	%r15
	addq	%rax,%r13
	movq	%rbx,%rax
	movq	%r10,8(%rdi,%rcx,1)
	movq	%rdx,%r12
	adcq	$0,%r12

	mulq	%r14
	addq	%rax,%r11
	movq	%rbx,%rax
	movq	24(%rsi,%rcx,1),%rbx
	movq	%rdx,%r10
	adcq	$0,%r10
	addq	%r13,%r11
	adcq	$0,%r10


	mulq	%r15
	addq	%rax,%r12
	movq	%rbx,%rax
	movq	%r11,16(%rdi,%rcx,1)
	movq	%rdx,%r13
	adcq	$0,%r13
	leaq	32(%rcx),%rcx

	mulq	%r14
	addq	%rax,%r10
	movq	%rbx,%rax
	movq	%rdx,%r11
	adcq	$0,%r11
	addq	%r12,%r10
	adcq	$0,%r11
	movq	%r10,-8(%rdi,%rcx,1)

	cmpq	$0,%rcx
	jne	.Lsqr4x_1st

	mulq	%r15
	addq	%rax,%r13
	leaq	16(%rbp),%rbp
	adcq	$0,%rdx
	addq	%r11,%r13
	adcq	$0,%rdx

	movq	%r13,(%rdi)
	movq	%rdx,%r12
	movq	%rdx,8(%rdi)
	jmp	.Lsqr4x_outer

.align	32
.Lsqr4x_outer:
	movq	-32(%rsi,%rbp,1),%r14
	leaq	48+8(%rsp,%r9,2),%rdi
	movq	-24(%rsi,%rbp,1),%rax
	leaq	-32(%rdi,%rbp,1),%rdi
	movq	-16(%rsi,%rbp,1),%rbx
	movq	%rax,%r15

	mulq	%r14
	movq	-24(%rdi,%rbp,1),%r10
	addq	%rax,%r10
	movq	%rbx,%rax
	adcq	$0,%rdx
	movq	%r10,-24(%rdi,%rbp,1)
	movq	%rdx,%r11

	mulq	%r14
	addq	%rax,%r11
	movq	%rbx,%rax
	adcq	$0,%rdx
	addq	-16(%rdi,%rbp,1),%r11
	movq	%rdx,%r10
	adcq	$0,%r10
	movq	%r11,-16(%rdi,%rbp,1)

	xorq	%r12,%r12

	movq	-8(%rsi,%rbp,1),%rbx
	mulq	%r15
	addq	%rax,%r12
	movq	%rbx,%rax
	adcq	$0,%rdx
	addq	-8(%rdi,%rbp,1),%r12
	movq	%rdx,%r13
	adcq	$0,%r13

	mulq	%r14
	addq	%rax,%r10
	movq	%rbx,%rax
	adcq	$0,%rdx
	addq	%r12,%r10
	movq	%rdx,%r11
	adcq	$0,%r11
	movq	%r10,-8(%rdi,%rbp,1)

	leaq	(%rbp),%rcx
	jmp	.Lsqr4x_inner

.align	32
.Lsqr4x_inner:
	movq	(%rsi,%rcx,1),%rbx
	mulq	%r15
	addq	%rax,%r13
	movq	%rbx,%rax
	movq	%rdx,%r12
	adcq	$0,%r12
	addq	(%rdi,%rcx,1),%r13
	adcq	$0,%r12

.byte	0x67
	mulq	%r14
	addq	%rax,%r11
	movq	%rbx,%rax
	movq	8(%rsi,%rcx,1),%rbx
	movq	%rdx,%r10
	adcq	$0,%r10
	addq	%r13,%r11
	adcq	$0,%r10

	mulq	%r15
	addq	%rax,%r12
	movq	%r11,(%rdi,%rcx,1)
	movq	%rbx,%rax
	movq	%rdx,%r13
	adcq	$0,%r13
	addq	8(%rdi,%rcx,1),%r12
	leaq	16(%rcx),%rcx
	adcq	$0,%r13

	mulq	%r14
	addq	%rax,%r10
	movq	%rbx,%rax
	adcq	$0,%rdx
	addq	%r12,%r10
	movq	%rdx,%r11
	adcq	$0,%r11
	movq	%r10,-8(%rdi,%rcx,1)

	cmpq	$0,%rcx
	jne	.Lsqr4x_inner

.byte	0x67
	mulq	%r15
	addq	%rax,%r13
	adcq	$0,%rdx
	addq	%r11,%r13
	adcq	$0,%rdx

	movq	%r13,(%rdi)
	movq	%rdx,%r12
	movq	%rdx,8(%rdi)

	addq	$16,%rbp
	jnz	.Lsqr4x_outer


	movq	-32(%rsi),%r14
	leaq	48+8(%rsp,%r9,2),%rdi
	movq	-24(%rsi),%rax
	leaq	-32(%rdi,%rbp,1),%rdi
	movq	-16(%rsi),%rbx
	movq	%rax,%r15

	mulq	%r14
	addq	%rax,%r10
	movq	%rbx,%rax
	movq	%rdx,%r11
	adcq	$0,%r11

	mulq	%r14
	addq	%rax,%r11
	movq	%rbx,%rax
	movq	%r10,-24(%rdi)
	movq	%rdx,%r10
	adcq	$0,%r10
	addq	%r13,%r11
	movq	-8(%rsi),%rbx
	adcq	$0,%r10

	mulq	%r15
	addq	%rax,%r12
	movq	%rbx,%rax
	movq	%r11,-16(%rdi)
	movq	%rdx,%r13
	adcq	$0,%r13

	mulq	%r14
	addq	%rax,%r10
	movq	%rbx,%rax
	movq	%rdx,%r11
	adcq	$0,%r11
	addq	%r12,%r10
	adcq	$0,%r11
	movq	%r10,-8(%rdi)

	mulq	%r15
	addq	%rax,%r13
	movq	-16(%rsi),%rax
	adcq	$0,%rdx
	addq	%r11,%r13
	adcq	$0,%rdx

	movq	%r13,(%rdi)
	movq	%rdx,%r12
	movq	%rdx,8(%rdi)

	mulq	%rbx
	addq	$16,%rbp
	xorq	%r14,%r14
	subq	%r9,%rbp
	xorq	%r15,%r15

	addq	%r12,%rax
	adcq	$0,%rdx
	movq	%rax,8(%rdi)
	movq	%rdx,16(%rdi)
	movq	%r15,24(%rdi)

	movq	-16(%rsi,%rbp,1),%rax
	leaq	48+8(%rsp),%rdi
	xorq	%r10,%r10
	movq	8(%rdi),%r11

	leaq	(%r14,%r10,2),%r12
	shrq	$63,%r10
	leaq	(%rcx,%r11,2),%r13
	shrq	$63,%r11
	orq	%r10,%r13
	movq	16(%rdi),%r10
	movq	%r11,%r14
	mulq	%rax
	negq	%r15
	movq	24(%rdi),%r11
	adcq	%rax,%r12
	movq	-8(%rsi,%rbp,1),%rax
	movq	%r12,(%rdi)
	adcq	%rdx,%r13

	leaq	(%r14,%r10,2),%rbx
	movq	%r13,8(%rdi)
	sbbq	%r15,%r15
	shrq	$63,%r10
	leaq	(%rcx,%r11,2),%r8
	shrq	$63,%r11
	orq	%r10,%r8
	movq	32(%rdi),%r10
	movq	%r11,%r14
	mulq	%rax
	negq	%r15
	movq	40(%rdi),%r11
	adcq	%rax,%rbx
	movq	0(%rsi,%rbp,1),%rax
	movq	%rbx,16(%rdi)
	adcq	%rdx,%r8
	leaq	16(%rbp),%rbp
	movq	%r8,24(%rdi)
	sbbq	%r15,%r15
	leaq	64(%rdi),%rdi
	jmp	.Lsqr4x_shift_n_add

.align	32
.Lsqr4x_shift_n_add:
	leaq	(%r14,%r10,2),%r12
	shrq	$63,%r10
	leaq	(%rcx,%r11,2),%r13
	shrq	$63,%r11
	orq	%r10,%r13
	movq	-16(%rdi),%r10
	movq	%r11,%r14
	mulq	%rax
	negq	%r15
	movq	-8(%rdi),%r11
	adcq	%rax,%r12
	movq	-8(%rsi,%rbp,1),%rax
	movq	%r12,-32(%rdi)
	adcq	%rdx,%r13

	leaq	(%r14,%r10,2),%rbx
	movq	%r13,-24(%rdi)
	sbbq	%r15,%r15
	shrq	$63,%r10
	leaq	(%rcx,%r11,2),%r8
	shrq	$63,%r11
	orq	%r10,%r8
	movq	0(%rdi),%r10
	movq	%r11,%r14
	mulq	%rax
	negq	%r15
	movq	8(%rdi),%r11
	adcq	%rax,%rbx
	movq	0(%rsi,%rbp,1),%rax
	movq	%rbx,-16(%rdi)
	adcq	%rdx,%r8

	leaq	(%r14,%r10,2),%r12
	movq	%r8,-8(%rdi)
	sbbq	%r15,%r15
	shrq	$63,%r10
	leaq	(%rcx,%r11,2),%r13
	shrq	$63,%r11
	orq	%r10,%r13
	movq	16(%rdi),%r10
	movq	%r11,%r14
	mulq	%rax
	negq	%r15
	movq	24(%rdi),%r11
	adcq	%rax,%r12
	movq	8(%rsi,%rbp,1),%rax
	movq	%r12,0(%rdi)
	adcq	%rdx,%r13

	leaq	(%r14,%r10,2),%rbx
	movq	%r13,8(%rdi)
	sbbq	%r15,%r15
	shrq	$63,%r10
	leaq	(%rcx,%r11,2),%r8
	shrq	$63,%r11
	orq	%r10,%r8
	movq	32(%rdi),%r10
	movq	%r11,%r14
	mulq	%rax
	negq	%r15
	movq	40(%rdi),%r11
	adcq	%rax,%rbx
	movq	16(%rsi,%rbp,1),%rax
	movq	%rbx,16(%rdi)
	adcq	%rdx,%r8
	movq	%r8,24(%rdi)
	sbbq	%r15,%r15
	leaq	64(%rdi),%rdi
	addq	$32,%rbp
	jnz	.Lsqr4x_shift_n_add

	leaq	(%r14,%r10,2),%r12
.byte	0x67
	shrq	$63,%r10
	leaq	(%rcx,%r11,2),%r13
	shrq	$63,%r11
	orq	%r10,%r13
	movq	-16(%rdi),%r10
	movq	%r11,%r14
	mulq	%rax
	negq	%r15
	movq	-8(%rdi),%r11
	adcq	%rax,%r12
	movq	-8(%rsi),%rax
	movq	%r12,-32(%rdi)
	adcq	%rdx,%r13

	leaq	(%r14,%r10,2),%rbx
	movq	%r13,-24(%rdi)
	sbbq	%r15,%r15
	shrq	$63,%r10
	leaq	(%rcx,%r11,2),%r8
	shrq	$63,%r11
	orq	%r10,%r8
	mulq	%rax
	negq	%r15
	adcq	%rax,%rbx
	adcq	%rdx,%r8
	movq	%rbx,-16(%rdi)
	movq	%r8,-8(%rdi)
.byte	102,72,15,126,213
sqr8x_reduction:
	xorq	%rax,%rax
	leaq	(%rbp,%r9,2),%rcx
	leaq	48+8(%rsp,%r9,2),%rdx
	movq	%rcx,0+8(%rsp)
	leaq	48+8(%rsp,%r9,1),%rdi
	movq	%rdx,8+8(%rsp)
	negq	%r9
	jmp	.L8x_reduction_loop

.align	32
.L8x_reduction_loop:
	leaq	(%rdi,%r9,1),%rdi
.byte	0x66
	movq	0(%rdi),%rbx
	movq	8(%rdi),%r9
	movq	16(%rdi),%r10
	movq	24(%rdi),%r11
	movq	32(%rdi),%r12
	movq	40(%rdi),%r13
	movq	48(%rdi),%r14
	movq	56(%rdi),%r15
	movq	%rax,(%rdx)
	leaq	64(%rdi),%rdi

.byte	0x67
	movq	%rbx,%r8
	imulq	32+8(%rsp),%rbx
	movq	0(%rbp),%rax
	movl	$8,%ecx
	jmp	.L8x_reduce

.align	32
.L8x_reduce:
	mulq	%rbx
	movq	16(%rbp),%rax
	negq	%r8
	movq	%rdx,%r8
	adcq	$0,%r8

	mulq	%rbx
	addq	%rax,%r9
	movq	32(%rbp),%rax
	adcq	$0,%rdx
	addq	%r9,%r8
	movq	%rbx,48-8+8(%rsp,%rcx,8)
	movq	%rdx,%r9
	adcq	$0,%r9

	mulq	%rbx
	addq	%rax,%r10
	movq	48(%rbp),%rax
	adcq	$0,%rdx
	addq	%r10,%r9
	movq	32+8(%rsp),%rsi
	movq	%rdx,%r10
	adcq	$0,%r10

	mulq	%rbx
	addq	%rax,%r11
	movq	64(%rbp),%rax
	adcq	$0,%rdx
	imulq	%r8,%rsi
	addq	%r11,%r10
	movq	%rdx,%r11
	adcq	$0,%r11

	mulq	%rbx
	addq	%rax,%r12
	movq	80(%rbp),%rax
	adcq	$0,%rdx
	addq	%r12,%r11
	movq	%rdx,%r12
	adcq	$0,%r12

	mulq	%rbx
	addq	%rax,%r13
	movq	96(%rbp),%rax
	adcq	$0,%rdx
	addq	%r13,%r12
	movq	%rdx,%r13
	adcq	$0,%r13

	mulq	%rbx
	addq	%rax,%r14
	movq	112(%rbp),%rax
	adcq	$0,%rdx
	addq	%r14,%r13
	movq	%rdx,%r14
	adcq	$0,%r14

	mulq	%rbx
	movq	%rsi,%rbx
	addq	%rax,%r15
	movq	0(%rbp),%rax
	adcq	$0,%rdx
	addq	%r15,%r14
	movq	%rdx,%r15
	adcq	$0,%r15

	decl	%ecx
	jnz	.L8x_reduce

	leaq	128(%rbp),%rbp
	xorq	%rax,%rax
	movq	8+8(%rsp),%rdx
	cmpq	0+8(%rsp),%rbp
	jae	.L8x_no_tail

.byte	0x66
	addq	0(%rdi),%r8
	adcq	8(%rdi),%r9
	adcq	16(%rdi),%r10
	adcq	24(%rdi),%r11
	adcq	32(%rdi),%r12
	adcq	40(%rdi),%r13
	adcq	48(%rdi),%r14
	adcq	56(%rdi),%r15
	sbbq	%rsi,%rsi

	movq	48+56+8(%rsp),%rbx
	movl	$8,%ecx
	movq	0(%rbp),%rax
	jmp	.L8x_tail

.align	32
.L8x_tail:
	mulq	%rbx
	addq	%rax,%r8
	movq	16(%rbp),%rax
	movq	%r8,(%rdi)
	movq	%rdx,%r8
	adcq	$0,%r8

	mulq	%rbx
	addq	%rax,%r9
	movq	32(%rbp),%rax
	adcq	$0,%rdx
	addq	%r9,%r8
	leaq	8(%rdi),%rdi
	movq	%rdx,%r9
	adcq	$0,%r9

	mulq	%rbx
	addq	%rax,%r10
	movq	48(%rbp),%rax
	adcq	$0,%rdx
	addq	%r10,%r9
	movq	%rdx,%r10
	adcq	$0,%r10

	mulq	%rbx
	addq	%rax,%r11
	movq	64(%rbp),%rax
	adcq	$0,%rdx
	addq	%r11,%r10
	movq	%rdx,%r11
	adcq	$0,%r11

	mulq	%rbx
	addq	%rax,%r12
	movq	80(%rbp),%rax
	adcq	$0,%rdx
	addq	%r12,%r11
	movq	%rdx,%r12
	adcq	$0,%r12

	mulq	%rbx
	addq	%rax,%r13
	movq	96(%rbp),%rax
	adcq	$0,%rdx
	addq	%r13,%r12
	movq	%rdx,%r13
	adcq	$0,%r13

	mulq	%rbx
	addq	%rax,%r14
	movq	112(%rbp),%rax
	adcq	$0,%rdx
	addq	%r14,%r13
	movq	%rdx,%r14
	adcq	$0,%r14

	mulq	%rbx
	movq	48-16+8(%rsp,%rcx,8),%rbx
	addq	%rax,%r15
	adcq	$0,%rdx
	addq	%r15,%r14
	movq	0(%rbp),%rax
	movq	%rdx,%r15
	adcq	$0,%r15

	decl	%ecx
	jnz	.L8x_tail

	leaq	128(%rbp),%rbp
	movq	8+8(%rsp),%rdx
	cmpq	0+8(%rsp),%rbp
	jae	.L8x_tail_done

	movq	48+56+8(%rsp),%rbx
	negq	%rsi
	movq	0(%rbp),%rax
	adcq	0(%rdi),%r8
	adcq	8(%rdi),%r9
	adcq	16(%rdi),%r10
	adcq	24(%rdi),%r11
	adcq	32(%rdi),%r12
	adcq	40(%rdi),%r13
	adcq	48(%rdi),%r14
	adcq	56(%rdi),%r15
	sbbq	%rsi,%rsi

	movl	$8,%ecx
	jmp	.L8x_tail

.align	32
.L8x_tail_done:
	addq	(%rdx),%r8
	xorq	%rax,%rax

	negq	%rsi
.L8x_no_tail:
	adcq	0(%rdi),%r8
	adcq	8(%rdi),%r9
	adcq	16(%rdi),%r10
	adcq	24(%rdi),%r11
	adcq	32(%rdi),%r12
	adcq	40(%rdi),%r13
	adcq	48(%rdi),%r14
	adcq	56(%rdi),%r15
	adcq	$0,%rax
	movq	-16(%rbp),%rcx
	xorq	%rsi,%rsi

.byte	102,72,15,126,213

	movq	%r8,0(%rdi)
	movq	%r9,8(%rdi)
.byte	102,73,15,126,217
	movq	%r10,16(%rdi)
	movq	%r11,24(%rdi)
	movq	%r12,32(%rdi)
	movq	%r13,40(%rdi)
	movq	%r14,48(%rdi)
	movq	%r15,56(%rdi)
	leaq	64(%rdi),%rdi

	cmpq	%rdx,%rdi
	jb	.L8x_reduction_loop

	subq	%r15,%rcx
	leaq	(%rdi,%r9,1),%rbx
	adcq	%rsi,%rsi
	movq	%r9,%rcx
	orq	%rsi,%rax
.byte	102,72,15,126,207
	xorq	$1,%rax
.byte	102,72,15,126,206
	leaq	(%rbp,%rax,8),%rbp
	sarq	$3+2,%rcx
	jmp	.Lsqr4x_sub

.align	32
.Lsqr4x_sub:
.byte	0x66
	movq	0(%rbx),%r12
	movq	8(%rbx),%r13
	sbbq	0(%rbp),%r12
	movq	16(%rbx),%r14
	sbbq	16(%rbp),%r13
	movq	24(%rbx),%r15
	leaq	32(%rbx),%rbx
	sbbq	32(%rbp),%r14
	movq	%r12,0(%rdi)
	sbbq	48(%rbp),%r15
	leaq	64(%rbp),%rbp
	movq	%r13,8(%rdi)
	movq	%r14,16(%rdi)
	movq	%r15,24(%rdi)
	leaq	32(%rdi),%rdi

	incq	%rcx
	jnz	.Lsqr4x_sub
	movq	%r9,%r10
	negq	%r9
	.byte	0xf3,0xc3
.size	bn_sqr8x_internal,.-bn_sqr8x_internal
.globl	bn_from_montgomery
.hidden bn_from_montgomery
.type	bn_from_montgomery,@function
.align	32
bn_from_montgomery:
	testl	$7,%r9d
	jz	bn_from_mont8x
	xorl	%eax,%eax
	.byte	0xf3,0xc3
.size	bn_from_montgomery,.-bn_from_montgomery

.type	bn_from_mont8x,@function
.align	32
bn_from_mont8x:
.byte	0x67
	movq	%rsp,%rax
	pushq	%rbx
	pushq	%rbp
	pushq	%r12
	pushq	%r13
	pushq	%r14
	pushq	%r15
.byte	0x67
	movl	%r9d,%r10d
	shll	$3,%r9d
	shll	$3+2,%r10d
	negq	%r9
	movq	(%r8),%r8







	leaq	-64(%rsp,%r9,2),%r11
	subq	%rsi,%r11
	andq	$4095,%r11
	cmpq	%r11,%r10
	jb	.Lfrom_sp_alt
	subq	%r11,%rsp
	leaq	-64(%rsp,%r9,2),%rsp
	jmp	.Lfrom_sp_done

.align	32
.Lfrom_sp_alt:
	leaq	4096-64(,%r9,2),%r10
	leaq	-64(%rsp,%r9,2),%rsp
	subq	%r10,%r11
	movq	$0,%r10
	cmovcq	%r10,%r11
	subq	%r11,%rsp
.Lfrom_sp_done:
	andq	$-64,%rsp
	movq	%r9,%r10
	negq	%r9










	movq	%r8,32(%rsp)
	movq	%rax,40(%rsp)
.Lfrom_body:
	movq	%r9,%r11
	leaq	48(%rsp),%rax
	pxor	%xmm0,%xmm0
	jmp	.Lmul_by_1

.align	32
.Lmul_by_1:
	movdqu	(%rsi),%xmm1
	movdqu	16(%rsi),%xmm2
	movdqu	32(%rsi),%xmm3
	movdqa	%xmm0,(%rax,%r9,1)
	movdqu	48(%rsi),%xmm4
	movdqa	%xmm0,16(%rax,%r9,1)
.byte	0x48,0x8d,0xb6,0x40,0x00,0x00,0x00
	movdqa	%xmm1,(%rax)
	movdqa	%xmm0,32(%rax,%r9,1)
	movdqa	%xmm2,16(%rax)
	movdqa	%xmm0,48(%rax,%r9,1)
	movdqa	%xmm3,32(%rax)
	movdqa	%xmm4,48(%rax)
	leaq	64(%rax),%rax
	subq	$64,%r11
	jnz	.Lmul_by_1

.byte	102,72,15,110,207
.byte	102,72,15,110,209
.byte	0x67
	movq	%rcx,%rbp
.byte	102,73,15,110,218
	call	sqr8x_reduction

	pxor	%xmm0,%xmm0
	leaq	48(%rsp),%rax
	movq	40(%rsp),%rsi
	jmp	.Lfrom_mont_zero

.align	32
.Lfrom_mont_zero:
	movdqa	%xmm0,0(%rax)
	movdqa	%xmm0,16(%rax)
	movdqa	%xmm0,32(%rax)
	movdqa	%xmm0,48(%rax)
	leaq	64(%rax),%rax
	subq	$32,%r9
	jnz	.Lfrom_mont_zero

	movq	$1,%rax
	movq	-48(%rsi),%r15
	movq	-40(%rsi),%r14
	movq	-32(%rsi),%r13
	movq	-24(%rsi),%r12
	movq	-16(%rsi),%rbp
	movq	-8(%rsi),%rbx
	leaq	(%rsi),%rsp
.Lfrom_epilogue:
	.byte	0xf3,0xc3
.size	bn_from_mont8x,.-bn_from_mont8x
.globl	bn_scatter5
.hidden bn_scatter5
.type	bn_scatter5,@function
.align	16
bn_scatter5:
	cmpl	$0,%esi
	jz	.Lscatter_epilogue
	leaq	(%rdx,%rcx,8),%rdx
.Lscatter:
	movq	(%rdi),%rax
	leaq	8(%rdi),%rdi
	movq	%rax,(%rdx)
	leaq	256(%rdx),%rdx
	subl	$1,%esi
	jnz	.Lscatter
.Lscatter_epilogue:
	.byte	0xf3,0xc3
.size	bn_scatter5,.-bn_scatter5

.globl	bn_gather5
.hidden bn_gather5
.type	bn_gather5,@function
.align	16
bn_gather5:
	movl	%ecx,%r11d
	shrl	$3,%ecx
	andq	$7,%r11
	notl	%ecx
	leaq	.Lmagic_masks(%rip),%rax
	andl	$3,%ecx
	leaq	128(%rdx,%r11,8),%rdx
	movq	0(%rax,%rcx,8),%xmm4
	movq	8(%rax,%rcx,8),%xmm5
	movq	16(%rax,%rcx,8),%xmm6
	movq	24(%rax,%rcx,8),%xmm7
	jmp	.Lgather
.align	16
.Lgather:
	movq	-128(%rdx),%xmm0
	movq	-64(%rdx),%xmm1
	pand	%xmm4,%xmm0
	movq	0(%rdx),%xmm2
	pand	%xmm5,%xmm1
	movq	64(%rdx),%xmm3
	pand	%xmm6,%xmm2
	por	%xmm1,%xmm0
	pand	%xmm7,%xmm3
.byte	0x67,0x67
	por	%xmm2,%xmm0
	leaq	256(%rdx),%rdx
	por	%xmm3,%xmm0

	movq	%xmm0,(%rdi)
	leaq	8(%rdi),%rdi
	subl	$1,%esi
	jnz	.Lgather
	.byte	0xf3,0xc3
.LSEH_end_bn_gather5:
.size	bn_gather5,.-bn_gather5
.align	64
.Lmagic_masks:
.long	0,0, 0,0, 0,0, -1,-1
.long	0,0, 0,0, 0,0,  0,0
.byte	77,111,110,116,103,111,109,101,114,121,32,77,117,108,116,105,112,108,105,99,97,116,105,111,110,32,119,105,116,104,32,115,99,97,116,116,101,114,47,103,97,116,104,101,114,32,102,111,114,32,120,56,54,95,54,52,44,32,67,82,89,80,84,79,71,65,77,83,32,98,121,32,60,97,112,112,114,111,64,111,112,101,110,115,115,108,46,111,114,103,62,0
#endif
