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
align	16
__x86_AES_encrypt_compact:
	mov	DWORD [20+esp],edi
	xor	eax,DWORD [edi]
	xor	ebx,DWORD [4+edi]
	xor	ecx,DWORD [8+edi]
	xor	edx,DWORD [12+edi]
	mov	esi,DWORD [240+edi]
	lea	esi,[esi*1+esi-2]
	lea	esi,[esi*8+edi]
	mov	DWORD [24+esp],esi
	mov	edi,DWORD [ebp-128]
	mov	esi,DWORD [ebp-96]
	mov	edi,DWORD [ebp-64]
	mov	esi,DWORD [ebp-32]
	mov	edi,DWORD [ebp]
	mov	esi,DWORD [32+ebp]
	mov	edi,DWORD [64+ebp]
	mov	esi,DWORD [96+ebp]
align	16
L$000loop:
	mov	esi,eax
	and	esi,255
	movzx	esi,BYTE [esi*1+ebp-128]
	movzx	edi,bh
	movzx	edi,BYTE [edi*1+ebp-128]
	shl	edi,8
	xor	esi,edi
	mov	edi,ecx
	shr	edi,16
	and	edi,255
	movzx	edi,BYTE [edi*1+ebp-128]
	shl	edi,16
	xor	esi,edi
	mov	edi,edx
	shr	edi,24
	movzx	edi,BYTE [edi*1+ebp-128]
	shl	edi,24
	xor	esi,edi
	mov	DWORD [4+esp],esi
	mov	esi,ebx
	and	esi,255
	shr	ebx,16
	movzx	esi,BYTE [esi*1+ebp-128]
	movzx	edi,ch
	movzx	edi,BYTE [edi*1+ebp-128]
	shl	edi,8
	xor	esi,edi
	mov	edi,edx
	shr	edi,16
	and	edi,255
	movzx	edi,BYTE [edi*1+ebp-128]
	shl	edi,16
	xor	esi,edi
	mov	edi,eax
	shr	edi,24
	movzx	edi,BYTE [edi*1+ebp-128]
	shl	edi,24
	xor	esi,edi
	mov	DWORD [8+esp],esi
	mov	esi,ecx
	and	esi,255
	shr	ecx,24
	movzx	esi,BYTE [esi*1+ebp-128]
	movzx	edi,dh
	movzx	edi,BYTE [edi*1+ebp-128]
	shl	edi,8
	xor	esi,edi
	mov	edi,eax
	shr	edi,16
	and	edx,255
	and	edi,255
	movzx	edi,BYTE [edi*1+ebp-128]
	shl	edi,16
	xor	esi,edi
	movzx	edi,bh
	movzx	edi,BYTE [edi*1+ebp-128]
	shl	edi,24
	xor	esi,edi
	and	edx,255
	movzx	edx,BYTE [edx*1+ebp-128]
	movzx	eax,ah
	movzx	eax,BYTE [eax*1+ebp-128]
	shl	eax,8
	xor	edx,eax
	mov	eax,DWORD [4+esp]
	and	ebx,255
	movzx	ebx,BYTE [ebx*1+ebp-128]
	shl	ebx,16
	xor	edx,ebx
	mov	ebx,DWORD [8+esp]
	movzx	ecx,BYTE [ecx*1+ebp-128]
	shl	ecx,24
	xor	edx,ecx
	mov	ecx,esi
	mov	ebp,2155905152
	and	ebp,ecx
	lea	edi,[ecx*1+ecx]
	mov	esi,ebp
	shr	ebp,7
	and	edi,4278124286
	sub	esi,ebp
	mov	ebp,ecx
	and	esi,454761243
	ror	ebp,16
	xor	esi,edi
	mov	edi,ecx
	xor	ecx,esi
	ror	edi,24
	xor	esi,ebp
	rol	ecx,24
	xor	esi,edi
	mov	ebp,2155905152
	xor	ecx,esi
	and	ebp,edx
	lea	edi,[edx*1+edx]
	mov	esi,ebp
	shr	ebp,7
	and	edi,4278124286
	sub	esi,ebp
	mov	ebp,edx
	and	esi,454761243
	ror	ebp,16
	xor	esi,edi
	mov	edi,edx
	xor	edx,esi
	ror	edi,24
	xor	esi,ebp
	rol	edx,24
	xor	esi,edi
	mov	ebp,2155905152
	xor	edx,esi
	and	ebp,eax
	lea	edi,[eax*1+eax]
	mov	esi,ebp
	shr	ebp,7
	and	edi,4278124286
	sub	esi,ebp
	mov	ebp,eax
	and	esi,454761243
	ror	ebp,16
	xor	esi,edi
	mov	edi,eax
	xor	eax,esi
	ror	edi,24
	xor	esi,ebp
	rol	eax,24
	xor	esi,edi
	mov	ebp,2155905152
	xor	eax,esi
	and	ebp,ebx
	lea	edi,[ebx*1+ebx]
	mov	esi,ebp
	shr	ebp,7
	and	edi,4278124286
	sub	esi,ebp
	mov	ebp,ebx
	and	esi,454761243
	ror	ebp,16
	xor	esi,edi
	mov	edi,ebx
	xor	ebx,esi
	ror	edi,24
	xor	esi,ebp
	rol	ebx,24
	xor	esi,edi
	xor	ebx,esi
	mov	edi,DWORD [20+esp]
	mov	ebp,DWORD [28+esp]
	add	edi,16
	xor	eax,DWORD [edi]
	xor	ebx,DWORD [4+edi]
	xor	ecx,DWORD [8+edi]
	xor	edx,DWORD [12+edi]
	cmp	edi,DWORD [24+esp]
	mov	DWORD [20+esp],edi
	jb	NEAR L$000loop
	mov	esi,eax
	and	esi,255
	movzx	esi,BYTE [esi*1+ebp-128]
	movzx	edi,bh
	movzx	edi,BYTE [edi*1+ebp-128]
	shl	edi,8
	xor	esi,edi
	mov	edi,ecx
	shr	edi,16
	and	edi,255
	movzx	edi,BYTE [edi*1+ebp-128]
	shl	edi,16
	xor	esi,edi
	mov	edi,edx
	shr	edi,24
	movzx	edi,BYTE [edi*1+ebp-128]
	shl	edi,24
	xor	esi,edi
	mov	DWORD [4+esp],esi
	mov	esi,ebx
	and	esi,255
	shr	ebx,16
	movzx	esi,BYTE [esi*1+ebp-128]
	movzx	edi,ch
	movzx	edi,BYTE [edi*1+ebp-128]
	shl	edi,8
	xor	esi,edi
	mov	edi,edx
	shr	edi,16
	and	edi,255
	movzx	edi,BYTE [edi*1+ebp-128]
	shl	edi,16
	xor	esi,edi
	mov	edi,eax
	shr	edi,24
	movzx	edi,BYTE [edi*1+ebp-128]
	shl	edi,24
	xor	esi,edi
	mov	DWORD [8+esp],esi
	mov	esi,ecx
	and	esi,255
	shr	ecx,24
	movzx	esi,BYTE [esi*1+ebp-128]
	movzx	edi,dh
	movzx	edi,BYTE [edi*1+ebp-128]
	shl	edi,8
	xor	esi,edi
	mov	edi,eax
	shr	edi,16
	and	edx,255
	and	edi,255
	movzx	edi,BYTE [edi*1+ebp-128]
	shl	edi,16
	xor	esi,edi
	movzx	edi,bh
	movzx	edi,BYTE [edi*1+ebp-128]
	shl	edi,24
	xor	esi,edi
	mov	edi,DWORD [20+esp]
	and	edx,255
	movzx	edx,BYTE [edx*1+ebp-128]
	movzx	eax,ah
	movzx	eax,BYTE [eax*1+ebp-128]
	shl	eax,8
	xor	edx,eax
	mov	eax,DWORD [4+esp]
	and	ebx,255
	movzx	ebx,BYTE [ebx*1+ebp-128]
	shl	ebx,16
	xor	edx,ebx
	mov	ebx,DWORD [8+esp]
	movzx	ecx,BYTE [ecx*1+ebp-128]
	shl	ecx,24
	xor	edx,ecx
	mov	ecx,esi
	xor	eax,DWORD [16+edi]
	xor	ebx,DWORD [20+edi]
	xor	ecx,DWORD [24+edi]
	xor	edx,DWORD [28+edi]
	ret
align	16
__sse_AES_encrypt_compact:
	pxor	mm0,[edi]
	pxor	mm4,[8+edi]
	mov	esi,DWORD [240+edi]
	lea	esi,[esi*1+esi-2]
	lea	esi,[esi*8+edi]
	mov	DWORD [24+esp],esi
	mov	eax,454761243
	mov	DWORD [8+esp],eax
	mov	DWORD [12+esp],eax
	mov	eax,DWORD [ebp-128]
	mov	ebx,DWORD [ebp-96]
	mov	ecx,DWORD [ebp-64]
	mov	edx,DWORD [ebp-32]
	mov	eax,DWORD [ebp]
	mov	ebx,DWORD [32+ebp]
	mov	ecx,DWORD [64+ebp]
	mov	edx,DWORD [96+ebp]
align	16
L$001loop:
	pshufw	mm1,mm0,8
	pshufw	mm5,mm4,13
	movd	eax,mm1
	movd	ebx,mm5
	mov	DWORD [20+esp],edi
	movzx	esi,al
	movzx	edx,ah
	pshufw	mm2,mm0,13
	movzx	ecx,BYTE [esi*1+ebp-128]
	movzx	edi,bl
	movzx	edx,BYTE [edx*1+ebp-128]
	shr	eax,16
	shl	edx,8
	movzx	esi,BYTE [edi*1+ebp-128]
	movzx	edi,bh
	shl	esi,16
	pshufw	mm6,mm4,8
	or	ecx,esi
	movzx	esi,BYTE [edi*1+ebp-128]
	movzx	edi,ah
	shl	esi,24
	shr	ebx,16
	or	edx,esi
	movzx	esi,BYTE [edi*1+ebp-128]
	movzx	edi,bh
	shl	esi,8
	or	ecx,esi
	movzx	esi,BYTE [edi*1+ebp-128]
	movzx	edi,al
	shl	esi,24
	or	ecx,esi
	movzx	esi,BYTE [edi*1+ebp-128]
	movzx	edi,bl
	movd	eax,mm2
	movd	mm0,ecx
	movzx	ecx,BYTE [edi*1+ebp-128]
	movzx	edi,ah
	shl	ecx,16
	movd	ebx,mm6
	or	ecx,esi
	movzx	esi,BYTE [edi*1+ebp-128]
	movzx	edi,bh
	shl	esi,24
	or	ecx,esi
	movzx	esi,BYTE [edi*1+ebp-128]
	movzx	edi,bl
	shl	esi,8
	shr	ebx,16
	or	ecx,esi
	movzx	esi,BYTE [edi*1+ebp-128]
	movzx	edi,al
	shr	eax,16
	movd	mm1,ecx
	movzx	ecx,BYTE [edi*1+ebp-128]
	movzx	edi,ah
	shl	ecx,16
	and	eax,255
	or	ecx,esi
	punpckldq	mm0,mm1
	movzx	esi,BYTE [edi*1+ebp-128]
	movzx	edi,bh
	shl	esi,24
	and	ebx,255
	movzx	eax,BYTE [eax*1+ebp-128]
	or	ecx,esi
	shl	eax,16
	movzx	esi,BYTE [edi*1+ebp-128]
	or	edx,eax
	shl	esi,8
	movzx	ebx,BYTE [ebx*1+ebp-128]
	or	ecx,esi
	or	edx,ebx
	mov	edi,DWORD [20+esp]
	movd	mm4,ecx
	movd	mm5,edx
	punpckldq	mm4,mm5
	add	edi,16
	cmp	edi,DWORD [24+esp]
	ja	NEAR L$002out
	movq	mm2,[8+esp]
	pxor	mm3,mm3
	pxor	mm7,mm7
	movq	mm1,mm0
	movq	mm5,mm4
	pcmpgtb	mm3,mm0
	pcmpgtb	mm7,mm4
	pand	mm3,mm2
	pand	mm7,mm2
	pshufw	mm2,mm0,177
	pshufw	mm6,mm4,177
	paddb	mm0,mm0
	paddb	mm4,mm4
	pxor	mm0,mm3
	pxor	mm4,mm7
	pshufw	mm3,mm2,177
	pshufw	mm7,mm6,177
	pxor	mm1,mm0
	pxor	mm5,mm4
	pxor	mm0,mm2
	pxor	mm4,mm6
	movq	mm2,mm3
	movq	mm6,mm7
	pslld	mm3,8
	pslld	mm7,8
	psrld	mm2,24
	psrld	mm6,24
	pxor	mm0,mm3
	pxor	mm4,mm7
	pxor	mm0,mm2
	pxor	mm4,mm6
	movq	mm3,mm1
	movq	mm7,mm5
	movq	mm2,[edi]
	movq	mm6,[8+edi]
	psrld	mm1,8
	psrld	mm5,8
	mov	eax,DWORD [ebp-128]
	pslld	mm3,24
	pslld	mm7,24
	mov	ebx,DWORD [ebp-64]
	pxor	mm0,mm1
	pxor	mm4,mm5
	mov	ecx,DWORD [ebp]
	pxor	mm0,mm3
	pxor	mm4,mm7
	mov	edx,DWORD [64+ebp]
	pxor	mm0,mm2
	pxor	mm4,mm6
	jmp	NEAR L$001loop
