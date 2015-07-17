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
global	_sha1_block_data_order
align	16
_sha1_block_data_order:
L$_sha1_block_data_order_begin:
	push	ebp
	push	ebx
	push	esi
	push	edi
	call	L$000pic_point
L$000pic_point:
	pop	ebp
	lea	esi,[_OPENSSL_ia32cap_P]
	lea	ebp,[(L$K_XX_XX-L$000pic_point)+ebp]
	mov	eax,DWORD [esi]
	mov	edx,DWORD [4+esi]
	test	edx,512
	jz	NEAR L$001x86
	mov	ecx,DWORD [8+esi]
	test	eax,16777216
	jz	NEAR L$001x86
	test	ecx,536870912
	jnz	NEAR L$shaext_shortcut
	jmp	NEAR L$ssse3_shortcut
align	16
L$001x86:
	mov	ebp,DWORD [20+esp]
	mov	esi,DWORD [24+esp]
	mov	eax,DWORD [28+esp]
	sub	esp,76
	shl	eax,6
	add	eax,esi
	mov	DWORD [104+esp],eax
	mov	edi,DWORD [16+ebp]
	jmp	NEAR L$002loop
align	16
L$002loop:
	mov	eax,DWORD [esi]
	mov	ebx,DWORD [4+esi]
	mov	ecx,DWORD [8+esi]
	mov	edx,DWORD [12+esi]
	bswap	eax
	bswap	ebx
	bswap	ecx
	bswap	edx
	mov	DWORD [esp],eax
	mov	DWORD [4+esp],ebx
	mov	DWORD [8+esp],ecx
	mov	DWORD [12+esp],edx
	mov	eax,DWORD [16+esi]
	mov	ebx,DWORD [20+esi]
	mov	ecx,DWORD [24+esi]
	mov	edx,DWORD [28+esi]
	bswap	eax
	bswap	ebx
	bswap	ecx
	bswap	edx
	mov	DWORD [16+esp],eax
	mov	DWORD [20+esp],ebx
	mov	DWORD [24+esp],ecx
	mov	DWORD [28+esp],edx
	mov	eax,DWORD [32+esi]
	mov	ebx,DWORD [36+esi]
	mov	ecx,DWORD [40+esi]
	mov	edx,DWORD [44+esi]
	bswap	eax
	bswap	ebx
	bswap	ecx
	bswap	edx
	mov	DWORD [32+esp],eax
	mov	DWORD [36+esp],ebx
	mov	DWORD [40+esp],ecx
	mov	DWORD [44+esp],edx
	mov	eax,DWORD [48+esi]
	mov	ebx,DWORD [52+esi]
	mov	ecx,DWORD [56+esi]
	mov	edx,DWORD [60+esi]
	bswap	eax
	bswap	ebx
	bswap	ecx
	bswap	edx
	mov	DWORD [48+esp],eax
	mov	DWORD [52+esp],ebx
	mov	DWORD [56+esp],ecx
	mov	DWORD [60+esp],edx
	mov	DWORD [100+esp],esi
	mov	eax,DWORD [ebp]
	mov	ebx,DWORD [4+ebp]
	mov	ecx,DWORD [8+ebp]
	mov	edx,DWORD [12+ebp]
	; 00_15 0
	mov	esi,ecx
	mov	ebp,eax
	rol	ebp,5
	xor	esi,edx
	add	ebp,edi
	mov	edi,DWORD [esp]
	and	esi,ebx
	ror	ebx,2
	xor	esi,edx
	lea	ebp,[1518500249+edi*1+ebp]
	add	ebp,esi
	; 00_15 1
	mov	edi,ebx
	mov	esi,ebp
	rol	ebp,5
	xor	edi,ecx
	add	ebp,edx
	mov	edx,DWORD [4+esp]
	and	edi,eax
	ror	eax,2
	xor	edi,ecx
	lea	ebp,[1518500249+edx*1+ebp]
	add	ebp,edi
	; 00_15 2
	mov	edx,eax
	mov	edi,ebp
	rol	ebp,5
	xor	edx,ebx
	add	ebp,ecx
	mov	ecx,DWORD [8+esp]
	and	edx,esi
	ror	esi,2
	xor	edx,ebx
	lea	ebp,[1518500249+ecx*1+ebp]
	add	ebp,edx
	; 00_15 3
	mov	ecx,esi
	mov	edx,ebp
	rol	ebp,5
	xor	ecx,eax
	add	ebp,ebx
	mov	ebx,DWORD [12+esp]
	and	ecx,edi
	ror	edi,2
	xor	ecx,eax
	lea	ebp,[1518500249+ebx*1+ebp]
	add	ebp,ecx
	; 00_15 4
	mov	ebx,edi
	mov	ecx,ebp
	rol	ebp,5
	xor	ebx,esi
	add	ebp,eax
	mov	eax,DWORD [16+esp]
	and	ebx,edx
	ror	edx,2
	xor	ebx,esi
	lea	ebp,[1518500249+eax*1+ebp]
	add	ebp,ebx
	; 00_15 5
	mov	eax,edx
	mov	ebx,ebp
	rol	ebp,5
	xor	eax,edi
	add	ebp,esi
	mov	esi,DWORD [20+esp]
	and	eax,ecx
	ror	ecx,2
	xor	eax,edi
	lea	ebp,[1518500249+esi*1+ebp]
	add	ebp,eax
	; 00_15 6
	mov	esi,ecx
	mov	eax,ebp
	rol	ebp,5
	xor	esi,edx
	add	ebp,edi
	mov	edi,DWORD [24+esp]
	and	esi,ebx
	ror	ebx,2
	xor	esi,edx
	lea	ebp,[1518500249+edi*1+ebp]
	add	ebp,esi
	; 00_15 7
	mov	edi,ebx
	mov	esi,ebp
	rol	ebp,5
	xor	edi,ecx
	add	ebp,edx
	mov	edx,DWORD [28+esp]
	and	edi,eax
	ror	eax,2
	xor	edi,ecx
	lea	ebp,[1518500249+edx*1+ebp]
	add	ebp,edi
	; 00_15 8
	mov	edx,eax
	mov	edi,ebp
	rol	ebp,5
	xor	edx,ebx
	add	ebp,ecx
	mov	ecx,DWORD [32+esp]
	and	edx,esi
	ror	esi,2
	xor	edx,ebx
	lea	ebp,[1518500249+ecx*1+ebp]
	add	ebp,edx
	; 00_15 9
	mov	ecx,esi
	mov	edx,ebp
	rol	ebp,5
	xor	ecx,eax
	add	ebp,ebx
	mov	ebx,DWORD [36+esp]
	and	ecx,edi
	ror	edi,2
	xor	ecx,eax
	lea	ebp,[1518500249+ebx*1+ebp]
	add	ebp,ecx
	; 00_15 10
	mov	ebx,edi
	mov	ecx,ebp
	rol	ebp,5
	xor	ebx,esi
	add	ebp,eax
	mov	eax,DWORD [40+esp]
	and	ebx,edx
	ror	edx,2
	xor	ebx,esi
	lea	ebp,[1518500249+eax*1+ebp]
	add	ebp,ebx
	; 00_15 11
	mov	eax,edx
	mov	ebx,ebp
	rol	ebp,5
	xor	eax,edi
	add	ebp,esi
	mov	esi,DWORD [44+esp]
	and	eax,ecx
	ror	ecx,2
	xor	eax,edi
	lea	ebp,[1518500249+esi*1+ebp]
	add	ebp,eax
	; 00_15 12
	mov	esi,ecx
	mov	eax,ebp
	rol	ebp,5
	xor	esi,edx
	add	ebp,edi
	mov	edi,DWORD [48+esp]
	and	esi,ebx
	ror	ebx,2
	xor	esi,edx
	lea	ebp,[1518500249+edi*1+ebp]
	add	ebp,esi
	; 00_15 13
	mov	edi,ebx
	mov	esi,ebp
	rol	ebp,5
	xor	edi,ecx
	add	ebp,edx
	mov	edx,DWORD [52+esp]
	and	edi,eax
	ror	eax,2
	xor	edi,ecx
	lea	ebp,[1518500249+edx*1+ebp]
	add	ebp,edi
	; 00_15 14
	mov	edx,eax
	mov	edi,ebp
	rol	ebp,5
	xor	edx,ebx
	add	ebp,ecx
	mov	ecx,DWORD [56+esp]
	and	edx,esi
	ror	esi,2
	xor	edx,ebx
	lea	ebp,[1518500249+ecx*1+ebp]
	add	ebp,edx
	; 00_15 15
	mov	ecx,esi
	mov	edx,ebp
	rol	ebp,5
	xor	ecx,eax
	add	ebp,ebx
	mov	ebx,DWORD [60+esp]
	and	ecx,edi
	ror	edi,2
	xor	ecx,eax
	lea	ebp,[1518500249+ebx*1+ebp]
	mov	ebx,DWORD [esp]
	add	ecx,ebp
	; 16_19 16
	mov	ebp,edi
	xor	ebx,DWORD [8+esp]
	xor	ebp,esi
	xor	ebx,DWORD [32+esp]
	and	ebp,edx
	xor	ebx,DWORD [52+esp]
	rol	ebx,1
	xor	ebp,esi
	add	eax,ebp
	mov	ebp,ecx
	ror	edx,2
	mov	DWORD [esp],ebx
	rol	ebp,5
	lea	ebx,[1518500249+eax*1+ebx]
	mov	eax,DWORD [4+esp]
	add	ebx,ebp
	; 16_19 17
	mov	ebp,edx
	xor	eax,DWORD [12+esp]
	xor	ebp,edi
	xor	eax,DWORD [36+esp]
	and	ebp,ecx
	xor	eax,DWORD [56+esp]
	rol	eax,1
	xor	ebp,edi
	add	esi,ebp
	mov	ebp,ebx
	ror	ecx,2
	mov	DWORD [4+esp],eax
	rol	ebp,5
	lea	eax,[1518500249+esi*1+eax]
	mov	esi,DWORD [8+esp]
	add	eax,ebp
	; 16_19 18
	mov	ebp,ecx
	xor	esi,DWORD [16+esp]
	xor	ebp,edx
	xor	esi,DWORD [40+esp]
	and	ebp,ebx
	xor	esi,DWORD [60+esp]
	rol	esi,1
	xor	ebp,edx
	add	edi,ebp
	mov	ebp,eax
	ror	ebx,2
	mov	DWORD [8+esp],esi
	rol	ebp,5
	lea	esi,[1518500249+edi*1+esi]
	mov	edi,DWORD [12+esp]
	add	esi,ebp
	; 16_19 19
	mov	ebp,ebx
	xor	edi,DWORD [20+esp]
	xor	ebp,ecx
	xor	edi,DWORD [44+esp]
	and	ebp,eax
	xor	edi,DWORD [esp]
	rol	edi,1
	xor	ebp,ecx
	add	edx,ebp
	mov	ebp,esi
	ror	eax,2
	mov	DWORD [12+esp],edi
	rol	ebp,5
	lea	edi,[1518500249+edx*1+edi]
	mov	edx,DWORD [16+esp]
	add	edi,ebp
	; 20_39 20
	mov	ebp,esi
	xor	edx,DWORD [24+esp]
	xor	ebp,eax
	xor	edx,DWORD [48+esp]
	xor	ebp,ebx
	xor	edx,DWORD [4+esp]
	rol	edx,1
	add	ecx,ebp
	ror	esi,2
	mov	ebp,edi
	rol	ebp,5
	mov	DWORD [16+esp],edx
	lea	edx,[1859775393+ecx*1+edx]
	mov	ecx,DWORD [20+esp]
	add	edx,ebp
	; 20_39 21
	mov	ebp,edi
	xor	ecx,DWORD [28+esp]
	xor	ebp,esi
	xor	ecx,DWORD [52+esp]
	xor	ebp,eax
	xor	ecx,DWORD [8+esp]
	rol	ecx,1
	add	ebx,ebp
	ror	edi,2
	mov	ebp,edx
	rol	ebp,5
	mov	DWORD [20+esp],ecx
	lea	ecx,[1859775393+ebx*1+ecx]
	mov	ebx,DWORD [24+esp]
	add	ecx,ebp
	; 20_39 22
	mov	ebp,edx
	xor	ebx,DWORD [32+esp]
	xor	ebp,edi
	xor	ebx,DWORD [56+esp]
	xor	ebp,esi
	xor	ebx,DWORD [12+esp]
	rol	ebx,1
	add	eax,ebp
	ror	edx,2
	mov	ebp,ecx
	rol	ebp,5
	mov	DWORD [24+esp],ebx
	lea	ebx,[1859775393+eax*1+ebx]
	mov	eax,DWORD [28+esp]
	add	ebx,ebp
	; 20_39 23
	mov	ebp,ecx
	xor	eax,DWORD [36+esp]
	xor	ebp,edx
	xor	eax,DWORD [60+esp]
	xor	ebp,edi
	xor	eax,DWORD [16+esp]
	rol	eax,1
	add	esi,ebp
	ror	ecx,2
	mov	ebp,ebx
	rol	ebp,5
	mov	DWORD [28+esp],eax
	lea	eax,[1859775393+esi*1+eax]
	mov	esi,DWORD [32+esp]
	add	eax,ebp
	; 20_39 24
	mov	ebp,ebx
	xor	esi,DWORD [40+esp]
	xor	ebp,ecx
	xor	esi,DWORD [esp]
	xor	ebp,edx
	xor	esi,DWORD [20+esp]
	rol	esi,1
	add	edi,ebp
	ror	ebx,2
	mov	ebp,eax
	rol	ebp,5
	mov	DWORD [32+esp],esi
	lea	esi,[1859775393+edi*1+esi]
	mov	edi,DWORD [36+esp]
	add	esi,ebp
	; 20_39 25
	mov	ebp,eax
	xor	edi,DWORD [44+esp]
	xor	ebp,ebx
	xor	edi,DWORD [4+esp]
	xor	ebp,ecx
	xor	edi,DWORD [24+esp]
	rol	edi,1
	add	edx,ebp
	ror	eax,2
	mov	ebp,esi
	rol	ebp,5
	mov	DWORD [36+esp],edi
	lea	edi,[1859775393+edx*1+edi]
	mov	edx,DWORD [40+esp]
	add	edi,ebp
	; 20_39 26
	mov	ebp,esi
	xor	edx,DWORD [48+esp]
	xor	ebp,eax
	xor	edx,DWORD [8+esp]
	xor	ebp,ebx
	xor	edx,DWORD [28+esp]
	rol	edx,1
	add	ecx,ebp
	ror	esi,2
	mov	ebp,edi
	rol	ebp,5
	mov	DWORD [40+esp],edx
	lea	edx,[1859775393+ecx*1+edx]
	mov	ecx,DWORD [44+esp]
	add	edx,ebp
	; 20_39 27
	mov	ebp,edi
	xor	ecx,DWORD [52+esp]
	xor	ebp,esi
	xor	ecx,DWORD [12+esp]
	xor	ebp,eax
	xor	ecx,DWORD [32+esp]
	rol	ecx,1
	add	ebx,ebp
	ror	edi,2
	mov	ebp,edx
	rol	ebp,5
	mov	DWORD [44+esp],ecx
	lea	ecx,[1859775393+ebx*1+ecx]
	mov	ebx,DWORD [48+esp]
	add	ecx,ebp
	; 20_39 28
	mov	ebp,edx
	xor	ebx,DWORD [56+esp]
	xor	ebp,edi
	xor	ebx,DWORD [16+esp]
	xor	ebp,esi
	xor	ebx,DWORD [36+esp]
	rol	ebx,1
	add	eax,ebp
	ror	edx,2
	mov	ebp,ecx
	rol	ebp,5
	mov	DWORD [48+esp],ebx
	lea	ebx,[1859775393+eax*1+ebx]
	mov	eax,DWORD [52+esp]
	add	ebx,ebp
	; 20_39 29
	mov	ebp,ecx
	xor	eax,DWORD [60+esp]
	xor	ebp,edx
	xor	eax,DWORD [20+esp]
	xor	ebp,edi
	xor	eax,DWORD [40+esp]
	rol	eax,1
	add	esi,ebp
	ror	ecx,2
	mov	ebp,ebx
	rol	ebp,5
	mov	DWORD [52+esp],eax
	lea	eax,[1859775393+esi*1+eax]
	mov	esi,DWORD [56+esp]
	add	eax,ebp
	; 20_39 30
	mov	ebp,ebx
	xor	esi,DWORD [esp]
	xor	ebp,ecx
	xor	esi,DWORD [24+esp]
	xor	ebp,edx
	xor	esi,DWORD [44+esp]
	rol	esi,1
	add	edi,ebp
	ror	ebx,2
	mov	ebp,eax
	rol	ebp,5
	mov	DWORD [56+esp],esi
	lea	esi,[1859775393+edi*1+esi]
	mov	edi,DWORD [60+esp]
	add	esi,ebp
	; 20_39 31
	mov	ebp,eax
	xor	edi,DWORD [4+esp]
	xor	ebp,ebx
	xor	edi,DWORD [28+esp]
	xor	ebp,ecx
	xor	edi,DWORD [48+esp]
	rol	edi,1
	add	edx,ebp
	ror	eax,2
	mov	ebp,esi
	rol	ebp,5
	mov	DWORD [60+esp],edi
	lea	edi,[1859775393+edx*1+edi]
	mov	edx,DWORD [esp]
	add	edi,ebp
	; 20_39 32
	mov	ebp,esi
	xor	edx,DWORD [8+esp]
	xor	ebp,eax
	xor	edx,DWORD [32+esp]
	xor	ebp,ebx
	xor	edx,DWORD [52+esp]
	rol	edx,1
	add	ecx,ebp
	ror	esi,2
	mov	ebp,edi
	rol	ebp,5
	mov	DWORD [esp],edx
	lea	edx,[1859775393+ecx*1+edx]
	mov	ecx,DWORD [4+esp]
	add	edx,ebp
	; 20_39 33
	mov	ebp,edi
	xor	ecx,DWORD [12+esp]
	xor	ebp,esi
	xor	ecx,DWORD [36+esp]
	xor	ebp,eax
	xor	ecx,DWORD [56+esp]
	rol	ecx,1
	add	ebx,ebp
	ror	edi,2
	mov	ebp,edx
	rol	ebp,5
	mov	DWORD [4+esp],ecx
	lea	ecx,[1859775393+ebx*1+ecx]
	mov	ebx,DWORD [8+esp]
	add	ecx,ebp
	; 20_39 34
	mov	ebp,edx
	xor	ebx,DWORD [16+esp]
	xor	ebp,edi
	xor	ebx,DWORD [40+esp]
	xor	ebp,esi
	xor	ebx,DWORD [60+esp]
	rol	ebx,1
	add	eax,ebp
	ror	edx,2
	mov	ebp,ecx
	rol	ebp,5
	mov	DWORD [8+esp],ebx
	lea	ebx,[1859775393+eax*1+ebx]
	mov	eax,DWORD [12+esp]
	add	ebx,ebp
	; 20_39 35
	mov	ebp,ecx
	xor	eax,DWORD [20+esp]
	xor	ebp,edx
	xor	eax,DWORD [44+esp]
	xor	ebp,edi
	xor	eax,DWORD [esp]
	rol	eax,1
	add	esi,ebp
	ror	ecx,2
	mov	ebp,ebx
	rol	ebp,5
	mov	DWORD [12+esp],eax
	lea	eax,[1859775393+esi*1+eax]
	mov	esi,DWORD [16+esp]
	add	eax,ebp
	; 20_39 36
	mov	ebp,ebx
	xor	esi,DWORD [24+esp]
	xor	ebp,ecx
	xor	esi,DWORD [48+esp]
	xor	ebp,edx
	xor	esi,DWORD [4+esp]
	rol	esi,1
	add	edi,ebp
	ror	ebx,2
	mov	ebp,eax
	rol	ebp,5
	mov	DWORD [16+esp],esi
	lea	esi,[1859775393+edi*1+esi]
	mov	edi,DWORD [20+esp]
	add	esi,ebp
	; 20_39 37
	mov	ebp,eax
	xor	edi,DWORD [28+esp]
	xor	ebp,ebx
	xor	edi,DWORD [52+esp]
	xor	ebp,ecx
	xor	edi,DWORD [8+esp]
	rol	edi,1
	add	edx,ebp
	ror	eax,2
	mov	ebp,esi
	rol	ebp,5
	mov	DWORD [20+esp],edi
	lea	edi,[1859775393+edx*1+edi]
	mov	edx,DWORD [24+esp]
	add	edi,ebp
	; 20_39 38
	mov	ebp,esi
	xor	edx,DWORD [32+esp]
	xor	ebp,eax
	xor	edx,DWORD [56+esp]
	xor	ebp,ebx
	xor	edx,DWORD [12+esp]
	rol	edx,1
	add	ecx,ebp
	ror	esi,2
	mov	ebp,edi
	rol	ebp,5
	mov	DWORD [24+esp],edx
	lea	edx,[1859775393+ecx*1+edx]
	mov	ecx,DWORD [28+esp]
	add	edx,ebp
	; 20_39 39
	mov	ebp,edi
	xor	ecx,DWORD [36+esp]
	xor	ebp,esi
	xor	ecx,DWORD [60+esp]
	xor	ebp,eax
	xor	ecx,DWORD [16+esp]
	rol	ecx,1
	add	ebx,ebp
	ror	edi,2
	mov	ebp,edx
	rol	ebp,5
	mov	DWORD [28+esp],ecx
	lea	ecx,[1859775393+ebx*1+ecx]
	mov	ebx,DWORD [32+esp]
	add	ecx,ebp
	; 40_59 40
	mov	ebp,edi
	xor	ebx,DWORD [40+esp]
	xor	ebp,esi
	xor	ebx,DWORD [esp]
	and	ebp,edx
	xor	ebx,DWORD [20+esp]
	rol	ebx,1
	add	ebp,eax
	ror	edx,2
	mov	eax,ecx
	rol	eax,5
	mov	DWORD [32+esp],ebx
	lea	ebx,[2400959708+ebp*1+ebx]
	mov	ebp,edi
	add	ebx,eax
	and	ebp,esi
	mov	eax,DWORD [36+esp]
	add	ebx,ebp
	; 40_59 41
	mov	ebp,edx
	xor	eax,DWORD [44+esp]
	xor	ebp,edi
	xor	eax,DWORD [4+esp]
	and	ebp,ecx
	xor	eax,DWORD [24+esp]
	rol	eax,1
	add	ebp,esi
	ror	ecx,2
	mov	esi,ebx
	rol	esi,5
	mov	DWORD [36+esp],eax
	lea	eax,[2400959708+ebp*1+eax]
	mov	ebp,edx
	add	eax,esi
	and	ebp,edi
	mov	esi,DWORD [40+esp]
	add	eax,ebp
	; 40_59 42
	mov	ebp,ecx
	xor	esi,DWORD [48+esp]
	xor	ebp,edx
	xor	esi,DWORD [8+esp]
	and	ebp,ebx
	xor	esi,DWORD [28+esp]
	rol	esi,1
	add	ebp,edi
	ror	ebx,2
	mov	edi,eax
	rol	edi,5
	mov	DWORD [40+esp],esi
	lea	esi,[2400959708+ebp*1+esi]
	mov	ebp,ecx
	add	esi,edi
	and	ebp,edx
	mov	edi,DWORD [44+esp]
	add	esi,ebp
	; 40_59 43
	mov	ebp,ebx
	xor	edi,DWORD [52+esp]
	xor	ebp,ecx
	xor	edi,DWORD [12+esp]
	and	ebp,eax
	xor	edi,DWORD [32+esp]
	rol	edi,1
	add	ebp,edx
	ror	eax,2
	mov	edx,esi
	rol	edx,5
	mov	DWORD [44+esp],edi
	lea	edi,[2400959708+ebp*1+edi]
	mov	ebp,ebx
	add	edi,edx
	and	ebp,ecx
	mov	edx,DWORD [48+esp]
	add	edi,ebp
	; 40_59 44
	mov	ebp,eax
	xor	edx,DWORD [56+esp]
	xor	ebp,ebx
	xor	edx,DWORD [16+esp]
	and	ebp,esi
	xor	edx,DWORD [36+esp]
	rol	edx,1
	add	ebp,ecx
	ror	esi,2
	mov	ecx,edi
	rol	ecx,5
	mov	DWORD [48+esp],edx
	lea	edx,[2400959708+ebp*1+edx]
	mov	ebp,eax
	add	edx,ecx
	and	ebp,ebx
	mov	ecx,DWORD [52+esp]
	add	edx,ebp
	; 40_59 45
	mov	ebp,esi
	xor	ecx,DWORD [60+esp]
	xor	ebp,eax
	xor	ecx,DWORD [20+esp]
	and	ebp,edi
	xor	ecx,DWORD [40+esp]
	rol	ecx,1
	add	ebp,ebx
	ror	edi,2
	mov	ebx,edx
	rol	ebx,5
	mov	DWORD [52+esp],ecx
	lea	ecx,[2400959708+ebp*1+ecx]
	mov	ebp,esi
	add	ecx,ebx
	and	ebp,eax
	mov	ebx,DWORD [56+esp]
	add	ecx,ebp
	; 40_59 46
	mov	ebp,edi
	xor	ebx,DWORD [esp]
	xor	ebp,esi
	xor	ebx,DWORD [24+esp]
	and	ebp,edx
	xor	ebx,DWORD [44+esp]
	rol	ebx,1
	add	ebp,eax
	ror	edx,2
	mov	eax,ecx
	rol	eax,5
	mov	DWORD [56+esp],ebx
	lea	ebx,[2400959708+ebp*1+ebx]
	mov	ebp,edi
	add	ebx,eax
	and	ebp,esi
	mov	eax,DWORD [60+esp]
	add	ebx,ebp
	; 40_59 47
	mov	ebp,edx
	xor	eax,DWORD [4+esp]
	xor	ebp,edi
	xor	eax,DWORD [28+esp]
	and	ebp,ecx
	xor	eax,DWORD [48+esp]
	rol	eax,1
	add	ebp,esi
	ror	ecx,2
	mov	esi,ebx
	rol	esi,5
	mov	DWORD [60+esp],eax
	lea	eax,[2400959708+ebp*1+eax]
	mov	ebp,edx
	add	eax,esi
	and	ebp,edi
	mov	esi,DWORD [esp]
	add	eax,ebp
	; 40_59 48
	mov	ebp,ecx
	xor	esi,DWORD [8+esp]
	xor	ebp,edx
	xor	esi,DWORD [32+esp]
	and	ebp,ebx
	xor	esi,DWORD [52+esp]
	rol	esi,1
	add	ebp,edi
	ror	ebx,2
	mov	edi,eax
	rol	edi,5
	mov	DWORD [esp],esi
	lea	esi,[2400959708+ebp*1+esi]
	mov	ebp,ecx
	add	esi,edi
	and	ebp,edx
	mov	edi,DWORD [4+esp]
	add	esi,ebp
	; 40_59 49
	mov	ebp,ebx
	xor	edi,DWORD [12+esp]
	xor	ebp,ecx
	xor	edi,DWORD [36+esp]
	and	ebp,eax
	xor	edi,DWORD [56+esp]
	rol	edi,1
	add	ebp,edx
	ror	eax,2
	mov	edx,esi
	rol	edx,5
	mov	DWORD [4+esp],edi
	lea	edi,[2400959708+ebp*1+edi]
	mov	ebp,ebx
	add	edi,edx
	and	ebp,ecx
	mov	edx,DWORD [8+esp]
	add	edi,ebp
	; 40_59 50
	mov	ebp,eax
	xor	edx,DWORD [16+esp]
	xor	ebp,ebx
	xor	edx,DWORD [40+esp]
	and	ebp,esi
	xor	edx,DWORD [60+esp]
	rol	edx,1
	add	ebp,ecx
	ror	esi,2
	mov	ecx,edi
	rol	ecx,5
	mov	DWORD [8+esp],edx
	lea	edx,[2400959708+ebp*1+edx]
	mov	ebp,eax
	add	edx,ecx
	and	ebp,ebx
	mov	ecx,DWORD [12+esp]
	add	edx,ebp
	; 40_59 51
	mov	ebp,esi
	xor	ecx,DWORD [20+esp]
	xor	ebp,eax
	xor	ecx,DWORD [44+esp]
	and	ebp,edi
	xor	ecx,DWORD [esp]
	rol	ecx,1
	add	ebp,ebx
	ror	edi,2
	mov	ebx,edx
	rol	ebx,5
	mov	DWORD [12+esp],ecx
	lea	ecx,[2400959708+ebp*1+ecx]
	mov	ebp,esi
	add	ecx,ebx
	and	ebp,eax
	mov	ebx,DWORD [16+esp]
	add	ecx,ebp
	; 40_59 52
	mov	ebp,edi
	xor	ebx,DWORD [24+esp]
	xor	ebp,esi
	xor	ebx,DWORD [48+esp]
	and	ebp,edx
	xor	ebx,DWORD [4+esp]
	rol	ebx,1
	add	ebp,eax
	ror	edx,2
	mov	eax,ecx
	rol	eax,5
	mov	DWORD [16+esp],ebx
	lea	ebx,[2400959708+ebp*1+ebx]
	mov	ebp,edi
	add	ebx,eax
	and	ebp,esi
	mov	eax,DWORD [20+esp]
	add	ebx,ebp
	; 40_59 53
	mov	ebp,edx
	xor	eax,DWORD [28+esp]
	xor	ebp,edi
	xor	eax,DWORD [52+esp]
	and	ebp,ecx
	xor	eax,DWORD [8+esp]
	rol	eax,1
	add	ebp,esi
	ror	ecx,2
	mov	esi,ebx
	rol	esi,5
	mov	DWORD [20+esp],eax
	lea	eax,[2400959708+ebp*1+eax]
	mov	ebp,edx
	add	eax,esi
	and	ebp,edi
	mov	esi,DWORD [24+esp]
	add	eax,ebp
	; 40_59 54
	mov	ebp,ecx
	xor	esi,DWORD [32+esp]
	xor	ebp,edx
	xor	esi,DWORD [56+esp]
	and	ebp,ebx
	xor	esi,DWORD [12+esp]
	rol	esi,1
	add	ebp,edi
	ror	ebx,2
	mov	edi,eax
	rol	edi,5
	mov	DWORD [24+esp],esi
	lea	esi,[2400959708+ebp*1+esi]
	mov	ebp,ecx
	add	esi,edi
	and	ebp,edx
	mov	edi,DWORD [28+esp]
	add	esi,ebp
	; 40_59 55
	mov	ebp,ebx
	xor	edi,DWORD [36+esp]
	xor	ebp,ecx
	xor	edi,DWORD [60+esp]
	and	ebp,eax
	xor	edi,DWORD [16+esp]
	rol	edi,1
	add	ebp,edx
	ror	eax,2
	mov	edx,esi
	rol	edx,5
	mov	DWORD [28+esp],edi
	lea	edi,[2400959708+ebp*1+edi]
	mov	ebp,ebx
	add	edi,edx
	and	ebp,ecx
	mov	edx,DWORD [32+esp]
	add	edi,ebp
	; 40_59 56
	mov	ebp,eax
	xor	edx,DWORD [40+esp]
	xor	ebp,ebx
	xor	edx,DWORD [esp]
	and	ebp,esi
	xor	edx,DWORD [20+esp]
	rol	edx,1
	add	ebp,ecx
	ror	esi,2
	mov	ecx,edi
	rol	ecx,5
	mov	DWORD [32+esp],edx
	lea	edx,[2400959708+ebp*1+edx]
	mov	ebp,eax
	add	edx,ecx
	and	ebp,ebx
	mov	ecx,DWORD [36+esp]
	add	edx,ebp
	; 40_59 57
	mov	ebp,esi
	xor	ecx,DWORD [44+esp]
	xor	ebp,eax
	xor	ecx,DWORD [4+esp]
	and	ebp,edi
	xor	ecx,DWORD [24+esp]
	rol	ecx,1
	add	ebp,ebx
	ror	edi,2
	mov	ebx,edx
	rol	ebx,5
	mov	DWORD [36+esp],ecx
	lea	ecx,[2400959708+ebp*1+ecx]
	mov	ebp,esi
	add	ecx,ebx
	and	ebp,eax
	mov	ebx,DWORD [40+esp]
	add	ecx,ebp
	; 40_59 58
	mov	ebp,edi
	xor	ebx,DWORD [48+esp]
	xor	ebp,esi
	xor	ebx,DWORD [8+esp]
	and	ebp,edx
	xor	ebx,DWORD [28+esp]
	rol	ebx,1
	add	ebp,eax
	ror	edx,2
	mov	eax,ecx
	rol	eax,5
	mov	DWORD [40+esp],ebx
	lea	ebx,[2400959708+ebp*1+ebx]
	mov	ebp,edi
	add	ebx,eax
	and	ebp,esi
	mov	eax,DWORD [44+esp]
	add	ebx,ebp
	; 40_59 59
	mov	ebp,edx
	xor	eax,DWORD [52+esp]
	xor	ebp,edi
	xor	eax,DWORD [12+esp]
	and	ebp,ecx
	xor	eax,DWORD [32+esp]
	rol	eax,1
	add	ebp,esi
	ror	ecx,2
	mov	esi,ebx
	rol	esi,5
	mov	DWORD [44+esp],eax
	lea	eax,[2400959708+ebp*1+eax]
	mov	ebp,edx
	add	eax,esi
	and	ebp,edi
	mov	esi,DWORD [48+esp]
	add	eax,ebp
	; 20_39 60
	mov	ebp,ebx
	xor	esi,DWORD [56+esp]
	xor	ebp,ecx
	xor	esi,DWORD [16+esp]
	xor	ebp,edx
	xor	esi,DWORD [36+esp]
	rol	esi,1
	add	edi,ebp
	ror	ebx,2
	mov	ebp,eax
	rol	ebp,5
	mov	DWORD [48+esp],esi
	lea	esi,[3395469782+edi*1+esi]
	mov	edi,DWORD [52+esp]
	add	esi,ebp
	; 20_39 61
	mov	ebp,eax
	xor	edi,DWORD [60+esp]
	xor	ebp,ebx
	xor	edi,DWORD [20+esp]
	xor	ebp,ecx
	xor	edi,DWORD [40+esp]
	rol	edi,1
	add	edx,ebp
	ror	eax,2
	mov	ebp,esi
	rol	ebp,5
	mov	DWORD [52+esp],edi
	lea	edi,[3395469782+edx*1+edi]
	mov	edx,DWORD [56+esp]
	add	edi,ebp
	; 20_39 62
	mov	ebp,esi
	xor	edx,DWORD [esp]
	xor	ebp,eax
	xor	edx,DWORD [24+esp]
	xor	ebp,ebx
	xor	edx,DWORD [44+esp]
	rol	edx,1
	add	ecx,ebp
	ror	esi,2
	mov	ebp,edi
	rol	ebp,5
	mov	DWORD [56+esp],edx
	lea	edx,[3395469782+ecx*1+edx]
	mov	ecx,DWORD [60+esp]
	add	edx,ebp
	; 20_39 63
	mov	ebp,edi
	xor	ecx,DWORD [4+esp]
	xor	ebp,esi
	xor	ecx,DWORD [28+esp]
	xor	ebp,eax
	xor	ecx,DWORD [48+esp]
	rol	ecx,1
	add	ebx,ebp
	ror	edi,2
	mov	ebp,edx
	rol	ebp,5
	mov	DWORD [60+esp],ecx
	lea	ecx,[3395469782+ebx*1+ecx]
	mov	ebx,DWORD [esp]
	add	ecx,ebp
	; 20_39 64
	mov	ebp,edx
	xor	ebx,DWORD [8+esp]
	xor	ebp,edi
	xor	ebx,DWORD [32+esp]
	xor	ebp,esi
	xor	ebx,DWORD [52+esp]
	rol	ebx,1
	add	eax,ebp
	ror	edx,2
	mov	ebp,ecx
	rol	ebp,5
	mov	DWORD [esp],ebx
	lea	ebx,[3395469782+eax*1+ebx]
	mov	eax,DWORD [4+esp]
	add	ebx,ebp
	; 20_39 65
	mov	ebp,ecx
	xor	eax,DWORD [12+esp]
	xor	ebp,edx
	xor	eax,DWORD [36+esp]
	xor	ebp,edi
	xor	eax,DWORD [56+esp]
	rol	eax,1
	add	esi,ebp
	ror	ecx,2
	mov	ebp,ebx
	rol	ebp,5
	mov	DWORD [4+esp],eax
	lea	eax,[3395469782+esi*1+eax]
	mov	esi,DWORD [8+esp]
	add	eax,ebp
	; 20_39 66
	mov	ebp,ebx
	xor	esi,DWORD [16+esp]
	xor	ebp,ecx
	xor	esi,DWORD [40+esp]
	xor	ebp,edx
	xor	esi,DWORD [60+esp]
	rol	esi,1
	add	edi,ebp
	ror	ebx,2
	mov	ebp,eax
	rol	ebp,5
	mov	DWORD [8+esp],esi
	lea	esi,[3395469782+edi*1+esi]
	mov	edi,DWORD [12+esp]
	add	esi,ebp
	; 20_39 67
	mov	ebp,eax
	xor	edi,DWORD [20+esp]
	xor	ebp,ebx
	xor	edi,DWORD [44+esp]
	xor	ebp,ecx
	xor	edi,DWORD [esp]
	rol	edi,1
	add	edx,ebp
	ror	eax,2
	mov	ebp,esi
	rol	ebp,5
	mov	DWORD [12+esp],edi
	lea	edi,[3395469782+edx*1+edi]
	mov	edx,DWORD [16+esp]
	add	edi,ebp
	; 20_39 68
	mov	ebp,esi
	xor	edx,DWORD [24+esp]
	xor	ebp,eax
	xor	edx,DWORD [48+esp]
	xor	ebp,ebx
	xor	edx,DWORD [4+esp]
	rol	edx,1
	add	ecx,ebp
	ror	esi,2
	mov	ebp,edi
	rol	ebp,5
	mov	DWORD [16+esp],edx
	lea	edx,[3395469782+ecx*1+edx]
	mov	ecx,DWORD [20+esp]
	add	edx,ebp
	; 20_39 69
	mov	ebp,edi
	xor	ecx,DWORD [28+esp]
	xor	ebp,esi
	xor	ecx,DWORD [52+esp]
	xor	ebp,eax
	xor	ecx,DWORD [8+esp]
	rol	ecx,1
	add	ebx,ebp
	ror	edi,2
	mov	ebp,edx
	rol	ebp,5
	mov	DWORD [20+esp],ecx
	lea	ecx,[3395469782+ebx*1+ecx]
	mov	ebx,DWORD [24+esp]
	add	ecx,ebp
	; 20_39 70
	mov	ebp,edx
	xor	ebx,DWORD [32+esp]
	xor	ebp,edi
	xor	ebx,DWORD [56+esp]
	xor	ebp,esi
	xor	ebx,DWORD [12+esp]
	rol	ebx,1
	add	eax,ebp
	ror	edx,2
	mov	ebp,ecx
	rol	ebp,5
	mov	DWORD [24+esp],ebx
	lea	ebx,[3395469782+eax*1+ebx]
	mov	eax,DWORD [28+esp]
	add	ebx,ebp
	; 20_39 71
	mov	ebp,ecx
	xor	eax,DWORD [36+esp]
	xor	ebp,edx
	xor	eax,DWORD [60+esp]
	xor	ebp,edi
	xor	eax,DWORD [16+esp]
	rol	eax,1
	add	esi,ebp
	ror	ecx,2
	mov	ebp,ebx
	rol	ebp,5
	mov	DWORD [28+esp],eax
	lea	eax,[3395469782+esi*1+eax]
	mov	esi,DWORD [32+esp]
	add	eax,ebp
	; 20_39 72
	mov	ebp,ebx
	xor	esi,DWORD [40+esp]
	xor	ebp,ecx
	xor	esi,DWORD [esp]
	xor	ebp,edx
	xor	esi,DWORD [20+esp]
	rol	esi,1
	add	edi,ebp
	ror	ebx,2
	mov	ebp,eax
	rol	ebp,5
	mov	DWORD [32+esp],esi
	lea	esi,[3395469782+edi*1+esi]
	mov	edi,DWORD [36+esp]
	add	esi,ebp
	; 20_39 73
	mov	ebp,eax
	xor	edi,DWORD [44+esp]
	xor	ebp,ebx
	xor	edi,DWORD [4+esp]
	xor	ebp,ecx
	xor	edi,DWORD [24+esp]
	rol	edi,1
	add	edx,ebp
	ror	eax,2
	mov	ebp,esi
	rol	ebp,5
	mov	DWORD [36+esp],edi
	lea	edi,[3395469782+edx*1+edi]
	mov	edx,DWORD [40+esp]
	add	edi,ebp
	; 20_39 74
	mov	ebp,esi
	xor	edx,DWORD [48+esp]
	xor	ebp,eax
	xor	edx,DWORD [8+esp]
	xor	ebp,ebx
	xor	edx,DWORD [28+esp]
	rol	edx,1
	add	ecx,ebp
	ror	esi,2
	mov	ebp,edi
	rol	ebp,5
	mov	DWORD [40+esp],edx
	lea	edx,[3395469782+ecx*1+edx]
	mov	ecx,DWORD [44+esp]
	add	edx,ebp
	; 20_39 75
	mov	ebp,edi
	xor	ecx,DWORD [52+esp]
	xor	ebp,esi
	xor	ecx,DWORD [12+esp]
	xor	ebp,eax
	xor	ecx,DWORD [32+esp]
	rol	ecx,1
	add	ebx,ebp
	ror	edi,2
	mov	ebp,edx
	rol	ebp,5
	mov	DWORD [44+esp],ecx
	lea	ecx,[3395469782+ebx*1+ecx]
	mov	ebx,DWORD [48+esp]
	add	ecx,ebp
	; 20_39 76
	mov	ebp,edx
	xor	ebx,DWORD [56+esp]
	xor	ebp,edi
	xor	ebx,DWORD [16+esp]
	xor	ebp,esi
	xor	ebx,DWORD [36+esp]
	rol	ebx,1
	add	eax,ebp
	ror	edx,2
	mov	ebp,ecx
	rol	ebp,5
	mov	DWORD [48+esp],ebx
	lea	ebx,[3395469782+eax*1+ebx]
	mov	eax,DWORD [52+esp]
	add	ebx,ebp
	; 20_39 77
	mov	ebp,ecx
	xor	eax,DWORD [60+esp]
	xor	ebp,edx
	xor	eax,DWORD [20+esp]
	xor	ebp,edi
	xor	eax,DWORD [40+esp]
	rol	eax,1
	add	esi,ebp
	ror	ecx,2
	mov	ebp,ebx
	rol	ebp,5
	lea	eax,[3395469782+esi*1+eax]
	mov	esi,DWORD [56+esp]
	add	eax,ebp
	; 20_39 78
	mov	ebp,ebx
	xor	esi,DWORD [esp]
	xor	ebp,ecx
	xor	esi,DWORD [24+esp]
	xor	ebp,edx
	xor	esi,DWORD [44+esp]
	rol	esi,1
	add	edi,ebp
	ror	ebx,2
	mov	ebp,eax
	rol	ebp,5
	lea	esi,[3395469782+edi*1+esi]
	mov	edi,DWORD [60+esp]
	add	esi,ebp
	; 20_39 79
	mov	ebp,eax
	xor	edi,DWORD [4+esp]
	xor	ebp,ebx
	xor	edi,DWORD [28+esp]
	xor	ebp,ecx
	xor	edi,DWORD [48+esp]
	rol	edi,1
	add	edx,ebp
	ror	eax,2
	mov	ebp,esi
	rol	ebp,5
	lea	edi,[3395469782+edx*1+edi]
	add	edi,ebp
	mov	ebp,DWORD [96+esp]
	mov	edx,DWORD [100+esp]
	add	edi,DWORD [ebp]
	add	esi,DWORD [4+ebp]
	add	eax,DWORD [8+ebp]
	add	ebx,DWORD [12+ebp]
	add	ecx,DWORD [16+ebp]
	mov	DWORD [ebp],edi
	add	edx,64
	mov	DWORD [4+ebp],esi
	cmp	edx,DWORD [104+esp]
	mov	DWORD [8+ebp],eax
	mov	edi,ecx
	mov	DWORD [12+ebp],ebx
	mov	esi,edx
	mov	DWORD [16+ebp],ecx
	jb	NEAR L$002loop
	add	esp,76
	pop	edi
	pop	esi
	pop	ebx
	pop	ebp
	ret
