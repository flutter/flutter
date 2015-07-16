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
global	_sha512_block_data_order
align	16
_sha512_block_data_order:
L$_sha512_block_data_order_begin:
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
	lea	ebp,[(L$001K512-L$000pic_point)+ebp]
	sub	esp,16
	and	esp,-64
	shl	eax,7
	add	eax,edi
	mov	DWORD [esp],esi
	mov	DWORD [4+esp],edi
	mov	DWORD [8+esp],eax
	mov	DWORD [12+esp],ebx
align	16
L$002loop_x86:
	mov	eax,DWORD [edi]
	mov	ebx,DWORD [4+edi]
	mov	ecx,DWORD [8+edi]
	mov	edx,DWORD [12+edi]
	bswap	eax
	bswap	ebx
	bswap	ecx
	bswap	edx
	push	eax
	push	ebx
	push	ecx
	push	edx
	mov	eax,DWORD [16+edi]
	mov	ebx,DWORD [20+edi]
	mov	ecx,DWORD [24+edi]
	mov	edx,DWORD [28+edi]
	bswap	eax
	bswap	ebx
	bswap	ecx
	bswap	edx
	push	eax
	push	ebx
	push	ecx
	push	edx
	mov	eax,DWORD [32+edi]
	mov	ebx,DWORD [36+edi]
	mov	ecx,DWORD [40+edi]
	mov	edx,DWORD [44+edi]
	bswap	eax
	bswap	ebx
	bswap	ecx
	bswap	edx
	push	eax
	push	ebx
	push	ecx
	push	edx
	mov	eax,DWORD [48+edi]
	mov	ebx,DWORD [52+edi]
	mov	ecx,DWORD [56+edi]
	mov	edx,DWORD [60+edi]
	bswap	eax
	bswap	ebx
	bswap	ecx
	bswap	edx
	push	eax
	push	ebx
	push	ecx
	push	edx
	mov	eax,DWORD [64+edi]
	mov	ebx,DWORD [68+edi]
	mov	ecx,DWORD [72+edi]
	mov	edx,DWORD [76+edi]
	bswap	eax
	bswap	ebx
	bswap	ecx
	bswap	edx
	push	eax
	push	ebx
	push	ecx
	push	edx
	mov	eax,DWORD [80+edi]
	mov	ebx,DWORD [84+edi]
	mov	ecx,DWORD [88+edi]
	mov	edx,DWORD [92+edi]
	bswap	eax
	bswap	ebx
	bswap	ecx
	bswap	edx
	push	eax
	push	ebx
	push	ecx
	push	edx
	mov	eax,DWORD [96+edi]
	mov	ebx,DWORD [100+edi]
	mov	ecx,DWORD [104+edi]
	mov	edx,DWORD [108+edi]
	bswap	eax
	bswap	ebx
	bswap	ecx
	bswap	edx
	push	eax
	push	ebx
	push	ecx
	push	edx
	mov	eax,DWORD [112+edi]
	mov	ebx,DWORD [116+edi]
	mov	ecx,DWORD [120+edi]
	mov	edx,DWORD [124+edi]
	bswap	eax
	bswap	ebx
	bswap	ecx
	bswap	edx
	push	eax
	push	ebx
	push	ecx
	push	edx
	add	edi,128
	sub	esp,72
	mov	DWORD [204+esp],edi
	lea	edi,[8+esp]
	mov	ecx,16
