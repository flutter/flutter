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
;extern	_OPENSSL_ia32cap_P
global	_bn_mul_mont
align	16
_bn_mul_mont:
L$_bn_mul_mont_begin:
	push	ebp
	push	ebx
	push	esi
	push	edi
	xor	eax,eax
	mov	edi,DWORD [40+esp]
	cmp	edi,4
	jl	NEAR L$000just_leave
	lea	esi,[20+esp]
	lea	edx,[24+esp]
	mov	ebp,esp
	add	edi,2
	neg	edi
	lea	esp,[edi*4+esp-32]
	neg	edi
	mov	eax,esp
	sub	eax,edx
	and	eax,2047
	sub	esp,eax
	xor	edx,esp
	and	edx,2048
	xor	edx,2048
	sub	esp,edx
	and	esp,-64
	mov	eax,DWORD [esi]
	mov	ebx,DWORD [4+esi]
	mov	ecx,DWORD [8+esi]
	mov	edx,DWORD [12+esi]
	mov	esi,DWORD [16+esi]
	mov	esi,DWORD [esi]
	mov	DWORD [4+esp],eax
	mov	DWORD [8+esp],ebx
	mov	DWORD [12+esp],ecx
	mov	DWORD [16+esp],edx
	mov	DWORD [20+esp],esi
	lea	ebx,[edi-3]
	mov	DWORD [24+esp],ebp
	lea	eax,[_OPENSSL_ia32cap_P]
	bt	DWORD [eax],26
	jnc	NEAR L$001non_sse2
	mov	eax,-1
	movd	mm7,eax
	mov	esi,DWORD [8+esp]
	mov	edi,DWORD [12+esp]
	mov	ebp,DWORD [16+esp]
	xor	edx,edx
	xor	ecx,ecx
	movd	mm4,DWORD [edi]
	movd	mm5,DWORD [esi]
	movd	mm3,DWORD [ebp]
	pmuludq	mm5,mm4
	movq	mm2,mm5
	movq	mm0,mm5
	pand	mm0,mm7
	pmuludq	mm5,[20+esp]
	pmuludq	mm3,mm5
	paddq	mm3,mm0
	movd	mm1,DWORD [4+ebp]
	movd	mm0,DWORD [4+esi]
	psrlq	mm2,32
	psrlq	mm3,32
	inc	ecx
align	16
L$0021st:
	pmuludq	mm0,mm4
	pmuludq	mm1,mm5
	paddq	mm2,mm0
	paddq	mm3,mm1
	movq	mm0,mm2
	pand	mm0,mm7
	movd	mm1,DWORD [4+ecx*4+ebp]
	paddq	mm3,mm0
	movd	mm0,DWORD [4+ecx*4+esi]
	psrlq	mm2,32
	movd	DWORD [28+ecx*4+esp],mm3
	psrlq	mm3,32
	lea	ecx,[1+ecx]
	cmp	ecx,ebx
	jl	NEAR L$0021st
	pmuludq	mm0,mm4
	pmuludq	mm1,mm5
	paddq	mm2,mm0
	paddq	mm3,mm1
	movq	mm0,mm2
	pand	mm0,mm7
	paddq	mm3,mm0
	movd	DWORD [28+ecx*4+esp],mm3
	psrlq	mm2,32
	psrlq	mm3,32
	paddq	mm3,mm2
	movq	[32+ebx*4+esp],mm3
	inc	edx
L$003outer:
	xor	ecx,ecx
	movd	mm4,DWORD [edx*4+edi]
	movd	mm5,DWORD [esi]
	movd	mm6,DWORD [32+esp]
	movd	mm3,DWORD [ebp]
	pmuludq	mm5,mm4
	paddq	mm5,mm6
	movq	mm0,mm5
	movq	mm2,mm5
	pand	mm0,mm7
	pmuludq	mm5,[20+esp]
	pmuludq	mm3,mm5
	paddq	mm3,mm0
	movd	mm6,DWORD [36+esp]
	movd	mm1,DWORD [4+ebp]
	movd	mm0,DWORD [4+esi]
	psrlq	mm2,32
	psrlq	mm3,32
	paddq	mm2,mm6
	inc	ecx
	dec	ebx