align	16
L$002out:
	pxor	mm0,[edi]
	pxor	mm4,[8+edi]
	ret
align	16
__x86_AES_encrypt:
	mov	DWORD [20+esp],edi
	xor	eax,DWORD [edi]
	xor	ebx,DWORD [4+edi]
	xor	ecx,DWORD [8+edi]
	xor	edx,DWORD [12+edi]
	mov	esi,DWORD [240+edi]
	lea	esi,[esi*1+esi-2]
	lea	esi,[esi*8+edi]
	mov	DWORD [24+esp],esi
align	16
L$003loop:
	mov	esi,eax
	and	esi,255
	mov	esi,DWORD [esi*8+ebp]
	movzx	edi,bh
	xor	esi,DWORD [3+edi*8+ebp]
	mov	edi,ecx
	shr	edi,16
	and	edi,255
	xor	esi,DWORD [2+edi*8+ebp]
	mov	edi,edx
	shr	edi,24
	xor	esi,DWORD [1+edi*8+ebp]
	mov	DWORD [4+esp],esi
	mov	esi,ebx
	and	esi,255
	shr	ebx,16
	mov	esi,DWORD [esi*8+ebp]
	movzx	edi,ch
	xor	esi,DWORD [3+edi*8+ebp]
	mov	edi,edx
	shr	edi,16
	and	edi,255
	xor	esi,DWORD [2+edi*8+ebp]
	mov	edi,eax
	shr	edi,24
	xor	esi,DWORD [1+edi*8+ebp]
	mov	DWORD [8+esp],esi
	mov	esi,ecx
	and	esi,255
	shr	ecx,24
	mov	esi,DWORD [esi*8+ebp]
	movzx	edi,dh
	xor	esi,DWORD [3+edi*8+ebp]
	mov	edi,eax
	shr	edi,16
	and	edx,255
	and	edi,255
	xor	esi,DWORD [2+edi*8+ebp]
	movzx	edi,bh
	xor	esi,DWORD [1+edi*8+ebp]
	mov	edi,DWORD [20+esp]
	mov	edx,DWORD [edx*8+ebp]
	movzx	eax,ah
	xor	edx,DWORD [3+eax*8+ebp]
	mov	eax,DWORD [4+esp]
	and	ebx,255
	xor	edx,DWORD [2+ebx*8+ebp]
	mov	ebx,DWORD [8+esp]
	xor	edx,DWORD [1+ecx*8+ebp]
	mov	ecx,esi
	add	edi,16
	xor	eax,DWORD [edi]
	xor	ebx,DWORD [4+edi]
	xor	ecx,DWORD [8+edi]
	xor	edx,DWORD [12+edi]
	cmp	edi,DWORD [24+esp]
	mov	DWORD [20+esp],edi
	jb	NEAR L$003loop
	mov	esi,eax
	and	esi,255
	mov	esi,DWORD [2+esi*8+ebp]
	and	esi,255
	movzx	edi,bh
	mov	edi,DWORD [edi*8+ebp]
	and	edi,65280
	xor	esi,edi
	mov	edi,ecx
	shr	edi,16
	and	edi,255
	mov	edi,DWORD [edi*8+ebp]
	and	edi,16711680
	xor	esi,edi
	mov	edi,edx
	shr	edi,24
	mov	edi,DWORD [2+edi*8+ebp]
	and	edi,4278190080
	xor	esi,edi
	mov	DWORD [4+esp],esi
	mov	esi,ebx
	and	esi,255
	shr	ebx,16
	mov	esi,DWORD [2+esi*8+ebp]
	and	esi,255
	movzx	edi,ch
	mov	edi,DWORD [edi*8+ebp]
	and	edi,65280
	xor	esi,edi
	mov	edi,edx
	shr	edi,16
	and	edi,255
	mov	edi,DWORD [edi*8+ebp]
	and	edi,16711680
	xor	esi,edi
	mov	edi,eax
	shr	edi,24
	mov	edi,DWORD [2+edi*8+ebp]
	and	edi,4278190080
	xor	esi,edi
	mov	DWORD [8+esp],esi
	mov	esi,ecx
	and	esi,255
	shr	ecx,24
	mov	esi,DWORD [2+esi*8+ebp]
	and	esi,255
	movzx	edi,dh
	mov	edi,DWORD [edi*8+ebp]
	and	edi,65280
	xor	esi,edi
	mov	edi,eax
	shr	edi,16
	and	edx,255
	and	edi,255
	mov	edi,DWORD [edi*8+ebp]
	and	edi,16711680
	xor	esi,edi
	movzx	edi,bh
	mov	edi,DWORD [2+edi*8+ebp]
	and	edi,4278190080
	xor	esi,edi
	mov	edi,DWORD [20+esp]
	and	edx,255
	mov	edx,DWORD [2+edx*8+ebp]
	and	edx,255
	movzx	eax,ah
	mov	eax,DWORD [eax*8+ebp]
	and	eax,65280
	xor	edx,eax
	mov	eax,DWORD [4+esp]
	and	ebx,255
	mov	ebx,DWORD [ebx*8+ebp]
	and	ebx,16711680
	xor	edx,ebx
	mov	ebx,DWORD [8+esp]
	mov	ecx,DWORD [2+ecx*8+ebp]
	and	ecx,4278190080
	xor	edx,ecx
	mov	ecx,esi
	add	edi,16
	xor	eax,DWORD [edi]
	xor	ebx,DWORD [4+edi]
	xor	ecx,DWORD [8+edi]
	xor	edx,DWORD [12+edi]
	ret
align	64
L$AES_Te:
dd	2774754246,2774754246
dd	2222750968,2222750968
dd	2574743534,2574743534
dd	2373680118,2373680118
dd	234025727,234025727
dd	3177933782,3177933782
dd	2976870366,2976870366
dd	1422247313,1422247313
dd	1345335392,1345335392
dd	50397442,50397442
dd	2842126286,2842126286
dd	2099981142,2099981142
dd	436141799,436141799
dd	1658312629,1658312629
dd	3870010189,3870010189
dd	2591454956,2591454956
dd	1170918031,1170918031
dd	2642575903,2642575903
dd	1086966153,1086966153
dd	2273148410,2273148410
dd	368769775,368769775
dd	3948501426,3948501426
dd	3376891790,3376891790
dd	200339707,200339707
dd	3970805057,3970805057
dd	1742001331,1742001331
dd	4255294047,4255294047
dd	3937382213,3937382213
dd	3214711843,3214711843
dd	4154762323,4154762323
dd	2524082916,2524082916
dd	1539358875,1539358875
dd	3266819957,3266819957
dd	486407649,486407649
dd	2928907069,2928907069
dd	1780885068,1780885068
dd	1513502316,1513502316
dd	1094664062,1094664062
dd	49805301,49805301
dd	1338821763,1338821763
dd	1546925160,1546925160
dd	4104496465,4104496465
dd	887481809,887481809
dd	150073849,150073849
dd	2473685474,2473685474
dd	1943591083,1943591083
dd	1395732834,1395732834
dd	1058346282,1058346282
dd	201589768,201589768
dd	1388824469,1388824469
dd	1696801606,1696801606
dd	1589887901,1589887901
dd	672667696,672667696
dd	2711000631,2711000631
dd	251987210,251987210
dd	3046808111,3046808111
dd	151455502,151455502
dd	907153956,907153956
dd	2608889883,2608889883
dd	1038279391,1038279391
dd	652995533,652995533
dd	1764173646,1764173646
dd	3451040383,3451040383
dd	2675275242,2675275242
dd	453576978,453576978
dd	2659418909,2659418909
dd	1949051992,1949051992
dd	773462580,773462580
dd	756751158,756751158
dd	2993581788,2993581788
dd	3998898868,3998898868
dd	4221608027,4221608027
dd	4132590244,4132590244
dd	1295727478,1295727478
dd	1641469623,1641469623
dd	3467883389,3467883389
dd	2066295122,2066295122
dd	1055122397,1055122397
dd	1898917726,1898917726
dd	2542044179,2542044179
dd	4115878822,4115878822
dd	1758581177,1758581177
dd	0,0
dd	753790401,753790401
dd	1612718144,1612718144
dd	536673507,536673507
dd	3367088505,3367088505
dd	3982187446,3982187446
dd	3194645204,3194645204
dd	1187761037,1187761037
dd	3653156455,3653156455
dd	1262041458,1262041458
dd	3729410708,3729410708
dd	3561770136,3561770136
dd	3898103984,3898103984
dd	1255133061,1255133061
dd	1808847035,1808847035
dd	720367557,720367557
dd	3853167183,3853167183
dd	385612781,385612781
dd	3309519750,3309519750
dd	3612167578,3612167578
dd	1429418854,1429418854
dd	2491778321,2491778321
dd	3477423498,3477423498
dd	284817897,284817897
dd	100794884,100794884
dd	2172616702,2172616702
dd	4031795360,4031795360
dd	1144798328,1144798328
dd	3131023141,3131023141
dd	3819481163,3819481163
dd	4082192802,4082192802
dd	4272137053,4272137053
dd	3225436288,3225436288
dd	2324664069,2324664069
dd	2912064063,2912064063
dd	3164445985,3164445985
dd	1211644016,1211644016
dd	83228145,83228145
dd	3753688163,3753688163
dd	3249976951,3249976951
dd	1977277103,1977277103
dd	1663115586,1663115586
dd	806359072,806359072
dd	452984805,452984805
dd	250868733,250868733
dd	1842533055,1842533055
dd	1288555905,1288555905
dd	336333848,336333848
dd	890442534,890442534
dd	804056259,804056259
dd	3781124030,3781124030
dd	2727843637,2727843637
dd	3427026056,3427026056
dd	957814574,957814574
dd	1472513171,1472513171
dd	4071073621,4071073621
dd	2189328124,2189328124
dd	1195195770,1195195770
dd	2892260552,2892260552
dd	3881655738,3881655738
dd	723065138,723065138
dd	2507371494,2507371494
dd	2690670784,2690670784
dd	2558624025,2558624025
dd	3511635870,3511635870
dd	2145180835,2145180835
dd	1713513028,1713513028
dd	2116692564,2116692564
dd	2878378043,2878378043
dd	2206763019,2206763019
dd	3393603212,3393603212
dd	703524551,703524551
dd	3552098411,3552098411
dd	1007948840,1007948840
dd	2044649127,2044649127
dd	3797835452,3797835452
dd	487262998,487262998
dd	1994120109,1994120109
dd	1004593371,1004593371
dd	1446130276,1446130276
dd	1312438900,1312438900
dd	503974420,503974420
dd	3679013266,3679013266
dd	168166924,168166924
dd	1814307912,1814307912
dd	3831258296,3831258296
dd	1573044895,1573044895
dd	1859376061,1859376061
dd	4021070915,4021070915
dd	2791465668,2791465668
dd	2828112185,2828112185
dd	2761266481,2761266481
dd	937747667,937747667
dd	2339994098,2339994098
dd	854058965,854058965
dd	1137232011,1137232011
dd	1496790894,1496790894
dd	3077402074,3077402074
dd	2358086913,2358086913
dd	1691735473,1691735473
dd	3528347292,3528347292
dd	3769215305,3769215305
dd	3027004632,3027004632
dd	4199962284,4199962284
dd	133494003,133494003
dd	636152527,636152527
dd	2942657994,2942657994
dd	2390391540,2390391540
dd	3920539207,3920539207
dd	403179536,403179536
dd	3585784431,3585784431
dd	2289596656,2289596656
dd	1864705354,1864705354
dd	1915629148,1915629148
dd	605822008,605822008
dd	4054230615,4054230615
dd	3350508659,3350508659
dd	1371981463,1371981463
dd	602466507,602466507
dd	2094914977,2094914977
dd	2624877800,2624877800
dd	555687742,555687742
dd	3712699286,3712699286
dd	3703422305,3703422305
dd	2257292045,2257292045
dd	2240449039,2240449039
dd	2423288032,2423288032
dd	1111375484,1111375484
dd	3300242801,3300242801
dd	2858837708,2858837708
dd	3628615824,3628615824
dd	84083462,84083462
dd	32962295,32962295
dd	302911004,302911004
dd	2741068226,2741068226
dd	1597322602,1597322602
dd	4183250862,4183250862
dd	3501832553,3501832553
dd	2441512471,2441512471
dd	1489093017,1489093017
dd	656219450,656219450
dd	3114180135,3114180135
dd	954327513,954327513
dd	335083755,335083755
dd	3013122091,3013122091
dd	856756514,856756514
dd	3144247762,3144247762
dd	1893325225,1893325225
dd	2307821063,2307821063
dd	2811532339,2811532339
dd	3063651117,3063651117
dd	572399164,572399164
dd	2458355477,2458355477
dd	552200649,552200649
dd	1238290055,1238290055
dd	4283782570,4283782570
dd	2015897680,2015897680
dd	2061492133,2061492133
dd	2408352771,2408352771
dd	4171342169,4171342169
dd	2156497161,2156497161
dd	386731290,386731290
dd	3669999461,3669999461
dd	837215959,837215959
dd	3326231172,3326231172
dd	3093850320,3093850320
dd	3275833730,3275833730
dd	2962856233,2962856233
dd	1999449434,1999449434
dd	286199582,286199582
dd	3417354363,3417354363
dd	4233385128,4233385128
dd	3602627437,3602627437
dd	974525996,974525996
db	99,124,119,123,242,107,111,197
db	48,1,103,43,254,215,171,118
db	202,130,201,125,250,89,71,240
db	173,212,162,175,156,164,114,192
db	183,253,147,38,54,63,247,204
db	52,165,229,241,113,216,49,21
db	4,199,35,195,24,150,5,154
db	7,18,128,226,235,39,178,117
db	9,131,44,26,27,110,90,160
db	82,59,214,179,41,227,47,132
db	83,209,0,237,32,252,177,91
db	106,203,190,57,74,76,88,207
db	208,239,170,251,67,77,51,133
db	69,249,2,127,80,60,159,168
db	81,163,64,143,146,157,56,245
db	188,182,218,33,16,255,243,210
db	205,12,19,236,95,151,68,23
db	196,167,126,61,100,93,25,115
db	96,129,79,220,34,42,144,136
db	70,238,184,20,222,94,11,219
db	224,50,58,10,73,6,36,92
db	194,211,172,98,145,149,228,121
db	231,200,55,109,141,213,78,169
db	108,86,244,234,101,122,174,8
db	186,120,37,46,28,166,180,198
db	232,221,116,31,75,189,139,138
db	112,62,181,102,72,3,246,14
db	97,53,87,185,134,193,29,158
db	225,248,152,17,105,217,142,148
db	155,30,135,233,206,85,40,223
db	140,161,137,13,191,230,66,104
db	65,153,45,15,176,84,187,22
db	99,124,119,123,242,107,111,197
db	48,1,103,43,254,215,171,118
db	202,130,201,125,250,89,71,240
db	173,212,162,175,156,164,114,192
db	183,253,147,38,54,63,247,204
db	52,165,229,241,113,216,49,21
db	4,199,35,195,24,150,5,154
db	7,18,128,226,235,39,178,117
db	9,131,44,26,27,110,90,160
db	82,59,214,179,41,227,47,132
db	83,209,0,237,32,252,177,91
db	106,203,190,57,74,76,88,207
db	208,239,170,251,67,77,51,133
db	69,249,2,127,80,60,159,168
db	81,163,64,143,146,157,56,245
db	188,182,218,33,16,255,243,210
db	205,12,19,236,95,151,68,23
db	196,167,126,61,100,93,25,115
db	96,129,79,220,34,42,144,136
db	70,238,184,20,222,94,11,219
db	224,50,58,10,73,6,36,92
db	194,211,172,98,145,149,228,121
db	231,200,55,109,141,213,78,169
db	108,86,244,234,101,122,174,8
db	186,120,37,46,28,166,180,198
db	232,221,116,31,75,189,139,138
db	112,62,181,102,72,3,246,14
db	97,53,87,185,134,193,29,158
db	225,248,152,17,105,217,142,148
db	155,30,135,233,206,85,40,223
db	140,161,137,13,191,230,66,104
db	65,153,45,15,176,84,187,22
db	99,124,119,123,242,107,111,197
db	48,1,103,43,254,215,171,118
db	202,130,201,125,250,89,71,240
db	173,212,162,175,156,164,114,192
db	183,253,147,38,54,63,247,204
db	52,165,229,241,113,216,49,21
db	4,199,35,195,24,150,5,154
db	7,18,128,226,235,39,178,117
db	9,131,44,26,27,110,90,160
db	82,59,214,179,41,227,47,132
db	83,209,0,237,32,252,177,91
db	106,203,190,57,74,76,88,207
db	208,239,170,251,67,77,51,133
db	69,249,2,127,80,60,159,168
db	81,163,64,143,146,157,56,245
db	188,182,218,33,16,255,243,210
db	205,12,19,236,95,151,68,23
db	196,167,126,61,100,93,25,115
db	96,129,79,220,34,42,144,136
db	70,238,184,20,222,94,11,219
db	224,50,58,10,73,6,36,92
db	194,211,172,98,145,149,228,121
db	231,200,55,109,141,213,78,169
db	108,86,244,234,101,122,174,8
db	186,120,37,46,28,166,180,198
db	232,221,116,31,75,189,139,138
db	112,62,181,102,72,3,246,14
db	97,53,87,185,134,193,29,158
db	225,248,152,17,105,217,142,148
db	155,30,135,233,206,85,40,223
db	140,161,137,13,191,230,66,104
db	65,153,45,15,176,84,187,22
db	99,124,119,123,242,107,111,197
db	48,1,103,43,254,215,171,118
db	202,130,201,125,250,89,71,240
db	173,212,162,175,156,164,114,192
db	183,253,147,38,54,63,247,204
db	52,165,229,241,113,216,49,21
db	4,199,35,195,24,150,5,154
db	7,18,128,226,235,39,178,117
db	9,131,44,26,27,110,90,160
db	82,59,214,179,41,227,47,132
db	83,209,0,237,32,252,177,91
db	106,203,190,57,74,76,88,207
db	208,239,170,251,67,77,51,133
db	69,249,2,127,80,60,159,168
db	81,163,64,143,146,157,56,245
db	188,182,218,33,16,255,243,210
db	205,12,19,236,95,151,68,23
db	196,167,126,61,100,93,25,115
db	96,129,79,220,34,42,144,136
db	70,238,184,20,222,94,11,219
db	224,50,58,10,73,6,36,92
db	194,211,172,98,145,149,228,121
db	231,200,55,109,141,213,78,169
db	108,86,244,234,101,122,174,8
db	186,120,37,46,28,166,180,198
db	232,221,116,31,75,189,139,138
db	112,62,181,102,72,3,246,14
db	97,53,87,185,134,193,29,158
db	225,248,152,17,105,217,142,148
db	155,30,135,233,206,85,40,223
db	140,161,137,13,191,230,66,104
db	65,153,45,15,176,84,187,22
dd	1,2,4,8
dd	16,32,64,128
dd	27,54,0,0
dd	0,0,0,0
global	_asm_AES_encrypt
align	16
_asm_AES_encrypt:
L$_asm_AES_encrypt_begin:
	push	ebp
	push	ebx
	push	esi
	push	edi
	mov	esi,DWORD [20+esp]
	mov	edi,DWORD [28+esp]
	mov	eax,esp
	sub	esp,36
	and	esp,-64
	lea	ebx,[edi-127]
	sub	ebx,esp
	neg	ebx
	and	ebx,960
	sub	esp,ebx
	add	esp,4
	mov	DWORD [28+esp],eax
	call	L$004pic_point
