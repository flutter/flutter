#if defined(__i386__)
.file	"crypto/cpu-x86-asm.S"
.text
.globl	OPENSSL_ia32_cpuid
.hidden	OPENSSL_ia32_cpuid
.type	OPENSSL_ia32_cpuid,@function
.align	16
OPENSSL_ia32_cpuid:
.L_OPENSSL_ia32_cpuid_begin:
	pushl	%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	xorl	%edx,%edx
	pushfl
	popl	%eax
	movl	%eax,%ecx
	xorl	$2097152,%eax
	pushl	%eax
	popfl
	pushfl
	popl	%eax
	xorl	%eax,%ecx
	xorl	%eax,%eax
	btl	$21,%ecx
	jnc	.L000nocpuid
	movl	20(%esp),%esi
	movl	%eax,8(%esi)
	.byte	0x0f,0xa2
	movl	%eax,%edi
	xorl	%eax,%eax
	cmpl	$1970169159,%ebx
	setne	%al
	movl	%eax,%ebp
	cmpl	$1231384169,%edx
	setne	%al
	orl	%eax,%ebp
	cmpl	$1818588270,%ecx
	setne	%al
	orl	%eax,%ebp
	jz	.L001intel
	cmpl	$1752462657,%ebx
	setne	%al
	movl	%eax,%esi
	cmpl	$1769238117,%edx
	setne	%al
	orl	%eax,%esi
	cmpl	$1145913699,%ecx
	setne	%al
	orl	%eax,%esi
	jnz	.L001intel
	movl	$2147483648,%eax
	.byte	0x0f,0xa2
	cmpl	$2147483649,%eax
	jb	.L001intel
	movl	%eax,%esi
	movl	$2147483649,%eax
	.byte	0x0f,0xa2
	orl	%ecx,%ebp
	andl	$2049,%ebp
	cmpl	$2147483656,%esi
	jb	.L001intel
	movl	$2147483656,%eax
	.byte	0x0f,0xa2
	movzbl	%cl,%esi
	incl	%esi
	movl	$1,%eax
	xorl	%ecx,%ecx
	.byte	0x0f,0xa2
	btl	$28,%edx
	jnc	.L002generic
	shrl	$16,%ebx
	andl	$255,%ebx
	cmpl	%esi,%ebx
	ja	.L002generic
	andl	$4026531839,%edx
	jmp	.L002generic
.L001intel:
	cmpl	$7,%edi
	jb	.L003cacheinfo
	movl	20(%esp),%esi
	movl	$7,%eax
	xorl	%ecx,%ecx
	.byte	0x0f,0xa2
	movl	%ebx,8(%esi)
.L003cacheinfo:
	cmpl	$4,%edi
	movl	$-1,%edi
	jb	.L004nocacheinfo
	movl	$4,%eax
	movl	$0,%ecx
	.byte	0x0f,0xa2
	movl	%eax,%edi
	shrl	$14,%edi
	andl	$4095,%edi
.L004nocacheinfo:
	movl	$1,%eax
	xorl	%ecx,%ecx
	.byte	0x0f,0xa2
	andl	$3220176895,%edx
	cmpl	$0,%ebp
	jne	.L005notintel
	orl	$1073741824,%edx
.L005notintel:
	btl	$28,%edx
	jnc	.L002generic
	andl	$4026531839,%edx
	cmpl	$0,%edi
	je	.L002generic
	orl	$268435456,%edx
	shrl	$16,%ebx
	cmpb	$1,%bl
	ja	.L002generic
	andl	$4026531839,%edx
.L002generic:
	andl	$2048,%ebp
	andl	$4294965247,%ecx
	movl	%edx,%esi
	orl	%ecx,%ebp
	btl	$27,%ecx
	jnc	.L006clear_avx
	xorl	%ecx,%ecx
.byte	15,1,208
	andl	$6,%eax
	cmpl	$6,%eax
	je	.L007done
	cmpl	$2,%eax
	je	.L006clear_avx
.L008clear_xmm:
	andl	$4261412861,%ebp
	andl	$4278190079,%esi
.L006clear_avx:
	andl	$4026525695,%ebp
	movl	20(%esp),%edi
	andl	$4294967263,8(%edi)
.L007done:
	movl	%esi,%eax
	movl	%ebp,%edx
.L000nocpuid:
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret
.size	OPENSSL_ia32_cpuid,.-.L_OPENSSL_ia32_cpuid_begin
.globl	OPENSSL_rdtsc
.hidden	OPENSSL_rdtsc
.type	OPENSSL_rdtsc,@function
.align	16
OPENSSL_rdtsc:
.L_OPENSSL_rdtsc_begin:
	xorl	%eax,%eax
	xorl	%edx,%edx
	call	.L009PIC_me_up
.L009PIC_me_up:
	popl	%ecx
	leal	OPENSSL_ia32cap_P-.L009PIC_me_up(%ecx),%ecx
	btl	$4,(%ecx)
	jnc	.L010notsc
	.byte	0x0f,0x31
.L010notsc:
	ret
.size	OPENSSL_rdtsc,.-.L_OPENSSL_rdtsc_begin
.globl	OPENSSL_instrument_halt
.hidden	OPENSSL_instrument_halt
.type	OPENSSL_instrument_halt,@function
.align	16
OPENSSL_instrument_halt:
.L_OPENSSL_instrument_halt_begin:
	call	.L011PIC_me_up
