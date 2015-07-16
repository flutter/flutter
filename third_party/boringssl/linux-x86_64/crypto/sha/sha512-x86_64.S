#if defined(__x86_64__)
.text	

.extern	OPENSSL_ia32cap_P
.hidden OPENSSL_ia32cap_P
.globl	sha512_block_data_order
.hidden sha512_block_data_order
.type	sha512_block_data_order,@function
.align	16
sha512_block_data_order:
	pushq	%rbx
	pushq	%rbp
	pushq	%r12
	pushq	%r13
	pushq	%r14
	pushq	%r15
	movq	%rsp,%r11
	shlq	$4,%rdx
	subq	$128+32,%rsp
	leaq	(%rsi,%rdx,8),%rdx
	andq	$-64,%rsp
	movq	%rdi,128+0(%rsp)
	movq	%rsi,128+8(%rsp)
	movq	%rdx,128+16(%rsp)
	movq	%r11,128+24(%rsp)
.Lprologue:

	movq	0(%rdi),%rax
	movq	8(%rdi),%rbx
	movq	16(%rdi),%rcx
	movq	24(%rdi),%rdx
	movq	32(%rdi),%r8
	movq	40(%rdi),%r9
	movq	48(%rdi),%r10
	movq	56(%rdi),%r11
	jmp	.Lloop