align	16
__sha1_block_data_order_shaext:
	push	ebp
	push	ebx
	push	esi
	push	edi
	call	L$003pic_point
L$003pic_point:
	pop	ebp
	lea	ebp,[(L$K_XX_XX-L$003pic_point)+ebp]
L$shaext_shortcut:
	mov	edi,DWORD [20+esp]
	mov	ebx,esp
	mov	esi,DWORD [24+esp]
	mov	ecx,DWORD [28+esp]
	sub	esp,32
	movdqu	xmm0,[edi]
	movd	xmm1,DWORD [16+edi]
	and	esp,-32
	movdqa	xmm3,[80+ebp]
	movdqu	xmm4,[esi]
	pshufd	xmm0,xmm0,27
	movdqu	xmm5,[16+esi]
	pshufd	xmm1,xmm1,27
	movdqu	xmm6,[32+esi]
db	102,15,56,0,227
	movdqu	xmm7,[48+esi]
db	102,15,56,0,235
db	102,15,56,0,243
db	102,15,56,0,251
	jmp	NEAR L$004loop_shaext
align	16
L$004loop_shaext:
	dec	ecx
	lea	eax,[64+esi]
	movdqa	[esp],xmm1
	paddd	xmm1,xmm4
	cmovne	esi,eax
	movdqa	[16+esp],xmm0