dd	2784229001
align	16
L$00300_15_x86:
	mov	ecx,DWORD [40+esp]
	mov	edx,DWORD [44+esp]
	mov	esi,ecx
	shr	ecx,9
	mov	edi,edx
	shr	edx,9
	mov	ebx,ecx
	shl	esi,14
	mov	eax,edx
	shl	edi,14
	xor	ebx,esi
	shr	ecx,5
	xor	eax,edi
	shr	edx,5
	xor	eax,ecx
	shl	esi,4
	xor	ebx,edx
	shl	edi,4
	xor	ebx,esi
	shr	ecx,4
	xor	eax,edi
	shr	edx,4
	xor	eax,ecx
	shl	esi,5
	xor	ebx,edx
	shl	edi,5
	xor	eax,esi
	xor	ebx,edi
	mov	ecx,DWORD [48+esp]
	mov	edx,DWORD [52+esp]
	mov	esi,DWORD [56+esp]
	mov	edi,DWORD [60+esp]
	add	eax,DWORD [64+esp]
	adc	ebx,DWORD [68+esp]
	xor	ecx,esi
	xor	edx,edi
	and	ecx,DWORD [40+esp]
	and	edx,DWORD [44+esp]
	add	eax,DWORD [192+esp]
	adc	ebx,DWORD [196+esp]
	xor	ecx,esi
	xor	edx,edi
	mov	esi,DWORD [ebp]
	mov	edi,DWORD [4+ebp]
	add	eax,ecx
	adc	ebx,edx
	mov	ecx,DWORD [32+esp]
	mov	edx,DWORD [36+esp]
	add	eax,esi
	adc	ebx,edi
	mov	DWORD [esp],eax
	mov	DWORD [4+esp],ebx
	add	eax,ecx
	adc	ebx,edx
	mov	ecx,DWORD [8+esp]
	mov	edx,DWORD [12+esp]
	mov	DWORD [32+esp],eax
	mov	DWORD [36+esp],ebx
	mov	esi,ecx
	shr	ecx,2
	mov	edi,edx
	shr	edx,2
	mov	ebx,ecx
	shl	esi,4
	mov	eax,edx
	shl	edi,4
	xor	ebx,esi
	shr	ecx,5
	xor	eax,edi
	shr	edx,5
	xor	ebx,ecx
	shl	esi,21
	xor	eax,edx
	shl	edi,21
	xor	eax,esi
	shr	ecx,21
	xor	ebx,edi
	shr	edx,21
	xor	eax,ecx
	shl	esi,5
	xor	ebx,edx
	shl	edi,5
	xor	eax,esi
	xor	ebx,edi
	mov	ecx,DWORD [8+esp]
	mov	edx,DWORD [12+esp]
	mov	esi,DWORD [16+esp]
	mov	edi,DWORD [20+esp]
	add	eax,DWORD [esp]
	adc	ebx,DWORD [4+esp]
	or	ecx,esi
	or	edx,edi
	and	ecx,DWORD [24+esp]
	and	edx,DWORD [28+esp]
	and	esi,DWORD [8+esp]
	and	edi,DWORD [12+esp]
	or	ecx,esi
	or	edx,edi
	add	eax,ecx
	adc	ebx,edx
	mov	DWORD [esp],eax
	mov	DWORD [4+esp],ebx
	mov	dl,BYTE [ebp]
	sub	esp,8
	lea	ebp,[8+ebp]
	cmp	dl,148
	jne	NEAR L$00300_15_x86
