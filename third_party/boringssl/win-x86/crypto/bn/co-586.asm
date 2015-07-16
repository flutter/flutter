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
global	_bn_mul_comba8
align	16
_bn_mul_comba8:
L$_bn_mul_comba8_begin:
	push	esi
	mov	esi,DWORD [12+esp]
	push	edi
	mov	edi,DWORD [20+esp]
	push	ebp
	push	ebx
	xor	ebx,ebx
	mov	eax,DWORD [esi]
	xor	ecx,ecx
	mov	edx,DWORD [edi]
	; ################## Calculate word 0
	xor	ebp,ebp
	; mul a[0]*b[0]
	mul	edx
	add	ebx,eax
	mov	eax,DWORD [20+esp]
	adc	ecx,edx
	mov	edx,DWORD [edi]
	adc	ebp,0
	mov	DWORD [eax],ebx
	mov	eax,DWORD [4+esi]
	; saved r[0]
	; ################## Calculate word 1
	xor	ebx,ebx
	; mul a[1]*b[0]
	mul	edx
	add	ecx,eax
	mov	eax,DWORD [esi]
	adc	ebp,edx
	mov	edx,DWORD [4+edi]
	adc	ebx,0
	; mul a[0]*b[1]
	mul	edx
	add	ecx,eax
	mov	eax,DWORD [20+esp]
	adc	ebp,edx
	mov	edx,DWORD [edi]
	adc	ebx,0
	mov	DWORD [4+eax],ecx
	mov	eax,DWORD [8+esi]
	; saved r[1]
	; ################## Calculate word 2
	xor	ecx,ecx
	; mul a[2]*b[0]
	mul	edx
	add	ebp,eax
	mov	eax,DWORD [4+esi]
	adc	ebx,edx
	mov	edx,DWORD [4+edi]
	adc	ecx,0
	; mul a[1]*b[1]
	mul	edx
	add	ebp,eax
	mov	eax,DWORD [esi]
	adc	ebx,edx
	mov	edx,DWORD [8+edi]
	adc	ecx,0
	; mul a[0]*b[2]
	mul	edx
	add	ebp,eax
	mov	eax,DWORD [20+esp]
	adc	ebx,edx
	mov	edx,DWORD [edi]
	adc	ecx,0
	mov	DWORD [8+eax],ebp
	mov	eax,DWORD [12+esi]
	; saved r[2]
	; ################## Calculate word 3
	xor	ebp,ebp
	; mul a[3]*b[0]
	mul	edx
	add	ebx,eax
	mov	eax,DWORD [8+esi]
	adc	ecx,edx
	mov	edx,DWORD [4+edi]
	adc	ebp,0
	; mul a[2]*b[1]
	mul	edx
	add	ebx,eax
	mov	eax,DWORD [4+esi]
	adc	ecx,edx
	mov	edx,DWORD [8+edi]
	adc	ebp,0
	; mul a[1]*b[2]
	mul	edx
	add	ebx,eax
	mov	eax,DWORD [esi]
	adc	ecx,edx
	mov	edx,DWORD [12+edi]
	adc	ebp,0
	; mul a[0]*b[3]
	mul	edx
	add	ebx,eax
	mov	eax,DWORD [20+esp]
	adc	ecx,edx
	mov	edx,DWORD [edi]
	adc	ebp,0
	mov	DWORD [12+eax],ebx
	mov	eax,DWORD [16+esi]
	; saved r[3]
	; ################## Calculate word 4
	xor	ebx,ebx
	; mul a[4]*b[0]
	mul	edx
	add	ecx,eax
	mov	eax,DWORD [12+esi]
	adc	ebp,edx
	mov	edx,DWORD [4+edi]
	adc	ebx,0
	; mul a[3]*b[1]
	mul	edx
	add	ecx,eax
	mov	eax,DWORD [8+esi]
	adc	ebp,edx
	mov	edx,DWORD [8+edi]
	adc	ebx,0
	; mul a[2]*b[2]
	mul	edx
	add	ecx,eax
	mov	eax,DWORD [4+esi]
	adc	ebp,edx
	mov	edx,DWORD [12+edi]
	adc	ebx,0
	; mul a[1]*b[3]
	mul	edx
	add	ecx,eax
	mov	eax,DWORD [esi]
	adc	ebp,edx
	mov	edx,DWORD [16+edi]
	adc	ebx,0
	; mul a[0]*b[4]
	mul	edx
	add	ecx,eax
	mov	eax,DWORD [20+esp]
	adc	ebp,edx
	mov	edx,DWORD [edi]
	adc	ebx,0
	mov	DWORD [16+eax],ecx
	mov	eax,DWORD [20+esi]
	; saved r[4]
	; ################## Calculate word 5
	xor	ecx,ecx
	; mul a[5]*b[0]
	mul	edx
	add	ebp,eax
	mov	eax,DWORD [16+esi]
	adc	ebx,edx
	mov	edx,DWORD [4+edi]
	adc	ecx,0
	; mul a[4]*b[1]
	mul	edx
	add	ebp,eax
	mov	eax,DWORD [12+esi]
	adc	ebx,edx
	mov	edx,DWORD [8+edi]
	adc	ecx,0
	; mul a[3]*b[2]
	mul	edx
	add	ebp,eax
	mov	eax,DWORD [8+esi]
	adc	ebx,edx
	mov	edx,DWORD [12+edi]
	adc	ecx,0
	; mul a[2]*b[3]
	mul	edx
	add	ebp,eax
	mov	eax,DWORD [4+esi]
	adc	ebx,edx
	mov	edx,DWORD [16+edi]
	adc	ecx,0
	; mul a[1]*b[4]
	mul	edx
	add	ebp,eax
	mov	eax,DWORD [esi]
	adc	ebx,edx
	mov	edx,DWORD [20+edi]
	adc	ecx,0
	; mul a[0]*b[5]
	mul	edx
	add	ebp,eax
	mov	eax,DWORD [20+esp]
	adc	ebx,edx
	mov	edx,DWORD [edi]
	adc	ecx,0
	mov	DWORD [20+eax],ebp
	mov	eax,DWORD [24+esi]
	; saved r[5]
	; ################## Calculate word 6
	xor	ebp,ebp
	; mul a[6]*b[0]
	mul	edx
	add	ebx,eax
	mov	eax,DWORD [20+esi]
	adc	ecx,edx
	mov	edx,DWORD [4+edi]
	adc	ebp,0
	; mul a[5]*b[1]
	mul	edx
	add	ebx,eax
	mov	eax,DWORD [16+esi]
	adc	ecx,edx
	mov	edx,DWORD [8+edi]
	adc	ebp,0
	; mul a[4]*b[2]
	mul	edx
	add	ebx,eax
	mov	eax,DWORD [12+esi]
	adc	ecx,edx
	mov	edx,DWORD [12+edi]
	adc	ebp,0
	; mul a[3]*b[3]
	mul	edx
	add	ebx,eax
	mov	eax,DWORD [8+esi]
	adc	ecx,edx
	mov	edx,DWORD [16+edi]
	adc	ebp,0
	; mul a[2]*b[4]
	mul	edx
	add	ebx,eax
	mov	eax,DWORD [4+esi]
	adc	ecx,edx
	mov	edx,DWORD [20+edi]
	adc	ebp,0
	; mul a[1]*b[5]
	mul	edx
	add	ebx,eax
	mov	eax,DWORD [esi]
	adc	ecx,edx
	mov	edx,DWORD [24+edi]
	adc	ebp,0
	; mul a[0]*b[6]
	mul	edx
	add	ebx,eax
	mov	eax,DWORD [20+esp]
	adc	ecx,edx
	mov	edx,DWORD [edi]
	adc	ebp,0
	mov	DWORD [24+eax],ebx
	mov	eax,DWORD [28+esi]
	; saved r[6]
	; ################## Calculate word 7
	xor	ebx,ebx
	; mul a[7]*b[0]
	mul	edx
	add	ecx,eax
	mov	eax,DWORD [24+esi]
	adc	ebp,edx
	mov	edx,DWORD [4+edi]
	adc	ebx,0
	; mul a[6]*b[1]
	mul	edx
	add	ecx,eax
	mov	eax,DWORD [20+esi]
	adc	ebp,edx
	mov	edx,DWORD [8+edi]
	adc	ebx,0
	; mul a[5]*b[2]
	mul	edx
	add	ecx,eax
	mov	eax,DWORD [16+esi]
	adc	ebp,edx
	mov	edx,DWORD [12+edi]
	adc	ebx,0
	; mul a[4]*b[3]
	mul	edx
	add	ecx,eax
	mov	eax,DWORD [12+esi]
	adc	ebp,edx
	mov	edx,DWORD [16+edi]
	adc	ebx,0
	; mul a[3]*b[4]
	mul	edx
	add	ecx,eax
	mov	eax,DWORD [8+esi]
	adc	ebp,edx
	mov	edx,DWORD [20+edi]
	adc	ebx,0
	; mul a[2]*b[5]
	mul	edx
	add	ecx,eax
	mov	eax,DWORD [4+esi]
	adc	ebp,edx
	mov	edx,DWORD [24+edi]
	adc	ebx,0
	; mul a[1]*b[6]
	mul	edx
	add	ecx,eax
	mov	eax,DWORD [esi]
	adc	ebp,edx
	mov	edx,DWORD [28+edi]
	adc	ebx,0
	; mul a[0]*b[7]
	mul	edx
	add	ecx,eax
	mov	eax,DWORD [20+esp]
	adc	ebp,edx
	mov	edx,DWORD [4+edi]
	adc	ebx,0
	mov	DWORD [28+eax],ecx
	mov	eax,DWORD [28+esi]
	; saved r[7]
	; ################## Calculate word 8
	xor	ecx,ecx
	; mul a[7]*b[1]
	mul	edx
	add	ebp,eax
	mov	eax,DWORD [24+esi]
	adc	ebx,edx
	mov	edx,DWORD [8+edi]
	adc	ecx,0
	; mul a[6]*b[2]
	mul	edx
	add	ebp,eax
	mov	eax,DWORD [20+esi]
	adc	ebx,edx
	mov	edx,DWORD [12+edi]
	adc	ecx,0
	; mul a[5]*b[3]
	mul	edx
	add	ebp,eax
	mov	eax,DWORD [16+esi]
	adc	ebx,edx
	mov	edx,DWORD [16+edi]
	adc	ecx,0
	; mul a[4]*b[4]
	mul	edx
	add	ebp,eax
	mov	eax,DWORD [12+esi]
	adc	ebx,edx
	mov	edx,DWORD [20+edi]
	adc	ecx,0
	; mul a[3]*b[5]
	mul	edx
	add	ebp,eax
	mov	eax,DWORD [8+esi]
	adc	ebx,edx
	mov	edx,DWORD [24+edi]
	adc	ecx,0
	; mul a[2]*b[6]
	mul	edx
	add	ebp,eax
	mov	eax,DWORD [4+esi]
	adc	ebx,edx
	mov	edx,DWORD [28+edi]
	adc	ecx,0
	; mul a[1]*b[7]
	mul	edx
	add	ebp,eax
	mov	eax,DWORD [20+esp]
	adc	ebx,edx
	mov	edx,DWORD [8+edi]
	adc	ecx,0
	mov	DWORD [32+eax],ebp
	mov	eax,DWORD [28+esi]
	; saved r[8]
	; ################## Calculate word 9
	xor	ebp,ebp
	; mul a[7]*b[2]
	mul	edx
	add	ebx,eax
	mov	eax,DWORD [24+esi]
	adc	ecx,edx
	mov	edx,DWORD [12+edi]
	adc	ebp,0
	; mul a[6]*b[3]
	mul	edx
	add	ebx,eax
	mov	eax,DWORD [20+esi]
	adc	ecx,edx
	mov	edx,DWORD [16+edi]
	adc	ebp,0
	; mul a[5]*b[4]
	mul	edx
	add	ebx,eax
	mov	eax,DWORD [16+esi]
	adc	ecx,edx
	mov	edx,DWORD [20+edi]
	adc	ebp,0
	; mul a[4]*b[5]
	mul	edx
	add	ebx,eax
	mov	eax,DWORD [12+esi]
	adc	ecx,edx
	mov	edx,DWORD [24+edi]
	adc	ebp,0
	; mul a[3]*b[6]
	mul	edx
	add	ebx,eax
	mov	eax,DWORD [8+esi]
	adc	ecx,edx
	mov	edx,DWORD [28+edi]
	adc	ebp,0
	; mul a[2]*b[7]
	mul	edx
	add	ebx,eax
	mov	eax,DWORD [20+esp]
	adc	ecx,edx
	mov	edx,DWORD [12+edi]
	adc	ebp,0
	mov	DWORD [36+eax],ebx
	mov	eax,DWORD [28+esi]
	; saved r[9]
	; ################## Calculate word 10
	xor	ebx,ebx
	; mul a[7]*b[3]
	mul	edx
	add	ecx,eax
	mov	eax,DWORD [24+esi]
	adc	ebp,edx
	mov	edx,DWORD [16+edi]
	adc	ebx,0
	; mul a[6]*b[4]
	mul	edx
	add	ecx,eax
	mov	eax,DWORD [20+esi]
	adc	ebp,edx
	mov	edx,DWORD [20+edi]
	adc	ebx,0
	; mul a[5]*b[5]
	mul	edx
	add	ecx,eax
	mov	eax,DWORD [16+esi]
	adc	ebp,edx
	mov	edx,DWORD [24+edi]
	adc	ebx,0
	; mul a[4]*b[6]
	mul	edx
	add	ecx,eax
	mov	eax,DWORD [12+esi]
	adc	ebp,edx
	mov	edx,DWORD [28+edi]
	adc	ebx,0
	; mul a[3]*b[7]
	mul	edx
	add	ecx,eax
	mov	eax,DWORD [20+esp]
	adc	ebp,edx
	mov	edx,DWORD [16+edi]
	adc	ebx,0
	mov	DWORD [40+eax],ecx
	mov	eax,DWORD [28+esi]
	; saved r[10]
	; ################## Calculate word 11
	xor	ecx,ecx
	; mul a[7]*b[4]
	mul	edx
	add	ebp,eax
	mov	eax,DWORD [24+esi]
	adc	ebx,edx
	mov	edx,DWORD [20+edi]
	adc	ecx,0
	; mul a[6]*b[5]
	mul	edx
	add	ebp,eax
	mov	eax,DWORD [20+esi]
	adc	ebx,edx
	mov	edx,DWORD [24+edi]
	adc	ecx,0
	; mul a[5]*b[6]
	mul	edx
	add	ebp,eax
	mov	eax,DWORD [16+esi]
	adc	ebx,edx
	mov	edx,DWORD [28+edi]
	adc	ecx,0
	; mul a[4]*b[7]
	mul	edx
	add	ebp,eax
	mov	eax,DWORD [20+esp]
	adc	ebx,edx
	mov	edx,DWORD [20+edi]
	adc	ecx,0
	mov	DWORD [44+eax],ebp
	mov	eax,DWORD [28+esi]
	; saved r[11]
	; ################## Calculate word 12
	xor	ebp,ebp
	; mul a[7]*b[5]
	mul	edx
	add	ebx,eax
	mov	eax,DWORD [24+esi]
	adc	ecx,edx
	mov	edx,DWORD [24+edi]
	adc	ebp,0
	; mul a[6]*b[6]
	mul	edx
	add	ebx,eax
	mov	eax,DWORD [20+esi]
	adc	ecx,edx
	mov	edx,DWORD [28+edi]
	adc	ebp,0
	; mul a[5]*b[7]
	mul	edx
	add	ebx,eax
	mov	eax,DWORD [20+esp]
	adc	ecx,edx
	mov	edx,DWORD [24+edi]
	adc	ebp,0
	mov	DWORD [48+eax],ebx
	mov	eax,DWORD [28+esi]
	; saved r[12]
	; ################## Calculate word 13
	xor	ebx,ebx
	; mul a[7]*b[6]
	mul	edx
	add	ecx,eax
	mov	eax,DWORD [24+esi]
	adc	ebp,edx
	mov	edx,DWORD [28+edi]
	adc	ebx,0
	; mul a[6]*b[7]
	mul	edx
	add	ecx,eax
	mov	eax,DWORD [20+esp]
	adc	ebp,edx
	mov	edx,DWORD [28+edi]
	adc	ebx,0
	mov	DWORD [52+eax],ecx
	mov	eax,DWORD [28+esi]
	; saved r[13]
	; ################## Calculate word 14
	xor	ecx,ecx
	; mul a[7]*b[7]
	mul	edx
	add	ebp,eax
	mov	eax,DWORD [20+esp]
	adc	ebx,edx
	adc	ecx,0
	mov	DWORD [56+eax],ebp
	; saved r[14]
	; save r[15]
	mov	DWORD [60+eax],ebx
	pop	ebx
	pop	ebp
	pop	edi
	pop	esi
	ret