L$004pic_point:
	pop	ebp
	lea	eax,[_OPENSSL_ia32cap_P]
	lea	ebp,[(L$AES_Te-L$004pic_point)+ebp]
	lea	ebx,[764+esp]
	sub	ebx,ebp
	and	ebx,768
	lea	ebp,[2176+ebx*1+ebp]
	bt	DWORD [eax],25
	jnc	NEAR L$005x86
	movq	mm0,[esi]
	movq	mm4,[8+esi]
	call	__sse_AES_encrypt_compact
	mov	esp,DWORD [28+esp]
	mov	esi,DWORD [24+esp]
	movq	[esi],mm0
	movq	[8+esi],mm4
	emms
	pop	edi
	pop	esi
	pop	ebx
	pop	ebp
	ret
align	16
L$005x86:
	mov	DWORD [24+esp],ebp
	mov	eax,DWORD [esi]
	mov	ebx,DWORD [4+esi]
	mov	ecx,DWORD [8+esi]
	mov	edx,DWORD [12+esi]
	call	__x86_AES_encrypt_compact
	mov	esp,DWORD [28+esp]
	mov	esi,DWORD [24+esp]
	mov	DWORD [esi],eax
	mov	DWORD [4+esi],ebx
	mov	DWORD [8+esi],ecx
	mov	DWORD [12+esi],edx
	pop	edi
	pop	esi
	pop	ebx
	pop	ebp
	ret
align	16
__x86_AES_decrypt_compact:
	mov	DWORD [20+esp],edi
	xor	eax,DWORD [edi]
	xor	ebx,DWORD [4+edi]
	xor	ecx,DWORD [8+edi]
	xor	edx,DWORD [12+edi]
	mov	esi,DWORD [240+edi]
	lea	esi,[esi*1+esi-2]
	lea	esi,[esi*8+edi]
	mov	DWORD [24+esp],esi
	mov	edi,DWORD [ebp-128]
	mov	esi,DWORD [ebp-96]
	mov	edi,DWORD [ebp-64]
	mov	esi,DWORD [ebp-32]
	mov	edi,DWORD [ebp]
	mov	esi,DWORD [32+ebp]
	mov	edi,DWORD [64+ebp]
	mov	esi,DWORD [96+ebp]