db	15,56,201,229
	movdqa	xmm2,xmm0
db	15,58,204,193,0
db	15,56,200,213
	pxor	xmm4,xmm6
db	15,56,201,238
db	15,56,202,231
	movdqa	xmm1,xmm0
db	15,58,204,194,0
db	15,56,200,206
	pxor	xmm5,xmm7
db	15,56,202,236
db	15,56,201,247
	movdqa	xmm2,xmm0
db	15,58,204,193,0
db	15,56,200,215
	pxor	xmm6,xmm4
db	15,56,201,252
db	15,56,202,245
	movdqa	xmm1,xmm0
db	15,58,204,194,0
db	15,56,200,204
	pxor	xmm7,xmm5
db	15,56,202,254
db	15,56,201,229
	movdqa	xmm2,xmm0
db	15,58,204,193,0
db	15,56,200,213
	pxor	xmm4,xmm6
db	15,56,201,238
db	15,56,202,231
	movdqa	xmm1,xmm0
db	15,58,204,194,1
db	15,56,200,206
	pxor	xmm5,xmm7
db	15,56,202,236
db	15,56,201,247
	movdqa	xmm2,xmm0
db	15,58,204,193,1
db	15,56,200,215
	pxor	xmm6,xmm4
db	15,56,201,252
db	15,56,202,245
	movdqa	xmm1,xmm0
