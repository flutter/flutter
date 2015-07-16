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
global	_gcm_gmult_4bit_x86
align	16
_gcm_gmult_4bit_x86:
L$_gcm_gmult_4bit_x86_begin:
	push	ebp
	push	ebx
	push	esi
	push	edi
	sub	esp,84
	mov	edi,DWORD [104+esp]
	mov	esi,DWORD [108+esp]
	mov	ebp,DWORD [edi]
	mov	edx,DWORD [4+edi]
	mov	ecx,DWORD [8+edi]
	mov	ebx,DWORD [12+edi]
	mov	DWORD [16+esp],0
	mov	DWORD [20+esp],471859200
	mov	DWORD [24+esp],943718400
	mov	DWORD [28+esp],610271232
	mov	DWORD [32+esp],1887436800
	mov	DWORD [36+esp],1822425088
	mov	DWORD [40+esp],1220542464
	mov	DWORD [44+esp],1423966208
	mov	DWORD [48+esp],3774873600
	mov	DWORD [52+esp],4246732800
	mov	DWORD [56+esp],3644850176
	mov	DWORD [60+esp],3311403008
	mov	DWORD [64+esp],2441084928
	mov	DWORD [68+esp],2376073216
	mov	DWORD [72+esp],2847932416
	mov	DWORD [76+esp],3051356160
	mov	DWORD [esp],ebp
	mov	DWORD [4+esp],edx
	mov	DWORD [8+esp],ecx
	mov	DWORD [12+esp],ebx
	shr	ebx,20
	and	ebx,240
	mov	ebp,DWORD [4+ebx*1+esi]
	mov	edx,DWORD [ebx*1+esi]
	mov	ecx,DWORD [12+ebx*1+esi]
	mov	ebx,DWORD [8+ebx*1+esi]
	xor	eax,eax
	mov	edi,15
	jmp	NEAR L$000x86_loop
align	16
L$000x86_loop:
	mov	al,bl
	shrd	ebx,ecx,4
	and	al,15
	shrd	ecx,edx,4
	shrd	edx,ebp,4
	shr	ebp,4
	xor	ebp,DWORD [16+eax*4+esp]
	mov	al,BYTE [edi*1+esp]
	and	al,240
	xor	ebx,DWORD [8+eax*1+esi]
	xor	ecx,DWORD [12+eax*1+esi]
	xor	edx,DWORD [eax*1+esi]
	xor	ebp,DWORD [4+eax*1+esi]
	dec	edi
	js	NEAR L$001x86_break
	mov	al,bl
	shrd	ebx,ecx,4
	and	al,15
	shrd	ecx,edx,4
	shrd	edx,ebp,4
	shr	ebp,4
	xor	ebp,DWORD [16+eax*4+esp]
	mov	al,BYTE [edi*1+esp]
	shl	al,4
	xor	ebx,DWORD [8+eax*1+esi]
	xor	ecx,DWORD [12+eax*1+esi]
	xor	edx,DWORD [eax*1+esi]
	xor	ebp,DWORD [4+eax*1+esi]
	jmp	NEAR L$000x86_loop
align	16
L$001x86_break:
	bswap	ebx
	bswap	ecx
	bswap	edx
	bswap	ebp
	mov	edi,DWORD [104+esp]
	mov	DWORD [12+edi],ebx
	mov	DWORD [8+edi],ecx
	mov	DWORD [4+edi],edx
	mov	DWORD [edi],ebp
	add	esp,84
	pop	edi
	pop	esi
	pop	ebx
	pop	ebp
	ret
global	_gcm_ghash_4bit_x86
align	16
_gcm_ghash_4bit_x86:
L$_gcm_ghash_4bit_x86_begin:
	push	ebp
	push	ebx
	push	esi
	push	edi
	sub	esp,84
	mov	ebx,DWORD [104+esp]
	mov	esi,DWORD [108+esp]
	mov	edi,DWORD [112+esp]
	mov	ecx,DWORD [116+esp]
	add	ecx,edi
	mov	DWORD [116+esp],ecx
	mov	ebp,DWORD [ebx]
	mov	edx,DWORD [4+ebx]
	mov	ecx,DWORD [8+ebx]
	mov	ebx,DWORD [12+ebx]
	mov	DWORD [16+esp],0
	mov	DWORD [20+esp],471859200
	mov	DWORD [24+esp],943718400
	mov	DWORD [28+esp],610271232
	mov	DWORD [32+esp],1887436800
	mov	DWORD [36+esp],1822425088
	mov	DWORD [40+esp],1220542464
	mov	DWORD [44+esp],1423966208
	mov	DWORD [48+esp],3774873600
	mov	DWORD [52+esp],4246732800
	mov	DWORD [56+esp],3644850176
	mov	DWORD [60+esp],3311403008
	mov	DWORD [64+esp],2441084928
	mov	DWORD [68+esp],2376073216
	mov	DWORD [72+esp],2847932416
	mov	DWORD [76+esp],3051356160
align	16
L$002x86_outer_loop:
	xor	ebx,DWORD [12+edi]
	xor	ecx,DWORD [8+edi]
	xor	edx,DWORD [4+edi]
	xor	ebp,DWORD [edi]
	mov	DWORD [12+esp],ebx
	mov	DWORD [8+esp],ecx
	mov	DWORD [4+esp],edx
	mov	DWORD [esp],ebp
	shr	ebx,20
	and	ebx,240
	mov	ebp,DWORD [4+ebx*1+esi]
	mov	edx,DWORD [ebx*1+esi]
	mov	ecx,DWORD [12+ebx*1+esi]
	mov	ebx,DWORD [8+ebx*1+esi]
	xor	eax,eax
	mov	edi,15
	jmp	NEAR L$003x86_loop
