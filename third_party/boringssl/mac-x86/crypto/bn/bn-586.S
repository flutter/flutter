#if defined(__i386__)
.file	"src/crypto/bn/asm/bn-586.S"
.text
.globl	_bn_mul_add_words
.private_extern	_bn_mul_add_words
.align	4
_bn_mul_add_words:
L_bn_mul_add_words_begin:
	call	L000PIC_me_up
L000PIC_me_up:
	popl	%eax
	movl	L_OPENSSL_ia32cap_P$non_lazy_ptr-L000PIC_me_up(%eax),%eax
	btl	$26,(%eax)
	jnc	L001maw_non_sse2
	movl	4(%esp),%eax
	movl	8(%esp),%edx
	movl	12(%esp),%ecx
	movd	16(%esp),%mm0
	pxor	%mm1,%mm1
	jmp	L002maw_sse2_entry
.align	4,0x90
L003maw_sse2_unrolled:
	movd	(%eax),%mm3
	paddq	%mm3,%mm1
	movd	(%edx),%mm2
	pmuludq	%mm0,%mm2
	movd	4(%edx),%mm4
	pmuludq	%mm0,%mm4
	movd	8(%edx),%mm6
	pmuludq	%mm0,%mm6
	movd	12(%edx),%mm7
	pmuludq	%mm0,%mm7
	paddq	%mm2,%mm1
	movd	4(%eax),%mm3
	paddq	%mm4,%mm3
	movd	8(%eax),%mm5
	paddq	%mm6,%mm5
	movd	12(%eax),%mm4
	paddq	%mm4,%mm7
	movd	%mm1,(%eax)
	movd	16(%edx),%mm2
	pmuludq	%mm0,%mm2
	psrlq	$32,%mm1
	movd	20(%edx),%mm4
	pmuludq	%mm0,%mm4
	paddq	%mm3,%mm1
	movd	24(%edx),%mm6
	pmuludq	%mm0,%mm6
	movd	%mm1,4(%eax)
	psrlq	$32,%mm1
	movd	28(%edx),%mm3
	addl	$32,%edx
	pmuludq	%mm0,%mm3
	paddq	%mm5,%mm1
	movd	16(%eax),%mm5
	paddq	%mm5,%mm2
	movd	%mm1,8(%eax)
	psrlq	$32,%mm1
	paddq	%mm7,%mm1
	movd	20(%eax),%mm5
	paddq	%mm5,%mm4
	movd	%mm1,12(%eax)
	psrlq	$32,%mm1
	paddq	%mm2,%mm1
	movd	24(%eax),%mm5
	paddq	%mm5,%mm6
	movd	%mm1,16(%eax)
	psrlq	$32,%mm1
	paddq	%mm4,%mm1
	movd	28(%eax),%mm5
	paddq	%mm5,%mm3
	movd	%mm1,20(%eax)
	psrlq	$32,%mm1
	paddq	%mm6,%mm1
	movd	%mm1,24(%eax)
	psrlq	$32,%mm1
	paddq	%mm3,%mm1
	movd	%mm1,28(%eax)
	leal	32(%eax),%eax
	psrlq	$32,%mm1
	subl	$8,%ecx
	jz	L004maw_sse2_exit
L002maw_sse2_entry:
	testl	$4294967288,%ecx
	jnz	L003maw_sse2_unrolled
.align	2,0x90
L005maw_sse2_loop:
	movd	(%edx),%mm2
	movd	(%eax),%mm3
	pmuludq	%mm0,%mm2
	leal	4(%edx),%edx
	paddq	%mm3,%mm1
	paddq	%mm2,%mm1
	movd	%mm1,(%eax)
	subl	$1,%ecx
	psrlq	$32,%mm1
	leal	4(%eax),%eax
	jnz	L005maw_sse2_loop
L004maw_sse2_exit:
	movd	%mm1,%eax
	emms
	ret
.align	4,0x90
L001maw_non_sse2:
	pushl	%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi

	xorl	%esi,%esi
	movl	20(%esp),%edi
	movl	28(%esp),%ecx
	movl	24(%esp),%ebx
	andl	$4294967288,%ecx
	movl	32(%esp),%ebp
	pushl	%ecx
	jz	L006maw_finish