db	15,58,204,194,1
db	15,56,200,204
	pxor	xmm7,xmm5
db	15,56,202,254
db	15,56,201,229
	movdqa	xmm2,xmm0
db	15,58,204,193,1
db	15,56,200,213
	pxor	xmm4,xmm6
db	15,56,201,238
db	15,56,202,231
	movdqa	xmm1,xmm0
db	15,58,204,194,1
db	15,56,200,206
	pxor	xmm5,xmm7
db	15,56,202,236
db	15,56,201,247
	movdqa	xmm2,xmm0
db	15,58,204,193,2
db	15,56,200,215
	pxor	xmm6,xmm4
db	15,56,201,252
db	15,56,202,245
	movdqa	xmm1,xmm0
db	15,58,204,194,2
db	15,56,200,204
	pxor	xmm7,xmm5
db	15,56,202,254
db	15,56,201,229
	movdqa	xmm2,xmm0
db	15,58,204,193,2
db	15,56,200,213
	pxor	xmm4,xmm6
db	15,56,201,238
db	15,56,202,231
	movdqa	xmm1,xmm0
db	15,58,204,194,2
db	15,56,200,206
	pxor	xmm5,xmm7
db	15,56,202,236
db	15,56,201,247
	movdqa	xmm2,xmm0
db	15,58,204,193,2
db	15,56,200,215
	pxor	xmm6,xmm4
