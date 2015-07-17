%ifidn __OUTPUT_FORMAT__,obj
section	code	use32 class=code align=64
%elifidn __OUTPUT_FORMAT__,win32
%ifdef __YASM_VERSION_ID__
%if __YASM_VERSION_ID__ < 01010000h
%error yasm version 1.1.0 or later needed.
%endif
; Yasm automatically includes .00 and complains about redefining it.
; https://www.tortall.net/projects/yasm/manual/html/objfmt-win32-safeseh.html
%else
$@feat.00 equ 1
%endif
section	.text	code align=64
%else
section	.text	code
%endif
global	_OPENSSL_ia32_cpuid
align	16
_OPENSSL_ia32_cpuid:
L$_OPENSSL_ia32_cpuid_begin:
	push	ebp
	push	ebx
	push	esi
	push	edi
	xor	edx,edx
	pushfd
	pop	eax
	mov	ecx,eax
	xor	eax,2097152
	push	eax
	popfd
	pushfd
	pop	eax
	xor	ecx,eax
	xor	eax,eax
	bt	ecx,21
	jnc	NEAR L$000nocpuid
	mov	esi,DWORD [20+esp]
	mov	DWORD [8+esi],eax
	cpuid
	mov	edi,eax
	xor	eax,eax
	cmp	ebx,1970169159
	setne	al
	mov	ebp,eax
	cmp	edx,1231384169
	setne	al
	or	ebp,eax
	cmp	ecx,1818588270
	setne	al
	or	ebp,eax
	jz	NEAR L$001intel
	cmp	ebx,1752462657
	setne	al
	mov	esi,eax
	cmp	edx,1769238117
	setne	al
	or	esi,eax
	cmp	ecx,1145913699
	setne	al
	or	esi,eax
	jnz	NEAR L$001intel
	mov	eax,2147483648
	cpuid
	cmp	eax,2147483649
	jb	NEAR L$001intel
	mov	esi,eax
	mov	eax,2147483649
	cpuid
	or	ebp,ecx
	and	ebp,2049
	cmp	esi,2147483656
	jb	NEAR L$001intel
	mov	eax,2147483656
	cpuid
	movzx	esi,cl
	inc	esi
	mov	eax,1
	xor	ecx,ecx
	cpuid
	bt	edx,28
	jnc	NEAR L$002generic
	shr	ebx,16
	and	ebx,255
	cmp	ebx,esi
	ja	NEAR L$002generic
	and	edx,4026531839
	jmp	NEAR L$002generic
L$001intel:
	cmp	edi,7
	jb	NEAR L$003cacheinfo
	mov	esi,DWORD [20+esp]
	mov	eax,7
	xor	ecx,ecx
	cpuid
	mov	DWORD [8+esi],ebx
L$003cacheinfo:
	cmp	edi,4
	mov	edi,-1
	jb	NEAR L$004nocacheinfo
	mov	eax,4
	mov	ecx,0
	cpuid
	mov	edi,eax
	shr	edi,14
	and	edi,4095
L$004nocacheinfo:
	mov	eax,1
	xor	ecx,ecx
	cpuid
	and	edx,3220176895
	cmp	ebp,0
	jne	NEAR L$005notintel
	or	edx,1073741824
L$005notintel:
	bt	edx,28
	jnc	NEAR L$002generic
	and	edx,4026531839
	cmp	edi,0
	je	NEAR L$002generic
	or	edx,268435456
	shr	ebx,16
	cmp	bl,1
	ja	NEAR L$002generic
	and	edx,4026531839
L$002generic:
	and	ebp,2048
	and	ecx,4294965247
	mov	esi,edx
	or	ebp,ecx
	bt	ecx,27
	jnc	NEAR L$006clear_avx
	xor	ecx,ecx
db	15,1,208
	and	eax,6
	cmp	eax,6
	je	NEAR L$007done
	cmp	eax,2
	je	NEAR L$006clear_avx
L$008clear_xmm:
	and	ebp,4261412861
	and	esi,4278190079
L$006clear_avx:
	and	ebp,4026525695
	mov	edi,DWORD [20+esp]
	and	DWORD [8+edi],4294967263
L$007done:
	mov	eax,esi
	mov	edx,ebp
L$000nocpuid:
	pop	edi
	pop	esi
	pop	ebx
	pop	ebp
	ret