.align	4,0x90
L007maw_loop:
	# Round 0 
	movl	(%ebx),%eax
	mull	%ebp
	addl	%esi,%eax
	adcl	$0,%edx
	addl	(%edi),%eax
	adcl	$0,%edx
	movl	%eax,(%edi)
	movl	%edx,%esi
	# Round 4 
	movl	4(%ebx),%eax
	mull	%ebp
	addl	%esi,%eax
	adcl	$0,%edx
	addl	4(%edi),%eax
	adcl	$0,%edx
	movl	%eax,4(%edi)
	movl	%edx,%esi
	# Round 8 
	movl	8(%ebx),%eax
	mull	%ebp
	addl	%esi,%eax
	adcl	$0,%edx
	addl	8(%edi),%eax
	adcl	$0,%edx
	movl	%eax,8(%edi)
	movl	%edx,%esi
	# Round 12 
	movl	12(%ebx),%eax
	mull	%ebp
	addl	%esi,%eax
	adcl	$0,%edx
	addl	12(%edi),%eax
	adcl	$0,%edx
	movl	%eax,12(%edi)
	movl	%edx,%esi
	# Round 16 
	movl	16(%ebx),%eax
	mull	%ebp
	addl	%esi,%eax
	adcl	$0,%edx
	addl	16(%edi),%eax
	adcl	$0,%edx
	movl	%eax,16(%edi)
	movl	%edx,%esi
	# Round 20 
	movl	20(%ebx),%eax
	mull	%ebp
	addl	%esi,%eax
	adcl	$0,%edx
	addl	20(%edi),%eax
	adcl	$0,%edx
	movl	%eax,20(%edi)
	movl	%edx,%esi
	# Round 24 
	movl	24(%ebx),%eax
	mull	%ebp
	addl	%esi,%eax
	adcl	$0,%edx
	addl	24(%edi),%eax
	adcl	$0,%edx
	movl	%eax,24(%edi)
	movl	%edx,%esi
	# Round 28 
	movl	28(%ebx),%eax
	mull	%ebp
	addl	%esi,%eax
	adcl	$0,%edx
	addl	28(%edi),%eax
	adcl	$0,%edx
	movl	%eax,28(%edi)
	movl	%edx,%esi

	subl	$8,%ecx
	leal	32(%ebx),%ebx
	leal	32(%edi),%edi
	jnz	L007maw_loop
L006maw_finish:
	movl	32(%esp),%ecx
	andl	$7,%ecx
	jnz	L008maw_finish2
	jmp	L009maw_end
L008maw_finish2:
	# Tail Round 0 
	movl	(%ebx),%eax
	mull	%ebp
	addl	%esi,%eax
	adcl	$0,%edx
	addl	(%edi),%eax
	adcl	$0,%edx
	decl	%ecx
	movl	%eax,(%edi)
	movl	%edx,%esi
	jz	L009maw_end
	# Tail Round 1 
	movl	4(%ebx),%eax
	mull	%ebp
	addl	%esi,%eax
	adcl	$0,%edx
	addl	4(%edi),%eax
	adcl	$0,%edx
	decl	%ecx
	movl	%eax,4(%edi)
	movl	%edx,%esi
	jz	L009maw_end
	# Tail Round 2 
	movl	8(%ebx),%eax
	mull	%ebp
	addl	%esi,%eax
	adcl	$0,%edx
	addl	8(%edi),%eax
	adcl	$0,%edx
	decl	%ecx
	movl	%eax,8(%edi)
	movl	%edx,%esi
	jz	L009maw_end
	# Tail Round 3 
	movl	12(%ebx),%eax
	mull	%ebp
	addl	%esi,%eax
	adcl	$0,%edx
	addl	12(%edi),%eax
	adcl	$0,%edx
	decl	%ecx
	movl	%eax,12(%edi)
	movl	%edx,%esi
	jz	L009maw_end
	# Tail Round 4 
	movl	16(%ebx),%eax
	mull	%ebp
	addl	%esi,%eax
	adcl	$0,%edx
	addl	16(%edi),%eax
	adcl	$0,%edx
	decl	%ecx
	movl	%eax,16(%edi)
	movl	%edx,%esi
	jz	L009maw_end
	# Tail Round 5 
	movl	20(%ebx),%eax
	mull	%ebp
	addl	%esi,%eax
	adcl	$0,%edx
	addl	20(%edi),%eax
	adcl	$0,%edx
	decl	%ecx
	movl	%eax,20(%edi)
	movl	%edx,%esi
	jz	L009maw_end
	# Tail Round 6 
	movl	24(%ebx),%eax
	mull	%ebp
	addl	%esi,%eax
	adcl	$0,%edx
	addl	24(%edi),%eax
	adcl	$0,%edx
	movl	%eax,24(%edi)
	movl	%edx,%esi
L009maw_end:
	movl	%esi,%eax
	popl	%ecx
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret
.globl	_bn_mul_words
.private_extern	_bn_mul_words
.align	4
_bn_mul_words:
L_bn_mul_words_begin:
	call	L010PIC_me_up
L010PIC_me_up:
	popl	%eax
	movl	L_OPENSSL_ia32cap_P$non_lazy_ptr-L010PIC_me_up(%eax),%eax
	btl	$26,(%eax)
	jnc	L011mw_non_sse2
	movl	4(%esp),%eax
	movl	8(%esp),%edx
	movl	12(%esp),%ecx
	movd	16(%esp),%mm0
	pxor	%mm1,%mm1
.align	4,0x90
L012mw_sse2_loop:
	movd	(%edx),%mm2
	pmuludq	%mm0,%mm2
	leal	4(%edx),%edx
	paddq	%mm2,%mm1
	movd	%mm1,(%eax)
	subl	$1,%ecx
	psrlq	$32,%mm1
	leal	4(%eax),%eax
	jnz	L012mw_sse2_loop
	movd	%mm1,%eax
	emms
	ret
.align	4,0x90
L011mw_non_sse2:
	pushl	%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi

	xorl	%esi,%esi
	movl	20(%esp),%edi
	movl	24(%esp),%ebx
	movl	28(%esp),%ebp
	movl	32(%esp),%ecx
	andl	$4294967288,%ebp
	jz	L013mw_finish