L$004inner:
	pmuludq	mm0,mm4
	pmuludq	mm1,mm5
	paddq	mm2,mm0
	paddq	mm3,mm1
	movq	mm0,mm2
	movd	mm6,DWORD [36+ecx*4+esp]
	pand	mm0,mm7
	movd	mm1,DWORD [4+ecx*4+ebp]
	paddq	mm3,mm0
	movd	mm0,DWORD [4+ecx*4+esi]
	psrlq	mm2,32
	movd	DWORD [28+ecx*4+esp],mm3
	psrlq	mm3,32
	paddq	mm2,mm6
	dec	ebx
	lea	ecx,[1+ecx]
	jnz	NEAR L$004inner
	mov	ebx,ecx
	pmuludq	mm0,mm4
	pmuludq	mm1,mm5
	paddq	mm2,mm0
	paddq	mm3,mm1
	movq	mm0,mm2
	pand	mm0,mm7
	paddq	mm3,mm0
	movd	DWORD [28+ecx*4+esp],mm3
	psrlq	mm2,32
	psrlq	mm3,32
	movd	mm6,DWORD [36+ebx*4+esp]
	paddq	mm3,mm2
	paddq	mm3,mm6
	movq	[32+ebx*4+esp],mm3
	lea	edx,[1+edx]
	cmp	edx,ebx
	jle	NEAR L$003outer
	emms
	jmp	NEAR L$005common_tail
align	16
L$001non_sse2:
	mov	esi,DWORD [8+esp]
	lea	ebp,[1+ebx]
	mov	edi,DWORD [12+esp]
	xor	ecx,ecx
	mov	edx,esi
	and	ebp,1
	sub	edx,edi
	lea	eax,[4+ebx*4+edi]
	or	ebp,edx
	mov	edi,DWORD [edi]
	jz	NEAR L$006bn_sqr_mont
	mov	DWORD [28+esp],eax
	mov	eax,DWORD [esi]
	xor	edx,edx
align	16
L$007mull:
	mov	ebp,edx
	mul	edi
	add	ebp,eax
	lea	ecx,[1+ecx]
	adc	edx,0
	mov	eax,DWORD [ecx*4+esi]
	cmp	ecx,ebx
	mov	DWORD [28+ecx*4+esp],ebp
	jl	NEAR L$007mull
	mov	ebp,edx
	mul	edi
	mov	edi,DWORD [20+esp]
	add	eax,ebp
	mov	esi,DWORD [16+esp]
	adc	edx,0
	imul	edi,DWORD [32+esp]
	mov	DWORD [32+ebx*4+esp],eax
	xor	ecx,ecx
	mov	DWORD [36+ebx*4+esp],edx
	mov	DWORD [40+ebx*4+esp],ecx
	mov	eax,DWORD [esi]
	mul	edi
	add	eax,DWORD [32+esp]
	mov	eax,DWORD [4+esi]
	adc	edx,0
	inc	ecx
	jmp	NEAR L$0082ndmadd
align	16
L$0091stmadd:
	mov	ebp,edx
	mul	edi
	add	ebp,DWORD [32+ecx*4+esp]
	lea	ecx,[1+ecx]
	adc	edx,0
	add	ebp,eax
	mov	eax,DWORD [ecx*4+esi]
	adc	edx,0
	cmp	ecx,ebx
	mov	DWORD [28+ecx*4+esp],ebp
	jl	NEAR L$0091stmadd
	mov	ebp,edx
	mul	edi
	add	eax,DWORD [32+ebx*4+esp]
	mov	edi,DWORD [20+esp]
	adc	edx,0
	mov	esi,DWORD [16+esp]
	add	ebp,eax
	adc	edx,0
	imul	edi,DWORD [32+esp]
	xor	ecx,ecx
	add	edx,DWORD [36+ebx*4+esp]
	mov	DWORD [32+ebx*4+esp],ebp
	adc	ecx,0
	mov	eax,DWORD [esi]
	mov	DWORD [36+ebx*4+esp],edx
	mov	DWORD [40+ebx*4+esp],ecx
	mul	edi
	add	eax,DWORD [32+esp]
	mov	eax,DWORD [4+esi]
	adc	edx,0
	mov	ecx,1
