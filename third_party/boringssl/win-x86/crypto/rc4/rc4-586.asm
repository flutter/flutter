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
global	_asm_RC4
align	16
_asm_RC4:
L$_asm_RC4_begin:
	push	ebp
	push	ebx
	push	esi
	push	edi
	mov	edi,DWORD [20+esp]
	mov	edx,DWORD [24+esp]
	mov	esi,DWORD [28+esp]
	mov	ebp,DWORD [32+esp]
	xor	eax,eax
	xor	ebx,ebx
	cmp	edx,0
	je	NEAR L$000abort
	mov	al,BYTE [edi]
	mov	bl,BYTE [4+edi]
	add	edi,8
	lea	ecx,[edx*1+esi]
	sub	ebp,esi
	mov	DWORD [24+esp],ecx
	inc	al
	cmp	DWORD [256+edi],-1
	je	NEAR L$001RC4_CHAR
	mov	ecx,DWORD [eax*4+edi]
	and	edx,-4
	jz	NEAR L$002loop1
	mov	DWORD [32+esp],ebp
	test	edx,-8
	jz	NEAR L$003go4loop4
	lea	ebp,[_OPENSSL_ia32cap_P]
	bt	DWORD [ebp],26
	jnc	NEAR L$003go4loop4
	mov	ebp,DWORD [32+esp]
	and	edx,-8
	lea	edx,[edx*1+esi-8]
	mov	DWORD [edi-4],edx
	add	bl,cl
	mov	edx,DWORD [ebx*4+edi]
	mov	DWORD [ebx*4+edi],ecx
	mov	DWORD [eax*4+edi],edx
	inc	eax
	add	edx,ecx
	movzx	eax,al
	movzx	edx,dl
	movq	mm0,[esi]
	mov	ecx,DWORD [eax*4+edi]
	movd	mm2,DWORD [edx*4+edi]
	jmp	NEAR L$004loop_mmx_enter
align	16
L$005loop_mmx:
	add	bl,cl
	psllq	mm1,56
	mov	edx,DWORD [ebx*4+edi]
	mov	DWORD [ebx*4+edi],ecx
	mov	DWORD [eax*4+edi],edx
	inc	eax
	add	edx,ecx
	movzx	eax,al
	movzx	edx,dl
	pxor	mm2,mm1
	movq	mm0,[esi]
	movq	[esi*1+ebp-8],mm2
	mov	ecx,DWORD [eax*4+edi]
	movd	mm2,DWORD [edx*4+edi]
L$004loop_mmx_enter:
	add	bl,cl
	mov	edx,DWORD [ebx*4+edi]
	mov	DWORD [ebx*4+edi],ecx
	mov	DWORD [eax*4+edi],edx
	inc	eax
	add	edx,ecx
	movzx	eax,al
	movzx	edx,dl
	pxor	mm2,mm0
	mov	ecx,DWORD [eax*4+edi]
	movd	mm1,DWORD [edx*4+edi]
	add	bl,cl
	psllq	mm1,8
	mov	edx,DWORD [ebx*4+edi]
	mov	DWORD [ebx*4+edi],ecx
	mov	DWORD [eax*4+edi],edx
	inc	eax
	add	edx,ecx
	movzx	eax,al
	movzx	edx,dl
	pxor	mm2,mm1
	mov	ecx,DWORD [eax*4+edi]
	movd	mm1,DWORD [edx*4+edi]
	add	bl,cl
	psllq	mm1,16
	mov	edx,DWORD [ebx*4+edi]
	mov	DWORD [ebx*4+edi],ecx
	mov	DWORD [eax*4+edi],edx
	inc	eax
	add	edx,ecx
	movzx	eax,al
	movzx	edx,dl
	pxor	mm2,mm1
	mov	ecx,DWORD [eax*4+edi]
	movd	mm1,DWORD [edx*4+edi]
	add	bl,cl
	psllq	mm1,24
	mov	edx,DWORD [ebx*4+edi]
	mov	DWORD [ebx*4+edi],ecx
	mov	DWORD [eax*4+edi],edx
	inc	eax
	add	edx,ecx
	movzx	eax,al
	movzx	edx,dl
	pxor	mm2,mm1
	mov	ecx,DWORD [eax*4+edi]
	movd	mm1,DWORD [edx*4+edi]
	add	bl,cl
	psllq	mm1,32
	mov	edx,DWORD [ebx*4+edi]
	mov	DWORD [ebx*4+edi],ecx
	mov	DWORD [eax*4+edi],edx
	inc	eax
	add	edx,ecx
	movzx	eax,al
	movzx	edx,dl
	pxor	mm2,mm1
	mov	ecx,DWORD [eax*4+edi]
	movd	mm1,DWORD [edx*4+edi]
	add	bl,cl
	psllq	mm1,40
	mov	edx,DWORD [ebx*4+edi]
	mov	DWORD [ebx*4+edi],ecx
	mov	DWORD [eax*4+edi],edx
	inc	eax
	add	edx,ecx
	movzx	eax,al
	movzx	edx,dl
	pxor	mm2,mm1
	mov	ecx,DWORD [eax*4+edi]
	movd	mm1,DWORD [edx*4+edi]
	add	bl,cl
	psllq	mm1,48
	mov	edx,DWORD [ebx*4+edi]
	mov	DWORD [ebx*4+edi],ecx
	mov	DWORD [eax*4+edi],edx
	inc	eax
	add	edx,ecx
	movzx	eax,al
	movzx	edx,dl
	pxor	mm2,mm1
	mov	ecx,DWORD [eax*4+edi]
	movd	mm1,DWORD [edx*4+edi]
	mov	edx,ebx
	xor	ebx,ebx
	mov	bl,dl
	cmp	esi,DWORD [edi-4]
	lea	esi,[8+esi]
	jb	NEAR L$005loop_mmx
	psllq	mm1,56
	pxor	mm2,mm1
	movq	[esi*1+ebp-8],mm2
	emms
	cmp	esi,DWORD [24+esp]
	je	NEAR L$006done
	jmp	NEAR L$002loop1