align	16
L$006loop:
	mov	esi,eax
	and	esi,255
	movzx	esi,BYTE [esi*1+ebp-128]
	movzx	edi,dh
	movzx	edi,BYTE [edi*1+ebp-128]
	shl	edi,8
	xor	esi,edi
	mov	edi,ecx
	shr	edi,16
	and	edi,255
	movzx	edi,BYTE [edi*1+ebp-128]
	shl	edi,16
	xor	esi,edi
	mov	edi,ebx
	shr	edi,24
	movzx	edi,BYTE [edi*1+ebp-128]
	shl	edi,24
	xor	esi,edi
	mov	DWORD [4+esp],esi
	mov	esi,ebx
	and	esi,255
	movzx	esi,BYTE [esi*1+ebp-128]
	movzx	edi,ah
	movzx	edi,BYTE [edi*1+ebp-128]
	shl	edi,8
	xor	esi,edi
	mov	edi,edx
	shr	edi,16
	and	edi,255
	movzx	edi,BYTE [edi*1+ebp-128]
	shl	edi,16
	xor	esi,edi
	mov	edi,ecx
	shr	edi,24
	movzx	edi,BYTE [edi*1+ebp-128]
	shl	edi,24
	xor	esi,edi
	mov	DWORD [8+esp],esi
	mov	esi,ecx
	and	esi,255
	movzx	esi,BYTE [esi*1+ebp-128]
	movzx	edi,bh
	movzx	edi,BYTE [edi*1+ebp-128]
	shl	edi,8
	xor	esi,edi
	mov	edi,eax
	shr	edi,16
	and	edi,255
	movzx	edi,BYTE [edi*1+ebp-128]
	shl	edi,16
	xor	esi,edi
	mov	edi,edx
	shr	edi,24
	movzx	edi,BYTE [edi*1+ebp-128]
	shl	edi,24
	xor	esi,edi
	and	edx,255
	movzx	edx,BYTE [edx*1+ebp-128]
	movzx	ecx,ch
	movzx	ecx,BYTE [ecx*1+ebp-128]
	shl	ecx,8
	xor	edx,ecx
	mov	ecx,esi
	shr	ebx,16
	and	ebx,255
	movzx	ebx,BYTE [ebx*1+ebp-128]
	shl	ebx,16
	xor	edx,ebx
	shr	eax,24
	movzx	eax,BYTE [eax*1+ebp-128]
	shl	eax,24
	xor	edx,eax
	mov	edi,2155905152
	and	edi,ecx
	mov	esi,edi
	shr	edi,7
	lea	eax,[ecx*1+ecx]
	sub	esi,edi
	and	eax,4278124286
	and	esi,454761243
	xor	eax,esi
	mov	edi,2155905152
	and	edi,eax
	mov	esi,edi
	shr	edi,7
	lea	ebx,[eax*1+eax]
	sub	esi,edi
	and	ebx,4278124286
	and	esi,454761243
	xor	eax,ecx
	xor	ebx,esi
	mov	edi,2155905152
	and	edi,ebx
	mov	esi,edi
	shr	edi,7
	lea	ebp,[ebx*1+ebx]
	sub	esi,edi
	and	ebp,4278124286
	and	esi,454761243
	xor	ebx,ecx
	rol	ecx,8
	xor	ebp,esi
	xor	ecx,eax
	xor	eax,ebp
	xor	ecx,ebx
	xor	ebx,ebp
	rol	eax,24
	xor	ecx,ebp
	rol	ebx,16
	xor	ecx,eax
	rol	ebp,8
	xor	ecx,ebx
	mov	eax,DWORD [4+esp]
	xor	ecx,ebp
	mov	DWORD [12+esp],ecx
	mov	edi,2155905152
	and	edi,edx
	mov	esi,edi
	shr	edi,7
	lea	ebx,[edx*1+edx]
	sub	esi,edi
	and	ebx,4278124286
	and	esi,454761243
	xor	ebx,esi
	mov	edi,2155905152
	and	edi,ebx
	mov	esi,edi
	shr	edi,7
	lea	ecx,[ebx*1+ebx]
	sub	esi,edi
	and	ecx,4278124286
	and	esi,454761243
	xor	ebx,edx
	xor	ecx,esi
	mov	edi,2155905152
	and	edi,ecx
	mov	esi,edi
	shr	edi,7
	lea	ebp,[ecx*1+ecx]
	sub	esi,edi
	and	ebp,4278124286
	and	esi,454761243
	xor	ecx,edx
	rol	edx,8
	xor	ebp,esi
	xor	edx,ebx
	xor	ebx,ebp
	xor	edx,ecx
	xor	ecx,ebp
	rol	ebx,24
	xor	edx,ebp
	rol	ecx,16
	xor	edx,ebx
	rol	ebp,8
	xor	edx,ecx
	mov	ebx,DWORD [8+esp]
	xor	edx,ebp
	mov	DWORD [16+esp],edx
	mov	edi,2155905152
	and	edi,eax
	mov	esi,edi
	shr	edi,7
	lea	ecx,[eax*1+eax]
	sub	esi,edi
	and	ecx,4278124286
	and	esi,454761243
	xor	ecx,esi
	mov	edi,2155905152
	and	edi,ecx
	mov	esi,edi
	shr	edi,7
	lea	edx,[ecx*1+ecx]
	sub	esi,edi
	and	edx,4278124286
	and	esi,454761243
	xor	ecx,eax
	xor	edx,esi
	mov	edi,2155905152
	and	edi,edx
	mov	esi,edi
	shr	edi,7
	lea	ebp,[edx*1+edx]
	sub	esi,edi
	and	ebp,4278124286
	and	esi,454761243
	xor	edx,eax
	rol	eax,8
	xor	ebp,esi
	xor	eax,ecx
	xor	ecx,ebp
	xor	eax,edx
	xor	edx,ebp
	rol	ecx,24
	xor	eax,ebp
	rol	edx,16
	xor	eax,ecx
	rol	ebp,8
	xor	eax,edx
	xor	eax,ebp
	mov	edi,2155905152
	and	edi,ebx
	mov	esi,edi
	shr	edi,7
	lea	ecx,[ebx*1+ebx]
	sub	esi,edi
	and	ecx,4278124286
	and	esi,454761243
	xor	ecx,esi
	mov	edi,2155905152
	and	edi,ecx
	mov	esi,edi
	shr	edi,7
	lea	edx,[ecx*1+ecx]
	sub	esi,edi
	and	edx,4278124286
	and	esi,454761243
	xor	ecx,ebx
	xor	edx,esi
	mov	edi,2155905152
	and	edi,edx
	mov	esi,edi
	shr	edi,7
	lea	ebp,[edx*1+edx]
	sub	esi,edi
	and	ebp,4278124286
	and	esi,454761243
	xor	edx,ebx
	rol	ebx,8
	xor	ebp,esi
	xor	ebx,ecx
	xor	ecx,ebp
	xor	ebx,edx
	xor	edx,ebp
	rol	ecx,24
	xor	ebx,ebp
	rol	edx,16
	xor	ebx,ecx
	rol	ebp,8
	xor	ebx,edx
	mov	ecx,DWORD [12+esp]
	xor	ebx,ebp
	mov	edx,DWORD [16+esp]
	mov	edi,DWORD [20+esp]
	mov	ebp,DWORD [28+esp]
	add	edi,16
	xor	eax,DWORD [edi]
	xor	ebx,DWORD [4+edi]
	xor	ecx,DWORD [8+edi]
	xor	edx,DWORD [12+edi]
	cmp	edi,DWORD [24+esp]
	mov	DWORD [20+esp],edi
	jb	NEAR L$006loop
	mov	esi,eax
	and	esi,255
	movzx	esi,BYTE [esi*1+ebp-128]
	movzx	edi,dh
	movzx	edi,BYTE [edi*1+ebp-128]
	shl	edi,8
	xor	esi,edi
	mov	edi,ecx
	shr	edi,16
	and	edi,255
	movzx	edi,BYTE [edi*1+ebp-128]
	shl	edi,16
	xor	esi,edi
	mov	edi,ebx
	shr	edi,24
	movzx	edi,BYTE [edi*1+ebp-128]
	shl	edi,24
	xor	esi,edi
	mov	DWORD [4+esp],esi
	mov	esi,ebx
	and	esi,255
	movzx	esi,BYTE [esi*1+ebp-128]
	movzx	edi,ah
	movzx	edi,BYTE [edi*1+ebp-128]
	shl	edi,8
	xor	esi,edi
	mov	edi,edx
	shr	edi,16
	and	edi,255
	movzx	edi,BYTE [edi*1+ebp-128]
	shl	edi,16
	xor	esi,edi
	mov	edi,ecx
	shr	edi,24
	movzx	edi,BYTE [edi*1+ebp-128]
	shl	edi,24
	xor	esi,edi
	mov	DWORD [8+esp],esi
	mov	esi,ecx
	and	esi,255
	movzx	esi,BYTE [esi*1+ebp-128]
	movzx	edi,bh
	movzx	edi,BYTE [edi*1+ebp-128]
	shl	edi,8
	xor	esi,edi
	mov	edi,eax
	shr	edi,16
	and	edi,255
	movzx	edi,BYTE [edi*1+ebp-128]
	shl	edi,16
	xor	esi,edi
	mov	edi,edx
	shr	edi,24
	movzx	edi,BYTE [edi*1+ebp-128]
	shl	edi,24
	xor	esi,edi
	mov	edi,DWORD [20+esp]
	and	edx,255
	movzx	edx,BYTE [edx*1+ebp-128]
	movzx	ecx,ch
	movzx	ecx,BYTE [ecx*1+ebp-128]
	shl	ecx,8
	xor	edx,ecx
	mov	ecx,esi
	shr	ebx,16
	and	ebx,255
	movzx	ebx,BYTE [ebx*1+ebp-128]
	shl	ebx,16
	xor	edx,ebx
	mov	ebx,DWORD [8+esp]
	shr	eax,24
	movzx	eax,BYTE [eax*1+ebp-128]
	shl	eax,24
	xor	edx,eax
	mov	eax,DWORD [4+esp]
	xor	eax,DWORD [16+edi]
	xor	ebx,DWORD [20+edi]
	xor	ecx,DWORD [24+edi]
	xor	edx,DWORD [28+edi]
	ret
align	16
__sse_AES_decrypt_compact:
	pxor	mm0,[edi]
	pxor	mm4,[8+edi]
	mov	esi,DWORD [240+edi]
	lea	esi,[esi*1+esi-2]
	lea	esi,[esi*8+edi]
	mov	DWORD [24+esp],esi
	mov	eax,454761243
	mov	DWORD [8+esp],eax
	mov	DWORD [12+esp],eax
	mov	eax,DWORD [ebp-128]
	mov	ebx,DWORD [ebp-96]
	mov	ecx,DWORD [ebp-64]
	mov	edx,DWORD [ebp-32]
	mov	eax,DWORD [ebp]
	mov	ebx,DWORD [32+ebp]
	mov	ecx,DWORD [64+ebp]
	mov	edx,DWORD [96+ebp]
align	16
L$007loop:
	pshufw	mm1,mm0,12
	pshufw	mm5,mm4,9
	movd	eax,mm1
	movd	ebx,mm5
	mov	DWORD [20+esp],edi
	movzx	esi,al
	movzx	edx,ah
	pshufw	mm2,mm0,6
	movzx	ecx,BYTE [esi*1+ebp-128]
	movzx	edi,bl
	movzx	edx,BYTE [edx*1+ebp-128]
	shr	eax,16
	shl	edx,8
	movzx	esi,BYTE [edi*1+ebp-128]
	movzx	edi,bh
	shl	esi,16
	pshufw	mm6,mm4,3
	or	ecx,esi
	movzx	esi,BYTE [edi*1+ebp-128]
	movzx	edi,ah
	shl	esi,24
	shr	ebx,16
	or	edx,esi
	movzx	esi,BYTE [edi*1+ebp-128]
	movzx	edi,bh
	shl	esi,24
	or	ecx,esi
	movzx	esi,BYTE [edi*1+ebp-128]
	movzx	edi,al
	shl	esi,8
	movd	eax,mm2
	or	ecx,esi
	movzx	esi,BYTE [edi*1+ebp-128]
	movzx	edi,bl
	shl	esi,16
	movd	ebx,mm6
	movd	mm0,ecx
	movzx	ecx,BYTE [edi*1+ebp-128]
	movzx	edi,al
	or	ecx,esi
	movzx	esi,BYTE [edi*1+ebp-128]
	movzx	edi,bl
	or	edx,esi
	movzx	esi,BYTE [edi*1+ebp-128]
	movzx	edi,ah
	shl	esi,16
	shr	eax,16
	or	edx,esi
	movzx	esi,BYTE [edi*1+ebp-128]
	movzx	edi,bh
	shr	ebx,16
	shl	esi,8
	movd	mm1,edx
	movzx	edx,BYTE [edi*1+ebp-128]
	movzx	edi,bh
	shl	edx,24
	and	ebx,255
	or	edx,esi
	punpckldq	mm0,mm1
	movzx	esi,BYTE [edi*1+ebp-128]
	movzx	edi,al
	shl	esi,8
	movzx	eax,ah
	movzx	ebx,BYTE [ebx*1+ebp-128]
	or	ecx,esi
	movzx	esi,BYTE [edi*1+ebp-128]
	or	edx,ebx
	shl	esi,16
	movzx	eax,BYTE [eax*1+ebp-128]
	or	edx,esi
	shl	eax,24
	or	ecx,eax
	mov	edi,DWORD [20+esp]
	movd	mm4,edx
	movd	mm5,ecx
	punpckldq	mm4,mm5
	add	edi,16
	cmp	edi,DWORD [24+esp]
	ja	NEAR L$008out
	movq	mm3,mm0
	movq	mm7,mm4
	pshufw	mm2,mm0,228
	pshufw	mm6,mm4,228
	movq	mm1,mm0
	movq	mm5,mm4
	pshufw	mm0,mm0,177
	pshufw	mm4,mm4,177
	pslld	mm2,8
	pslld	mm6,8
	psrld	mm3,8
	psrld	mm7,8
	pxor	mm0,mm2
	pxor	mm4,mm6
	pxor	mm0,mm3
	pxor	mm4,mm7
	pslld	mm2,16
	pslld	mm6,16
	psrld	mm3,16
	psrld	mm7,16
	pxor	mm0,mm2
	pxor	mm4,mm6
	pxor	mm0,mm3
	pxor	mm4,mm7
	movq	mm3,[8+esp]
	pxor	mm2,mm2
	pxor	mm6,mm6
	pcmpgtb	mm2,mm1
	pcmpgtb	mm6,mm5
	pand	mm2,mm3
	pand	mm6,mm3
	paddb	mm1,mm1
	paddb	mm5,mm5
	pxor	mm1,mm2
	pxor	mm5,mm6
	movq	mm3,mm1
	movq	mm7,mm5
	movq	mm2,mm1
	movq	mm6,mm5
	pxor	mm0,mm1
	pxor	mm4,mm5
	pslld	mm3,24
	pslld	mm7,24
	psrld	mm2,8
	psrld	mm6,8
	pxor	mm0,mm3
	pxor	mm4,mm7
	pxor	mm0,mm2
	pxor	mm4,mm6
	movq	mm2,[8+esp]
	pxor	mm3,mm3
	pxor	mm7,mm7
	pcmpgtb	mm3,mm1
	pcmpgtb	mm7,mm5
	pand	mm3,mm2
	pand	mm7,mm2
	paddb	mm1,mm1
	paddb	mm5,mm5
	pxor	mm1,mm3
	pxor	mm5,mm7
	pshufw	mm3,mm1,177
	pshufw	mm7,mm5,177
	pxor	mm0,mm1
	pxor	mm4,mm5
	pxor	mm0,mm3
	pxor	mm4,mm7
	pxor	mm3,mm3
	pxor	mm7,mm7
	pcmpgtb	mm3,mm1
	pcmpgtb	mm7,mm5
	pand	mm3,mm2
	pand	mm7,mm2
	paddb	mm1,mm1
	paddb	mm5,mm5
	pxor	mm1,mm3
	pxor	mm5,mm7
	pxor	mm0,mm1
	pxor	mm4,mm5
	movq	mm3,mm1
	movq	mm7,mm5
	pshufw	mm2,mm1,177
	pshufw	mm6,mm5,177
	pxor	mm0,mm2
	pxor	mm4,mm6
	pslld	mm1,8
	pslld	mm5,8
	psrld	mm3,8
	psrld	mm7,8
	movq	mm2,[edi]
	movq	mm6,[8+edi]
	pxor	mm0,mm1
	pxor	mm4,mm5
	pxor	mm0,mm3
	pxor	mm4,mm7
	mov	eax,DWORD [ebp-128]
	pslld	mm1,16
	pslld	mm5,16
	mov	ebx,DWORD [ebp-64]
	psrld	mm3,16
	psrld	mm7,16
	mov	ecx,DWORD [ebp]
	pxor	mm0,mm1
	pxor	mm4,mm5
	mov	edx,DWORD [64+ebp]
	pxor	mm0,mm3
	pxor	mm4,mm7
	pxor	mm0,mm2
	pxor	mm4,mm6
	jmp	NEAR L$007loop
align	16
L$008out:
	pxor	mm0,[edi]
	pxor	mm4,[8+edi]
	ret
align	16
__x86_AES_decrypt:
	mov	DWORD [20+esp],edi
	xor	eax,DWORD [edi]
	xor	ebx,DWORD [4+edi]
	xor	ecx,DWORD [8+edi]
	xor	edx,DWORD [12+edi]
	mov	esi,DWORD [240+edi]
	lea	esi,[esi*1+esi-2]
	lea	esi,[esi*8+edi]
	mov	DWORD [24+esp],esi
