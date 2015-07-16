#if defined(__i386__)
.file	"src/crypto/bn/asm/co-586.S"
.text
.globl	_bn_mul_comba8
.private_extern	_bn_mul_comba8
.align	4
_bn_mul_comba8:
L_bn_mul_comba8_begin:
	pushl	%esi
	movl	12(%esp),%esi
	pushl	%edi
	movl	20(%esp),%edi
	pushl	%ebp
	pushl	%ebx
	xorl	%ebx,%ebx
	movl	(%esi),%eax
	xorl	%ecx,%ecx
	movl	(%edi),%edx
	# ################## Calculate word 0 
	xorl	%ebp,%ebp
	# mul a[0]*b[0] 
	mull	%edx
	addl	%eax,%ebx
	movl	20(%esp),%eax
	adcl	%edx,%ecx
	movl	(%edi),%edx
	adcl	$0,%ebp
	movl	%ebx,(%eax)
	movl	4(%esi),%eax
	# saved r[0] 
	# ################## Calculate word 1 
	xorl	%ebx,%ebx
	# mul a[1]*b[0] 
	mull	%edx
	addl	%eax,%ecx
	movl	(%esi),%eax
	adcl	%edx,%ebp
	movl	4(%edi),%edx
	adcl	$0,%ebx
	# mul a[0]*b[1] 
	mull	%edx
	addl	%eax,%ecx
	movl	20(%esp),%eax
	adcl	%edx,%ebp
	movl	(%edi),%edx
	adcl	$0,%ebx
	movl	%ecx,4(%eax)
	movl	8(%esi),%eax
	# saved r[1] 
	# ################## Calculate word 2 
	xorl	%ecx,%ecx
	# mul a[2]*b[0] 
	mull	%edx
	addl	%eax,%ebp
	movl	4(%esi),%eax
	adcl	%edx,%ebx
	movl	4(%edi),%edx
	adcl	$0,%ecx
	# mul a[1]*b[1] 
	mull	%edx
	addl	%eax,%ebp
	movl	(%esi),%eax
	adcl	%edx,%ebx
	movl	8(%edi),%edx
	adcl	$0,%ecx
	# mul a[0]*b[2] 
	mull	%edx
	addl	%eax,%ebp
	movl	20(%esp),%eax
	adcl	%edx,%ebx
	movl	(%edi),%edx
	adcl	$0,%ecx
	movl	%ebp,8(%eax)
	movl	12(%esi),%eax
	# saved r[2] 
	# ################## Calculate word 3 
	xorl	%ebp,%ebp
	# mul a[3]*b[0] 
	mull	%edx
	addl	%eax,%ebx
	movl	8(%esi),%eax
	adcl	%edx,%ecx
	movl	4(%edi),%edx
	adcl	$0,%ebp
	# mul a[2]*b[1] 
	mull	%edx
	addl	%eax,%ebx
	movl	4(%esi),%eax
	adcl	%edx,%ecx
	movl	8(%edi),%edx
	adcl	$0,%ebp
	# mul a[1]*b[2] 
	mull	%edx
	addl	%eax,%ebx
	movl	(%esi),%eax
	adcl	%edx,%ecx
	movl	12(%edi),%edx
	adcl	$0,%ebp
	# mul a[0]*b[3] 
	mull	%edx
	addl	%eax,%ebx
	movl	20(%esp),%eax
	adcl	%edx,%ecx
	movl	(%edi),%edx
	adcl	$0,%ebp
	movl	%ebx,12(%eax)
	movl	16(%esi),%eax
	# saved r[3] 
	# ################## Calculate word 4 
	xorl	%ebx,%ebx
	# mul a[4]*b[0] 
	mull	%edx
	addl	%eax,%ecx
	movl	12(%esi),%eax
	adcl	%edx,%ebp
	movl	4(%edi),%edx
	adcl	$0,%ebx
	# mul a[3]*b[1] 
	mull	%edx
	addl	%eax,%ecx
	movl	8(%esi),%eax
	adcl	%edx,%ebp
	movl	8(%edi),%edx
	adcl	$0,%ebx
	# mul a[2]*b[2] 
	mull	%edx
	addl	%eax,%ecx
	movl	4(%esi),%eax
	adcl	%edx,%ebp
	movl	12(%edi),%edx
	adcl	$0,%ebx
	# mul a[1]*b[3] 
	mull	%edx
	addl	%eax,%ecx
	movl	(%esi),%eax
	adcl	%edx,%ebp
	movl	16(%edi),%edx
	adcl	$0,%ebx
	# mul a[0]*b[4] 
	mull	%edx
	addl	%eax,%ecx
	movl	20(%esp),%eax
	adcl	%edx,%ebp
	movl	(%edi),%edx
	adcl	$0,%ebx
	movl	%ecx,16(%eax)
	movl	20(%esi),%eax
	# saved r[4] 
	# ################## Calculate word 5 
	xorl	%ecx,%ecx
	# mul a[5]*b[0] 
	mull	%edx
	addl	%eax,%ebp
	movl	16(%esi),%eax
	adcl	%edx,%ebx
	movl	4(%edi),%edx
	adcl	$0,%ecx
	# mul a[4]*b[1] 
	mull	%edx
	addl	%eax,%ebp
	movl	12(%esi),%eax
	adcl	%edx,%ebx
	movl	8(%edi),%edx
	adcl	$0,%ecx
	# mul a[3]*b[2] 
	mull	%edx
	addl	%eax,%ebp
	movl	8(%esi),%eax
	adcl	%edx,%ebx
	movl	12(%edi),%edx
	adcl	$0,%ecx
	# mul a[2]*b[3] 
	mull	%edx
	addl	%eax,%ebp
	movl	4(%esi),%eax
	adcl	%edx,%ebx
	movl	16(%edi),%edx
	adcl	$0,%ecx
	# mul a[1]*b[4] 
	mull	%edx
	addl	%eax,%ebp
	movl	(%esi),%eax
	adcl	%edx,%ebx
	movl	20(%edi),%edx
	adcl	$0,%ecx
	# mul a[0]*b[5] 
	mull	%edx
	addl	%eax,%ebp
	movl	20(%esp),%eax
	adcl	%edx,%ebx
	movl	(%edi),%edx
	adcl	$0,%ecx
	movl	%ebp,20(%eax)
	movl	24(%esi),%eax
	# saved r[5] 
	# ################## Calculate word 6 
	xorl	%ebp,%ebp
	# mul a[6]*b[0] 
	mull	%edx
	addl	%eax,%ebx
	movl	20(%esi),%eax
	adcl	%edx,%ecx
	movl	4(%edi),%edx
	adcl	$0,%ebp
	# mul a[5]*b[1] 
	mull	%edx
	addl	%eax,%ebx
	movl	16(%esi),%eax
	adcl	%edx,%ecx
	movl	8(%edi),%edx
	adcl	$0,%ebp
	# mul a[4]*b[2] 
	mull	%edx
	addl	%eax,%ebx
	movl	12(%esi),%eax
	adcl	%edx,%ecx
	movl	12(%edi),%edx
	adcl	$0,%ebp
	# mul a[3]*b[3] 
	mull	%edx
	addl	%eax,%ebx
	movl	8(%esi),%eax
	adcl	%edx,%ecx
	movl	16(%edi),%edx
	adcl	$0,%ebp
	# mul a[2]*b[4] 
	mull	%edx
	addl	%eax,%ebx
	movl	4(%esi),%eax
	adcl	%edx,%ecx
	movl	20(%edi),%edx
	adcl	$0,%ebp
	# mul a[1]*b[5] 
	mull	%edx
	addl	%eax,%ebx
	movl	(%esi),%eax
	adcl	%edx,%ecx
	movl	24(%edi),%edx
	adcl	$0,%ebp
	# mul a[0]*b[6] 
	mull	%edx
	addl	%eax,%ebx
	movl	20(%esp),%eax
	adcl	%edx,%ecx
	movl	(%edi),%edx
	adcl	$0,%ebp
	movl	%ebx,24(%eax)
	movl	28(%esi),%eax
	# saved r[6] 
	# ################## Calculate word 7 
	xorl	%ebx,%ebx
	# mul a[7]*b[0] 
	mull	%edx
	addl	%eax,%ecx
	movl	24(%esi),%eax
	adcl	%edx,%ebp
	movl	4(%edi),%edx
	adcl	$0,%ebx
	# mul a[6]*b[1] 
	mull	%edx
	addl	%eax,%ecx
	movl	20(%esi),%eax
	adcl	%edx,%ebp
	movl	8(%edi),%edx
	adcl	$0,%ebx
	# mul a[5]*b[2] 
	mull	%edx
	addl	%eax,%ecx
	movl	16(%esi),%eax
	adcl	%edx,%ebp
	movl	12(%edi),%edx
	adcl	$0,%ebx
	# mul a[4]*b[3] 
	mull	%edx
	addl	%eax,%ecx
	movl	12(%esi),%eax
	adcl	%edx,%ebp
	movl	16(%edi),%edx
	adcl	$0,%ebx
	# mul a[3]*b[4] 
	mull	%edx
	addl	%eax,%ecx
	movl	8(%esi),%eax
	adcl	%edx,%ebp
	movl	20(%edi),%edx
	adcl	$0,%ebx
	# mul a[2]*b[5] 
	mull	%edx
	addl	%eax,%ecx
	movl	4(%esi),%eax
	adcl	%edx,%ebp
	movl	24(%edi),%edx
	adcl	$0,%ebx
	# mul a[1]*b[6] 
	mull	%edx
	addl	%eax,%ecx
	movl	(%esi),%eax
	adcl	%edx,%ebp
	movl	28(%edi),%edx
	adcl	$0,%ebx
	# mul a[0]*b[7] 
	mull	%edx
	addl	%eax,%ecx
	movl	20(%esp),%eax
	adcl	%edx,%ebp
	movl	4(%edi),%edx
	adcl	$0,%ebx
	movl	%ecx,28(%eax)
	movl	28(%esi),%eax
	# saved r[7] 
	# ################## Calculate word 8 
	xorl	%ecx,%ecx
	# mul a[7]*b[1] 
	mull	%edx
	addl	%eax,%ebp
	movl	24(%esi),%eax
	adcl	%edx,%ebx
	movl	8(%edi),%edx
	adcl	$0,%ecx
	# mul a[6]*b[2] 
	mull	%edx
	addl	%eax,%ebp
	movl	20(%esi),%eax
	adcl	%edx,%ebx
	movl	12(%edi),%edx
	adcl	$0,%ecx
	# mul a[5]*b[3] 
	mull	%edx
	addl	%eax,%ebp
	movl	16(%esi),%eax
	adcl	%edx,%ebx
	movl	16(%edi),%edx
	adcl	$0,%ecx
	# mul a[4]*b[4] 
	mull	%edx
	addl	%eax,%ebp
	movl	12(%esi),%eax
	adcl	%edx,%ebx
	movl	20(%edi),%edx
	adcl	$0,%ecx
	# mul a[3]*b[5] 
	mull	%edx
	addl	%eax,%ebp
	movl	8(%esi),%eax
	adcl	%edx,%ebx
	movl	24(%edi),%edx
	adcl	$0,%ecx
	# mul a[2]*b[6] 
	mull	%edx
	addl	%eax,%ebp
	movl	4(%esi),%eax
	adcl	%edx,%ebx
	movl	28(%edi),%edx
	adcl	$0,%ecx
	# mul a[1]*b[7] 
	mull	%edx
	addl	%eax,%ebp
	movl	20(%esp),%eax
	adcl	%edx,%ebx
	movl	8(%edi),%edx
	adcl	$0,%ecx
	movl	%ebp,32(%eax)
	movl	28(%esi),%eax
	# saved r[8] 
	# ################## Calculate word 9 
	xorl	%ebp,%ebp
	# mul a[7]*b[2] 
	mull	%edx
	addl	%eax,%ebx
	movl	24(%esi),%eax
	adcl	%edx,%ecx
	movl	12(%edi),%edx
	adcl	$0,%ebp
	# mul a[6]*b[3] 
	mull	%edx
	addl	%eax,%ebx
	movl	20(%esi),%eax
	adcl	%edx,%ecx
	movl	16(%edi),%edx
	adcl	$0,%ebp
	# mul a[5]*b[4] 
	mull	%edx
	addl	%eax,%ebx
	movl	16(%esi),%eax
	adcl	%edx,%ecx
	movl	20(%edi),%edx
	adcl	$0,%ebp
	# mul a[4]*b[5] 
	mull	%edx
	addl	%eax,%ebx
	movl	12(%esi),%eax
	adcl	%edx,%ecx
	movl	24(%edi),%edx
	adcl	$0,%ebp
	# mul a[3]*b[6] 
	mull	%edx
	addl	%eax,%ebx
	movl	8(%esi),%eax
	adcl	%edx,%ecx
	movl	28(%edi),%edx
	adcl	$0,%ebp
	# mul a[2]*b[7] 
	mull	%edx
	addl	%eax,%ebx
	movl	20(%esp),%eax
	adcl	%edx,%ecx
	movl	12(%edi),%edx
	adcl	$0,%ebp
	movl	%ebx,36(%eax)
	movl	28(%esi),%eax
	# saved r[9] 
	# ################## Calculate word 10 
	xorl	%ebx,%ebx
	# mul a[7]*b[3] 
	mull	%edx
	addl	%eax,%ecx
	movl	24(%esi),%eax
	adcl	%edx,%ebp
	movl	16(%edi),%edx
	adcl	$0,%ebx
	# mul a[6]*b[4] 
	mull	%edx
	addl	%eax,%ecx
	movl	20(%esi),%eax
	adcl	%edx,%ebp
	movl	20(%edi),%edx
	adcl	$0,%ebx
	# mul a[5]*b[5] 
	mull	%edx
	addl	%eax,%ecx
	movl	16(%esi),%eax
	adcl	%edx,%ebp
	movl	24(%edi),%edx
	adcl	$0,%ebx
	# mul a[4]*b[6] 
	mull	%edx
	addl	%eax,%ecx
	movl	12(%esi),%eax
	adcl	%edx,%ebp
	movl	28(%edi),%edx
	adcl	$0,%ebx
	# mul a[3]*b[7] 
	mull	%edx
	addl	%eax,%ecx
	movl	20(%esp),%eax
	adcl	%edx,%ebp
	movl	16(%edi),%edx
	adcl	$0,%ebx
	movl	%ecx,40(%eax)
	movl	28(%esi),%eax
	# saved r[10] 
	# ################## Calculate word 11 
	xorl	%ecx,%ecx
	# mul a[7]*b[4] 
	mull	%edx
	addl	%eax,%ebp
	movl	24(%esi),%eax
	adcl	%edx,%ebx
	movl	20(%edi),%edx
	adcl	$0,%ecx
	# mul a[6]*b[5] 
	mull	%edx
	addl	%eax,%ebp
	movl	20(%esi),%eax
	adcl	%edx,%ebx
	movl	24(%edi),%edx
	adcl	$0,%ecx
	# mul a[5]*b[6] 
	mull	%edx
	addl	%eax,%ebp
	movl	16(%esi),%eax
	adcl	%edx,%ebx
	movl	28(%edi),%edx
	adcl	$0,%ecx
	# mul a[4]*b[7] 
	mull	%edx
	addl	%eax,%ebp
	movl	20(%esp),%eax
	adcl	%edx,%ebx
	movl	20(%edi),%edx
	adcl	$0,%ecx
	movl	%ebp,44(%eax)
	movl	28(%esi),%eax
	# saved r[11] 
	# ################## Calculate word 12 
	xorl	%ebp,%ebp
	# mul a[7]*b[5] 
	mull	%edx
	addl	%eax,%ebx
	movl	24(%esi),%eax
	adcl	%edx,%ecx
	movl	24(%edi),%edx
	adcl	$0,%ebp
	# mul a[6]*b[6] 
	mull	%edx
	addl	%eax,%ebx
	movl	20(%esi),%eax
	adcl	%edx,%ecx
	movl	28(%edi),%edx
	adcl	$0,%ebp
	# mul a[5]*b[7] 
	mull	%edx
	addl	%eax,%ebx
	movl	20(%esp),%eax
	adcl	%edx,%ecx
	movl	24(%edi),%edx
	adcl	$0,%ebp
	movl	%ebx,48(%eax)
	movl	28(%esi),%eax
	# saved r[12] 
	# ################## Calculate word 13 
	xorl	%ebx,%ebx
	# mul a[7]*b[6] 
	mull	%edx
	addl	%eax,%ecx
	movl	24(%esi),%eax
	adcl	%edx,%ebp
	movl	28(%edi),%edx
	adcl	$0,%ebx
	# mul a[6]*b[7] 
	mull	%edx
	addl	%eax,%ecx
	movl	20(%esp),%eax
	adcl	%edx,%ebp
	movl	28(%edi),%edx
	adcl	$0,%ebx
	movl	%ecx,52(%eax)
	movl	28(%esi),%eax
	# saved r[13] 
	# ################## Calculate word 14 
	xorl	%ecx,%ecx
	# mul a[7]*b[7] 
	mull	%edx
	addl	%eax,%ebp
	movl	20(%esp),%eax
	adcl	%edx,%ebx
	adcl	$0,%ecx
	movl	%ebp,56(%eax)
	# saved r[14] 
	# save r[15] 
	movl	%ebx,60(%eax)
	popl	%ebx
	popl	%ebp
	popl	%edi
	popl	%esi
	ret