L014mw_loop:
	# Round 0 
	movl	(%ebx),%eax
	mull	%ecx
	addl	%esi,%eax
	adcl	$0,%edx
	movl	%eax,(%edi)
	movl	%edx,%esi
	# Round 4 
	movl	4(%ebx),%eax
	mull	%ecx
	addl	%esi,%eax
	adcl	$0,%edx
	movl	%eax,4(%edi)
	movl	%edx,%esi
	# Round 8 
	movl	8(%ebx),%eax
	mull	%ecx
	addl	%esi,%eax
	adcl	$0,%edx
	movl	%eax,8(%edi)
	movl	%edx,%esi
	# Round 12 
	movl	12(%ebx),%eax
	mull	%ecx
	addl	%esi,%eax
	adcl	$0,%edx
	movl	%eax,12(%edi)
	movl	%edx,%esi
	# Round 16 
	movl	16(%ebx),%eax
	mull	%ecx
	addl	%esi,%eax
	adcl	$0,%edx
	movl	%eax,16(%edi)
	movl	%edx,%esi
	# Round 20 
	movl	20(%ebx),%eax
	mull	%ecx
	addl	%esi,%eax
	adcl	$0,%edx
	movl	%eax,20(%edi)
	movl	%edx,%esi
	# Round 24 
	movl	24(%ebx),%eax
	mull	%ecx
	addl	%esi,%eax
	adcl	$0,%edx
	movl	%eax,24(%edi)
	movl	%edx,%esi
	# Round 28 
	movl	28(%ebx),%eax
	mull	%ecx
	addl	%esi,%eax
	adcl	$0,%edx
	movl	%eax,28(%edi)
	movl	%edx,%esi

	addl	$32,%ebx
	addl	$32,%edi
	subl	$8,%ebp
	jz	L013mw_finish
	jmp	L014mw_loop
L013mw_finish:
	movl	28(%esp),%ebp
	andl	$7,%ebp
	jnz	L015mw_finish2
	jmp	L016mw_end
L015mw_finish2:
	# Tail Round 0 
	movl	(%ebx),%eax
	mull	%ecx
	addl	%esi,%eax
	adcl	$0,%edx
	movl	%eax,(%edi)
	movl	%edx,%esi
	decl	%ebp
	jz	L016mw_end
	# Tail Round 1 
	movl	4(%ebx),%eax
	mull	%ecx
	addl	%esi,%eax
	adcl	$0,%edx
	movl	%eax,4(%edi)
	movl	%edx,%esi
	decl	%ebp
	jz	L016mw_end
	# Tail Round 2 
	movl	8(%ebx),%eax
	mull	%ecx
	addl	%esi,%eax
	adcl	$0,%edx
	movl	%eax,8(%edi)
	movl	%edx,%esi
	decl	%ebp
	jz	L016mw_end
	# Tail Round 3 
	movl	12(%ebx),%eax
	mull	%ecx
	addl	%esi,%eax
	adcl	$0,%edx
	movl	%eax,12(%edi)
	movl	%edx,%esi
	decl	%ebp
	jz	L016mw_end
	# Tail Round 4 
	movl	16(%ebx),%eax
	mull	%ecx
	addl	%esi,%eax
	adcl	$0,%edx
	movl	%eax,16(%edi)
	movl	%edx,%esi
	decl	%ebp
	jz	L016mw_end
	# Tail Round 5 
	movl	20(%ebx),%eax
	mull	%ecx
	addl	%esi,%eax
	adcl	$0,%edx
	movl	%eax,20(%edi)
	movl	%edx,%esi
	decl	%ebp
	jz	L016mw_end
	# Tail Round 6 
	movl	24(%ebx),%eax
	mull	%ecx
	addl	%esi,%eax
	adcl	$0,%edx
	movl	%eax,24(%edi)
	movl	%edx,%esi
L016mw_end:
	movl	%esi,%eax
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret
.globl	_bn_sqr_words
.private_extern	_bn_sqr_words
.align	4
_bn_sqr_words:
L_bn_sqr_words_begin:
	call	L017PIC_me_up
L017PIC_me_up:
	popl	%eax
	movl	L_OPENSSL_ia32cap_P$non_lazy_ptr-L017PIC_me_up(%eax),%eax
	btl	$26,(%eax)
	jnc	L018sqr_non_sse2
	movl	4(%esp),%eax
	movl	8(%esp),%edx
	movl	12(%esp),%ecx
.align	4,0x90
L019sqr_sse2_loop:
	movd	(%edx),%mm0
	pmuludq	%mm0,%mm0
	leal	4(%edx),%edx
	movq	%mm0,(%eax)
	subl	$1,%ecx
	leal	8(%eax),%eax
	jnz	L019sqr_sse2_loop
	emms
	ret
.align	4,0x90
L018sqr_non_sse2:
	pushl	%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi

	movl	20(%esp),%esi
	movl	24(%esp),%edi
	movl	28(%esp),%ebx
	andl	$4294967288,%ebx
	jz	L020sw_finish