db	15,56,201,252
db	15,56,202,245
	movdqa	xmm1,xmm0
db	15,58,204,194,3
db	15,56,200,204
	pxor	xmm7,xmm5
db	15,56,202,254
	movdqu	xmm4,[esi]
	movdqa	xmm2,xmm0
db	15,58,204,193,3
db	15,56,200,213
	movdqu	xmm5,[16+esi]
db	102,15,56,0,227
	movdqa	xmm1,xmm0
db	15,58,204,194,3
db	15,56,200,206
	movdqu	xmm6,[32+esi]
db	102,15,56,0,235
	movdqa	xmm2,xmm0
db	15,58,204,193,3
db	15,56,200,215
	movdqu	xmm7,[48+esi]
db	102,15,56,0,243
	movdqa	xmm1,xmm0
db	15,58,204,194,3
	movdqa	xmm2,[esp]
db	102,15,56,0,251
db	15,56,200,202
	paddd	xmm0,[16+esp]
	jnz	NEAR L$004loop_shaext
	pshufd	xmm0,xmm0,27
	pshufd	xmm1,xmm1,27
	movdqu	[edi],xmm0
	movd	DWORD [16+edi],xmm1
	mov	esp,ebx
	pop	edi
	pop	esi
	pop	ebx
	pop	ebp
	ret
align	16
__sha1_block_data_order_ssse3:
	push	ebp
	push	ebx
	push	esi
	push	edi
	call	L$005pic_point
L$005pic_point:
	pop	ebp
	lea	ebp,[(L$K_XX_XX-L$005pic_point)+ebp]
L$ssse3_shortcut:
	movdqa	xmm7,[ebp]
	movdqa	xmm0,[16+ebp]
	movdqa	xmm1,[32+ebp]
	movdqa	xmm2,[48+ebp]
	movdqa	xmm6,[64+ebp]
	mov	edi,DWORD [20+esp]
	mov	ebp,DWORD [24+esp]
	mov	edx,DWORD [28+esp]
	mov	esi,esp
	sub	esp,208
	and	esp,-64
	movdqa	[112+esp],xmm0
	movdqa	[128+esp],xmm1
	movdqa	[144+esp],xmm2
	shl	edx,6
	movdqa	[160+esp],xmm7
	add	edx,ebp
	movdqa	[176+esp],xmm6
	add	ebp,64
	mov	DWORD [192+esp],edi
	mov	DWORD [196+esp],ebp
	mov	DWORD [200+esp],edx
	mov	DWORD [204+esp],esi
	mov	eax,DWORD [edi]
	mov	ebx,DWORD [4+edi]
	mov	ecx,DWORD [8+edi]
	mov	edx,DWORD [12+edi]
	mov	edi,DWORD [16+edi]
	mov	esi,ebx
	movdqu	xmm0,[ebp-64]
	movdqu	xmm1,[ebp-48]
	movdqu	xmm2,[ebp-32]
	movdqu	xmm3,[ebp-16]
db	102,15,56,0,198
db	102,15,56,0,206
db	102,15,56,0,214
	movdqa	[96+esp],xmm7
db	102,15,56,0,222
	paddd	xmm0,xmm7
	paddd	xmm1,xmm7
	paddd	xmm2,xmm7
	movdqa	[esp],xmm0
	psubd	xmm0,xmm7
	movdqa	[16+esp],xmm1
	psubd	xmm1,xmm7
	movdqa	[32+esp],xmm2
	mov	ebp,ecx
	psubd	xmm2,xmm7
	xor	ebp,edx
	pshufd	xmm4,xmm0,238
	and	esi,ebp
	jmp	NEAR L$006loop