align	16
L$0082ndmadd:
	mov	ebp,edx
	mul	edi
	add	ebp,DWORD [32+ecx*4+esp]
	lea	ecx,[1+ecx]
	adc	edx,0
	add	ebp,eax
	mov	eax,DWORD [ecx*4+esi]
	adc	edx,0
	cmp	ecx,ebx
	mov	DWORD [24+ecx*4+esp],ebp
	jl	NEAR L$0082ndmadd
	mov	ebp,edx
	mul	edi
	add	ebp,DWORD [32+ebx*4+esp]
	adc	edx,0
	add	ebp,eax
	adc	edx,0
	mov	DWORD [28+ebx*4+esp],ebp
	xor	eax,eax
	mov	ecx,DWORD [12+esp]
	add	edx,DWORD [36+ebx*4+esp]
	adc	eax,DWORD [40+ebx*4+esp]
	lea	ecx,[4+ecx]
	mov	DWORD [32+ebx*4+esp],edx
	cmp	ecx,DWORD [28+esp]
	mov	DWORD [36+ebx*4+esp],eax
	je	NEAR L$005common_tail
	mov	edi,DWORD [ecx]
	mov	esi,DWORD [8+esp]
	mov	DWORD [12+esp],ecx
	xor	ecx,ecx
	xor	edx,edx
	mov	eax,DWORD [esi]
	jmp	NEAR L$0091stmadd
align	16
L$006bn_sqr_mont:
	mov	DWORD [esp],ebx
	mov	DWORD [12+esp],ecx
	mov	eax,edi
	mul	edi
	mov	DWORD [32+esp],eax
	mov	ebx,edx
	shr	edx,1
	and	ebx,1
	inc	ecx
align	16
L$010sqr:
	mov	eax,DWORD [ecx*4+esi]
	mov	ebp,edx
	mul	edi
	add	eax,ebp
	lea	ecx,[1+ecx]
	adc	edx,0
	lea	ebp,[eax*2+ebx]
	shr	eax,31
	cmp	ecx,DWORD [esp]
	mov	ebx,eax
	mov	DWORD [28+ecx*4+esp],ebp
	jl	NEAR L$010sqr
	mov	eax,DWORD [ecx*4+esi]
	mov	ebp,edx
	mul	edi
	add	eax,ebp
	mov	edi,DWORD [20+esp]
	adc	edx,0
	mov	esi,DWORD [16+esp]
	lea	ebp,[eax*2+ebx]
	imul	edi,DWORD [32+esp]
	shr	eax,31
	mov	DWORD [32+ecx*4+esp],ebp
	lea	ebp,[edx*2+eax]
	mov	eax,DWORD [esi]
	shr	edx,31
	mov	DWORD [36+ecx*4+esp],ebp
	mov	DWORD [40+ecx*4+esp],edx
	mul	edi
	add	eax,DWORD [32+esp]
	mov	ebx,ecx
	adc	edx,0
	mov	eax,DWORD [4+esi]
	mov	ecx,1