global	_bn_mul_comba4
align	16
_bn_mul_comba4:
L$_bn_mul_comba4_begin:
	push	esi
	mov	esi,DWORD [12+esp]
	push	edi
	mov	edi,DWORD [20+esp]
	push	ebp
	push	ebx
	xor	ebx,ebx
	mov	eax,DWORD [esi]
	xor	ecx,ecx
	mov	edx,DWORD [edi]
	; ################## Calculate word 0
	xor	ebp,ebp
	; mul a[0]*b[0]
	mul	edx
	add	ebx,eax
	mov	eax,DWORD [20+esp]
	adc	ecx,edx
	mov	edx,DWORD [edi]
	adc	ebp,0
	mov	DWORD [eax],ebx
	mov	eax,DWORD [4+esi]
	; saved r[0]
	; ################## Calculate word 1
	xor	ebx,ebx
	; mul a[1]*b[0]
	mul	edx
	add	ecx,eax
	mov	eax,DWORD [esi]
	adc	ebp,edx
	mov	edx,DWORD [4+edi]
	adc	ebx,0
	; mul a[0]*b[1]
	mul	edx
	add	ecx,eax
	mov	eax,DWORD [20+esp]
	adc	ebp,edx
	mov	edx,DWORD [edi]
	adc	ebx,0
	mov	DWORD [4+eax],ecx
	mov	eax,DWORD [8+esi]
	; saved r[1]
	; ################## Calculate word 2
	xor	ecx,ecx
	; mul a[2]*b[0]
	mul	edx
	add	ebp,eax
	mov	eax,DWORD [4+esi]
	adc	ebx,edx
	mov	edx,DWORD [4+edi]
	adc	ecx,0
	; mul a[1]*b[1]
	mul	edx
	add	ebp,eax
	mov	eax,DWORD [esi]
	adc	ebx,edx
	mov	edx,DWORD [8+edi]
	adc	ecx,0
	; mul a[0]*b[2]
	mul	edx
	add	ebp,eax
	mov	eax,DWORD [20+esp]
	adc	ebx,edx
	mov	edx,DWORD [edi]
	adc	ecx,0
	mov	DWORD [8+eax],ebp
	mov	eax,DWORD [12+esi]
	; saved r[2]
	; ################## Calculate word 3
	xor	ebp,ebp
	; mul a[3]*b[0]
	mul	edx
	add	ebx,eax
	mov	eax,DWORD [8+esi]
	adc	ecx,edx
	mov	edx,DWORD [4+edi]
	adc	ebp,0
	; mul a[2]*b[1]
	mul	edx
	add	ebx,eax
	mov	eax,DWORD [4+esi]
	adc	ecx,edx
	mov	edx,DWORD [8+edi]
	adc	ebp,0
	; mul a[1]*b[2]
	mul	edx
	add	ebx,eax
	mov	eax,DWORD [esi]
	adc	ecx,edx
	mov	edx,DWORD [12+edi]
	adc	ebp,0
	; mul a[0]*b[3]
	mul	edx
	add	ebx,eax
	mov	eax,DWORD [20+esp]
	adc	ecx,edx
	mov	edx,DWORD [4+edi]
	adc	ebp,0
	mov	DWORD [12+eax],ebx
	mov	eax,DWORD [12+esi]
	; saved r[3]
	; ################## Calculate word 4
	xor	ebx,ebx
	; mul a[3]*b[1]
	mul	edx
	add	ecx,eax
	mov	eax,DWORD [8+esi]
	adc	ebp,edx
	mov	edx,DWORD [8+edi]
	adc	ebx,0
	; mul a[2]*b[2]
	mul	edx
	add	ecx,eax
	mov	eax,DWORD [4+esi]
	adc	ebp,edx
	mov	edx,DWORD [12+edi]
	adc	ebx,0
	; mul a[1]*b[3]
	mul	edx
	add	ecx,eax
	mov	eax,DWORD [20+esp]
	adc	ebp,edx
	mov	edx,DWORD [8+edi]
	adc	ebx,0
	mov	DWORD [16+eax],ecx
	mov	eax,DWORD [12+esi]
	; saved r[4]
	; ################## Calculate word 5
	xor	ecx,ecx
	; mul a[3]*b[2]
	mul	edx
	add	ebp,eax
	mov	eax,DWORD [8+esi]
	adc	ebx,edx
	mov	edx,DWORD [12+edi]
	adc	ecx,0
	; mul a[2]*b[3]
	mul	edx
	add	ebp,eax
	mov	eax,DWORD [20+esp]
	adc	ebx,edx
	mov	edx,DWORD [12+edi]
	adc	ecx,0
	mov	DWORD [20+eax],ebp
	mov	eax,DWORD [12+esi]
	; saved r[5]
	; ################## Calculate word 6
	xor	ebp,ebp
	; mul a[3]*b[3]
	mul	edx
	add	ebx,eax
	mov	eax,DWORD [20+esp]
	adc	ecx,edx
	adc	ebp,0
	mov	DWORD [24+eax],ebx
	; saved r[6]
	; save r[7]
	mov	DWORD [28+eax],ecx
	pop	ebx
	pop	ebp
	pop	edi
	pop	esi
	ret