.globl	_bn_mul_comba4
.private_extern	_bn_mul_comba4
.align	4
_bn_mul_comba4:
L_bn_mul_comba4_begin:
	pushl	%esi
	movl	12(%esp),%esi
	pushl	%edi
	movl	20(%esp),%edi
	pushl	%ebp
	pushl	%ebx
	xorl	%ebx,%ebx
	movl	(%esi),%eax
	xorl	%ecx,%ecx
	movl	(%edi),%edx
	# ################## Calculate word 0 
	xorl	%ebp,%ebp
	# mul a[0]*b[0] 
	mull	%edx
	addl	%eax,%ebx
	movl	20(%esp),%eax
	adcl	%edx,%ecx
	movl	(%edi),%edx
	adcl	$0,%ebp
	movl	%ebx,(%eax)
	movl	4(%esi),%eax
	# saved r[0] 
	# ################## Calculate word 1 
	xorl	%ebx,%ebx
	# mul a[1]*b[0] 
	mull	%edx
	addl	%eax,%ecx
	movl	(%esi),%eax
	adcl	%edx,%ebp
	movl	4(%edi),%edx
	adcl	$0,%ebx
	# mul a[0]*b[1] 
	mull	%edx
	addl	%eax,%ecx
	movl	20(%esp),%eax
	adcl	%edx,%ebp
	movl	(%edi),%edx
	adcl	$0,%ebx
	movl	%ecx,4(%eax)
	movl	8(%esi),%eax
	# saved r[1] 
	# ################## Calculate word 2 
	xorl	%ecx,%ecx
	# mul a[2]*b[0] 
	mull	%edx
	addl	%eax,%ebp
	movl	4(%esi),%eax
	adcl	%edx,%ebx
	movl	4(%edi),%edx
	adcl	$0,%ecx
	# mul a[1]*b[1] 
	mull	%edx
	addl	%eax,%ebp
	movl	(%esi),%eax
	adcl	%edx,%ebx
	movl	8(%edi),%edx
	adcl	$0,%ecx
	# mul a[0]*b[2] 
	mull	%edx
	addl	%eax,%ebp
	movl	20(%esp),%eax
	adcl	%edx,%ebx
	movl	(%edi),%edx
	adcl	$0,%ecx
	movl	%ebp,8(%eax)
	movl	12(%esi),%eax
	# saved r[2] 
	# ################## Calculate word 3 
	xorl	%ebp,%ebp
	# mul a[3]*b[0] 
	mull	%edx
	addl	%eax,%ebx
	movl	8(%esi),%eax
	adcl	%edx,%ecx
	movl	4(%edi),%edx
	adcl	$0,%ebp
	# mul a[2]*b[1] 
	mull	%edx
	addl	%eax,%ebx
	movl	4(%esi),%eax
	adcl	%edx,%ecx
	movl	8(%edi),%edx
	adcl	$0,%ebp
	# mul a[1]*b[2] 
	mull	%edx
	addl	%eax,%ebx
	movl	(%esi),%eax
	adcl	%edx,%ecx
	movl	12(%edi),%edx
	adcl	$0,%ebp
	# mul a[0]*b[3] 
	mull	%edx
	addl	%eax,%ebx
	movl	20(%esp),%eax
	adcl	%edx,%ecx
	movl	4(%edi),%edx
	adcl	$0,%ebp
	movl	%ebx,12(%eax)
	movl	12(%esi),%eax
	# saved r[3] 
	# ################## Calculate word 4 
	xorl	%ebx,%ebx
	# mul a[3]*b[1] 
	mull	%edx
	addl	%eax,%ecx
	movl	8(%esi),%eax
	adcl	%edx,%ebp
	movl	8(%edi),%edx
	adcl	$0,%ebx
	# mul a[2]*b[2] 
	mull	%edx
	addl	%eax,%ecx
	movl	4(%esi),%eax
	adcl	%edx,%ebp
	movl	12(%edi),%edx
	adcl	$0,%ebx
	# mul a[1]*b[3] 
	mull	%edx
	addl	%eax,%ecx
	movl	20(%esp),%eax
	adcl	%edx,%ebp
	movl	8(%edi),%edx
	adcl	$0,%ebx
	movl	%ecx,16(%eax)
	movl	12(%esi),%eax
	# saved r[4] 
	# ################## Calculate word 5 
	xorl	%ecx,%ecx
	# mul a[3]*b[2] 
	mull	%edx
	addl	%eax,%ebp
	movl	8(%esi),%eax
	adcl	%edx,%ebx
	movl	12(%edi),%edx
	adcl	$0,%ecx
	# mul a[2]*b[3] 
	mull	%edx
	addl	%eax,%ebp
	movl	20(%esp),%eax
	adcl	%edx,%ebx
	movl	12(%edi),%edx
	adcl	$0,%ecx
	movl	%ebp,20(%eax)
	movl	12(%esi),%eax
	# saved r[5] 
	# ################## Calculate word 6 
	xorl	%ebp,%ebp
	# mul a[3]*b[3] 
	mull	%edx
	addl	%eax,%ebx
	movl	20(%esp),%eax
	adcl	%edx,%ecx
	adcl	$0,%ebp
	movl	%ebx,24(%eax)
	# saved r[6] 
	# save r[7] 
	movl	%ecx,28(%eax)
	popl	%ebx
	popl	%ebp
	popl	%edi
	popl	%esi
	ret