.align	16
.Lloop:
	movq	%rbx,%rdi
	leaq	K512(%rip),%rbp
	xorq	%rcx,%rdi
	movq	0(%rsi),%r12
	movq	%r8,%r13
	movq	%rax,%r14
	bswapq	%r12
	rorq	$23,%r13
	movq	%r9,%r15

	xorq	%r8,%r13
	rorq	$5,%r14
	xorq	%r10,%r15

	movq	%r12,0(%rsp)
	xorq	%rax,%r14
	andq	%r8,%r15

	rorq	$4,%r13
	addq	%r11,%r12
	xorq	%r10,%r15

	rorq	$6,%r14
	xorq	%r8,%r13
	addq	%r15,%r12

	movq	%rax,%r15
	addq	(%rbp),%r12
	xorq	%rax,%r14

	xorq	%rbx,%r15
	rorq	$14,%r13
	movq	%rbx,%r11

	andq	%r15,%rdi
	rorq	$28,%r14
	addq	%r13,%r12

	xorq	%rdi,%r11
	addq	%r12,%rdx
	addq	%r12,%r11

	leaq	8(%rbp),%rbp
	addq	%r14,%r11
	movq	8(%rsi),%r12
	movq	%rdx,%r13
	movq	%r11,%r14
	bswapq	%r12
	rorq	$23,%r13
	movq	%r8,%rdi

	xorq	%rdx,%r13
	rorq	$5,%r14
	xorq	%r9,%rdi

	movq	%r12,8(%rsp)
	xorq	%r11,%r14
	andq	%rdx,%rdi

	rorq	$4,%r13
	addq	%r10,%r12
	xorq	%r9,%rdi

	rorq	$6,%r14
	xorq	%rdx,%r13
	addq	%rdi,%r12

	movq	%r11,%rdi
	addq	(%rbp),%r12
	xorq	%r11,%r14

	xorq	%rax,%rdi
	rorq	$14,%r13
	movq	%rax,%r10

	andq	%rdi,%r15
	rorq	$28,%r14
	addq	%r13,%r12

	xorq	%r15,%r10
	addq	%r12,%rcx
	addq	%r12,%r10

	leaq	24(%rbp),%rbp
	addq	%r14,%r10
	movq	16(%rsi),%r12
	movq	%rcx,%r13
	movq	%r10,%r14
	bswapq	%r12
	rorq	$23,%r13
	movq	%rdx,%r15

	xorq	%rcx,%r13
	rorq	$5,%r14
	xorq	%r8,%r15

	movq	%r12,16(%rsp)
	xorq	%r10,%r14
	andq	%rcx,%r15

	rorq	$4,%r13
	addq	%r9,%r12
	xorq	%r8,%r15

	rorq	$6,%r14
	xorq	%rcx,%r13
	addq	%r15,%r12

	movq	%r10,%r15
	addq	(%rbp),%r12
	xorq	%r10,%r14

	xorq	%r11,%r15
	rorq	$14,%r13
	movq	%r11,%r9

	andq	%r15,%rdi
	rorq	$28,%r14
	addq	%r13,%r12

	xorq	%rdi,%r9
	addq	%r12,%rbx
	addq	%r12,%r9

	leaq	8(%rbp),%rbp
	addq	%r14,%r9
	movq	24(%rsi),%r12
	movq	%rbx,%r13
	movq	%r9,%r14
	bswapq	%r12
	rorq	$23,%r13
	movq	%rcx,%rdi

	xorq	%rbx,%r13
	rorq	$5,%r14
	xorq	%rdx,%rdi

	movq	%r12,24(%rsp)
	xorq	%r9,%r14
	andq	%rbx,%rdi

	rorq	$4,%r13
	addq	%r8,%r12
	xorq	%rdx,%rdi

	rorq	$6,%r14
	xorq	%rbx,%r13
	addq	%rdi,%r12

	movq	%r9,%rdi
	addq	(%rbp),%r12
	xorq	%r9,%r14

	xorq	%r10,%rdi
	rorq	$14,%r13
	movq	%r10,%r8

	andq	%rdi,%r15
	rorq	$28,%r14
	addq	%r13,%r12

	xorq	%r15,%r8
	addq	%r12,%rax
	addq	%r12,%r8

	leaq	24(%rbp),%rbp
	addq	%r14,%r8
	movq	32(%rsi),%r12
	movq	%rax,%r13
	movq	%r8,%r14
	bswapq	%r12
	rorq	$23,%r13
	movq	%rbx,%r15

	xorq	%rax,%r13
	rorq	$5,%r14
	xorq	%rcx,%r15

	movq	%r12,32(%rsp)
	xorq	%r8,%r14
	andq	%rax,%r15

	rorq	$4,%r13
	addq	%rdx,%r12
	xorq	%rcx,%r15

	rorq	$6,%r14
	xorq	%rax,%r13
	addq	%r15,%r12

	movq	%r8,%r15
	addq	(%rbp),%r12
	xorq	%r8,%r14

	xorq	%r9,%r15
	rorq	$14,%r13
	movq	%r9,%rdx

	andq	%r15,%rdi
	rorq	$28,%r14
	addq	%r13,%r12

	xorq	%rdi,%rdx
	addq	%r12,%r11
	addq	%r12,%rdx

	leaq	8(%rbp),%rbp
	addq	%r14,%rdx
	movq	40(%rsi),%r12
	movq	%r11,%r13
	movq	%rdx,%r14
	bswapq	%r12
	rorq	$23,%r13
	movq	%rax,%rdi

	xorq	%r11,%r13
	rorq	$5,%r14
	xorq	%rbx,%rdi

	movq	%r12,40(%rsp)
	xorq	%rdx,%r14
	andq	%r11,%rdi

	rorq	$4,%r13
	addq	%rcx,%r12
	xorq	%rbx,%rdi

	rorq	$6,%r14
	xorq	%r11,%r13
	addq	%rdi,%r12

	movq	%rdx,%rdi
	addq	(%rbp),%r12
	xorq	%rdx,%r14

	xorq	%r8,%rdi
	rorq	$14,%r13
	movq	%r8,%rcx

	andq	%rdi,%r15
	rorq	$28,%r14
	addq	%r13,%r12

	xorq	%r15,%rcx
	addq	%r12,%r10
	addq	%r12,%rcx

	leaq	24(%rbp),%rbp
	addq	%r14,%rcx
	movq	48(%rsi),%r12
	movq	%r10,%r13
	movq	%rcx,%r14
	bswapq	%r12
	rorq	$23,%r13
	movq	%r11,%r15

	xorq	%r10,%r13
	rorq	$5,%r14
	xorq	%rax,%r15

	movq	%r12,48(%rsp)
	xorq	%rcx,%r14
	andq	%r10,%r15

	rorq	$4,%r13
	addq	%rbx,%r12
	xorq	%rax,%r15

	rorq	$6,%r14
	xorq	%r10,%r13
	addq	%r15,%r12

	movq	%rcx,%r15
	addq	(%rbp),%r12
	xorq	%rcx,%r14

	xorq	%rdx,%r15
	rorq	$14,%r13
	movq	%rdx,%rbx

	andq	%r15,%rdi
	rorq	$28,%r14
	addq	%r13,%r12

	xorq	%rdi,%rbx
	addq	%r12,%r9
	addq	%r12,%rbx

	leaq	8(%rbp),%rbp
	addq	%r14,%rbx
	movq	56(%rsi),%r12
	movq	%r9,%r13
	movq	%rbx,%r14
	bswapq	%r12
	rorq	$23,%r13
	movq	%r10,%rdi

	xorq	%r9,%r13
	rorq	$5,%r14
	xorq	%r11,%rdi

	movq	%r12,56(%rsp)
	xorq	%rbx,%r14
	andq	%r9,%rdi

	rorq	$4,%r13
	addq	%rax,%r12
	xorq	%r11,%rdi

	rorq	$6,%r14
	xorq	%r9,%r13
	addq	%rdi,%r12

	movq	%rbx,%rdi
	addq	(%rbp),%r12
	xorq	%rbx,%r14

	xorq	%rcx,%rdi
	rorq	$14,%r13
	movq	%rcx,%rax

	andq	%rdi,%r15
	rorq	$28,%r14
	addq	%r13,%r12

	xorq	%r15,%rax
	addq	%r12,%r8
	addq	%r12,%rax

	leaq	24(%rbp),%rbp
	addq	%r14,%rax
	movq	64(%rsi),%r12
	movq	%r8,%r13
	movq	%rax,%r14
	bswapq	%r12
	rorq	$23,%r13
	movq	%r9,%r15

	xorq	%r8,%r13
	rorq	$5,%r14
	xorq	%r10,%r15

	movq	%r12,64(%rsp)
	xorq	%rax,%r14
	andq	%r8,%r15

	rorq	$4,%r13
	addq	%r11,%r12
	xorq	%r10,%r15

	rorq	$6,%r14
	xorq	%r8,%r13
	addq	%r15,%r12

	movq	%rax,%r15
	addq	(%rbp),%r12
	xorq	%rax,%r14

	xorq	%rbx,%r15
	rorq	$14,%r13
	movq	%rbx,%r11

	andq	%r15,%rdi
	rorq	$28,%r14
	addq	%r13,%r12

	xorq	%rdi,%r11
	addq	%r12,%rdx
	addq	%r12,%r11

	leaq	8(%rbp),%rbp
	addq	%r14,%r11
	movq	72(%rsi),%r12
	movq	%rdx,%r13
	movq	%r11,%r14
	bswapq	%r12
	rorq	$23,%r13
	movq	%r8,%rdi

	xorq	%rdx,%r13
	rorq	$5,%r14
	xorq	%r9,%rdi

	movq	%r12,72(%rsp)
	xorq	%r11,%r14
	andq	%rdx,%rdi

	rorq	$4,%r13
	addq	%r10,%r12
	xorq	%r9,%rdi

	rorq	$6,%r14
	xorq	%rdx,%r13
	addq	%rdi,%r12

	movq	%r11,%rdi
	addq	(%rbp),%r12
	xorq	%r11,%r14

	xorq	%rax,%rdi
	rorq	$14,%r13
	movq	%rax,%r10

	andq	%rdi,%r15
	rorq	$28,%r14
	addq	%r13,%r12

	xorq	%r15,%r10
	addq	%r12,%rcx
	addq	%r12,%r10

	leaq	24(%rbp),%rbp
	addq	%r14,%r10
	movq	80(%rsi),%r12
	movq	%rcx,%r13
	movq	%r10,%r14
	bswapq	%r12
	rorq	$23,%r13
	movq	%rdx,%r15

	xorq	%rcx,%r13
	rorq	$5,%r14
	xorq	%r8,%r15

	movq	%r12,80(%rsp)
	xorq	%r10,%r14
	andq	%rcx,%r15

	rorq	$4,%r13
	addq	%r9,%r12
	xorq	%r8,%r15

	rorq	$6,%r14
	xorq	%rcx,%r13
	addq	%r15,%r12

	movq	%r10,%r15
	addq	(%rbp),%r12
	xorq	%r10,%r14

	xorq	%r11,%r15
	rorq	$14,%r13
	movq	%r11,%r9

	andq	%r15,%rdi
	rorq	$28,%r14
	addq	%r13,%r12

	xorq	%rdi,%r9
	addq	%r12,%rbx
	addq	%r12,%r9

	leaq	8(%rbp),%rbp
	addq	%r14,%r9
	movq	88(%rsi),%r12
	movq	%rbx,%r13
	movq	%r9,%r14
	bswapq	%r12
	rorq	$23,%r13
	movq	%rcx,%rdi

	xorq	%rbx,%r13
	rorq	$5,%r14
	xorq	%rdx,%rdi

	movq	%r12,88(%rsp)
	xorq	%r9,%r14
	andq	%rbx,%rdi

	rorq	$4,%r13
	addq	%r8,%r12
	xorq	%rdx,%rdi

	rorq	$6,%r14
	xorq	%rbx,%r13
	addq	%rdi,%r12

	movq	%r9,%rdi
	addq	(%rbp),%r12
	xorq	%r9,%r14

	xorq	%r10,%rdi
	rorq	$14,%r13
	movq	%r10,%r8

	andq	%rdi,%r15
	rorq	$28,%r14
	addq	%r13,%r12

	xorq	%r15,%r8
	addq	%r12,%rax
	addq	%r12,%r8

	leaq	24(%rbp),%rbp
	addq	%r14,%r8
	movq	96(%rsi),%r12
	movq	%rax,%r13
	movq	%r8,%r14
	bswapq	%r12
	rorq	$23,%r13
	movq	%rbx,%r15

	xorq	%rax,%r13
	rorq	$5,%r14
	xorq	%rcx,%r15

	movq	%r12,96(%rsp)
	xorq	%r8,%r14
	andq	%rax,%r15

	rorq	$4,%r13
	addq	%rdx,%r12
	xorq	%rcx,%r15

	rorq	$6,%r14
	xorq	%rax,%r13
	addq	%r15,%r12

	movq	%r8,%r15
	addq	(%rbp),%r12
	xorq	%r8,%r14

	xorq	%r9,%r15
	rorq	$14,%r13
	movq	%r9,%rdx

	andq	%r15,%rdi
	rorq	$28,%r14
	addq	%r13,%r12

	xorq	%rdi,%rdx
	addq	%r12,%r11
	addq	%r12,%rdx

	leaq	8(%rbp),%rbp
	addq	%r14,%rdx
	movq	104(%rsi),%r12
	movq	%r11,%r13
	movq	%rdx,%r14
	bswapq	%r12
	rorq	$23,%r13
	movq	%rax,%rdi

	xorq	%r11,%r13
	rorq	$5,%r14
	xorq	%rbx,%rdi

	movq	%r12,104(%rsp)
	xorq	%rdx,%r14
	andq	%r11,%rdi

	rorq	$4,%r13
	addq	%rcx,%r12
	xorq	%rbx,%rdi

	rorq	$6,%r14
	xorq	%r11,%r13
	addq	%rdi,%r12

	movq	%rdx,%rdi
	addq	(%rbp),%r12
	xorq	%rdx,%r14

	xorq	%r8,%rdi
	rorq	$14,%r13
	movq	%r8,%rcx

	andq	%rdi,%r15
	rorq	$28,%r14
	addq	%r13,%r12

	xorq	%r15,%rcx
	addq	%r12,%r10
	addq	%r12,%rcx

	leaq	24(%rbp),%rbp
	addq	%r14,%rcx
	movq	112(%rsi),%r12
	movq	%r10,%r13
	movq	%rcx,%r14
	bswapq	%r12
	rorq	$23,%r13
	movq	%r11,%r15

	xorq	%r10,%r13
	rorq	$5,%r14
	xorq	%rax,%r15

	movq	%r12,112(%rsp)
	xorq	%rcx,%r14
	andq	%r10,%r15

	rorq	$4,%r13
	addq	%rbx,%r12
	xorq	%rax,%r15

	rorq	$6,%r14
	xorq	%r10,%r13
	addq	%r15,%r12

	movq	%rcx,%r15
	addq	(%rbp),%r12
	xorq	%rcx,%r14

	xorq	%rdx,%r15
	rorq	$14,%r13
	movq	%rdx,%rbx

	andq	%r15,%rdi
	rorq	$28,%r14
	addq	%r13,%r12

	xorq	%rdi,%rbx
	addq	%r12,%r9
	addq	%r12,%rbx

	leaq	8(%rbp),%rbp
	addq	%r14,%rbx
	movq	120(%rsi),%r12
	movq	%r9,%r13
	movq	%rbx,%r14
	bswapq	%r12
	rorq	$23,%r13
	movq	%r10,%rdi

	xorq	%r9,%r13
	rorq	$5,%r14
	xorq	%r11,%rdi

	movq	%r12,120(%rsp)
	xorq	%rbx,%r14
	andq	%r9,%rdi

	rorq	$4,%r13
	addq	%rax,%r12
	xorq	%r11,%rdi

	rorq	$6,%r14
	xorq	%r9,%r13
	addq	%rdi,%r12

	movq	%rbx,%rdi
	addq	(%rbp),%r12
	xorq	%rbx,%r14

	xorq	%rcx,%rdi
	rorq	$14,%r13
	movq	%rcx,%rax

	andq	%rdi,%r15
	rorq	$28,%r14
	addq	%r13,%r12

	xorq	%r15,%rax
	addq	%r12,%r8
	addq	%r12,%rax

	leaq	24(%rbp),%rbp
	jmp	.Lrounds_16_xx