align	16
L$009loop:
	mov	esi,eax
	and	esi,255
	mov	esi,DWORD [esi*8+ebp]
	movzx	edi,dh
	xor	esi,DWORD [3+edi*8+ebp]
	mov	edi,ecx
	shr	edi,16
	and	edi,255
	xor	esi,DWORD [2+edi*8+ebp]
	mov	edi,ebx
	shr	edi,24
	xor	esi,DWORD [1+edi*8+ebp]
	mov	DWORD [4+esp],esi
	mov	esi,ebx
	and	esi,255
	mov	esi,DWORD [esi*8+ebp]
	movzx	edi,ah
	xor	esi,DWORD [3+edi*8+ebp]
	mov	edi,edx
	shr	edi,16
	and	edi,255
	xor	esi,DWORD [2+edi*8+ebp]
	mov	edi,ecx
	shr	edi,24
	xor	esi,DWORD [1+edi*8+ebp]
	mov	DWORD [8+esp],esi
	mov	esi,ecx
	and	esi,255
	mov	esi,DWORD [esi*8+ebp]
	movzx	edi,bh
	xor	esi,DWORD [3+edi*8+ebp]
	mov	edi,eax
	shr	edi,16
	and	edi,255
	xor	esi,DWORD [2+edi*8+ebp]
	mov	edi,edx
	shr	edi,24
	xor	esi,DWORD [1+edi*8+ebp]
	mov	edi,DWORD [20+esp]
	and	edx,255
	mov	edx,DWORD [edx*8+ebp]
	movzx	ecx,ch
	xor	edx,DWORD [3+ecx*8+ebp]
	mov	ecx,esi
	shr	ebx,16
	and	ebx,255
	xor	edx,DWORD [2+ebx*8+ebp]
	mov	ebx,DWORD [8+esp]
	shr	eax,24
	xor	edx,DWORD [1+eax*8+ebp]
	mov	eax,DWORD [4+esp]
	add	edi,16
	xor	eax,DWORD [edi]
	xor	ebx,DWORD [4+edi]
	xor	ecx,DWORD [8+edi]
	xor	edx,DWORD [12+edi]
	cmp	edi,DWORD [24+esp]
	mov	DWORD [20+esp],edi
	jb	NEAR L$009loop
	lea	ebp,[2176+ebp]
	mov	edi,DWORD [ebp-128]
	mov	esi,DWORD [ebp-96]
	mov	edi,DWORD [ebp-64]
	mov	esi,DWORD [ebp-32]
	mov	edi,DWORD [ebp]
	mov	esi,DWORD [32+ebp]
	mov	edi,DWORD [64+ebp]
	mov	esi,DWORD [96+ebp]
	lea	ebp,[ebp-128]
	mov	esi,eax
	and	esi,255
	movzx	esi,BYTE [esi*1+ebp]
	movzx	edi,dh
	movzx	edi,BYTE [edi*1+ebp]
	shl	edi,8
	xor	esi,edi
	mov	edi,ecx
	shr	edi,16
	and	edi,255
	movzx	edi,BYTE [edi*1+ebp]
	shl	edi,16
	xor	esi,edi
	mov	edi,ebx
	shr	edi,24
	movzx	edi,BYTE [edi*1+ebp]
	shl	edi,24
	xor	esi,edi
	mov	DWORD [4+esp],esi
	mov	esi,ebx
	and	esi,255
	movzx	esi,BYTE [esi*1+ebp]
	movzx	edi,ah
	movzx	edi,BYTE [edi*1+ebp]
	shl	edi,8
	xor	esi,edi
	mov	edi,edx
	shr	edi,16
	and	edi,255
	movzx	edi,BYTE [edi*1+ebp]
	shl	edi,16
	xor	esi,edi
	mov	edi,ecx
	shr	edi,24
	movzx	edi,BYTE [edi*1+ebp]
	shl	edi,24
	xor	esi,edi
	mov	DWORD [8+esp],esi
	mov	esi,ecx
	and	esi,255
	movzx	esi,BYTE [esi*1+ebp]
	movzx	edi,bh
	movzx	edi,BYTE [edi*1+ebp]
	shl	edi,8
	xor	esi,edi
	mov	edi,eax
	shr	edi,16
	and	edi,255
	movzx	edi,BYTE [edi*1+ebp]
	shl	edi,16
	xor	esi,edi
	mov	edi,edx
	shr	edi,24
	movzx	edi,BYTE [edi*1+ebp]
	shl	edi,24
	xor	esi,edi
	mov	edi,DWORD [20+esp]
	and	edx,255
	movzx	edx,BYTE [edx*1+ebp]
	movzx	ecx,ch
	movzx	ecx,BYTE [ecx*1+ebp]
	shl	ecx,8
	xor	edx,ecx
	mov	ecx,esi
	shr	ebx,16
	and	ebx,255
	movzx	ebx,BYTE [ebx*1+ebp]
	shl	ebx,16
	xor	edx,ebx
	mov	ebx,DWORD [8+esp]
	shr	eax,24
	movzx	eax,BYTE [eax*1+ebp]
	shl	eax,24
	xor	edx,eax
	mov	eax,DWORD [4+esp]
	lea	ebp,[ebp-2048]
	add	edi,16
	xor	eax,DWORD [edi]
	xor	ebx,DWORD [4+edi]
	xor	ecx,DWORD [8+edi]
	xor	edx,DWORD [12+edi]
	ret
align	64
L$AES_Td:
dd	1353184337,1353184337
dd	1399144830,1399144830
dd	3282310938,3282310938
dd	2522752826,2522752826
dd	3412831035,3412831035
dd	4047871263,4047871263
dd	2874735276,2874735276
dd	2466505547,2466505547
dd	1442459680,1442459680
dd	4134368941,4134368941
dd	2440481928,2440481928
dd	625738485,625738485
dd	4242007375,4242007375
dd	3620416197,3620416197
dd	2151953702,2151953702
dd	2409849525,2409849525
dd	1230680542,1230680542
dd	1729870373,1729870373
dd	2551114309,2551114309
dd	3787521629,3787521629
dd	41234371,41234371
dd	317738113,317738113
dd	2744600205,2744600205
dd	3338261355,3338261355
dd	3881799427,3881799427
dd	2510066197,2510066197
dd	3950669247,3950669247
dd	3663286933,3663286933
dd	763608788,763608788
dd	3542185048,3542185048
dd	694804553,694804553
dd	1154009486,1154009486
dd	1787413109,1787413109
dd	2021232372,2021232372
dd	1799248025,1799248025
dd	3715217703,3715217703
dd	3058688446,3058688446
dd	397248752,397248752
dd	1722556617,1722556617
dd	3023752829,3023752829
dd	407560035,407560035
dd	2184256229,2184256229
dd	1613975959,1613975959
dd	1165972322,1165972322
dd	3765920945,3765920945
dd	2226023355,2226023355
dd	480281086,480281086
dd	2485848313,2485848313
dd	1483229296,1483229296
dd	436028815,436028815
dd	2272059028,2272059028
dd	3086515026,3086515026
dd	601060267,601060267
dd	3791801202,3791801202
dd	1468997603,1468997603
dd	715871590,715871590
dd	120122290,120122290
dd	63092015,63092015
dd	2591802758,2591802758
dd	2768779219,2768779219
dd	4068943920,4068943920
dd	2997206819,2997206819
dd	3127509762,3127509762
dd	1552029421,1552029421
dd	723308426,723308426
dd	2461301159,2461301159
dd	4042393587,4042393587
dd	2715969870,2715969870
dd	3455375973,3455375973
dd	3586000134,3586000134
dd	526529745,526529745
dd	2331944644,2331944644
dd	2639474228,2639474228
dd	2689987490,2689987490
dd	853641733,853641733
dd	1978398372,1978398372
dd	971801355,971801355
dd	2867814464,2867814464
dd	111112542,111112542
dd	1360031421,1360031421
dd	4186579262,4186579262
dd	1023860118,1023860118
dd	2919579357,2919579357
dd	1186850381,1186850381
dd	3045938321,3045938321
dd	90031217,90031217
dd	1876166148,1876166148
dd	4279586912,4279586912
dd	620468249,620468249
dd	2548678102,2548678102
dd	3426959497,3426959497
dd	2006899047,2006899047
dd	3175278768,3175278768
dd	2290845959,2290845959
dd	945494503,945494503
dd	3689859193,3689859193
dd	1191869601,1191869601
dd	3910091388,3910091388
dd	3374220536,3374220536
dd	0,0
dd	2206629897,2206629897
dd	1223502642,1223502642
dd	2893025566,2893025566
dd	1316117100,1316117100
dd	4227796733,4227796733
dd	1446544655,1446544655
dd	517320253,517320253
dd	658058550,658058550
dd	1691946762,1691946762
dd	564550760,564550760
dd	3511966619,3511966619
dd	976107044,976107044
dd	2976320012,2976320012
dd	266819475,266819475
dd	3533106868,3533106868
dd	2660342555,2660342555
dd	1338359936,1338359936
dd	2720062561,2720062561
dd	1766553434,1766553434
dd	370807324,370807324
dd	179999714,179999714
dd	3844776128,3844776128
dd	1138762300,1138762300
dd	488053522,488053522
dd	185403662,185403662
dd	2915535858,2915535858
dd	3114841645,3114841645
dd	3366526484,3366526484
dd	2233069911,2233069911
dd	1275557295,1275557295
dd	3151862254,3151862254
dd	4250959779,4250959779
dd	2670068215,2670068215
dd	3170202204,3170202204
dd	3309004356,3309004356
dd	880737115,880737115
dd	1982415755,1982415755
dd	3703972811,3703972811
dd	1761406390,1761406390
dd	1676797112,1676797112
dd	3403428311,3403428311
dd	277177154,277177154
dd	1076008723,1076008723
dd	538035844,538035844
dd	2099530373,2099530373
dd	4164795346,4164795346
dd	288553390,288553390
dd	1839278535,1839278535
dd	1261411869,1261411869
dd	4080055004,4080055004
dd	3964831245,3964831245
dd	3504587127,3504587127
dd	1813426987,1813426987
dd	2579067049,2579067049
dd	4199060497,4199060497
dd	577038663,577038663
dd	3297574056,3297574056
dd	440397984,440397984
dd	3626794326,3626794326
dd	4019204898,4019204898
dd	3343796615,3343796615
dd	3251714265,3251714265
dd	4272081548,4272081548
dd	906744984,906744984
dd	3481400742,3481400742
dd	685669029,685669029
dd	646887386,646887386
dd	2764025151,2764025151
dd	3835509292,3835509292
dd	227702864,227702864
dd	2613862250,2613862250
dd	1648787028,1648787028
dd	3256061430,3256061430
dd	3904428176,3904428176
dd	1593260334,1593260334
dd	4121936770,4121936770
dd	3196083615,3196083615
dd	2090061929,2090061929
dd	2838353263,2838353263
dd	3004310991,3004310991
dd	999926984,999926984
dd	2809993232,2809993232
dd	1852021992,1852021992
dd	2075868123,2075868123
dd	158869197,158869197
dd	4095236462,4095236462
dd	28809964,28809964
dd	2828685187,2828685187
dd	1701746150,1701746150
dd	2129067946,2129067946
dd	147831841,147831841
dd	3873969647,3873969647
dd	3650873274,3650873274
dd	3459673930,3459673930
dd	3557400554,3557400554
dd	3598495785,3598495785
dd	2947720241,2947720241
dd	824393514,824393514
dd	815048134,815048134
dd	3227951669,3227951669
dd	935087732,935087732
dd	2798289660,2798289660
dd	2966458592,2966458592
dd	366520115,366520115
dd	1251476721,1251476721
dd	4158319681,4158319681
dd	240176511,240176511
dd	804688151,804688151
dd	2379631990,2379631990
dd	1303441219,1303441219
dd	1414376140,1414376140
dd	3741619940,3741619940
dd	3820343710,3820343710
dd	461924940,461924940
dd	3089050817,3089050817
dd	2136040774,2136040774
dd	82468509,82468509
dd	1563790337,1563790337
dd	1937016826,1937016826
dd	776014843,776014843
dd	1511876531,1511876531
dd	1389550482,1389550482
dd	861278441,861278441
dd	323475053,323475053
dd	2355222426,2355222426
dd	2047648055,2047648055
dd	2383738969,2383738969
dd	2302415851,2302415851
dd	3995576782,3995576782
dd	902390199,902390199
dd	3991215329,3991215329
dd	1018251130,1018251130
dd	1507840668,1507840668
dd	1064563285,1064563285
dd	2043548696,2043548696
dd	3208103795,3208103795
dd	3939366739,3939366739
dd	1537932639,1537932639
dd	342834655,342834655
dd	2262516856,2262516856
dd	2180231114,2180231114
dd	1053059257,1053059257
dd	741614648,741614648
dd	1598071746,1598071746
dd	1925389590,1925389590
dd	203809468,203809468
dd	2336832552,2336832552
dd	1100287487,1100287487
dd	1895934009,1895934009
dd	3736275976,3736275976
dd	2632234200,2632234200
dd	2428589668,2428589668
dd	1636092795,1636092795
dd	1890988757,1890988757
dd	1952214088,1952214088
dd	1113045200,1113045200
db	82,9,106,213,48,54,165,56
db	191,64,163,158,129,243,215,251
db	124,227,57,130,155,47,255,135
db	52,142,67,68,196,222,233,203
db	84,123,148,50,166,194,35,61
db	238,76,149,11,66,250,195,78
db	8,46,161,102,40,217,36,178
db	118,91,162,73,109,139,209,37
db	114,248,246,100,134,104,152,22
db	212,164,92,204,93,101,182,146
db	108,112,72,80,253,237,185,218
db	94,21,70,87,167,141,157,132
db	144,216,171,0,140,188,211,10
db	247,228,88,5,184,179,69,6
db	208,44,30,143,202,63,15,2
db	193,175,189,3,1,19,138,107
db	58,145,17,65,79,103,220,234
db	151,242,207,206,240,180,230,115
db	150,172,116,34,231,173,53,133
db	226,249,55,232,28,117,223,110
db	71,241,26,113,29,41,197,137
db	111,183,98,14,170,24,190,27
db	252,86,62,75,198,210,121,32
db	154,219,192,254,120,205,90,244
db	31,221,168,51,136,7,199,49
db	177,18,16,89,39,128,236,95
db	96,81,127,169,25,181,74,13
db	45,229,122,159,147,201,156,239
db	160,224,59,77,174,42,245,176
db	200,235,187,60,131,83,153,97
db	23,43,4,126,186,119,214,38
db	225,105,20,99,85,33,12,125
db	82,9,106,213,48,54,165,56
db	191,64,163,158,129,243,215,251
db	124,227,57,130,155,47,255,135
db	52,142,67,68,196,222,233,203
db	84,123,148,50,166,194,35,61
db	238,76,149,11,66,250,195,78
db	8,46,161,102,40,217,36,178
db	118,91,162,73,109,139,209,37
db	114,248,246,100,134,104,152,22
db	212,164,92,204,93,101,182,146
db	108,112,72,80,253,237,185,218
db	94,21,70,87,167,141,157,132
db	144,216,171,0,140,188,211,10
db	247,228,88,5,184,179,69,6
db	208,44,30,143,202,63,15,2
db	193,175,189,3,1,19,138,107
db	58,145,17,65,79,103,220,234
db	151,242,207,206,240,180,230,115
db	150,172,116,34,231,173,53,133
db	226,249,55,232,28,117,223,110
db	71,241,26,113,29,41,197,137
db	111,183,98,14,170,24,190,27
db	252,86,62,75,198,210,121,32
db	154,219,192,254,120,205,90,244
db	31,221,168,51,136,7,199,49
db	177,18,16,89,39,128,236,95
db	96,81,127,169,25,181,74,13
db	45,229,122,159,147,201,156,239
db	160,224,59,77,174,42,245,176
db	200,235,187,60,131,83,153,97
db	23,43,4,126,186,119,214,38
db	225,105,20,99,85,33,12,125
db	82,9,106,213,48,54,165,56
db	191,64,163,158,129,243,215,251
db	124,227,57,130,155,47,255,135
db	52,142,67,68,196,222,233,203
db	84,123,148,50,166,194,35,61
db	238,76,149,11,66,250,195,78
db	8,46,161,102,40,217,36,178
db	118,91,162,73,109,139,209,37
db	114,248,246,100,134,104,152,22
db	212,164,92,204,93,101,182,146
db	108,112,72,80,253,237,185,218
db	94,21,70,87,167,141,157,132
db	144,216,171,0,140,188,211,10
db	247,228,88,5,184,179,69,6
db	208,44,30,143,202,63,15,2
db	193,175,189,3,1,19,138,107
db	58,145,17,65,79,103,220,234
db	151,242,207,206,240,180,230,115
db	150,172,116,34,231,173,53,133
db	226,249,55,232,28,117,223,110
db	71,241,26,113,29,41,197,137
db	111,183,98,14,170,24,190,27
db	252,86,62,75,198,210,121,32
db	154,219,192,254,120,205,90,244
db	31,221,168,51,136,7,199,49
db	177,18,16,89,39,128,236,95
db	96,81,127,169,25,181,74,13
db	45,229,122,159,147,201,156,239
db	160,224,59,77,174,42,245,176
db	200,235,187,60,131,83,153,97
db	23,43,4,126,186,119,214,38
db	225,105,20,99,85,33,12,125
db	82,9,106,213,48,54,165,56
db	191,64,163,158,129,243,215,251
db	124,227,57,130,155,47,255,135
db	52,142,67,68,196,222,233,203
db	84,123,148,50,166,194,35,61
db	238,76,149,11,66,250,195,78
db	8,46,161,102,40,217,36,178
db	118,91,162,73,109,139,209,37
db	114,248,246,100,134,104,152,22
db	212,164,92,204,93,101,182,146
db	108,112,72,80,253,237,185,218
db	94,21,70,87,167,141,157,132
db	144,216,171,0,140,188,211,10
db	247,228,88,5,184,179,69,6
db	208,44,30,143,202,63,15,2
db	193,175,189,3,1,19,138,107
db	58,145,17,65,79,103,220,234
db	151,242,207,206,240,180,230,115
db	150,172,116,34,231,173,53,133
db	226,249,55,232,28,117,223,110
db	71,241,26,113,29,41,197,137
db	111,183,98,14,170,24,190,27
db	252,86,62,75,198,210,121,32
db	154,219,192,254,120,205,90,244
db	31,221,168,51,136,7,199,49
db	177,18,16,89,39,128,236,95
db	96,81,127,169,25,181,74,13
db	45,229,122,159,147,201,156,239
db	160,224,59,77,174,42,245,176
db	200,235,187,60,131,83,153,97
db	23,43,4,126,186,119,214,38
db	225,105,20,99,85,33,12,125
global	_asm_AES_decrypt
align	16
_asm_AES_decrypt:
L$_asm_AES_decrypt_begin:
	push	ebp
	push	ebx
	push	esi
	push	edi
	mov	esi,DWORD [20+esp]
	mov	edi,DWORD [28+esp]
	mov	eax,esp
	sub	esp,36
	and	esp,-64
	lea	ebx,[edi-127]
	sub	ebx,esp
	neg	ebx
	and	ebx,960
	sub	esp,ebx
	add	esp,4
	mov	DWORD [28+esp],eax
	call	L$010pic_point