L021sw_loop:
	# Round 0 
	movl	(%edi),%eax
	mull	%eax
	movl	%eax,(%esi)
	movl	%edx,4(%esi)
	# Round 4 
	movl	4(%edi),%eax
	mull	%eax
	movl	%eax,8(%esi)
	movl	%edx,12(%esi)
	# Round 8 
	movl	8(%edi),%eax
	mull	%eax
	movl	%eax,16(%esi)
	movl	%edx,20(%esi)
	# Round 12 
	movl	12(%edi),%eax
	mull	%eax
	movl	%eax,24(%esi)
	movl	%edx,28(%esi)
	# Round 16 
	movl	16(%edi),%eax
	mull	%eax
	movl	%eax,32(%esi)
	movl	%edx,36(%esi)
	# Round 20 
	movl	20(%edi),%eax
	mull	%eax
	movl	%eax,40(%esi)
	movl	%edx,44(%esi)
	# Round 24 
	movl	24(%edi),%eax
	mull	%eax
	movl	%eax,48(%esi)
	movl	%edx,52(%esi)
	# Round 28 
	movl	28(%edi),%eax
	mull	%eax
	movl	%eax,56(%esi)
	movl	%edx,60(%esi)

	addl	$32,%edi
	addl	$64,%esi
	subl	$8,%ebx
	jnz	L021sw_loop
L020sw_finish:
	movl	28(%esp),%ebx
	andl	$7,%ebx
	jz	L022sw_end
	# Tail Round 0 
	movl	(%edi),%eax
	mull	%eax
	movl	%eax,(%esi)
	decl	%ebx
	movl	%edx,4(%esi)
	jz	L022sw_end
	# Tail Round 1 
	movl	4(%edi),%eax
	mull	%eax
	movl	%eax,8(%esi)
	decl	%ebx
	movl	%edx,12(%esi)
	jz	L022sw_end
	# Tail Round 2 
	movl	8(%edi),%eax
	mull	%eax
	movl	%eax,16(%esi)
	decl	%ebx
	movl	%edx,20(%esi)
	jz	L022sw_end
	# Tail Round 3 
	movl	12(%edi),%eax
	mull	%eax
	movl	%eax,24(%esi)
	decl	%ebx
	movl	%edx,28(%esi)
	jz	L022sw_end
	# Tail Round 4 
	movl	16(%edi),%eax
	mull	%eax
	movl	%eax,32(%esi)
	decl	%ebx
	movl	%edx,36(%esi)
	jz	L022sw_end
	# Tail Round 5 
	movl	20(%edi),%eax
	mull	%eax
	movl	%eax,40(%esi)
	decl	%ebx
	movl	%edx,44(%esi)
	jz	L022sw_end
	# Tail Round 6 
	movl	24(%edi),%eax
	mull	%eax
	movl	%eax,48(%esi)
	movl	%edx,52(%esi)
L022sw_end:
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret
.globl	_bn_div_words
.private_extern	_bn_div_words
.align	4
_bn_div_words:
L_bn_div_words_begin:
	movl	4(%esp),%edx
	movl	8(%esp),%eax
	movl	12(%esp),%ecx
	divl	%ecx
	ret
.globl	_bn_add_words
.private_extern	_bn_add_words
.align	4
_bn_add_words:
L_bn_add_words_begin:
	pushl	%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi

	movl	20(%esp),%ebx
	movl	24(%esp),%esi
	movl	28(%esp),%edi
	movl	32(%esp),%ebp
	xorl	%eax,%eax
	andl	$4294967288,%ebp
	jz	L023aw_finish
L024aw_loop:
	# Round 0 
	movl	(%esi),%ecx
	movl	(%edi),%edx
	addl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	addl	%edx,%ecx
	adcl	$0,%eax
	movl	%ecx,(%ebx)
	# Round 1 
	movl	4(%esi),%ecx
	movl	4(%edi),%edx
	addl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	addl	%edx,%ecx
	adcl	$0,%eax
	movl	%ecx,4(%ebx)
	# Round 2 
	movl	8(%esi),%ecx
	movl	8(%edi),%edx
	addl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	addl	%edx,%ecx
	adcl	$0,%eax
	movl	%ecx,8(%ebx)
	# Round 3 
	movl	12(%esi),%ecx
	movl	12(%edi),%edx
	addl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	addl	%edx,%ecx
	adcl	$0,%eax
	movl	%ecx,12(%ebx)
	# Round 4 
	movl	16(%esi),%ecx
	movl	16(%edi),%edx
	addl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	addl	%edx,%ecx
	adcl	$0,%eax
	movl	%ecx,16(%ebx)
	# Round 5 
	movl	20(%esi),%ecx
	movl	20(%edi),%edx
	addl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	addl	%edx,%ecx
	adcl	$0,%eax
	movl	%ecx,20(%ebx)
	# Round 6 
	movl	24(%esi),%ecx
	movl	24(%edi),%edx
	addl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	addl	%edx,%ecx
	adcl	$0,%eax
	movl	%ecx,24(%ebx)
	# Round 7 
	movl	28(%esi),%ecx
	movl	28(%edi),%edx
	addl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	addl	%edx,%ecx
	adcl	$0,%eax
	movl	%ecx,28(%ebx)

	addl	$32,%esi
	addl	$32,%edi
	addl	$32,%ebx
	subl	$8,%ebp
	jnz	L024aw_loop