align	16
L$006loop:
	ror	ebx,2
	xor	esi,edx
	mov	ebp,eax
	punpcklqdq	xmm4,xmm1
	movdqa	xmm6,xmm3
	add	edi,DWORD [esp]
	xor	ebx,ecx
	paddd	xmm7,xmm3
	movdqa	[64+esp],xmm0
	rol	eax,5
	add	edi,esi
	psrldq	xmm6,4
	and	ebp,ebx
	xor	ebx,ecx
	pxor	xmm4,xmm0
	add	edi,eax
	ror	eax,7
	pxor	xmm6,xmm2
	xor	ebp,ecx
	mov	esi,edi
	add	edx,DWORD [4+esp]
	pxor	xmm4,xmm6
	xor	eax,ebx
	rol	edi,5
	movdqa	[48+esp],xmm7
	add	edx,ebp
	and	esi,eax
	movdqa	xmm0,xmm4
	xor	eax,ebx
	add	edx,edi
	ror	edi,7
	movdqa	xmm6,xmm4
	xor	esi,ebx
	pslldq	xmm0,12
	paddd	xmm4,xmm4
	mov	ebp,edx
	add	ecx,DWORD [8+esp]
	psrld	xmm6,31
	xor	edi,eax
	rol	edx,5
	movdqa	xmm7,xmm0
	add	ecx,esi
	and	ebp,edi
	xor	edi,eax
	psrld	xmm0,30
	add	ecx,edx
	ror	edx,7
	por	xmm4,xmm6
	xor	ebp,eax
	mov	esi,ecx
	add	ebx,DWORD [12+esp]
	pslld	xmm7,2
	xor	edx,edi
	rol	ecx,5
	pxor	xmm4,xmm0
	movdqa	xmm0,[96+esp]
	add	ebx,ebp
	and	esi,edx
	pxor	xmm4,xmm7
	pshufd	xmm5,xmm1,238
	xor	edx,edi
	add	ebx,ecx
	ror	ecx,7
	xor	esi,edi
	mov	ebp,ebx
	punpcklqdq	xmm5,xmm2
	movdqa	xmm7,xmm4
	add	eax,DWORD [16+esp]
	xor	ecx,edx
	paddd	xmm0,xmm4
	movdqa	[80+esp],xmm1
	rol	ebx,5
	add	eax,esi
	psrldq	xmm7,4
	and	ebp,ecx
	xor	ecx,edx
	pxor	xmm5,xmm1
	add	eax,ebx
	ror	ebx,7
	pxor	xmm7,xmm3
	xor	ebp,edx
	mov	esi,eax
	add	edi,DWORD [20+esp]
	pxor	xmm5,xmm7
	xor	ebx,ecx
	rol	eax,5
	movdqa	[esp],xmm0
	add	edi,ebp
	and	esi,ebx
	movdqa	xmm1,xmm5
	xor	ebx,ecx
	add	edi,eax
	ror	eax,7
	movdqa	xmm7,xmm5
	xor	esi,ecx
	pslldq	xmm1,12
	paddd	xmm5,xmm5
	mov	ebp,edi
	add	edx,DWORD [24+esp]
	psrld	xmm7,31
	xor	eax,ebx
	rol	edi,5
	movdqa	xmm0,xmm1
	add	edx,esi
	and	ebp,eax
	xor	eax,ebx
	psrld	xmm1,30
	add	edx,edi
	ror	edi,7
	por	xmm5,xmm7
	xor	ebp,ebx
	mov	esi,edx
	add	ecx,DWORD [28+esp]
	pslld	xmm0,2
	xor	edi,eax
	rol	edx,5
	pxor	xmm5,xmm1
	movdqa	xmm1,[112+esp]
	add	ecx,ebp
	and	esi,edi
	pxor	xmm5,xmm0
	pshufd	xmm6,xmm2,238
	xor	edi,eax
	add	ecx,edx
	ror	edx,7
	xor	esi,eax
	mov	ebp,ecx
	punpcklqdq	xmm6,xmm3
	movdqa	xmm0,xmm5
	add	ebx,DWORD [32+esp]
	xor	edx,edi
	paddd	xmm1,xmm5
	movdqa	[96+esp],xmm2
	rol	ecx,5
	add	ebx,esi
	psrldq	xmm0,4
	and	ebp,edx
	xor	edx,edi
	pxor	xmm6,xmm2
	add	ebx,ecx
	ror	ecx,7
	pxor	xmm0,xmm4
	xor	ebp,edi
	mov	esi,ebx
	add	eax,DWORD [36+esp]
	pxor	xmm6,xmm0
	xor	ecx,edx
	rol	ebx,5
	movdqa	[16+esp],xmm1
	add	eax,ebp
	and	esi,ecx
	movdqa	xmm2,xmm6
	xor	ecx,edx
	add	eax,ebx
	ror	ebx,7
	movdqa	xmm0,xmm6
	xor	esi,edx
	pslldq	xmm2,12
	paddd	xmm6,xmm6
	mov	ebp,eax
	add	edi,DWORD [40+esp]
	psrld	xmm0,31
	xor	ebx,ecx
	rol	eax,5
	movdqa	xmm1,xmm2
	add	edi,esi
	and	ebp,ebx
	xor	ebx,ecx
	psrld	xmm2,30
	add	edi,eax
	ror	eax,7
	por	xmm6,xmm0
	xor	ebp,ecx
	movdqa	xmm0,[64+esp]
	mov	esi,edi
	add	edx,DWORD [44+esp]
	pslld	xmm1,2
	xor	eax,ebx
	rol	edi,5
	pxor	xmm6,xmm2
	movdqa	xmm2,[112+esp]
	add	edx,ebp
	and	esi,eax
	pxor	xmm6,xmm1
	pshufd	xmm7,xmm3,238
	xor	eax,ebx
	add	edx,edi
	ror	edi,7
	xor	esi,ebx
	mov	ebp,edx
	punpcklqdq	xmm7,xmm4
	movdqa	xmm1,xmm6
	add	ecx,DWORD [48+esp]
	xor	edi,eax
	paddd	xmm2,xmm6
	movdqa	[64+esp],xmm3
	rol	edx,5
	add	ecx,esi
	psrldq	xmm1,4
	and	ebp,edi
	xor	edi,eax
	pxor	xmm7,xmm3
	add	ecx,edx
	ror	edx,7
	pxor	xmm1,xmm5
	xor	ebp,eax
	mov	esi,ecx
	add	ebx,DWORD [52+esp]
	pxor	xmm7,xmm1
	xor	edx,edi
	rol	ecx,5
	movdqa	[32+esp],xmm2
	add	ebx,ebp
	and	esi,edx
	movdqa	xmm3,xmm7
	xor	edx,edi
	add	ebx,ecx
	ror	ecx,7
	movdqa	xmm1,xmm7
	xor	esi,edi
	pslldq	xmm3,12
	paddd	xmm7,xmm7
	mov	ebp,ebx
	add	eax,DWORD [56+esp]
	psrld	xmm1,31
	xor	ecx,edx
	rol	ebx,5
	movdqa	xmm2,xmm3
	add	eax,esi
	and	ebp,ecx
	xor	ecx,edx
	psrld	xmm3,30
	add	eax,ebx
	ror	ebx,7
	por	xmm7,xmm1
	xor	ebp,edx
	movdqa	xmm1,[80+esp]
	mov	esi,eax
	add	edi,DWORD [60+esp]
	pslld	xmm2,2
	xor	ebx,ecx
	rol	eax,5
	pxor	xmm7,xmm3
	movdqa	xmm3,[112+esp]
	add	edi,ebp
	and	esi,ebx
	pxor	xmm7,xmm2
	pshufd	xmm2,xmm6,238
	xor	ebx,ecx
	add	edi,eax
	ror	eax,7
	pxor	xmm0,xmm4
	punpcklqdq	xmm2,xmm7
	xor	esi,ecx
	mov	ebp,edi
	add	edx,DWORD [esp]
	pxor	xmm0,xmm1
	movdqa	[80+esp],xmm4
	xor	eax,ebx
	rol	edi,5
	movdqa	xmm4,xmm3
	add	edx,esi
	paddd	xmm3,xmm7
	and	ebp,eax
	pxor	xmm0,xmm2
	xor	eax,ebx
	add	edx,edi
	ror	edi,7
	xor	ebp,ebx
	movdqa	xmm2,xmm0
	movdqa	[48+esp],xmm3
	mov	esi,edx
	add	ecx,DWORD [4+esp]
	xor	edi,eax
	rol	edx,5
	pslld	xmm0,2
	add	ecx,ebp
	and	esi,edi
	psrld	xmm2,30
	xor	edi,eax
	add	ecx,edx
	ror	edx,7
	xor	esi,eax
	mov	ebp,ecx
	add	ebx,DWORD [8+esp]
	xor	edx,edi
	rol	ecx,5
	por	xmm0,xmm2
	add	ebx,esi
	and	ebp,edx
	movdqa	xmm2,[96+esp]
	xor	edx,edi
	add	ebx,ecx
	add	eax,DWORD [12+esp]
	xor	ebp,edi
	mov	esi,ebx
	pshufd	xmm3,xmm7,238
	rol	ebx,5
	add	eax,ebp
	xor	esi,edx
	ror	ecx,7
	add	eax,ebx
	add	edi,DWORD [16+esp]
	pxor	xmm1,xmm5
	punpcklqdq	xmm3,xmm0
	xor	esi,ecx
	mov	ebp,eax
	rol	eax,5
	pxor	xmm1,xmm2
	movdqa	[96+esp],xmm5
	add	edi,esi
	xor	ebp,ecx
	movdqa	xmm5,xmm4
	ror	ebx,7
	paddd	xmm4,xmm0
	add	edi,eax
	pxor	xmm1,xmm3
	add	edx,DWORD [20+esp]
	xor	ebp,ebx
	mov	esi,edi
	rol	edi,5
	movdqa	xmm3,xmm1
	movdqa	[esp],xmm4
	add	edx,ebp
	xor	esi,ebx
	ror	eax,7
	add	edx,edi
	pslld	xmm1,2
	add	ecx,DWORD [24+esp]
	xor	esi,eax
	psrld	xmm3,30
	mov	ebp,edx
	rol	edx,5
	add	ecx,esi
	xor	ebp,eax
	ror	edi,7
	add	ecx,edx
	por	xmm1,xmm3
	add	ebx,DWORD [28+esp]
	xor	ebp,edi
	movdqa	xmm3,[64+esp]
	mov	esi,ecx
	rol	ecx,5
	add	ebx,ebp
	xor	esi,edi
	ror	edx,7
	pshufd	xmm4,xmm0,238
	add	ebx,ecx
	add	eax,DWORD [32+esp]
	pxor	xmm2,xmm6
	punpcklqdq	xmm4,xmm1
	xor	esi,edx
	mov	ebp,ebx
	rol	ebx,5
	pxor	xmm2,xmm3
	movdqa	[64+esp],xmm6
	add	eax,esi
	xor	ebp,edx
	movdqa	xmm6,[128+esp]
	ror	ecx,7
	paddd	xmm5,xmm1
	add	eax,ebx
	pxor	xmm2,xmm4
	add	edi,DWORD [36+esp]
	xor	ebp,ecx
	mov	esi,eax
	rol	eax,5
	movdqa	xmm4,xmm2
	movdqa	[16+esp],xmm5
	add	edi,ebp
	xor	esi,ecx
	ror	ebx,7
	add	edi,eax
	pslld	xmm2,2
	add	edx,DWORD [40+esp]
	xor	esi,ebx
	psrld	xmm4,30
	mov	ebp,edi
	rol	edi,5
	add	edx,esi
	xor	ebp,ebx
	ror	eax,7
	add	edx,edi
	por	xmm2,xmm4
	add	ecx,DWORD [44+esp]
	xor	ebp,eax
	movdqa	xmm4,[80+esp]
	mov	esi,edx
	rol	edx,5
	add	ecx,ebp
	xor	esi,eax
	ror	edi,7
	pshufd	xmm5,xmm1,238
	add	ecx,edx
	add	ebx,DWORD [48+esp]
	pxor	xmm3,xmm7
	punpcklqdq	xmm5,xmm2
	xor	esi,edi
	mov	ebp,ecx
	rol	ecx,5
	pxor	xmm3,xmm4
	movdqa	[80+esp],xmm7
	add	ebx,esi
	xor	ebp,edi
	movdqa	xmm7,xmm6
	ror	edx,7
	paddd	xmm6,xmm2
	add	ebx,ecx
	pxor	xmm3,xmm5
	add	eax,DWORD [52+esp]
	xor	ebp,edx
	mov	esi,ebx
	rol	ebx,5
	movdqa	xmm5,xmm3
	movdqa	[32+esp],xmm6
	add	eax,ebp
	xor	esi,edx
	ror	ecx,7
	add	eax,ebx
	pslld	xmm3,2
	add	edi,DWORD [56+esp]
	xor	esi,ecx
	psrld	xmm5,30
	mov	ebp,eax
	rol	eax,5
	add	edi,esi
	xor	ebp,ecx
	ror	ebx,7
	add	edi,eax
	por	xmm3,xmm5
	add	edx,DWORD [60+esp]
	xor	ebp,ebx
	movdqa	xmm5,[96+esp]
	mov	esi,edi
	rol	edi,5
	add	edx,ebp
	xor	esi,ebx
	ror	eax,7
	pshufd	xmm6,xmm2,238
	add	edx,edi
	add	ecx,DWORD [esp]
	pxor	xmm4,xmm0
	punpcklqdq	xmm6,xmm3
	xor	esi,eax
	mov	ebp,edx
	rol	edx,5
	pxor	xmm4,xmm5
	movdqa	[96+esp],xmm0
	add	ecx,esi
	xor	ebp,eax
	movdqa	xmm0,xmm7
	ror	edi,7
	paddd	xmm7,xmm3
	add	ecx,edx
	pxor	xmm4,xmm6
	add	ebx,DWORD [4+esp]
	xor	ebp,edi
	mov	esi,ecx
	rol	ecx,5
	movdqa	xmm6,xmm4
	movdqa	[48+esp],xmm7
	add	ebx,ebp
	xor	esi,edi
	ror	edx,7
	add	ebx,ecx
	pslld	xmm4,2
	add	eax,DWORD [8+esp]
	xor	esi,edx
	psrld	xmm6,30
	mov	ebp,ebx
	rol	ebx,5
	add	eax,esi
	xor	ebp,edx
	ror	ecx,7
	add	eax,ebx
	por	xmm4,xmm6
	add	edi,DWORD [12+esp]
	xor	ebp,ecx
	movdqa	xmm6,[64+esp]
	mov	esi,eax
	rol	eax,5
	add	edi,ebp
	xor	esi,ecx
	ror	ebx,7
	pshufd	xmm7,xmm3,238
	add	edi,eax
	add	edx,DWORD [16+esp]
	pxor	xmm5,xmm1
	punpcklqdq	xmm7,xmm4
	xor	esi,ebx
	mov	ebp,edi
	rol	edi,5
	pxor	xmm5,xmm6
	movdqa	[64+esp],xmm1
	add	edx,esi
	xor	ebp,ebx
	movdqa	xmm1,xmm0
	ror	eax,7
	paddd	xmm0,xmm4
	add	edx,edi
	pxor	xmm5,xmm7
	add	ecx,DWORD [20+esp]
	xor	ebp,eax
	mov	esi,edx
	rol	edx,5
	movdqa	xmm7,xmm5
	movdqa	[esp],xmm0
	add	ecx,ebp
	xor	esi,eax
	ror	edi,7
	add	ecx,edx
	pslld	xmm5,2
	add	ebx,DWORD [24+esp]
	xor	esi,edi
	psrld	xmm7,30
	mov	ebp,ecx
	rol	ecx,5
	add	ebx,esi
	xor	ebp,edi
	ror	edx,7
	add	ebx,ecx
	por	xmm5,xmm7
	add	eax,DWORD [28+esp]
	movdqa	xmm7,[80+esp]
	ror	ecx,7
	mov	esi,ebx
	xor	ebp,edx
	rol	ebx,5
	pshufd	xmm0,xmm4,238
	add	eax,ebp
	xor	esi,ecx
	xor	ecx,edx
	add	eax,ebx
	add	edi,DWORD [32+esp]
	pxor	xmm6,xmm2
	punpcklqdq	xmm0,xmm5
	and	esi,ecx
	xor	ecx,edx
	ror	ebx,7
	pxor	xmm6,xmm7
	movdqa	[80+esp],xmm2
	mov	ebp,eax
	xor	esi,ecx
	rol	eax,5
	movdqa	xmm2,xmm1
	add	edi,esi
	paddd	xmm1,xmm5
	xor	ebp,ebx
	pxor	xmm6,xmm0
	xor	ebx,ecx
	add	edi,eax
	add	edx,DWORD [36+esp]
	and	ebp,ebx
	movdqa	xmm0,xmm6
	movdqa	[16+esp],xmm1
	xor	ebx,ecx
	ror	eax,7
	mov	esi,edi
	xor	ebp,ebx
	rol	edi,5
	pslld	xmm6,2
	add	edx,ebp
	xor	esi,eax
	psrld	xmm0,30
	xor	eax,ebx
	add	edx,edi
	add	ecx,DWORD [40+esp]
	and	esi,eax
	xor	eax,ebx
	ror	edi,7
	por	xmm6,xmm0
	mov	ebp,edx
	xor	esi,eax
	movdqa	xmm0,[96+esp]
	rol	edx,5
	add	ecx,esi
	xor	ebp,edi
	xor	edi,eax
	add	ecx,edx
	pshufd	xmm1,xmm5,238
	add	ebx,DWORD [44+esp]
	and	ebp,edi
	xor	edi,eax
	ror	edx,7
	mov	esi,ecx
	xor	ebp,edi
	rol	ecx,5
	add	ebx,ebp
	xor	esi,edx
	xor	edx,edi
	add	ebx,ecx
	add	eax,DWORD [48+esp]
	pxor	xmm7,xmm3
	punpcklqdq	xmm1,xmm6
	and	esi,edx
	xor	edx,edi
	ror	ecx,7
	pxor	xmm7,xmm0
	movdqa	[96+esp],xmm3
	mov	ebp,ebx
	xor	esi,edx
	rol	ebx,5
	movdqa	xmm3,[144+esp]
	add	eax,esi
	paddd	xmm2,xmm6
	xor	ebp,ecx
	pxor	xmm7,xmm1
	xor	ecx,edx
	add	eax,ebx
	add	edi,DWORD [52+esp]
	and	ebp,ecx
	movdqa	xmm1,xmm7
	movdqa	[32+esp],xmm2
	xor	ecx,edx
	ror	ebx,7
	mov	esi,eax
	xor	ebp,ecx
	rol	eax,5
	pslld	xmm7,2
	add	edi,ebp
	xor	esi,ebx
	psrld	xmm1,30
	xor	ebx,ecx
	add	edi,eax
	add	edx,DWORD [56+esp]
	and	esi,ebx
	xor	ebx,ecx
	ror	eax,7
	por	xmm7,xmm1
	mov	ebp,edi
	xor	esi,ebx
	movdqa	xmm1,[64+esp]
	rol	edi,5
	add	edx,esi
	xor	ebp,eax
	xor	eax,ebx
	add	edx,edi
	pshufd	xmm2,xmm6,238
	add	ecx,DWORD [60+esp]
	and	ebp,eax
	xor	eax,ebx
	ror	edi,7
	mov	esi,edx
	xor	ebp,eax
	rol	edx,5
	add	ecx,ebp
	xor	esi,edi
	xor	edi,eax
	add	ecx,edx
	add	ebx,DWORD [esp]
	pxor	xmm0,xmm4
	punpcklqdq	xmm2,xmm7
	and	esi,edi
	xor	edi,eax
	ror	edx,7
	pxor	xmm0,xmm1
	movdqa	[64+esp],xmm4
	mov	ebp,ecx
	xor	esi,edi
	rol	ecx,5
	movdqa	xmm4,xmm3
	add	ebx,esi
	paddd	xmm3,xmm7
	xor	ebp,edx
	pxor	xmm0,xmm2
	xor	edx,edi
	add	ebx,ecx
	add	eax,DWORD [4+esp]
	and	ebp,edx
	movdqa	xmm2,xmm0
	movdqa	[48+esp],xmm3
	xor	edx,edi
	ror	ecx,7
	mov	esi,ebx
	xor	ebp,edx
	rol	ebx,5
	pslld	xmm0,2
	add	eax,ebp
	xor	esi,ecx
	psrld	xmm2,30
	xor	ecx,edx
	add	eax,ebx
	add	edi,DWORD [8+esp]
	and	esi,ecx
	xor	ecx,edx
	ror	ebx,7
	por	xmm0,xmm2
	mov	ebp,eax
	xor	esi,ecx
	movdqa	xmm2,[80+esp]
	rol	eax,5
	add	edi,esi
	xor	ebp,ebx
	xor	ebx,ecx
	add	edi,eax
	pshufd	xmm3,xmm7,238
	add	edx,DWORD [12+esp]
	and	ebp,ebx
	xor	ebx,ecx
	ror	eax,7
	mov	esi,edi
	xor	ebp,ebx
	rol	edi,5
	add	edx,ebp
	xor	esi,eax
	xor	eax,ebx
	add	edx,edi
	add	ecx,DWORD [16+esp]
	pxor	xmm1,xmm5
	punpcklqdq	xmm3,xmm0
	and	esi,eax
	xor	eax,ebx
	ror	edi,7
	pxor	xmm1,xmm2
	movdqa	[80+esp],xmm5
	mov	ebp,edx
	xor	esi,eax
	rol	edx,5
	movdqa	xmm5,xmm4
	add	ecx,esi
	paddd	xmm4,xmm0
	xor	ebp,edi
	pxor	xmm1,xmm3
	xor	edi,eax
	add	ecx,edx
	add	ebx,DWORD [20+esp]
	and	ebp,edi
	movdqa	xmm3,xmm1
	movdqa	[esp],xmm4
	xor	edi,eax
	ror	edx,7
	mov	esi,ecx
	xor	ebp,edi
	rol	ecx,5
	pslld	xmm1,2
	add	ebx,ebp
	xor	esi,edx
	psrld	xmm3,30
	xor	edx,edi
	add	ebx,ecx
	add	eax,DWORD [24+esp]
	and	esi,edx
	xor	edx,edi
	ror	ecx,7
	por	xmm1,xmm3
	mov	ebp,ebx
	xor	esi,edx
	movdqa	xmm3,[96+esp]
	rol	ebx,5
	add	eax,esi
	xor	ebp,ecx
	xor	ecx,edx
	add	eax,ebx
	pshufd	xmm4,xmm0,238
	add	edi,DWORD [28+esp]
	and	ebp,ecx
	xor	ecx,edx
	ror	ebx,7
	mov	esi,eax
	xor	ebp,ecx
	rol	eax,5
	add	edi,ebp
	xor	esi,ebx
	xor	ebx,ecx
	add	edi,eax
	add	edx,DWORD [32+esp]
	pxor	xmm2,xmm6
	punpcklqdq	xmm4,xmm1
	and	esi,ebx
	xor	ebx,ecx
	ror	eax,7
	pxor	xmm2,xmm3
	movdqa	[96+esp],xmm6
	mov	ebp,edi
	xor	esi,ebx
	rol	edi,5
	movdqa	xmm6,xmm5
	add	edx,esi
	paddd	xmm5,xmm1
	xor	ebp,eax
	pxor	xmm2,xmm4
	xor	eax,ebx
	add	edx,edi
	add	ecx,DWORD [36+esp]
	and	ebp,eax
	movdqa	xmm4,xmm2
	movdqa	[16+esp],xmm5
	xor	eax,ebx
	ror	edi,7
	mov	esi,edx
	xor	ebp,eax
	rol	edx,5
	pslld	xmm2,2
	add	ecx,ebp
	xor	esi,edi
	psrld	xmm4,30
	xor	edi,eax
	add	ecx,edx
	add	ebx,DWORD [40+esp]
	and	esi,edi
	xor	edi,eax
	ror	edx,7
	por	xmm2,xmm4
	mov	ebp,ecx
	xor	esi,edi
	movdqa	xmm4,[64+esp]
	rol	ecx,5
	add	ebx,esi
	xor	ebp,edx
	xor	edx,edi
	add	ebx,ecx
	pshufd	xmm5,xmm1,238
	add	eax,DWORD [44+esp]
	and	ebp,edx
	xor	edx,edi
	ror	ecx,7
	mov	esi,ebx
	xor	ebp,edx
	rol	ebx,5
	add	eax,ebp
	xor	esi,edx
	add	eax,ebx
	add	edi,DWORD [48+esp]
	pxor	xmm3,xmm7
	punpcklqdq	xmm5,xmm2
	xor	esi,ecx
	mov	ebp,eax
	rol	eax,5
	pxor	xmm3,xmm4
	movdqa	[64+esp],xmm7
	add	edi,esi
	xor	ebp,ecx
	movdqa	xmm7,xmm6
	ror	ebx,7
	paddd	xmm6,xmm2
	add	edi,eax
	pxor	xmm3,xmm5
	add	edx,DWORD [52+esp]
	xor	ebp,ebx
	mov	esi,edi
	rol	edi,5
	movdqa	xmm5,xmm3
	movdqa	[32+esp],xmm6
	add	edx,ebp
	xor	esi,ebx
	ror	eax,7
	add	edx,edi
	pslld	xmm3,2
	add	ecx,DWORD [56+esp]
	xor	esi,eax
	psrld	xmm5,30
	mov	ebp,edx
	rol	edx,5
	add	ecx,esi
	xor	ebp,eax
	ror	edi,7
	add	ecx,edx
	por	xmm3,xmm5
	add	ebx,DWORD [60+esp]
	xor	ebp,edi
	mov	esi,ecx
	rol	ecx,5
	add	ebx,ebp
	xor	esi,edi
	ror	edx,7
	add	ebx,ecx
	add	eax,DWORD [esp]
	xor	esi,edx
	mov	ebp,ebx
	rol	ebx,5
	add	eax,esi
	xor	ebp,edx
	ror	ecx,7
	paddd	xmm7,xmm3
	add	eax,ebx
	add	edi,DWORD [4+esp]
	xor	ebp,ecx
	mov	esi,eax
	movdqa	[48+esp],xmm7
	rol	eax,5
	add	edi,ebp
	xor	esi,ecx
	ror	ebx,7
	add	edi,eax
	add	edx,DWORD [8+esp]
	xor	esi,ebx
	mov	ebp,edi
	rol	edi,5
	add	edx,esi
	xor	ebp,ebx
	ror	eax,7
	add	edx,edi
	add	ecx,DWORD [12+esp]
	xor	ebp,eax
	mov	esi,edx
	rol	edx,5
	add	ecx,ebp
	xor	esi,eax
	ror	edi,7
	add	ecx,edx
	mov	ebp,DWORD [196+esp]
	cmp	ebp,DWORD [200+esp]
	je	NEAR L$007done
	movdqa	xmm7,[160+esp]
	movdqa	xmm6,[176+esp]
	movdqu	xmm0,[ebp]
	movdqu	xmm1,[16+ebp]
	movdqu	xmm2,[32+ebp]
	movdqu	xmm3,[48+ebp]
	add	ebp,64