L$010pic_point:
	pop	ebp
	lea	eax,[_OPENSSL_ia32cap_P]
	lea	ebp,[(L$AES_Td-L$010pic_point)+ebp]
	lea	ebx,[764+esp]
	sub	ebx,ebp
	and	ebx,768
	lea	ebp,[2176+ebx*1+ebp]
	bt	DWORD [eax],25
	jnc	NEAR L$011x86
	movq	mm0,[esi]
	movq	mm4,[8+esi]
	call	__sse_AES_decrypt_compact
	mov	esp,DWORD [28+esp]
	mov	esi,DWORD [24+esp]
	movq	[esi],mm0
	movq	[8+esi],mm4
	emms
	pop	edi
	pop	esi
	pop	ebx
	pop	ebp
	ret
align	16
L$011x86:
	mov	DWORD [24+esp],ebp
	mov	eax,DWORD [esi]
	mov	ebx,DWORD [4+esi]
	mov	ecx,DWORD [8+esi]
	mov	edx,DWORD [12+esi]
	call	__x86_AES_decrypt_compact
	mov	esp,DWORD [28+esp]
	mov	esi,DWORD [24+esp]
	mov	DWORD [esi],eax
	mov	DWORD [4+esi],ebx
	mov	DWORD [8+esi],ecx
	mov	DWORD [12+esi],edx
	pop	edi
	pop	esi
	pop	ebx
	pop	ebp
	ret
global	_asm_AES_cbc_encrypt
align	16
_asm_AES_cbc_encrypt:
L$_asm_AES_cbc_encrypt_begin:
	push	ebp
	push	ebx
	push	esi
	push	edi
	mov	ecx,DWORD [28+esp]
	cmp	ecx,0
	je	NEAR L$012drop_out
	call	L$013pic_point
L$013pic_point:
	pop	ebp
	lea	eax,[_OPENSSL_ia32cap_P]
	cmp	DWORD [40+esp],0
	lea	ebp,[(L$AES_Te-L$013pic_point)+ebp]
	jne	NEAR L$014picked_te
	lea	ebp,[(L$AES_Td-L$AES_Te)+ebp]
L$014picked_te:
	pushfd
	cld
	cmp	ecx,512
	jb	NEAR L$015slow_way
	test	ecx,15
	jnz	NEAR L$015slow_way
	bt	DWORD [eax],28
	jc	NEAR L$015slow_way
	lea	esi,[esp-324]
	and	esi,-64
	mov	eax,ebp
	lea	ebx,[2304+ebp]
	mov	edx,esi
	and	eax,4095
	and	ebx,4095
	and	edx,4095
	cmp	edx,ebx
	jb	NEAR L$016tbl_break_out
	sub	edx,ebx
	sub	esi,edx
	jmp	NEAR L$017tbl_ok
align	4
L$016tbl_break_out:
	sub	edx,eax
	and	edx,4095
	add	edx,384
	sub	esi,edx
align	4
L$017tbl_ok:
	lea	edx,[24+esp]
	xchg	esp,esi
	add	esp,4
	mov	DWORD [24+esp],ebp
	mov	DWORD [28+esp],esi
	mov	eax,DWORD [edx]
	mov	ebx,DWORD [4+edx]
	mov	edi,DWORD [12+edx]
	mov	esi,DWORD [16+edx]
	mov	edx,DWORD [20+edx]
	mov	DWORD [32+esp],eax
	mov	DWORD [36+esp],ebx
	mov	DWORD [40+esp],ecx
	mov	DWORD [44+esp],edi
	mov	DWORD [48+esp],esi
	mov	DWORD [316+esp],0
	mov	ebx,edi
	mov	ecx,61
	sub	ebx,ebp
	mov	esi,edi
	and	ebx,4095
	lea	edi,[76+esp]
	cmp	ebx,2304
	jb	NEAR L$018do_copy
	cmp	ebx,3852
	jb	NEAR L$019skip_copy
align	4
L$018do_copy:
	mov	DWORD [44+esp],edi
dd	2784229001
L$019skip_copy:
	mov	edi,16
align	4
L$020prefetch_tbl:
	mov	eax,DWORD [ebp]
	mov	ebx,DWORD [32+ebp]
	mov	ecx,DWORD [64+ebp]
	mov	esi,DWORD [96+ebp]
	lea	ebp,[128+ebp]
	sub	edi,1
	jnz	NEAR L$020prefetch_tbl
	sub	ebp,2048
	mov	esi,DWORD [32+esp]
	mov	edi,DWORD [48+esp]
	cmp	edx,0
	je	NEAR L$021fast_decrypt
	mov	eax,DWORD [edi]
	mov	ebx,DWORD [4+edi]
align	16
L$022fast_enc_loop:
	mov	ecx,DWORD [8+edi]
	mov	edx,DWORD [12+edi]
	xor	eax,DWORD [esi]
	xor	ebx,DWORD [4+esi]
	xor	ecx,DWORD [8+esi]
	xor	edx,DWORD [12+esi]
	mov	edi,DWORD [44+esp]
	call	__x86_AES_encrypt
	mov	esi,DWORD [32+esp]
	mov	edi,DWORD [36+esp]
	mov	DWORD [edi],eax
	mov	DWORD [4+edi],ebx
	mov	DWORD [8+edi],ecx
	mov	DWORD [12+edi],edx
	lea	esi,[16+esi]
	mov	ecx,DWORD [40+esp]
	mov	DWORD [32+esp],esi
	lea	edx,[16+edi]
	mov	DWORD [36+esp],edx
	sub	ecx,16
	mov	DWORD [40+esp],ecx
	jnz	NEAR L$022fast_enc_loop
	mov	esi,DWORD [48+esp]
	mov	ecx,DWORD [8+edi]
	mov	edx,DWORD [12+edi]
	mov	DWORD [esi],eax
	mov	DWORD [4+esi],ebx
	mov	DWORD [8+esi],ecx
	mov	DWORD [12+esi],edx
	cmp	DWORD [316+esp],0
	mov	edi,DWORD [44+esp]
	je	NEAR L$023skip_ezero
	mov	ecx,60
	xor	eax,eax
align	4
dd	2884892297
L$023skip_ezero:
	mov	esp,DWORD [28+esp]
	popfd
L$012drop_out:
	pop	edi
	pop	esi
	pop	ebx
	pop	ebp
	ret
	pushfd
align	16
L$021fast_decrypt:
	cmp	esi,DWORD [36+esp]
	je	NEAR L$024fast_dec_in_place
	mov	DWORD [52+esp],edi
align	4
align	16
L$025fast_dec_loop:
	mov	eax,DWORD [esi]
	mov	ebx,DWORD [4+esi]
	mov	ecx,DWORD [8+esi]
	mov	edx,DWORD [12+esi]
	mov	edi,DWORD [44+esp]
	call	__x86_AES_decrypt
	mov	edi,DWORD [52+esp]
	mov	esi,DWORD [40+esp]
	xor	eax,DWORD [edi]
	xor	ebx,DWORD [4+edi]
	xor	ecx,DWORD [8+edi]
	xor	edx,DWORD [12+edi]
	mov	edi,DWORD [36+esp]
	mov	esi,DWORD [32+esp]
	mov	DWORD [edi],eax
	mov	DWORD [4+edi],ebx
	mov	DWORD [8+edi],ecx
	mov	DWORD [12+edi],edx
	mov	ecx,DWORD [40+esp]
	mov	DWORD [52+esp],esi
	lea	esi,[16+esi]
	mov	DWORD [32+esp],esi
	lea	edi,[16+edi]
	mov	DWORD [36+esp],edi
	sub	ecx,16
	mov	DWORD [40+esp],ecx
	jnz	NEAR L$025fast_dec_loop
	mov	edi,DWORD [52+esp]
	mov	esi,DWORD [48+esp]
	mov	eax,DWORD [edi]
	mov	ebx,DWORD [4+edi]
	mov	ecx,DWORD [8+edi]
	mov	edx,DWORD [12+edi]
	mov	DWORD [esi],eax
	mov	DWORD [4+esi],ebx
	mov	DWORD [8+esi],ecx
	mov	DWORD [12+esi],edx
	jmp	NEAR L$026fast_dec_out
