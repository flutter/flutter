#if defined(__x86_64__)
.text	

.globl	OPENSSL_ia32_cpuid
.hidden OPENSSL_ia32_cpuid
.type	OPENSSL_ia32_cpuid,@function
.align	16
OPENSSL_ia32_cpuid:


	movq	%rdi,%rdi
	movq	%rbx,%r8

	xorl	%eax,%eax
	movl	%eax,8(%rdi)
	cpuid
	movl	%eax,%r11d

	xorl	%eax,%eax
	cmpl	$1970169159,%ebx
	setne	%al
	movl	%eax,%r9d
	cmpl	$1231384169,%edx
	setne	%al
	orl	%eax,%r9d
	cmpl	$1818588270,%ecx
	setne	%al
	orl	%eax,%r9d
	jz	.Lintel

	cmpl	$1752462657,%ebx
	setne	%al
	movl	%eax,%r10d
	cmpl	$1769238117,%edx
	setne	%al
	orl	%eax,%r10d
	cmpl	$1145913699,%ecx
	setne	%al
	orl	%eax,%r10d
	jnz	.Lintel




	movl	$2147483648,%eax
	cpuid


	cmpl	$2147483649,%eax
	jb	.Lintel
	movl	%eax,%r10d
	movl	$2147483649,%eax
	cpuid


	orl	%ecx,%r9d
	andl	$2049,%r9d

	cmpl	$2147483656,%r10d
	jb	.Lintel

	movl	$2147483656,%eax
	cpuid

	movzbq	%cl,%r10
	incq	%r10

	movl	$1,%eax
	cpuid

	btl	$28,%edx
	jnc	.Lgeneric
	shrl	$16,%ebx
	cmpb	%r10b,%bl
	ja	.Lgeneric
	andl	$4026531839,%edx
	jmp	.Lgeneric

.Lintel:
	cmpl	$4,%r11d
	movl	$-1,%r10d
	jb	.Lnocacheinfo

	movl	$4,%eax
	movl	$0,%ecx
	cpuid
	movl	%eax,%r10d
	shrl	$14,%r10d
	andl	$4095,%r10d

	cmpl	$7,%r11d
	jb	.Lnocacheinfo

	movl	$7,%eax
	xorl	%ecx,%ecx
	cpuid
	movl	%ebx,8(%rdi)

.Lnocacheinfo:
	movl	$1,%eax
	cpuid

	andl	$3220176895,%edx
	cmpl	$0,%r9d
	jne	.Lnotintel
	orl	$1073741824,%edx
.Lnotintel:
	btl	$28,%edx
	jnc	.Lgeneric
	andl	$4026531839,%edx
	cmpl	$0,%r10d
	je	.Lgeneric

	orl	$268435456,%edx
	shrl	$16,%ebx
	cmpb	$1,%bl
	ja	.Lgeneric
	andl	$4026531839,%edx
.Lgeneric:
	andl	$2048,%r9d
	andl	$4294965247,%ecx
	orl	%ecx,%r9d

	movl	%edx,%r10d
	btl	$27,%r9d
	jnc	.Lclear_avx
	xorl	%ecx,%ecx
.byte	0x0f,0x01,0xd0
	andl	$6,%eax
	cmpl	$6,%eax
	je	.Ldone
.Lclear_avx:
	movl	$4026525695,%eax
	andl	%eax,%r9d
	andl	$4294967263,8(%rdi)
.Ldone:
	movl	%r9d,4(%rdi)
	movl	%r10d,0(%rdi)
	movq	%r8,%rbx
	.byte	0xf3,0xc3
.size	OPENSSL_ia32_cpuid,.-OPENSSL_ia32_cpuid

#endif