align	16
L$003x86_loop:
	mov	al,bl
	shrd	ebx,ecx,4
	and	al,15
	shrd	ecx,edx,4
	shrd	edx,ebp,4
	shr	ebp,4
	xor	ebp,DWORD [16+eax*4+esp]
	mov	al,BYTE [edi*1+esp]
	and	al,240
	xor	ebx,DWORD [8+eax*1+esi]
	xor	ecx,DWORD [12+eax*1+esi]
	xor	edx,DWORD [eax*1+esi]
	xor	ebp,DWORD [4+eax*1+esi]
	dec	edi
	js	NEAR L$004x86_break
	mov	al,bl
	shrd	ebx,ecx,4
	and	al,15
	shrd	ecx,edx,4
	shrd	edx,ebp,4
	shr	ebp,4
	xor	ebp,DWORD [16+eax*4+esp]
	mov	al,BYTE [edi*1+esp]
	shl	al,4
	xor	ebx,DWORD [8+eax*1+esi]
	xor	ecx,DWORD [12+eax*1+esi]
	xor	edx,DWORD [eax*1+esi]
	xor	ebp,DWORD [4+eax*1+esi]
	jmp	NEAR L$003x86_loop
align	16
L$004x86_break:
	bswap	ebx
	bswap	ecx
	bswap	edx
	bswap	ebp
	mov	edi,DWORD [112+esp]
	lea	edi,[16+edi]
	cmp	edi,DWORD [116+esp]
	mov	DWORD [112+esp],edi
	jb	NEAR L$002x86_outer_loop
	mov	edi,DWORD [104+esp]
	mov	DWORD [12+edi],ebx
	mov	DWORD [8+edi],ecx
	mov	DWORD [4+edi],edx
	mov	DWORD [edi],ebp
	add	esp,84
	pop	edi
	pop	esi
	pop	ebx
	pop	ebp
	ret
global	_gcm_gmult_4bit_mmx
align	16
_gcm_gmult_4bit_mmx:
L$_gcm_gmult_4bit_mmx_begin:
	push	ebp
	push	ebx
	push	esi
	push	edi
	mov	edi,DWORD [20+esp]
	mov	esi,DWORD [24+esp]
	call	L$005pic_point
L$005pic_point:
	pop	eax
	lea	eax,[(L$rem_4bit-L$005pic_point)+eax]
	movzx	ebx,BYTE [15+edi]
	xor	ecx,ecx
	mov	edx,ebx
	mov	cl,dl
	mov	ebp,14
	shl	cl,4
	and	edx,240
	movq	mm0,[8+ecx*1+esi]
	movq	mm1,[ecx*1+esi]
	movd	ebx,mm0
	jmp	NEAR L$006mmx_loop
align	16
L$006mmx_loop:
	psrlq	mm0,4
	and	ebx,15
	movq	mm2,mm1
	psrlq	mm1,4
	pxor	mm0,[8+edx*1+esi]
	mov	cl,BYTE [ebp*1+edi]
	psllq	mm2,60
	pxor	mm1,[ebx*8+eax]
	dec	ebp
	movd	ebx,mm0
	pxor	mm1,[edx*1+esi]
	mov	edx,ecx
	pxor	mm0,mm2
	js	NEAR L$007mmx_break
	shl	cl,4
	and	ebx,15
	psrlq	mm0,4
	and	edx,240
	movq	mm2,mm1
	psrlq	mm1,4
	pxor	mm0,[8+ecx*1+esi]
	psllq	mm2,60
	pxor	mm1,[ebx*8+eax]
	movd	ebx,mm0
	pxor	mm1,[ecx*1+esi]
	pxor	mm0,mm2
	jmp	NEAR L$006mmx_loop
align	16
L$007mmx_break:
	shl	cl,4
	and	ebx,15
	psrlq	mm0,4
	and	edx,240
	movq	mm2,mm1
	psrlq	mm1,4
	pxor	mm0,[8+ecx*1+esi]
	psllq	mm2,60
	pxor	mm1,[ebx*8+eax]
	movd	ebx,mm0
	pxor	mm1,[ecx*1+esi]
	pxor	mm0,mm2
	psrlq	mm0,4
	and	ebx,15
	movq	mm2,mm1
	psrlq	mm1,4
	pxor	mm0,[8+edx*1+esi]
	psllq	mm2,60
	pxor	mm1,[ebx*8+eax]
	movd	ebx,mm0
	pxor	mm1,[edx*1+esi]
	pxor	mm0,mm2
	psrlq	mm0,32
	movd	edx,mm1
	psrlq	mm1,32
	movd	ecx,mm0
	movd	ebp,mm1
	bswap	ebx
	bswap	edx
	bswap	ecx
	bswap	ebp
	emms
	mov	DWORD [12+edi],ebx
	mov	DWORD [4+edi],edx
	mov	DWORD [8+edi],ecx
	mov	DWORD [edi],ebp
	pop	edi
	pop	esi
	pop	ebx
	pop	ebp
	ret
global	_gcm_ghash_4bit_mmx
align	16
_gcm_ghash_4bit_mmx:
L$_gcm_ghash_4bit_mmx_begin:
	push	ebp
	push	ebx
	push	esi
	push	edi
	mov	eax,DWORD [20+esp]
	mov	ebx,DWORD [24+esp]
	mov	ecx,DWORD [28+esp]
	mov	edx,DWORD [32+esp]
	mov	ebp,esp
	call	L$008pic_point
