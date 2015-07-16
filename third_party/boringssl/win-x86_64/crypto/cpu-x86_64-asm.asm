default	rel
%define XMMWORD
%define YMMWORD
%define ZMMWORD
section	.text code align=64


global	OPENSSL_ia32_cpuid

ALIGN	16
OPENSSL_ia32_cpuid:
	mov	QWORD[8+rsp],rdi	;WIN64 prologue
	mov	QWORD[16+rsp],rsi
	mov	rax,rsp
$L$SEH_begin_OPENSSL_ia32_cpuid:
	mov	rdi,rcx




	mov	rdi,rcx
	mov	r8,rbx

	xor	eax,eax
	mov	DWORD[8+rdi],eax
	cpuid
	mov	r11d,eax

	xor	eax,eax
	cmp	ebx,0x756e6547
	setne	al
	mov	r9d,eax
	cmp	edx,0x49656e69
	setne	al
	or	r9d,eax
	cmp	ecx,0x6c65746e
	setne	al
	or	r9d,eax
	jz	NEAR $L$intel

	cmp	ebx,0x68747541
	setne	al
	mov	r10d,eax
	cmp	edx,0x69746E65
	setne	al
	or	r10d,eax
	cmp	ecx,0x444D4163
	setne	al
	or	r10d,eax
	jnz	NEAR $L$intel




	mov	eax,0x80000000
	cpuid


	cmp	eax,0x80000001
	jb	NEAR $L$intel
	mov	r10d,eax
	mov	eax,0x80000001
	cpuid


	or	r9d,ecx
	and	r9d,0x00000801

	cmp	r10d,0x80000008
	jb	NEAR $L$intel

	mov	eax,0x80000008
	cpuid

	movzx	r10,cl
	inc	r10

	mov	eax,1
	cpuid

	bt	edx,28
	jnc	NEAR $L$generic
	shr	ebx,16
	cmp	bl,r10b
	ja	NEAR $L$generic
	and	edx,0xefffffff
	jmp	NEAR $L$generic

$L$intel:
	cmp	r11d,4
	mov	r10d,-1
	jb	NEAR $L$nocacheinfo

	mov	eax,4
	mov	ecx,0
	cpuid
	mov	r10d,eax
	shr	r10d,14
	and	r10d,0xfff

	cmp	r11d,7
	jb	NEAR $L$nocacheinfo

	mov	eax,7
	xor	ecx,ecx
	cpuid
	mov	DWORD[8+rdi],ebx

$L$nocacheinfo:
	mov	eax,1
	cpuid

	and	edx,0xbfefffff
	cmp	r9d,0
	jne	NEAR $L$notintel
	or	edx,0x40000000
$L$notintel:
	bt	edx,28
	jnc	NEAR $L$generic
	and	edx,0xefffffff
	cmp	r10d,0
	je	NEAR $L$generic

	or	edx,0x10000000
	shr	ebx,16
	cmp	bl,1
	ja	NEAR $L$generic
	and	edx,0xefffffff
$L$generic:
	and	r9d,0x00000800
	and	ecx,0xfffff7ff
	or	r9d,ecx

	mov	r10d,edx
	bt	r9d,27
	jnc	NEAR $L$clear_avx
	xor	ecx,ecx
DB	0x0f,0x01,0xd0
	and	eax,6
	cmp	eax,6
	je	NEAR $L$done
$L$clear_avx:
	mov	eax,0xefffe7ff
	and	r9d,eax
	and	DWORD[8+rdi],0xffffffdf
$L$done:
	mov	DWORD[4+rdi],r9d
	mov	DWORD[rdi],r10d
	mov	rbx,r8
	mov	rdi,QWORD[8+rsp]	;WIN64 epilogue
	mov	rsi,QWORD[16+rsp]
	DB	0F3h,0C3h		;repret
$L$SEH_end_OPENSSL_ia32_cpuid:

