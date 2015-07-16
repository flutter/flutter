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
global	_sha256_block_data_order
align	16
_sha256_block_data_order:
L$_sha256_block_data_order_begin:
	push	ebp
	push	ebx
	push	esi
	push	edi
	mov	esi,DWORD [20+esp]
	mov	edi,DWORD [24+esp]
	mov	eax,DWORD [28+esp]
	mov	ebx,esp
	call	L$000pic_point
L$000pic_point:
	pop	ebp
	lea	ebp,[(L$001K256-L$000pic_point)+ebp]
	sub	esp,16
	and	esp,-64
	shl	eax,6
	add	eax,edi
	mov	DWORD [esp],esi
	mov	DWORD [4+esp],edi
	mov	DWORD [8+esp],eax
	mov	DWORD [12+esp],ebx
	jmp	NEAR L$002loop
align	16
L$002loop:
	mov	eax,DWORD [edi]
	mov	ebx,DWORD [4+edi]
	mov	ecx,DWORD [8+edi]
	bswap	eax
	mov	edx,DWORD [12+edi]
	bswap	ebx
	push	eax
	bswap	ecx
	push	ebx
	bswap	edx
	push	ecx
	push	edx
	mov	eax,DWORD [16+edi]
	mov	ebx,DWORD [20+edi]
	mov	ecx,DWORD [24+edi]
	bswap	eax
	mov	edx,DWORD [28+edi]
	bswap	ebx
	push	eax
	bswap	ecx
	push	ebx
	bswap	edx
	push	ecx
	push	edx
	mov	eax,DWORD [32+edi]
	mov	ebx,DWORD [36+edi]
	mov	ecx,DWORD [40+edi]
	bswap	eax
	mov	edx,DWORD [44+edi]
	bswap	ebx
	push	eax
	bswap	ecx
	push	ebx
	bswap	edx
	push	ecx
	push	edx
	mov	eax,DWORD [48+edi]
	mov	ebx,DWORD [52+edi]
	mov	ecx,DWORD [56+edi]
	bswap	eax
	mov	edx,DWORD [60+edi]
	bswap	ebx
	push	eax
	bswap	ecx
	push	ebx
	bswap	edx
	push	ecx
	push	edx
	add	edi,64
	lea	esp,[esp-36]
	mov	DWORD [104+esp],edi
	mov	eax,DWORD [esi]
	mov	ebx,DWORD [4+esi]
	mov	ecx,DWORD [8+esi]
	mov	edi,DWORD [12+esi]
	mov	DWORD [8+esp],ebx
	xor	ebx,ecx
	mov	DWORD [12+esp],ecx
	mov	DWORD [16+esp],edi
	mov	DWORD [esp],ebx
	mov	edx,DWORD [16+esi]
	mov	ebx,DWORD [20+esi]
	mov	ecx,DWORD [24+esi]
	mov	edi,DWORD [28+esi]
	mov	DWORD [24+esp],ebx
	mov	DWORD [28+esp],ecx
	mov	DWORD [32+esp],edi
align	16
L$00300_15:
	mov	ecx,edx
	mov	esi,DWORD [24+esp]
	ror	ecx,14
	mov	edi,DWORD [28+esp]
	xor	ecx,edx
	xor	esi,edi
	mov	ebx,DWORD [96+esp]
	ror	ecx,5
	and	esi,edx
	mov	DWORD [20+esp],edx
	xor	edx,ecx
	add	ebx,DWORD [32+esp]
	xor	esi,edi
	ror	edx,6
	mov	ecx,eax
	add	ebx,esi
	ror	ecx,9
	add	ebx,edx
	mov	edi,DWORD [8+esp]
	xor	ecx,eax
	mov	DWORD [4+esp],eax
	lea	esp,[esp-4]
	ror	ecx,11
	mov	esi,DWORD [ebp]
	xor	ecx,eax
	mov	edx,DWORD [20+esp]
	xor	eax,edi
	ror	ecx,2
	add	ebx,esi
	mov	DWORD [esp],eax
	add	edx,ebx
	and	eax,DWORD [4+esp]
	add	ebx,ecx
	xor	eax,edi
	add	ebp,4
	add	eax,ebx
	cmp	esi,3248222580
	jne	NEAR L$00300_15
	mov	ecx,DWORD [156+esp]
	jmp	NEAR L$00416_63
align	16
L$00416_63:
	mov	ebx,ecx
	mov	esi,DWORD [104+esp]
	ror	ecx,11
	mov	edi,esi
	ror	esi,2
	xor	ecx,ebx
	shr	ebx,3
	ror	ecx,7
	xor	esi,edi
	xor	ebx,ecx
	ror	esi,17
	add	ebx,DWORD [160+esp]
	shr	edi,10
	add	ebx,DWORD [124+esp]
	mov	ecx,edx
	xor	edi,esi
	mov	esi,DWORD [24+esp]
	ror	ecx,14
	add	ebx,edi
	mov	edi,DWORD [28+esp]
	xor	ecx,edx
	xor	esi,edi
	mov	DWORD [96+esp],ebx
	ror	ecx,5
	and	esi,edx
	mov	DWORD [20+esp],edx
	xor	edx,ecx
	add	ebx,DWORD [32+esp]
	xor	esi,edi
	ror	edx,6
	mov	ecx,eax
	add	ebx,esi
	ror	ecx,9
	add	ebx,edx
	mov	edi,DWORD [8+esp]
	xor	ecx,eax
	mov	DWORD [4+esp],eax
	lea	esp,[esp-4]
	ror	ecx,11
	mov	esi,DWORD [ebp]
	xor	ecx,eax
	mov	edx,DWORD [20+esp]
	xor	eax,edi
	ror	ecx,2
	add	ebx,esi
	mov	DWORD [esp],eax
	add	edx,ebx
	and	eax,DWORD [4+esp]
	add	ebx,ecx
	xor	eax,edi
	mov	ecx,DWORD [156+esp]
	add	ebp,4
	add	eax,ebx
	cmp	esi,3329325298
	jne	NEAR L$00416_63
	mov	esi,DWORD [356+esp]
	mov	ebx,DWORD [8+esp]
	mov	ecx,DWORD [16+esp]
	add	eax,DWORD [esi]
	add	ebx,DWORD [4+esi]
	add	edi,DWORD [8+esi]
	add	ecx,DWORD [12+esi]
	mov	DWORD [esi],eax
	mov	DWORD [4+esi],ebx
	mov	DWORD [8+esi],edi
	mov	DWORD [12+esi],ecx
	mov	eax,DWORD [24+esp]
	mov	ebx,DWORD [28+esp]
	mov	ecx,DWORD [32+esp]
	mov	edi,DWORD [360+esp]
	add	edx,DWORD [16+esi]
	add	eax,DWORD [20+esi]
	add	ebx,DWORD [24+esi]
	add	ecx,DWORD [28+esi]
	mov	DWORD [16+esi],edx
	mov	DWORD [20+esi],eax
	mov	DWORD [24+esi],ebx
	mov	DWORD [28+esi],ecx
	lea	esp,[356+esp]
	sub	ebp,256
	cmp	edi,DWORD [8+esp]
	jb	NEAR L$002loop
	mov	esp,DWORD [12+esp]
	pop	edi
	pop	esi
	pop	ebx
	pop	ebp
	ret
align	32
L$005loop_shrd:
	mov	eax,DWORD [edi]
	mov	ebx,DWORD [4+edi]
	mov	ecx,DWORD [8+edi]
	bswap	eax
	mov	edx,DWORD [12+edi]
	bswap	ebx
	push	eax
	bswap	ecx
	push	ebx
	bswap	edx
	push	ecx
	push	edx
	mov	eax,DWORD [16+edi]
	mov	ebx,DWORD [20+edi]
	mov	ecx,DWORD [24+edi]
	bswap	eax
	mov	edx,DWORD [28+edi]
	bswap	ebx
	push	eax
	bswap	ecx
	push	ebx
	bswap	edx
	push	ecx
	push	edx
	mov	eax,DWORD [32+edi]
	mov	ebx,DWORD [36+edi]
	mov	ecx,DWORD [40+edi]
	bswap	eax
	mov	edx,DWORD [44+edi]
	bswap	ebx
	push	eax
	bswap	ecx
	push	ebx
	bswap	edx
	push	ecx
	push	edx
	mov	eax,DWORD [48+edi]
	mov	ebx,DWORD [52+edi]
	mov	ecx,DWORD [56+edi]
	bswap	eax
	mov	edx,DWORD [60+edi]
	bswap	ebx
	push	eax
	bswap	ecx
	push	ebx
	bswap	edx
	push	ecx
	push	edx
	add	edi,64
	lea	esp,[esp-36]
	mov	DWORD [104+esp],edi
	mov	eax,DWORD [esi]
	mov	ebx,DWORD [4+esi]
	mov	ecx,DWORD [8+esi]
	mov	edi,DWORD [12+esi]
	mov	DWORD [8+esp],ebx
	xor	ebx,ecx
	mov	DWORD [12+esp],ecx
	mov	DWORD [16+esp],edi
	mov	DWORD [esp],ebx
	mov	edx,DWORD [16+esi]
	mov	ebx,DWORD [20+esi]
	mov	ecx,DWORD [24+esi]
	mov	edi,DWORD [28+esi]
	mov	DWORD [24+esp],ebx
	mov	DWORD [28+esp],ecx
	mov	DWORD [32+esp],edi
align	16
L$00600_15_shrd:
	mov	ecx,edx
	mov	esi,DWORD [24+esp]
	shrd	ecx,ecx,14
	mov	edi,DWORD [28+esp]
	xor	ecx,edx
	xor	esi,edi
	mov	ebx,DWORD [96+esp]
	shrd	ecx,ecx,5
	and	esi,edx
	mov	DWORD [20+esp],edx
	xor	edx,ecx
	add	ebx,DWORD [32+esp]
	xor	esi,edi
	shrd	edx,edx,6
	mov	ecx,eax
	add	ebx,esi
	shrd	ecx,ecx,9
	add	ebx,edx
	mov	edi,DWORD [8+esp]
	xor	ecx,eax
	mov	DWORD [4+esp],eax
	lea	esp,[esp-4]
	shrd	ecx,ecx,11
	mov	esi,DWORD [ebp]
	xor	ecx,eax
	mov	edx,DWORD [20+esp]
	xor	eax,edi
	shrd	ecx,ecx,2
	add	ebx,esi
	mov	DWORD [esp],eax
	add	edx,ebx
	and	eax,DWORD [4+esp]
	add	ebx,ecx
	xor	eax,edi
	add	ebp,4
	add	eax,ebx
	cmp	esi,3248222580
	jne	NEAR L$00600_15_shrd
	mov	ecx,DWORD [156+esp]
	jmp	NEAR L$00716_63_shrd
align	16
L$00716_63_shrd:
	mov	ebx,ecx
	mov	esi,DWORD [104+esp]
	shrd	ecx,ecx,11
	mov	edi,esi
	shrd	esi,esi,2
	xor	ecx,ebx
	shr	ebx,3
	shrd	ecx,ecx,7
	xor	esi,edi
	xor	ebx,ecx
	shrd	esi,esi,17
	add	ebx,DWORD [160+esp]
	shr	edi,10
	add	ebx,DWORD [124+esp]
	mov	ecx,edx
	xor	edi,esi
	mov	esi,DWORD [24+esp]
	shrd	ecx,ecx,14
	add	ebx,edi
	mov	edi,DWORD [28+esp]
	xor	ecx,edx
	xor	esi,edi
	mov	DWORD [96+esp],ebx
	shrd	ecx,ecx,5
	and	esi,edx
	mov	DWORD [20+esp],edx
	xor	edx,ecx
	add	ebx,DWORD [32+esp]
	xor	esi,edi
	shrd	edx,edx,6
	mov	ecx,eax
	add	ebx,esi
	shrd	ecx,ecx,9
	add	ebx,edx
	mov	edi,DWORD [8+esp]
	xor	ecx,eax
	mov	DWORD [4+esp],eax
	lea	esp,[esp-4]
	shrd	ecx,ecx,11
	mov	esi,DWORD [ebp]
	xor	ecx,eax
	mov	edx,DWORD [20+esp]
	xor	eax,edi
	shrd	ecx,ecx,2
	add	ebx,esi
	mov	DWORD [esp],eax
	add	edx,ebx
	and	eax,DWORD [4+esp]
	add	ebx,ecx
	xor	eax,edi
	mov	ecx,DWORD [156+esp]
	add	ebp,4
	add	eax,ebx
	cmp	esi,3329325298
	jne	NEAR L$00716_63_shrd
	mov	esi,DWORD [356+esp]
	mov	ebx,DWORD [8+esp]
	mov	ecx,DWORD [16+esp]
	add	eax,DWORD [esi]
	add	ebx,DWORD [4+esi]
	add	edi,DWORD [8+esi]
	add	ecx,DWORD [12+esi]
	mov	DWORD [esi],eax
	mov	DWORD [4+esi],ebx
	mov	DWORD [8+esi],edi
	mov	DWORD [12+esi],ecx
	mov	eax,DWORD [24+esp]
	mov	ebx,DWORD [28+esp]
	mov	ecx,DWORD [32+esp]
	mov	edi,DWORD [360+esp]
	add	edx,DWORD [16+esi]
	add	eax,DWORD [20+esi]
	add	ebx,DWORD [24+esi]
	add	ecx,DWORD [28+esi]
	mov	DWORD [16+esi],edx
	mov	DWORD [20+esi],eax
	mov	DWORD [24+esi],ebx
	mov	DWORD [28+esi],ecx
	lea	esp,[356+esp]
	sub	ebp,256
	cmp	edi,DWORD [8+esp]
	jb	NEAR L$005loop_shrd
	mov	esp,DWORD [12+esp]
	pop	edi
	pop	esi
	pop	ebx
	pop	ebp
	ret
align	64
L$001K256:
dd	1116352408,1899447441,3049323471,3921009573,961987163,1508970993,2453635748,2870763221,3624381080,310598401,607225278,1426881987,1925078388,2162078206,2614888103,3248222580,3835390401,4022224774,264347078,604807628,770255983,1249150122,1555081692,1996064986,2554220882,2821834349,2952996808,3210313671,3336571891,3584528711,113926993,338241895,666307205,773529912,1294757372,1396182291,1695183700,1986661051,2177026350,2456956037,2730485921,2820302411,3259730800,3345764771,3516065817,3600352804,4094571909,275423344,430227734,506948616,659060556,883997877,958139571,1322822218,1537002063,1747873779,1955562222,2024104815,2227730452,2361852424,2428436474,2756734187,3204031479,3329325298
dd	66051,67438087,134810123,202182159
db	83,72,65,50,53,54,32,98,108,111,99,107,32,116,114,97
db	110,115,102,111,114,109,32,102,111,114,32,120,56,54,44,32
db	67,82,89,80,84,79,71,65,77,83,32,98,121,32,60,97
db	112,112,114,111,64,111,112,101,110,115,115,108,46,111,114,103
db	62,0
align	16
L$008unrolled:
	lea	esp,[esp-96]
	mov	eax,DWORD [esi]
	mov	ebp,DWORD [4+esi]
	mov	ecx,DWORD [8+esi]
	mov	ebx,DWORD [12+esi]
	mov	DWORD [4+esp],ebp
	xor	ebp,ecx
	mov	DWORD [8+esp],ecx
	mov	DWORD [12+esp],ebx
	mov	edx,DWORD [16+esi]
	mov	ebx,DWORD [20+esi]
	mov	ecx,DWORD [24+esi]
	mov	esi,DWORD [28+esi]
	mov	DWORD [20+esp],ebx
	mov	DWORD [24+esp],ecx
	mov	DWORD [28+esp],esi
	jmp	NEAR L$009grand_loop