L$008pic_point:
	pop	esi
	lea	esi,[(L$rem_8bit-L$008pic_point)+esi]
	sub	esp,544
	and	esp,-64
	sub	esp,16
	add	edx,ecx
	mov	DWORD [544+esp],eax
	mov	DWORD [552+esp],edx
	mov	DWORD [556+esp],ebp
	add	ebx,128
	lea	edi,[144+esp]
	lea	ebp,[400+esp]
	mov	edx,DWORD [ebx-120]
	movq	mm0,[ebx-120]
	movq	mm3,[ebx-128]
	shl	edx,4
	mov	BYTE [esp],dl
	mov	edx,DWORD [ebx-104]
	movq	mm2,[ebx-104]
	movq	mm5,[ebx-112]
	movq	[edi-128],mm0
	psrlq	mm0,4
	movq	[edi],mm3
	movq	mm7,mm3
	psrlq	mm3,4
	shl	edx,4
	mov	BYTE [1+esp],dl
	mov	edx,DWORD [ebx-88]
	movq	mm1,[ebx-88]
	psllq	mm7,60
	movq	mm4,[ebx-96]
	por	mm0,mm7
	movq	[edi-120],mm2
	psrlq	mm2,4
	movq	[8+edi],mm5
	movq	mm6,mm5
	movq	[ebp-128],mm0
	psrlq	mm5,4
	movq	[ebp],mm3
	shl	edx,4
	mov	BYTE [2+esp],dl
	mov	edx,DWORD [ebx-72]
	movq	mm0,[ebx-72]
	psllq	mm6,60
	movq	mm3,[ebx-80]
	por	mm2,mm6
	movq	[edi-112],mm1
	psrlq	mm1,4
	movq	[16+edi],mm4
	movq	mm7,mm4
	movq	[ebp-120],mm2
	psrlq	mm4,4
	movq	[8+ebp],mm5
	shl	edx,4
	mov	BYTE [3+esp],dl
	mov	edx,DWORD [ebx-56]
	movq	mm2,[ebx-56]
	psllq	mm7,60
	movq	mm5,[ebx-64]
	por	mm1,mm7
	movq	[edi-104],mm0
	psrlq	mm0,4
	movq	[24+edi],mm3
	movq	mm6,mm3
	movq	[ebp-112],mm1
	psrlq	mm3,4
	movq	[16+ebp],mm4
	shl	edx,4
	mov	BYTE [4+esp],dl
	mov	edx,DWORD [ebx-40]
	movq	mm1,[ebx-40]
	psllq	mm6,60
	movq	mm4,[ebx-48]
	por	mm0,mm6
	movq	[edi-96],mm2
	psrlq	mm2,4
	movq	[32+edi],mm5
	movq	mm7,mm5
	movq	[ebp-104],mm0
	psrlq	mm5,4
	movq	[24+ebp],mm3
	shl	edx,4
	mov	BYTE [5+esp],dl
	mov	edx,DWORD [ebx-24]
	movq	mm0,[ebx-24]
	psllq	mm7,60
	movq	mm3,[ebx-32]
	por	mm2,mm7
	movq	[edi-88],mm1
	psrlq	mm1,4
	movq	[40+edi],mm4
	movq	mm6,mm4
	movq	[ebp-96],mm2
	psrlq	mm4,4
	movq	[32+ebp],mm5
	shl	edx,4
	mov	BYTE [6+esp],dl
	mov	edx,DWORD [ebx-8]
	movq	mm2,[ebx-8]
	psllq	mm6,60
	movq	mm5,[ebx-16]
	por	mm1,mm6
	movq	[edi-80],mm0
	psrlq	mm0,4
	movq	[48+edi],mm3
	movq	mm7,mm3
	movq	[ebp-88],mm1
	psrlq	mm3,4
	movq	[40+ebp],mm4
	shl	edx,4
	mov	BYTE [7+esp],dl
	mov	edx,DWORD [8+ebx]
	movq	mm1,[8+ebx]
	psllq	mm7,60
	movq	mm4,[ebx]
	por	mm0,mm7
	movq	[edi-72],mm2
	psrlq	mm2,4
	movq	[56+edi],mm5
	movq	mm6,mm5
	movq	[ebp-80],mm0
	psrlq	mm5,4
	movq	[48+ebp],mm3
	shl	edx,4
	mov	BYTE [8+esp],dl
	mov	edx,DWORD [24+ebx]
	movq	mm0,[24+ebx]
	psllq	mm6,60
	movq	mm3,[16+ebx]
	por	mm2,mm6
	movq	[edi-64],mm1
	psrlq	mm1,4
	movq	[64+edi],mm4
	movq	mm7,mm4
	movq	[ebp-72],mm2
	psrlq	mm4,4
	movq	[56+ebp],mm5
	shl	edx,4
	mov	BYTE [9+esp],dl
	mov	edx,DWORD [40+ebx]
	movq	mm2,[40+ebx]
	psllq	mm7,60
	movq	mm5,[32+ebx]
	por	mm1,mm7
	movq	[edi-56],mm0
	psrlq	mm0,4
	movq	[72+edi],mm3
	movq	mm6,mm3
	movq	[ebp-64],mm1
	psrlq	mm3,4
	movq	[64+ebp],mm4
	shl	edx,4
	mov	BYTE [10+esp],dl
	mov	edx,DWORD [56+ebx]
	movq	mm1,[56+ebx]
	psllq	mm6,60
	movq	mm4,[48+ebx]
	por	mm0,mm6
	movq	[edi-48],mm2
	psrlq	mm2,4
	movq	[80+edi],mm5
	movq	mm7,mm5
	movq	[ebp-56],mm0
	psrlq	mm5,4
	movq	[72+ebp],mm3
	shl	edx,4
	mov	BYTE [11+esp],dl
	mov	edx,DWORD [72+ebx]
	movq	mm0,[72+ebx]
	psllq	mm7,60
	movq	mm3,[64+ebx]
	por	mm2,mm7
	movq	[edi-40],mm1
	psrlq	mm1,4
	movq	[88+edi],mm4
	movq	mm6,mm4
	movq	[ebp-48],mm2
	psrlq	mm4,4
	movq	[80+ebp],mm5
	shl	edx,4
	mov	BYTE [12+esp],dl
	mov	edx,DWORD [88+ebx]
	movq	mm2,[88+ebx]
	psllq	mm6,60
	movq	mm5,[80+ebx]
	por	mm1,mm6
	movq	[edi-32],mm0
	psrlq	mm0,4
	movq	[96+edi],mm3
	movq	mm7,mm3
	movq	[ebp-40],mm1
	psrlq	mm3,4
	movq	[88+ebp],mm4
	shl	edx,4
	mov	BYTE [13+esp],dl
	mov	edx,DWORD [104+ebx]
	movq	mm1,[104+ebx]
	psllq	mm7,60
	movq	mm4,[96+ebx]
	por	mm0,mm7
	movq	[edi-24],mm2
	psrlq	mm2,4
	movq	[104+edi],mm5
	movq	mm6,mm5
	movq	[ebp-32],mm0
	psrlq	mm5,4
	movq	[96+ebp],mm3
	shl	edx,4
	mov	BYTE [14+esp],dl
	mov	edx,DWORD [120+ebx]
	movq	mm0,[120+ebx]
	psllq	mm6,60
	movq	mm3,[112+ebx]
	por	mm2,mm6
	movq	[edi-16],mm1
	psrlq	mm1,4
	movq	[112+edi],mm4
	movq	mm7,mm4
	movq	[ebp-24],mm2
	psrlq	mm4,4
	movq	[104+ebp],mm5
	shl	edx,4
	mov	BYTE [15+esp],dl
	psllq	mm7,60
	por	mm1,mm7
	movq	[edi-8],mm0
	psrlq	mm0,4
	movq	[120+edi],mm3
	movq	mm6,mm3
	movq	[ebp-16],mm1
	psrlq	mm3,4
	movq	[112+ebp],mm4
	psllq	mm6,60
	por	mm0,mm6
	movq	[ebp-8],mm0
	movq	[120+ebp],mm3
	movq	mm6,[eax]
	mov	ebx,DWORD [8+eax]
	mov	edx,DWORD [12+eax]