.globl	_bn_sqr_comba8
.private_extern	_bn_sqr_comba8
.align	4
_bn_sqr_comba8:
L_bn_sqr_comba8_begin:
	pushl	%esi
	pushl	%edi
	pushl	%ebp
	pushl	%ebx
	movl	20(%esp),%edi
	movl	24(%esp),%esi
	xorl	%ebx,%ebx
	xorl	%ecx,%ecx
	movl	(%esi),%eax
	# ############### Calculate word 0 
	xorl	%ebp,%ebp
	# sqr a[0]*a[0] 
	mull	%eax
	addl	%eax,%ebx
	adcl	%edx,%ecx
	movl	(%esi),%edx
	adcl	$0,%ebp
	movl	%ebx,(%edi)
	movl	4(%esi),%eax
	# saved r[0] 
	# ############### Calculate word 1 
	xorl	%ebx,%ebx
	# sqr a[1]*a[0] 
	mull	%edx
	addl	%eax,%eax
	adcl	%edx,%edx
	adcl	$0,%ebx
	addl	%eax,%ecx
	adcl	%edx,%ebp
	movl	8(%esi),%eax
	adcl	$0,%ebx
	movl	%ecx,4(%edi)
	movl	(%esi),%edx
	# saved r[1] 
	# ############### Calculate word 2 
	xorl	%ecx,%ecx
	# sqr a[2]*a[0] 
	mull	%edx
	addl	%eax,%eax
	adcl	%edx,%edx
	adcl	$0,%ecx
	addl	%eax,%ebp
	adcl	%edx,%ebx
	movl	4(%esi),%eax
	adcl	$0,%ecx
	# sqr a[1]*a[1] 
	mull	%eax
	addl	%eax,%ebp
	adcl	%edx,%ebx
	movl	(%esi),%edx
	adcl	$0,%ecx
	movl	%ebp,8(%edi)
	movl	12(%esi),%eax
	# saved r[2] 
	# ############### Calculate word 3 
	xorl	%ebp,%ebp
	# sqr a[3]*a[0] 
	mull	%edx
	addl	%eax,%eax
	adcl	%edx,%edx
	adcl	$0,%ebp
	addl	%eax,%ebx
	adcl	%edx,%ecx
	movl	8(%esi),%eax
	adcl	$0,%ebp
	movl	4(%esi),%edx
	# sqr a[2]*a[1] 
	mull	%edx
	addl	%eax,%eax
	adcl	%edx,%edx
	adcl	$0,%ebp
	addl	%eax,%ebx
	adcl	%edx,%ecx
	movl	16(%esi),%eax
	adcl	$0,%ebp
	movl	%ebx,12(%edi)
	movl	(%esi),%edx
	# saved r[3] 
	# ############### Calculate word 4 
	xorl	%ebx,%ebx
	# sqr a[4]*a[0] 
	mull	%edx
	addl	%eax,%eax
	adcl	%edx,%edx
	adcl	$0,%ebx
	addl	%eax,%ecx
	adcl	%edx,%ebp
	movl	12(%esi),%eax
	adcl	$0,%ebx
	movl	4(%esi),%edx
	# sqr a[3]*a[1] 
	mull	%edx
	addl	%eax,%eax
	adcl	%edx,%edx
	adcl	$0,%ebx
	addl	%eax,%ecx
	adcl	%edx,%ebp
	movl	8(%esi),%eax
	adcl	$0,%ebx
	# sqr a[2]*a[2] 
	mull	%eax
	addl	%eax,%ecx
	adcl	%edx,%ebp
	movl	(%esi),%edx
	adcl	$0,%ebx
	movl	%ecx,16(%edi)
	movl	20(%esi),%eax
	# saved r[4] 
	# ############### Calculate word 5 
	xorl	%ecx,%ecx
	# sqr a[5]*a[0] 
	mull	%edx
	addl	%eax,%eax
	adcl	%edx,%edx
	adcl	$0,%ecx
	addl	%eax,%ebp
	adcl	%edx,%ebx
	movl	16(%esi),%eax
	adcl	$0,%ecx
	movl	4(%esi),%edx
	# sqr a[4]*a[1] 
	mull	%edx
	addl	%eax,%eax
	adcl	%edx,%edx
	adcl	$0,%ecx
	addl	%eax,%ebp
	adcl	%edx,%ebx
	movl	12(%esi),%eax
	adcl	$0,%ecx
	movl	8(%esi),%edx
	# sqr a[3]*a[2] 
	mull	%edx
	addl	%eax,%eax
	adcl	%edx,%edx
	adcl	$0,%ecx
	addl	%eax,%ebp
	adcl	%edx,%ebx
	movl	24(%esi),%eax
	adcl	$0,%ecx
	movl	%ebp,20(%edi)
	movl	(%esi),%edx
	# saved r[5] 
	# ############### Calculate word 6 
	xorl	%ebp,%ebp
	# sqr a[6]*a[0] 
	mull	%edx
	addl	%eax,%eax
	adcl	%edx,%edx
	adcl	$0,%ebp
	addl	%eax,%ebx
	adcl	%edx,%ecx
	movl	20(%esi),%eax
	adcl	$0,%ebp
	movl	4(%esi),%edx
	# sqr a[5]*a[1] 
	mull	%edx
	addl	%eax,%eax
	adcl	%edx,%edx
	adcl	$0,%ebp
	addl	%eax,%ebx
	adcl	%edx,%ecx
	movl	16(%esi),%eax
	adcl	$0,%ebp
	movl	8(%esi),%edx
	# sqr a[4]*a[2] 
	mull	%edx
	addl	%eax,%eax
	adcl	%edx,%edx
	adcl	$0,%ebp
	addl	%eax,%ebx
	adcl	%edx,%ecx
	movl	12(%esi),%eax
	adcl	$0,%ebp
	# sqr a[3]*a[3] 
	mull	%eax
	addl	%eax,%ebx
	adcl	%edx,%ecx
	movl	(%esi),%edx
	adcl	$0,%ebp
	movl	%ebx,24(%edi)
	movl	28(%esi),%eax
	# saved r[6] 
	# ############### Calculate word 7 
	xorl	%ebx,%ebx
	# sqr a[7]*a[0] 
	mull	%edx
	addl	%eax,%eax
	adcl	%edx,%edx
	adcl	$0,%ebx
	addl	%eax,%ecx
	adcl	%edx,%ebp
	movl	24(%esi),%eax
	adcl	$0,%ebx
	movl	4(%esi),%edx
	# sqr a[6]*a[1] 
	mull	%edx
	addl	%eax,%eax
	adcl	%edx,%edx
	adcl	$0,%ebx
	addl	%eax,%ecx
	adcl	%edx,%ebp
	movl	20(%esi),%eax
	adcl	$0,%ebx
	movl	8(%esi),%edx
	# sqr a[5]*a[2] 
	mull	%edx
	addl	%eax,%eax
	adcl	%edx,%edx
	adcl	$0,%ebx
	addl	%eax,%ecx
	adcl	%edx,%ebp
	movl	16(%esi),%eax
	adcl	$0,%ebx
	movl	12(%esi),%edx
	# sqr a[4]*a[3] 
	mull	%edx
	addl	%eax,%eax
	adcl	%edx,%edx
	adcl	$0,%ebx
	addl	%eax,%ecx
	adcl	%edx,%ebp
	movl	28(%esi),%eax
	adcl	$0,%ebx
	movl	%ecx,28(%edi)
	movl	4(%esi),%edx
	# saved r[7] 
	# ############### Calculate word 8 
	xorl	%ecx,%ecx
	# sqr a[7]*a[1] 
	mull	%edx
	addl	%eax,%eax
	adcl	%edx,%edx
	adcl	$0,%ecx
	addl	%eax,%ebp
	adcl	%edx,%ebx
	movl	24(%esi),%eax
	adcl	$0,%ecx
	movl	8(%esi),%edx
	# sqr a[6]*a[2] 
	mull	%edx
	addl	%eax,%eax
	adcl	%edx,%edx
	adcl	$0,%ecx
	addl	%eax,%ebp
	adcl	%edx,%ebx
	movl	20(%esi),%eax
	adcl	$0,%ecx
	movl	12(%esi),%edx
	# sqr a[5]*a[3] 
	mull	%edx
	addl	%eax,%eax
	adcl	%edx,%edx
	adcl	$0,%ecx
	addl	%eax,%ebp
	adcl	%edx,%ebx
	movl	16(%esi),%eax
	adcl	$0,%ecx
	# sqr a[4]*a[4] 
	mull	%eax
	addl	%eax,%ebp
	adcl	%edx,%ebx
	movl	8(%esi),%edx
	adcl	$0,%ecx
	movl	%ebp,32(%edi)
	movl	28(%esi),%eax
	# saved r[8] 
	# ############### Calculate word 9 
	xorl	%ebp,%ebp
	# sqr a[7]*a[2] 
	mull	%edx
	addl	%eax,%eax
	adcl	%edx,%edx
	adcl	$0,%ebp
	addl	%eax,%ebx
	adcl	%edx,%ecx
	movl	24(%esi),%eax
	adcl	$0,%ebp
	movl	12(%esi),%edx
	# sqr a[6]*a[3] 
	mull	%edx
	addl	%eax,%eax
	adcl	%edx,%edx
	adcl	$0,%ebp
	addl	%eax,%ebx
	adcl	%edx,%ecx
	movl	20(%esi),%eax
	adcl	$0,%ebp
	movl	16(%esi),%edx
	# sqr a[5]*a[4] 
	mull	%edx
	addl	%eax,%eax
	adcl	%edx,%edx
	adcl	$0,%ebp
	addl	%eax,%ebx
	adcl	%edx,%ecx
	movl	28(%esi),%eax
	adcl	$0,%ebp
	movl	%ebx,36(%edi)
	movl	12(%esi),%edx
	# saved r[9] 
	# ############### Calculate word 10 
	xorl	%ebx,%ebx
	# sqr a[7]*a[3] 
	mull	%edx
	addl	%eax,%eax
	adcl	%edx,%edx
	adcl	$0,%ebx
	addl	%eax,%ecx
	adcl	%edx,%ebp
	movl	24(%esi),%eax
	adcl	$0,%ebx
	movl	16(%esi),%edx
	# sqr a[6]*a[4] 
	mull	%edx
	addl	%eax,%eax
	adcl	%edx,%edx
	adcl	$0,%ebx
	addl	%eax,%ecx
	adcl	%edx,%ebp
	movl	20(%esi),%eax
	adcl	$0,%ebx
	# sqr a[5]*a[5] 
	mull	%eax
	addl	%eax,%ecx
	adcl	%edx,%ebp
	movl	16(%esi),%edx
	adcl	$0,%ebx
	movl	%ecx,40(%edi)
	movl	28(%esi),%eax
	# saved r[10] 
	# ############### Calculate word 11 
	xorl	%ecx,%ecx
	# sqr a[7]*a[4] 
	mull	%edx
	addl	%eax,%eax
	adcl	%edx,%edx
	adcl	$0,%ecx
	addl	%eax,%ebp
	adcl	%edx,%ebx
	movl	24(%esi),%eax
	adcl	$0,%ecx
	movl	20(%esi),%edx
	# sqr a[6]*a[5] 
	mull	%edx
	addl	%eax,%eax
	adcl	%edx,%edx
	adcl	$0,%ecx
	addl	%eax,%ebp
	adcl	%edx,%ebx
	movl	28(%esi),%eax
	adcl	$0,%ecx
	movl	%ebp,44(%edi)
	movl	20(%esi),%edx
	# saved r[11] 
	# ############### Calculate word 12 
	xorl	%ebp,%ebp
	# sqr a[7]*a[5] 
	mull	%edx
	addl	%eax,%eax
	adcl	%edx,%edx
	adcl	$0,%ebp
	addl	%eax,%ebx
	adcl	%edx,%ecx
	movl	24(%esi),%eax
	adcl	$0,%ebp
	# sqr a[6]*a[6] 
	mull	%eax
	addl	%eax,%ebx
	adcl	%edx,%ecx
	movl	24(%esi),%edx
	adcl	$0,%ebp
	movl	%ebx,48(%edi)
	movl	28(%esi),%eax
	# saved r[12] 
	# ############### Calculate word 13 
	xorl	%ebx,%ebx
	# sqr a[7]*a[6] 
	mull	%edx
	addl	%eax,%eax
	adcl	%edx,%edx
	adcl	$0,%ebx
	addl	%eax,%ecx
	adcl	%edx,%ebp
	movl	28(%esi),%eax
	adcl	$0,%ebx
	movl	%ecx,52(%edi)
	# saved r[13] 
	# ############### Calculate word 14 
	xorl	%ecx,%ecx
	# sqr a[7]*a[7] 
	mull	%eax
	addl	%eax,%ebp
	adcl	%edx,%ebx
	adcl	$0,%ecx
	movl	%ebp,56(%edi)
	# saved r[14] 
	movl	%ebx,60(%edi)
	popl	%ebx
	popl	%ebp
	popl	%edi
	popl	%esi
	ret