align	16
L$024fast_dec_in_place:
L$027fast_dec_in_place_loop:
	mov	eax,DWORD [esi]
	mov	ebx,DWORD [4+esi]
	mov	ecx,DWORD [8+esi]
	mov	edx,DWORD [12+esi]
	lea	edi,[60+esp]
	mov	DWORD [edi],eax
	mov	DWORD [4+edi],ebx
	mov	DWORD [8+edi],ecx
	mov	DWORD [12+edi],edx
	mov	edi,DWORD [44+esp]
	call	__x86_AES_decrypt
	mov	edi,DWORD [48+esp]
	mov	esi,DWORD [36+esp]
	xor	eax,DWORD [edi]
	xor	ebx,DWORD [4+edi]
	xor	ecx,DWORD [8+edi]
	xor	edx,DWORD [12+edi]
	mov	DWORD [esi],eax
	mov	DWORD [4+esi],ebx
	mov	DWORD [8+esi],ecx
	mov	DWORD [12+esi],edx
	lea	esi,[16+esi]
	mov	DWORD [36+esp],esi
	lea	esi,[60+esp]
	mov	eax,DWORD [esi]
	mov	ebx,DWORD [4+esi]
	mov	ecx,DWORD [8+esi]
	mov	edx,DWORD [12+esi]
	mov	DWORD [edi],eax
	mov	DWORD [4+edi],ebx
	mov	DWORD [8+edi],ecx
	mov	DWORD [12+edi],edx
	mov	esi,DWORD [32+esp]
	mov	ecx,DWORD [40+esp]
	lea	esi,[16+esi]
	mov	DWORD [32+esp],esi
	sub	ecx,16
	mov	DWORD [40+esp],ecx
	jnz	NEAR L$027fast_dec_in_place_loop
align	4
L$026fast_dec_out:
	cmp	DWORD [316+esp],0
	mov	edi,DWORD [44+esp]
	je	NEAR L$028skip_dzero
	mov	ecx,60
	xor	eax,eax
align	4
dd	2884892297
L$028skip_dzero:
	mov	esp,DWORD [28+esp]
	popfd
	pop	edi
	pop	esi
	pop	ebx
	pop	ebp
	ret
	pushfd
align	16
L$015slow_way:
	mov	eax,DWORD [eax]
	mov	edi,DWORD [36+esp]
	lea	esi,[esp-80]
	and	esi,-64
	lea	ebx,[edi-143]
	sub	ebx,esi
	neg	ebx
	and	ebx,960
	sub	esi,ebx
	lea	ebx,[768+esi]
	sub	ebx,ebp
	and	ebx,768
	lea	ebp,[2176+ebx*1+ebp]
	lea	edx,[24+esp]
	xchg	esp,esi
	add	esp,4
	mov	DWORD [24+esp],ebp
	mov	DWORD [28+esp],esi
	mov	DWORD [52+esp],eax
	mov	eax,DWORD [edx]
	mov	ebx,DWORD [4+edx]
	mov	esi,DWORD [16+edx]
	mov	edx,DWORD [20+edx]
	mov	DWORD [32+esp],eax
	mov	DWORD [36+esp],ebx
	mov	DWORD [40+esp],ecx
	mov	DWORD [44+esp],edi
	mov	DWORD [48+esp],esi
	mov	edi,esi
	mov	esi,eax
	cmp	edx,0
	je	NEAR L$029slow_decrypt
	cmp	ecx,16
	mov	edx,ebx
	jb	NEAR L$030slow_enc_tail
	bt	DWORD [52+esp],25
	jnc	NEAR L$031slow_enc_x86
	movq	mm0,[edi]
	movq	mm4,[8+edi]
align	16
L$032slow_enc_loop_sse:
	pxor	mm0,[esi]
	pxor	mm4,[8+esi]
	mov	edi,DWORD [44+esp]
	call	__sse_AES_encrypt_compact
	mov	esi,DWORD [32+esp]
	mov	edi,DWORD [36+esp]
	mov	ecx,DWORD [40+esp]
	movq	[edi],mm0
	movq	[8+edi],mm4
	lea	esi,[16+esi]
	mov	DWORD [32+esp],esi
	lea	edx,[16+edi]
	mov	DWORD [36+esp],edx
	sub	ecx,16
	cmp	ecx,16
	mov	DWORD [40+esp],ecx
	jae	NEAR L$032slow_enc_loop_sse
	test	ecx,15
	jnz	NEAR L$030slow_enc_tail
	mov	esi,DWORD [48+esp]
	movq	[esi],mm0
	movq	[8+esi],mm4
	emms
	mov	esp,DWORD [28+esp]
	popfd
	pop	edi
	pop	esi
	pop	ebx
	pop	ebp
	ret
	pushfd
align	16
L$031slow_enc_x86:
	mov	eax,DWORD [edi]
	mov	ebx,DWORD [4+edi]
align	4
L$033slow_enc_loop_x86:
	mov	ecx,DWORD [8+edi]
	mov	edx,DWORD [12+edi]
	xor	eax,DWORD [esi]
	xor	ebx,DWORD [4+esi]
	xor	ecx,DWORD [8+esi]
	xor	edx,DWORD [12+esi]
	mov	edi,DWORD [44+esp]
	call	__x86_AES_encrypt_compact
	mov	esi,DWORD [32+esp]
	mov	edi,DWORD [36+esp]
	mov	DWORD [edi],eax
	mov	DWORD [4+edi],ebx
	mov	DWORD [8+edi],ecx
	mov	DWORD [12+edi],edx
	mov	ecx,DWORD [40+esp]
	lea	esi,[16+esi]
	mov	DWORD [32+esp],esi
	lea	edx,[16+edi]
	mov	DWORD [36+esp],edx
	sub	ecx,16
	cmp	ecx,16
	mov	DWORD [40+esp],ecx
	jae	NEAR L$033slow_enc_loop_x86
	test	ecx,15
	jnz	NEAR L$030slow_enc_tail
	mov	esi,DWORD [48+esp]
	mov	ecx,DWORD [8+edi]
	mov	edx,DWORD [12+edi]
	mov	DWORD [esi],eax
	mov	DWORD [4+esi],ebx
	mov	DWORD [8+esi],ecx
	mov	DWORD [12+esi],edx
	mov	esp,DWORD [28+esp]
	popfd
	pop	edi
	pop	esi
	pop	ebx
	pop	ebp
	ret
	pushfd
align	16
L$030slow_enc_tail:
	emms
	mov	edi,edx
	mov	ebx,16
	sub	ebx,ecx
	cmp	edi,esi
	je	NEAR L$034enc_in_place
align	4
dd	2767451785
	jmp	NEAR L$035enc_skip_in_place
L$034enc_in_place:
	lea	edi,[ecx*1+edi]
L$035enc_skip_in_place:
	mov	ecx,ebx
	xor	eax,eax
align	4
dd	2868115081
	mov	edi,DWORD [48+esp]
	mov	esi,edx
	mov	eax,DWORD [edi]
	mov	ebx,DWORD [4+edi]
	mov	DWORD [40+esp],16
	jmp	NEAR L$033slow_enc_loop_x86
align	16
L$029slow_decrypt:
	bt	DWORD [52+esp],25
	jnc	NEAR L$036slow_dec_loop_x86
align	4
L$037slow_dec_loop_sse:
	movq	mm0,[esi]
	movq	mm4,[8+esi]
	mov	edi,DWORD [44+esp]
	call	__sse_AES_decrypt_compact
	mov	esi,DWORD [32+esp]
	lea	eax,[60+esp]
	mov	ebx,DWORD [36+esp]
	mov	ecx,DWORD [40+esp]
	mov	edi,DWORD [48+esp]
	movq	mm1,[esi]
	movq	mm5,[8+esi]
	pxor	mm0,[edi]
	pxor	mm4,[8+edi]
	movq	[edi],mm1
	movq	[8+edi],mm5
	sub	ecx,16
	jc	NEAR L$038slow_dec_partial_sse
	movq	[ebx],mm0
	movq	[8+ebx],mm4
	lea	ebx,[16+ebx]
	mov	DWORD [36+esp],ebx
	lea	esi,[16+esi]
	mov	DWORD [32+esp],esi
	mov	DWORD [40+esp],ecx
	jnz	NEAR L$037slow_dec_loop_sse
	emms
	mov	esp,DWORD [28+esp]
	popfd
	pop	edi
	pop	esi
	pop	ebx
	pop	ebp
	ret
	pushfd
align	16
L$038slow_dec_partial_sse:
	movq	[eax],mm0
	movq	[8+eax],mm4
	emms
	add	ecx,16
	mov	edi,ebx
	mov	esi,eax
align	4
dd	2767451785
	mov	esp,DWORD [28+esp]
	popfd
	pop	edi
	pop	esi
	pop	ebx
	pop	ebp
	ret
	pushfd
align	16
L$036slow_dec_loop_x86:
	mov	eax,DWORD [esi]
	mov	ebx,DWORD [4+esi]
	mov	ecx,DWORD [8+esi]
	mov	edx,DWORD [12+esi]
	lea	edi,[60+esp]
	mov	DWORD [edi],eax
	mov	DWORD [4+edi],ebx
	mov	DWORD [8+edi],ecx
	mov	DWORD [12+edi],edx
	mov	edi,DWORD [44+esp]
	call	__x86_AES_decrypt_compact
	mov	edi,DWORD [48+esp]
	mov	esi,DWORD [40+esp]
	xor	eax,DWORD [edi]
	xor	ebx,DWORD [4+edi]
	xor	ecx,DWORD [8+edi]
	xor	edx,DWORD [12+edi]
	sub	esi,16
	jc	NEAR L$039slow_dec_partial_x86
	mov	DWORD [40+esp],esi
	mov	esi,DWORD [36+esp]
	mov	DWORD [esi],eax
	mov	DWORD [4+esi],ebx
	mov	DWORD [8+esi],ecx
	mov	DWORD [12+esi],edx
	lea	esi,[16+esi]
	mov	DWORD [36+esp],esi
	lea	esi,[60+esp]
	mov	eax,DWORD [esi]
	mov	ebx,DWORD [4+esi]
	mov	ecx,DWORD [8+esi]
	mov	edx,DWORD [12+esi]
	mov	DWORD [edi],eax
	mov	DWORD [4+edi],ebx
	mov	DWORD [8+edi],ecx
	mov	DWORD [12+edi],edx
	mov	esi,DWORD [32+esp]
	lea	esi,[16+esi]
	mov	DWORD [32+esp],esi
	jnz	NEAR L$036slow_dec_loop_x86
	mov	esp,DWORD [28+esp]
	popfd
	pop	edi
	pop	esi
	pop	ebx
	pop	ebp
	ret
	pushfd
align	16
L$039slow_dec_partial_x86:
	lea	esi,[60+esp]
	mov	DWORD [esi],eax
	mov	DWORD [4+esi],ebx
	mov	DWORD [8+esi],ecx
	mov	DWORD [12+esi],edx
	mov	esi,DWORD [32+esp]
	mov	eax,DWORD [esi]
	mov	ebx,DWORD [4+esi]
	mov	ecx,DWORD [8+esi]
	mov	edx,DWORD [12+esi]
	mov	DWORD [edi],eax
	mov	DWORD [4+edi],ebx
	mov	DWORD [8+edi],ecx
	mov	DWORD [12+edi],edx
	mov	ecx,DWORD [40+esp]
	mov	edi,DWORD [36+esp]
	lea	esi,[60+esp]
align	4
dd	2767451785
	mov	esp,DWORD [28+esp]
	popfd
	pop	edi
	pop	esi
	pop	ebx
	pop	ebp
	ret
align	16
__x86_AES_set_encrypt_key:
	push	ebp
	push	ebx
	push	esi
	push	edi
	mov	esi,DWORD [24+esp]
	mov	edi,DWORD [32+esp]
	test	esi,-1
	jz	NEAR L$040badpointer
	test	edi,-1
	jz	NEAR L$040badpointer
	call	L$041pic_point
L$041pic_point:
	pop	ebp
	lea	ebp,[(L$AES_Te-L$041pic_point)+ebp]
	lea	ebp,[2176+ebp]
	mov	eax,DWORD [ebp-128]
	mov	ebx,DWORD [ebp-96]
	mov	ecx,DWORD [ebp-64]
	mov	edx,DWORD [ebp-32]
	mov	eax,DWORD [ebp]
	mov	ebx,DWORD [32+ebp]
	mov	ecx,DWORD [64+ebp]
	mov	edx,DWORD [96+ebp]
	mov	ecx,DWORD [28+esp]
	cmp	ecx,128
	je	NEAR L$04210rounds
	cmp	ecx,192
	je	NEAR L$04312rounds
	cmp	ecx,256
	je	NEAR L$04414rounds
	mov	eax,-2
	jmp	NEAR L$045exit
L$04210rounds:
	mov	eax,DWORD [esi]
	mov	ebx,DWORD [4+esi]
	mov	ecx,DWORD [8+esi]
	mov	edx,DWORD [12+esi]
	mov	DWORD [edi],eax
	mov	DWORD [4+edi],ebx
	mov	DWORD [8+edi],ecx
	mov	DWORD [12+edi],edx
	xor	ecx,ecx
	jmp	NEAR L$04610shortcut
align	4
L$04710loop:
	mov	eax,DWORD [edi]
	mov	edx,DWORD [12+edi]