align	16
L$009outer:
	xor	edx,DWORD [12+ecx]
	xor	ebx,DWORD [8+ecx]
	pxor	mm6,[ecx]
	lea	ecx,[16+ecx]
	mov	DWORD [536+esp],ebx
	movq	[528+esp],mm6
	mov	DWORD [548+esp],ecx
	xor	eax,eax
	rol	edx,8
	mov	al,dl
	mov	ebp,eax
	and	al,15
	shr	ebp,4
	pxor	mm0,mm0
	rol	edx,8
	pxor	mm1,mm1
	pxor	mm2,mm2
	movq	mm7,[16+eax*8+esp]
	movq	mm6,[144+eax*8+esp]
	mov	al,dl
	movd	ebx,mm7
	psrlq	mm7,8
	movq	mm3,mm6
	mov	edi,eax
	psrlq	mm6,8
	pxor	mm7,[272+ebp*8+esp]
	and	al,15
	psllq	mm3,56
	shr	edi,4
	pxor	mm7,[16+eax*8+esp]
	rol	edx,8
	pxor	mm6,[144+eax*8+esp]
	pxor	mm7,mm3
	pxor	mm6,[400+ebp*8+esp]
	xor	bl,BYTE [ebp*1+esp]
	mov	al,dl
	movd	ecx,mm7
	movzx	ebx,bl
	psrlq	mm7,8
	movq	mm3,mm6
	mov	ebp,eax
	psrlq	mm6,8
	pxor	mm7,[272+edi*8+esp]
	and	al,15
	psllq	mm3,56
	shr	ebp,4
	pinsrw	mm2,WORD [ebx*2+esi],2
	pxor	mm7,[16+eax*8+esp]
	rol	edx,8
	pxor	mm6,[144+eax*8+esp]
	pxor	mm7,mm3
	pxor	mm6,[400+edi*8+esp]
	xor	cl,BYTE [edi*1+esp]
	mov	al,dl
	mov	edx,DWORD [536+esp]
	movd	ebx,mm7
	movzx	ecx,cl
	psrlq	mm7,8
	movq	mm3,mm6
	mov	edi,eax
	psrlq	mm6,8
	pxor	mm7,[272+ebp*8+esp]
	and	al,15
	psllq	mm3,56
	pxor	mm6,mm2
	shr	edi,4
	pinsrw	mm1,WORD [ecx*2+esi],2
	pxor	mm7,[16+eax*8+esp]
	rol	edx,8
	pxor	mm6,[144+eax*8+esp]
	pxor	mm7,mm3
	pxor	mm6,[400+ebp*8+esp]
	xor	bl,BYTE [ebp*1+esp]
	mov	al,dl
	movd	ecx,mm7
	movzx	ebx,bl
	psrlq	mm7,8
	movq	mm3,mm6
	mov	ebp,eax
	psrlq	mm6,8
	pxor	mm7,[272+edi*8+esp]
	and	al,15
	psllq	mm3,56
	pxor	mm6,mm1
	shr	ebp,4
	pinsrw	mm0,WORD [ebx*2+esi],2
	pxor	mm7,[16+eax*8+esp]
	rol	edx,8
	pxor	mm6,[144+eax*8+esp]
	pxor	mm7,mm3
	pxor	mm6,[400+edi*8+esp]
	xor	cl,BYTE [edi*1+esp]
	mov	al,dl
	movd	ebx,mm7
	movzx	ecx,cl
	psrlq	mm7,8
	movq	mm3,mm6
	mov	edi,eax
	psrlq	mm6,8
	pxor	mm7,[272+ebp*8+esp]
	and	al,15
	psllq	mm3,56
	pxor	mm6,mm0
	shr	edi,4
	pinsrw	mm2,WORD [ecx*2+esi],2
	pxor	mm7,[16+eax*8+esp]
	rol	edx,8
	pxor	mm6,[144+eax*8+esp]
	pxor	mm7,mm3
	pxor	mm6,[400+ebp*8+esp]
	xor	bl,BYTE [ebp*1+esp]
	mov	al,dl
	movd	ecx,mm7
	movzx	ebx,bl
	psrlq	mm7,8
	movq	mm3,mm6
	mov	ebp,eax
	psrlq	mm6,8
	pxor	mm7,[272+edi*8+esp]
	and	al,15
	psllq	mm3,56
	pxor	mm6,mm2
	shr	ebp,4
	pinsrw	mm1,WORD [ebx*2+esi],2
	pxor	mm7,[16+eax*8+esp]
	rol	edx,8
	pxor	mm6,[144+eax*8+esp]
	pxor	mm7,mm3
	pxor	mm6,[400+edi*8+esp]
	xor	cl,BYTE [edi*1+esp]
	mov	al,dl
	mov	edx,DWORD [532+esp]
	movd	ebx,mm7
	movzx	ecx,cl
	psrlq	mm7,8
	movq	mm3,mm6
	mov	edi,eax
	psrlq	mm6,8
	pxor	mm7,[272+ebp*8+esp]
	and	al,15
	psllq	mm3,56
	pxor	mm6,mm1
	shr	edi,4
	pinsrw	mm0,WORD [ecx*2+esi],2
	pxor	mm7,[16+eax*8+esp]
	rol	edx,8
	pxor	mm6,[144+eax*8+esp]
	pxor	mm7,mm3
	pxor	mm6,[400+ebp*8+esp]
	xor	bl,BYTE [ebp*1+esp]
	mov	al,dl
	movd	ecx,mm7
	movzx	ebx,bl
	psrlq	mm7,8
	movq	mm3,mm6
	mov	ebp,eax
	psrlq	mm6,8
	pxor	mm7,[272+edi*8+esp]
	and	al,15
	psllq	mm3,56
	pxor	mm6,mm0
	shr	ebp,4
	pinsrw	mm2,WORD [ebx*2+esi],2
	pxor	mm7,[16+eax*8+esp]
	rol	edx,8
	pxor	mm6,[144+eax*8+esp]
	pxor	mm7,mm3
	pxor	mm6,[400+edi*8+esp]
	xor	cl,BYTE [edi*1+esp]
	mov	al,dl
	movd	ebx,mm7
	movzx	ecx,cl
	psrlq	mm7,8
	movq	mm3,mm6
	mov	edi,eax
	psrlq	mm6,8
	pxor	mm7,[272+ebp*8+esp]
	and	al,15
	psllq	mm3,56
	pxor	mm6,mm2
	shr	edi,4
	pinsrw	mm1,WORD [ecx*2+esi],2
	pxor	mm7,[16+eax*8+esp]
	rol	edx,8
	pxor	mm6,[144+eax*8+esp]
	pxor	mm7,mm3
	pxor	mm6,[400+ebp*8+esp]
	xor	bl,BYTE [ebp*1+esp]
	mov	al,dl
	movd	ecx,mm7
	movzx	ebx,bl
	psrlq	mm7,8
	movq	mm3,mm6
	mov	ebp,eax
	psrlq	mm6,8
	pxor	mm7,[272+edi*8+esp]
	and	al,15
	psllq	mm3,56
	pxor	mm6,mm1
	shr	ebp,4
	pinsrw	mm0,WORD [ebx*2+esi],2
	pxor	mm7,[16+eax*8+esp]
	rol	edx,8
	pxor	mm6,[144+eax*8+esp]
	pxor	mm7,mm3
	pxor	mm6,[400+edi*8+esp]
	xor	cl,BYTE [edi*1+esp]
	mov	al,dl
	mov	edx,DWORD [528+esp]
	movd	ebx,mm7
	movzx	ecx,cl
	psrlq	mm7,8
	movq	mm3,mm6
	mov	edi,eax
	psrlq	mm6,8
	pxor	mm7,[272+ebp*8+esp]
	and	al,15
	psllq	mm3,56
	pxor	mm6,mm0
	shr	edi,4
	pinsrw	mm2,WORD [ecx*2+esi],2
	pxor	mm7,[16+eax*8+esp]
	rol	edx,8
	pxor	mm6,[144+eax*8+esp]
	pxor	mm7,mm3
	pxor	mm6,[400+ebp*8+esp]
	xor	bl,BYTE [ebp*1+esp]
	mov	al,dl
	movd	ecx,mm7
	movzx	ebx,bl
	psrlq	mm7,8
	movq	mm3,mm6
	mov	ebp,eax
	psrlq	mm6,8
	pxor	mm7,[272+edi*8+esp]
	and	al,15
	psllq	mm3,56
	pxor	mm6,mm2
	shr	ebp,4
	pinsrw	mm1,WORD [ebx*2+esi],2
	pxor	mm7,[16+eax*8+esp]
	rol	edx,8
	pxor	mm6,[144+eax*8+esp]
	pxor	mm7,mm3
	pxor	mm6,[400+edi*8+esp]
	xor	cl,BYTE [edi*1+esp]
	mov	al,dl
	movd	ebx,mm7
	movzx	ecx,cl
	psrlq	mm7,8
	movq	mm3,mm6
	mov	edi,eax
	psrlq	mm6,8
	pxor	mm7,[272+ebp*8+esp]
	and	al,15
	psllq	mm3,56
	pxor	mm6,mm1
	shr	edi,4
	pinsrw	mm0,WORD [ecx*2+esi],2
	pxor	mm7,[16+eax*8+esp]
	rol	edx,8
	pxor	mm6,[144+eax*8+esp]
	pxor	mm7,mm3
	pxor	mm6,[400+ebp*8+esp]
	xor	bl,BYTE [ebp*1+esp]
	mov	al,dl
	movd	ecx,mm7
	movzx	ebx,bl
	psrlq	mm7,8
	movq	mm3,mm6
	mov	ebp,eax
	psrlq	mm6,8
	pxor	mm7,[272+edi*8+esp]
	and	al,15
	psllq	mm3,56
	pxor	mm6,mm0
	shr	ebp,4
	pinsrw	mm2,WORD [ebx*2+esi],2
	pxor	mm7,[16+eax*8+esp]
	rol	edx,8
	pxor	mm6,[144+eax*8+esp]
	pxor	mm7,mm3
	pxor	mm6,[400+edi*8+esp]
	xor	cl,BYTE [edi*1+esp]
	mov	al,dl
	mov	edx,DWORD [524+esp]
	movd	ebx,mm7
	movzx	ecx,cl
	psrlq	mm7,8
	movq	mm3,mm6
	mov	edi,eax
	psrlq	mm6,8
	pxor	mm7,[272+ebp*8+esp]
	and	al,15
	psllq	mm3,56
	pxor	mm6,mm2
	shr	edi,4
	pinsrw	mm1,WORD [ecx*2+esi],2
	pxor	mm7,[16+eax*8+esp]
	pxor	mm6,[144+eax*8+esp]
	xor	bl,BYTE [ebp*1+esp]
	pxor	mm7,mm3
	pxor	mm6,[400+ebp*8+esp]
	movzx	ebx,bl
	pxor	mm2,mm2
	psllq	mm1,4
	movd	ecx,mm7
	psrlq	mm7,4
	movq	mm3,mm6
	psrlq	mm6,4
	shl	ecx,4
	pxor	mm7,[16+edi*8+esp]
	psllq	mm3,60
	movzx	ecx,cl
	pxor	mm7,mm3
	pxor	mm6,[144+edi*8+esp]
	pinsrw	mm0,WORD [ebx*2+esi],2
	pxor	mm6,mm1
	movd	edx,mm7
	pinsrw	mm2,WORD [ecx*2+esi],3
	psllq	mm0,12
	pxor	mm6,mm0
	psrlq	mm7,32
	pxor	mm6,mm2
	mov	ecx,DWORD [548+esp]
	movd	ebx,mm7
	movq	mm3,mm6
	psllw	mm6,8
	psrlw	mm3,8
	por	mm6,mm3
	bswap	edx
	pshufw	mm6,mm6,27
	bswap	ebx
	cmp	ecx,DWORD [552+esp]
	jne	NEAR L$009outer
	mov	eax,DWORD [544+esp]
	mov	DWORD [12+eax],edx
	mov	DWORD [8+eax],ebx
	movq	[eax],mm6
	mov	esp,DWORD [556+esp]
	emms
	pop	edi
	pop	esi
	pop	ebx
	pop	ebp
	ret