L023aw_finish:
	movl	32(%esp),%ebp
	andl	$7,%ebp
	jz	L025aw_end
	# Tail Round 0 
	movl	(%esi),%ecx
	movl	(%edi),%edx
	addl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	addl	%edx,%ecx
	adcl	$0,%eax
	decl	%ebp
	movl	%ecx,(%ebx)
	jz	L025aw_end
	# Tail Round 1 
	movl	4(%esi),%ecx
	movl	4(%edi),%edx
	addl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	addl	%edx,%ecx
	adcl	$0,%eax
	decl	%ebp
	movl	%ecx,4(%ebx)
	jz	L025aw_end
	# Tail Round 2 
	movl	8(%esi),%ecx
	movl	8(%edi),%edx
	addl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	addl	%edx,%ecx
	adcl	$0,%eax
	decl	%ebp
	movl	%ecx,8(%ebx)
	jz	L025aw_end
	# Tail Round 3 
	movl	12(%esi),%ecx
	movl	12(%edi),%edx
	addl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	addl	%edx,%ecx
	adcl	$0,%eax
	decl	%ebp
	movl	%ecx,12(%ebx)
	jz	L025aw_end
	# Tail Round 4 
	movl	16(%esi),%ecx
	movl	16(%edi),%edx
	addl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	addl	%edx,%ecx
	adcl	$0,%eax
	decl	%ebp
	movl	%ecx,16(%ebx)
	jz	L025aw_end
	# Tail Round 5 
	movl	20(%esi),%ecx
	movl	20(%edi),%edx
	addl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	addl	%edx,%ecx
	adcl	$0,%eax
	decl	%ebp
	movl	%ecx,20(%ebx)
	jz	L025aw_end
	# Tail Round 6 
	movl	24(%esi),%ecx
	movl	24(%edi),%edx
	addl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	addl	%edx,%ecx
	adcl	$0,%eax
	movl	%ecx,24(%ebx)
L025aw_end:
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret
.globl	_bn_sub_words
.private_extern	_bn_sub_words
.align	4
_bn_sub_words:
L_bn_sub_words_begin:
	pushl	%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi

	movl	20(%esp),%ebx
	movl	24(%esp),%esi
	movl	28(%esp),%edi
	movl	32(%esp),%ebp
	xorl	%eax,%eax
	andl	$4294967288,%ebp
	jz	L026aw_finish
L027aw_loop:
	# Round 0 
	movl	(%esi),%ecx
	movl	(%edi),%edx
	subl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	subl	%edx,%ecx
	adcl	$0,%eax
	movl	%ecx,(%ebx)
	# Round 1 
	movl	4(%esi),%ecx
	movl	4(%edi),%edx
	subl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	subl	%edx,%ecx
	adcl	$0,%eax
	movl	%ecx,4(%ebx)
	# Round 2 
	movl	8(%esi),%ecx
	movl	8(%edi),%edx
	subl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	subl	%edx,%ecx
	adcl	$0,%eax
	movl	%ecx,8(%ebx)
	# Round 3 
	movl	12(%esi),%ecx
	movl	12(%edi),%edx
	subl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	subl	%edx,%ecx
	adcl	$0,%eax
	movl	%ecx,12(%ebx)
	# Round 4 
	movl	16(%esi),%ecx
	movl	16(%edi),%edx
	subl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	subl	%edx,%ecx
	adcl	$0,%eax
	movl	%ecx,16(%ebx)
	# Round 5 
	movl	20(%esi),%ecx
	movl	20(%edi),%edx
	subl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	subl	%edx,%ecx
	adcl	$0,%eax
	movl	%ecx,20(%ebx)
	# Round 6 
	movl	24(%esi),%ecx
	movl	24(%edi),%edx
	subl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	subl	%edx,%ecx
	adcl	$0,%eax
	movl	%ecx,24(%ebx)
	# Round 7 
	movl	28(%esi),%ecx
	movl	28(%edi),%edx
	subl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	subl	%edx,%ecx
	adcl	$0,%eax
	movl	%ecx,28(%ebx)

	addl	$32,%esi
	addl	$32,%edi
	addl	$32,%ebx
	subl	$8,%ebp
	jnz	L027aw_loop
L026aw_finish:
	movl	32(%esp),%ebp
	andl	$7,%ebp
	jz	L028aw_end
	# Tail Round 0 
	movl	(%esi),%ecx
	movl	(%edi),%edx
	subl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	subl	%edx,%ecx
	adcl	$0,%eax
	decl	%ebp
	movl	%ecx,(%ebx)
	jz	L028aw_end
	# Tail Round 1 
	movl	4(%esi),%ecx
	movl	4(%edi),%edx
	subl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	subl	%edx,%ecx
	adcl	$0,%eax
	decl	%ebp
	movl	%ecx,4(%ebx)
	jz	L028aw_end
	# Tail Round 2 
	movl	8(%esi),%ecx
	movl	8(%edi),%edx
	subl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	subl	%edx,%ecx
	adcl	$0,%eax
	decl	%ebp
	movl	%ecx,8(%ebx)
	jz	L028aw_end
	# Tail Round 3 
	movl	12(%esi),%ecx
	movl	12(%edi),%edx
	subl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	subl	%edx,%ecx
	adcl	$0,%eax
	decl	%ebp
	movl	%ecx,12(%ebx)
	jz	L028aw_end
	# Tail Round 4 
	movl	16(%esi),%ecx
	movl	16(%edi),%edx
	subl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	subl	%edx,%ecx
	adcl	$0,%eax
	decl	%ebp
	movl	%ecx,16(%ebx)
	jz	L028aw_end
	# Tail Round 5 
	movl	20(%esi),%ecx
	movl	20(%edi),%edx
	subl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	subl	%edx,%ecx
	adcl	$0,%eax
	decl	%ebp
	movl	%ecx,20(%ebx)
	jz	L028aw_end
	# Tail Round 6 
	movl	24(%esi),%ecx
	movl	24(%edi),%edx
	subl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	subl	%edx,%ecx
	adcl	$0,%eax
	movl	%ecx,24(%ebx)