.globl	_bn_sqr_comba4
.private_extern	_bn_sqr_comba4
.align	4
_bn_sqr_comba4:
L_bn_sqr_comba4_begin:
	pushl	%esi
	pushl	%edi
	pushl	%ebp
	pushl	%ebx
	movl	20(%esp),%edi
	movl	24(%esp),%esi
	xorl	%ebx,%ebx
	xorl	%ecx,%ecx
	movl	(%esi),%eax
	# ############### Calculate word 0 
	xorl	%ebp,%ebp
	# sqr a[0]*a[0] 
	mull	%eax
	addl	%eax,%ebx
	adcl	%edx,%ecx
	movl	(%esi),%edx
	adcl	$0,%ebp
	movl	%ebx,(%edi)
	movl	4(%esi),%eax
	# saved r[0] 
	# ############### Calculate word 1 
	xorl	%ebx,%ebx
	# sqr a[1]*a[0] 
	mull	%edx
	addl	%eax,%eax
	adcl	%edx,%edx
	adcl	$0,%ebx
	addl	%eax,%ecx
	adcl	%edx,%ebp
	movl	8(%esi),%eax
	adcl	$0,%ebx
	movl	%ecx,4(%edi)
	movl	(%esi),%edx
	# saved r[1] 
	# ############### Calculate word 2 
	xorl	%ecx,%ecx
	# sqr a[2]*a[0] 
	mull	%edx
	addl	%eax,%eax
	adcl	%edx,%edx
	adcl	$0,%ecx
	addl	%eax,%ebp
	adcl	%edx,%ebx
	movl	4(%esi),%eax
	adcl	$0,%ecx
	# sqr a[1]*a[1] 
	mull	%eax
	addl	%eax,%ebp
	adcl	%edx,%ebx
	movl	(%esi),%edx
	adcl	$0,%ecx
	movl	%ebp,8(%edi)
	movl	12(%esi),%eax
	# saved r[2] 
	# ############### Calculate word 3 
	xorl	%ebp,%ebp
	# sqr a[3]*a[0] 
	mull	%edx
	addl	%eax,%eax
	adcl	%edx,%edx
	adcl	$0,%ebp
	addl	%eax,%ebx
	adcl	%edx,%ecx
	movl	8(%esi),%eax
	adcl	$0,%ebp
	movl	4(%esi),%edx
	# sqr a[2]*a[1] 
	mull	%edx
	addl	%eax,%eax
	adcl	%edx,%edx
	adcl	$0,%ebp
	addl	%eax,%ebx
	adcl	%edx,%ecx
	movl	12(%esi),%eax
	adcl	$0,%ebp
	movl	%ebx,12(%edi)
	movl	4(%esi),%edx
	# saved r[3] 
	# ############### Calculate word 4 
	xorl	%ebx,%ebx
	# sqr a[3]*a[1] 
	mull	%edx
	addl	%eax,%eax
	adcl	%edx,%edx
	adcl	$0,%ebx
	addl	%eax,%ecx
	adcl	%edx,%ebp
	movl	8(%esi),%eax
	adcl	$0,%ebx
	# sqr a[2]*a[2] 
	mull	%eax
	addl	%eax,%ecx
	adcl	%edx,%ebp
	movl	8(%esi),%edx
	adcl	$0,%ebx
	movl	%ecx,16(%edi)
	movl	12(%esi),%eax
	# saved r[4] 
	# ############### Calculate word 5 
	xorl	%ecx,%ecx
	# sqr a[3]*a[2] 
	mull	%edx
	addl	%eax,%eax
	adcl	%edx,%edx
	adcl	$0,%ecx
	addl	%eax,%ebp
	adcl	%edx,%ebx
	movl	12(%esi),%eax
	adcl	$0,%ecx
	movl	%ebp,20(%edi)
	# saved r[5] 
	# ############### Calculate word 6 
	xorl	%ebp,%ebp
	# sqr a[3]*a[3] 
	mull	%eax
	addl	%eax,%ebx
	adcl	%edx,%ecx
	adcl	$0,%ebp
	movl	%ebx,24(%edi)
	# saved r[6] 
	movl	%ecx,28(%edi)
	popl	%ebx
	popl	%ebp
	popl	%edi
	popl	%esi
	ret
#endif