global	_gcm_init_clmul
align	16
_gcm_init_clmul:
L$_gcm_init_clmul_begin:
	mov	edx,DWORD [4+esp]
	mov	eax,DWORD [8+esp]
	call	L$010pic
L$010pic:
	pop	ecx
	lea	ecx,[(L$bswap-L$010pic)+ecx]
	movdqu	xmm2,[eax]
	pshufd	xmm2,xmm2,78
	pshufd	xmm4,xmm2,255
	movdqa	xmm3,xmm2
	psllq	xmm2,1
	pxor	xmm5,xmm5
	psrlq	xmm3,63
	pcmpgtd	xmm5,xmm4
	pslldq	xmm3,8
	por	xmm2,xmm3
	pand	xmm5,[16+ecx]
	pxor	xmm2,xmm5
	movdqa	xmm0,xmm2
	movdqa	xmm1,xmm0
	pshufd	xmm3,xmm0,78
	pshufd	xmm4,xmm2,78
	pxor	xmm3,xmm0
	pxor	xmm4,xmm2
db	102,15,58,68,194,0
db	102,15,58,68,202,17
db	102,15,58,68,220,0
	xorps	xmm3,xmm0
	xorps	xmm3,xmm1
	movdqa	xmm4,xmm3
	psrldq	xmm3,8
	pslldq	xmm4,8
	pxor	xmm1,xmm3
	pxor	xmm0,xmm4
	movdqa	xmm4,xmm0
	movdqa	xmm3,xmm0
	psllq	xmm0,5
	pxor	xmm3,xmm0
	psllq	xmm0,1
	pxor	xmm0,xmm3
	psllq	xmm0,57
	movdqa	xmm3,xmm0
	pslldq	xmm0,8
	psrldq	xmm3,8
	pxor	xmm0,xmm4
	pxor	xmm1,xmm3
	movdqa	xmm4,xmm0
	psrlq	xmm0,1
	pxor	xmm1,xmm4
	pxor	xmm4,xmm0
	psrlq	xmm0,5
	pxor	xmm0,xmm4
	psrlq	xmm0,1
	pxor	xmm0,xmm1
	pshufd	xmm3,xmm2,78
	pshufd	xmm4,xmm0,78
	pxor	xmm3,xmm2
	movdqu	[edx],xmm2
	pxor	xmm4,xmm0
	movdqu	[16+edx],xmm0