L028aw_end:
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret
.globl	_bn_sub_part_words
.private_extern	_bn_sub_part_words
.align	4
_bn_sub_part_words:
L_bn_sub_part_words_begin:
	pushl	%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi

	movl	20(%esp),%ebx
	movl	24(%esp),%esi
	movl	28(%esp),%edi
	movl	32(%esp),%ebp
	xorl	%eax,%eax
	andl	$4294967288,%ebp
	jz	L029aw_finish
L030aw_loop:
	# Round 0 
	movl	(%esi),%ecx
	movl	(%edi),%edx
	subl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	subl	%edx,%ecx
	adcl	$0,%eax
	movl	%ecx,(%ebx)
	# Round 1 
	movl	4(%esi),%ecx
	movl	4(%edi),%edx
	subl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	subl	%edx,%ecx
	adcl	$0,%eax
	movl	%ecx,4(%ebx)
	# Round 2 
	movl	8(%esi),%ecx
	movl	8(%edi),%edx
	subl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	subl	%edx,%ecx
	adcl	$0,%eax
	movl	%ecx,8(%ebx)
	# Round 3 
	movl	12(%esi),%ecx
	movl	12(%edi),%edx
	subl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	subl	%edx,%ecx
	adcl	$0,%eax
	movl	%ecx,12(%ebx)
	# Round 4 
	movl	16(%esi),%ecx
	movl	16(%edi),%edx
	subl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	subl	%edx,%ecx
	adcl	$0,%eax
	movl	%ecx,16(%ebx)
	# Round 5 
	movl	20(%esi),%ecx
	movl	20(%edi),%edx
	subl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	subl	%edx,%ecx
	adcl	$0,%eax
	movl	%ecx,20(%ebx)
	# Round 6 
	movl	24(%esi),%ecx
	movl	24(%edi),%edx
	subl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	subl	%edx,%ecx
	adcl	$0,%eax
	movl	%ecx,24(%ebx)
	# Round 7 
	movl	28(%esi),%ecx
	movl	28(%edi),%edx
	subl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	subl	%edx,%ecx
	adcl	$0,%eax
	movl	%ecx,28(%ebx)

	addl	$32,%esi
	addl	$32,%edi
	addl	$32,%ebx
	subl	$8,%ebp
	jnz	L030aw_loop
L029aw_finish:
	movl	32(%esp),%ebp
	andl	$7,%ebp
	jz	L031aw_end
	# Tail Round 0 
	movl	(%esi),%ecx
	movl	(%edi),%edx
	subl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	subl	%edx,%ecx
	adcl	$0,%eax
	movl	%ecx,(%ebx)
	addl	$4,%esi
	addl	$4,%edi
	addl	$4,%ebx
	decl	%ebp
	jz	L031aw_end
	# Tail Round 1 
	movl	(%esi),%ecx
	movl	(%edi),%edx
	subl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	subl	%edx,%ecx
	adcl	$0,%eax
	movl	%ecx,(%ebx)
	addl	$4,%esi
	addl	$4,%edi
	addl	$4,%ebx
	decl	%ebp
	jz	L031aw_end
	# Tail Round 2 
	movl	(%esi),%ecx
	movl	(%edi),%edx
	subl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	subl	%edx,%ecx
	adcl	$0,%eax
	movl	%ecx,(%ebx)
	addl	$4,%esi
	addl	$4,%edi
	addl	$4,%ebx
	decl	%ebp
	jz	L031aw_end
	# Tail Round 3 
	movl	(%esi),%ecx
	movl	(%edi),%edx
	subl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	subl	%edx,%ecx
	adcl	$0,%eax
	movl	%ecx,(%ebx)
	addl	$4,%esi
	addl	$4,%edi
	addl	$4,%ebx
	decl	%ebp
	jz	L031aw_end
	# Tail Round 4 
	movl	(%esi),%ecx
	movl	(%edi),%edx
	subl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	subl	%edx,%ecx
	adcl	$0,%eax
	movl	%ecx,(%ebx)
	addl	$4,%esi
	addl	$4,%edi
	addl	$4,%ebx
	decl	%ebp
	jz	L031aw_end
	# Tail Round 5 
	movl	(%esi),%ecx
	movl	(%edi),%edx
	subl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	subl	%edx,%ecx
	adcl	$0,%eax
	movl	%ecx,(%ebx)
	addl	$4,%esi
	addl	$4,%edi
	addl	$4,%ebx
	decl	%ebp
	jz	L031aw_end
	# Tail Round 6 
	movl	(%esi),%ecx
	movl	(%edi),%edx
	subl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	subl	%edx,%ecx
	adcl	$0,%eax
	movl	%ecx,(%ebx)
	addl	$4,%esi
	addl	$4,%edi
	addl	$4,%ebx
