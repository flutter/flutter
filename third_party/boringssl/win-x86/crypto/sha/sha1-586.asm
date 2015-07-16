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
global	_sha1_block_data_order
align	16
_sha1_block_data_order:
L$_sha1_block_data_order_begin:
	push	ebp
	push	ebx
	push	esi
	push	edi
	mov	ebp,DWORD [20+esp]
	mov	esi,DWORD [24+esp]
	mov	eax,DWORD [28+esp]
	sub	esp,76
	shl	eax,6
	add	eax,esi
	mov	DWORD [104+esp],eax
	mov	edi,DWORD [16+ebp]
	jmp	NEAR L$000loop
align	16
L$000loop:
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
	jb	NEAR L$000loop
	add	esp,76
	pop	edi
	pop	esi
	pop	ebx
	pop	ebp
	ret
db	83,72,65,49,32,98,108,111,99,107,32,116,114,97,110,115
db	102,111,114,109,32,102,111,114,32,120,56,54,44,32,67,82
db	89,80,84,79,71,65,77,83,32,98,121,32,60,97,112,112
db	114,111,64,111,112,101,110,115,115,108,46,111,114,103,62,0