align	16
L$00416_79_x86:
	mov	ecx,DWORD [312+esp]
	mov	edx,DWORD [316+esp]
	mov	esi,ecx
	shr	ecx,1
	mov	edi,edx
	shr	edx,1
	mov	eax,ecx
	shl	esi,24
	mov	ebx,edx
	shl	edi,24
	xor	ebx,esi
	shr	ecx,6
	xor	eax,edi
	shr	edx,6
	xor	eax,ecx
	shl	esi,7
	xor	ebx,edx
	shl	edi,1
	xor	ebx,esi
	shr	ecx,1
	xor	eax,edi
	shr	edx,1
	xor	eax,ecx
	shl	edi,6
	xor	ebx,edx
	xor	eax,edi
	mov	DWORD [esp],eax
	mov	DWORD [4+esp],ebx
	mov	ecx,DWORD [208+esp]
	mov	edx,DWORD [212+esp]
	mov	esi,ecx
	shr	ecx,6
	mov	edi,edx
	shr	edx,6
	mov	eax,ecx
	shl	esi,3
	mov	ebx,edx
	shl	edi,3
	xor	eax,esi
	shr	ecx,13
	xor	ebx,edi
	shr	edx,13
	xor	eax,ecx
	shl	esi,10
	xor	ebx,edx
	shl	edi,10
	xor	ebx,esi
	shr	ecx,10
	xor	eax,edi
	shr	edx,10
	xor	ebx,ecx
	shl	edi,13
	xor	eax,edx
	xor	eax,edi
	mov	ecx,DWORD [320+esp]
	mov	edx,DWORD [324+esp]
	add	eax,DWORD [esp]
	adc	ebx,DWORD [4+esp]
	mov	esi,DWORD [248+esp]
	mov	edi,DWORD [252+esp]
	add	eax,ecx
	adc	ebx,edx
	add	eax,esi
	adc	ebx,edi
	mov	DWORD [192+esp],eax
	mov	DWORD [196+esp],ebx
	mov	ecx,DWORD [40+esp]
	mov	edx,DWORD [44+esp]
	mov	esi,ecx
	shr	ecx,9
	mov	edi,edx
	shr	edx,9
	mov	ebx,ecx
	shl	esi,14
	mov	eax,edx
	shl	edi,14
	xor	ebx,esi
	shr	ecx,5
	xor	eax,edi
	shr	edx,5
	xor	eax,ecx
	shl	esi,4
	xor	ebx,edx
	shl	edi,4
	xor	ebx,esi
	shr	ecx,4
	xor	eax,edi
	shr	edx,4
	xor	eax,ecx
	shl	esi,5
	xor	ebx,edx
	shl	edi,5
	xor	eax,esi
	xor	ebx,edi
	mov	ecx,DWORD [48+esp]
	mov	edx,DWORD [52+esp]
	mov	esi,DWORD [56+esp]
	mov	edi,DWORD [60+esp]
	add	eax,DWORD [64+esp]
	adc	ebx,DWORD [68+esp]
	xor	ecx,esi
	xor	edx,edi
	and	ecx,DWORD [40+esp]
	and	edx,DWORD [44+esp]
	add	eax,DWORD [192+esp]
	adc	ebx,DWORD [196+esp]
	xor	ecx,esi
	xor	edx,edi
	mov	esi,DWORD [ebp]
	mov	edi,DWORD [4+ebp]
	add	eax,ecx
	adc	ebx,edx
	mov	ecx,DWORD [32+esp]
	mov	edx,DWORD [36+esp]
	add	eax,esi
	adc	ebx,edi
	mov	DWORD [esp],eax
	mov	DWORD [4+esp],ebx
	add	eax,ecx
	adc	ebx,edx
	mov	ecx,DWORD [8+esp]
	mov	edx,DWORD [12+esp]
	mov	DWORD [32+esp],eax
	mov	DWORD [36+esp],ebx
	mov	esi,ecx
	shr	ecx,2
	mov	edi,edx
	shr	edx,2
	mov	ebx,ecx
	shl	esi,4
	mov	eax,edx
	shl	edi,4
	xor	ebx,esi
	shr	ecx,5
	xor	eax,edi
	shr	edx,5
	xor	ebx,ecx
	shl	esi,21
	xor	eax,edx
	shl	edi,21
	xor	eax,esi
	shr	ecx,21
	xor	ebx,edi
	shr	edx,21
	xor	eax,ecx
	shl	esi,5
	xor	ebx,edx
	shl	edi,5
	xor	eax,esi
	xor	ebx,edi
	mov	ecx,DWORD [8+esp]
	mov	edx,DWORD [12+esp]
	mov	esi,DWORD [16+esp]
	mov	edi,DWORD [20+esp]
	add	eax,DWORD [esp]
	adc	ebx,DWORD [4+esp]
	or	ecx,esi
	or	edx,edi
	and	ecx,DWORD [24+esp]
	and	edx,DWORD [28+esp]
	and	esi,DWORD [8+esp]
	and	edi,DWORD [12+esp]
	or	ecx,esi
	or	edx,edi
	add	eax,ecx
	adc	ebx,edx
	mov	DWORD [esp],eax
	mov	DWORD [4+esp],ebx
	mov	dl,BYTE [ebp]
	sub	esp,8
	lea	ebp,[8+ebp]
	cmp	dl,23
	jne	NEAR L$00416_79_x86
	mov	esi,DWORD [840+esp]
	mov	edi,DWORD [844+esp]
	mov	eax,DWORD [esi]
	mov	ebx,DWORD [4+esi]
	mov	ecx,DWORD [8+esi]
	mov	edx,DWORD [12+esi]
	add	eax,DWORD [8+esp]
	adc	ebx,DWORD [12+esp]
	mov	DWORD [esi],eax
	mov	DWORD [4+esi],ebx
	add	ecx,DWORD [16+esp]
	adc	edx,DWORD [20+esp]
	mov	DWORD [8+esi],ecx
	mov	DWORD [12+esi],edx
	mov	eax,DWORD [16+esi]
	mov	ebx,DWORD [20+esi]
	mov	ecx,DWORD [24+esi]
	mov	edx,DWORD [28+esi]
	add	eax,DWORD [24+esp]
	adc	ebx,DWORD [28+esp]
	mov	DWORD [16+esi],eax
	mov	DWORD [20+esi],ebx
	add	ecx,DWORD [32+esp]
	adc	edx,DWORD [36+esp]
	mov	DWORD [24+esi],ecx
	mov	DWORD [28+esi],edx
	mov	eax,DWORD [32+esi]
	mov	ebx,DWORD [36+esi]
	mov	ecx,DWORD [40+esi]
	mov	edx,DWORD [44+esi]
	add	eax,DWORD [40+esp]
	adc	ebx,DWORD [44+esp]
	mov	DWORD [32+esi],eax
	mov	DWORD [36+esi],ebx
	add	ecx,DWORD [48+esp]
	adc	edx,DWORD [52+esp]
	mov	DWORD [40+esi],ecx
	mov	DWORD [44+esi],edx
	mov	eax,DWORD [48+esi]
	mov	ebx,DWORD [52+esi]
	mov	ecx,DWORD [56+esi]
	mov	edx,DWORD [60+esi]
	add	eax,DWORD [56+esp]
	adc	ebx,DWORD [60+esp]
	mov	DWORD [48+esi],eax
	mov	DWORD [52+esi],ebx
	add	ecx,DWORD [64+esp]
	adc	edx,DWORD [68+esp]
	mov	DWORD [56+esi],ecx
	mov	DWORD [60+esi],edx
	add	esp,840
	sub	ebp,640
	cmp	edi,DWORD [8+esp]
	jb	NEAR L$002loop_x86
	mov	esp,DWORD [12+esp]
	pop	edi
	pop	esi
	pop	ebx
	pop	ebp
	ret