db	102,15,58,15,227,8
	movdqu	[32+edx],xmm4
	ret
global	_gcm_gmult_clmul
align	16
_gcm_gmult_clmul:
L$_gcm_gmult_clmul_begin:
	mov	eax,DWORD [4+esp]
	mov	edx,DWORD [8+esp]
	call	L$011pic
L$011pic:
	pop	ecx
	lea	ecx,[(L$bswap-L$011pic)+ecx]
	movdqu	xmm0,[eax]
	movdqa	xmm5,[ecx]
	movups	xmm2,[edx]
db	102,15,56,0,197
	movups	xmm4,[32+edx]
	movdqa	xmm1,xmm0
	pshufd	xmm3,xmm0,78
	pxor	xmm3,xmm0
db	102,15,58,68,194,0
db	102,15,58,68,202,17
db	102,15,58,68,220,0
	xorps	xmm3,xmm0
	xorps	xmm3,xmm1
	movdqa	xmm4,xmm3
	psrldq	xmm3,8
	pslldq	xmm4,8
	pxor	xmm1,xmm3
	pxor	xmm0,xmm4
	movdqa	xmm4,xmm0
	movdqa	xmm3,xmm0
	psllq	xmm0,5
	pxor	xmm3,xmm0
	psllq	xmm0,1
	pxor	xmm0,xmm3
	psllq	xmm0,57
	movdqa	xmm3,xmm0
	pslldq	xmm0,8
	psrldq	xmm3,8
	pxor	xmm0,xmm4
	pxor	xmm1,xmm3
	movdqa	xmm4,xmm0
	psrlq	xmm0,1
	pxor	xmm1,xmm4
	pxor	xmm4,xmm0
	psrlq	xmm0,5
	pxor	xmm0,xmm4
	psrlq	xmm0,1
	pxor	xmm0,xmm1