L$04610shortcut:
	movzx	esi,dl
	movzx	ebx,BYTE [esi*1+ebp-128]
	movzx	esi,dh
	shl	ebx,24
	xor	eax,ebx
	movzx	ebx,BYTE [esi*1+ebp-128]
	shr	edx,16
	movzx	esi,dl
	xor	eax,ebx
	movzx	ebx,BYTE [esi*1+ebp-128]
	movzx	esi,dh
	shl	ebx,8
	xor	eax,ebx
	movzx	ebx,BYTE [esi*1+ebp-128]
	shl	ebx,16
	xor	eax,ebx
	xor	eax,DWORD [896+ecx*4+ebp]
	mov	DWORD [16+edi],eax
	xor	eax,DWORD [4+edi]
	mov	DWORD [20+edi],eax
	xor	eax,DWORD [8+edi]
	mov	DWORD [24+edi],eax
	xor	eax,DWORD [12+edi]
	mov	DWORD [28+edi],eax
	inc	ecx
	add	edi,16
	cmp	ecx,10
	jl	NEAR L$04710loop
	mov	DWORD [80+edi],10
	xor	eax,eax
	jmp	NEAR L$045exit
L$04312rounds:
	mov	eax,DWORD [esi]
	mov	ebx,DWORD [4+esi]
	mov	ecx,DWORD [8+esi]
	mov	edx,DWORD [12+esi]
	mov	DWORD [edi],eax
	mov	DWORD [4+edi],ebx
	mov	DWORD [8+edi],ecx
	mov	DWORD [12+edi],edx
	mov	ecx,DWORD [16+esi]
	mov	edx,DWORD [20+esi]
	mov	DWORD [16+edi],ecx
	mov	DWORD [20+edi],edx
	xor	ecx,ecx
	jmp	NEAR L$04812shortcut
align	4
L$04912loop:
	mov	eax,DWORD [edi]
	mov	edx,DWORD [20+edi]
L$04812shortcut:
	movzx	esi,dl
	movzx	ebx,BYTE [esi*1+ebp-128]
	movzx	esi,dh
	shl	ebx,24
	xor	eax,ebx
	movzx	ebx,BYTE [esi*1+ebp-128]
	shr	edx,16
	movzx	esi,dl
	xor	eax,ebx
	movzx	ebx,BYTE [esi*1+ebp-128]
	movzx	esi,dh
	shl	ebx,8
	xor	eax,ebx
	movzx	ebx,BYTE [esi*1+ebp-128]
	shl	ebx,16
	xor	eax,ebx
	xor	eax,DWORD [896+ecx*4+ebp]
	mov	DWORD [24+edi],eax
	xor	eax,DWORD [4+edi]
	mov	DWORD [28+edi],eax
	xor	eax,DWORD [8+edi]
	mov	DWORD [32+edi],eax
	xor	eax,DWORD [12+edi]
	mov	DWORD [36+edi],eax
	cmp	ecx,7
	je	NEAR L$05012break
	inc	ecx
	xor	eax,DWORD [16+edi]
	mov	DWORD [40+edi],eax
	xor	eax,DWORD [20+edi]
	mov	DWORD [44+edi],eax
	add	edi,24
	jmp	NEAR L$04912loop
L$05012break:
	mov	DWORD [72+edi],12
	xor	eax,eax
	jmp	NEAR L$045exit
L$04414rounds:
	mov	eax,DWORD [esi]
	mov	ebx,DWORD [4+esi]
	mov	ecx,DWORD [8+esi]
	mov	edx,DWORD [12+esi]
	mov	DWORD [edi],eax
	mov	DWORD [4+edi],ebx
	mov	DWORD [8+edi],ecx
	mov	DWORD [12+edi],edx
	mov	eax,DWORD [16+esi]
	mov	ebx,DWORD [20+esi]
	mov	ecx,DWORD [24+esi]
	mov	edx,DWORD [28+esi]
	mov	DWORD [16+edi],eax
	mov	DWORD [20+edi],ebx
	mov	DWORD [24+edi],ecx
	mov	DWORD [28+edi],edx
	xor	ecx,ecx
	jmp	NEAR L$05114shortcut
align	4
L$05214loop:
	mov	edx,DWORD [28+edi]
L$05114shortcut:
	mov	eax,DWORD [edi]
	movzx	esi,dl
	movzx	ebx,BYTE [esi*1+ebp-128]
	movzx	esi,dh
	shl	ebx,24
	xor	eax,ebx
	movzx	ebx,BYTE [esi*1+ebp-128]
	shr	edx,16
	movzx	esi,dl
	xor	eax,ebx
	movzx	ebx,BYTE [esi*1+ebp-128]
	movzx	esi,dh
	shl	ebx,8
	xor	eax,ebx
	movzx	ebx,BYTE [esi*1+ebp-128]
	shl	ebx,16
	xor	eax,ebx
	xor	eax,DWORD [896+ecx*4+ebp]
	mov	DWORD [32+edi],eax
	xor	eax,DWORD [4+edi]
	mov	DWORD [36+edi],eax
	xor	eax,DWORD [8+edi]
	mov	DWORD [40+edi],eax
	xor	eax,DWORD [12+edi]
	mov	DWORD [44+edi],eax
	cmp	ecx,6
	je	NEAR L$05314break
	inc	ecx
	mov	edx,eax
	mov	eax,DWORD [16+edi]
	movzx	esi,dl
	movzx	ebx,BYTE [esi*1+ebp-128]
	movzx	esi,dh
	xor	eax,ebx
	movzx	ebx,BYTE [esi*1+ebp-128]
	shr	edx,16
	shl	ebx,8
	movzx	esi,dl
	xor	eax,ebx
	movzx	ebx,BYTE [esi*1+ebp-128]
	movzx	esi,dh
	shl	ebx,16
	xor	eax,ebx
	movzx	ebx,BYTE [esi*1+ebp-128]
	shl	ebx,24
	xor	eax,ebx
	mov	DWORD [48+edi],eax
	xor	eax,DWORD [20+edi]
	mov	DWORD [52+edi],eax
	xor	eax,DWORD [24+edi]
	mov	DWORD [56+edi],eax
	xor	eax,DWORD [28+edi]
	mov	DWORD [60+edi],eax
	add	edi,32
	jmp	NEAR L$05214loop
L$05314break:
	mov	DWORD [48+edi],14
	xor	eax,eax
	jmp	NEAR L$045exit
L$040badpointer:
	mov	eax,-1
L$045exit:
	pop	edi
	pop	esi
	pop	ebx
	pop	ebp
	ret
global	_asm_AES_set_encrypt_key
align	16
_asm_AES_set_encrypt_key:
L$_asm_AES_set_encrypt_key_begin:
	call	__x86_AES_set_encrypt_key
	ret
global	_asm_AES_set_decrypt_key
align	16
_asm_AES_set_decrypt_key:
L$_asm_AES_set_decrypt_key_begin:
	call	__x86_AES_set_encrypt_key
	cmp	eax,0
	je	NEAR L$054proceed
	ret
L$054proceed:
	push	ebp
	push	ebx
	push	esi
	push	edi
	mov	esi,DWORD [28+esp]
	mov	ecx,DWORD [240+esi]
	lea	ecx,[ecx*4]
	lea	edi,[ecx*4+esi]
align	4
L$055invert:
	mov	eax,DWORD [esi]
	mov	ebx,DWORD [4+esi]
	mov	ecx,DWORD [edi]
	mov	edx,DWORD [4+edi]
	mov	DWORD [edi],eax
	mov	DWORD [4+edi],ebx
	mov	DWORD [esi],ecx
	mov	DWORD [4+esi],edx
	mov	eax,DWORD [8+esi]
	mov	ebx,DWORD [12+esi]
	mov	ecx,DWORD [8+edi]
	mov	edx,DWORD [12+edi]
	mov	DWORD [8+edi],eax
	mov	DWORD [12+edi],ebx
	mov	DWORD [8+esi],ecx
	mov	DWORD [12+esi],edx
	add	esi,16
	sub	edi,16
	cmp	esi,edi
	jne	NEAR L$055invert
	mov	edi,DWORD [28+esp]
	mov	esi,DWORD [240+edi]
	lea	esi,[esi*1+esi-2]
	lea	esi,[esi*8+edi]
	mov	DWORD [28+esp],esi
	mov	eax,DWORD [16+edi]
align	4
L$056permute:
	add	edi,16
	mov	ebp,2155905152
	and	ebp,eax
	lea	ebx,[eax*1+eax]
	mov	esi,ebp
	shr	ebp,7
	sub	esi,ebp
	and	ebx,4278124286
	and	esi,454761243
	xor	ebx,esi
	mov	ebp,2155905152
	and	ebp,ebx
	lea	ecx,[ebx*1+ebx]
	mov	esi,ebp
	shr	ebp,7
	sub	esi,ebp
	and	ecx,4278124286
	and	esi,454761243
	xor	ebx,eax
	xor	ecx,esi
	mov	ebp,2155905152
	and	ebp,ecx
	lea	edx,[ecx*1+ecx]
	mov	esi,ebp
	shr	ebp,7
	xor	ecx,eax
	sub	esi,ebp
	and	edx,4278124286
	and	esi,454761243
	rol	eax,8
	xor	edx,esi
	mov	ebp,DWORD [4+edi]
	xor	eax,ebx
	xor	ebx,edx
	xor	eax,ecx
	rol	ebx,24
	xor	ecx,edx
	xor	eax,edx
	rol	ecx,16
	xor	eax,ebx
	rol	edx,8
	xor	eax,ecx
	mov	ebx,ebp
	xor	eax,edx
	mov	DWORD [edi],eax
	mov	ebp,2155905152
	and	ebp,ebx
	lea	ecx,[ebx*1+ebx]
	mov	esi,ebp
	shr	ebp,7
	sub	esi,ebp
	and	ecx,4278124286
	and	esi,454761243
	xor	ecx,esi
	mov	ebp,2155905152
	and	ebp,ecx
	lea	edx,[ecx*1+ecx]
	mov	esi,ebp
	shr	ebp,7
	sub	esi,ebp
	and	edx,4278124286
	and	esi,454761243
	xor	ecx,ebx
	xor	edx,esi
	mov	ebp,2155905152
	and	ebp,edx
	lea	eax,[edx*1+edx]
	mov	esi,ebp
	shr	ebp,7
	xor	edx,ebx
	sub	esi,ebp
	and	eax,4278124286
	and	esi,454761243
	rol	ebx,8
	xor	eax,esi
	mov	ebp,DWORD [8+edi]
	xor	ebx,ecx
	xor	ecx,eax
	xor	ebx,edx
	rol	ecx,24
	xor	edx,eax
	xor	ebx,eax
	rol	edx,16
	xor	ebx,ecx
	rol	eax,8
	xor	ebx,edx
	mov	ecx,ebp
	xor	ebx,eax
	mov	DWORD [4+edi],ebx
	mov	ebp,2155905152
	and	ebp,ecx
	lea	edx,[ecx*1+ecx]
	mov	esi,ebp
	shr	ebp,7
	sub	esi,ebp
	and	edx,4278124286
	and	esi,454761243
	xor	edx,esi
	mov	ebp,2155905152
	and	ebp,edx
	lea	eax,[edx*1+edx]
	mov	esi,ebp
	shr	ebp,7
	sub	esi,ebp
	and	eax,4278124286
	and	esi,454761243
	xor	edx,ecx
	xor	eax,esi
	mov	ebp,2155905152
	and	ebp,eax
	lea	ebx,[eax*1+eax]
	mov	esi,ebp
	shr	ebp,7
	xor	eax,ecx
	sub	esi,ebp
	and	ebx,4278124286
	and	esi,454761243
	rol	ecx,8
	xor	ebx,esi
	mov	ebp,DWORD [12+edi]
	xor	ecx,edx
	xor	edx,ebx
	xor	ecx,eax
	rol	edx,24
	xor	eax,ebx
	xor	ecx,ebx
	rol	eax,16
	xor	ecx,edx
	rol	ebx,8
	xor	ecx,eax
	mov	edx,ebp
	xor	ecx,ebx
	mov	DWORD [8+edi],ecx
	mov	ebp,2155905152
	and	ebp,edx
	lea	eax,[edx*1+edx]
	mov	esi,ebp
	shr	ebp,7
	sub	esi,ebp
	and	eax,4278124286
	and	esi,454761243
	xor	eax,esi
	mov	ebp,2155905152
	and	ebp,eax
	lea	ebx,[eax*1+eax]
	mov	esi,ebp
	shr	ebp,7
	sub	esi,ebp
	and	ebx,4278124286
	and	esi,454761243
	xor	eax,edx
	xor	ebx,esi
	mov	ebp,2155905152
	and	ebp,ebx
	lea	ecx,[ebx*1+ebx]
	mov	esi,ebp
	shr	ebp,7
	xor	ebx,edx
	sub	esi,ebp
	and	ecx,4278124286
	and	esi,454761243
	rol	edx,8
	xor	ecx,esi
	mov	ebp,DWORD [16+edi]
	xor	edx,eax
	xor	eax,ecx
	xor	edx,ebx
	rol	eax,24
	xor	ebx,ecx
	xor	edx,ecx
	rol	ebx,16
	xor	edx,eax
	rol	ecx,8
	xor	edx,ebx
	mov	eax,ebp
	xor	edx,ecx
	mov	DWORD [12+edi],edx
	cmp	edi,DWORD [28+esp]
	jb	NEAR L$056permute
	xor	eax,eax
	pop	edi
	pop	esi
	pop	ebx
	pop	ebp
	ret
db	65,69,83,32,102,111,114,32,120,56,54,44,32,67,82,89
db	80,84,79,71,65,77,83,32,98,121,32,60,97,112,112,114
db	111,64,111,112,101,110,115,115,108,46,111,114,103,62,0
segment	.bss
common	_OPENSSL_ia32cap_P 16