align	16
L$003go4loop4:
	lea	edx,[edx*1+esi-4]
	mov	DWORD [28+esp],edx
L$007loop4:
	add	bl,cl
	mov	edx,DWORD [ebx*4+edi]
	mov	DWORD [ebx*4+edi],ecx
	mov	DWORD [eax*4+edi],edx
	add	edx,ecx
	inc	al
	and	edx,255
	mov	ecx,DWORD [eax*4+edi]
	mov	ebp,DWORD [edx*4+edi]
	add	bl,cl
	mov	edx,DWORD [ebx*4+edi]
	mov	DWORD [ebx*4+edi],ecx
	mov	DWORD [eax*4+edi],edx
	add	edx,ecx
	inc	al
	and	edx,255
	ror	ebp,8
	mov	ecx,DWORD [eax*4+edi]
	or	ebp,DWORD [edx*4+edi]
	add	bl,cl
	mov	edx,DWORD [ebx*4+edi]
	mov	DWORD [ebx*4+edi],ecx
	mov	DWORD [eax*4+edi],edx
	add	edx,ecx
	inc	al
	and	edx,255
	ror	ebp,8
	mov	ecx,DWORD [eax*4+edi]
	or	ebp,DWORD [edx*4+edi]
	add	bl,cl
	mov	edx,DWORD [ebx*4+edi]
	mov	DWORD [ebx*4+edi],ecx
	mov	DWORD [eax*4+edi],edx
	add	edx,ecx
	inc	al
	and	edx,255
	ror	ebp,8
	mov	ecx,DWORD [32+esp]
	or	ebp,DWORD [edx*4+edi]
	ror	ebp,8
	xor	ebp,DWORD [esi]
	cmp	esi,DWORD [28+esp]
	mov	DWORD [esi*1+ecx],ebp
	lea	esi,[4+esi]
	mov	ecx,DWORD [eax*4+edi]
	jb	NEAR L$007loop4
	cmp	esi,DWORD [24+esp]
	je	NEAR L$006done
	mov	ebp,DWORD [32+esp]
align	16
L$002loop1:
	add	bl,cl
	mov	edx,DWORD [ebx*4+edi]
	mov	DWORD [ebx*4+edi],ecx
	mov	DWORD [eax*4+edi],edx
	add	edx,ecx
	inc	al
	and	edx,255
	mov	edx,DWORD [edx*4+edi]
	xor	dl,BYTE [esi]
	lea	esi,[1+esi]
	mov	ecx,DWORD [eax*4+edi]
	cmp	esi,DWORD [24+esp]
	mov	BYTE [esi*1+ebp-1],dl
	jb	NEAR L$002loop1
	jmp	NEAR L$006done