db	102,15,56,0,197
	movdqu	[eax],xmm0
	ret
global	_gcm_ghash_clmul
align	16
_gcm_ghash_clmul:
L$_gcm_ghash_clmul_begin:
	push	ebp
	push	ebx
	push	esi
	push	edi
	mov	eax,DWORD [20+esp]
	mov	edx,DWORD [24+esp]
	mov	esi,DWORD [28+esp]
	mov	ebx,DWORD [32+esp]
	call	L$012pic
L$012pic:
	pop	ecx
	lea	ecx,[(L$bswap-L$012pic)+ecx]
	movdqu	xmm0,[eax]
	movdqa	xmm5,[ecx]
	movdqu	xmm2,[edx]
db	102,15,56,0,197
	sub	ebx,16
	jz	NEAR L$013odd_tail
	movdqu	xmm3,[esi]
	movdqu	xmm6,[16+esi]
db	102,15,56,0,221
db	102,15,56,0,245
	movdqu	xmm5,[32+edx]
	pxor	xmm0,xmm3
	pshufd	xmm3,xmm6,78
	movdqa	xmm7,xmm6
	pxor	xmm3,xmm6
	lea	esi,[32+esi]
db	102,15,58,68,242,0
db	102,15,58,68,250,17
db	102,15,58,68,221,0
	movups	xmm2,[16+edx]
	nop
	sub	ebx,32
	jbe	NEAR L$014even_tail
	jmp	NEAR L$015mod_loop
align	32
L$015mod_loop:
	pshufd	xmm4,xmm0,78
	movdqa	xmm1,xmm0
	pxor	xmm4,xmm0
	nop
db	102,15,58,68,194,0
db	102,15,58,68,202,17
db	102,15,58,68,229,16
	movups	xmm2,[edx]
	xorps	xmm0,xmm6
	movdqa	xmm5,[ecx]
	xorps	xmm1,xmm7
	movdqu	xmm7,[esi]
	pxor	xmm3,xmm0
	movdqu	xmm6,[16+esi]
	pxor	xmm3,xmm1
db	102,15,56,0,253
	pxor	xmm4,xmm3
	movdqa	xmm3,xmm4
	psrldq	xmm4,8
	pslldq	xmm3,8
	pxor	xmm1,xmm4
	pxor	xmm0,xmm3
db	102,15,56,0,245
	pxor	xmm1,xmm7
	movdqa	xmm7,xmm6
	movdqa	xmm4,xmm0
	movdqa	xmm3,xmm0
	psllq	xmm0,5
	pxor	xmm3,xmm0
	psllq	xmm0,1
	pxor	xmm0,xmm3
db	102,15,58,68,242,0
	movups	xmm5,[32+edx]
	psllq	xmm0,57
	movdqa	xmm3,xmm0
	pslldq	xmm0,8
	psrldq	xmm3,8
	pxor	xmm0,xmm4
	pxor	xmm1,xmm3
	pshufd	xmm3,xmm7,78
	movdqa	xmm4,xmm0
	psrlq	xmm0,1
	pxor	xmm3,xmm7
	pxor	xmm1,xmm4
db	102,15,58,68,250,17
	movups	xmm2,[16+edx]
	pxor	xmm4,xmm0
	psrlq	xmm0,5
	pxor	xmm0,xmm4
	psrlq	xmm0,1
	pxor	xmm0,xmm1
db	102,15,58,68,221,0
	lea	esi,[32+esi]
	sub	ebx,32
	ja	NEAR L$015mod_loop
L$014even_tail:
	pshufd	xmm4,xmm0,78
	movdqa	xmm1,xmm0
	pxor	xmm4,xmm0