db	102,15,56,0,198
	mov	DWORD [196+esp],ebp
	movdqa	[96+esp],xmm7
	add	ebx,DWORD [16+esp]
	xor	esi,edi
	mov	ebp,ecx
	rol	ecx,5
	add	ebx,esi
	xor	ebp,edi
	ror	edx,7
db	102,15,56,0,206
	add	ebx,ecx
	add	eax,DWORD [20+esp]
	xor	ebp,edx
	mov	esi,ebx
	paddd	xmm0,xmm7
	rol	ebx,5
	add	eax,ebp
	xor	esi,edx
	ror	ecx,7
	movdqa	[esp],xmm0
	add	eax,ebx
	add	edi,DWORD [24+esp]
	xor	esi,ecx
	mov	ebp,eax
	psubd	xmm0,xmm7
	rol	eax,5
	add	edi,esi
	xor	ebp,ecx
	ror	ebx,7
	add	edi,eax
	add	edx,DWORD [28+esp]
	xor	ebp,ebx
	mov	esi,edi
	rol	edi,5
	add	edx,ebp
	xor	esi,ebx
	ror	eax,7
	add	edx,edi
	add	ecx,DWORD [32+esp]
	xor	esi,eax
	mov	ebp,edx
	rol	edx,5
	add	ecx,esi
	xor	ebp,eax
	ror	edi,7