align	16
L$0113rdmadd:
	mov	ebp,edx
	mul	edi
	add	ebp,DWORD [32+ecx*4+esp]
	adc	edx,0
	add	ebp,eax
	mov	eax,DWORD [4+ecx*4+esi]
	adc	edx,0
	mov	DWORD [28+ecx*4+esp],ebp
	mov	ebp,edx
	mul	edi
	add	ebp,DWORD [36+ecx*4+esp]
	lea	ecx,[2+ecx]
	adc	edx,0
	add	ebp,eax
	mov	eax,DWORD [ecx*4+esi]
	adc	edx,0
	cmp	ecx,ebx
	mov	DWORD [24+ecx*4+esp],ebp
	jl	NEAR L$0113rdmadd
	mov	ebp,edx
	mul	edi
	add	ebp,DWORD [32+ebx*4+esp]
	adc	edx,0
	add	ebp,eax
	adc	edx,0
	mov	DWORD [28+ebx*4+esp],ebp
	mov	ecx,DWORD [12+esp]
	xor	eax,eax
	mov	esi,DWORD [8+esp]
	add	edx,DWORD [36+ebx*4+esp]
	adc	eax,DWORD [40+ebx*4+esp]
	mov	DWORD [32+ebx*4+esp],edx
	cmp	ecx,ebx
	mov	DWORD [36+ebx*4+esp],eax
	je	NEAR L$005common_tail
	mov	edi,DWORD [4+ecx*4+esi]
	lea	ecx,[1+ecx]
	mov	eax,edi
	mov	DWORD [12+esp],ecx
	mul	edi
	add	eax,DWORD [32+ecx*4+esp]
	adc	edx,0
	mov	DWORD [32+ecx*4+esp],eax
	xor	ebp,ebp
	cmp	ecx,ebx
	lea	ecx,[1+ecx]
	je	NEAR L$012sqrlast
	mov	ebx,edx
	shr	edx,1
	and	ebx,1
align	16
L$013sqradd:
	mov	eax,DWORD [ecx*4+esi]
	mov	ebp,edx
	mul	edi
	add	eax,ebp
	lea	ebp,[eax*1+eax]
	adc	edx,0
	shr	eax,31
	add	ebp,DWORD [32+ecx*4+esp]
	lea	ecx,[1+ecx]
	adc	eax,0
	add	ebp,ebx
	adc	eax,0
	cmp	ecx,DWORD [esp]
	mov	DWORD [28+ecx*4+esp],ebp
	mov	ebx,eax
	jle	NEAR L$013sqradd
	mov	ebp,edx
	add	edx,edx
	shr	ebp,31
	add	edx,ebx
	adc	ebp,0
L$012sqrlast:
	mov	edi,DWORD [20+esp]
	mov	esi,DWORD [16+esp]
	imul	edi,DWORD [32+esp]
	add	edx,DWORD [32+ecx*4+esp]
	mov	eax,DWORD [esi]
	adc	ebp,0
	mov	DWORD [32+ecx*4+esp],edx
	mov	DWORD [36+ecx*4+esp],ebp
	mul	edi
	add	eax,DWORD [32+esp]
	lea	ebx,[ecx-1]
	adc	edx,0
	mov	ecx,1
	mov	eax,DWORD [4+esi]
	jmp	NEAR L$0113rdmadd
align	16
L$005common_tail:
	mov	ebp,DWORD [16+esp]
	mov	edi,DWORD [4+esp]
	lea	esi,[32+esp]
	mov	eax,DWORD [esi]
	mov	ecx,ebx
	xor	edx,edx
align	16
L$014sub:
	sbb	eax,DWORD [edx*4+ebp]
	mov	DWORD [edx*4+edi],eax
	dec	ecx
	mov	eax,DWORD [4+edx*4+esi]
	lea	edx,[1+edx]
	jge	NEAR L$014sub
	sbb	eax,0
align	16
L$015copy:
	mov	edx,DWORD [ebx*4+esi]
	mov	ebp,DWORD [ebx*4+edi]
	xor	edx,ebp
	and	edx,eax
	xor	edx,ebp
	mov	DWORD [ebx*4+esi],ecx
	mov	DWORD [ebx*4+edi],edx
	dec	ebx
	jge	NEAR L$015copy
	mov	esp,DWORD [24+esp]
	mov	eax,1
L$000just_leave:
	pop	edi
	pop	esi
	pop	ebx
	pop	ebp
	ret
db	77,111,110,116,103,111,109,101,114,121,32,77,117,108,116,105
db	112,108,105,99,97,116,105,111,110,32,102,111,114,32,120,56
db	54,44,32,67,82,89,80,84,79,71,65,77,83,32,98,121
db	32,60,97,112,112,114,111,64,111,112,101,110,115,115,108,46
db	111,114,103,62,0
segment	.bss
common	_OPENSSL_ia32cap_P 16