db	102,15,58,68,194,0
db	102,15,58,68,202,17
db	102,15,58,68,229,16
	movdqa	xmm5,[ecx]
	xorps	xmm0,xmm6
	xorps	xmm1,xmm7
	pxor	xmm3,xmm0
	pxor	xmm3,xmm1
	pxor	xmm4,xmm3
	movdqa	xmm3,xmm4
	psrldq	xmm4,8
	pslldq	xmm3,8
	pxor	xmm1,xmm4
	pxor	xmm0,xmm3
	movdqa	xmm4,xmm0
	movdqa	xmm3,xmm0
	psllq	xmm0,5
	pxor	xmm3,xmm0
	psllq	xmm0,1
	pxor	xmm0,xmm3
	psllq	xmm0,57
	movdqa	xmm3,xmm0
	pslldq	xmm0,8
	psrldq	xmm3,8
	pxor	xmm0,xmm4
	pxor	xmm1,xmm3
	movdqa	xmm4,xmm0
	psrlq	xmm0,1
	pxor	xmm1,xmm4
	pxor	xmm4,xmm0
	psrlq	xmm0,5
	pxor	xmm0,xmm4
	psrlq	xmm0,1
	pxor	xmm0,xmm1
	test	ebx,ebx
	jnz	NEAR L$016done
	movups	xmm2,[edx]
L$013odd_tail:
	movdqu	xmm3,[esi]
db	102,15,56,0,221
	pxor	xmm0,xmm3
	movdqa	xmm1,xmm0
	pshufd	xmm3,xmm0,78
	pshufd	xmm4,xmm2,78
	pxor	xmm3,xmm0
	pxor	xmm4,xmm2
db	102,15,58,68,194,0
db	102,15,58,68,202,17
db	102,15,58,68,220,0
	xorps	xmm3,xmm0
	xorps	xmm3,xmm1
	movdqa	xmm4,xmm3
	psrldq	xmm3,8
	pslldq	xmm4,8
	pxor	xmm1,xmm3
	pxor	xmm0,xmm4
	movdqa	xmm4,xmm0
	movdqa	xmm3,xmm0
	psllq	xmm0,5
	pxor	xmm3,xmm0
	psllq	xmm0,1
	pxor	xmm0,xmm3
	psllq	xmm0,57
	movdqa	xmm3,xmm0
	pslldq	xmm0,8
	psrldq	xmm3,8
	pxor	xmm0,xmm4
	pxor	xmm1,xmm3
	movdqa	xmm4,xmm0
	psrlq	xmm0,1
	pxor	xmm1,xmm4
	pxor	xmm4,xmm0
	psrlq	xmm0,5
	pxor	xmm0,xmm4
	psrlq	xmm0,1
	pxor	xmm0,xmm1
L$016done:
db	102,15,56,0,197
	movdqu	[eax],xmm0
	pop	edi
	pop	esi
	pop	ebx
	pop	ebp
	ret
align	64
L$bswap:
db	15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,0
db	1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,194
align	64
L$rem_8bit:
dw	0,450,900,582,1800,1738,1164,1358
dw	3600,4050,3476,3158,2328,2266,2716,2910
dw	7200,7650,8100,7782,6952,6890,6316,6510
dw	4656,5106,4532,4214,5432,5370,5820,6014
dw	14400,14722,15300,14854,16200,16010,15564,15630
dw	13904,14226,13780,13334,12632,12442,13020,13086
dw	9312,9634,10212,9766,9064,8874,8428,8494
dw	10864,11186,10740,10294,11640,11450,12028,12094
dw	28800,28994,29444,29382,30600,30282,29708,30158
dw	32400,32594,32020,31958,31128,30810,31260,31710
dw	27808,28002,28452,28390,27560,27242,26668,27118
dw	25264,25458,24884,24822,26040,25722,26172,26622
dw	18624,18690,19268,19078,20424,19978,19532,19854
dw	18128,18194,17748,17558,16856,16410,16988,17310
dw	21728,21794,22372,22182,21480,21034,20588,20910
dw	23280,23346,22900,22710,24056,23610,24188,24510
dw	57600,57538,57988,58182,58888,59338,58764,58446
dw	61200,61138,60564,60758,59416,59866,60316,59998
dw	64800,64738,65188,65382,64040,64490,63916,63598
dw	62256,62194,61620,61814,62520,62970,63420,63102
dw	55616,55426,56004,56070,56904,57226,56780,56334
dw	55120,54930,54484,54550,53336,53658,54236,53790
dw	50528,50338,50916,50982,49768,50090,49644,49198
dw	52080,51890,51444,51510,52344,52666,53244,52798
dw	37248,36930,37380,37830,38536,38730,38156,38094
dw	40848,40530,39956,40406,39064,39258,39708,39646
dw	36256,35938,36388,36838,35496,35690,35116,35054
dw	33712,33394,32820,33270,33976,34170,34620,34558
dw	43456,43010,43588,43910,44744,44810,44364,44174
dw	42960,42514,42068,42390,41176,41242,41820,41630
dw	46560,46114,46692,47014,45800,45866,45420,45230
dw	48112,47666,47220,47542,48376,48442,49020,48830
align	64
L$rem_4bit:
dd	0,0,0,471859200,0,943718400,0,610271232
dd	0,1887436800,0,1822425088,0,1220542464,0,1423966208
dd	0,3774873600,0,4246732800,0,3644850176,0,3311403008
dd	0,2441084928,0,2376073216,0,2847932416,0,3051356160
db	71,72,65,83,72,32,102,111,114,32,120,56,54,44,32,67
db	82,89,80,84,79,71,65,77,83,32,98,121,32,60,97,112
db	112,114,111,64,111,112,101,110,115,115,108,46,111,114,103,62
db	0