global	_bn_sqr_comba8
align	16
_bn_sqr_comba8:
L$_bn_sqr_comba8_begin:
	push	esi
	push	edi
	push	ebp
	push	ebx
	mov	edi,DWORD [20+esp]
	mov	esi,DWORD [24+esp]
	xor	ebx,ebx
	xor	ecx,ecx
	mov	eax,DWORD [esi]
	; ############### Calculate word 0
	xor	ebp,ebp
	; sqr a[0]*a[0]
	mul	eax
	add	ebx,eax
	adc	ecx,edx
	mov	edx,DWORD [esi]
	adc	ebp,0
	mov	DWORD [edi],ebx
	mov	eax,DWORD [4+esi]
	; saved r[0]
	; ############### Calculate word 1
	xor	ebx,ebx
	; sqr a[1]*a[0]
	mul	edx
	add	eax,eax
	adc	edx,edx
	adc	ebx,0
	add	ecx,eax
	adc	ebp,edx
	mov	eax,DWORD [8+esi]
	adc	ebx,0
	mov	DWORD [4+edi],ecx
	mov	edx,DWORD [esi]
	; saved r[1]
	; ############### Calculate word 2
	xor	ecx,ecx
	; sqr a[2]*a[0]
	mul	edx
	add	eax,eax
	adc	edx,edx
	adc	ecx,0
	add	ebp,eax
	adc	ebx,edx
	mov	eax,DWORD [4+esi]
	adc	ecx,0
	; sqr a[1]*a[1]
	mul	eax
	add	ebp,eax
	adc	ebx,edx
	mov	edx,DWORD [esi]
	adc	ecx,0
	mov	DWORD [8+edi],ebp
	mov	eax,DWORD [12+esi]
	; saved r[2]
	; ############### Calculate word 3
	xor	ebp,ebp
	; sqr a[3]*a[0]
	mul	edx
	add	eax,eax
	adc	edx,edx
	adc	ebp,0
	add	ebx,eax
	adc	ecx,edx
	mov	eax,DWORD [8+esi]
	adc	ebp,0
	mov	edx,DWORD [4+esi]
	; sqr a[2]*a[1]
	mul	edx
	add	eax,eax
	adc	edx,edx
	adc	ebp,0
	add	ebx,eax
	adc	ecx,edx
	mov	eax,DWORD [16+esi]
	adc	ebp,0
	mov	DWORD [12+edi],ebx
	mov	edx,DWORD [esi]
	; saved r[3]
	; ############### Calculate word 4
	xor	ebx,ebx
	; sqr a[4]*a[0]
	mul	edx
	add	eax,eax
	adc	edx,edx
	adc	ebx,0
	add	ecx,eax
	adc	ebp,edx
	mov	eax,DWORD [12+esi]
	adc	ebx,0
	mov	edx,DWORD [4+esi]
	; sqr a[3]*a[1]
	mul	edx
	add	eax,eax
	adc	edx,edx
	adc	ebx,0
	add	ecx,eax
	adc	ebp,edx
	mov	eax,DWORD [8+esi]
	adc	ebx,0
	; sqr a[2]*a[2]
	mul	eax
	add	ecx,eax
	adc	ebp,edx
	mov	edx,DWORD [esi]
	adc	ebx,0
	mov	DWORD [16+edi],ecx
	mov	eax,DWORD [20+esi]
	; saved r[4]
	; ############### Calculate word 5
	xor	ecx,ecx
	; sqr a[5]*a[0]
	mul	edx
	add	eax,eax
	adc	edx,edx
	adc	ecx,0
	add	ebp,eax
	adc	ebx,edx
	mov	eax,DWORD [16+esi]
	adc	ecx,0
	mov	edx,DWORD [4+esi]
	; sqr a[4]*a[1]
	mul	edx
	add	eax,eax
	adc	edx,edx
	adc	ecx,0
	add	ebp,eax
	adc	ebx,edx
	mov	eax,DWORD [12+esi]
	adc	ecx,0
	mov	edx,DWORD [8+esi]
	; sqr a[3]*a[2]
	mul	edx
	add	eax,eax
	adc	edx,edx
	adc	ecx,0
	add	ebp,eax
	adc	ebx,edx
	mov	eax,DWORD [24+esi]
	adc	ecx,0
	mov	DWORD [20+edi],ebp
	mov	edx,DWORD [esi]
	; saved r[5]
	; ############### Calculate word 6
	xor	ebp,ebp
	; sqr a[6]*a[0]
	mul	edx
	add	eax,eax
	adc	edx,edx
	adc	ebp,0
	add	ebx,eax
	adc	ecx,edx
	mov	eax,DWORD [20+esi]
	adc	ebp,0
	mov	edx,DWORD [4+esi]
	; sqr a[5]*a[1]
	mul	edx
	add	eax,eax
	adc	edx,edx
	adc	ebp,0
	add	ebx,eax
	adc	ecx,edx
	mov	eax,DWORD [16+esi]
	adc	ebp,0
	mov	edx,DWORD [8+esi]
	; sqr a[4]*a[2]
	mul	edx
	add	eax,eax
	adc	edx,edx
	adc	ebp,0
	add	ebx,eax
	adc	ecx,edx
	mov	eax,DWORD [12+esi]
	adc	ebp,0
	; sqr a[3]*a[3]
	mul	eax
	add	ebx,eax
	adc	ecx,edx
	mov	edx,DWORD [esi]
	adc	ebp,0
	mov	DWORD [24+edi],ebx
	mov	eax,DWORD [28+esi]
	; saved r[6]
	; ############### Calculate word 7
	xor	ebx,ebx
	; sqr a[7]*a[0]
	mul	edx
	add	eax,eax
	adc	edx,edx
	adc	ebx,0
	add	ecx,eax
	adc	ebp,edx
	mov	eax,DWORD [24+esi]
	adc	ebx,0
	mov	edx,DWORD [4+esi]
	; sqr a[6]*a[1]
	mul	edx
	add	eax,eax
	adc	edx,edx
	adc	ebx,0
	add	ecx,eax
	adc	ebp,edx
	mov	eax,DWORD [20+esi]
	adc	ebx,0
	mov	edx,DWORD [8+esi]
	; sqr a[5]*a[2]
	mul	edx
	add	eax,eax
	adc	edx,edx
	adc	ebx,0
	add	ecx,eax
	adc	ebp,edx
	mov	eax,DWORD [16+esi]
	adc	ebx,0
	mov	edx,DWORD [12+esi]
	; sqr a[4]*a[3]
	mul	edx
	add	eax,eax
	adc	edx,edx
	adc	ebx,0
	add	ecx,eax
	adc	ebp,edx
	mov	eax,DWORD [28+esi]
	adc	ebx,0
	mov	DWORD [28+edi],ecx
	mov	edx,DWORD [4+esi]
	; saved r[7]
	; ############### Calculate word 8
	xor	ecx,ecx
	; sqr a[7]*a[1]
	mul	edx
	add	eax,eax
	adc	edx,edx
	adc	ecx,0
	add	ebp,eax
	adc	ebx,edx
	mov	eax,DWORD [24+esi]
	adc	ecx,0
	mov	edx,DWORD [8+esi]
	; sqr a[6]*a[2]
	mul	edx
	add	eax,eax
	adc	edx,edx
	adc	ecx,0
	add	ebp,eax
	adc	ebx,edx
	mov	eax,DWORD [20+esi]
	adc	ecx,0
	mov	edx,DWORD [12+esi]
	; sqr a[5]*a[3]
	mul	edx
	add	eax,eax
	adc	edx,edx
	adc	ecx,0
	add	ebp,eax
	adc	ebx,edx
	mov	eax,DWORD [16+esi]
	adc	ecx,0
	; sqr a[4]*a[4]
	mul	eax
	add	ebp,eax
	adc	ebx,edx
	mov	edx,DWORD [8+esi]
	adc	ecx,0
	mov	DWORD [32+edi],ebp
	mov	eax,DWORD [28+esi]
	; saved r[8]
	; ############### Calculate word 9
	xor	ebp,ebp
	; sqr a[7]*a[2]
	mul	edx
	add	eax,eax
	adc	edx,edx
	adc	ebp,0
	add	ebx,eax
	adc	ecx,edx
	mov	eax,DWORD [24+esi]
	adc	ebp,0
	mov	edx,DWORD [12+esi]
	; sqr a[6]*a[3]
	mul	edx
	add	eax,eax
	adc	edx,edx
	adc	ebp,0
	add	ebx,eax
	adc	ecx,edx
	mov	eax,DWORD [20+esi]
	adc	ebp,0
	mov	edx,DWORD [16+esi]
	; sqr a[5]*a[4]
	mul	edx
	add	eax,eax
	adc	edx,edx
	adc	ebp,0
	add	ebx,eax
	adc	ecx,edx
	mov	eax,DWORD [28+esi]
	adc	ebp,0
	mov	DWORD [36+edi],ebx
	mov	edx,DWORD [12+esi]
	; saved r[9]
	; ############### Calculate word 10
	xor	ebx,ebx
	; sqr a[7]*a[3]
	mul	edx
	add	eax,eax
	adc	edx,edx
	adc	ebx,0
	add	ecx,eax
	adc	ebp,edx
	mov	eax,DWORD [24+esi]
	adc	ebx,0
	mov	edx,DWORD [16+esi]
	; sqr a[6]*a[4]
	mul	edx
	add	eax,eax
	adc	edx,edx
	adc	ebx,0
	add	ecx,eax
	adc	ebp,edx
	mov	eax,DWORD [20+esi]
	adc	ebx,0
	; sqr a[5]*a[5]
	mul	eax
	add	ecx,eax
	adc	ebp,edx
	mov	edx,DWORD [16+esi]
	adc	ebx,0
	mov	DWORD [40+edi],ecx
	mov	eax,DWORD [28+esi]
	; saved r[10]
	; ############### Calculate word 11
	xor	ecx,ecx
	; sqr a[7]*a[4]
	mul	edx
	add	eax,eax
	adc	edx,edx
	adc	ecx,0
	add	ebp,eax
	adc	ebx,edx
	mov	eax,DWORD [24+esi]
	adc	ecx,0
	mov	edx,DWORD [20+esi]
	; sqr a[6]*a[5]
	mul	edx
	add	eax,eax
	adc	edx,edx
	adc	ecx,0
	add	ebp,eax
	adc	ebx,edx
	mov	eax,DWORD [28+esi]
	adc	ecx,0
	mov	DWORD [44+edi],ebp
	mov	edx,DWORD [20+esi]
	; saved r[11]
	; ############### Calculate word 12
	xor	ebp,ebp
	; sqr a[7]*a[5]
	mul	edx
	add	eax,eax
	adc	edx,edx
	adc	ebp,0
	add	ebx,eax
	adc	ecx,edx
	mov	eax,DWORD [24+esi]
	adc	ebp,0
	; sqr a[6]*a[6]
	mul	eax
	add	ebx,eax
	adc	ecx,edx
	mov	edx,DWORD [24+esi]
	adc	ebp,0
	mov	DWORD [48+edi],ebx
	mov	eax,DWORD [28+esi]
	; saved r[12]
	; ############### Calculate word 13
	xor	ebx,ebx
	; sqr a[7]*a[6]
	mul	edx
	add	eax,eax
	adc	edx,edx
	adc	ebx,0
	add	ecx,eax
	adc	ebp,edx
	mov	eax,DWORD [28+esi]
	adc	ebx,0
	mov	DWORD [52+edi],ecx
	; saved r[13]
	; ############### Calculate word 14
	xor	ecx,ecx
	; sqr a[7]*a[7]
	mul	eax
	add	ebp,eax
	adc	ebx,edx
	adc	ecx,0
	mov	DWORD [56+edi],ebp
	; saved r[14]
	mov	DWORD [60+edi],ebx
	pop	ebx
	pop	ebp
	pop	edi
	pop	esi
	ret