align	16
L$009grand_loop:
	mov	ebx,DWORD [edi]
	mov	ecx,DWORD [4+edi]
	bswap	ebx
	mov	esi,DWORD [8+edi]
	bswap	ecx
	mov	DWORD [32+esp],ebx
	bswap	esi
	mov	DWORD [36+esp],ecx
	mov	DWORD [40+esp],esi
	mov	ebx,DWORD [12+edi]
	mov	ecx,DWORD [16+edi]
	bswap	ebx
	mov	esi,DWORD [20+edi]
	bswap	ecx
	mov	DWORD [44+esp],ebx
	bswap	esi
	mov	DWORD [48+esp],ecx
	mov	DWORD [52+esp],esi
	mov	ebx,DWORD [24+edi]
	mov	ecx,DWORD [28+edi]
	bswap	ebx
	mov	esi,DWORD [32+edi]
	bswap	ecx
	mov	DWORD [56+esp],ebx
	bswap	esi
	mov	DWORD [60+esp],ecx
	mov	DWORD [64+esp],esi
	mov	ebx,DWORD [36+edi]
	mov	ecx,DWORD [40+edi]
	bswap	ebx
	mov	esi,DWORD [44+edi]
	bswap	ecx
	mov	DWORD [68+esp],ebx
	bswap	esi
	mov	DWORD [72+esp],ecx
	mov	DWORD [76+esp],esi
	mov	ebx,DWORD [48+edi]
	mov	ecx,DWORD [52+edi]
	bswap	ebx
	mov	esi,DWORD [56+edi]
	bswap	ecx
	mov	DWORD [80+esp],ebx
	bswap	esi
	mov	DWORD [84+esp],ecx
	mov	DWORD [88+esp],esi
	mov	ebx,DWORD [60+edi]
	add	edi,64
	bswap	ebx
	mov	DWORD [100+esp],edi
	mov	DWORD [92+esp],ebx
	mov	ecx,edx
	mov	esi,DWORD [20+esp]
	ror	edx,14
	mov	edi,DWORD [24+esp]
	xor	edx,ecx
	mov	ebx,DWORD [32+esp]
	xor	esi,edi
	ror	edx,5
	and	esi,ecx
	mov	DWORD [16+esp],ecx
	xor	edx,ecx
	add	ebx,DWORD [28+esp]
	xor	edi,esi
	ror	edx,6
	mov	ecx,eax
	add	ebx,edi
	ror	ecx,9
	mov	esi,eax
	mov	edi,DWORD [4+esp]
	xor	ecx,eax
	mov	DWORD [esp],eax
	xor	eax,edi
	ror	ecx,11
	and	ebp,eax
	lea	edx,[1116352408+edx*1+ebx]
	xor	ecx,esi
	xor	ebp,edi
	ror	ecx,2
	add	ebp,edx
	add	edx,DWORD [12+esp]
	add	ebp,ecx
	mov	esi,edx
	mov	ecx,DWORD [16+esp]
	ror	edx,14
	mov	edi,DWORD [20+esp]
	xor	edx,esi
	mov	ebx,DWORD [36+esp]
	xor	ecx,edi
	ror	edx,5
	and	ecx,esi
	mov	DWORD [12+esp],esi
	xor	edx,esi
	add	ebx,DWORD [24+esp]
	xor	edi,ecx
	ror	edx,6
	mov	esi,ebp
	add	ebx,edi
	ror	esi,9
	mov	ecx,ebp
	mov	edi,DWORD [esp]
	xor	esi,ebp
	mov	DWORD [28+esp],ebp
	xor	ebp,edi
	ror	esi,11
	and	eax,ebp
	lea	edx,[1899447441+edx*1+ebx]
	xor	esi,ecx
	xor	eax,edi
	ror	esi,2
	add	eax,edx
	add	edx,DWORD [8+esp]
	add	eax,esi
	mov	ecx,edx
	mov	esi,DWORD [12+esp]
	ror	edx,14
	mov	edi,DWORD [16+esp]
	xor	edx,ecx
	mov	ebx,DWORD [40+esp]
	xor	esi,edi
	ror	edx,5
	and	esi,ecx
	mov	DWORD [8+esp],ecx
	xor	edx,ecx
	add	ebx,DWORD [20+esp]
	xor	edi,esi
	ror	edx,6
	mov	ecx,eax
	add	ebx,edi
	ror	ecx,9
	mov	esi,eax
	mov	edi,DWORD [28+esp]
	xor	ecx,eax
	mov	DWORD [24+esp],eax
	xor	eax,edi
	ror	ecx,11
	and	ebp,eax
	lea	edx,[3049323471+edx*1+ebx]
	xor	ecx,esi
	xor	ebp,edi
	ror	ecx,2
	add	ebp,edx
	add	edx,DWORD [4+esp]
	add	ebp,ecx
	mov	esi,edx
	mov	ecx,DWORD [8+esp]
	ror	edx,14
	mov	edi,DWORD [12+esp]
	xor	edx,esi
	mov	ebx,DWORD [44+esp]
	xor	ecx,edi
	ror	edx,5
	and	ecx,esi
	mov	DWORD [4+esp],esi
	xor	edx,esi
	add	ebx,DWORD [16+esp]
	xor	edi,ecx
	ror	edx,6
	mov	esi,ebp
	add	ebx,edi
	ror	esi,9
	mov	ecx,ebp
	mov	edi,DWORD [24+esp]
	xor	esi,ebp
	mov	DWORD [20+esp],ebp
	xor	ebp,edi
	ror	esi,11
	and	eax,ebp
	lea	edx,[3921009573+edx*1+ebx]
	xor	esi,ecx
	xor	eax,edi
	ror	esi,2
	add	eax,edx
	add	edx,DWORD [esp]
	add	eax,esi
	mov	ecx,edx
	mov	esi,DWORD [4+esp]
	ror	edx,14
	mov	edi,DWORD [8+esp]
	xor	edx,ecx
	mov	ebx,DWORD [48+esp]
	xor	esi,edi
	ror	edx,5
	and	esi,ecx
	mov	DWORD [esp],ecx
	xor	edx,ecx
	add	ebx,DWORD [12+esp]
	xor	edi,esi
	ror	edx,6
	mov	ecx,eax
	add	ebx,edi
	ror	ecx,9
	mov	esi,eax
	mov	edi,DWORD [20+esp]
	xor	ecx,eax
	mov	DWORD [16+esp],eax
	xor	eax,edi
	ror	ecx,11
	and	ebp,eax
	lea	edx,[961987163+edx*1+ebx]
	xor	ecx,esi
	xor	ebp,edi
	ror	ecx,2
	add	ebp,edx
	add	edx,DWORD [28+esp]
	add	ebp,ecx
	mov	esi,edx
	mov	ecx,DWORD [esp]
	ror	edx,14
	mov	edi,DWORD [4+esp]
	xor	edx,esi
	mov	ebx,DWORD [52+esp]
	xor	ecx,edi
	ror	edx,5
	and	ecx,esi
	mov	DWORD [28+esp],esi
	xor	edx,esi
	add	ebx,DWORD [8+esp]
	xor	edi,ecx
	ror	edx,6
	mov	esi,ebp
	add	ebx,edi
	ror	esi,9
	mov	ecx,ebp
	mov	edi,DWORD [16+esp]
	xor	esi,ebp
	mov	DWORD [12+esp],ebp
	xor	ebp,edi
	ror	esi,11
	and	eax,ebp
	lea	edx,[1508970993+edx*1+ebx]
	xor	esi,ecx
	xor	eax,edi
	ror	esi,2
	add	eax,edx
	add	edx,DWORD [24+esp]
	add	eax,esi
	mov	ecx,edx
	mov	esi,DWORD [28+esp]
	ror	edx,14
	mov	edi,DWORD [esp]
	xor	edx,ecx
	mov	ebx,DWORD [56+esp]
	xor	esi,edi
	ror	edx,5
	and	esi,ecx
	mov	DWORD [24+esp],ecx
	xor	edx,ecx
	add	ebx,DWORD [4+esp]
	xor	edi,esi
	ror	edx,6
	mov	ecx,eax
	add	ebx,edi
	ror	ecx,9
	mov	esi,eax
	mov	edi,DWORD [12+esp]
	xor	ecx,eax
	mov	DWORD [8+esp],eax
	xor	eax,edi
	ror	ecx,11
	and	ebp,eax
	lea	edx,[2453635748+edx*1+ebx]
	xor	ecx,esi
	xor	ebp,edi
	ror	ecx,2
	add	ebp,edx
	add	edx,DWORD [20+esp]
	add	ebp,ecx
	mov	esi,edx
	mov	ecx,DWORD [24+esp]
	ror	edx,14
	mov	edi,DWORD [28+esp]
	xor	edx,esi
	mov	ebx,DWORD [60+esp]
	xor	ecx,edi
	ror	edx,5
	and	ecx,esi
	mov	DWORD [20+esp],esi
	xor	edx,esi
	add	ebx,DWORD [esp]
	xor	edi,ecx
	ror	edx,6
	mov	esi,ebp
	add	ebx,edi
	ror	esi,9
	mov	ecx,ebp
	mov	edi,DWORD [8+esp]
	xor	esi,ebp
	mov	DWORD [4+esp],ebp
	xor	ebp,edi
	ror	esi,11
	and	eax,ebp
	lea	edx,[2870763221+edx*1+ebx]
	xor	esi,ecx
	xor	eax,edi
	ror	esi,2
	add	eax,edx
	add	edx,DWORD [16+esp]
	add	eax,esi
	mov	ecx,edx
	mov	esi,DWORD [20+esp]
	ror	edx,14
	mov	edi,DWORD [24+esp]
	xor	edx,ecx
	mov	ebx,DWORD [64+esp]
	xor	esi,edi
	ror	edx,5
	and	esi,ecx
	mov	DWORD [16+esp],ecx
	xor	edx,ecx
	add	ebx,DWORD [28+esp]
	xor	edi,esi
	ror	edx,6
	mov	ecx,eax
	add	ebx,edi
	ror	ecx,9
	mov	esi,eax
	mov	edi,DWORD [4+esp]
	xor	ecx,eax
	mov	DWORD [esp],eax
	xor	eax,edi
	ror	ecx,11
	and	ebp,eax
	lea	edx,[3624381080+edx*1+ebx]
	xor	ecx,esi
	xor	ebp,edi
	ror	ecx,2
	add	ebp,edx
	add	edx,DWORD [12+esp]
	add	ebp,ecx
	mov	esi,edx
	mov	ecx,DWORD [16+esp]
	ror	edx,14
	mov	edi,DWORD [20+esp]
	xor	edx,esi
	mov	ebx,DWORD [68+esp]
	xor	ecx,edi
	ror	edx,5
	and	ecx,esi
	mov	DWORD [12+esp],esi
	xor	edx,esi
	add	ebx,DWORD [24+esp]
	xor	edi,ecx
	ror	edx,6
	mov	esi,ebp
	add	ebx,edi
	ror	esi,9
	mov	ecx,ebp
	mov	edi,DWORD [esp]
	xor	esi,ebp
	mov	DWORD [28+esp],ebp
	xor	ebp,edi
	ror	esi,11
	and	eax,ebp
	lea	edx,[310598401+edx*1+ebx]
	xor	esi,ecx
	xor	eax,edi
	ror	esi,2
	add	eax,edx
	add	edx,DWORD [8+esp]
	add	eax,esi
	mov	ecx,edx
	mov	esi,DWORD [12+esp]
	ror	edx,14
	mov	edi,DWORD [16+esp]
	xor	edx,ecx
	mov	ebx,DWORD [72+esp]
	xor	esi,edi
	ror	edx,5
	and	esi,ecx
	mov	DWORD [8+esp],ecx
	xor	edx,ecx
	add	ebx,DWORD [20+esp]
	xor	edi,esi
	ror	edx,6
	mov	ecx,eax
	add	ebx,edi
	ror	ecx,9
	mov	esi,eax
	mov	edi,DWORD [28+esp]
	xor	ecx,eax
	mov	DWORD [24+esp],eax
	xor	eax,edi
	ror	ecx,11
	and	ebp,eax
	lea	edx,[607225278+edx*1+ebx]
	xor	ecx,esi
	xor	ebp,edi
	ror	ecx,2
	add	ebp,edx
	add	edx,DWORD [4+esp]
	add	ebp,ecx
	mov	esi,edx
	mov	ecx,DWORD [8+esp]
	ror	edx,14
	mov	edi,DWORD [12+esp]
	xor	edx,esi
	mov	ebx,DWORD [76+esp]
	xor	ecx,edi
	ror	edx,5
	and	ecx,esi
	mov	DWORD [4+esp],esi
	xor	edx,esi
	add	ebx,DWORD [16+esp]
	xor	edi,ecx
	ror	edx,6
	mov	esi,ebp
	add	ebx,edi
	ror	esi,9
	mov	ecx,ebp
	mov	edi,DWORD [24+esp]
	xor	esi,ebp
	mov	DWORD [20+esp],ebp
	xor	ebp,edi
	ror	esi,11
	and	eax,ebp
	lea	edx,[1426881987+edx*1+ebx]
	xor	esi,ecx
	xor	eax,edi
	ror	esi,2
	add	eax,edx
	add	edx,DWORD [esp]
	add	eax,esi
	mov	ecx,edx
	mov	esi,DWORD [4+esp]
	ror	edx,14
	mov	edi,DWORD [8+esp]
	xor	edx,ecx
	mov	ebx,DWORD [80+esp]
	xor	esi,edi
	ror	edx,5
	and	esi,ecx
	mov	DWORD [esp],ecx
	xor	edx,ecx
	add	ebx,DWORD [12+esp]
	xor	edi,esi
	ror	edx,6
	mov	ecx,eax
	add	ebx,edi
	ror	ecx,9
	mov	esi,eax
	mov	edi,DWORD [20+esp]
	xor	ecx,eax
	mov	DWORD [16+esp],eax
	xor	eax,edi
	ror	ecx,11
	and	ebp,eax
	lea	edx,[1925078388+edx*1+ebx]
	xor	ecx,esi
	xor	ebp,edi
	ror	ecx,2
	add	ebp,edx
	add	edx,DWORD [28+esp]
	add	ebp,ecx
	mov	esi,edx
	mov	ecx,DWORD [esp]
	ror	edx,14
	mov	edi,DWORD [4+esp]
	xor	edx,esi
	mov	ebx,DWORD [84+esp]
	xor	ecx,edi
	ror	edx,5
	and	ecx,esi
	mov	DWORD [28+esp],esi
	xor	edx,esi
	add	ebx,DWORD [8+esp]
	xor	edi,ecx
	ror	edx,6
	mov	esi,ebp
	add	ebx,edi
	ror	esi,9
	mov	ecx,ebp
	mov	edi,DWORD [16+esp]
	xor	esi,ebp
	mov	DWORD [12+esp],ebp
	xor	ebp,edi
	ror	esi,11
	and	eax,ebp
	lea	edx,[2162078206+edx*1+ebx]
	xor	esi,ecx
	xor	eax,edi
	ror	esi,2
	add	eax,edx
	add	edx,DWORD [24+esp]
	add	eax,esi
	mov	ecx,edx
	mov	esi,DWORD [28+esp]
	ror	edx,14
	mov	edi,DWORD [esp]
	xor	edx,ecx
	mov	ebx,DWORD [88+esp]
	xor	esi,edi
	ror	edx,5
	and	esi,ecx
	mov	DWORD [24+esp],ecx
	xor	edx,ecx
	add	ebx,DWORD [4+esp]
	xor	edi,esi
	ror	edx,6
	mov	ecx,eax
	add	ebx,edi
	ror	ecx,9
	mov	esi,eax
	mov	edi,DWORD [12+esp]
	xor	ecx,eax
	mov	DWORD [8+esp],eax
	xor	eax,edi
	ror	ecx,11
	and	ebp,eax
	lea	edx,[2614888103+edx*1+ebx]
	xor	ecx,esi
	xor	ebp,edi
	ror	ecx,2
	add	ebp,edx
	add	edx,DWORD [20+esp]
	add	ebp,ecx
	mov	esi,edx
	mov	ecx,DWORD [24+esp]
	ror	edx,14
	mov	edi,DWORD [28+esp]
	xor	edx,esi
	mov	ebx,DWORD [92+esp]
	xor	ecx,edi
	ror	edx,5
	and	ecx,esi
	mov	DWORD [20+esp],esi
	xor	edx,esi
	add	ebx,DWORD [esp]
	xor	edi,ecx
	ror	edx,6
	mov	esi,ebp
	add	ebx,edi
	ror	esi,9
	mov	ecx,ebp
	mov	edi,DWORD [8+esp]
	xor	esi,ebp
	mov	DWORD [4+esp],ebp
	xor	ebp,edi
	ror	esi,11
	and	eax,ebp
	lea	edx,[3248222580+edx*1+ebx]
	xor	esi,ecx
	xor	eax,edi
	mov	ecx,DWORD [36+esp]
	ror	esi,2
	add	eax,edx
	add	edx,DWORD [16+esp]
	add	eax,esi
	mov	esi,DWORD [88+esp]
	mov	ebx,ecx
	ror	ecx,11
	mov	edi,esi
	ror	esi,2
	xor	ecx,ebx
	shr	ebx,3
	ror	ecx,7
	xor	esi,edi
	xor	ebx,ecx
	ror	esi,17
	add	ebx,DWORD [32+esp]
	shr	edi,10
	add	ebx,DWORD [68+esp]
	mov	ecx,edx
	xor	edi,esi
	mov	esi,DWORD [20+esp]
	ror	edx,14
	add	ebx,edi
	mov	edi,DWORD [24+esp]
	xor	edx,ecx
	mov	DWORD [32+esp],ebx
	xor	esi,edi
	ror	edx,5
	and	esi,ecx
	mov	DWORD [16+esp],ecx
	xor	edx,ecx
	add	ebx,DWORD [28+esp]
	xor	edi,esi
	ror	edx,6
	mov	ecx,eax
	add	ebx,edi
	ror	ecx,9
	mov	esi,eax
	mov	edi,DWORD [4+esp]
	xor	ecx,eax
	mov	DWORD [esp],eax
	xor	eax,edi
	ror	ecx,11
	and	ebp,eax
	lea	edx,[3835390401+edx*1+ebx]
	xor	ecx,esi
	xor	ebp,edi
	mov	esi,DWORD [40+esp]
	ror	ecx,2
	add	ebp,edx
	add	edx,DWORD [12+esp]
	add	ebp,ecx
	mov	ecx,DWORD [92+esp]
	mov	ebx,esi
	ror	esi,11
	mov	edi,ecx
	ror	ecx,2
	xor	esi,ebx
	shr	ebx,3
	ror	esi,7
	xor	ecx,edi
	xor	ebx,esi
	ror	ecx,17
	add	ebx,DWORD [36+esp]
	shr	edi,10
	add	ebx,DWORD [72+esp]
	mov	esi,edx
	xor	edi,ecx
	mov	ecx,DWORD [16+esp]
	ror	edx,14
	add	ebx,edi
	mov	edi,DWORD [20+esp]
	xor	edx,esi
	mov	DWORD [36+esp],ebx
	xor	ecx,edi
	ror	edx,5
	and	ecx,esi
	mov	DWORD [12+esp],esi
	xor	edx,esi
	add	ebx,DWORD [24+esp]
	xor	edi,ecx
	ror	edx,6
	mov	esi,ebp
	add	ebx,edi
	ror	esi,9
	mov	ecx,ebp
	mov	edi,DWORD [esp]
	xor	esi,ebp
	mov	DWORD [28+esp],ebp
	xor	ebp,edi
	ror	esi,11
	and	eax,ebp
	lea	edx,[4022224774+edx*1+ebx]
	xor	esi,ecx
	xor	eax,edi
	mov	ecx,DWORD [44+esp]
	ror	esi,2
	add	eax,edx
	add	edx,DWORD [8+esp]
	add	eax,esi
	mov	esi,DWORD [32+esp]
	mov	ebx,ecx
	ror	ecx,11
	mov	edi,esi
	ror	esi,2
	xor	ecx,ebx
	shr	ebx,3
	ror	ecx,7
	xor	esi,edi
	xor	ebx,ecx
	ror	esi,17
	add	ebx,DWORD [40+esp]
	shr	edi,10
	add	ebx,DWORD [76+esp]
	mov	ecx,edx
	xor	edi,esi
	mov	esi,DWORD [12+esp]
	ror	edx,14
	add	ebx,edi
	mov	edi,DWORD [16+esp]
	xor	edx,ecx
	mov	DWORD [40+esp],ebx
	xor	esi,edi
	ror	edx,5
	and	esi,ecx
	mov	DWORD [8+esp],ecx
	xor	edx,ecx
	add	ebx,DWORD [20+esp]
	xor	edi,esi
	ror	edx,6
	mov	ecx,eax
	add	ebx,edi
	ror	ecx,9
	mov	esi,eax
	mov	edi,DWORD [28+esp]
	xor	ecx,eax
	mov	DWORD [24+esp],eax
	xor	eax,edi
	ror	ecx,11
	and	ebp,eax
	lea	edx,[264347078+edx*1+ebx]
	xor	ecx,esi
	xor	ebp,edi
	mov	esi,DWORD [48+esp]
	ror	ecx,2
	add	ebp,edx
	add	edx,DWORD [4+esp]
	add	ebp,ecx
	mov	ecx,DWORD [36+esp]
	mov	ebx,esi
	ror	esi,11
	mov	edi,ecx
	ror	ecx,2
	xor	esi,ebx
	shr	ebx,3
	ror	esi,7
	xor	ecx,edi
	xor	ebx,esi
	ror	ecx,17
	add	ebx,DWORD [44+esp]
	shr	edi,10
	add	ebx,DWORD [80+esp]
	mov	esi,edx
	xor	edi,ecx
	mov	ecx,DWORD [8+esp]
	ror	edx,14
	add	ebx,edi
	mov	edi,DWORD [12+esp]
	xor	edx,esi
	mov	DWORD [44+esp],ebx
	xor	ecx,edi
	ror	edx,5
	and	ecx,esi
	mov	DWORD [4+esp],esi
	xor	edx,esi
	add	ebx,DWORD [16+esp]
	xor	edi,ecx
	ror	edx,6
	mov	esi,ebp
	add	ebx,edi
	ror	esi,9
	mov	ecx,ebp
	mov	edi,DWORD [24+esp]
	xor	esi,ebp
	mov	DWORD [20+esp],ebp
	xor	ebp,edi
	ror	esi,11
	and	eax,ebp
	lea	edx,[604807628+edx*1+ebx]
	xor	esi,ecx
	xor	eax,edi
	mov	ecx,DWORD [52+esp]
	ror	esi,2
	add	eax,edx
	add	edx,DWORD [esp]
	add	eax,esi
	mov	esi,DWORD [40+esp]
	mov	ebx,ecx
	ror	ecx,11
	mov	edi,esi
	ror	esi,2
	xor	ecx,ebx
	shr	ebx,3
	ror	ecx,7
	xor	esi,edi
	xor	ebx,ecx
	ror	esi,17
	add	ebx,DWORD [48+esp]
	shr	edi,10
	add	ebx,DWORD [84+esp]
	mov	ecx,edx
	xor	edi,esi
	mov	esi,DWORD [4+esp]
	ror	edx,14
	add	ebx,edi
	mov	edi,DWORD [8+esp]
	xor	edx,ecx
	mov	DWORD [48+esp],ebx
	xor	esi,edi
	ror	edx,5
	and	esi,ecx
	mov	DWORD [esp],ecx
	xor	edx,ecx
	add	ebx,DWORD [12+esp]
	xor	edi,esi
	ror	edx,6
	mov	ecx,eax
	add	ebx,edi
	ror	ecx,9
	mov	esi,eax
	mov	edi,DWORD [20+esp]
	xor	ecx,eax
	mov	DWORD [16+esp],eax
	xor	eax,edi
	ror	ecx,11
	and	ebp,eax
	lea	edx,[770255983+edx*1+ebx]
	xor	ecx,esi
	xor	ebp,edi
	mov	esi,DWORD [56+esp]
	ror	ecx,2
	add	ebp,edx
	add	edx,DWORD [28+esp]
	add	ebp,ecx
	mov	ecx,DWORD [44+esp]
	mov	ebx,esi
	ror	esi,11
	mov	edi,ecx
	ror	ecx,2
	xor	esi,ebx
	shr	ebx,3
	ror	esi,7
	xor	ecx,edi
	xor	ebx,esi
	ror	ecx,17
	add	ebx,DWORD [52+esp]
	shr	edi,10
	add	ebx,DWORD [88+esp]
	mov	esi,edx
	xor	edi,ecx
	mov	ecx,DWORD [esp]
	ror	edx,14
	add	ebx,edi
	mov	edi,DWORD [4+esp]
	xor	edx,esi
	mov	DWORD [52+esp],ebx
	xor	ecx,edi
	ror	edx,5
	and	ecx,esi
	mov	DWORD [28+esp],esi
	xor	edx,esi
	add	ebx,DWORD [8+esp]
	xor	edi,ecx
	ror	edx,6
	mov	esi,ebp
	add	ebx,edi
	ror	esi,9
	mov	ecx,ebp
	mov	edi,DWORD [16+esp]
	xor	esi,ebp
	mov	DWORD [12+esp],ebp
	xor	ebp,edi
	ror	esi,11
	and	eax,ebp
	lea	edx,[1249150122+edx*1+ebx]
	xor	esi,ecx
	xor	eax,edi
	mov	ecx,DWORD [60+esp]
	ror	esi,2
	add	eax,edx
	add	edx,DWORD [24+esp]
	add	eax,esi
	mov	esi,DWORD [48+esp]
	mov	ebx,ecx
	ror	ecx,11
	mov	edi,esi
	ror	esi,2
	xor	ecx,ebx
	shr	ebx,3
	ror	ecx,7
	xor	esi,edi
	xor	ebx,ecx
	ror	esi,17
	add	ebx,DWORD [56+esp]
	shr	edi,10
	add	ebx,DWORD [92+esp]
	mov	ecx,edx
	xor	edi,esi
	mov	esi,DWORD [28+esp]
	ror	edx,14
	add	ebx,edi
	mov	edi,DWORD [esp]
	xor	edx,ecx
	mov	DWORD [56+esp],ebx
	xor	esi,edi
	ror	edx,5
	and	esi,ecx
	mov	DWORD [24+esp],ecx
	xor	edx,ecx
	add	ebx,DWORD [4+esp]
	xor	edi,esi
	ror	edx,6
	mov	ecx,eax
	add	ebx,edi
	ror	ecx,9
	mov	esi,eax
	mov	edi,DWORD [12+esp]
	xor	ecx,eax
	mov	DWORD [8+esp],eax
	xor	eax,edi
	ror	ecx,11
	and	ebp,eax
	lea	edx,[1555081692+edx*1+ebx]
	xor	ecx,esi
	xor	ebp,edi
	mov	esi,DWORD [64+esp]
	ror	ecx,2
	add	ebp,edx
	add	edx,DWORD [20+esp]
	add	ebp,ecx
	mov	ecx,DWORD [52+esp]
	mov	ebx,esi
	ror	esi,11
	mov	edi,ecx
	ror	ecx,2
	xor	esi,ebx
	shr	ebx,3
	ror	esi,7
	xor	ecx,edi
	xor	ebx,esi
	ror	ecx,17
	add	ebx,DWORD [60+esp]
	shr	edi,10
	add	ebx,DWORD [32+esp]
	mov	esi,edx
	xor	edi,ecx
	mov	ecx,DWORD [24+esp]
	ror	edx,14
	add	ebx,edi
	mov	edi,DWORD [28+esp]
	xor	edx,esi
	mov	DWORD [60+esp],ebx
	xor	ecx,edi
	ror	edx,5
	and	ecx,esi
	mov	DWORD [20+esp],esi
	xor	edx,esi
	add	ebx,DWORD [esp]
	xor	edi,ecx
	ror	edx,6
	mov	esi,ebp
	add	ebx,edi
	ror	esi,9
	mov	ecx,ebp
	mov	edi,DWORD [8+esp]
	xor	esi,ebp
	mov	DWORD [4+esp],ebp
	xor	ebp,edi
	ror	esi,11
	and	eax,ebp
	lea	edx,[1996064986+edx*1+ebx]
	xor	esi,ecx
	xor	eax,edi
	mov	ecx,DWORD [68+esp]
	ror	esi,2
	add	eax,edx
	add	edx,DWORD [16+esp]
	add	eax,esi
	mov	esi,DWORD [56+esp]
	mov	ebx,ecx
	ror	ecx,11
	mov	edi,esi
	ror	esi,2
	xor	ecx,ebx
	shr	ebx,3
	ror	ecx,7
	xor	esi,edi
	xor	ebx,ecx
	ror	esi,17
	add	ebx,DWORD [64+esp]
	shr	edi,10
	add	ebx,DWORD [36+esp]
	mov	ecx,edx
	xor	edi,esi
	mov	esi,DWORD [20+esp]
	ror	edx,14
	add	ebx,edi
	mov	edi,DWORD [24+esp]
	xor	edx,ecx
	mov	DWORD [64+esp],ebx
	xor	esi,edi
	ror	edx,5
	and	esi,ecx
	mov	DWORD [16+esp],ecx
	xor	edx,ecx
	add	ebx,DWORD [28+esp]
	xor	edi,esi
	ror	edx,6
	mov	ecx,eax
	add	ebx,edi
	ror	ecx,9
	mov	esi,eax
	mov	edi,DWORD [4+esp]
	xor	ecx,eax
	mov	DWORD [esp],eax
	xor	eax,edi
	ror	ecx,11
	and	ebp,eax
	lea	edx,[2554220882+edx*1+ebx]
	xor	ecx,esi
	xor	ebp,edi
	mov	esi,DWORD [72+esp]
	ror	ecx,2
	add	ebp,edx
	add	edx,DWORD [12+esp]
	add	ebp,ecx
	mov	ecx,DWORD [60+esp]
	mov	ebx,esi
	ror	esi,11
	mov	edi,ecx
	ror	ecx,2
	xor	esi,ebx
	shr	ebx,3
	ror	esi,7
	xor	ecx,edi
	xor	ebx,esi
	ror	ecx,17
	add	ebx,DWORD [68+esp]
	shr	edi,10
	add	ebx,DWORD [40+esp]
	mov	esi,edx
	xor	edi,ecx
	mov	ecx,DWORD [16+esp]
	ror	edx,14
	add	ebx,edi
	mov	edi,DWORD [20+esp]
	xor	edx,esi
	mov	DWORD [68+esp],ebx
	xor	ecx,edi
	ror	edx,5
	and	ecx,esi
	mov	DWORD [12+esp],esi
	xor	edx,esi
	add	ebx,DWORD [24+esp]
	xor	edi,ecx
	ror	edx,6
	mov	esi,ebp
	add	ebx,edi
	ror	esi,9
	mov	ecx,ebp
	mov	edi,DWORD [esp]
	xor	esi,ebp
	mov	DWORD [28+esp],ebp
	xor	ebp,edi
	ror	esi,11
	and	eax,ebp
	lea	edx,[2821834349+edx*1+ebx]
	xor	esi,ecx
	xor	eax,edi
	mov	ecx,DWORD [76+esp]
	ror	esi,2
	add	eax,edx
	add	edx,DWORD [8+esp]
	add	eax,esi
	mov	esi,DWORD [64+esp]
	mov	ebx,ecx
	ror	ecx,11
	mov	edi,esi
	ror	esi,2
	xor	ecx,ebx
	shr	ebx,3
	ror	ecx,7
	xor	esi,edi
	xor	ebx,ecx
	ror	esi,17
	add	ebx,DWORD [72+esp]
	shr	edi,10
	add	ebx,DWORD [44+esp]
	mov	ecx,edx
	xor	edi,esi
	mov	esi,DWORD [12+esp]
	ror	edx,14
	add	ebx,edi
	mov	edi,DWORD [16+esp]
	xor	edx,ecx
	mov	DWORD [72+esp],ebx
	xor	esi,edi
	ror	edx,5
	and	esi,ecx
	mov	DWORD [8+esp],ecx
	xor	edx,ecx
	add	ebx,DWORD [20+esp]
	xor	edi,esi
	ror	edx,6
	mov	ecx,eax
	add	ebx,edi
	ror	ecx,9
	mov	esi,eax
	mov	edi,DWORD [28+esp]
	xor	ecx,eax
	mov	DWORD [24+esp],eax
	xor	eax,edi
	ror	ecx,11
	and	ebp,eax
	lea	edx,[2952996808+edx*1+ebx]
	xor	ecx,esi
	xor	ebp,edi
	mov	esi,DWORD [80+esp]
	ror	ecx,2
	add	ebp,edx
	add	edx,DWORD [4+esp]
	add	ebp,ecx
	mov	ecx,DWORD [68+esp]
	mov	ebx,esi
	ror	esi,11
	mov	edi,ecx
	ror	ecx,2
	xor	esi,ebx
	shr	ebx,3
	ror	esi,7
	xor	ecx,edi
	xor	ebx,esi
	ror	ecx,17
	add	ebx,DWORD [76+esp]
	shr	edi,10
	add	ebx,DWORD [48+esp]
	mov	esi,edx
	xor	edi,ecx
	mov	ecx,DWORD [8+esp]
	ror	edx,14
	add	ebx,edi
	mov	edi,DWORD [12+esp]
	xor	edx,esi
	mov	DWORD [76+esp],ebx
	xor	ecx,edi
	ror	edx,5
	and	ecx,esi
	mov	DWORD [4+esp],esi
	xor	edx,esi
	add	ebx,DWORD [16+esp]
	xor	edi,ecx
	ror	edx,6
	mov	esi,ebp
	add	ebx,edi
	ror	esi,9
	mov	ecx,ebp
	mov	edi,DWORD [24+esp]
	xor	esi,ebp
	mov	DWORD [20+esp],ebp
	xor	ebp,edi
	ror	esi,11
	and	eax,ebp
	lea	edx,[3210313671+edx*1+ebx]
	xor	esi,ecx
	xor	eax,edi
	mov	ecx,DWORD [84+esp]
	ror	esi,2
	add	eax,edx
	add	edx,DWORD [esp]
	add	eax,esi
	mov	esi,DWORD [72+esp]
	mov	ebx,ecx
	ror	ecx,11
	mov	edi,esi
	ror	esi,2
	xor	ecx,ebx
	shr	ebx,3
	ror	ecx,7
	xor	esi,edi
	xor	ebx,ecx
	ror	esi,17
	add	ebx,DWORD [80+esp]
	shr	edi,10
	add	ebx,DWORD [52+esp]
	mov	ecx,edx
	xor	edi,esi
	mov	esi,DWORD [4+esp]
	ror	edx,14
	add	ebx,edi
	mov	edi,DWORD [8+esp]
	xor	edx,ecx
	mov	DWORD [80+esp],ebx
	xor	esi,edi
	ror	edx,5
	and	esi,ecx
	mov	DWORD [esp],ecx
	xor	edx,ecx
	add	ebx,DWORD [12+esp]
	xor	edi,esi
	ror	edx,6
	mov	ecx,eax
	add	ebx,edi
	ror	ecx,9
	mov	esi,eax
	mov	edi,DWORD [20+esp]
	xor	ecx,eax
	mov	DWORD [16+esp],eax
	xor	eax,edi
	ror	ecx,11
	and	ebp,eax
	lea	edx,[3336571891+edx*1+ebx]
	xor	ecx,esi
	xor	ebp,edi
	mov	esi,DWORD [88+esp]
	ror	ecx,2
	add	ebp,edx
	add	edx,DWORD [28+esp]
	add	ebp,ecx
	mov	ecx,DWORD [76+esp]
	mov	ebx,esi
	ror	esi,11
	mov	edi,ecx
	ror	ecx,2
	xor	esi,ebx
	shr	ebx,3
	ror	esi,7
	xor	ecx,edi
	xor	ebx,esi
	ror	ecx,17
	add	ebx,DWORD [84+esp]
	shr	edi,10
	add	ebx,DWORD [56+esp]
	mov	esi,edx
	xor	edi,ecx
	mov	ecx,DWORD [esp]
	ror	edx,14
	add	ebx,edi
	mov	edi,DWORD [4+esp]
	xor	edx,esi
	mov	DWORD [84+esp],ebx
	xor	ecx,edi
	ror	edx,5
	and	ecx,esi
	mov	DWORD [28+esp],esi
	xor	edx,esi
	add	ebx,DWORD [8+esp]
	xor	edi,ecx
	ror	edx,6
	mov	esi,ebp
	add	ebx,edi
	ror	esi,9
	mov	ecx,ebp
	mov	edi,DWORD [16+esp]
	xor	esi,ebp
	mov	DWORD [12+esp],ebp
	xor	ebp,edi
	ror	esi,11
	and	eax,ebp
	lea	edx,[3584528711+edx*1+ebx]
	xor	esi,ecx
	xor	eax,edi
	mov	ecx,DWORD [92+esp]
	ror	esi,2
	add	eax,edx
	add	edx,DWORD [24+esp]
	add	eax,esi
	mov	esi,DWORD [80+esp]
	mov	ebx,ecx
	ror	ecx,11
	mov	edi,esi
	ror	esi,2
	xor	ecx,ebx
	shr	ebx,3
	ror	ecx,7
	xor	esi,edi
	xor	ebx,ecx
	ror	esi,17
	add	ebx,DWORD [88+esp]
	shr	edi,10
	add	ebx,DWORD [60+esp]
	mov	ecx,edx
	xor	edi,esi
	mov	esi,DWORD [28+esp]
	ror	edx,14
	add	ebx,edi
	mov	edi,DWORD [esp]
	xor	edx,ecx
	mov	DWORD [88+esp],ebx
	xor	esi,edi
	ror	edx,5
	and	esi,ecx
	mov	DWORD [24+esp],ecx
	xor	edx,ecx
	add	ebx,DWORD [4+esp]
	xor	edi,esi
	ror	edx,6
	mov	ecx,eax
	add	ebx,edi
	ror	ecx,9
	mov	esi,eax
	mov	edi,DWORD [12+esp]
	xor	ecx,eax
	mov	DWORD [8+esp],eax
	xor	eax,edi
	ror	ecx,11
	and	ebp,eax
	lea	edx,[113926993+edx*1+ebx]
	xor	ecx,esi
	xor	ebp,edi
	mov	esi,DWORD [32+esp]
	ror	ecx,2
	add	ebp,edx
	add	edx,DWORD [20+esp]
	add	ebp,ecx
	mov	ecx,DWORD [84+esp]
	mov	ebx,esi
	ror	esi,11
	mov	edi,ecx
	ror	ecx,2
	xor	esi,ebx
	shr	ebx,3
	ror	esi,7
	xor	ecx,edi
	xor	ebx,esi
	ror	ecx,17
	add	ebx,DWORD [92+esp]
	shr	edi,10
	add	ebx,DWORD [64+esp]
	mov	esi,edx
	xor	edi,ecx
	mov	ecx,DWORD [24+esp]
	ror	edx,14
	add	ebx,edi
	mov	edi,DWORD [28+esp]
	xor	edx,esi
	mov	DWORD [92+esp],ebx
	xor	ecx,edi
	ror	edx,5
	and	ecx,esi
	mov	DWORD [20+esp],esi
	xor	edx,esi
	add	ebx,DWORD [esp]
	xor	edi,ecx
	ror	edx,6
	mov	esi,ebp
	add	ebx,edi
	ror	esi,9
	mov	ecx,ebp
	mov	edi,DWORD [8+esp]
	xor	esi,ebp
	mov	DWORD [4+esp],ebp
	xor	ebp,edi
	ror	esi,11
	and	eax,ebp
	lea	edx,[338241895+edx*1+ebx]
	xor	esi,ecx
	xor	eax,edi
	mov	ecx,DWORD [36+esp]
	ror	esi,2
	add	eax,edx
	add	edx,DWORD [16+esp]
	add	eax,esi
	mov	esi,DWORD [88+esp]
	mov	ebx,ecx
	ror	ecx,11
	mov	edi,esi
	ror	esi,2
	xor	ecx,ebx
	shr	ebx,3
	ror	ecx,7
	xor	esi,edi
	xor	ebx,ecx
	ror	esi,17
	add	ebx,DWORD [32+esp]
	shr	edi,10
	add	ebx,DWORD [68+esp]
	mov	ecx,edx
	xor	edi,esi
	mov	esi,DWORD [20+esp]
	ror	edx,14
	add	ebx,edi
	mov	edi,DWORD [24+esp]
	xor	edx,ecx
	mov	DWORD [32+esp],ebx
	xor	esi,edi
	ror	edx,5
	and	esi,ecx
	mov	DWORD [16+esp],ecx
	xor	edx,ecx
	add	ebx,DWORD [28+esp]
	xor	edi,esi
	ror	edx,6
	mov	ecx,eax
	add	ebx,edi
	ror	ecx,9
	mov	esi,eax
	mov	edi,DWORD [4+esp]
	xor	ecx,eax
	mov	DWORD [esp],eax
	xor	eax,edi
	ror	ecx,11
	and	ebp,eax
	lea	edx,[666307205+edx*1+ebx]
	xor	ecx,esi
	xor	ebp,edi
	mov	esi,DWORD [40+esp]
	ror	ecx,2
	add	ebp,edx
	add	edx,DWORD [12+esp]
	add	ebp,ecx
	mov	ecx,DWORD [92+esp]
	mov	ebx,esi
	ror	esi,11
	mov	edi,ecx
	ror	ecx,2
	xor	esi,ebx
	shr	ebx,3
	ror	esi,7
	xor	ecx,edi
	xor	ebx,esi
	ror	ecx,17
	add	ebx,DWORD [36+esp]
	shr	edi,10
	add	ebx,DWORD [72+esp]
	mov	esi,edx
	xor	edi,ecx
	mov	ecx,DWORD [16+esp]
	ror	edx,14
	add	ebx,edi
	mov	edi,DWORD [20+esp]
	xor	edx,esi
	mov	DWORD [36+esp],ebx
	xor	ecx,edi
	ror	edx,5
	and	ecx,esi
	mov	DWORD [12+esp],esi
	xor	edx,esi
	add	ebx,DWORD [24+esp]
	xor	edi,ecx
	ror	edx,6
	mov	esi,ebp
	add	ebx,edi
	ror	esi,9
	mov	ecx,ebp
	mov	edi,DWORD [esp]
	xor	esi,ebp
	mov	DWORD [28+esp],ebp
	xor	ebp,edi
	ror	esi,11
	and	eax,ebp
	lea	edx,[773529912+edx*1+ebx]
	xor	esi,ecx
	xor	eax,edi
	mov	ecx,DWORD [44+esp]
	ror	esi,2
	add	eax,edx
	add	edx,DWORD [8+esp]
	add	eax,esi
	mov	esi,DWORD [32+esp]
	mov	ebx,ecx
	ror	ecx,11
	mov	edi,esi
	ror	esi,2
	xor	ecx,ebx
	shr	ebx,3
	ror	ecx,7
	xor	esi,edi
	xor	ebx,ecx
	ror	esi,17
	add	ebx,DWORD [40+esp]
	shr	edi,10
	add	ebx,DWORD [76+esp]
	mov	ecx,edx
	xor	edi,esi
	mov	esi,DWORD [12+esp]
	ror	edx,14
	add	ebx,edi
	mov	edi,DWORD [16+esp]
	xor	edx,ecx
	mov	DWORD [40+esp],ebx
	xor	esi,edi
	ror	edx,5
	and	esi,ecx
	mov	DWORD [8+esp],ecx
	xor	edx,ecx
	add	ebx,DWORD [20+esp]
	xor	edi,esi
	ror	edx,6
	mov	ecx,eax
	add	ebx,edi
	ror	ecx,9
	mov	esi,eax
	mov	edi,DWORD [28+esp]
	xor	ecx,eax
	mov	DWORD [24+esp],eax
	xor	eax,edi
	ror	ecx,11
	and	ebp,eax
	lea	edx,[1294757372+edx*1+ebx]
	xor	ecx,esi
	xor	ebp,edi
	mov	esi,DWORD [48+esp]
	ror	ecx,2
	add	ebp,edx
	add	edx,DWORD [4+esp]
	add	ebp,ecx
	mov	ecx,DWORD [36+esp]
	mov	ebx,esi
	ror	esi,11
	mov	edi,ecx
	ror	ecx,2
	xor	esi,ebx
	shr	ebx,3
	ror	esi,7
	xor	ecx,edi
	xor	ebx,esi
	ror	ecx,17
	add	ebx,DWORD [44+esp]
	shr	edi,10
	add	ebx,DWORD [80+esp]
	mov	esi,edx
	xor	edi,ecx
	mov	ecx,DWORD [8+esp]
	ror	edx,14
	add	ebx,edi
	mov	edi,DWORD [12+esp]
	xor	edx,esi
	mov	DWORD [44+esp],ebx
	xor	ecx,edi
	ror	edx,5
	and	ecx,esi
	mov	DWORD [4+esp],esi
	xor	edx,esi
	add	ebx,DWORD [16+esp]
	xor	edi,ecx
	ror	edx,6
	mov	esi,ebp
	add	ebx,edi
	ror	esi,9
	mov	ecx,ebp
	mov	edi,DWORD [24+esp]
	xor	esi,ebp
	mov	DWORD [20+esp],ebp
	xor	ebp,edi
	ror	esi,11
	and	eax,ebp
	lea	edx,[1396182291+edx*1+ebx]
	xor	esi,ecx
	xor	eax,edi
	mov	ecx,DWORD [52+esp]
	ror	esi,2
	add	eax,edx
	add	edx,DWORD [esp]
	add	eax,esi
	mov	esi,DWORD [40+esp]
	mov	ebx,ecx
	ror	ecx,11
	mov	edi,esi
	ror	esi,2
	xor	ecx,ebx
	shr	ebx,3
	ror	ecx,7
	xor	esi,edi
	xor	ebx,ecx
	ror	esi,17
	add	ebx,DWORD [48+esp]
	shr	edi,10
	add	ebx,DWORD [84+esp]
	mov	ecx,edx
	xor	edi,esi
	mov	esi,DWORD [4+esp]
	ror	edx,14
	add	ebx,edi
	mov	edi,DWORD [8+esp]
	xor	edx,ecx
	mov	DWORD [48+esp],ebx
	xor	esi,edi
	ror	edx,5
	and	esi,ecx
	mov	DWORD [esp],ecx
	xor	edx,ecx
	add	ebx,DWORD [12+esp]
	xor	edi,esi
	ror	edx,6
	mov	ecx,eax
	add	ebx,edi
	ror	ecx,9
	mov	esi,eax
	mov	edi,DWORD [20+esp]
	xor	ecx,eax
	mov	DWORD [16+esp],eax
	xor	eax,edi
	ror	ecx,11
	and	ebp,eax
	lea	edx,[1695183700+edx*1+ebx]
	xor	ecx,esi
	xor	ebp,edi
	mov	esi,DWORD [56+esp]
	ror	ecx,2
	add	ebp,edx
	add	edx,DWORD [28+esp]
	add	ebp,ecx
	mov	ecx,DWORD [44+esp]
	mov	ebx,esi
	ror	esi,11
	mov	edi,ecx
	ror	ecx,2
	xor	esi,ebx
	shr	ebx,3
	ror	esi,7
	xor	ecx,edi
	xor	ebx,esi
	ror	ecx,17
	add	ebx,DWORD [52+esp]
	shr	edi,10
	add	ebx,DWORD [88+esp]
	mov	esi,edx
	xor	edi,ecx
	mov	ecx,DWORD [esp]
	ror	edx,14
	add	ebx,edi
	mov	edi,DWORD [4+esp]
	xor	edx,esi
	mov	DWORD [52+esp],ebx
	xor	ecx,edi
	ror	edx,5
	and	ecx,esi
	mov	DWORD [28+esp],esi
	xor	edx,esi
	add	ebx,DWORD [8+esp]
	xor	edi,ecx
	ror	edx,6
	mov	esi,ebp
	add	ebx,edi
	ror	esi,9
	mov	ecx,ebp
	mov	edi,DWORD [16+esp]
	xor	esi,ebp
	mov	DWORD [12+esp],ebp
	xor	ebp,edi
	ror	esi,11
	and	eax,ebp
	lea	edx,[1986661051+edx*1+ebx]
	xor	esi,ecx
	xor	eax,edi
	mov	ecx,DWORD [60+esp]
	ror	esi,2
	add	eax,edx
	add	edx,DWORD [24+esp]
	add	eax,esi
	mov	esi,DWORD [48+esp]
	mov	ebx,ecx
	ror	ecx,11
	mov	edi,esi
	ror	esi,2
	xor	ecx,ebx
	shr	ebx,3
	ror	ecx,7
	xor	esi,edi
	xor	ebx,ecx
	ror	esi,17
	add	ebx,DWORD [56+esp]
	shr	edi,10
	add	ebx,DWORD [92+esp]
	mov	ecx,edx
	xor	edi,esi
	mov	esi,DWORD [28+esp]
	ror	edx,14
	add	ebx,edi
	mov	edi,DWORD [esp]
	xor	edx,ecx
	mov	DWORD [56+esp],ebx
	xor	esi,edi
	ror	edx,5
	and	esi,ecx
	mov	DWORD [24+esp],ecx
	xor	edx,ecx
	add	ebx,DWORD [4+esp]
	xor	edi,esi
	ror	edx,6
	mov	ecx,eax
	add	ebx,edi
	ror	ecx,9
	mov	esi,eax
	mov	edi,DWORD [12+esp]
	xor	ecx,eax
	mov	DWORD [8+esp],eax
	xor	eax,edi
	ror	ecx,11
	and	ebp,eax
	lea	edx,[2177026350+edx*1+ebx]
	xor	ecx,esi
	xor	ebp,edi
	mov	esi,DWORD [64+esp]
	ror	ecx,2
	add	ebp,edx
	add	edx,DWORD [20+esp]
	add	ebp,ecx
	mov	ecx,DWORD [52+esp]
	mov	ebx,esi
	ror	esi,11
	mov	edi,ecx
	ror	ecx,2
	xor	esi,ebx
	shr	ebx,3
	ror	esi,7
	xor	ecx,edi
	xor	ebx,esi
	ror	ecx,17
	add	ebx,DWORD [60+esp]
	shr	edi,10
	add	ebx,DWORD [32+esp]
	mov	esi,edx
	xor	edi,ecx
	mov	ecx,DWORD [24+esp]
	ror	edx,14
	add	ebx,edi
	mov	edi,DWORD [28+esp]
	xor	edx,esi
	mov	DWORD [60+esp],ebx
	xor	ecx,edi
	ror	edx,5
	and	ecx,esi
	mov	DWORD [20+esp],esi
	xor	edx,esi
	add	ebx,DWORD [esp]
	xor	edi,ecx
	ror	edx,6
	mov	esi,ebp
	add	ebx,edi
	ror	esi,9
	mov	ecx,ebp
	mov	edi,DWORD [8+esp]
	xor	esi,ebp
	mov	DWORD [4+esp],ebp
	xor	ebp,edi
	ror	esi,11
	and	eax,ebp
	lea	edx,[2456956037+edx*1+ebx]
	xor	esi,ecx
	xor	eax,edi
	mov	ecx,DWORD [68+esp]
	ror	esi,2
	add	eax,edx
	add	edx,DWORD [16+esp]
	add	eax,esi
	mov	esi,DWORD [56+esp]
	mov	ebx,ecx
	ror	ecx,11
	mov	edi,esi
	ror	esi,2
	xor	ecx,ebx
	shr	ebx,3
	ror	ecx,7
	xor	esi,edi
	xor	ebx,ecx
	ror	esi,17
	add	ebx,DWORD [64+esp]
	shr	edi,10
	add	ebx,DWORD [36+esp]
	mov	ecx,edx
	xor	edi,esi
	mov	esi,DWORD [20+esp]
	ror	edx,14
	add	ebx,edi
	mov	edi,DWORD [24+esp]
	xor	edx,ecx
	mov	DWORD [64+esp],ebx
	xor	esi,edi
	ror	edx,5
	and	esi,ecx
	mov	DWORD [16+esp],ecx
	xor	edx,ecx
	add	ebx,DWORD [28+esp]
	xor	edi,esi
	ror	edx,6
	mov	ecx,eax
	add	ebx,edi
	ror	ecx,9
	mov	esi,eax
	mov	edi,DWORD [4+esp]
	xor	ecx,eax
	mov	DWORD [esp],eax
	xor	eax,edi
	ror	ecx,11
	and	ebp,eax
	lea	edx,[2730485921+edx*1+ebx]
	xor	ecx,esi
	xor	ebp,edi
	mov	esi,DWORD [72+esp]
	ror	ecx,2
	add	ebp,edx
	add	edx,DWORD [12+esp]
	add	ebp,ecx
	mov	ecx,DWORD [60+esp]
	mov	ebx,esi
	ror	esi,11
	mov	edi,ecx
	ror	ecx,2
	xor	esi,ebx
	shr	ebx,3
	ror	esi,7
	xor	ecx,edi
	xor	ebx,esi
	ror	ecx,17
	add	ebx,DWORD [68+esp]
	shr	edi,10
	add	ebx,DWORD [40+esp]
	mov	esi,edx
	xor	edi,ecx
	mov	ecx,DWORD [16+esp]
	ror	edx,14
	add	ebx,edi
	mov	edi,DWORD [20+esp]
	xor	edx,esi
	mov	DWORD [68+esp],ebx
	xor	ecx,edi
	ror	edx,5
	and	ecx,esi
	mov	DWORD [12+esp],esi
	xor	edx,esi
	add	ebx,DWORD [24+esp]
	xor	edi,ecx
	ror	edx,6
	mov	esi,ebp
	add	ebx,edi
	ror	esi,9
	mov	ecx,ebp
	mov	edi,DWORD [esp]
	xor	esi,ebp
	mov	DWORD [28+esp],ebp
	xor	ebp,edi
	ror	esi,11
	and	eax,ebp
	lea	edx,[2820302411+edx*1+ebx]
	xor	esi,ecx
	xor	eax,edi
	mov	ecx,DWORD [76+esp]
	ror	esi,2
	add	eax,edx
	add	edx,DWORD [8+esp]
	add	eax,esi
	mov	esi,DWORD [64+esp]
	mov	ebx,ecx
	ror	ecx,11
	mov	edi,esi
	ror	esi,2
	xor	ecx,ebx
	shr	ebx,3
	ror	ecx,7
	xor	esi,edi
	xor	ebx,ecx
	ror	esi,17
	add	ebx,DWORD [72+esp]
	shr	edi,10
	add	ebx,DWORD [44+esp]
	mov	ecx,edx
	xor	edi,esi
	mov	esi,DWORD [12+esp]
	ror	edx,14
	add	ebx,edi
	mov	edi,DWORD [16+esp]
	xor	edx,ecx
	mov	DWORD [72+esp],ebx
	xor	esi,edi
	ror	edx,5
	and	esi,ecx
	mov	DWORD [8+esp],ecx
	xor	edx,ecx
	add	ebx,DWORD [20+esp]
	xor	edi,esi
	ror	edx,6
	mov	ecx,eax
	add	ebx,edi
	ror	ecx,9
	mov	esi,eax
	mov	edi,DWORD [28+esp]
	xor	ecx,eax
	mov	DWORD [24+esp],eax
	xor	eax,edi
	ror	ecx,11
	and	ebp,eax
	lea	edx,[3259730800+edx*1+ebx]
	xor	ecx,esi
	xor	ebp,edi
	mov	esi,DWORD [80+esp]
	ror	ecx,2
	add	ebp,edx
	add	edx,DWORD [4+esp]
	add	ebp,ecx
	mov	ecx,DWORD [68+esp]
	mov	ebx,esi
	ror	esi,11
	mov	edi,ecx
	ror	ecx,2
	xor	esi,ebx
	shr	ebx,3
	ror	esi,7
	xor	ecx,edi
	xor	ebx,esi
	ror	ecx,17
	add	ebx,DWORD [76+esp]
	shr	edi,10
	add	ebx,DWORD [48+esp]
	mov	esi,edx
	xor	edi,ecx
	mov	ecx,DWORD [8+esp]
	ror	edx,14
	add	ebx,edi
	mov	edi,DWORD [12+esp]
	xor	edx,esi
	mov	DWORD [76+esp],ebx
	xor	ecx,edi
	ror	edx,5
	and	ecx,esi
	mov	DWORD [4+esp],esi
	xor	edx,esi
	add	ebx,DWORD [16+esp]
	xor	edi,ecx
	ror	edx,6
	mov	esi,ebp
	add	ebx,edi
	ror	esi,9
	mov	ecx,ebp
	mov	edi,DWORD [24+esp]
	xor	esi,ebp
	mov	DWORD [20+esp],ebp
	xor	ebp,edi
	ror	esi,11
	and	eax,ebp
	lea	edx,[3345764771+edx*1+ebx]
	xor	esi,ecx
	xor	eax,edi
	mov	ecx,DWORD [84+esp]
	ror	esi,2
	add	eax,edx
	add	edx,DWORD [esp]
	add	eax,esi
	mov	esi,DWORD [72+esp]
	mov	ebx,ecx
	ror	ecx,11
	mov	edi,esi
	ror	esi,2
	xor	ecx,ebx
	shr	ebx,3
	ror	ecx,7
	xor	esi,edi
	xor	ebx,ecx
	ror	esi,17
	add	ebx,DWORD [80+esp]
	shr	edi,10
	add	ebx,DWORD [52+esp]
	mov	ecx,edx
	xor	edi,esi
	mov	esi,DWORD [4+esp]
	ror	edx,14
	add	ebx,edi
	mov	edi,DWORD [8+esp]
	xor	edx,ecx
	mov	DWORD [80+esp],ebx
	xor	esi,edi
	ror	edx,5
	and	esi,ecx
	mov	DWORD [esp],ecx
	xor	edx,ecx
	add	ebx,DWORD [12+esp]
	xor	edi,esi
	ror	edx,6
	mov	ecx,eax
	add	ebx,edi
	ror	ecx,9
	mov	esi,eax
	mov	edi,DWORD [20+esp]
	xor	ecx,eax
	mov	DWORD [16+esp],eax
	xor	eax,edi
	ror	ecx,11
	and	ebp,eax
	lea	edx,[3516065817+edx*1+ebx]
	xor	ecx,esi
	xor	ebp,edi
	mov	esi,DWORD [88+esp]
	ror	ecx,2
	add	ebp,edx
	add	edx,DWORD [28+esp]
	add	ebp,ecx
	mov	ecx,DWORD [76+esp]
	mov	ebx,esi
	ror	esi,11
	mov	edi,ecx
	ror	ecx,2
	xor	esi,ebx
	shr	ebx,3
	ror	esi,7
	xor	ecx,edi
	xor	ebx,esi
	ror	ecx,17
	add	ebx,DWORD [84+esp]
	shr	edi,10
	add	ebx,DWORD [56+esp]
	mov	esi,edx
	xor	edi,ecx
	mov	ecx,DWORD [esp]
	ror	edx,14
	add	ebx,edi
	mov	edi,DWORD [4+esp]
	xor	edx,esi
	mov	DWORD [84+esp],ebx
	xor	ecx,edi
	ror	edx,5
	and	ecx,esi
	mov	DWORD [28+esp],esi
	xor	edx,esi
	add	ebx,DWORD [8+esp]
	xor	edi,ecx
	ror	edx,6
	mov	esi,ebp
	add	ebx,edi
	ror	esi,9
	mov	ecx,ebp
	mov	edi,DWORD [16+esp]
	xor	esi,ebp
	mov	DWORD [12+esp],ebp
	xor	ebp,edi
	ror	esi,11
	and	eax,ebp
	lea	edx,[3600352804+edx*1+ebx]
	xor	esi,ecx
	xor	eax,edi
	mov	ecx,DWORD [92+esp]
	ror	esi,2
	add	eax,edx
	add	edx,DWORD [24+esp]
	add	eax,esi
	mov	esi,DWORD [80+esp]
	mov	ebx,ecx
	ror	ecx,11
	mov	edi,esi
	ror	esi,2
	xor	ecx,ebx
	shr	ebx,3
	ror	ecx,7
	xor	esi,edi
	xor	ebx,ecx
	ror	esi,17
	add	ebx,DWORD [88+esp]
	shr	edi,10
	add	ebx,DWORD [60+esp]
	mov	ecx,edx
	xor	edi,esi
	mov	esi,DWORD [28+esp]
	ror	edx,14
	add	ebx,edi
	mov	edi,DWORD [esp]
	xor	edx,ecx
	mov	DWORD [88+esp],ebx
	xor	esi,edi
	ror	edx,5
	and	esi,ecx
	mov	DWORD [24+esp],ecx
	xor	edx,ecx
	add	ebx,DWORD [4+esp]
	xor	edi,esi
	ror	edx,6
	mov	ecx,eax
	add	ebx,edi
	ror	ecx,9
	mov	esi,eax
	mov	edi,DWORD [12+esp]
	xor	ecx,eax
	mov	DWORD [8+esp],eax
	xor	eax,edi
	ror	ecx,11
	and	ebp,eax
	lea	edx,[4094571909+edx*1+ebx]
	xor	ecx,esi
	xor	ebp,edi
	mov	esi,DWORD [32+esp]
	ror	ecx,2
	add	ebp,edx
	add	edx,DWORD [20+esp]
	add	ebp,ecx
	mov	ecx,DWORD [84+esp]
	mov	ebx,esi
	ror	esi,11
	mov	edi,ecx
	ror	ecx,2
	xor	esi,ebx
	shr	ebx,3
	ror	esi,7
	xor	ecx,edi
	xor	ebx,esi
	ror	ecx,17
	add	ebx,DWORD [92+esp]
	shr	edi,10
	add	ebx,DWORD [64+esp]
	mov	esi,edx
	xor	edi,ecx
	mov	ecx,DWORD [24+esp]
	ror	edx,14
	add	ebx,edi
	mov	edi,DWORD [28+esp]
	xor	edx,esi
	mov	DWORD [92+esp],ebx
	xor	ecx,edi
	ror	edx,5
	and	ecx,esi
	mov	DWORD [20+esp],esi
	xor	edx,esi
	add	ebx,DWORD [esp]
	xor	edi,ecx
	ror	edx,6
	mov	esi,ebp
	add	ebx,edi
	ror	esi,9
	mov	ecx,ebp
	mov	edi,DWORD [8+esp]
	xor	esi,ebp
	mov	DWORD [4+esp],ebp
	xor	ebp,edi
	ror	esi,11
	and	eax,ebp
	lea	edx,[275423344+edx*1+ebx]
	xor	esi,ecx
	xor	eax,edi
	mov	ecx,DWORD [36+esp]
	ror	esi,2
	add	eax,edx
	add	edx,DWORD [16+esp]
	add	eax,esi
	mov	esi,DWORD [88+esp]
	mov	ebx,ecx
	ror	ecx,11
	mov	edi,esi
	ror	esi,2
	xor	ecx,ebx
	shr	ebx,3
	ror	ecx,7
	xor	esi,edi
	xor	ebx,ecx
	ror	esi,17
	add	ebx,DWORD [32+esp]
	shr	edi,10
	add	ebx,DWORD [68+esp]
	mov	ecx,edx
	xor	edi,esi
	mov	esi,DWORD [20+esp]
	ror	edx,14
	add	ebx,edi
	mov	edi,DWORD [24+esp]
	xor	edx,ecx
	mov	DWORD [32+esp],ebx
	xor	esi,edi
	ror	edx,5
	and	esi,ecx
	mov	DWORD [16+esp],ecx
	xor	edx,ecx
	add	ebx,DWORD [28+esp]
	xor	edi,esi
	ror	edx,6
	mov	ecx,eax
	add	ebx,edi
	ror	ecx,9
	mov	esi,eax
	mov	edi,DWORD [4+esp]
	xor	ecx,eax
	mov	DWORD [esp],eax
	xor	eax,edi
	ror	ecx,11
	and	ebp,eax
	lea	edx,[430227734+edx*1+ebx]
	xor	ecx,esi
	xor	ebp,edi
	mov	esi,DWORD [40+esp]
	ror	ecx,2
	add	ebp,edx
	add	edx,DWORD [12+esp]
	add	ebp,ecx
	mov	ecx,DWORD [92+esp]
	mov	ebx,esi
	ror	esi,11
	mov	edi,ecx
	ror	ecx,2
	xor	esi,ebx
	shr	ebx,3
	ror	esi,7
	xor	ecx,edi
	xor	ebx,esi
	ror	ecx,17
	add	ebx,DWORD [36+esp]
	shr	edi,10
	add	ebx,DWORD [72+esp]
	mov	esi,edx
	xor	edi,ecx
	mov	ecx,DWORD [16+esp]
	ror	edx,14
	add	ebx,edi
	mov	edi,DWORD [20+esp]
	xor	edx,esi
	mov	DWORD [36+esp],ebx
	xor	ecx,edi
	ror	edx,5
	and	ecx,esi
	mov	DWORD [12+esp],esi
	xor	edx,esi
	add	ebx,DWORD [24+esp]
	xor	edi,ecx
	ror	edx,6
	mov	esi,ebp
	add	ebx,edi
	ror	esi,9
	mov	ecx,ebp
	mov	edi,DWORD [esp]
	xor	esi,ebp
	mov	DWORD [28+esp],ebp
	xor	ebp,edi
	ror	esi,11
	and	eax,ebp
	lea	edx,[506948616+edx*1+ebx]
	xor	esi,ecx
	xor	eax,edi
	mov	ecx,DWORD [44+esp]
	ror	esi,2
	add	eax,edx
	add	edx,DWORD [8+esp]
	add	eax,esi
	mov	esi,DWORD [32+esp]
	mov	ebx,ecx
	ror	ecx,11
	mov	edi,esi
	ror	esi,2
	xor	ecx,ebx
	shr	ebx,3
	ror	ecx,7
	xor	esi,edi
	xor	ebx,ecx
	ror	esi,17
	add	ebx,DWORD [40+esp]
	shr	edi,10
	add	ebx,DWORD [76+esp]
	mov	ecx,edx
	xor	edi,esi
	mov	esi,DWORD [12+esp]
	ror	edx,14
	add	ebx,edi
	mov	edi,DWORD [16+esp]
	xor	edx,ecx
	mov	DWORD [40+esp],ebx
	xor	esi,edi
	ror	edx,5
	and	esi,ecx
	mov	DWORD [8+esp],ecx
	xor	edx,ecx
	add	ebx,DWORD [20+esp]
	xor	edi,esi
	ror	edx,6
	mov	ecx,eax
	add	ebx,edi
	ror	ecx,9
	mov	esi,eax
	mov	edi,DWORD [28+esp]
	xor	ecx,eax
	mov	DWORD [24+esp],eax
	xor	eax,edi
	ror	ecx,11
	and	ebp,eax
	lea	edx,[659060556+edx*1+ebx]
	xor	ecx,esi
	xor	ebp,edi
	mov	esi,DWORD [48+esp]
	ror	ecx,2
	add	ebp,edx
	add	edx,DWORD [4+esp]
	add	ebp,ecx
	mov	ecx,DWORD [36+esp]
	mov	ebx,esi
	ror	esi,11
	mov	edi,ecx
	ror	ecx,2
	xor	esi,ebx
	shr	ebx,3
	ror	esi,7
	xor	ecx,edi
	xor	ebx,esi
	ror	ecx,17
	add	ebx,DWORD [44+esp]
	shr	edi,10
	add	ebx,DWORD [80+esp]
	mov	esi,edx
	xor	edi,ecx
	mov	ecx,DWORD [8+esp]
	ror	edx,14
	add	ebx,edi
	mov	edi,DWORD [12+esp]
	xor	edx,esi
	mov	DWORD [44+esp],ebx
	xor	ecx,edi
	ror	edx,5
	and	ecx,esi
	mov	DWORD [4+esp],esi
	xor	edx,esi
	add	ebx,DWORD [16+esp]
	xor	edi,ecx
	ror	edx,6
	mov	esi,ebp
	add	ebx,edi
	ror	esi,9
	mov	ecx,ebp
	mov	edi,DWORD [24+esp]
	xor	esi,ebp
	mov	DWORD [20+esp],ebp
	xor	ebp,edi
	ror	esi,11
	and	eax,ebp
	lea	edx,[883997877+edx*1+ebx]
	xor	esi,ecx
	xor	eax,edi
	mov	ecx,DWORD [52+esp]
	ror	esi,2
	add	eax,edx
	add	edx,DWORD [esp]
	add	eax,esi
	mov	esi,DWORD [40+esp]
	mov	ebx,ecx
	ror	ecx,11
	mov	edi,esi
	ror	esi,2
	xor	ecx,ebx
	shr	ebx,3
	ror	ecx,7
	xor	esi,edi
	xor	ebx,ecx
	ror	esi,17
	add	ebx,DWORD [48+esp]
	shr	edi,10
	add	ebx,DWORD [84+esp]
	mov	ecx,edx
	xor	edi,esi
	mov	esi,DWORD [4+esp]
	ror	edx,14
	add	ebx,edi
	mov	edi,DWORD [8+esp]
	xor	edx,ecx
	mov	DWORD [48+esp],ebx
	xor	esi,edi
	ror	edx,5
	and	esi,ecx
	mov	DWORD [esp],ecx
	xor	edx,ecx
	add	ebx,DWORD [12+esp]
	xor	edi,esi
	ror	edx,6
	mov	ecx,eax
	add	ebx,edi
	ror	ecx,9
	mov	esi,eax
	mov	edi,DWORD [20+esp]
	xor	ecx,eax
	mov	DWORD [16+esp],eax
	xor	eax,edi
	ror	ecx,11
	and	ebp,eax
	lea	edx,[958139571+edx*1+ebx]
	xor	ecx,esi
	xor	ebp,edi
	mov	esi,DWORD [56+esp]
	ror	ecx,2
	add	ebp,edx
	add	edx,DWORD [28+esp]
	add	ebp,ecx
	mov	ecx,DWORD [44+esp]
	mov	ebx,esi
	ror	esi,11
	mov	edi,ecx
	ror	ecx,2
	xor	esi,ebx
	shr	ebx,3
	ror	esi,7
	xor	ecx,edi
	xor	ebx,esi
	ror	ecx,17
	add	ebx,DWORD [52+esp]
	shr	edi,10
	add	ebx,DWORD [88+esp]
	mov	esi,edx
	xor	edi,ecx
	mov	ecx,DWORD [esp]
	ror	edx,14
	add	ebx,edi
	mov	edi,DWORD [4+esp]
	xor	edx,esi
	mov	DWORD [52+esp],ebx
	xor	ecx,edi
	ror	edx,5
	and	ecx,esi
	mov	DWORD [28+esp],esi
	xor	edx,esi
	add	ebx,DWORD [8+esp]
	xor	edi,ecx
	ror	edx,6
	mov	esi,ebp
	add	ebx,edi
	ror	esi,9
	mov	ecx,ebp
	mov	edi,DWORD [16+esp]
	xor	esi,ebp
	mov	DWORD [12+esp],ebp
	xor	ebp,edi
	ror	esi,11
	and	eax,ebp
	lea	edx,[1322822218+edx*1+ebx]
	xor	esi,ecx
	xor	eax,edi
	mov	ecx,DWORD [60+esp]
	ror	esi,2
	add	eax,edx
	add	edx,DWORD [24+esp]
	add	eax,esi
	mov	esi,DWORD [48+esp]
	mov	ebx,ecx
	ror	ecx,11
	mov	edi,esi
	ror	esi,2
	xor	ecx,ebx
	shr	ebx,3
	ror	ecx,7
	xor	esi,edi
	xor	ebx,ecx
	ror	esi,17
	add	ebx,DWORD [56+esp]
	shr	edi,10
	add	ebx,DWORD [92+esp]
	mov	ecx,edx
	xor	edi,esi
	mov	esi,DWORD [28+esp]
	ror	edx,14
	add	ebx,edi
	mov	edi,DWORD [esp]
	xor	edx,ecx
	mov	DWORD [56+esp],ebx
	xor	esi,edi
	ror	edx,5
	and	esi,ecx
	mov	DWORD [24+esp],ecx
	xor	edx,ecx
	add	ebx,DWORD [4+esp]
	xor	edi,esi
	ror	edx,6
	mov	ecx,eax
	add	ebx,edi
	ror	ecx,9
	mov	esi,eax
	mov	edi,DWORD [12+esp]
	xor	ecx,eax
	mov	DWORD [8+esp],eax
	xor	eax,edi
	ror	ecx,11
	and	ebp,eax
	lea	edx,[1537002063+edx*1+ebx]
	xor	ecx,esi
	xor	ebp,edi
	mov	esi,DWORD [64+esp]
	ror	ecx,2
	add	ebp,edx
	add	edx,DWORD [20+esp]
	add	ebp,ecx
	mov	ecx,DWORD [52+esp]
	mov	ebx,esi
	ror	esi,11
	mov	edi,ecx
	ror	ecx,2
	xor	esi,ebx
	shr	ebx,3
	ror	esi,7
	xor	ecx,edi
	xor	ebx,esi
	ror	ecx,17
	add	ebx,DWORD [60+esp]
	shr	edi,10
	add	ebx,DWORD [32+esp]
	mov	esi,edx
	xor	edi,ecx
	mov	ecx,DWORD [24+esp]
	ror	edx,14
	add	ebx,edi
	mov	edi,DWORD [28+esp]
	xor	edx,esi
	mov	DWORD [60+esp],ebx
	xor	ecx,edi
	ror	edx,5
	and	ecx,esi
	mov	DWORD [20+esp],esi
	xor	edx,esi
	add	ebx,DWORD [esp]
	xor	edi,ecx
	ror	edx,6
	mov	esi,ebp
	add	ebx,edi
	ror	esi,9
	mov	ecx,ebp
	mov	edi,DWORD [8+esp]
	xor	esi,ebp
	mov	DWORD [4+esp],ebp
	xor	ebp,edi
	ror	esi,11
	and	eax,ebp
	lea	edx,[1747873779+edx*1+ebx]
	xor	esi,ecx
	xor	eax,edi
	mov	ecx,DWORD [68+esp]
	ror	esi,2
	add	eax,edx
	add	edx,DWORD [16+esp]
	add	eax,esi
	mov	esi,DWORD [56+esp]
	mov	ebx,ecx
	ror	ecx,11
	mov	edi,esi
	ror	esi,2
	xor	ecx,ebx
	shr	ebx,3
	ror	ecx,7
	xor	esi,edi
	xor	ebx,ecx
	ror	esi,17
	add	ebx,DWORD [64+esp]
	shr	edi,10
	add	ebx,DWORD [36+esp]
	mov	ecx,edx
	xor	edi,esi
	mov	esi,DWORD [20+esp]
	ror	edx,14
	add	ebx,edi
	mov	edi,DWORD [24+esp]
	xor	edx,ecx
	mov	DWORD [64+esp],ebx
	xor	esi,edi
	ror	edx,5
	and	esi,ecx
	mov	DWORD [16+esp],ecx
	xor	edx,ecx
	add	ebx,DWORD [28+esp]
	xor	edi,esi
	ror	edx,6
	mov	ecx,eax
	add	ebx,edi
	ror	ecx,9
	mov	esi,eax
	mov	edi,DWORD [4+esp]
	xor	ecx,eax
	mov	DWORD [esp],eax
	xor	eax,edi
	ror	ecx,11
	and	ebp,eax
	lea	edx,[1955562222+edx*1+ebx]
	xor	ecx,esi
	xor	ebp,edi
	mov	esi,DWORD [72+esp]
	ror	ecx,2
	add	ebp,edx
	add	edx,DWORD [12+esp]
	add	ebp,ecx
	mov	ecx,DWORD [60+esp]
	mov	ebx,esi
	ror	esi,11
	mov	edi,ecx
	ror	ecx,2
	xor	esi,ebx
	shr	ebx,3
	ror	esi,7
	xor	ecx,edi
	xor	ebx,esi
	ror	ecx,17
	add	ebx,DWORD [68+esp]
	shr	edi,10
	add	ebx,DWORD [40+esp]
	mov	esi,edx
	xor	edi,ecx
	mov	ecx,DWORD [16+esp]
	ror	edx,14
	add	ebx,edi
	mov	edi,DWORD [20+esp]
	xor	edx,esi
	mov	DWORD [68+esp],ebx
	xor	ecx,edi
	ror	edx,5
	and	ecx,esi
	mov	DWORD [12+esp],esi
	xor	edx,esi
	add	ebx,DWORD [24+esp]
	xor	edi,ecx
	ror	edx,6
	mov	esi,ebp
	add	ebx,edi
	ror	esi,9
	mov	ecx,ebp
	mov	edi,DWORD [esp]
	xor	esi,ebp
	mov	DWORD [28+esp],ebp
	xor	ebp,edi
	ror	esi,11
	and	eax,ebp
	lea	edx,[2024104815+edx*1+ebx]
	xor	esi,ecx
	xor	eax,edi
	mov	ecx,DWORD [76+esp]
	ror	esi,2
	add	eax,edx
	add	edx,DWORD [8+esp]
	add	eax,esi
	mov	esi,DWORD [64+esp]
	mov	ebx,ecx
	ror	ecx,11
	mov	edi,esi
	ror	esi,2
	xor	ecx,ebx
	shr	ebx,3
	ror	ecx,7
	xor	esi,edi
	xor	ebx,ecx
	ror	esi,17
	add	ebx,DWORD [72+esp]
	shr	edi,10
	add	ebx,DWORD [44+esp]
	mov	ecx,edx
	xor	edi,esi
	mov	esi,DWORD [12+esp]
	ror	edx,14
	add	ebx,edi
	mov	edi,DWORD [16+esp]
	xor	edx,ecx
	mov	DWORD [72+esp],ebx
	xor	esi,edi
	ror	edx,5
	and	esi,ecx
	mov	DWORD [8+esp],ecx
	xor	edx,ecx
	add	ebx,DWORD [20+esp]
	xor	edi,esi
	ror	edx,6
	mov	ecx,eax
	add	ebx,edi
	ror	ecx,9
	mov	esi,eax
	mov	edi,DWORD [28+esp]
	xor	ecx,eax
	mov	DWORD [24+esp],eax
	xor	eax,edi
	ror	ecx,11
	and	ebp,eax
	lea	edx,[2227730452+edx*1+ebx]
	xor	ecx,esi
	xor	ebp,edi
	mov	esi,DWORD [80+esp]
	ror	ecx,2
	add	ebp,edx
	add	edx,DWORD [4+esp]
	add	ebp,ecx
	mov	ecx,DWORD [68+esp]
	mov	ebx,esi
	ror	esi,11
	mov	edi,ecx
	ror	ecx,2
	xor	esi,ebx
	shr	ebx,3
	ror	esi,7
	xor	ecx,edi
	xor	ebx,esi
	ror	ecx,17
	add	ebx,DWORD [76+esp]
	shr	edi,10
	add	ebx,DWORD [48+esp]
	mov	esi,edx
	xor	edi,ecx
	mov	ecx,DWORD [8+esp]
	ror	edx,14
	add	ebx,edi
	mov	edi,DWORD [12+esp]
	xor	edx,esi
	mov	DWORD [76+esp],ebx
	xor	ecx,edi
	ror	edx,5
	and	ecx,esi
	mov	DWORD [4+esp],esi
	xor	edx,esi
	add	ebx,DWORD [16+esp]
	xor	edi,ecx
	ror	edx,6
	mov	esi,ebp
	add	ebx,edi
	ror	esi,9
	mov	ecx,ebp
	mov	edi,DWORD [24+esp]
	xor	esi,ebp
	mov	DWORD [20+esp],ebp
	xor	ebp,edi
	ror	esi,11
	and	eax,ebp
	lea	edx,[2361852424+edx*1+ebx]
	xor	esi,ecx
	xor	eax,edi
	mov	ecx,DWORD [84+esp]
	ror	esi,2
	add	eax,edx
	add	edx,DWORD [esp]
	add	eax,esi
	mov	esi,DWORD [72+esp]
	mov	ebx,ecx
	ror	ecx,11
	mov	edi,esi
	ror	esi,2
	xor	ecx,ebx
	shr	ebx,3
	ror	ecx,7
	xor	esi,edi
	xor	ebx,ecx
	ror	esi,17
	add	ebx,DWORD [80+esp]
	shr	edi,10
	add	ebx,DWORD [52+esp]
	mov	ecx,edx
	xor	edi,esi
	mov	esi,DWORD [4+esp]
	ror	edx,14
	add	ebx,edi
	mov	edi,DWORD [8+esp]
	xor	edx,ecx
	mov	DWORD [80+esp],ebx
	xor	esi,edi
	ror	edx,5
	and	esi,ecx
	mov	DWORD [esp],ecx
	xor	edx,ecx
	add	ebx,DWORD [12+esp]
	xor	edi,esi
	ror	edx,6
	mov	ecx,eax
	add	ebx,edi
	ror	ecx,9
	mov	esi,eax
	mov	edi,DWORD [20+esp]
	xor	ecx,eax
	mov	DWORD [16+esp],eax
	xor	eax,edi
	ror	ecx,11
	and	ebp,eax
	lea	edx,[2428436474+edx*1+ebx]
	xor	ecx,esi
	xor	ebp,edi
	mov	esi,DWORD [88+esp]
	ror	ecx,2
	add	ebp,edx
	add	edx,DWORD [28+esp]
	add	ebp,ecx
	mov	ecx,DWORD [76+esp]
	mov	ebx,esi
	ror	esi,11
	mov	edi,ecx
	ror	ecx,2
	xor	esi,ebx
	shr	ebx,3
	ror	esi,7
	xor	ecx,edi
	xor	ebx,esi
	ror	ecx,17
	add	ebx,DWORD [84+esp]
	shr	edi,10
	add	ebx,DWORD [56+esp]
	mov	esi,edx
	xor	edi,ecx
	mov	ecx,DWORD [esp]
	ror	edx,14
	add	ebx,edi
	mov	edi,DWORD [4+esp]
	xor	edx,esi
	mov	DWORD [84+esp],ebx
	xor	ecx,edi
	ror	edx,5
	and	ecx,esi
	mov	DWORD [28+esp],esi
	xor	edx,esi
	add	ebx,DWORD [8+esp]
	xor	edi,ecx
	ror	edx,6
	mov	esi,ebp
	add	ebx,edi
	ror	esi,9
	mov	ecx,ebp
	mov	edi,DWORD [16+esp]
	xor	esi,ebp
	mov	DWORD [12+esp],ebp
	xor	ebp,edi
	ror	esi,11
	and	eax,ebp
	lea	edx,[2756734187+edx*1+ebx]
	xor	esi,ecx
	xor	eax,edi
	mov	ecx,DWORD [92+esp]
	ror	esi,2
	add	eax,edx
	add	edx,DWORD [24+esp]
	add	eax,esi
	mov	esi,DWORD [80+esp]
	mov	ebx,ecx
	ror	ecx,11
	mov	edi,esi
	ror	esi,2
	xor	ecx,ebx
	shr	ebx,3
	ror	ecx,7
	xor	esi,edi
	xor	ebx,ecx
	ror	esi,17
	add	ebx,DWORD [88+esp]
	shr	edi,10
	add	ebx,DWORD [60+esp]
	mov	ecx,edx
	xor	edi,esi
	mov	esi,DWORD [28+esp]
	ror	edx,14
	add	ebx,edi
	mov	edi,DWORD [esp]
	xor	edx,ecx
	xor	esi,edi
	ror	edx,5
	and	esi,ecx
	mov	DWORD [24+esp],ecx
	xor	edx,ecx
	add	ebx,DWORD [4+esp]
	xor	edi,esi
	ror	edx,6
	mov	ecx,eax
	add	ebx,edi
	ror	ecx,9
	mov	esi,eax
	mov	edi,DWORD [12+esp]
	xor	ecx,eax
	mov	DWORD [8+esp],eax
	xor	eax,edi
	ror	ecx,11
	and	ebp,eax
	lea	edx,[3204031479+edx*1+ebx]
	xor	ecx,esi
	xor	ebp,edi
	mov	esi,DWORD [32+esp]
	ror	ecx,2
	add	ebp,edx
	add	edx,DWORD [20+esp]
	add	ebp,ecx
	mov	ecx,DWORD [84+esp]
	mov	ebx,esi
	ror	esi,11
	mov	edi,ecx
	ror	ecx,2
	xor	esi,ebx
	shr	ebx,3
	ror	esi,7
	xor	ecx,edi
	xor	ebx,esi
	ror	ecx,17
	add	ebx,DWORD [92+esp]
	shr	edi,10
	add	ebx,DWORD [64+esp]
	mov	esi,edx
	xor	edi,ecx
	mov	ecx,DWORD [24+esp]
	ror	edx,14
	add	ebx,edi
	mov	edi,DWORD [28+esp]
	xor	edx,esi
	xor	ecx,edi
	ror	edx,5
	and	ecx,esi
	mov	DWORD [20+esp],esi
	xor	edx,esi
	add	ebx,DWORD [esp]
	xor	edi,ecx
	ror	edx,6
	mov	esi,ebp
	add	ebx,edi
	ror	esi,9
	mov	ecx,ebp
	mov	edi,DWORD [8+esp]
	xor	esi,ebp
	mov	DWORD [4+esp],ebp
	xor	ebp,edi
	ror	esi,11
	and	eax,ebp
	lea	edx,[3329325298+edx*1+ebx]
	xor	esi,ecx
	xor	eax,edi
	ror	esi,2
	add	eax,edx
	add	edx,DWORD [16+esp]
	add	eax,esi
	mov	esi,DWORD [96+esp]
	xor	ebp,edi
	mov	ecx,DWORD [12+esp]
	add	eax,DWORD [esi]
	add	ebp,DWORD [4+esi]
	add	edi,DWORD [8+esi]
	add	ecx,DWORD [12+esi]
	mov	DWORD [esi],eax
	mov	DWORD [4+esi],ebp
	mov	DWORD [8+esi],edi
	mov	DWORD [12+esi],ecx
	mov	DWORD [4+esp],ebp
	xor	ebp,edi
	mov	DWORD [8+esp],edi
	mov	DWORD [12+esp],ecx
	mov	edi,DWORD [20+esp]
	mov	ebx,DWORD [24+esp]
	mov	ecx,DWORD [28+esp]
	add	edx,DWORD [16+esi]
	add	edi,DWORD [20+esi]
	add	ebx,DWORD [24+esi]
	add	ecx,DWORD [28+esi]
	mov	DWORD [16+esi],edx
	mov	DWORD [20+esi],edi
	mov	DWORD [24+esi],ebx
	mov	DWORD [28+esi],ecx
	mov	DWORD [20+esp],edi
	mov	edi,DWORD [100+esp]
	mov	DWORD [24+esp],ebx
	mov	DWORD [28+esp],ecx
	cmp	edi,DWORD [104+esp]
	jb	NEAR L$009grand_loop
	mov	esp,DWORD [108+esp]
	pop	edi
	pop	esi
	pop	ebx
	pop	ebp
	ret
segment	.bss
common	_OPENSSL_ia32cap_P 16