.L011PIC_me_up:
	popl	%ecx
	leal	OPENSSL_ia32cap_P-.L011PIC_me_up(%ecx),%ecx
	btl	$4,(%ecx)
	jnc	.L012nohalt
.long	2421723150
	andl	$3,%eax
	jnz	.L012nohalt
	pushfl
	popl	%eax
	btl	$9,%eax
	jnc	.L012nohalt
	.byte	0x0f,0x31
	pushl	%edx
	pushl	%eax
	hlt
	.byte	0x0f,0x31
	subl	(%esp),%eax
	sbbl	4(%esp),%edx
	addl	$8,%esp
	ret
.L012nohalt:
	xorl	%eax,%eax
	xorl	%edx,%edx
	ret
.size	OPENSSL_instrument_halt,.-.L_OPENSSL_instrument_halt_begin
.globl	OPENSSL_far_spin
.hidden	OPENSSL_far_spin
.type	OPENSSL_far_spin,@function
.align	16
OPENSSL_far_spin:
.L_OPENSSL_far_spin_begin:
	pushfl
	popl	%eax
	btl	$9,%eax
	jnc	.L013nospin
	movl	4(%esp),%eax
	movl	8(%esp),%ecx
.long	2430111262
	xorl	%eax,%eax
	movl	(%ecx),%edx
	jmp	.L014spin
.align	16
.L014spin:
	incl	%eax
	cmpl	(%ecx),%edx
	je	.L014spin
.long	529567888
	ret
.L013nospin:
	xorl	%eax,%eax
	xorl	%edx,%edx
	ret
.size	OPENSSL_far_spin,.-.L_OPENSSL_far_spin_begin
.globl	OPENSSL_wipe_cpu
.hidden	OPENSSL_wipe_cpu
.type	OPENSSL_wipe_cpu,@function
.align	16
OPENSSL_wipe_cpu:
.L_OPENSSL_wipe_cpu_begin:
	xorl	%eax,%eax
	xorl	%edx,%edx
	call	.L015PIC_me_up
.L015PIC_me_up:
	popl	%ecx
	leal	OPENSSL_ia32cap_P-.L015PIC_me_up(%ecx),%ecx
	movl	(%ecx),%ecx
	btl	$1,(%ecx)
	jnc	.L016no_x87
	andl	$83886080,%ecx
	cmpl	$83886080,%ecx
	jne	.L017no_sse2
	pxor	%xmm0,%xmm0
	pxor	%xmm1,%xmm1
	pxor	%xmm2,%xmm2
	pxor	%xmm3,%xmm3
	pxor	%xmm4,%xmm4
	pxor	%xmm5,%xmm5
	pxor	%xmm6,%xmm6
	pxor	%xmm7,%xmm7
.L017no_sse2:
.long	4007259865,4007259865,4007259865,4007259865,2430851995
.L016no_x87:
	leal	4(%esp),%eax
	ret
.size	OPENSSL_wipe_cpu,.-.L_OPENSSL_wipe_cpu_begin
.globl	OPENSSL_atomic_add
.hidden	OPENSSL_atomic_add
.type	OPENSSL_atomic_add,@function
.align	16
OPENSSL_atomic_add:
.L_OPENSSL_atomic_add_begin:
	movl	4(%esp),%edx
	movl	8(%esp),%ecx
	pushl	%ebx
	nop
	movl	(%edx),%eax
.L018spin:
	leal	(%eax,%ecx,1),%ebx
	nop
.long	447811568
	jne	.L018spin
	movl	%ebx,%eax
	popl	%ebx
	ret
.size	OPENSSL_atomic_add,.-.L_OPENSSL_atomic_add_begin
.globl	OPENSSL_indirect_call
.hidden	OPENSSL_indirect_call
.type	OPENSSL_indirect_call,@function
.align	16
OPENSSL_indirect_call:
.L_OPENSSL_indirect_call_begin:
	pushl	%ebp
	movl	%esp,%ebp
	subl	$28,%esp
	movl	12(%ebp),%ecx
	movl	%ecx,(%esp)
	movl	16(%ebp),%edx
	movl	%edx,4(%esp)
	movl	20(%ebp),%eax
	movl	%eax,8(%esp)
	movl	24(%ebp),%eax
	movl	%eax,12(%esp)
	movl	28(%ebp),%eax
	movl	%eax,16(%esp)
	movl	32(%ebp),%eax
	movl	%eax,20(%esp)
	movl	36(%ebp),%eax
	movl	%eax,24(%esp)
	call	*8(%ebp)
	movl	%ebp,%esp
	popl	%ebp
	ret
.size	OPENSSL_indirect_call,.-.L_OPENSSL_indirect_call_begin
.globl	OPENSSL_ia32_rdrand
.hidden	OPENSSL_ia32_rdrand
.type	OPENSSL_ia32_rdrand,@function
.align	16
OPENSSL_ia32_rdrand:
.L_OPENSSL_ia32_rdrand_begin:
	movl	$8,%ecx
.L019loop:
.byte	15,199,240
	jc	.L020break
	loop	.L019loop
.L020break:
	cmpl	$0,%eax
	cmovel	%ecx,%eax
	ret
.size	OPENSSL_ia32_rdrand,.-.L_OPENSSL_ia32_rdrand_begin
.hidden	OPENSSL_ia32cap_P
#endif