db	102,15,56,0,214
	add	ecx,edx
	add	ebx,DWORD [36+esp]
	xor	ebp,edi
	mov	esi,ecx
	paddd	xmm1,xmm7
	rol	ecx,5
	add	ebx,ebp
	xor	esi,edi
	ror	edx,7
	movdqa	[16+esp],xmm1
	add	ebx,ecx
	add	eax,DWORD [40+esp]
	xor	esi,edx
	mov	ebp,ebx
	psubd	xmm1,xmm7
	rol	ebx,5
	add	eax,esi
	xor	ebp,edx
	ror	ecx,7
	add	eax,ebx
	add	edi,DWORD [44+esp]
	xor	ebp,ecx
	mov	esi,eax
	rol	eax,5
	add	edi,ebp
	xor	esi,ecx
	ror	ebx,7
	add	edi,eax
	add	edx,DWORD [48+esp]
	xor	esi,ebx
	mov	ebp,edi
	rol	edi,5
	add	edx,esi
	xor	ebp,ebx
	ror	eax,7
db	102,15,56,0,222
	add	edx,edi
	add	ecx,DWORD [52+esp]
	xor	ebp,eax
	mov	esi,edx
	paddd	xmm2,xmm7
	rol	edx,5
	add	ecx,ebp
	xor	esi,eax
	ror	edi,7
	movdqa	[32+esp],xmm2
	add	ecx,edx
	add	ebx,DWORD [56+esp]
	xor	esi,edi
	mov	ebp,ecx
	psubd	xmm2,xmm7
	rol	ecx,5
	add	ebx,esi
	xor	ebp,edi
	ror	edx,7
	add	ebx,ecx
	add	eax,DWORD [60+esp]
	xor	ebp,edx
	mov	esi,ebx
	rol	ebx,5
	add	eax,ebp
	ror	ecx,7
	add	eax,ebx
	mov	ebp,DWORD [192+esp]
	add	eax,DWORD [ebp]
	add	esi,DWORD [4+ebp]
	add	ecx,DWORD [8+ebp]
	mov	DWORD [ebp],eax
	add	edx,DWORD [12+ebp]
	mov	DWORD [4+ebp],esi
	add	edi,DWORD [16+ebp]
	mov	DWORD [8+ebp],ecx
	mov	ebx,ecx
	mov	DWORD [12+ebp],edx
	xor	ebx,edx
	mov	DWORD [16+ebp],edi
	mov	ebp,esi
	pshufd	xmm4,xmm0,238
	and	esi,ebx
	mov	ebx,ebp
	jmp	NEAR L$006loop
align	16
L$007done:
	add	ebx,DWORD [16+esp]
	xor	esi,edi
	mov	ebp,ecx
	rol	ecx,5
	add	ebx,esi
	xor	ebp,edi
	ror	edx,7
	add	ebx,ecx
	add	eax,DWORD [20+esp]
	xor	ebp,edx
	mov	esi,ebx
	rol	ebx,5
	add	eax,ebp
	xor	esi,edx
	ror	ecx,7
	add	eax,ebx
	add	edi,DWORD [24+esp]
	xor	esi,ecx
	mov	ebp,eax
	rol	eax,5
	add	edi,esi
	xor	ebp,ecx
	ror	ebx,7
	add	edi,eax
	add	edx,DWORD [28+esp]
	xor	ebp,ebx
	mov	esi,edi
	rol	edi,5
	add	edx,ebp
	xor	esi,ebx
	ror	eax,7
	add	edx,edi
	add	ecx,DWORD [32+esp]
	xor	esi,eax
	mov	ebp,edx
	rol	edx,5
	add	ecx,esi
	xor	ebp,eax
	ror	edi,7
	add	ecx,edx
	add	ebx,DWORD [36+esp]
	xor	ebp,edi
	mov	esi,ecx
	rol	ecx,5
	add	ebx,ebp
	xor	esi,edi
	ror	edx,7
	add	ebx,ecx
	add	eax,DWORD [40+esp]
	xor	esi,edx
	mov	ebp,ebx
	rol	ebx,5
	add	eax,esi
	xor	ebp,edx
	ror	ecx,7
	add	eax,ebx
	add	edi,DWORD [44+esp]
	xor	ebp,ecx
	mov	esi,eax
	rol	eax,5
	add	edi,ebp
	xor	esi,ecx
	ror	ebx,7
	add	edi,eax
	add	edx,DWORD [48+esp]
	xor	esi,ebx
	mov	ebp,edi
	rol	edi,5
	add	edx,esi
	xor	ebp,ebx
	ror	eax,7
	add	edx,edi
	add	ecx,DWORD [52+esp]
	xor	ebp,eax
	mov	esi,edx
	rol	edx,5
	add	ecx,ebp
	xor	esi,eax
	ror	edi,7
	add	ecx,edx
	add	ebx,DWORD [56+esp]
	xor	esi,edi
	mov	ebp,ecx
	rol	ecx,5
	add	ebx,esi
	xor	ebp,edi
	ror	edx,7
	add	ebx,ecx
	add	eax,DWORD [60+esp]
	xor	ebp,edx
	mov	esi,ebx
	rol	ebx,5
	add	eax,ebp
	ror	ecx,7
	add	eax,ebx
	mov	ebp,DWORD [192+esp]
	add	eax,DWORD [ebp]
	mov	esp,DWORD [204+esp]
	add	esi,DWORD [4+ebp]
	add	ecx,DWORD [8+ebp]
	mov	DWORD [ebp],eax
	add	edx,DWORD [12+ebp]
	mov	DWORD [4+ebp],esi
	add	edi,DWORD [16+ebp]
	mov	DWORD [8+ebp],ecx
	mov	DWORD [12+ebp],edx
	mov	DWORD [16+ebp],edi
	pop	edi
	pop	esi
	pop	ebx
	pop	ebp
	ret
align	64
L$K_XX_XX:
dd	1518500249,1518500249,1518500249,1518500249
dd	1859775393,1859775393,1859775393,1859775393
dd	2400959708,2400959708,2400959708,2400959708
dd	3395469782,3395469782,3395469782,3395469782
dd	66051,67438087,134810123,202182159
db	15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,0
db	83,72,65,49,32,98,108,111,99,107,32,116,114,97,110,115
db	102,111,114,109,32,102,111,114,32,120,56,54,44,32,67,82
db	89,80,84,79,71,65,77,83,32,98,121,32,60,97,112,112
db	114,111,64,111,112,101,110,115,115,108,46,111,114,103,62,0
segment	.bss
common	_OPENSSL_ia32cap_P 16