;extern	_OPENSSL_ia32cap_P
global	_OPENSSL_rdtsc
align	16
_OPENSSL_rdtsc:
L$_OPENSSL_rdtsc_begin:
	xor	eax,eax
	xor	edx,edx
	lea	ecx,[_OPENSSL_ia32cap_P]
	bt	DWORD [ecx],4
	jnc	NEAR L$009notsc
	rdtsc
L$009notsc:
	ret
global	_OPENSSL_instrument_halt
align	16
_OPENSSL_instrument_halt:
L$_OPENSSL_instrument_halt_begin:
	lea	ecx,[_OPENSSL_ia32cap_P]
	bt	DWORD [ecx],4
	jnc	NEAR L$010nohalt
dd	2421723150
	and	eax,3
	jnz	NEAR L$010nohalt
	pushfd
	pop	eax
	bt	eax,9
	jnc	NEAR L$010nohalt
	rdtsc
	push	edx
	push	eax
	hlt
	rdtsc
	sub	eax,DWORD [esp]
	sbb	edx,DWORD [4+esp]
	add	esp,8
	ret
L$010nohalt:
	xor	eax,eax
	xor	edx,edx
	ret
global	_OPENSSL_far_spin
align	16
_OPENSSL_far_spin:
L$_OPENSSL_far_spin_begin:
	pushfd
	pop	eax
	bt	eax,9
	jnc	NEAR L$011nospin
	mov	eax,DWORD [4+esp]
	mov	ecx,DWORD [8+esp]
dd	2430111262
	xor	eax,eax
	mov	edx,DWORD [ecx]
	jmp	NEAR L$012spin
align	16
L$012spin:
	inc	eax
	cmp	edx,DWORD [ecx]
	je	NEAR L$012spin
dd	529567888
	ret
L$011nospin:
	xor	eax,eax
	xor	edx,edx
	ret
global	_OPENSSL_wipe_cpu
align	16
_OPENSSL_wipe_cpu:
L$_OPENSSL_wipe_cpu_begin:
	xor	eax,eax
	xor	edx,edx
	lea	ecx,[_OPENSSL_ia32cap_P]
	mov	ecx,DWORD [ecx]
	bt	DWORD [ecx],1
	jnc	NEAR L$013no_x87
	and	ecx,83886080
	cmp	ecx,83886080
	jne	NEAR L$014no_sse2
	pxor	xmm0,xmm0
	pxor	xmm1,xmm1
	pxor	xmm2,xmm2
	pxor	xmm3,xmm3
	pxor	xmm4,xmm4
	pxor	xmm5,xmm5
	pxor	xmm6,xmm6
	pxor	xmm7,xmm7
L$014no_sse2:
dd	4007259865,4007259865,4007259865,4007259865,2430851995
L$013no_x87:
	lea	eax,[4+esp]
	ret
global	_OPENSSL_atomic_add
align	16
_OPENSSL_atomic_add:
L$_OPENSSL_atomic_add_begin:
	mov	edx,DWORD [4+esp]
	mov	ecx,DWORD [8+esp]
	push	ebx
	nop
	mov	eax,DWORD [edx]
L$015spin:
	lea	ebx,[ecx*1+eax]
	nop
dd	447811568
	jne	NEAR L$015spin
	mov	eax,ebx
	pop	ebx
	ret
global	_OPENSSL_indirect_call
align	16
_OPENSSL_indirect_call:
L$_OPENSSL_indirect_call_begin:
	push	ebp
	mov	ebp,esp
	sub	esp,28
	mov	ecx,DWORD [12+ebp]
	mov	DWORD [esp],ecx
	mov	edx,DWORD [16+ebp]
	mov	DWORD [4+esp],edx
	mov	eax,DWORD [20+ebp]
	mov	DWORD [8+esp],eax
	mov	eax,DWORD [24+ebp]
	mov	DWORD [12+esp],eax
	mov	eax,DWORD [28+ebp]
	mov	DWORD [16+esp],eax
	mov	eax,DWORD [32+ebp]
	mov	DWORD [20+esp],eax
	mov	eax,DWORD [36+ebp]
	mov	DWORD [24+esp],eax
	call	DWORD [8+ebp]
	mov	esp,ebp
	pop	ebp
	ret
global	_OPENSSL_ia32_rdrand
align	16
_OPENSSL_ia32_rdrand:
L$_OPENSSL_ia32_rdrand_begin:
	mov	ecx,8
L$016loop:
db	15,199,240
	jc	NEAR L$017break
	loop	L$016loop
L$017break:
	cmp	eax,0
	cmove	eax,ecx
	ret
segment	.bss
common	_OPENSSL_ia32cap_P 16