L031aw_end:
	cmpl	$0,36(%esp)
	je	L032pw_end
	movl	36(%esp),%ebp
	cmpl	$0,%ebp
	je	L032pw_end
	jge	L033pw_pos
	# pw_neg 
	movl	$0,%edx
	subl	%ebp,%edx
	movl	%edx,%ebp
	andl	$4294967288,%ebp
	jz	L034pw_neg_finish
L035pw_neg_loop:
	# dl<0 Round 0 
	movl	$0,%ecx
	movl	(%edi),%edx
	subl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	subl	%edx,%ecx
	adcl	$0,%eax
	movl	%ecx,(%ebx)
	# dl<0 Round 1 
	movl	$0,%ecx
	movl	4(%edi),%edx
	subl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	subl	%edx,%ecx
	adcl	$0,%eax
	movl	%ecx,4(%ebx)
	# dl<0 Round 2 
	movl	$0,%ecx
	movl	8(%edi),%edx
	subl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	subl	%edx,%ecx
	adcl	$0,%eax
	movl	%ecx,8(%ebx)
	# dl<0 Round 3 
	movl	$0,%ecx
	movl	12(%edi),%edx
	subl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	subl	%edx,%ecx
	adcl	$0,%eax
	movl	%ecx,12(%ebx)
	# dl<0 Round 4 
	movl	$0,%ecx
	movl	16(%edi),%edx
	subl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	subl	%edx,%ecx
	adcl	$0,%eax
	movl	%ecx,16(%ebx)
	# dl<0 Round 5 
	movl	$0,%ecx
	movl	20(%edi),%edx
	subl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	subl	%edx,%ecx
	adcl	$0,%eax
	movl	%ecx,20(%ebx)
	# dl<0 Round 6 
	movl	$0,%ecx
	movl	24(%edi),%edx
	subl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	subl	%edx,%ecx
	adcl	$0,%eax
	movl	%ecx,24(%ebx)
	# dl<0 Round 7 
	movl	$0,%ecx
	movl	28(%edi),%edx
	subl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	subl	%edx,%ecx
	adcl	$0,%eax
	movl	%ecx,28(%ebx)

	addl	$32,%edi
	addl	$32,%ebx
	subl	$8,%ebp
	jnz	L035pw_neg_loop
L034pw_neg_finish:
	movl	36(%esp),%edx
	movl	$0,%ebp
	subl	%edx,%ebp
	andl	$7,%ebp
	jz	L032pw_end
	# dl<0 Tail Round 0 
	movl	$0,%ecx
	movl	(%edi),%edx
	subl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	subl	%edx,%ecx
	adcl	$0,%eax
	decl	%ebp
	movl	%ecx,(%ebx)
	jz	L032pw_end
	# dl<0 Tail Round 1 
	movl	$0,%ecx
	movl	4(%edi),%edx
	subl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	subl	%edx,%ecx
	adcl	$0,%eax
	decl	%ebp
	movl	%ecx,4(%ebx)
	jz	L032pw_end
	# dl<0 Tail Round 2 
	movl	$0,%ecx
	movl	8(%edi),%edx
	subl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	subl	%edx,%ecx
	adcl	$0,%eax
	decl	%ebp
	movl	%ecx,8(%ebx)
	jz	L032pw_end
	# dl<0 Tail Round 3 
	movl	$0,%ecx
	movl	12(%edi),%edx
	subl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	subl	%edx,%ecx
	adcl	$0,%eax
	decl	%ebp
	movl	%ecx,12(%ebx)
	jz	L032pw_end
	# dl<0 Tail Round 4 
	movl	$0,%ecx
	movl	16(%edi),%edx
	subl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	subl	%edx,%ecx
	adcl	$0,%eax
	decl	%ebp
	movl	%ecx,16(%ebx)
	jz	L032pw_end
	# dl<0 Tail Round 5 
	movl	$0,%ecx
	movl	20(%edi),%edx
	subl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	subl	%edx,%ecx
	adcl	$0,%eax
	decl	%ebp
	movl	%ecx,20(%ebx)
	jz	L032pw_end
	# dl<0 Tail Round 6 
	movl	$0,%ecx
	movl	24(%edi),%edx
	subl	%eax,%ecx
	movl	$0,%eax
	adcl	%eax,%eax
	subl	%edx,%ecx
	adcl	$0,%eax
	movl	%ecx,24(%ebx)
	jmp	L032pw_end
L033pw_pos:
	andl	$4294967288,%ebp
	jz	L036pw_pos_finish