.align	16
.Lrounds_16_xx:
	movq	8(%rsp),%r13
	movq	112(%rsp),%r15

	movq	%r13,%r12
	rorq	$7,%r13
	addq	%r14,%rax
	movq	%r15,%r14
	rorq	$42,%r15

	xorq	%r12,%r13
	shrq	$7,%r12
	rorq	$1,%r13
	xorq	%r14,%r15
	shrq	$6,%r14

	rorq	$19,%r15
	xorq	%r13,%r12
	xorq	%r14,%r15
	addq	72(%rsp),%r12

	addq	0(%rsp),%r12
	movq	%r8,%r13
	addq	%r15,%r12
	movq	%rax,%r14
	rorq	$23,%r13
	movq	%r9,%r15

	xorq	%r8,%r13
	rorq	$5,%r14
	xorq	%r10,%r15

	movq	%r12,0(%rsp)
	xorq	%rax,%r14
	andq	%r8,%r15

	rorq	$4,%r13
	addq	%r11,%r12
	xorq	%r10,%r15

	rorq	$6,%r14
	xorq	%r8,%r13
	addq	%r15,%r12

	movq	%rax,%r15
	addq	(%rbp),%r12
	xorq	%rax,%r14

	xorq	%rbx,%r15
	rorq	$14,%r13
	movq	%rbx,%r11

	andq	%r15,%rdi
	rorq	$28,%r14
	addq	%r13,%r12

	xorq	%rdi,%r11
	addq	%r12,%rdx
	addq	%r12,%r11

	leaq	8(%rbp),%rbp
	movq	16(%rsp),%r13
	movq	120(%rsp),%rdi

	movq	%r13,%r12
	rorq	$7,%r13
	addq	%r14,%r11
	movq	%rdi,%r14
	rorq	$42,%rdi

	xorq	%r12,%r13
	shrq	$7,%r12
	rorq	$1,%r13
	xorq	%r14,%rdi
	shrq	$6,%r14

	rorq	$19,%rdi
	xorq	%r13,%r12
	xorq	%r14,%rdi
	addq	80(%rsp),%r12

	addq	8(%rsp),%r12
	movq	%rdx,%r13
	addq	%rdi,%r12
	movq	%r11,%r14
	rorq	$23,%r13
	movq	%r8,%rdi

	xorq	%rdx,%r13
	rorq	$5,%r14
	xorq	%r9,%rdi

	movq	%r12,8(%rsp)
	xorq	%r11,%r14
	andq	%rdx,%rdi

	rorq	$4,%r13
	addq	%r10,%r12
	xorq	%r9,%rdi

	rorq	$6,%r14
	xorq	%rdx,%r13
	addq	%rdi,%r12

	movq	%r11,%rdi
	addq	(%rbp),%r12
	xorq	%r11,%r14

	xorq	%rax,%rdi
	rorq	$14,%r13
	movq	%rax,%r10

	andq	%rdi,%r15
	rorq	$28,%r14
	addq	%r13,%r12

	xorq	%r15,%r10
	addq	%r12,%rcx
	addq	%r12,%r10

	leaq	24(%rbp),%rbp
	movq	24(%rsp),%r13
	movq	0(%rsp),%r15

	movq	%r13,%r12
	rorq	$7,%r13
	addq	%r14,%r10
	movq	%r15,%r14
	rorq	$42,%r15

	xorq	%r12,%r13
	shrq	$7,%r12
	rorq	$1,%r13
	xorq	%r14,%r15
	shrq	$6,%r14

	rorq	$19,%r15
	xorq	%r13,%r12
	xorq	%r14,%r15
	addq	88(%rsp),%r12

	addq	16(%rsp),%r12
	movq	%rcx,%r13
	addq	%r15,%r12
	movq	%r10,%r14
	rorq	$23,%r13
	movq	%rdx,%r15

	xorq	%rcx,%r13
	rorq	$5,%r14
	xorq	%r8,%r15

	movq	%r12,16(%rsp)
	xorq	%r10,%r14
	andq	%rcx,%r15

	rorq	$4,%r13
	addq	%r9,%r12
	xorq	%r8,%r15

	rorq	$6,%r14
	xorq	%rcx,%r13
	addq	%r15,%r12

	movq	%r10,%r15
	addq	(%rbp),%r12
	xorq	%r10,%r14

	xorq	%r11,%r15
	rorq	$14,%r13
	movq	%r11,%r9

	andq	%r15,%rdi
	rorq	$28,%r14
	addq	%r13,%r12

	xorq	%rdi,%r9
	addq	%r12,%rbx
	addq	%r12,%r9

	leaq	8(%rbp),%rbp
	movq	32(%rsp),%r13
	movq	8(%rsp),%rdi

	movq	%r13,%r12
	rorq	$7,%r13
	addq	%r14,%r9
	movq	%rdi,%r14
	rorq	$42,%rdi

	xorq	%r12,%r13
	shrq	$7,%r12
	rorq	$1,%r13
	xorq	%r14,%rdi
	shrq	$6,%r14

	rorq	$19,%rdi
	xorq	%r13,%r12
	xorq	%r14,%rdi
	addq	96(%rsp),%r12

	addq	24(%rsp),%r12
	movq	%rbx,%r13
	addq	%rdi,%r12
	movq	%r9,%r14
	rorq	$23,%r13
	movq	%rcx,%rdi

	xorq	%rbx,%r13
	rorq	$5,%r14
	xorq	%rdx,%rdi

	movq	%r12,24(%rsp)
	xorq	%r9,%r14
	andq	%rbx,%rdi

	rorq	$4,%r13
	addq	%r8,%r12
	xorq	%rdx,%rdi

	rorq	$6,%r14
	xorq	%rbx,%r13
	addq	%rdi,%r12

	movq	%r9,%rdi
	addq	(%rbp),%r12
	xorq	%r9,%r14

	xorq	%r10,%rdi
	rorq	$14,%r13
	movq	%r10,%r8

	andq	%rdi,%r15
	rorq	$28,%r14
	addq	%r13,%r12

	xorq	%r15,%r8
	addq	%r12,%rax
	addq	%r12,%r8

	leaq	24(%rbp),%rbp
	movq	40(%rsp),%r13
	movq	16(%rsp),%r15

	movq	%r13,%r12
	rorq	$7,%r13
	addq	%r14,%r8
	movq	%r15,%r14
	rorq	$42,%r15

	xorq	%r12,%r13
	shrq	$7,%r12
	rorq	$1,%r13
	xorq	%r14,%r15
	shrq	$6,%r14

	rorq	$19,%r15
	xorq	%r13,%r12
	xorq	%r14,%r15
	addq	104(%rsp),%r12

	addq	32(%rsp),%r12
	movq	%rax,%r13
	addq	%r15,%r12
	movq	%r8,%r14
	rorq	$23,%r13
	movq	%rbx,%r15

	xorq	%rax,%r13
	rorq	$5,%r14
	xorq	%rcx,%r15

	movq	%r12,32(%rsp)
	xorq	%r8,%r14
	andq	%rax,%r15

	rorq	$4,%r13
	addq	%rdx,%r12
	xorq	%rcx,%r15

	rorq	$6,%r14
	xorq	%rax,%r13
	addq	%r15,%r12

	movq	%r8,%r15
	addq	(%rbp),%r12
	xorq	%r8,%r14

	xorq	%r9,%r15
	rorq	$14,%r13
	movq	%r9,%rdx

	andq	%r15,%rdi
	rorq	$28,%r14
	addq	%r13,%r12

	xorq	%rdi,%rdx
	addq	%r12,%r11
	addq	%r12,%rdx

	leaq	8(%rbp),%rbp
	movq	48(%rsp),%r13
	movq	24(%rsp),%rdi

	movq	%r13,%r12
	rorq	$7,%r13
	addq	%r14,%rdx
	movq	%rdi,%r14
	rorq	$42,%rdi

	xorq	%r12,%r13
	shrq	$7,%r12
	rorq	$1,%r13
	xorq	%r14,%rdi
	shrq	$6,%r14

	rorq	$19,%rdi
	xorq	%r13,%r12
	xorq	%r14,%rdi
	addq	112(%rsp),%r12

	addq	40(%rsp),%r12
	movq	%r11,%r13
	addq	%rdi,%r12
	movq	%rdx,%r14
	rorq	$23,%r13
	movq	%rax,%rdi

	xorq	%r11,%r13
	rorq	$5,%r14
	xorq	%rbx,%rdi

	movq	%r12,40(%rsp)
	xorq	%rdx,%r14
	andq	%r11,%rdi

	rorq	$4,%r13
	addq	%rcx,%r12
	xorq	%rbx,%rdi

	rorq	$6,%r14
	xorq	%r11,%r13
	addq	%rdi,%r12

	movq	%rdx,%rdi
	addq	(%rbp),%r12
	xorq	%rdx,%r14

	xorq	%r8,%rdi
	rorq	$14,%r13
	movq	%r8,%rcx

	andq	%rdi,%r15
	rorq	$28,%r14
	addq	%r13,%r12

	xorq	%r15,%rcx
	addq	%r12,%r10
	addq	%r12,%rcx

	leaq	24(%rbp),%rbp
	movq	56(%rsp),%r13
	movq	32(%rsp),%r15

	movq	%r13,%r12
	rorq	$7,%r13
	addq	%r14,%rcx
	movq	%r15,%r14
	rorq	$42,%r15

	xorq	%r12,%r13
	shrq	$7,%r12
	rorq	$1,%r13
	xorq	%r14,%r15
	shrq	$6,%r14

	rorq	$19,%r15
	xorq	%r13,%r12
	xorq	%r14,%r15
	addq	120(%rsp),%r12

	addq	48(%rsp),%r12
	movq	%r10,%r13
	addq	%r15,%r12
	movq	%rcx,%r14
	rorq	$23,%r13
	movq	%r11,%r15

	xorq	%r10,%r13
	rorq	$5,%r14
	xorq	%rax,%r15

	movq	%r12,48(%rsp)
	xorq	%rcx,%r14
	andq	%r10,%r15

	rorq	$4,%r13
	addq	%rbx,%r12
	xorq	%rax,%r15

	rorq	$6,%r14
	xorq	%r10,%r13
	addq	%r15,%r12

	movq	%rcx,%r15
	addq	(%rbp),%r12
	xorq	%rcx,%r14

	xorq	%rdx,%r15
	rorq	$14,%r13
	movq	%rdx,%rbx

	andq	%r15,%rdi
	rorq	$28,%r14
	addq	%r13,%r12

	xorq	%rdi,%rbx
	addq	%r12,%r9
	addq	%r12,%rbx

	leaq	8(%rbp),%rbp
	movq	64(%rsp),%r13
	movq	40(%rsp),%rdi

	movq	%r13,%r12
	rorq	$7,%r13
	addq	%r14,%rbx
	movq	%rdi,%r14
	rorq	$42,%rdi

	xorq	%r12,%r13
	shrq	$7,%r12
	rorq	$1,%r13
	xorq	%r14,%rdi
	shrq	$6,%r14

	rorq	$19,%rdi
	xorq	%r13,%r12
	xorq	%r14,%rdi
	addq	0(%rsp),%r12

	addq	56(%rsp),%r12
	movq	%r9,%r13
	addq	%rdi,%r12
	movq	%rbx,%r14
	rorq	$23,%r13
	movq	%r10,%rdi

	xorq	%r9,%r13
	rorq	$5,%r14
	xorq	%r11,%rdi

	movq	%r12,56(%rsp)
	xorq	%rbx,%r14
	andq	%r9,%rdi

	rorq	$4,%r13
	addq	%rax,%r12
	xorq	%r11,%rdi

	rorq	$6,%r14
	xorq	%r9,%r13
	addq	%rdi,%r12

	movq	%rbx,%rdi
	addq	(%rbp),%r12
	xorq	%rbx,%r14

	xorq	%rcx,%rdi
	rorq	$14,%r13
	movq	%rcx,%rax

	andq	%rdi,%r15
	rorq	$28,%r14
	addq	%r13,%r12

	xorq	%r15,%rax
	addq	%r12,%r8
	addq	%r12,%rax

	leaq	24(%rbp),%rbp
	movq	72(%rsp),%r13
	movq	48(%rsp),%r15

	movq	%r13,%r12
	rorq	$7,%r13
	addq	%r14,%rax
	movq	%r15,%r14
	rorq	$42,%r15

	xorq	%r12,%r13
	shrq	$7,%r12
	rorq	$1,%r13
	xorq	%r14,%r15
	shrq	$6,%r14

	rorq	$19,%r15
	xorq	%r13,%r12
	xorq	%r14,%r15
	addq	8(%rsp),%r12

	addq	64(%rsp),%r12
	movq	%r8,%r13
	addq	%r15,%r12
	movq	%rax,%r14
	rorq	$23,%r13
	movq	%r9,%r15

	xorq	%r8,%r13
	rorq	$5,%r14
	xorq	%r10,%r15

	movq	%r12,64(%rsp)
	xorq	%rax,%r14
	andq	%r8,%r15

	rorq	$4,%r13
	addq	%r11,%r12
	xorq	%r10,%r15

	rorq	$6,%r14
	xorq	%r8,%r13
	addq	%r15,%r12

	movq	%rax,%r15
	addq	(%rbp),%r12
	xorq	%rax,%r14

	xorq	%rbx,%r15
	rorq	$14,%r13
	movq	%rbx,%r11

	andq	%r15,%rdi
	rorq	$28,%r14
	addq	%r13,%r12

	xorq	%rdi,%r11
	addq	%r12,%rdx
	addq	%r12,%r11

	leaq	8(%rbp),%rbp
	movq	80(%rsp),%r13
	movq	56(%rsp),%rdi

	movq	%r13,%r12
	rorq	$7,%r13
	addq	%r14,%r11
	movq	%rdi,%r14
	rorq	$42,%rdi

	xorq	%r12,%r13
	shrq	$7,%r12
	rorq	$1,%r13
	xorq	%r14,%rdi
	shrq	$6,%r14

	rorq	$19,%rdi
	xorq	%r13,%r12
	xorq	%r14,%rdi
	addq	16(%rsp),%r12

	addq	72(%rsp),%r12
	movq	%rdx,%r13
	addq	%rdi,%r12
	movq	%r11,%r14
	rorq	$23,%r13
	movq	%r8,%rdi

	xorq	%rdx,%r13
	rorq	$5,%r14
	xorq	%r9,%rdi

	movq	%r12,72(%rsp)
	xorq	%r11,%r14
	andq	%rdx,%rdi

	rorq	$4,%r13
	addq	%r10,%r12
	xorq	%r9,%rdi

	rorq	$6,%r14
	xorq	%rdx,%r13
	addq	%rdi,%r12

	movq	%r11,%rdi
	addq	(%rbp),%r12
	xorq	%r11,%r14

	xorq	%rax,%rdi
	rorq	$14,%r13
	movq	%rax,%r10

	andq	%rdi,%r15
	rorq	$28,%r14
	addq	%r13,%r12

	xorq	%r15,%r10
	addq	%r12,%rcx
	addq	%r12,%r10

	leaq	24(%rbp),%rbp
	movq	88(%rsp),%r13
	movq	64(%rsp),%r15

	movq	%r13,%r12
	rorq	$7,%r13
	addq	%r14,%r10
	movq	%r15,%r14
	rorq	$42,%r15

	xorq	%r12,%r13
	shrq	$7,%r12
	rorq	$1,%r13
	xorq	%r14,%r15
	shrq	$6,%r14

	rorq	$19,%r15
	xorq	%r13,%r12
	xorq	%r14,%r15
	addq	24(%rsp),%r12

	addq	80(%rsp),%r12
	movq	%rcx,%r13
	addq	%r15,%r12
	movq	%r10,%r14
	rorq	$23,%r13
	movq	%rdx,%r15

	xorq	%rcx,%r13
	rorq	$5,%r14
	xorq	%r8,%r15

	movq	%r12,80(%rsp)
	xorq	%r10,%r14
	andq	%rcx,%r15

	rorq	$4,%r13
	addq	%r9,%r12
	xorq	%r8,%r15

	rorq	$6,%r14
	xorq	%rcx,%r13
	addq	%r15,%r12

	movq	%r10,%r15
	addq	(%rbp),%r12
	xorq	%r10,%r14

	xorq	%r11,%r15
	rorq	$14,%r13
	movq	%r11,%r9

	andq	%r15,%rdi
	rorq	$28,%r14
	addq	%r13,%r12

	xorq	%rdi,%r9
	addq	%r12,%rbx
	addq	%r12,%r9

	leaq	8(%rbp),%rbp
	movq	96(%rsp),%r13
	movq	72(%rsp),%rdi

	movq	%r13,%r12
	rorq	$7,%r13
	addq	%r14,%r9
	movq	%rdi,%r14
	rorq	$42,%rdi

	xorq	%r12,%r13
	shrq	$7,%r12
	rorq	$1,%r13
	xorq	%r14,%rdi
	shrq	$6,%r14

	rorq	$19,%rdi
	xorq	%r13,%r12
	xorq	%r14,%rdi
	addq	32(%rsp),%r12

	addq	88(%rsp),%r12
	movq	%rbx,%r13
	addq	%rdi,%r12
	movq	%r9,%r14
	rorq	$23,%r13
	movq	%rcx,%rdi

	xorq	%rbx,%r13
	rorq	$5,%r14
	xorq	%rdx,%rdi

	movq	%r12,88(%rsp)
	xorq	%r9,%r14
	andq	%rbx,%rdi

	rorq	$4,%r13
	addq	%r8,%r12
	xorq	%rdx,%rdi

	rorq	$6,%r14
	xorq	%rbx,%r13
	addq	%rdi,%r12

	movq	%r9,%rdi
	addq	(%rbp),%r12
	xorq	%r9,%r14

	xorq	%r10,%rdi
	rorq	$14,%r13
	movq	%r10,%r8

	andq	%rdi,%r15
	rorq	$28,%r14
	addq	%r13,%r12

	xorq	%r15,%r8
	addq	%r12,%rax
	addq	%r12,%r8

	leaq	24(%rbp),%rbp
	movq	104(%rsp),%r13
	movq	80(%rsp),%r15

	movq	%r13,%r12
	rorq	$7,%r13
	addq	%r14,%r8
	movq	%r15,%r14
	rorq	$42,%r15

	xorq	%r12,%r13
	shrq	$7,%r12
	rorq	$1,%r13
	xorq	%r14,%r15
	shrq	$6,%r14

	rorq	$19,%r15
	xorq	%r13,%r12
	xorq	%r14,%r15
	addq	40(%rsp),%r12

	addq	96(%rsp),%r12
	movq	%rax,%r13
	addq	%r15,%r12
	movq	%r8,%r14
	rorq	$23,%r13
	movq	%rbx,%r15

	xorq	%rax,%r13
	rorq	$5,%r14
	xorq	%rcx,%r15

	movq	%r12,96(%rsp)
	xorq	%r8,%r14
	andq	%rax,%r15

	rorq	$4,%r13
	addq	%rdx,%r12
	xorq	%rcx,%r15

	rorq	$6,%r14
	xorq	%rax,%r13
	addq	%r15,%r12

	movq	%r8,%r15
	addq	(%rbp),%r12
	xorq	%r8,%r14

	xorq	%r9,%r15
	rorq	$14,%r13
	movq	%r9,%rdx

	andq	%r15,%rdi
	rorq	$28,%r14
	addq	%r13,%r12

	xorq	%rdi,%rdx
	addq	%r12,%r11
	addq	%r12,%rdx

	leaq	8(%rbp),%rbp
	movq	112(%rsp),%r13
	movq	88(%rsp),%rdi

	movq	%r13,%r12
	rorq	$7,%r13
	addq	%r14,%rdx
	movq	%rdi,%r14
	rorq	$42,%rdi

	xorq	%r12,%r13
	shrq	$7,%r12
	rorq	$1,%r13
	xorq	%r14,%rdi
	shrq	$6,%r14

	rorq	$19,%rdi
	xorq	%r13,%r12
	xorq	%r14,%rdi
	addq	48(%rsp),%r12

	addq	104(%rsp),%r12
	movq	%r11,%r13
	addq	%rdi,%r12
	movq	%rdx,%r14
	rorq	$23,%r13
	movq	%rax,%rdi

	xorq	%r11,%r13
	rorq	$5,%r14
	xorq	%rbx,%rdi

	movq	%r12,104(%rsp)
	xorq	%rdx,%r14
	andq	%r11,%rdi

	rorq	$4,%r13
	addq	%rcx,%r12
	xorq	%rbx,%rdi

	rorq	$6,%r14
	xorq	%r11,%r13
	addq	%rdi,%r12

	movq	%rdx,%rdi
	addq	(%rbp),%r12
	xorq	%rdx,%r14

	xorq	%r8,%rdi
	rorq	$14,%r13
	movq	%r8,%rcx

	andq	%rdi,%r15
	rorq	$28,%r14
	addq	%r13,%r12

	xorq	%r15,%rcx
	addq	%r12,%r10
	addq	%r12,%rcx

	leaq	24(%rbp),%rbp
	movq	120(%rsp),%r13
	movq	96(%rsp),%r15

	movq	%r13,%r12
	rorq	$7,%r13
	addq	%r14,%rcx
	movq	%r15,%r14
	rorq	$42,%r15

	xorq	%r12,%r13
	shrq	$7,%r12
	rorq	$1,%r13
	xorq	%r14,%r15
	shrq	$6,%r14

	rorq	$19,%r15
	xorq	%r13,%r12
	xorq	%r14,%r15
	addq	56(%rsp),%r12

	addq	112(%rsp),%r12
	movq	%r10,%r13
	addq	%r15,%r12
	movq	%rcx,%r14
	rorq	$23,%r13
	movq	%r11,%r15

	xorq	%r10,%r13
	rorq	$5,%r14
	xorq	%rax,%r15

	movq	%r12,112(%rsp)
	xorq	%rcx,%r14
	andq	%r10,%r15

	rorq	$4,%r13
	addq	%rbx,%r12
	xorq	%rax,%r15

	rorq	$6,%r14
	xorq	%r10,%r13
	addq	%r15,%r12

	movq	%rcx,%r15
	addq	(%rbp),%r12
	xorq	%rcx,%r14

	xorq	%rdx,%r15
	rorq	$14,%r13
	movq	%rdx,%rbx

	andq	%r15,%rdi
	rorq	$28,%r14
	addq	%r13,%r12

	xorq	%rdi,%rbx
	addq	%r12,%r9
	addq	%r12,%rbx

	leaq	8(%rbp),%rbp
	movq	0(%rsp),%r13
	movq	104(%rsp),%rdi

	movq	%r13,%r12
	rorq	$7,%r13
	addq	%r14,%rbx
	movq	%rdi,%r14
	rorq	$42,%rdi

	xorq	%r12,%r13
	shrq	$7,%r12
	rorq	$1,%r13
	xorq	%r14,%rdi
	shrq	$6,%r14

	rorq	$19,%rdi
	xorq	%r13,%r12
	xorq	%r14,%rdi
	addq	64(%rsp),%r12

	addq	120(%rsp),%r12
	movq	%r9,%r13
	addq	%rdi,%r12
	movq	%rbx,%r14
	rorq	$23,%r13
	movq	%r10,%rdi

	xorq	%r9,%r13
	rorq	$5,%r14
	xorq	%r11,%rdi

	movq	%r12,120(%rsp)
	xorq	%rbx,%r14
	andq	%r9,%rdi

	rorq	$4,%r13
	addq	%rax,%r12
	xorq	%r11,%rdi

	rorq	$6,%r14
	xorq	%r9,%r13
	addq	%rdi,%r12

	movq	%rbx,%rdi
	addq	(%rbp),%r12
	xorq	%rbx,%r14

	xorq	%rcx,%rdi
	rorq	$14,%r13
	movq	%rcx,%rax

	andq	%rdi,%r15
	rorq	$28,%r14
	addq	%r13,%r12

	xorq	%r15,%rax
	addq	%r12,%r8
	addq	%r12,%rax

	leaq	24(%rbp),%rbp
	cmpb	$0,7(%rbp)
	jnz	.Lrounds_16_xx

	movq	128+0(%rsp),%rdi
	addq	%r14,%rax
	leaq	128(%rsi),%rsi

	addq	0(%rdi),%rax
	addq	8(%rdi),%rbx
	addq	16(%rdi),%rcx
	addq	24(%rdi),%rdx
	addq	32(%rdi),%r8
	addq	40(%rdi),%r9
	addq	48(%rdi),%r10
	addq	56(%rdi),%r11

	cmpq	128+16(%rsp),%rsi

	movq	%rax,0(%rdi)
	movq	%rbx,8(%rdi)
	movq	%rcx,16(%rdi)
	movq	%rdx,24(%rdi)
	movq	%r8,32(%rdi)
	movq	%r9,40(%rdi)
	movq	%r10,48(%rdi)
	movq	%r11,56(%rdi)
	jb	.Lloop

	movq	128+24(%rsp),%rsi
	movq	(%rsi),%r15
	movq	8(%rsi),%r14
	movq	16(%rsi),%r13
	movq	24(%rsi),%r12
	movq	32(%rsi),%rbp
	movq	40(%rsi),%rbx
	leaq	48(%rsi),%rsp