global	_bn_sqr_comba4
align	16
_bn_sqr_comba4:
L$_bn_sqr_comba4_begin:
	push	esi
	push	edi
	push	ebp
	push	ebx
	mov	edi,DWORD [20+esp]
	mov	esi,DWORD [24+esp]
	xor	ebx,ebx
	xor	ecx,ecx
	mov	eax,DWORD [esi]
	; ############### Calculate word 0
	xor	ebp,ebp
	; sqr a[0]*a[0]
	mul	eax
	add	ebx,eax
	adc	ecx,edx
	mov	edx,DWORD [esi]
	adc	ebp,0
	mov	DWORD [edi],ebx
	mov	eax,DWORD [4+esi]
	; saved r[0]
	; ############### Calculate word 1
	xor	ebx,ebx
	; sqr a[1]*a[0]
	mul	edx
	add	eax,eax
	adc	edx,edx
	adc	ebx,0
	add	ecx,eax
	adc	ebp,edx
	mov	eax,DWORD [8+esi]
	adc	ebx,0
	mov	DWORD [4+edi],ecx
	mov	edx,DWORD [esi]
	; saved r[1]
	; ############### Calculate word 2
	xor	ecx,ecx
	; sqr a[2]*a[0]
	mul	edx
	add	eax,eax
	adc	edx,edx
	adc	ecx,0
	add	ebp,eax
	adc	ebx,edx
	mov	eax,DWORD [4+esi]
	adc	ecx,0
	; sqr a[1]*a[1]
	mul	eax
	add	ebp,eax
	adc	ebx,edx
	mov	edx,DWORD [esi]
	adc	ecx,0
	mov	DWORD [8+edi],ebp
	mov	eax,DWORD [12+esi]
	; saved r[2]
	; ############### Calculate word 3
	xor	ebp,ebp
	; sqr a[3]*a[0]
	mul	edx
	add	eax,eax
	adc	edx,edx
	adc	ebp,0
	add	ebx,eax
	adc	ecx,edx
	mov	eax,DWORD [8+esi]
	adc	ebp,0
	mov	edx,DWORD [4+esi]
	; sqr a[2]*a[1]
	mul	edx
	add	eax,eax
	adc	edx,edx
	adc	ebp,0
	add	ebx,eax
	adc	ecx,edx
	mov	eax,DWORD [12+esi]
	adc	ebp,0
	mov	DWORD [12+edi],ebx
	mov	edx,DWORD [4+esi]
	; saved r[3]
	; ############### Calculate word 4
	xor	ebx,ebx
	; sqr a[3]*a[1]
	mul	edx
	add	eax,eax
	adc	edx,edx
	adc	ebx,0
	add	ecx,eax
	adc	ebp,edx
	mov	eax,DWORD [8+esi]
	adc	ebx,0
	; sqr a[2]*a[2]
	mul	eax
	add	ecx,eax
	adc	ebp,edx
	mov	edx,DWORD [8+esi]
	adc	ebx,0
	mov	DWORD [16+edi],ecx
	mov	eax,DWORD [12+esi]
	; saved r[4]
	; ############### Calculate word 5
	xor	ecx,ecx
	; sqr a[3]*a[2]
	mul	edx
	add	eax,eax
	adc	edx,edx
	adc	ecx,0
	add	ebp,eax
	adc	ebx,edx
	mov	eax,DWORD [12+esi]
	adc	ecx,0
	mov	DWORD [20+edi],ebp
	; saved r[5]
	; ############### Calculate word 6
	xor	ebp,ebp
	; sqr a[3]*a[3]
	mul	eax
	add	ebx,eax
	adc	ecx,edx
	adc	ebp,0
	mov	DWORD [24+edi],ebx
	; saved r[6]
	mov	DWORD [28+edi],ecx
	pop	ebx
	pop	ebp
	pop	edi
	pop	esi
	ret