L037pw_pos_loop:
	# dl>0 Round 0 
	movl	(%esi),%ecx
	subl	%eax,%ecx
	movl	%ecx,(%ebx)
	jnc	L038pw_nc0
	# dl>0 Round 1 
	movl	4(%esi),%ecx
	subl	%eax,%ecx
	movl	%ecx,4(%ebx)
	jnc	L039pw_nc1
	# dl>0 Round 2 
	movl	8(%esi),%ecx
	subl	%eax,%ecx
	movl	%ecx,8(%ebx)
	jnc	L040pw_nc2
	# dl>0 Round 3 
	movl	12(%esi),%ecx
	subl	%eax,%ecx
	movl	%ecx,12(%ebx)
	jnc	L041pw_nc3
	# dl>0 Round 4 
	movl	16(%esi),%ecx
	subl	%eax,%ecx
	movl	%ecx,16(%ebx)
	jnc	L042pw_nc4
	# dl>0 Round 5 
	movl	20(%esi),%ecx
	subl	%eax,%ecx
	movl	%ecx,20(%ebx)
	jnc	L043pw_nc5
	# dl>0 Round 6 
	movl	24(%esi),%ecx
	subl	%eax,%ecx
	movl	%ecx,24(%ebx)
	jnc	L044pw_nc6
	# dl>0 Round 7 
	movl	28(%esi),%ecx
	subl	%eax,%ecx
	movl	%ecx,28(%ebx)
	jnc	L045pw_nc7

	addl	$32,%esi
	addl	$32,%ebx
	subl	$8,%ebp
	jnz	L037pw_pos_loop
L036pw_pos_finish:
	movl	36(%esp),%ebp
	andl	$7,%ebp
	jz	L032pw_end
	# dl>0 Tail Round 0 
	movl	(%esi),%ecx
	subl	%eax,%ecx
	movl	%ecx,(%ebx)
	jnc	L046pw_tail_nc0
	decl	%ebp
	jz	L032pw_end
	# dl>0 Tail Round 1 
	movl	4(%esi),%ecx
	subl	%eax,%ecx
	movl	%ecx,4(%ebx)
	jnc	L047pw_tail_nc1
	decl	%ebp
	jz	L032pw_end
	# dl>0 Tail Round 2 
	movl	8(%esi),%ecx
	subl	%eax,%ecx
	movl	%ecx,8(%ebx)
	jnc	L048pw_tail_nc2
	decl	%ebp
	jz	L032pw_end
	# dl>0 Tail Round 3 
	movl	12(%esi),%ecx
	subl	%eax,%ecx
	movl	%ecx,12(%ebx)
	jnc	L049pw_tail_nc3
	decl	%ebp
	jz	L032pw_end
	# dl>0 Tail Round 4 
	movl	16(%esi),%ecx
	subl	%eax,%ecx
	movl	%ecx,16(%ebx)
	jnc	L050pw_tail_nc4
	decl	%ebp
	jz	L032pw_end
	# dl>0 Tail Round 5 
	movl	20(%esi),%ecx
	subl	%eax,%ecx
	movl	%ecx,20(%ebx)
	jnc	L051pw_tail_nc5
	decl	%ebp
	jz	L032pw_end
	# dl>0 Tail Round 6 
	movl	24(%esi),%ecx
	subl	%eax,%ecx
	movl	%ecx,24(%ebx)
	jnc	L052pw_tail_nc6
	movl	$1,%eax
	jmp	L032pw_end
L053pw_nc_loop:
	movl	(%esi),%ecx
	movl	%ecx,(%ebx)
L038pw_nc0:
	movl	4(%esi),%ecx
	movl	%ecx,4(%ebx)
L039pw_nc1:
	movl	8(%esi),%ecx
	movl	%ecx,8(%ebx)
L040pw_nc2:
	movl	12(%esi),%ecx
	movl	%ecx,12(%ebx)
L041pw_nc3:
	movl	16(%esi),%ecx
	movl	%ecx,16(%ebx)
L042pw_nc4:
	movl	20(%esi),%ecx
	movl	%ecx,20(%ebx)
L043pw_nc5:
	movl	24(%esi),%ecx
	movl	%ecx,24(%ebx)
L044pw_nc6:
	movl	28(%esi),%ecx
	movl	%ecx,28(%ebx)
L045pw_nc7:

	addl	$32,%esi
	addl	$32,%ebx
	subl	$8,%ebp
	jnz	L053pw_nc_loop
	movl	36(%esp),%ebp
	andl	$7,%ebp
	jz	L054pw_nc_end
	movl	(%esi),%ecx
	movl	%ecx,(%ebx)
L046pw_tail_nc0:
	decl	%ebp
	jz	L054pw_nc_end
	movl	4(%esi),%ecx
	movl	%ecx,4(%ebx)
L047pw_tail_nc1:
	decl	%ebp
	jz	L054pw_nc_end
	movl	8(%esi),%ecx
	movl	%ecx,8(%ebx)
L048pw_tail_nc2:
	decl	%ebp
	jz	L054pw_nc_end
	movl	12(%esi),%ecx
	movl	%ecx,12(%ebx)
L049pw_tail_nc3:
	decl	%ebp
	jz	L054pw_nc_end
	movl	16(%esi),%ecx
	movl	%ecx,16(%ebx)
L050pw_tail_nc4:
	decl	%ebp
	jz	L054pw_nc_end
	movl	20(%esi),%ecx
	movl	%ecx,20(%ebx)
L051pw_tail_nc5:
	decl	%ebp
	jz	L054pw_nc_end
	movl	24(%esi),%ecx
	movl	%ecx,24(%ebx)
L052pw_tail_nc6:
L054pw_nc_end:
	movl	$0,%eax
L032pw_end:
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret
.section __IMPORT,__pointers,non_lazy_symbol_pointers
L_OPENSSL_ia32cap_P$non_lazy_ptr:
.indirect_symbol	_OPENSSL_ia32cap_P
.long	0
#endif