.Lepilogue:
	.byte	0xf3,0xc3
.size	sha512_block_data_order,.-sha512_block_data_order
.align	64
.type	K512,@object
K512:
.quad	0x428a2f98d728ae22,0x7137449123ef65cd
.quad	0x428a2f98d728ae22,0x7137449123ef65cd
.quad	0xb5c0fbcfec4d3b2f,0xe9b5dba58189dbbc
.quad	0xb5c0fbcfec4d3b2f,0xe9b5dba58189dbbc
.quad	0x3956c25bf348b538,0x59f111f1b605d019
.quad	0x3956c25bf348b538,0x59f111f1b605d019
.quad	0x923f82a4af194f9b,0xab1c5ed5da6d8118
.quad	0x923f82a4af194f9b,0xab1c5ed5da6d8118
.quad	0xd807aa98a3030242,0x12835b0145706fbe
.quad	0xd807aa98a3030242,0x12835b0145706fbe
.quad	0x243185be4ee4b28c,0x550c7dc3d5ffb4e2
.quad	0x243185be4ee4b28c,0x550c7dc3d5ffb4e2
.quad	0x72be5d74f27b896f,0x80deb1fe3b1696b1
.quad	0x72be5d74f27b896f,0x80deb1fe3b1696b1
.quad	0x9bdc06a725c71235,0xc19bf174cf692694
.quad	0x9bdc06a725c71235,0xc19bf174cf692694
.quad	0xe49b69c19ef14ad2,0xefbe4786384f25e3
.quad	0xe49b69c19ef14ad2,0xefbe4786384f25e3
.quad	0x0fc19dc68b8cd5b5,0x240ca1cc77ac9c65
.quad	0x0fc19dc68b8cd5b5,0x240ca1cc77ac9c65
.quad	0x2de92c6f592b0275,0x4a7484aa6ea6e483
.quad	0x2de92c6f592b0275,0x4a7484aa6ea6e483
.quad	0x5cb0a9dcbd41fbd4,0x76f988da831153b5
.quad	0x5cb0a9dcbd41fbd4,0x76f988da831153b5
.quad	0x983e5152ee66dfab,0xa831c66d2db43210
.quad	0x983e5152ee66dfab,0xa831c66d2db43210
.quad	0xb00327c898fb213f,0xbf597fc7beef0ee4
.quad	0xb00327c898fb213f,0xbf597fc7beef0ee4
.quad	0xc6e00bf33da88fc2,0xd5a79147930aa725
.quad	0xc6e00bf33da88fc2,0xd5a79147930aa725
.quad	0x06ca6351e003826f,0x142929670a0e6e70
.quad	0x06ca6351e003826f,0x142929670a0e6e70
.quad	0x27b70a8546d22ffc,0x2e1b21385c26c926
.quad	0x27b70a8546d22ffc,0x2e1b21385c26c926
.quad	0x4d2c6dfc5ac42aed,0x53380d139d95b3df
.quad	0x4d2c6dfc5ac42aed,0x53380d139d95b3df
.quad	0x650a73548baf63de,0x766a0abb3c77b2a8
.quad	0x650a73548baf63de,0x766a0abb3c77b2a8
.quad	0x81c2c92e47edaee6,0x92722c851482353b
.quad	0x81c2c92e47edaee6,0x92722c851482353b
.quad	0xa2bfe8a14cf10364,0xa81a664bbc423001
.quad	0xa2bfe8a14cf10364,0xa81a664bbc423001
.quad	0xc24b8b70d0f89791,0xc76c51a30654be30
.quad	0xc24b8b70d0f89791,0xc76c51a30654be30
.quad	0xd192e819d6ef5218,0xd69906245565a910
.quad	0xd192e819d6ef5218,0xd69906245565a910
.quad	0xf40e35855771202a,0x106aa07032bbd1b8
.quad	0xf40e35855771202a,0x106aa07032bbd1b8
.quad	0x19a4c116b8d2d0c8,0x1e376c085141ab53
.quad	0x19a4c116b8d2d0c8,0x1e376c085141ab53
.quad	0x2748774cdf8eeb99,0x34b0bcb5e19b48a8
.quad	0x2748774cdf8eeb99,0x34b0bcb5e19b48a8
.quad	0x391c0cb3c5c95a63,0x4ed8aa4ae3418acb
.quad	0x391c0cb3c5c95a63,0x4ed8aa4ae3418acb
.quad	0x5b9cca4f7763e373,0x682e6ff3d6b2b8a3
.quad	0x5b9cca4f7763e373,0x682e6ff3d6b2b8a3
.quad	0x748f82ee5defb2fc,0x78a5636f43172f60
.quad	0x748f82ee5defb2fc,0x78a5636f43172f60
.quad	0x84c87814a1f0ab72,0x8cc702081a6439ec
.quad	0x84c87814a1f0ab72,0x8cc702081a6439ec
.quad	0x90befffa23631e28,0xa4506cebde82bde9
.quad	0x90befffa23631e28,0xa4506cebde82bde9
.quad	0xbef9a3f7b2c67915,0xc67178f2e372532b
.quad	0xbef9a3f7b2c67915,0xc67178f2e372532b
.quad	0xca273eceea26619c,0xd186b8c721c0c207
.quad	0xca273eceea26619c,0xd186b8c721c0c207
.quad	0xeada7dd6cde0eb1e,0xf57d4f7fee6ed178
.quad	0xeada7dd6cde0eb1e,0xf57d4f7fee6ed178
.quad	0x06f067aa72176fba,0x0a637dc5a2c898a6
.quad	0x06f067aa72176fba,0x0a637dc5a2c898a6
.quad	0x113f9804bef90dae,0x1b710b35131c471b
.quad	0x113f9804bef90dae,0x1b710b35131c471b
.quad	0x28db77f523047d84,0x32caab7b40c72493
.quad	0x28db77f523047d84,0x32caab7b40c72493
.quad	0x3c9ebe0a15c9bebc,0x431d67c49c100d4c
.quad	0x3c9ebe0a15c9bebc,0x431d67c49c100d4c
.quad	0x4cc5d4becb3e42b6,0x597f299cfc657e2a
.quad	0x4cc5d4becb3e42b6,0x597f299cfc657e2a
.quad	0x5fcb6fab3ad6faec,0x6c44198c4a475817
.quad	0x5fcb6fab3ad6faec,0x6c44198c4a475817

.quad	0x0001020304050607,0x08090a0b0c0d0e0f
.quad	0x0001020304050607,0x08090a0b0c0d0e0f
.byte	83,72,65,53,49,50,32,98,108,111,99,107,32,116,114,97,110,115,102,111,114,109,32,102,111,114,32,120,56,54,95,54,52,44,32,67,82,89,80,84,79,71,65,77,83,32,98,121,32,60,97,112,112,114,111,64,111,112,101,110,115,115,108,46,111,114,103,62,0
#endif