align	64
L$001K512:
dd	3609767458,1116352408
dd	602891725,1899447441
dd	3964484399,3049323471
dd	2173295548,3921009573
dd	4081628472,961987163
dd	3053834265,1508970993
dd	2937671579,2453635748
dd	3664609560,2870763221
dd	2734883394,3624381080
dd	1164996542,310598401
dd	1323610764,607225278
dd	3590304994,1426881987
dd	4068182383,1925078388
dd	991336113,2162078206
dd	633803317,2614888103
dd	3479774868,3248222580
dd	2666613458,3835390401
dd	944711139,4022224774
dd	2341262773,264347078
dd	2007800933,604807628
dd	1495990901,770255983
dd	1856431235,1249150122
dd	3175218132,1555081692
dd	2198950837,1996064986
dd	3999719339,2554220882
dd	766784016,2821834349
dd	2566594879,2952996808
dd	3203337956,3210313671
dd	1034457026,3336571891
dd	2466948901,3584528711
dd	3758326383,113926993
dd	168717936,338241895
dd	1188179964,666307205
dd	1546045734,773529912
dd	1522805485,1294757372
dd	2643833823,1396182291
dd	2343527390,1695183700
dd	1014477480,1986661051
dd	1206759142,2177026350
dd	344077627,2456956037
dd	1290863460,2730485921
dd	3158454273,2820302411
dd	3505952657,3259730800
dd	106217008,3345764771
dd	3606008344,3516065817
dd	1432725776,3600352804
dd	1467031594,4094571909
dd	851169720,275423344
dd	3100823752,430227734
dd	1363258195,506948616
dd	3750685593,659060556
dd	3785050280,883997877
dd	3318307427,958139571
dd	3812723403,1322822218
dd	2003034995,1537002063
dd	3602036899,1747873779
dd	1575990012,1955562222
dd	1125592928,2024104815
dd	2716904306,2227730452
dd	442776044,2361852424
dd	593698344,2428436474
dd	3733110249,2756734187
dd	2999351573,3204031479
dd	3815920427,3329325298
dd	3928383900,3391569614
dd	566280711,3515267271
dd	3454069534,3940187606
dd	4000239992,4118630271
dd	1914138554,116418474
dd	2731055270,174292421
dd	3203993006,289380356
dd	320620315,460393269
dd	587496836,685471733
dd	1086792851,852142971
dd	365543100,1017036298
dd	2618297676,1126000580
dd	3409855158,1288033470
dd	4234509866,1501505948
dd	987167468,1607167915
dd	1246189591,1816402316
dd	67438087,66051
dd	202182159,134810123
db	83,72,65,53,49,50,32,98,108,111,99,107,32,116,114,97
db	110,115,102,111,114,109,32,102,111,114,32,120,56,54,44,32
db	67,82,89,80,84,79,71,65,77,83,32,98,121,32,60,97
db	112,112,114,111,64,111,112,101,110,115,115,108,46,111,114,103
db	62,0