align	16
L$001RC4_CHAR:
	movzx	ecx,BYTE [eax*1+edi]
L$008cloop1:
	add	bl,cl
	movzx	edx,BYTE [ebx*1+edi]
	mov	BYTE [ebx*1+edi],cl
	mov	BYTE [eax*1+edi],dl
	add	dl,cl
	movzx	edx,BYTE [edx*1+edi]
	add	al,1
	xor	dl,BYTE [esi]
	lea	esi,[1+esi]
	movzx	ecx,BYTE [eax*1+edi]
	cmp	esi,DWORD [24+esp]
	mov	BYTE [esi*1+ebp-1],dl
	jb	NEAR L$008cloop1
L$006done:
	dec	al
	mov	DWORD [edi-4],ebx
	mov	BYTE [edi-8],al
L$000abort:
	pop	edi
	pop	esi
	pop	ebx
	pop	ebp
	ret
global	_asm_RC4_set_key
align	16
_asm_RC4_set_key:
L$_asm_RC4_set_key_begin:
	push	ebp
	push	ebx
	push	esi
	push	edi
	mov	edi,DWORD [20+esp]
	mov	ebp,DWORD [24+esp]
	mov	esi,DWORD [28+esp]
	lea	edx,[_OPENSSL_ia32cap_P]
	lea	edi,[8+edi]
	lea	esi,[ebp*1+esi]
	neg	ebp
	xor	eax,eax
	mov	DWORD [edi-4],ebp
	bt	DWORD [edx],20
	jc	NEAR L$009c1stloop
align	16
L$010w1stloop:
	mov	DWORD [eax*4+edi],eax
	add	al,1
	jnc	NEAR L$010w1stloop
	xor	ecx,ecx
	xor	edx,edx
align	16
L$011w2ndloop:
	mov	eax,DWORD [ecx*4+edi]
	add	dl,BYTE [ebp*1+esi]
	add	dl,al
	add	ebp,1
	mov	ebx,DWORD [edx*4+edi]
	jnz	NEAR L$012wnowrap
	mov	ebp,DWORD [edi-4]
L$012wnowrap:
	mov	DWORD [edx*4+edi],eax
	mov	DWORD [ecx*4+edi],ebx
	add	cl,1
	jnc	NEAR L$011w2ndloop
	jmp	NEAR L$013exit
align	16
L$009c1stloop:
	mov	BYTE [eax*1+edi],al
	add	al,1
	jnc	NEAR L$009c1stloop
	xor	ecx,ecx
	xor	edx,edx
	xor	ebx,ebx
align	16
L$014c2ndloop:
	mov	al,BYTE [ecx*1+edi]
	add	dl,BYTE [ebp*1+esi]
	add	dl,al
	add	ebp,1
	mov	bl,BYTE [edx*1+edi]
	jnz	NEAR L$015cnowrap
	mov	ebp,DWORD [edi-4]
L$015cnowrap:
	mov	BYTE [edx*1+edi],al
	mov	BYTE [ecx*1+edi],bl
	add	cl,1
	jnc	NEAR L$014c2ndloop
	mov	DWORD [256+edi],-1
L$013exit:
	xor	eax,eax
	mov	DWORD [edi-8],eax
	mov	DWORD [edi-4],eax
	pop	edi
	pop	esi
	pop	ebx
	pop	ebp
	ret
global	_RC4_options
align	16
_RC4_options:
L$_RC4_options_begin:
	call	L$016pic_point
L$016pic_point:
	pop	eax
	lea	eax,[(L$017opts-L$016pic_point)+eax]
	lea	edx,[_OPENSSL_ia32cap_P]
	mov	edx,DWORD [edx]
	bt	edx,20
	jc	NEAR L$0181xchar
	bt	edx,26
	jnc	NEAR L$019ret
	add	eax,25
	ret
L$0181xchar:
	add	eax,12
L$019ret:
	ret
align	64
L$017opts:
db	114,99,52,40,52,120,44,105,110,116,41,0
db	114,99,52,40,49,120,44,99,104,97,114,41,0
db	114,99,52,40,56,120,44,109,109,120,41,0
db	82,67,52,32,102,111,114,32,120,56,54,44,32,67,82,89
db	80,84,79,71,65,77,83,32,98,121,32,60,97,112,112,114
db	111,64,111,112,101,110,115,115,108,46,111,114,103,62,0
align	64
segment	.bss
common	_OPENSSL_ia32cap_P 16
