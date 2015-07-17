default	rel
%define XMMWORD
%define YMMWORD
%define ZMMWORD
section	.text code align=64

EXTERN	OPENSSL_ia32cap_P
global	aesni_encrypt

ALIGN	16
aesni_encrypt:
	movups	xmm2,XMMWORD[rcx]
	mov	eax,DWORD[240+r8]
	movups	xmm0,XMMWORD[r8]
	movups	xmm1,XMMWORD[16+r8]
	lea	r8,[32+r8]
	xorps	xmm2,xmm0
$L$oop_enc1_1:
DB	102,15,56,220,209
	dec	eax
	movups	xmm1,XMMWORD[r8]
	lea	r8,[16+r8]
	jnz	NEAR $L$oop_enc1_1
DB	102,15,56,221,209
	pxor	xmm0,xmm0
	pxor	xmm1,xmm1
	movups	XMMWORD[rdx],xmm2
	pxor	xmm2,xmm2
	DB	0F3h,0C3h		;repret


global	aesni_decrypt

ALIGN	16
aesni_decrypt:
	movups	xmm2,XMMWORD[rcx]
	mov	eax,DWORD[240+r8]
	movups	xmm0,XMMWORD[r8]
	movups	xmm1,XMMWORD[16+r8]
	lea	r8,[32+r8]
	xorps	xmm2,xmm0
$L$oop_dec1_2:
DB	102,15,56,222,209
	dec	eax
	movups	xmm1,XMMWORD[r8]
	lea	r8,[16+r8]
	jnz	NEAR $L$oop_dec1_2
DB	102,15,56,223,209
	pxor	xmm0,xmm0
	pxor	xmm1,xmm1
	movups	XMMWORD[rdx],xmm2
	pxor	xmm2,xmm2
	DB	0F3h,0C3h		;repret


ALIGN	16
_aesni_encrypt2:
	movups	xmm0,XMMWORD[rcx]
	shl	eax,4
	movups	xmm1,XMMWORD[16+rcx]
	xorps	xmm2,xmm0
	xorps	xmm3,xmm0
	movups	xmm0,XMMWORD[32+rcx]
	lea	rcx,[32+rax*1+rcx]
	neg	rax
	add	rax,16

$L$enc_loop2:
DB	102,15,56,220,209
DB	102,15,56,220,217
	movups	xmm1,XMMWORD[rax*1+rcx]
	add	rax,32
DB	102,15,56,220,208
DB	102,15,56,220,216
	movups	xmm0,XMMWORD[((-16))+rax*1+rcx]
	jnz	NEAR $L$enc_loop2

DB	102,15,56,220,209
DB	102,15,56,220,217
DB	102,15,56,221,208
DB	102,15,56,221,216
	DB	0F3h,0C3h		;repret


ALIGN	16
_aesni_decrypt2:
	movups	xmm0,XMMWORD[rcx]
	shl	eax,4
	movups	xmm1,XMMWORD[16+rcx]
	xorps	xmm2,xmm0
	xorps	xmm3,xmm0
	movups	xmm0,XMMWORD[32+rcx]
	lea	rcx,[32+rax*1+rcx]
	neg	rax
	add	rax,16

$L$dec_loop2:
DB	102,15,56,222,209
DB	102,15,56,222,217
	movups	xmm1,XMMWORD[rax*1+rcx]
	add	rax,32
DB	102,15,56,222,208
DB	102,15,56,222,216
	movups	xmm0,XMMWORD[((-16))+rax*1+rcx]
	jnz	NEAR $L$dec_loop2

DB	102,15,56,222,209
DB	102,15,56,222,217
DB	102,15,56,223,208
DB	102,15,56,223,216
	DB	0F3h,0C3h		;repret


ALIGN	16
_aesni_encrypt3:
	movups	xmm0,XMMWORD[rcx]
	shl	eax,4
	movups	xmm1,XMMWORD[16+rcx]
	xorps	xmm2,xmm0
	xorps	xmm3,xmm0
	xorps	xmm4,xmm0
	movups	xmm0,XMMWORD[32+rcx]
	lea	rcx,[32+rax*1+rcx]
	neg	rax
	add	rax,16

$L$enc_loop3:
DB	102,15,56,220,209
DB	102,15,56,220,217
DB	102,15,56,220,225
	movups	xmm1,XMMWORD[rax*1+rcx]
	add	rax,32
DB	102,15,56,220,208
DB	102,15,56,220,216
DB	102,15,56,220,224
	movups	xmm0,XMMWORD[((-16))+rax*1+rcx]
	jnz	NEAR $L$enc_loop3

DB	102,15,56,220,209
DB	102,15,56,220,217
DB	102,15,56,220,225
DB	102,15,56,221,208
DB	102,15,56,221,216
DB	102,15,56,221,224
	DB	0F3h,0C3h		;repret


ALIGN	16
_aesni_decrypt3:
	movups	xmm0,XMMWORD[rcx]
	shl	eax,4
	movups	xmm1,XMMWORD[16+rcx]
	xorps	xmm2,xmm0
	xorps	xmm3,xmm0
	xorps	xmm4,xmm0
	movups	xmm0,XMMWORD[32+rcx]
	lea	rcx,[32+rax*1+rcx]
	neg	rax
	add	rax,16

$L$dec_loop3:
DB	102,15,56,222,209
DB	102,15,56,222,217
DB	102,15,56,222,225
	movups	xmm1,XMMWORD[rax*1+rcx]
	add	rax,32
DB	102,15,56,222,208
DB	102,15,56,222,216
DB	102,15,56,222,224
	movups	xmm0,XMMWORD[((-16))+rax*1+rcx]
	jnz	NEAR $L$dec_loop3

DB	102,15,56,222,209
DB	102,15,56,222,217
DB	102,15,56,222,225
DB	102,15,56,223,208
DB	102,15,56,223,216
DB	102,15,56,223,224
	DB	0F3h,0C3h		;repret


ALIGN	16
_aesni_encrypt4:
	movups	xmm0,XMMWORD[rcx]
	shl	eax,4
	movups	xmm1,XMMWORD[16+rcx]
	xorps	xmm2,xmm0
	xorps	xmm3,xmm0
	xorps	xmm4,xmm0
	xorps	xmm5,xmm0
	movups	xmm0,XMMWORD[32+rcx]
	lea	rcx,[32+rax*1+rcx]
	neg	rax
DB	0x0f,0x1f,0x00
	add	rax,16

$L$enc_loop4:
DB	102,15,56,220,209
DB	102,15,56,220,217
DB	102,15,56,220,225
DB	102,15,56,220,233
	movups	xmm1,XMMWORD[rax*1+rcx]
	add	rax,32
DB	102,15,56,220,208
DB	102,15,56,220,216
DB	102,15,56,220,224
DB	102,15,56,220,232
	movups	xmm0,XMMWORD[((-16))+rax*1+rcx]
	jnz	NEAR $L$enc_loop4

DB	102,15,56,220,209
DB	102,15,56,220,217
DB	102,15,56,220,225
DB	102,15,56,220,233
DB	102,15,56,221,208
DB	102,15,56,221,216
DB	102,15,56,221,224
DB	102,15,56,221,232
	DB	0F3h,0C3h		;repret


ALIGN	16
_aesni_decrypt4:
	movups	xmm0,XMMWORD[rcx]
	shl	eax,4
	movups	xmm1,XMMWORD[16+rcx]
	xorps	xmm2,xmm0
	xorps	xmm3,xmm0
	xorps	xmm4,xmm0
	xorps	xmm5,xmm0
	movups	xmm0,XMMWORD[32+rcx]
	lea	rcx,[32+rax*1+rcx]
	neg	rax
DB	0x0f,0x1f,0x00
	add	rax,16

$L$dec_loop4:
DB	102,15,56,222,209
DB	102,15,56,222,217
DB	102,15,56,222,225
DB	102,15,56,222,233
	movups	xmm1,XMMWORD[rax*1+rcx]
	add	rax,32
DB	102,15,56,222,208
DB	102,15,56,222,216
DB	102,15,56,222,224
DB	102,15,56,222,232
	movups	xmm0,XMMWORD[((-16))+rax*1+rcx]
	jnz	NEAR $L$dec_loop4

DB	102,15,56,222,209
DB	102,15,56,222,217
DB	102,15,56,222,225
DB	102,15,56,222,233
DB	102,15,56,223,208
DB	102,15,56,223,216
DB	102,15,56,223,224
DB	102,15,56,223,232
	DB	0F3h,0C3h		;repret


ALIGN	16
_aesni_encrypt6:
	movups	xmm0,XMMWORD[rcx]
	shl	eax,4
	movups	xmm1,XMMWORD[16+rcx]
	xorps	xmm2,xmm0
	pxor	xmm3,xmm0
	pxor	xmm4,xmm0
DB	102,15,56,220,209
	lea	rcx,[32+rax*1+rcx]
	neg	rax
DB	102,15,56,220,217
	pxor	xmm5,xmm0
	pxor	xmm6,xmm0
DB	102,15,56,220,225
	pxor	xmm7,xmm0
	movups	xmm0,XMMWORD[rax*1+rcx]
	add	rax,16
	jmp	NEAR $L$enc_loop6_enter
ALIGN	16
$L$enc_loop6:
DB	102,15,56,220,209
DB	102,15,56,220,217
DB	102,15,56,220,225
$L$enc_loop6_enter:
DB	102,15,56,220,233
DB	102,15,56,220,241
DB	102,15,56,220,249
	movups	xmm1,XMMWORD[rax*1+rcx]
	add	rax,32
DB	102,15,56,220,208
DB	102,15,56,220,216
DB	102,15,56,220,224
DB	102,15,56,220,232
DB	102,15,56,220,240
DB	102,15,56,220,248
	movups	xmm0,XMMWORD[((-16))+rax*1+rcx]
	jnz	NEAR $L$enc_loop6

DB	102,15,56,220,209
DB	102,15,56,220,217
DB	102,15,56,220,225
DB	102,15,56,220,233
DB	102,15,56,220,241
DB	102,15,56,220,249
DB	102,15,56,221,208
DB	102,15,56,221,216
DB	102,15,56,221,224
DB	102,15,56,221,232
DB	102,15,56,221,240
DB	102,15,56,221,248
	DB	0F3h,0C3h		;repret


ALIGN	16
_aesni_decrypt6:
	movups	xmm0,XMMWORD[rcx]
	shl	eax,4
	movups	xmm1,XMMWORD[16+rcx]
	xorps	xmm2,xmm0
	pxor	xmm3,xmm0
	pxor	xmm4,xmm0
DB	102,15,56,222,209
	lea	rcx,[32+rax*1+rcx]
	neg	rax
DB	102,15,56,222,217
	pxor	xmm5,xmm0
	pxor	xmm6,xmm0
DB	102,15,56,222,225
	pxor	xmm7,xmm0
	movups	xmm0,XMMWORD[rax*1+rcx]
	add	rax,16
	jmp	NEAR $L$dec_loop6_enter
ALIGN	16
$L$dec_loop6:
DB	102,15,56,222,209
DB	102,15,56,222,217
DB	102,15,56,222,225
$L$dec_loop6_enter:
DB	102,15,56,222,233
DB	102,15,56,222,241
DB	102,15,56,222,249
	movups	xmm1,XMMWORD[rax*1+rcx]
	add	rax,32
DB	102,15,56,222,208
DB	102,15,56,222,216
DB	102,15,56,222,224
DB	102,15,56,222,232
DB	102,15,56,222,240
DB	102,15,56,222,248
	movups	xmm0,XMMWORD[((-16))+rax*1+rcx]
	jnz	NEAR $L$dec_loop6

DB	102,15,56,222,209
DB	102,15,56,222,217
DB	102,15,56,222,225
DB	102,15,56,222,233
DB	102,15,56,222,241
DB	102,15,56,222,249
DB	102,15,56,223,208
DB	102,15,56,223,216
DB	102,15,56,223,224
DB	102,15,56,223,232
DB	102,15,56,223,240
DB	102,15,56,223,248
	DB	0F3h,0C3h		;repret


ALIGN	16
_aesni_encrypt8:
	movups	xmm0,XMMWORD[rcx]
	shl	eax,4
	movups	xmm1,XMMWORD[16+rcx]
	xorps	xmm2,xmm0
	xorps	xmm3,xmm0
	pxor	xmm4,xmm0
	pxor	xmm5,xmm0
	pxor	xmm6,xmm0
	lea	rcx,[32+rax*1+rcx]
	neg	rax
DB	102,15,56,220,209
	pxor	xmm7,xmm0
	pxor	xmm8,xmm0
DB	102,15,56,220,217
	pxor	xmm9,xmm0
	movups	xmm0,XMMWORD[rax*1+rcx]
	add	rax,16
	jmp	NEAR $L$enc_loop8_inner
ALIGN	16
$L$enc_loop8:
DB	102,15,56,220,209
DB	102,15,56,220,217
$L$enc_loop8_inner:
DB	102,15,56,220,225
DB	102,15,56,220,233
DB	102,15,56,220,241
DB	102,15,56,220,249
DB	102,68,15,56,220,193
DB	102,68,15,56,220,201
$L$enc_loop8_enter:
	movups	xmm1,XMMWORD[rax*1+rcx]
	add	rax,32
DB	102,15,56,220,208
DB	102,15,56,220,216
DB	102,15,56,220,224
DB	102,15,56,220,232
DB	102,15,56,220,240
DB	102,15,56,220,248
DB	102,68,15,56,220,192
DB	102,68,15,56,220,200
	movups	xmm0,XMMWORD[((-16))+rax*1+rcx]
	jnz	NEAR $L$enc_loop8

DB	102,15,56,220,209
DB	102,15,56,220,217
DB	102,15,56,220,225
DB	102,15,56,220,233
DB	102,15,56,220,241
DB	102,15,56,220,249
DB	102,68,15,56,220,193
DB	102,68,15,56,220,201
DB	102,15,56,221,208
DB	102,15,56,221,216
DB	102,15,56,221,224
DB	102,15,56,221,232
DB	102,15,56,221,240
DB	102,15,56,221,248
DB	102,68,15,56,221,192
DB	102,68,15,56,221,200
	DB	0F3h,0C3h		;repret


ALIGN	16
_aesni_decrypt8:
	movups	xmm0,XMMWORD[rcx]
	shl	eax,4
	movups	xmm1,XMMWORD[16+rcx]
	xorps	xmm2,xmm0
	xorps	xmm3,xmm0
	pxor	xmm4,xmm0
	pxor	xmm5,xmm0
	pxor	xmm6,xmm0
	lea	rcx,[32+rax*1+rcx]
	neg	rax
DB	102,15,56,222,209
	pxor	xmm7,xmm0
	pxor	xmm8,xmm0
DB	102,15,56,222,217
	pxor	xmm9,xmm0
	movups	xmm0,XMMWORD[rax*1+rcx]
	add	rax,16
	jmp	NEAR $L$dec_loop8_inner
ALIGN	16
$L$dec_loop8:
DB	102,15,56,222,209
DB	102,15,56,222,217
$L$dec_loop8_inner:
DB	102,15,56,222,225
DB	102,15,56,222,233
DB	102,15,56,222,241
DB	102,15,56,222,249
DB	102,68,15,56,222,193
DB	102,68,15,56,222,201
$L$dec_loop8_enter:
	movups	xmm1,XMMWORD[rax*1+rcx]
	add	rax,32
DB	102,15,56,222,208
DB	102,15,56,222,216
DB	102,15,56,222,224
DB	102,15,56,222,232
DB	102,15,56,222,240
DB	102,15,56,222,248
DB	102,68,15,56,222,192
DB	102,68,15,56,222,200
	movups	xmm0,XMMWORD[((-16))+rax*1+rcx]
	jnz	NEAR $L$dec_loop8

DB	102,15,56,222,209
DB	102,15,56,222,217
DB	102,15,56,222,225
DB	102,15,56,222,233
DB	102,15,56,222,241
DB	102,15,56,222,249
DB	102,68,15,56,222,193
DB	102,68,15,56,222,201
DB	102,15,56,223,208
DB	102,15,56,223,216
DB	102,15,56,223,224
DB	102,15,56,223,232
DB	102,15,56,223,240
DB	102,15,56,223,248
DB	102,68,15,56,223,192
DB	102,68,15,56,223,200
	DB	0F3h,0C3h		;repret

global	aesni_ecb_encrypt

ALIGN	16
aesni_ecb_encrypt:
	mov	QWORD[8+rsp],rdi	;WIN64 prologue
	mov	QWORD[16+rsp],rsi
	mov	rax,rsp
$L$SEH_begin_aesni_ecb_encrypt:
	mov	rdi,rcx
	mov	rsi,rdx
	mov	rdx,r8
	mov	rcx,r9
	mov	r8,QWORD[40+rsp]


	lea	rsp,[((-88))+rsp]
	movaps	XMMWORD[rsp],xmm6
	movaps	XMMWORD[16+rsp],xmm7
	movaps	XMMWORD[32+rsp],xmm8
	movaps	XMMWORD[48+rsp],xmm9
$L$ecb_enc_body:
	and	rdx,-16
	jz	NEAR $L$ecb_ret

	mov	eax,DWORD[240+rcx]
	movups	xmm0,XMMWORD[rcx]
	mov	r11,rcx
	mov	r10d,eax
	test	r8d,r8d
	jz	NEAR $L$ecb_decrypt

	cmp	rdx,0x80
	jb	NEAR $L$ecb_enc_tail

	movdqu	xmm2,XMMWORD[rdi]
	movdqu	xmm3,XMMWORD[16+rdi]
	movdqu	xmm4,XMMWORD[32+rdi]
	movdqu	xmm5,XMMWORD[48+rdi]
	movdqu	xmm6,XMMWORD[64+rdi]
	movdqu	xmm7,XMMWORD[80+rdi]
	movdqu	xmm8,XMMWORD[96+rdi]
	movdqu	xmm9,XMMWORD[112+rdi]
	lea	rdi,[128+rdi]
	sub	rdx,0x80
	jmp	NEAR $L$ecb_enc_loop8_enter
ALIGN	16
$L$ecb_enc_loop8:
	movups	XMMWORD[rsi],xmm2
	mov	rcx,r11
	movdqu	xmm2,XMMWORD[rdi]
	mov	eax,r10d
	movups	XMMWORD[16+rsi],xmm3
	movdqu	xmm3,XMMWORD[16+rdi]
	movups	XMMWORD[32+rsi],xmm4
	movdqu	xmm4,XMMWORD[32+rdi]
	movups	XMMWORD[48+rsi],xmm5
	movdqu	xmm5,XMMWORD[48+rdi]
	movups	XMMWORD[64+rsi],xmm6
	movdqu	xmm6,XMMWORD[64+rdi]
	movups	XMMWORD[80+rsi],xmm7
	movdqu	xmm7,XMMWORD[80+rdi]
	movups	XMMWORD[96+rsi],xmm8
	movdqu	xmm8,XMMWORD[96+rdi]
	movups	XMMWORD[112+rsi],xmm9
	lea	rsi,[128+rsi]
	movdqu	xmm9,XMMWORD[112+rdi]
	lea	rdi,[128+rdi]
$L$ecb_enc_loop8_enter:

	call	_aesni_encrypt8

	sub	rdx,0x80
	jnc	NEAR $L$ecb_enc_loop8

	movups	XMMWORD[rsi],xmm2
	mov	rcx,r11
	movups	XMMWORD[16+rsi],xmm3
	mov	eax,r10d
	movups	XMMWORD[32+rsi],xmm4
	movups	XMMWORD[48+rsi],xmm5
	movups	XMMWORD[64+rsi],xmm6
	movups	XMMWORD[80+rsi],xmm7
	movups	XMMWORD[96+rsi],xmm8
	movups	XMMWORD[112+rsi],xmm9
	lea	rsi,[128+rsi]
	add	rdx,0x80
	jz	NEAR $L$ecb_ret

$L$ecb_enc_tail:
	movups	xmm2,XMMWORD[rdi]
	cmp	rdx,0x20
	jb	NEAR $L$ecb_enc_one
	movups	xmm3,XMMWORD[16+rdi]
	je	NEAR $L$ecb_enc_two
	movups	xmm4,XMMWORD[32+rdi]
	cmp	rdx,0x40
	jb	NEAR $L$ecb_enc_three
	movups	xmm5,XMMWORD[48+rdi]
	je	NEAR $L$ecb_enc_four
	movups	xmm6,XMMWORD[64+rdi]
	cmp	rdx,0x60
	jb	NEAR $L$ecb_enc_five
	movups	xmm7,XMMWORD[80+rdi]
	je	NEAR $L$ecb_enc_six
	movdqu	xmm8,XMMWORD[96+rdi]
	xorps	xmm9,xmm9
	call	_aesni_encrypt8
	movups	XMMWORD[rsi],xmm2
	movups	XMMWORD[16+rsi],xmm3
	movups	XMMWORD[32+rsi],xmm4
	movups	XMMWORD[48+rsi],xmm5
	movups	XMMWORD[64+rsi],xmm6
	movups	XMMWORD[80+rsi],xmm7
	movups	XMMWORD[96+rsi],xmm8
	jmp	NEAR $L$ecb_ret
ALIGN	16
$L$ecb_enc_one:
	movups	xmm0,XMMWORD[rcx]
	movups	xmm1,XMMWORD[16+rcx]
	lea	rcx,[32+rcx]
	xorps	xmm2,xmm0
$L$oop_enc1_3:
DB	102,15,56,220,209
	dec	eax
	movups	xmm1,XMMWORD[rcx]
	lea	rcx,[16+rcx]
	jnz	NEAR $L$oop_enc1_3
DB	102,15,56,221,209
	movups	XMMWORD[rsi],xmm2
	jmp	NEAR $L$ecb_ret
ALIGN	16
$L$ecb_enc_two:
	call	_aesni_encrypt2
	movups	XMMWORD[rsi],xmm2
	movups	XMMWORD[16+rsi],xmm3
	jmp	NEAR $L$ecb_ret
ALIGN	16
$L$ecb_enc_three:
	call	_aesni_encrypt3
	movups	XMMWORD[rsi],xmm2
	movups	XMMWORD[16+rsi],xmm3
	movups	XMMWORD[32+rsi],xmm4
	jmp	NEAR $L$ecb_ret
ALIGN	16
$L$ecb_enc_four:
	call	_aesni_encrypt4
	movups	XMMWORD[rsi],xmm2
	movups	XMMWORD[16+rsi],xmm3
	movups	XMMWORD[32+rsi],xmm4
	movups	XMMWORD[48+rsi],xmm5
	jmp	NEAR $L$ecb_ret
ALIGN	16
$L$ecb_enc_five:
	xorps	xmm7,xmm7
	call	_aesni_encrypt6
	movups	XMMWORD[rsi],xmm2
	movups	XMMWORD[16+rsi],xmm3
	movups	XMMWORD[32+rsi],xmm4
	movups	XMMWORD[48+rsi],xmm5
	movups	XMMWORD[64+rsi],xmm6
	jmp	NEAR $L$ecb_ret
ALIGN	16
$L$ecb_enc_six:
	call	_aesni_encrypt6
	movups	XMMWORD[rsi],xmm2
	movups	XMMWORD[16+rsi],xmm3
	movups	XMMWORD[32+rsi],xmm4
	movups	XMMWORD[48+rsi],xmm5
	movups	XMMWORD[64+rsi],xmm6
	movups	XMMWORD[80+rsi],xmm7
	jmp	NEAR $L$ecb_ret

ALIGN	16
$L$ecb_decrypt:
	cmp	rdx,0x80
	jb	NEAR $L$ecb_dec_tail

	movdqu	xmm2,XMMWORD[rdi]
	movdqu	xmm3,XMMWORD[16+rdi]
	movdqu	xmm4,XMMWORD[32+rdi]
	movdqu	xmm5,XMMWORD[48+rdi]
	movdqu	xmm6,XMMWORD[64+rdi]
	movdqu	xmm7,XMMWORD[80+rdi]
	movdqu	xmm8,XMMWORD[96+rdi]
	movdqu	xmm9,XMMWORD[112+rdi]
	lea	rdi,[128+rdi]
	sub	rdx,0x80
	jmp	NEAR $L$ecb_dec_loop8_enter
ALIGN	16
$L$ecb_dec_loop8:
	movups	XMMWORD[rsi],xmm2
	mov	rcx,r11
	movdqu	xmm2,XMMWORD[rdi]
	mov	eax,r10d
	movups	XMMWORD[16+rsi],xmm3
	movdqu	xmm3,XMMWORD[16+rdi]
	movups	XMMWORD[32+rsi],xmm4
	movdqu	xmm4,XMMWORD[32+rdi]
	movups	XMMWORD[48+rsi],xmm5
	movdqu	xmm5,XMMWORD[48+rdi]
	movups	XMMWORD[64+rsi],xmm6
	movdqu	xmm6,XMMWORD[64+rdi]
	movups	XMMWORD[80+rsi],xmm7
	movdqu	xmm7,XMMWORD[80+rdi]
	movups	XMMWORD[96+rsi],xmm8
	movdqu	xmm8,XMMWORD[96+rdi]
	movups	XMMWORD[112+rsi],xmm9
	lea	rsi,[128+rsi]
	movdqu	xmm9,XMMWORD[112+rdi]
	lea	rdi,[128+rdi]
$L$ecb_dec_loop8_enter:

	call	_aesni_decrypt8

	movups	xmm0,XMMWORD[r11]
	sub	rdx,0x80
	jnc	NEAR $L$ecb_dec_loop8

	movups	XMMWORD[rsi],xmm2
	pxor	xmm2,xmm2
	mov	rcx,r11
	movups	XMMWORD[16+rsi],xmm3
	pxor	xmm3,xmm3
	mov	eax,r10d
	movups	XMMWORD[32+rsi],xmm4
	pxor	xmm4,xmm4
	movups	XMMWORD[48+rsi],xmm5
	pxor	xmm5,xmm5
	movups	XMMWORD[64+rsi],xmm6
	pxor	xmm6,xmm6
	movups	XMMWORD[80+rsi],xmm7
	pxor	xmm7,xmm7
	movups	XMMWORD[96+rsi],xmm8
	pxor	xmm8,xmm8
	movups	XMMWORD[112+rsi],xmm9
	pxor	xmm9,xmm9
	lea	rsi,[128+rsi]
	add	rdx,0x80
	jz	NEAR $L$ecb_ret

$L$ecb_dec_tail:
	movups	xmm2,XMMWORD[rdi]
	cmp	rdx,0x20
	jb	NEAR $L$ecb_dec_one
	movups	xmm3,XMMWORD[16+rdi]
	je	NEAR $L$ecb_dec_two
	movups	xmm4,XMMWORD[32+rdi]
	cmp	rdx,0x40
	jb	NEAR $L$ecb_dec_three
	movups	xmm5,XMMWORD[48+rdi]
	je	NEAR $L$ecb_dec_four
	movups	xmm6,XMMWORD[64+rdi]
	cmp	rdx,0x60
	jb	NEAR $L$ecb_dec_five
	movups	xmm7,XMMWORD[80+rdi]
	je	NEAR $L$ecb_dec_six
	movups	xmm8,XMMWORD[96+rdi]
	movups	xmm0,XMMWORD[rcx]
	xorps	xmm9,xmm9
	call	_aesni_decrypt8
	movups	XMMWORD[rsi],xmm2
	pxor	xmm2,xmm2
	movups	XMMWORD[16+rsi],xmm3
	pxor	xmm3,xmm3
	movups	XMMWORD[32+rsi],xmm4
	pxor	xmm4,xmm4
	movups	XMMWORD[48+rsi],xmm5
	pxor	xmm5,xmm5
	movups	XMMWORD[64+rsi],xmm6
	pxor	xmm6,xmm6
	movups	XMMWORD[80+rsi],xmm7
	pxor	xmm7,xmm7
	movups	XMMWORD[96+rsi],xmm8
	pxor	xmm8,xmm8
	pxor	xmm9,xmm9
	jmp	NEAR $L$ecb_ret
ALIGN	16
$L$ecb_dec_one:
	movups	xmm0,XMMWORD[rcx]
	movups	xmm1,XMMWORD[16+rcx]
	lea	rcx,[32+rcx]
	xorps	xmm2,xmm0
$L$oop_dec1_4:
DB	102,15,56,222,209
	dec	eax
	movups	xmm1,XMMWORD[rcx]
	lea	rcx,[16+rcx]
	jnz	NEAR $L$oop_dec1_4
DB	102,15,56,223,209
	movups	XMMWORD[rsi],xmm2
	pxor	xmm2,xmm2
	jmp	NEAR $L$ecb_ret
ALIGN	16
$L$ecb_dec_two:
	call	_aesni_decrypt2
	movups	XMMWORD[rsi],xmm2
	pxor	xmm2,xmm2
	movups	XMMWORD[16+rsi],xmm3
	pxor	xmm3,xmm3
	jmp	NEAR $L$ecb_ret
ALIGN	16
$L$ecb_dec_three:
	call	_aesni_decrypt3
	movups	XMMWORD[rsi],xmm2
	pxor	xmm2,xmm2
	movups	XMMWORD[16+rsi],xmm3
	pxor	xmm3,xmm3
	movups	XMMWORD[32+rsi],xmm4
	pxor	xmm4,xmm4
	jmp	NEAR $L$ecb_ret
ALIGN	16
$L$ecb_dec_four:
	call	_aesni_decrypt4
	movups	XMMWORD[rsi],xmm2
	pxor	xmm2,xmm2
	movups	XMMWORD[16+rsi],xmm3
	pxor	xmm3,xmm3
	movups	XMMWORD[32+rsi],xmm4
	pxor	xmm4,xmm4
	movups	XMMWORD[48+rsi],xmm5
	pxor	xmm5,xmm5
	jmp	NEAR $L$ecb_ret
ALIGN	16
$L$ecb_dec_five:
	xorps	xmm7,xmm7
	call	_aesni_decrypt6
	movups	XMMWORD[rsi],xmm2
	pxor	xmm2,xmm2
	movups	XMMWORD[16+rsi],xmm3
	pxor	xmm3,xmm3
	movups	XMMWORD[32+rsi],xmm4
	pxor	xmm4,xmm4
	movups	XMMWORD[48+rsi],xmm5
	pxor	xmm5,xmm5
	movups	XMMWORD[64+rsi],xmm6
	pxor	xmm6,xmm6
	pxor	xmm7,xmm7
	jmp	NEAR $L$ecb_ret
ALIGN	16
$L$ecb_dec_six:
	call	_aesni_decrypt6
	movups	XMMWORD[rsi],xmm2
	pxor	xmm2,xmm2
	movups	XMMWORD[16+rsi],xmm3
	pxor	xmm3,xmm3
	movups	XMMWORD[32+rsi],xmm4
	pxor	xmm4,xmm4
	movups	XMMWORD[48+rsi],xmm5
	pxor	xmm5,xmm5
	movups	XMMWORD[64+rsi],xmm6
	pxor	xmm6,xmm6
	movups	XMMWORD[80+rsi],xmm7
	pxor	xmm7,xmm7

$L$ecb_ret:
	xorps	xmm0,xmm0
	pxor	xmm1,xmm1
	movaps	xmm6,XMMWORD[rsp]
	movaps	XMMWORD[rsp],xmm0
	movaps	xmm7,XMMWORD[16+rsp]
	movaps	XMMWORD[16+rsp],xmm0
	movaps	xmm8,XMMWORD[32+rsp]
	movaps	XMMWORD[32+rsp],xmm0
	movaps	xmm9,XMMWORD[48+rsp]
	movaps	XMMWORD[48+rsp],xmm0
	lea	rsp,[88+rsp]
$L$ecb_enc_ret:
	mov	rdi,QWORD[8+rsp]	;WIN64 epilogue
	mov	rsi,QWORD[16+rsp]
	DB	0F3h,0C3h		;repret
$L$SEH_end_aesni_ecb_encrypt:
global	aesni_ccm64_encrypt_blocks

ALIGN	16
aesni_ccm64_encrypt_blocks:
	mov	QWORD[8+rsp],rdi	;WIN64 prologue
	mov	QWORD[16+rsp],rsi
	mov	rax,rsp
$L$SEH_begin_aesni_ccm64_encrypt_blocks:
	mov	rdi,rcx
	mov	rsi,rdx
	mov	rdx,r8
	mov	rcx,r9
	mov	r8,QWORD[40+rsp]
	mov	r9,QWORD[48+rsp]


	lea	rsp,[((-88))+rsp]
	movaps	XMMWORD[rsp],xmm6
	movaps	XMMWORD[16+rsp],xmm7
	movaps	XMMWORD[32+rsp],xmm8
	movaps	XMMWORD[48+rsp],xmm9
$L$ccm64_enc_body:
	mov	eax,DWORD[240+rcx]
	movdqu	xmm6,XMMWORD[r8]
	movdqa	xmm9,XMMWORD[$L$increment64]
	movdqa	xmm7,XMMWORD[$L$bswap_mask]

	shl	eax,4
	mov	r10d,16
	lea	r11,[rcx]
	movdqu	xmm3,XMMWORD[r9]
	movdqa	xmm2,xmm6
	lea	rcx,[32+rax*1+rcx]
DB	102,15,56,0,247
	sub	r10,rax
	jmp	NEAR $L$ccm64_enc_outer
ALIGN	16
$L$ccm64_enc_outer:
	movups	xmm0,XMMWORD[r11]
	mov	rax,r10
	movups	xmm8,XMMWORD[rdi]

	xorps	xmm2,xmm0
	movups	xmm1,XMMWORD[16+r11]
	xorps	xmm0,xmm8
	xorps	xmm3,xmm0
	movups	xmm0,XMMWORD[32+r11]

$L$ccm64_enc2_loop:
DB	102,15,56,220,209
DB	102,15,56,220,217
	movups	xmm1,XMMWORD[rax*1+rcx]
	add	rax,32
DB	102,15,56,220,208
DB	102,15,56,220,216
	movups	xmm0,XMMWORD[((-16))+rax*1+rcx]
	jnz	NEAR $L$ccm64_enc2_loop
DB	102,15,56,220,209
DB	102,15,56,220,217
	paddq	xmm6,xmm9
	dec	rdx
DB	102,15,56,221,208
DB	102,15,56,221,216

	lea	rdi,[16+rdi]
	xorps	xmm8,xmm2
	movdqa	xmm2,xmm6
	movups	XMMWORD[rsi],xmm8
DB	102,15,56,0,215
	lea	rsi,[16+rsi]
	jnz	NEAR $L$ccm64_enc_outer

	pxor	xmm0,xmm0
	pxor	xmm1,xmm1
	pxor	xmm2,xmm2
	movups	XMMWORD[r9],xmm3
	pxor	xmm3,xmm3
	pxor	xmm8,xmm8
	pxor	xmm6,xmm6
	movaps	xmm6,XMMWORD[rsp]
	movaps	XMMWORD[rsp],xmm0
	movaps	xmm7,XMMWORD[16+rsp]
	movaps	XMMWORD[16+rsp],xmm0
	movaps	xmm8,XMMWORD[32+rsp]
	movaps	XMMWORD[32+rsp],xmm0
	movaps	xmm9,XMMWORD[48+rsp]
	movaps	XMMWORD[48+rsp],xmm0
	lea	rsp,[88+rsp]
$L$ccm64_enc_ret:
	mov	rdi,QWORD[8+rsp]	;WIN64 epilogue
	mov	rsi,QWORD[16+rsp]
	DB	0F3h,0C3h		;repret
$L$SEH_end_aesni_ccm64_encrypt_blocks:
global	aesni_ccm64_decrypt_blocks

ALIGN	16
aesni_ccm64_decrypt_blocks:
	mov	QWORD[8+rsp],rdi	;WIN64 prologue
	mov	QWORD[16+rsp],rsi
	mov	rax,rsp
$L$SEH_begin_aesni_ccm64_decrypt_blocks:
	mov	rdi,rcx
	mov	rsi,rdx
	mov	rdx,r8
	mov	rcx,r9
	mov	r8,QWORD[40+rsp]
	mov	r9,QWORD[48+rsp]


	lea	rsp,[((-88))+rsp]
	movaps	XMMWORD[rsp],xmm6
	movaps	XMMWORD[16+rsp],xmm7
	movaps	XMMWORD[32+rsp],xmm8
	movaps	XMMWORD[48+rsp],xmm9
$L$ccm64_dec_body:
	mov	eax,DWORD[240+rcx]
	movups	xmm6,XMMWORD[r8]
	movdqu	xmm3,XMMWORD[r9]
	movdqa	xmm9,XMMWORD[$L$increment64]
	movdqa	xmm7,XMMWORD[$L$bswap_mask]

	movaps	xmm2,xmm6
	mov	r10d,eax
	mov	r11,rcx
DB	102,15,56,0,247
	movups	xmm0,XMMWORD[rcx]
	movups	xmm1,XMMWORD[16+rcx]
	lea	rcx,[32+rcx]
	xorps	xmm2,xmm0
$L$oop_enc1_5:
DB	102,15,56,220,209
	dec	eax
	movups	xmm1,XMMWORD[rcx]
	lea	rcx,[16+rcx]
	jnz	NEAR $L$oop_enc1_5
DB	102,15,56,221,209
	shl	r10d,4
	mov	eax,16
	movups	xmm8,XMMWORD[rdi]
	paddq	xmm6,xmm9
	lea	rdi,[16+rdi]
	sub	rax,r10
	lea	rcx,[32+r10*1+r11]
	mov	r10,rax
	jmp	NEAR $L$ccm64_dec_outer
ALIGN	16
$L$ccm64_dec_outer:
	xorps	xmm8,xmm2
	movdqa	xmm2,xmm6
	movups	XMMWORD[rsi],xmm8
	lea	rsi,[16+rsi]
DB	102,15,56,0,215

	sub	rdx,1
	jz	NEAR $L$ccm64_dec_break

	movups	xmm0,XMMWORD[r11]
	mov	rax,r10
	movups	xmm1,XMMWORD[16+r11]
	xorps	xmm8,xmm0
	xorps	xmm2,xmm0
	xorps	xmm3,xmm8
	movups	xmm0,XMMWORD[32+r11]
	jmp	NEAR $L$ccm64_dec2_loop
ALIGN	16
$L$ccm64_dec2_loop:
DB	102,15,56,220,209
DB	102,15,56,220,217
	movups	xmm1,XMMWORD[rax*1+rcx]
	add	rax,32
DB	102,15,56,220,208
DB	102,15,56,220,216
	movups	xmm0,XMMWORD[((-16))+rax*1+rcx]
	jnz	NEAR $L$ccm64_dec2_loop
	movups	xmm8,XMMWORD[rdi]
	paddq	xmm6,xmm9
DB	102,15,56,220,209
DB	102,15,56,220,217
DB	102,15,56,221,208
DB	102,15,56,221,216
	lea	rdi,[16+rdi]
	jmp	NEAR $L$ccm64_dec_outer

ALIGN	16
$L$ccm64_dec_break:

	mov	eax,DWORD[240+r11]
	movups	xmm0,XMMWORD[r11]
	movups	xmm1,XMMWORD[16+r11]
	xorps	xmm8,xmm0
	lea	r11,[32+r11]
	xorps	xmm3,xmm8
$L$oop_enc1_6:
DB	102,15,56,220,217
	dec	eax
	movups	xmm1,XMMWORD[r11]
	lea	r11,[16+r11]
	jnz	NEAR $L$oop_enc1_6
DB	102,15,56,221,217
	pxor	xmm0,xmm0
	pxor	xmm1,xmm1
	pxor	xmm2,xmm2
	movups	XMMWORD[r9],xmm3
	pxor	xmm3,xmm3
	pxor	xmm8,xmm8
	pxor	xmm6,xmm6
	movaps	xmm6,XMMWORD[rsp]
	movaps	XMMWORD[rsp],xmm0
	movaps	xmm7,XMMWORD[16+rsp]
	movaps	XMMWORD[16+rsp],xmm0
	movaps	xmm8,XMMWORD[32+rsp]
	movaps	XMMWORD[32+rsp],xmm0
	movaps	xmm9,XMMWORD[48+rsp]
	movaps	XMMWORD[48+rsp],xmm0
	lea	rsp,[88+rsp]
$L$ccm64_dec_ret:
	mov	rdi,QWORD[8+rsp]	;WIN64 epilogue
	mov	rsi,QWORD[16+rsp]
	DB	0F3h,0C3h		;repret
$L$SEH_end_aesni_ccm64_decrypt_blocks:
global	aesni_ctr32_encrypt_blocks

ALIGN	16
aesni_ctr32_encrypt_blocks:
	mov	QWORD[8+rsp],rdi	;WIN64 prologue
	mov	QWORD[16+rsp],rsi
	mov	rax,rsp
$L$SEH_begin_aesni_ctr32_encrypt_blocks:
	mov	rdi,rcx
	mov	rsi,rdx
	mov	rdx,r8
	mov	rcx,r9
	mov	r8,QWORD[40+rsp]


	cmp	rdx,1
	jne	NEAR $L$ctr32_bulk



	movups	xmm2,XMMWORD[r8]
	movups	xmm3,XMMWORD[rdi]
	mov	edx,DWORD[240+rcx]
	movups	xmm0,XMMWORD[rcx]
	movups	xmm1,XMMWORD[16+rcx]
	lea	rcx,[32+rcx]
	xorps	xmm2,xmm0
$L$oop_enc1_7:
DB	102,15,56,220,209
	dec	edx
	movups	xmm1,XMMWORD[rcx]
	lea	rcx,[16+rcx]
	jnz	NEAR $L$oop_enc1_7
DB	102,15,56,221,209
	pxor	xmm0,xmm0
	pxor	xmm1,xmm1
	xorps	xmm2,xmm3
	pxor	xmm3,xmm3
	movups	XMMWORD[rsi],xmm2
	xorps	xmm2,xmm2
	jmp	NEAR $L$ctr32_epilogue

ALIGN	16
$L$ctr32_bulk:
	lea	rax,[rsp]
	push	rbp
	sub	rsp,288
	and	rsp,-16
	movaps	XMMWORD[(-168)+rax],xmm6
	movaps	XMMWORD[(-152)+rax],xmm7
	movaps	XMMWORD[(-136)+rax],xmm8
	movaps	XMMWORD[(-120)+rax],xmm9
	movaps	XMMWORD[(-104)+rax],xmm10
	movaps	XMMWORD[(-88)+rax],xmm11
	movaps	XMMWORD[(-72)+rax],xmm12
	movaps	XMMWORD[(-56)+rax],xmm13
	movaps	XMMWORD[(-40)+rax],xmm14
	movaps	XMMWORD[(-24)+rax],xmm15
$L$ctr32_body:
	lea	rbp,[((-8))+rax]




	movdqu	xmm2,XMMWORD[r8]
	movdqu	xmm0,XMMWORD[rcx]
	mov	r8d,DWORD[12+r8]
	pxor	xmm2,xmm0
	mov	r11d,DWORD[12+rcx]
	movdqa	XMMWORD[rsp],xmm2
	bswap	r8d
	movdqa	xmm3,xmm2
	movdqa	xmm4,xmm2
	movdqa	xmm5,xmm2
	movdqa	XMMWORD[64+rsp],xmm2
	movdqa	XMMWORD[80+rsp],xmm2
	movdqa	XMMWORD[96+rsp],xmm2
	mov	r10,rdx
	movdqa	XMMWORD[112+rsp],xmm2

	lea	rax,[1+r8]
	lea	rdx,[2+r8]
	bswap	eax
	bswap	edx
	xor	eax,r11d
	xor	edx,r11d
DB	102,15,58,34,216,3
	lea	rax,[3+r8]
	movdqa	XMMWORD[16+rsp],xmm3
DB	102,15,58,34,226,3
	bswap	eax
	mov	rdx,r10
	lea	r10,[4+r8]
	movdqa	XMMWORD[32+rsp],xmm4
	xor	eax,r11d
	bswap	r10d
DB	102,15,58,34,232,3
	xor	r10d,r11d
	movdqa	XMMWORD[48+rsp],xmm5
	lea	r9,[5+r8]
	mov	DWORD[((64+12))+rsp],r10d
	bswap	r9d
	lea	r10,[6+r8]
	mov	eax,DWORD[240+rcx]
	xor	r9d,r11d
	bswap	r10d
	mov	DWORD[((80+12))+rsp],r9d
	xor	r10d,r11d
	lea	r9,[7+r8]
	mov	DWORD[((96+12))+rsp],r10d
	bswap	r9d
	mov	r10d,DWORD[((OPENSSL_ia32cap_P+4))]
	xor	r9d,r11d
	and	r10d,71303168
	mov	DWORD[((112+12))+rsp],r9d

	movups	xmm1,XMMWORD[16+rcx]

	movdqa	xmm6,XMMWORD[64+rsp]
	movdqa	xmm7,XMMWORD[80+rsp]

	cmp	rdx,8
	jb	NEAR $L$ctr32_tail

	sub	rdx,6
	cmp	r10d,4194304
	je	NEAR $L$ctr32_6x

	lea	rcx,[128+rcx]
	sub	rdx,2
	jmp	NEAR $L$ctr32_loop8

ALIGN	16
$L$ctr32_6x:
	shl	eax,4
	mov	r10d,48
	bswap	r11d
	lea	rcx,[32+rax*1+rcx]
	sub	r10,rax
	jmp	NEAR $L$ctr32_loop6

ALIGN	16
$L$ctr32_loop6:
	add	r8d,6
	movups	xmm0,XMMWORD[((-48))+r10*1+rcx]
DB	102,15,56,220,209
	mov	eax,r8d
	xor	eax,r11d
DB	102,15,56,220,217
DB	0x0f,0x38,0xf1,0x44,0x24,12
	lea	eax,[1+r8]
DB	102,15,56,220,225
	xor	eax,r11d
DB	0x0f,0x38,0xf1,0x44,0x24,28
DB	102,15,56,220,233
	lea	eax,[2+r8]
	xor	eax,r11d
DB	102,15,56,220,241
DB	0x0f,0x38,0xf1,0x44,0x24,44
	lea	eax,[3+r8]
DB	102,15,56,220,249
	movups	xmm1,XMMWORD[((-32))+r10*1+rcx]
	xor	eax,r11d

DB	102,15,56,220,208
DB	0x0f,0x38,0xf1,0x44,0x24,60
	lea	eax,[4+r8]
DB	102,15,56,220,216
	xor	eax,r11d
DB	0x0f,0x38,0xf1,0x44,0x24,76
DB	102,15,56,220,224
	lea	eax,[5+r8]
	xor	eax,r11d
DB	102,15,56,220,232
DB	0x0f,0x38,0xf1,0x44,0x24,92
	mov	rax,r10
DB	102,15,56,220,240
DB	102,15,56,220,248
	movups	xmm0,XMMWORD[((-16))+r10*1+rcx]

	call	$L$enc_loop6

	movdqu	xmm8,XMMWORD[rdi]
	movdqu	xmm9,XMMWORD[16+rdi]
	movdqu	xmm10,XMMWORD[32+rdi]
	movdqu	xmm11,XMMWORD[48+rdi]
	movdqu	xmm12,XMMWORD[64+rdi]
	movdqu	xmm13,XMMWORD[80+rdi]
	lea	rdi,[96+rdi]
	movups	xmm1,XMMWORD[((-64))+r10*1+rcx]
	pxor	xmm8,xmm2
	movaps	xmm2,XMMWORD[rsp]
	pxor	xmm9,xmm3
	movaps	xmm3,XMMWORD[16+rsp]
	pxor	xmm10,xmm4
	movaps	xmm4,XMMWORD[32+rsp]
	pxor	xmm11,xmm5
	movaps	xmm5,XMMWORD[48+rsp]
	pxor	xmm12,xmm6
	movaps	xmm6,XMMWORD[64+rsp]
	pxor	xmm13,xmm7
	movaps	xmm7,XMMWORD[80+rsp]
	movdqu	XMMWORD[rsi],xmm8
	movdqu	XMMWORD[16+rsi],xmm9
	movdqu	XMMWORD[32+rsi],xmm10
	movdqu	XMMWORD[48+rsi],xmm11
	movdqu	XMMWORD[64+rsi],xmm12
	movdqu	XMMWORD[80+rsi],xmm13
	lea	rsi,[96+rsi]

	sub	rdx,6
	jnc	NEAR $L$ctr32_loop6

	add	rdx,6
	jz	NEAR $L$ctr32_done

	lea	eax,[((-48))+r10]
	lea	rcx,[((-80))+r10*1+rcx]
	neg	eax
	shr	eax,4
	jmp	NEAR $L$ctr32_tail

ALIGN	32
$L$ctr32_loop8:
	add	r8d,8
	movdqa	xmm8,XMMWORD[96+rsp]
DB	102,15,56,220,209
	mov	r9d,r8d
	movdqa	xmm9,XMMWORD[112+rsp]
DB	102,15,56,220,217
	bswap	r9d
	movups	xmm0,XMMWORD[((32-128))+rcx]
DB	102,15,56,220,225
	xor	r9d,r11d
	nop
DB	102,15,56,220,233
	mov	DWORD[((0+12))+rsp],r9d
	lea	r9,[1+r8]
DB	102,15,56,220,241
DB	102,15,56,220,249
DB	102,68,15,56,220,193
DB	102,68,15,56,220,201
	movups	xmm1,XMMWORD[((48-128))+rcx]
	bswap	r9d
DB	102,15,56,220,208
DB	102,15,56,220,216
	xor	r9d,r11d
DB	0x66,0x90
DB	102,15,56,220,224
DB	102,15,56,220,232
	mov	DWORD[((16+12))+rsp],r9d
	lea	r9,[2+r8]
DB	102,15,56,220,240
DB	102,15,56,220,248
DB	102,68,15,56,220,192
DB	102,68,15,56,220,200
	movups	xmm0,XMMWORD[((64-128))+rcx]
	bswap	r9d
DB	102,15,56,220,209
DB	102,15,56,220,217
	xor	r9d,r11d
DB	0x66,0x90
DB	102,15,56,220,225
DB	102,15,56,220,233
	mov	DWORD[((32+12))+rsp],r9d
	lea	r9,[3+r8]
DB	102,15,56,220,241
DB	102,15,56,220,249
DB	102,68,15,56,220,193
DB	102,68,15,56,220,201
	movups	xmm1,XMMWORD[((80-128))+rcx]
	bswap	r9d
DB	102,15,56,220,208
DB	102,15,56,220,216
	xor	r9d,r11d
DB	0x66,0x90
DB	102,15,56,220,224
DB	102,15,56,220,232
	mov	DWORD[((48+12))+rsp],r9d
	lea	r9,[4+r8]
DB	102,15,56,220,240
DB	102,15,56,220,248
DB	102,68,15,56,220,192
DB	102,68,15,56,220,200
	movups	xmm0,XMMWORD[((96-128))+rcx]
	bswap	r9d
DB	102,15,56,220,209
DB	102,15,56,220,217
	xor	r9d,r11d
DB	0x66,0x90
DB	102,15,56,220,225
DB	102,15,56,220,233
	mov	DWORD[((64+12))+rsp],r9d
	lea	r9,[5+r8]
DB	102,15,56,220,241
DB	102,15,56,220,249
DB	102,68,15,56,220,193
DB	102,68,15,56,220,201
	movups	xmm1,XMMWORD[((112-128))+rcx]
	bswap	r9d
DB	102,15,56,220,208
DB	102,15,56,220,216
	xor	r9d,r11d
DB	0x66,0x90
DB	102,15,56,220,224
DB	102,15,56,220,232
	mov	DWORD[((80+12))+rsp],r9d
	lea	r9,[6+r8]
DB	102,15,56,220,240
DB	102,15,56,220,248
DB	102,68,15,56,220,192
DB	102,68,15,56,220,200
	movups	xmm0,XMMWORD[((128-128))+rcx]
	bswap	r9d
DB	102,15,56,220,209
DB	102,15,56,220,217
	xor	r9d,r11d
DB	0x66,0x90
DB	102,15,56,220,225
DB	102,15,56,220,233
	mov	DWORD[((96+12))+rsp],r9d
	lea	r9,[7+r8]
DB	102,15,56,220,241
DB	102,15,56,220,249
DB	102,68,15,56,220,193
DB	102,68,15,56,220,201
	movups	xmm1,XMMWORD[((144-128))+rcx]
	bswap	r9d
DB	102,15,56,220,208
DB	102,15,56,220,216
DB	102,15,56,220,224
	xor	r9d,r11d
	movdqu	xmm10,XMMWORD[rdi]
DB	102,15,56,220,232
	mov	DWORD[((112+12))+rsp],r9d
	cmp	eax,11
DB	102,15,56,220,240
DB	102,15,56,220,248
DB	102,68,15,56,220,192
DB	102,68,15,56,220,200
	movups	xmm0,XMMWORD[((160-128))+rcx]

	jb	NEAR $L$ctr32_enc_done

DB	102,15,56,220,209
DB	102,15,56,220,217
DB	102,15,56,220,225
DB	102,15,56,220,233
DB	102,15,56,220,241
DB	102,15,56,220,249
DB	102,68,15,56,220,193
DB	102,68,15,56,220,201
	movups	xmm1,XMMWORD[((176-128))+rcx]

DB	102,15,56,220,208
DB	102,15,56,220,216
DB	102,15,56,220,224
DB	102,15,56,220,232
DB	102,15,56,220,240
DB	102,15,56,220,248
DB	102,68,15,56,220,192
DB	102,68,15,56,220,200
	movups	xmm0,XMMWORD[((192-128))+rcx]
	je	NEAR $L$ctr32_enc_done

DB	102,15,56,220,209
DB	102,15,56,220,217
DB	102,15,56,220,225
DB	102,15,56,220,233
DB	102,15,56,220,241
DB	102,15,56,220,249
DB	102,68,15,56,220,193
DB	102,68,15,56,220,201
	movups	xmm1,XMMWORD[((208-128))+rcx]

DB	102,15,56,220,208
DB	102,15,56,220,216
DB	102,15,56,220,224
DB	102,15,56,220,232
DB	102,15,56,220,240
DB	102,15,56,220,248
DB	102,68,15,56,220,192
DB	102,68,15,56,220,200
	movups	xmm0,XMMWORD[((224-128))+rcx]
	jmp	NEAR $L$ctr32_enc_done

ALIGN	16
$L$ctr32_enc_done:
	movdqu	xmm11,XMMWORD[16+rdi]
	pxor	xmm10,xmm0
	movdqu	xmm12,XMMWORD[32+rdi]
	pxor	xmm11,xmm0
	movdqu	xmm13,XMMWORD[48+rdi]
	pxor	xmm12,xmm0
	movdqu	xmm14,XMMWORD[64+rdi]
	pxor	xmm13,xmm0
	movdqu	xmm15,XMMWORD[80+rdi]
	pxor	xmm14,xmm0
	pxor	xmm15,xmm0
DB	102,15,56,220,209
DB	102,15,56,220,217
DB	102,15,56,220,225
DB	102,15,56,220,233
DB	102,15,56,220,241
DB	102,15,56,220,249
DB	102,68,15,56,220,193
DB	102,68,15,56,220,201
	movdqu	xmm1,XMMWORD[96+rdi]
	lea	rdi,[128+rdi]

DB	102,65,15,56,221,210
	pxor	xmm1,xmm0
	movdqu	xmm10,XMMWORD[((112-128))+rdi]
DB	102,65,15,56,221,219
	pxor	xmm10,xmm0
	movdqa	xmm11,XMMWORD[rsp]
DB	102,65,15,56,221,228
DB	102,65,15,56,221,237
	movdqa	xmm12,XMMWORD[16+rsp]
	movdqa	xmm13,XMMWORD[32+rsp]
DB	102,65,15,56,221,246
DB	102,65,15,56,221,255
	movdqa	xmm14,XMMWORD[48+rsp]
	movdqa	xmm15,XMMWORD[64+rsp]
DB	102,68,15,56,221,193
	movdqa	xmm0,XMMWORD[80+rsp]
	movups	xmm1,XMMWORD[((16-128))+rcx]
DB	102,69,15,56,221,202

	movups	XMMWORD[rsi],xmm2
	movdqa	xmm2,xmm11
	movups	XMMWORD[16+rsi],xmm3
	movdqa	xmm3,xmm12
	movups	XMMWORD[32+rsi],xmm4
	movdqa	xmm4,xmm13
	movups	XMMWORD[48+rsi],xmm5
	movdqa	xmm5,xmm14
	movups	XMMWORD[64+rsi],xmm6
	movdqa	xmm6,xmm15
	movups	XMMWORD[80+rsi],xmm7
	movdqa	xmm7,xmm0
	movups	XMMWORD[96+rsi],xmm8
	movups	XMMWORD[112+rsi],xmm9
	lea	rsi,[128+rsi]

	sub	rdx,8
	jnc	NEAR $L$ctr32_loop8

	add	rdx,8
	jz	NEAR $L$ctr32_done
	lea	rcx,[((-128))+rcx]

$L$ctr32_tail:


	lea	rcx,[16+rcx]
	cmp	rdx,4
	jb	NEAR $L$ctr32_loop3
	je	NEAR $L$ctr32_loop4


	shl	eax,4
	movdqa	xmm8,XMMWORD[96+rsp]
	pxor	xmm9,xmm9

	movups	xmm0,XMMWORD[16+rcx]
DB	102,15,56,220,209
DB	102,15,56,220,217
	lea	rcx,[((32-16))+rax*1+rcx]
	neg	rax
DB	102,15,56,220,225
	add	rax,16
	movups	xmm10,XMMWORD[rdi]
DB	102,15,56,220,233
DB	102,15,56,220,241
	movups	xmm11,XMMWORD[16+rdi]
	movups	xmm12,XMMWORD[32+rdi]
DB	102,15,56,220,249
DB	102,68,15,56,220,193

	call	$L$enc_loop8_enter

	movdqu	xmm13,XMMWORD[48+rdi]
	pxor	xmm2,xmm10
	movdqu	xmm10,XMMWORD[64+rdi]
	pxor	xmm3,xmm11
	movdqu	XMMWORD[rsi],xmm2
	pxor	xmm4,xmm12
	movdqu	XMMWORD[16+rsi],xmm3
	pxor	xmm5,xmm13
	movdqu	XMMWORD[32+rsi],xmm4
	pxor	xmm6,xmm10
	movdqu	XMMWORD[48+rsi],xmm5
	movdqu	XMMWORD[64+rsi],xmm6
	cmp	rdx,6
	jb	NEAR $L$ctr32_done

	movups	xmm11,XMMWORD[80+rdi]
	xorps	xmm7,xmm11
	movups	XMMWORD[80+rsi],xmm7
	je	NEAR $L$ctr32_done

	movups	xmm12,XMMWORD[96+rdi]
	xorps	xmm8,xmm12
	movups	XMMWORD[96+rsi],xmm8
	jmp	NEAR $L$ctr32_done

ALIGN	32
$L$ctr32_loop4:
DB	102,15,56,220,209
	lea	rcx,[16+rcx]
	dec	eax
DB	102,15,56,220,217
DB	102,15,56,220,225
DB	102,15,56,220,233
	movups	xmm1,XMMWORD[rcx]
	jnz	NEAR $L$ctr32_loop4
DB	102,15,56,221,209
DB	102,15,56,221,217
	movups	xmm10,XMMWORD[rdi]
	movups	xmm11,XMMWORD[16+rdi]
DB	102,15,56,221,225
DB	102,15,56,221,233
	movups	xmm12,XMMWORD[32+rdi]
	movups	xmm13,XMMWORD[48+rdi]

	xorps	xmm2,xmm10
	movups	XMMWORD[rsi],xmm2
	xorps	xmm3,xmm11
	movups	XMMWORD[16+rsi],xmm3
	pxor	xmm4,xmm12
	movdqu	XMMWORD[32+rsi],xmm4
	pxor	xmm5,xmm13
	movdqu	XMMWORD[48+rsi],xmm5
	jmp	NEAR $L$ctr32_done

ALIGN	32
$L$ctr32_loop3:
DB	102,15,56,220,209
	lea	rcx,[16+rcx]
	dec	eax
DB	102,15,56,220,217
DB	102,15,56,220,225
	movups	xmm1,XMMWORD[rcx]
	jnz	NEAR $L$ctr32_loop3
DB	102,15,56,221,209
DB	102,15,56,221,217
DB	102,15,56,221,225

	movups	xmm10,XMMWORD[rdi]
	xorps	xmm2,xmm10
	movups	XMMWORD[rsi],xmm2
	cmp	rdx,2
	jb	NEAR $L$ctr32_done

	movups	xmm11,XMMWORD[16+rdi]
	xorps	xmm3,xmm11
	movups	XMMWORD[16+rsi],xmm3
	je	NEAR $L$ctr32_done

	movups	xmm12,XMMWORD[32+rdi]
	xorps	xmm4,xmm12
	movups	XMMWORD[32+rsi],xmm4

$L$ctr32_done:
	xorps	xmm0,xmm0
	xor	r11d,r11d
	pxor	xmm1,xmm1
	pxor	xmm2,xmm2
	pxor	xmm3,xmm3
	pxor	xmm4,xmm4
	pxor	xmm5,xmm5
	movaps	xmm6,XMMWORD[((-160))+rbp]
	movaps	XMMWORD[(-160)+rbp],xmm0
	movaps	xmm7,XMMWORD[((-144))+rbp]
	movaps	XMMWORD[(-144)+rbp],xmm0
	movaps	xmm8,XMMWORD[((-128))+rbp]
	movaps	XMMWORD[(-128)+rbp],xmm0
	movaps	xmm9,XMMWORD[((-112))+rbp]
	movaps	XMMWORD[(-112)+rbp],xmm0
	movaps	xmm10,XMMWORD[((-96))+rbp]
	movaps	XMMWORD[(-96)+rbp],xmm0
	movaps	xmm11,XMMWORD[((-80))+rbp]
	movaps	XMMWORD[(-80)+rbp],xmm0
	movaps	xmm12,XMMWORD[((-64))+rbp]
	movaps	XMMWORD[(-64)+rbp],xmm0
	movaps	xmm13,XMMWORD[((-48))+rbp]
	movaps	XMMWORD[(-48)+rbp],xmm0
	movaps	xmm14,XMMWORD[((-32))+rbp]
	movaps	XMMWORD[(-32)+rbp],xmm0
	movaps	xmm15,XMMWORD[((-16))+rbp]
	movaps	XMMWORD[(-16)+rbp],xmm0
	movaps	XMMWORD[rsp],xmm0
	movaps	XMMWORD[16+rsp],xmm0
	movaps	XMMWORD[32+rsp],xmm0
	movaps	XMMWORD[48+rsp],xmm0
	movaps	XMMWORD[64+rsp],xmm0
	movaps	XMMWORD[80+rsp],xmm0
	movaps	XMMWORD[96+rsp],xmm0
	movaps	XMMWORD[112+rsp],xmm0
	lea	rsp,[rbp]
	pop	rbp
$L$ctr32_epilogue:
	mov	rdi,QWORD[8+rsp]	;WIN64 epilogue
	mov	rsi,QWORD[16+rsp]
	DB	0F3h,0C3h		;repret
$L$SEH_end_aesni_ctr32_encrypt_blocks:
global	aesni_xts_encrypt

ALIGN	16
aesni_xts_encrypt:
	mov	QWORD[8+rsp],rdi	;WIN64 prologue
	mov	QWORD[16+rsp],rsi
	mov	rax,rsp
$L$SEH_begin_aesni_xts_encrypt:
	mov	rdi,rcx
	mov	rsi,rdx
	mov	rdx,r8
	mov	rcx,r9
	mov	r8,QWORD[40+rsp]
	mov	r9,QWORD[48+rsp]


	lea	rax,[rsp]
	push	rbp
	sub	rsp,272
	and	rsp,-16
	movaps	XMMWORD[(-168)+rax],xmm6
	movaps	XMMWORD[(-152)+rax],xmm7
	movaps	XMMWORD[(-136)+rax],xmm8
	movaps	XMMWORD[(-120)+rax],xmm9
	movaps	XMMWORD[(-104)+rax],xmm10
	movaps	XMMWORD[(-88)+rax],xmm11
	movaps	XMMWORD[(-72)+rax],xmm12
	movaps	XMMWORD[(-56)+rax],xmm13
	movaps	XMMWORD[(-40)+rax],xmm14
	movaps	XMMWORD[(-24)+rax],xmm15
$L$xts_enc_body:
	lea	rbp,[((-8))+rax]
	movups	xmm2,XMMWORD[r9]
	mov	eax,DWORD[240+r8]
	mov	r10d,DWORD[240+rcx]
	movups	xmm0,XMMWORD[r8]
	movups	xmm1,XMMWORD[16+r8]
	lea	r8,[32+r8]
	xorps	xmm2,xmm0
$L$oop_enc1_8:
DB	102,15,56,220,209
	dec	eax
	movups	xmm1,XMMWORD[r8]
	lea	r8,[16+r8]
	jnz	NEAR $L$oop_enc1_8
DB	102,15,56,221,209
	movups	xmm0,XMMWORD[rcx]
	mov	r11,rcx
	mov	eax,r10d
	shl	r10d,4
	mov	r9,rdx
	and	rdx,-16

	movups	xmm1,XMMWORD[16+r10*1+rcx]

	movdqa	xmm8,XMMWORD[$L$xts_magic]
	movdqa	xmm15,xmm2
	pshufd	xmm9,xmm2,0x5f
	pxor	xmm1,xmm0
	movdqa	xmm14,xmm9
	paddd	xmm9,xmm9
	movdqa	xmm10,xmm15
	psrad	xmm14,31
	paddq	xmm15,xmm15
	pand	xmm14,xmm8
	pxor	xmm10,xmm0
	pxor	xmm15,xmm14
	movdqa	xmm14,xmm9
	paddd	xmm9,xmm9
	movdqa	xmm11,xmm15
	psrad	xmm14,31
	paddq	xmm15,xmm15
	pand	xmm14,xmm8
	pxor	xmm11,xmm0
	pxor	xmm15,xmm14
	movdqa	xmm14,xmm9
	paddd	xmm9,xmm9
	movdqa	xmm12,xmm15
	psrad	xmm14,31
	paddq	xmm15,xmm15
	pand	xmm14,xmm8
	pxor	xmm12,xmm0
	pxor	xmm15,xmm14
	movdqa	xmm14,xmm9
	paddd	xmm9,xmm9
	movdqa	xmm13,xmm15
	psrad	xmm14,31
	paddq	xmm15,xmm15
	pand	xmm14,xmm8
	pxor	xmm13,xmm0
	pxor	xmm15,xmm14
	movdqa	xmm14,xmm15
	psrad	xmm9,31
	paddq	xmm15,xmm15
	pand	xmm9,xmm8
	pxor	xmm14,xmm0
	pxor	xmm15,xmm9
	movaps	XMMWORD[96+rsp],xmm1

	sub	rdx,16*6
	jc	NEAR $L$xts_enc_short

	mov	eax,16+96
	lea	rcx,[32+r10*1+r11]
	sub	rax,r10
	movups	xmm1,XMMWORD[16+r11]
	mov	r10,rax
	lea	r8,[$L$xts_magic]
	jmp	NEAR $L$xts_enc_grandloop

ALIGN	32
$L$xts_enc_grandloop:
	movdqu	xmm2,XMMWORD[rdi]
	movdqa	xmm8,xmm0
	movdqu	xmm3,XMMWORD[16+rdi]
	pxor	xmm2,xmm10
	movdqu	xmm4,XMMWORD[32+rdi]
	pxor	xmm3,xmm11
DB	102,15,56,220,209
	movdqu	xmm5,XMMWORD[48+rdi]
	pxor	xmm4,xmm12
DB	102,15,56,220,217
	movdqu	xmm6,XMMWORD[64+rdi]
	pxor	xmm5,xmm13
DB	102,15,56,220,225
	movdqu	xmm7,XMMWORD[80+rdi]
	pxor	xmm8,xmm15
	movdqa	xmm9,XMMWORD[96+rsp]
	pxor	xmm6,xmm14
DB	102,15,56,220,233
	movups	xmm0,XMMWORD[32+r11]
	lea	rdi,[96+rdi]
	pxor	xmm7,xmm8

	pxor	xmm10,xmm9
DB	102,15,56,220,241
	pxor	xmm11,xmm9
	movdqa	XMMWORD[rsp],xmm10
DB	102,15,56,220,249
	movups	xmm1,XMMWORD[48+r11]
	pxor	xmm12,xmm9

DB	102,15,56,220,208
	pxor	xmm13,xmm9
	movdqa	XMMWORD[16+rsp],xmm11
DB	102,15,56,220,216
	pxor	xmm14,xmm9
	movdqa	XMMWORD[32+rsp],xmm12
DB	102,15,56,220,224
DB	102,15,56,220,232
	pxor	xmm8,xmm9
	movdqa	XMMWORD[64+rsp],xmm14
DB	102,15,56,220,240
DB	102,15,56,220,248
	movups	xmm0,XMMWORD[64+r11]
	movdqa	XMMWORD[80+rsp],xmm8
	pshufd	xmm9,xmm15,0x5f
	jmp	NEAR $L$xts_enc_loop6
ALIGN	32
$L$xts_enc_loop6:
DB	102,15,56,220,209
DB	102,15,56,220,217
DB	102,15,56,220,225
DB	102,15,56,220,233
DB	102,15,56,220,241
DB	102,15,56,220,249
	movups	xmm1,XMMWORD[((-64))+rax*1+rcx]
	add	rax,32

DB	102,15,56,220,208
DB	102,15,56,220,216
DB	102,15,56,220,224
DB	102,15,56,220,232
DB	102,15,56,220,240
DB	102,15,56,220,248
	movups	xmm0,XMMWORD[((-80))+rax*1+rcx]
	jnz	NEAR $L$xts_enc_loop6

	movdqa	xmm8,XMMWORD[r8]
	movdqa	xmm14,xmm9
	paddd	xmm9,xmm9
DB	102,15,56,220,209
	paddq	xmm15,xmm15
	psrad	xmm14,31
DB	102,15,56,220,217
	pand	xmm14,xmm8
	movups	xmm10,XMMWORD[r11]
DB	102,15,56,220,225
DB	102,15,56,220,233
DB	102,15,56,220,241
	pxor	xmm15,xmm14
	movaps	xmm11,xmm10
DB	102,15,56,220,249
	movups	xmm1,XMMWORD[((-64))+rcx]

	movdqa	xmm14,xmm9
DB	102,15,56,220,208
	paddd	xmm9,xmm9
	pxor	xmm10,xmm15
DB	102,15,56,220,216
	psrad	xmm14,31
	paddq	xmm15,xmm15
DB	102,15,56,220,224
DB	102,15,56,220,232
	pand	xmm14,xmm8
	movaps	xmm12,xmm11
DB	102,15,56,220,240
	pxor	xmm15,xmm14
	movdqa	xmm14,xmm9
DB	102,15,56,220,248
	movups	xmm0,XMMWORD[((-48))+rcx]

	paddd	xmm9,xmm9
DB	102,15,56,220,209
	pxor	xmm11,xmm15
	psrad	xmm14,31
DB	102,15,56,220,217
	paddq	xmm15,xmm15
	pand	xmm14,xmm8
DB	102,15,56,220,225
DB	102,15,56,220,233
	movdqa	XMMWORD[48+rsp],xmm13
	pxor	xmm15,xmm14
DB	102,15,56,220,241
	movaps	xmm13,xmm12
	movdqa	xmm14,xmm9
DB	102,15,56,220,249
	movups	xmm1,XMMWORD[((-32))+rcx]

	paddd	xmm9,xmm9
DB	102,15,56,220,208
	pxor	xmm12,xmm15
	psrad	xmm14,31
DB	102,15,56,220,216
	paddq	xmm15,xmm15
	pand	xmm14,xmm8
DB	102,15,56,220,224
DB	102,15,56,220,232
DB	102,15,56,220,240
	pxor	xmm15,xmm14
	movaps	xmm14,xmm13
DB	102,15,56,220,248

	movdqa	xmm0,xmm9
	paddd	xmm9,xmm9
DB	102,15,56,220,209
	pxor	xmm13,xmm15
	psrad	xmm0,31
DB	102,15,56,220,217
	paddq	xmm15,xmm15
	pand	xmm0,xmm8
DB	102,15,56,220,225
DB	102,15,56,220,233
	pxor	xmm15,xmm0
	movups	xmm0,XMMWORD[r11]
DB	102,15,56,220,241
DB	102,15,56,220,249
	movups	xmm1,XMMWORD[16+r11]

	pxor	xmm14,xmm15
DB	102,15,56,221,84,36,0
	psrad	xmm9,31
	paddq	xmm15,xmm15
DB	102,15,56,221,92,36,16
DB	102,15,56,221,100,36,32
	pand	xmm9,xmm8
	mov	rax,r10
DB	102,15,56,221,108,36,48
DB	102,15,56,221,116,36,64
DB	102,15,56,221,124,36,80
	pxor	xmm15,xmm9

	lea	rsi,[96+rsi]
	movups	XMMWORD[(-96)+rsi],xmm2
	movups	XMMWORD[(-80)+rsi],xmm3
	movups	XMMWORD[(-64)+rsi],xmm4
	movups	XMMWORD[(-48)+rsi],xmm5
	movups	XMMWORD[(-32)+rsi],xmm6
	movups	XMMWORD[(-16)+rsi],xmm7
	sub	rdx,16*6
	jnc	NEAR $L$xts_enc_grandloop

	mov	eax,16+96
	sub	eax,r10d
	mov	rcx,r11
	shr	eax,4

$L$xts_enc_short:

	mov	r10d,eax
	pxor	xmm10,xmm0
	add	rdx,16*6
	jz	NEAR $L$xts_enc_done

	pxor	xmm11,xmm0
	cmp	rdx,0x20
	jb	NEAR $L$xts_enc_one
	pxor	xmm12,xmm0
	je	NEAR $L$xts_enc_two

	pxor	xmm13,xmm0
	cmp	rdx,0x40
	jb	NEAR $L$xts_enc_three
	pxor	xmm14,xmm0
	je	NEAR $L$xts_enc_four

	movdqu	xmm2,XMMWORD[rdi]
	movdqu	xmm3,XMMWORD[16+rdi]
	movdqu	xmm4,XMMWORD[32+rdi]
	pxor	xmm2,xmm10
	movdqu	xmm5,XMMWORD[48+rdi]
	pxor	xmm3,xmm11
	movdqu	xmm6,XMMWORD[64+rdi]
	lea	rdi,[80+rdi]
	pxor	xmm4,xmm12
	pxor	xmm5,xmm13
	pxor	xmm6,xmm14
	pxor	xmm7,xmm7

	call	_aesni_encrypt6

	xorps	xmm2,xmm10
	movdqa	xmm10,xmm15
	xorps	xmm3,xmm11
	xorps	xmm4,xmm12
	movdqu	XMMWORD[rsi],xmm2
	xorps	xmm5,xmm13
	movdqu	XMMWORD[16+rsi],xmm3
	xorps	xmm6,xmm14
	movdqu	XMMWORD[32+rsi],xmm4
	movdqu	XMMWORD[48+rsi],xmm5
	movdqu	XMMWORD[64+rsi],xmm6
	lea	rsi,[80+rsi]
	jmp	NEAR $L$xts_enc_done

ALIGN	16
$L$xts_enc_one:
	movups	xmm2,XMMWORD[rdi]
	lea	rdi,[16+rdi]
	xorps	xmm2,xmm10
	movups	xmm0,XMMWORD[rcx]
	movups	xmm1,XMMWORD[16+rcx]
	lea	rcx,[32+rcx]
	xorps	xmm2,xmm0
$L$oop_enc1_9:
DB	102,15,56,220,209
	dec	eax
	movups	xmm1,XMMWORD[rcx]
	lea	rcx,[16+rcx]
	jnz	NEAR $L$oop_enc1_9
DB	102,15,56,221,209
	xorps	xmm2,xmm10
	movdqa	xmm10,xmm11
	movups	XMMWORD[rsi],xmm2
	lea	rsi,[16+rsi]
	jmp	NEAR $L$xts_enc_done

ALIGN	16
$L$xts_enc_two:
	movups	xmm2,XMMWORD[rdi]
	movups	xmm3,XMMWORD[16+rdi]
	lea	rdi,[32+rdi]
	xorps	xmm2,xmm10
	xorps	xmm3,xmm11

	call	_aesni_encrypt2

	xorps	xmm2,xmm10
	movdqa	xmm10,xmm12
	xorps	xmm3,xmm11
	movups	XMMWORD[rsi],xmm2
	movups	XMMWORD[16+rsi],xmm3
	lea	rsi,[32+rsi]
	jmp	NEAR $L$xts_enc_done

ALIGN	16
$L$xts_enc_three:
	movups	xmm2,XMMWORD[rdi]
	movups	xmm3,XMMWORD[16+rdi]
	movups	xmm4,XMMWORD[32+rdi]
	lea	rdi,[48+rdi]
	xorps	xmm2,xmm10
	xorps	xmm3,xmm11
	xorps	xmm4,xmm12

	call	_aesni_encrypt3

	xorps	xmm2,xmm10
	movdqa	xmm10,xmm13
	xorps	xmm3,xmm11
	xorps	xmm4,xmm12
	movups	XMMWORD[rsi],xmm2
	movups	XMMWORD[16+rsi],xmm3
	movups	XMMWORD[32+rsi],xmm4
	lea	rsi,[48+rsi]
	jmp	NEAR $L$xts_enc_done

ALIGN	16
$L$xts_enc_four:
	movups	xmm2,XMMWORD[rdi]
	movups	xmm3,XMMWORD[16+rdi]
	movups	xmm4,XMMWORD[32+rdi]
	xorps	xmm2,xmm10
	movups	xmm5,XMMWORD[48+rdi]
	lea	rdi,[64+rdi]
	xorps	xmm3,xmm11
	xorps	xmm4,xmm12
	xorps	xmm5,xmm13

	call	_aesni_encrypt4

	pxor	xmm2,xmm10
	movdqa	xmm10,xmm14
	pxor	xmm3,xmm11
	pxor	xmm4,xmm12
	movdqu	XMMWORD[rsi],xmm2
	pxor	xmm5,xmm13
	movdqu	XMMWORD[16+rsi],xmm3
	movdqu	XMMWORD[32+rsi],xmm4
	movdqu	XMMWORD[48+rsi],xmm5
	lea	rsi,[64+rsi]
	jmp	NEAR $L$xts_enc_done

ALIGN	16
$L$xts_enc_done:
	and	r9,15
	jz	NEAR $L$xts_enc_ret
	mov	rdx,r9

$L$xts_enc_steal:
	movzx	eax,BYTE[rdi]
	movzx	ecx,BYTE[((-16))+rsi]
	lea	rdi,[1+rdi]
	mov	BYTE[((-16))+rsi],al
	mov	BYTE[rsi],cl
	lea	rsi,[1+rsi]
	sub	rdx,1
	jnz	NEAR $L$xts_enc_steal

	sub	rsi,r9
	mov	rcx,r11
	mov	eax,r10d

	movups	xmm2,XMMWORD[((-16))+rsi]
	xorps	xmm2,xmm10
	movups	xmm0,XMMWORD[rcx]
	movups	xmm1,XMMWORD[16+rcx]
	lea	rcx,[32+rcx]
	xorps	xmm2,xmm0
$L$oop_enc1_10:
DB	102,15,56,220,209
	dec	eax
	movups	xmm1,XMMWORD[rcx]
	lea	rcx,[16+rcx]
	jnz	NEAR $L$oop_enc1_10
DB	102,15,56,221,209
	xorps	xmm2,xmm10
	movups	XMMWORD[(-16)+rsi],xmm2

$L$xts_enc_ret:
	xorps	xmm0,xmm0
	pxor	xmm1,xmm1
	pxor	xmm2,xmm2
	pxor	xmm3,xmm3
	pxor	xmm4,xmm4
	pxor	xmm5,xmm5
	movaps	xmm6,XMMWORD[((-160))+rbp]
	movaps	XMMWORD[(-160)+rbp],xmm0
	movaps	xmm7,XMMWORD[((-144))+rbp]
	movaps	XMMWORD[(-144)+rbp],xmm0
	movaps	xmm8,XMMWORD[((-128))+rbp]
	movaps	XMMWORD[(-128)+rbp],xmm0
	movaps	xmm9,XMMWORD[((-112))+rbp]
	movaps	XMMWORD[(-112)+rbp],xmm0
	movaps	xmm10,XMMWORD[((-96))+rbp]
	movaps	XMMWORD[(-96)+rbp],xmm0
	movaps	xmm11,XMMWORD[((-80))+rbp]
	movaps	XMMWORD[(-80)+rbp],xmm0
	movaps	xmm12,XMMWORD[((-64))+rbp]
	movaps	XMMWORD[(-64)+rbp],xmm0
	movaps	xmm13,XMMWORD[((-48))+rbp]
	movaps	XMMWORD[(-48)+rbp],xmm0
	movaps	xmm14,XMMWORD[((-32))+rbp]
	movaps	XMMWORD[(-32)+rbp],xmm0
	movaps	xmm15,XMMWORD[((-16))+rbp]
	movaps	XMMWORD[(-16)+rbp],xmm0
	movaps	XMMWORD[rsp],xmm0
	movaps	XMMWORD[16+rsp],xmm0
	movaps	XMMWORD[32+rsp],xmm0
	movaps	XMMWORD[48+rsp],xmm0
	movaps	XMMWORD[64+rsp],xmm0
	movaps	XMMWORD[80+rsp],xmm0
	movaps	XMMWORD[96+rsp],xmm0
	lea	rsp,[rbp]
	pop	rbp
$L$xts_enc_epilogue:
	mov	rdi,QWORD[8+rsp]	;WIN64 epilogue
	mov	rsi,QWORD[16+rsp]
	DB	0F3h,0C3h		;repret
$L$SEH_end_aesni_xts_encrypt:
global	aesni_xts_decrypt

ALIGN	16
aesni_xts_decrypt:
	mov	QWORD[8+rsp],rdi	;WIN64 prologue
	mov	QWORD[16+rsp],rsi
	mov	rax,rsp
$L$SEH_begin_aesni_xts_decrypt:
	mov	rdi,rcx
	mov	rsi,rdx
	mov	rdx,r8
	mov	rcx,r9
	mov	r8,QWORD[40+rsp]
	mov	r9,QWORD[48+rsp]


	lea	rax,[rsp]
	push	rbp
	sub	rsp,272
	and	rsp,-16
	movaps	XMMWORD[(-168)+rax],xmm6
	movaps	XMMWORD[(-152)+rax],xmm7
	movaps	XMMWORD[(-136)+rax],xmm8
	movaps	XMMWORD[(-120)+rax],xmm9
	movaps	XMMWORD[(-104)+rax],xmm10
	movaps	XMMWORD[(-88)+rax],xmm11
	movaps	XMMWORD[(-72)+rax],xmm12
	movaps	XMMWORD[(-56)+rax],xmm13
	movaps	XMMWORD[(-40)+rax],xmm14
	movaps	XMMWORD[(-24)+rax],xmm15
$L$xts_dec_body:
	lea	rbp,[((-8))+rax]
	movups	xmm2,XMMWORD[r9]
	mov	eax,DWORD[240+r8]
	mov	r10d,DWORD[240+rcx]
	movups	xmm0,XMMWORD[r8]
	movups	xmm1,XMMWORD[16+r8]
	lea	r8,[32+r8]
	xorps	xmm2,xmm0
$L$oop_enc1_11:
DB	102,15,56,220,209
	dec	eax
	movups	xmm1,XMMWORD[r8]
	lea	r8,[16+r8]
	jnz	NEAR $L$oop_enc1_11
DB	102,15,56,221,209
	xor	eax,eax
	test	rdx,15
	setnz	al
	shl	rax,4
	sub	rdx,rax

	movups	xmm0,XMMWORD[rcx]
	mov	r11,rcx
	mov	eax,r10d
	shl	r10d,4
	mov	r9,rdx
	and	rdx,-16

	movups	xmm1,XMMWORD[16+r10*1+rcx]

	movdqa	xmm8,XMMWORD[$L$xts_magic]
	movdqa	xmm15,xmm2
	pshufd	xmm9,xmm2,0x5f
	pxor	xmm1,xmm0
	movdqa	xmm14,xmm9
	paddd	xmm9,xmm9
	movdqa	xmm10,xmm15
	psrad	xmm14,31
	paddq	xmm15,xmm15
	pand	xmm14,xmm8
	pxor	xmm10,xmm0
	pxor	xmm15,xmm14
	movdqa	xmm14,xmm9
	paddd	xmm9,xmm9
	movdqa	xmm11,xmm15
	psrad	xmm14,31
	paddq	xmm15,xmm15
	pand	xmm14,xmm8
	pxor	xmm11,xmm0
	pxor	xmm15,xmm14
	movdqa	xmm14,xmm9
	paddd	xmm9,xmm9
	movdqa	xmm12,xmm15
	psrad	xmm14,31
	paddq	xmm15,xmm15
	pand	xmm14,xmm8
	pxor	xmm12,xmm0
	pxor	xmm15,xmm14
	movdqa	xmm14,xmm9
	paddd	xmm9,xmm9
	movdqa	xmm13,xmm15
	psrad	xmm14,31
	paddq	xmm15,xmm15
	pand	xmm14,xmm8
	pxor	xmm13,xmm0
	pxor	xmm15,xmm14
	movdqa	xmm14,xmm15
	psrad	xmm9,31
	paddq	xmm15,xmm15
	pand	xmm9,xmm8
	pxor	xmm14,xmm0
	pxor	xmm15,xmm9
	movaps	XMMWORD[96+rsp],xmm1

	sub	rdx,16*6
	jc	NEAR $L$xts_dec_short

	mov	eax,16+96
	lea	rcx,[32+r10*1+r11]
	sub	rax,r10
	movups	xmm1,XMMWORD[16+r11]
	mov	r10,rax
	lea	r8,[$L$xts_magic]
	jmp	NEAR $L$xts_dec_grandloop

ALIGN	32
$L$xts_dec_grandloop:
	movdqu	xmm2,XMMWORD[rdi]
	movdqa	xmm8,xmm0
	movdqu	xmm3,XMMWORD[16+rdi]
	pxor	xmm2,xmm10
	movdqu	xmm4,XMMWORD[32+rdi]
	pxor	xmm3,xmm11
DB	102,15,56,222,209
	movdqu	xmm5,XMMWORD[48+rdi]
	pxor	xmm4,xmm12
DB	102,15,56,222,217
	movdqu	xmm6,XMMWORD[64+rdi]
	pxor	xmm5,xmm13
DB	102,15,56,222,225
	movdqu	xmm7,XMMWORD[80+rdi]
	pxor	xmm8,xmm15
	movdqa	xmm9,XMMWORD[96+rsp]
	pxor	xmm6,xmm14
DB	102,15,56,222,233
	movups	xmm0,XMMWORD[32+r11]
	lea	rdi,[96+rdi]
	pxor	xmm7,xmm8

	pxor	xmm10,xmm9
DB	102,15,56,222,241
	pxor	xmm11,xmm9
	movdqa	XMMWORD[rsp],xmm10
DB	102,15,56,222,249
	movups	xmm1,XMMWORD[48+r11]
	pxor	xmm12,xmm9

DB	102,15,56,222,208
	pxor	xmm13,xmm9
	movdqa	XMMWORD[16+rsp],xmm11
DB	102,15,56,222,216
	pxor	xmm14,xmm9
	movdqa	XMMWORD[32+rsp],xmm12
DB	102,15,56,222,224
DB	102,15,56,222,232
	pxor	xmm8,xmm9
	movdqa	XMMWORD[64+rsp],xmm14
DB	102,15,56,222,240
DB	102,15,56,222,248
	movups	xmm0,XMMWORD[64+r11]
	movdqa	XMMWORD[80+rsp],xmm8
	pshufd	xmm9,xmm15,0x5f
	jmp	NEAR $L$xts_dec_loop6
ALIGN	32
$L$xts_dec_loop6:
DB	102,15,56,222,209
DB	102,15,56,222,217
DB	102,15,56,222,225
DB	102,15,56,222,233
DB	102,15,56,222,241
DB	102,15,56,222,249
	movups	xmm1,XMMWORD[((-64))+rax*1+rcx]
	add	rax,32

DB	102,15,56,222,208
DB	102,15,56,222,216
DB	102,15,56,222,224
DB	102,15,56,222,232
DB	102,15,56,222,240
DB	102,15,56,222,248
	movups	xmm0,XMMWORD[((-80))+rax*1+rcx]
	jnz	NEAR $L$xts_dec_loop6

	movdqa	xmm8,XMMWORD[r8]
	movdqa	xmm14,xmm9
	paddd	xmm9,xmm9
DB	102,15,56,222,209
	paddq	xmm15,xmm15
	psrad	xmm14,31
DB	102,15,56,222,217
	pand	xmm14,xmm8
	movups	xmm10,XMMWORD[r11]
DB	102,15,56,222,225
DB	102,15,56,222,233
DB	102,15,56,222,241
	pxor	xmm15,xmm14
	movaps	xmm11,xmm10
DB	102,15,56,222,249
	movups	xmm1,XMMWORD[((-64))+rcx]

	movdqa	xmm14,xmm9
DB	102,15,56,222,208
	paddd	xmm9,xmm9
	pxor	xmm10,xmm15
DB	102,15,56,222,216
	psrad	xmm14,31
	paddq	xmm15,xmm15
DB	102,15,56,222,224
DB	102,15,56,222,232
	pand	xmm14,xmm8
	movaps	xmm12,xmm11
DB	102,15,56,222,240
	pxor	xmm15,xmm14
	movdqa	xmm14,xmm9
DB	102,15,56,222,248
	movups	xmm0,XMMWORD[((-48))+rcx]

	paddd	xmm9,xmm9
DB	102,15,56,222,209
	pxor	xmm11,xmm15
	psrad	xmm14,31
DB	102,15,56,222,217
	paddq	xmm15,xmm15
	pand	xmm14,xmm8
DB	102,15,56,222,225
DB	102,15,56,222,233
	movdqa	XMMWORD[48+rsp],xmm13
	pxor	xmm15,xmm14
DB	102,15,56,222,241
	movaps	xmm13,xmm12
	movdqa	xmm14,xmm9
DB	102,15,56,222,249
	movups	xmm1,XMMWORD[((-32))+rcx]

	paddd	xmm9,xmm9
DB	102,15,56,222,208
	pxor	xmm12,xmm15
	psrad	xmm14,31
DB	102,15,56,222,216
	paddq	xmm15,xmm15
	pand	xmm14,xmm8
DB	102,15,56,222,224
DB	102,15,56,222,232
DB	102,15,56,222,240
	pxor	xmm15,xmm14
	movaps	xmm14,xmm13
DB	102,15,56,222,248

	movdqa	xmm0,xmm9
	paddd	xmm9,xmm9
DB	102,15,56,222,209
	pxor	xmm13,xmm15
	psrad	xmm0,31
DB	102,15,56,222,217
	paddq	xmm15,xmm15
	pand	xmm0,xmm8
DB	102,15,56,222,225
DB	102,15,56,222,233
	pxor	xmm15,xmm0
	movups	xmm0,XMMWORD[r11]
DB	102,15,56,222,241
DB	102,15,56,222,249
	movups	xmm1,XMMWORD[16+r11]

	pxor	xmm14,xmm15
DB	102,15,56,223,84,36,0
	psrad	xmm9,31
	paddq	xmm15,xmm15
DB	102,15,56,223,92,36,16
DB	102,15,56,223,100,36,32
	pand	xmm9,xmm8
	mov	rax,r10
DB	102,15,56,223,108,36,48
DB	102,15,56,223,116,36,64
DB	102,15,56,223,124,36,80
	pxor	xmm15,xmm9

	lea	rsi,[96+rsi]
	movups	XMMWORD[(-96)+rsi],xmm2
	movups	XMMWORD[(-80)+rsi],xmm3
	movups	XMMWORD[(-64)+rsi],xmm4
	movups	XMMWORD[(-48)+rsi],xmm5
	movups	XMMWORD[(-32)+rsi],xmm6
	movups	XMMWORD[(-16)+rsi],xmm7
	sub	rdx,16*6
	jnc	NEAR $L$xts_dec_grandloop

	mov	eax,16+96
	sub	eax,r10d
	mov	rcx,r11
	shr	eax,4

$L$xts_dec_short:

	mov	r10d,eax
	pxor	xmm10,xmm0
	pxor	xmm11,xmm0
	add	rdx,16*6
	jz	NEAR $L$xts_dec_done

	pxor	xmm12,xmm0
	cmp	rdx,0x20
	jb	NEAR $L$xts_dec_one
	pxor	xmm13,xmm0
	je	NEAR $L$xts_dec_two

	pxor	xmm14,xmm0
	cmp	rdx,0x40
	jb	NEAR $L$xts_dec_three
	je	NEAR $L$xts_dec_four

	movdqu	xmm2,XMMWORD[rdi]
	movdqu	xmm3,XMMWORD[16+rdi]
	movdqu	xmm4,XMMWORD[32+rdi]
	pxor	xmm2,xmm10
	movdqu	xmm5,XMMWORD[48+rdi]
	pxor	xmm3,xmm11
	movdqu	xmm6,XMMWORD[64+rdi]
	lea	rdi,[80+rdi]
	pxor	xmm4,xmm12
	pxor	xmm5,xmm13
	pxor	xmm6,xmm14

	call	_aesni_decrypt6

	xorps	xmm2,xmm10
	xorps	xmm3,xmm11
	xorps	xmm4,xmm12
	movdqu	XMMWORD[rsi],xmm2
	xorps	xmm5,xmm13
	movdqu	XMMWORD[16+rsi],xmm3
	xorps	xmm6,xmm14
	movdqu	XMMWORD[32+rsi],xmm4
	pxor	xmm14,xmm14
	movdqu	XMMWORD[48+rsi],xmm5
	pcmpgtd	xmm14,xmm15
	movdqu	XMMWORD[64+rsi],xmm6
	lea	rsi,[80+rsi]
	pshufd	xmm11,xmm14,0x13
	and	r9,15
	jz	NEAR $L$xts_dec_ret

	movdqa	xmm10,xmm15
	paddq	xmm15,xmm15
	pand	xmm11,xmm8
	pxor	xmm11,xmm15
	jmp	NEAR $L$xts_dec_done2

ALIGN	16
$L$xts_dec_one:
	movups	xmm2,XMMWORD[rdi]
	lea	rdi,[16+rdi]
	xorps	xmm2,xmm10
	movups	xmm0,XMMWORD[rcx]
	movups	xmm1,XMMWORD[16+rcx]
	lea	rcx,[32+rcx]
	xorps	xmm2,xmm0
$L$oop_dec1_12:
DB	102,15,56,222,209
	dec	eax
	movups	xmm1,XMMWORD[rcx]
	lea	rcx,[16+rcx]
	jnz	NEAR $L$oop_dec1_12
DB	102,15,56,223,209
	xorps	xmm2,xmm10
	movdqa	xmm10,xmm11
	movups	XMMWORD[rsi],xmm2
	movdqa	xmm11,xmm12
	lea	rsi,[16+rsi]
	jmp	NEAR $L$xts_dec_done

ALIGN	16
$L$xts_dec_two:
	movups	xmm2,XMMWORD[rdi]
	movups	xmm3,XMMWORD[16+rdi]
	lea	rdi,[32+rdi]
	xorps	xmm2,xmm10
	xorps	xmm3,xmm11

	call	_aesni_decrypt2

	xorps	xmm2,xmm10
	movdqa	xmm10,xmm12
	xorps	xmm3,xmm11
	movdqa	xmm11,xmm13
	movups	XMMWORD[rsi],xmm2
	movups	XMMWORD[16+rsi],xmm3
	lea	rsi,[32+rsi]
	jmp	NEAR $L$xts_dec_done

ALIGN	16
$L$xts_dec_three:
	movups	xmm2,XMMWORD[rdi]
	movups	xmm3,XMMWORD[16+rdi]
	movups	xmm4,XMMWORD[32+rdi]
	lea	rdi,[48+rdi]
	xorps	xmm2,xmm10
	xorps	xmm3,xmm11
	xorps	xmm4,xmm12

	call	_aesni_decrypt3

	xorps	xmm2,xmm10
	movdqa	xmm10,xmm13
	xorps	xmm3,xmm11
	movdqa	xmm11,xmm14
	xorps	xmm4,xmm12
	movups	XMMWORD[rsi],xmm2
	movups	XMMWORD[16+rsi],xmm3
	movups	XMMWORD[32+rsi],xmm4
	lea	rsi,[48+rsi]
	jmp	NEAR $L$xts_dec_done

ALIGN	16
$L$xts_dec_four:
	movups	xmm2,XMMWORD[rdi]
	movups	xmm3,XMMWORD[16+rdi]
	movups	xmm4,XMMWORD[32+rdi]
	xorps	xmm2,xmm10
	movups	xmm5,XMMWORD[48+rdi]
	lea	rdi,[64+rdi]
	xorps	xmm3,xmm11
	xorps	xmm4,xmm12
	xorps	xmm5,xmm13

	call	_aesni_decrypt4

	pxor	xmm2,xmm10
	movdqa	xmm10,xmm14
	pxor	xmm3,xmm11
	movdqa	xmm11,xmm15
	pxor	xmm4,xmm12
	movdqu	XMMWORD[rsi],xmm2
	pxor	xmm5,xmm13
	movdqu	XMMWORD[16+rsi],xmm3
	movdqu	XMMWORD[32+rsi],xmm4
	movdqu	XMMWORD[48+rsi],xmm5
	lea	rsi,[64+rsi]
	jmp	NEAR $L$xts_dec_done

ALIGN	16
$L$xts_dec_done:
	and	r9,15
	jz	NEAR $L$xts_dec_ret
$L$xts_dec_done2:
	mov	rdx,r9
	mov	rcx,r11
	mov	eax,r10d

	movups	xmm2,XMMWORD[rdi]
	xorps	xmm2,xmm11
	movups	xmm0,XMMWORD[rcx]
	movups	xmm1,XMMWORD[16+rcx]
	lea	rcx,[32+rcx]
	xorps	xmm2,xmm0
$L$oop_dec1_13:
DB	102,15,56,222,209
	dec	eax
	movups	xmm1,XMMWORD[rcx]
	lea	rcx,[16+rcx]
	jnz	NEAR $L$oop_dec1_13
DB	102,15,56,223,209
	xorps	xmm2,xmm11
	movups	XMMWORD[rsi],xmm2

$L$xts_dec_steal:
	movzx	eax,BYTE[16+rdi]
	movzx	ecx,BYTE[rsi]
	lea	rdi,[1+rdi]
	mov	BYTE[rsi],al
	mov	BYTE[16+rsi],cl
	lea	rsi,[1+rsi]
	sub	rdx,1
	jnz	NEAR $L$xts_dec_steal

	sub	rsi,r9
	mov	rcx,r11
	mov	eax,r10d

	movups	xmm2,XMMWORD[rsi]
	xorps	xmm2,xmm10
	movups	xmm0,XMMWORD[rcx]
	movups	xmm1,XMMWORD[16+rcx]
	lea	rcx,[32+rcx]
	xorps	xmm2,xmm0
$L$oop_dec1_14:
DB	102,15,56,222,209
	dec	eax
	movups	xmm1,XMMWORD[rcx]
	lea	rcx,[16+rcx]
	jnz	NEAR $L$oop_dec1_14
DB	102,15,56,223,209
	xorps	xmm2,xmm10
	movups	XMMWORD[rsi],xmm2

$L$xts_dec_ret:
	xorps	xmm0,xmm0
	pxor	xmm1,xmm1
	pxor	xmm2,xmm2
	pxor	xmm3,xmm3
	pxor	xmm4,xmm4
	pxor	xmm5,xmm5
	movaps	xmm6,XMMWORD[((-160))+rbp]
	movaps	XMMWORD[(-160)+rbp],xmm0
	movaps	xmm7,XMMWORD[((-144))+rbp]
	movaps	XMMWORD[(-144)+rbp],xmm0
	movaps	xmm8,XMMWORD[((-128))+rbp]
	movaps	XMMWORD[(-128)+rbp],xmm0
	movaps	xmm9,XMMWORD[((-112))+rbp]
	movaps	XMMWORD[(-112)+rbp],xmm0
	movaps	xmm10,XMMWORD[((-96))+rbp]
	movaps	XMMWORD[(-96)+rbp],xmm0
	movaps	xmm11,XMMWORD[((-80))+rbp]
	movaps	XMMWORD[(-80)+rbp],xmm0
	movaps	xmm12,XMMWORD[((-64))+rbp]
	movaps	XMMWORD[(-64)+rbp],xmm0
	movaps	xmm13,XMMWORD[((-48))+rbp]
	movaps	XMMWORD[(-48)+rbp],xmm0
	movaps	xmm14,XMMWORD[((-32))+rbp]
	movaps	XMMWORD[(-32)+rbp],xmm0
	movaps	xmm15,XMMWORD[((-16))+rbp]
	movaps	XMMWORD[(-16)+rbp],xmm0
	movaps	XMMWORD[rsp],xmm0
	movaps	XMMWORD[16+rsp],xmm0
	movaps	XMMWORD[32+rsp],xmm0
	movaps	XMMWORD[48+rsp],xmm0
	movaps	XMMWORD[64+rsp],xmm0
	movaps	XMMWORD[80+rsp],xmm0
	movaps	XMMWORD[96+rsp],xmm0
	lea	rsp,[rbp]
	pop	rbp
$L$xts_dec_epilogue:
	mov	rdi,QWORD[8+rsp]	;WIN64 epilogue
	mov	rsi,QWORD[16+rsp]
	DB	0F3h,0C3h		;repret
$L$SEH_end_aesni_xts_decrypt:
global	aesni_cbc_encrypt

ALIGN	16
aesni_cbc_encrypt:
	mov	QWORD[8+rsp],rdi	;WIN64 prologue
	mov	QWORD[16+rsp],rsi
	mov	rax,rsp
$L$SEH_begin_aesni_cbc_encrypt:
	mov	rdi,rcx
	mov	rsi,rdx
	mov	rdx,r8
	mov	rcx,r9
	mov	r8,QWORD[40+rsp]
	mov	r9,QWORD[48+rsp]


	test	rdx,rdx
	jz	NEAR $L$cbc_ret

	mov	r10d,DWORD[240+rcx]
	mov	r11,rcx
	test	r9d,r9d
	jz	NEAR $L$cbc_decrypt

	movups	xmm2,XMMWORD[r8]
	mov	eax,r10d
	cmp	rdx,16
	jb	NEAR $L$cbc_enc_tail
	sub	rdx,16
	jmp	NEAR $L$cbc_enc_loop
ALIGN	16
$L$cbc_enc_loop:
	movups	xmm3,XMMWORD[rdi]
	lea	rdi,[16+rdi]

	movups	xmm0,XMMWORD[rcx]
	movups	xmm1,XMMWORD[16+rcx]
	xorps	xmm3,xmm0
	lea	rcx,[32+rcx]
	xorps	xmm2,xmm3
$L$oop_enc1_15:
DB	102,15,56,220,209
	dec	eax
	movups	xmm1,XMMWORD[rcx]
	lea	rcx,[16+rcx]
	jnz	NEAR $L$oop_enc1_15
DB	102,15,56,221,209
	mov	eax,r10d
	mov	rcx,r11
	movups	XMMWORD[rsi],xmm2
	lea	rsi,[16+rsi]
	sub	rdx,16
	jnc	NEAR $L$cbc_enc_loop
	add	rdx,16
	jnz	NEAR $L$cbc_enc_tail
	pxor	xmm0,xmm0
	pxor	xmm1,xmm1
	movups	XMMWORD[r8],xmm2
	pxor	xmm2,xmm2
	pxor	xmm3,xmm3
	jmp	NEAR $L$cbc_ret

$L$cbc_enc_tail:
	mov	rcx,rdx
	xchg	rsi,rdi
	DD	0x9066A4F3
	mov	ecx,16
	sub	rcx,rdx
	xor	eax,eax
	DD	0x9066AAF3
	lea	rdi,[((-16))+rdi]
	mov	eax,r10d
	mov	rsi,rdi
	mov	rcx,r11
	xor	rdx,rdx
	jmp	NEAR $L$cbc_enc_loop

ALIGN	16
$L$cbc_decrypt:
	cmp	rdx,16
	jne	NEAR $L$cbc_decrypt_bulk



	movdqu	xmm2,XMMWORD[rdi]
	movdqu	xmm3,XMMWORD[r8]
	movdqa	xmm4,xmm2
	movups	xmm0,XMMWORD[rcx]
	movups	xmm1,XMMWORD[16+rcx]
	lea	rcx,[32+rcx]
	xorps	xmm2,xmm0
$L$oop_dec1_16:
DB	102,15,56,222,209
	dec	r10d
	movups	xmm1,XMMWORD[rcx]
	lea	rcx,[16+rcx]
	jnz	NEAR $L$oop_dec1_16
DB	102,15,56,223,209
	pxor	xmm0,xmm0
	pxor	xmm1,xmm1
	movdqu	XMMWORD[r8],xmm4
	xorps	xmm2,xmm3
	pxor	xmm3,xmm3
	movups	XMMWORD[rsi],xmm2
	pxor	xmm2,xmm2
	jmp	NEAR $L$cbc_ret
ALIGN	16
$L$cbc_decrypt_bulk:
	lea	rax,[rsp]
	push	rbp
	sub	rsp,176
	and	rsp,-16
	movaps	XMMWORD[16+rsp],xmm6
	movaps	XMMWORD[32+rsp],xmm7
	movaps	XMMWORD[48+rsp],xmm8
	movaps	XMMWORD[64+rsp],xmm9
	movaps	XMMWORD[80+rsp],xmm10
	movaps	XMMWORD[96+rsp],xmm11
	movaps	XMMWORD[112+rsp],xmm12
	movaps	XMMWORD[128+rsp],xmm13
	movaps	XMMWORD[144+rsp],xmm14
	movaps	XMMWORD[160+rsp],xmm15
$L$cbc_decrypt_body:
	lea	rbp,[((-8))+rax]
	movups	xmm10,XMMWORD[r8]
	mov	eax,r10d
	cmp	rdx,0x50
	jbe	NEAR $L$cbc_dec_tail

	movups	xmm0,XMMWORD[rcx]
	movdqu	xmm2,XMMWORD[rdi]
	movdqu	xmm3,XMMWORD[16+rdi]
	movdqa	xmm11,xmm2
	movdqu	xmm4,XMMWORD[32+rdi]
	movdqa	xmm12,xmm3
	movdqu	xmm5,XMMWORD[48+rdi]
	movdqa	xmm13,xmm4
	movdqu	xmm6,XMMWORD[64+rdi]
	movdqa	xmm14,xmm5
	movdqu	xmm7,XMMWORD[80+rdi]
	movdqa	xmm15,xmm6
	mov	r9d,DWORD[((OPENSSL_ia32cap_P+4))]
	cmp	rdx,0x70
	jbe	NEAR $L$cbc_dec_six_or_seven

	and	r9d,71303168
	sub	rdx,0x50
	cmp	r9d,4194304
	je	NEAR $L$cbc_dec_loop6_enter
	sub	rdx,0x20
	lea	rcx,[112+rcx]
	jmp	NEAR $L$cbc_dec_loop8_enter
ALIGN	16
$L$cbc_dec_loop8:
	movups	XMMWORD[rsi],xmm9
	lea	rsi,[16+rsi]
$L$cbc_dec_loop8_enter:
	movdqu	xmm8,XMMWORD[96+rdi]
	pxor	xmm2,xmm0
	movdqu	xmm9,XMMWORD[112+rdi]
	pxor	xmm3,xmm0
	movups	xmm1,XMMWORD[((16-112))+rcx]
	pxor	xmm4,xmm0
	xor	r11,r11
	cmp	rdx,0x70
	pxor	xmm5,xmm0
	pxor	xmm6,xmm0
	pxor	xmm7,xmm0
	pxor	xmm8,xmm0

DB	102,15,56,222,209
	pxor	xmm9,xmm0
	movups	xmm0,XMMWORD[((32-112))+rcx]
DB	102,15,56,222,217
DB	102,15,56,222,225
DB	102,15,56,222,233
DB	102,15,56,222,241
DB	102,15,56,222,249
DB	102,68,15,56,222,193
	setnc	r11b
	shl	r11,7
DB	102,68,15,56,222,201
	add	r11,rdi
	movups	xmm1,XMMWORD[((48-112))+rcx]
DB	102,15,56,222,208
DB	102,15,56,222,216
DB	102,15,56,222,224
DB	102,15,56,222,232
DB	102,15,56,222,240
DB	102,15,56,222,248
DB	102,68,15,56,222,192
DB	102,68,15,56,222,200
	movups	xmm0,XMMWORD[((64-112))+rcx]
	nop
DB	102,15,56,222,209
DB	102,15,56,222,217
DB	102,15,56,222,225
DB	102,15,56,222,233
DB	102,15,56,222,241
DB	102,15,56,222,249
DB	102,68,15,56,222,193
DB	102,68,15,56,222,201
	movups	xmm1,XMMWORD[((80-112))+rcx]
	nop
DB	102,15,56,222,208
DB	102,15,56,222,216
DB	102,15,56,222,224
DB	102,15,56,222,232
DB	102,15,56,222,240
DB	102,15,56,222,248
DB	102,68,15,56,222,192
DB	102,68,15,56,222,200
	movups	xmm0,XMMWORD[((96-112))+rcx]
	nop
DB	102,15,56,222,209
DB	102,15,56,222,217
DB	102,15,56,222,225
DB	102,15,56,222,233
DB	102,15,56,222,241
DB	102,15,56,222,249
DB	102,68,15,56,222,193
DB	102,68,15,56,222,201
	movups	xmm1,XMMWORD[((112-112))+rcx]
	nop
DB	102,15,56,222,208
DB	102,15,56,222,216
DB	102,15,56,222,224
DB	102,15,56,222,232
DB	102,15,56,222,240
DB	102,15,56,222,248
DB	102,68,15,56,222,192
DB	102,68,15,56,222,200
	movups	xmm0,XMMWORD[((128-112))+rcx]
	nop
DB	102,15,56,222,209
DB	102,15,56,222,217
DB	102,15,56,222,225
DB	102,15,56,222,233
DB	102,15,56,222,241
DB	102,15,56,222,249
DB	102,68,15,56,222,193
DB	102,68,15,56,222,201
	movups	xmm1,XMMWORD[((144-112))+rcx]
	cmp	eax,11
DB	102,15,56,222,208
DB	102,15,56,222,216
DB	102,15,56,222,224
DB	102,15,56,222,232
DB	102,15,56,222,240
DB	102,15,56,222,248
DB	102,68,15,56,222,192
DB	102,68,15,56,222,200
	movups	xmm0,XMMWORD[((160-112))+rcx]
	jb	NEAR $L$cbc_dec_done
DB	102,15,56,222,209
DB	102,15,56,222,217
DB	102,15,56,222,225
DB	102,15,56,222,233
DB	102,15,56,222,241
DB	102,15,56,222,249
DB	102,68,15,56,222,193
DB	102,68,15,56,222,201
	movups	xmm1,XMMWORD[((176-112))+rcx]
	nop
DB	102,15,56,222,208
DB	102,15,56,222,216
DB	102,15,56,222,224
DB	102,15,56,222,232
DB	102,15,56,222,240
DB	102,15,56,222,248
DB	102,68,15,56,222,192
DB	102,68,15,56,222,200
	movups	xmm0,XMMWORD[((192-112))+rcx]
	je	NEAR $L$cbc_dec_done
DB	102,15,56,222,209
DB	102,15,56,222,217
DB	102,15,56,222,225
DB	102,15,56,222,233
DB	102,15,56,222,241
DB	102,15,56,222,249
DB	102,68,15,56,222,193
DB	102,68,15,56,222,201
	movups	xmm1,XMMWORD[((208-112))+rcx]
	nop
DB	102,15,56,222,208
DB	102,15,56,222,216
DB	102,15,56,222,224
DB	102,15,56,222,232
DB	102,15,56,222,240
DB	102,15,56,222,248
DB	102,68,15,56,222,192
DB	102,68,15,56,222,200
	movups	xmm0,XMMWORD[((224-112))+rcx]
	jmp	NEAR $L$cbc_dec_done
ALIGN	16
$L$cbc_dec_done:
DB	102,15,56,222,209
DB	102,15,56,222,217
	pxor	xmm10,xmm0
	pxor	xmm11,xmm0
DB	102,15,56,222,225
DB	102,15,56,222,233
	pxor	xmm12,xmm0
	pxor	xmm13,xmm0
DB	102,15,56,222,241
DB	102,15,56,222,249
	pxor	xmm14,xmm0
	pxor	xmm15,xmm0
DB	102,68,15,56,222,193
DB	102,68,15,56,222,201
	movdqu	xmm1,XMMWORD[80+rdi]

DB	102,65,15,56,223,210
	movdqu	xmm10,XMMWORD[96+rdi]
	pxor	xmm1,xmm0
DB	102,65,15,56,223,219
	pxor	xmm10,xmm0
	movdqu	xmm0,XMMWORD[112+rdi]
DB	102,65,15,56,223,228
	lea	rdi,[128+rdi]
	movdqu	xmm11,XMMWORD[r11]
DB	102,65,15,56,223,237
DB	102,65,15,56,223,246
	movdqu	xmm12,XMMWORD[16+r11]
	movdqu	xmm13,XMMWORD[32+r11]
DB	102,65,15,56,223,255
DB	102,68,15,56,223,193
	movdqu	xmm14,XMMWORD[48+r11]
	movdqu	xmm15,XMMWORD[64+r11]
DB	102,69,15,56,223,202
	movdqa	xmm10,xmm0
	movdqu	xmm1,XMMWORD[80+r11]
	movups	xmm0,XMMWORD[((-112))+rcx]

	movups	XMMWORD[rsi],xmm2
	movdqa	xmm2,xmm11
	movups	XMMWORD[16+rsi],xmm3
	movdqa	xmm3,xmm12
	movups	XMMWORD[32+rsi],xmm4
	movdqa	xmm4,xmm13
	movups	XMMWORD[48+rsi],xmm5
	movdqa	xmm5,xmm14
	movups	XMMWORD[64+rsi],xmm6
	movdqa	xmm6,xmm15
	movups	XMMWORD[80+rsi],xmm7
	movdqa	xmm7,xmm1
	movups	XMMWORD[96+rsi],xmm8
	lea	rsi,[112+rsi]

	sub	rdx,0x80
	ja	NEAR $L$cbc_dec_loop8

	movaps	xmm2,xmm9
	lea	rcx,[((-112))+rcx]
	add	rdx,0x70
	jle	NEAR $L$cbc_dec_clear_tail_collected
	movups	XMMWORD[rsi],xmm9
	lea	rsi,[16+rsi]
	cmp	rdx,0x50
	jbe	NEAR $L$cbc_dec_tail

	movaps	xmm2,xmm11
$L$cbc_dec_six_or_seven:
	cmp	rdx,0x60
	ja	NEAR $L$cbc_dec_seven

	movaps	xmm8,xmm7
	call	_aesni_decrypt6
	pxor	xmm2,xmm10
	movaps	xmm10,xmm8
	pxor	xmm3,xmm11
	movdqu	XMMWORD[rsi],xmm2
	pxor	xmm4,xmm12
	movdqu	XMMWORD[16+rsi],xmm3
	pxor	xmm3,xmm3
	pxor	xmm5,xmm13
	movdqu	XMMWORD[32+rsi],xmm4
	pxor	xmm4,xmm4
	pxor	xmm6,xmm14
	movdqu	XMMWORD[48+rsi],xmm5
	pxor	xmm5,xmm5
	pxor	xmm7,xmm15
	movdqu	XMMWORD[64+rsi],xmm6
	pxor	xmm6,xmm6
	lea	rsi,[80+rsi]
	movdqa	xmm2,xmm7
	pxor	xmm7,xmm7
	jmp	NEAR $L$cbc_dec_tail_collected

ALIGN	16
$L$cbc_dec_seven:
	movups	xmm8,XMMWORD[96+rdi]
	xorps	xmm9,xmm9
	call	_aesni_decrypt8
	movups	xmm9,XMMWORD[80+rdi]
	pxor	xmm2,xmm10
	movups	xmm10,XMMWORD[96+rdi]
	pxor	xmm3,xmm11
	movdqu	XMMWORD[rsi],xmm2
	pxor	xmm4,xmm12
	movdqu	XMMWORD[16+rsi],xmm3
	pxor	xmm3,xmm3
	pxor	xmm5,xmm13
	movdqu	XMMWORD[32+rsi],xmm4
	pxor	xmm4,xmm4
	pxor	xmm6,xmm14
	movdqu	XMMWORD[48+rsi],xmm5
	pxor	xmm5,xmm5
	pxor	xmm7,xmm15
	movdqu	XMMWORD[64+rsi],xmm6
	pxor	xmm6,xmm6
	pxor	xmm8,xmm9
	movdqu	XMMWORD[80+rsi],xmm7
	pxor	xmm7,xmm7
	lea	rsi,[96+rsi]
	movdqa	xmm2,xmm8
	pxor	xmm8,xmm8
	pxor	xmm9,xmm9
	jmp	NEAR $L$cbc_dec_tail_collected

ALIGN	16
$L$cbc_dec_loop6:
	movups	XMMWORD[rsi],xmm7
	lea	rsi,[16+rsi]
	movdqu	xmm2,XMMWORD[rdi]
	movdqu	xmm3,XMMWORD[16+rdi]
	movdqa	xmm11,xmm2
	movdqu	xmm4,XMMWORD[32+rdi]
	movdqa	xmm12,xmm3
	movdqu	xmm5,XMMWORD[48+rdi]
	movdqa	xmm13,xmm4
	movdqu	xmm6,XMMWORD[64+rdi]
	movdqa	xmm14,xmm5
	movdqu	xmm7,XMMWORD[80+rdi]
	movdqa	xmm15,xmm6
$L$cbc_dec_loop6_enter:
	lea	rdi,[96+rdi]
	movdqa	xmm8,xmm7

	call	_aesni_decrypt6

	pxor	xmm2,xmm10
	movdqa	xmm10,xmm8
	pxor	xmm3,xmm11
	movdqu	XMMWORD[rsi],xmm2
	pxor	xmm4,xmm12
	movdqu	XMMWORD[16+rsi],xmm3
	pxor	xmm5,xmm13
	movdqu	XMMWORD[32+rsi],xmm4
	pxor	xmm6,xmm14
	mov	rcx,r11
	movdqu	XMMWORD[48+rsi],xmm5
	pxor	xmm7,xmm15
	mov	eax,r10d
	movdqu	XMMWORD[64+rsi],xmm6
	lea	rsi,[80+rsi]
	sub	rdx,0x60
	ja	NEAR $L$cbc_dec_loop6

	movdqa	xmm2,xmm7
	add	rdx,0x50
	jle	NEAR $L$cbc_dec_clear_tail_collected
	movups	XMMWORD[rsi],xmm7
	lea	rsi,[16+rsi]

$L$cbc_dec_tail:
	movups	xmm2,XMMWORD[rdi]
	sub	rdx,0x10
	jbe	NEAR $L$cbc_dec_one

	movups	xmm3,XMMWORD[16+rdi]
	movaps	xmm11,xmm2
	sub	rdx,0x10
	jbe	NEAR $L$cbc_dec_two

	movups	xmm4,XMMWORD[32+rdi]
	movaps	xmm12,xmm3
	sub	rdx,0x10
	jbe	NEAR $L$cbc_dec_three

	movups	xmm5,XMMWORD[48+rdi]
	movaps	xmm13,xmm4
	sub	rdx,0x10
	jbe	NEAR $L$cbc_dec_four

	movups	xmm6,XMMWORD[64+rdi]
	movaps	xmm14,xmm5
	movaps	xmm15,xmm6
	xorps	xmm7,xmm7
	call	_aesni_decrypt6
	pxor	xmm2,xmm10
	movaps	xmm10,xmm15
	pxor	xmm3,xmm11
	movdqu	XMMWORD[rsi],xmm2
	pxor	xmm4,xmm12
	movdqu	XMMWORD[16+rsi],xmm3
	pxor	xmm3,xmm3
	pxor	xmm5,xmm13
	movdqu	XMMWORD[32+rsi],xmm4
	pxor	xmm4,xmm4
	pxor	xmm6,xmm14
	movdqu	XMMWORD[48+rsi],xmm5
	pxor	xmm5,xmm5
	lea	rsi,[64+rsi]
	movdqa	xmm2,xmm6
	pxor	xmm6,xmm6
	pxor	xmm7,xmm7
	sub	rdx,0x10
	jmp	NEAR $L$cbc_dec_tail_collected

ALIGN	16
$L$cbc_dec_one:
	movaps	xmm11,xmm2
	movups	xmm0,XMMWORD[rcx]
	movups	xmm1,XMMWORD[16+rcx]
	lea	rcx,[32+rcx]
	xorps	xmm2,xmm0
$L$oop_dec1_17:
DB	102,15,56,222,209
	dec	eax
	movups	xmm1,XMMWORD[rcx]
	lea	rcx,[16+rcx]
	jnz	NEAR $L$oop_dec1_17
DB	102,15,56,223,209
	xorps	xmm2,xmm10
	movaps	xmm10,xmm11
	jmp	NEAR $L$cbc_dec_tail_collected
ALIGN	16
$L$cbc_dec_two:
	movaps	xmm12,xmm3
	call	_aesni_decrypt2
	pxor	xmm2,xmm10
	movaps	xmm10,xmm12
	pxor	xmm3,xmm11
	movdqu	XMMWORD[rsi],xmm2
	movdqa	xmm2,xmm3
	pxor	xmm3,xmm3
	lea	rsi,[16+rsi]
	jmp	NEAR $L$cbc_dec_tail_collected
ALIGN	16
$L$cbc_dec_three:
	movaps	xmm13,xmm4
	call	_aesni_decrypt3
	pxor	xmm2,xmm10
	movaps	xmm10,xmm13
	pxor	xmm3,xmm11
	movdqu	XMMWORD[rsi],xmm2
	pxor	xmm4,xmm12
	movdqu	XMMWORD[16+rsi],xmm3
	pxor	xmm3,xmm3
	movdqa	xmm2,xmm4
	pxor	xmm4,xmm4
	lea	rsi,[32+rsi]
	jmp	NEAR $L$cbc_dec_tail_collected
ALIGN	16
$L$cbc_dec_four:
	movaps	xmm14,xmm5
	call	_aesni_decrypt4
	pxor	xmm2,xmm10
	movaps	xmm10,xmm14
	pxor	xmm3,xmm11
	movdqu	XMMWORD[rsi],xmm2
	pxor	xmm4,xmm12
	movdqu	XMMWORD[16+rsi],xmm3
	pxor	xmm3,xmm3
	pxor	xmm5,xmm13
	movdqu	XMMWORD[32+rsi],xmm4
	pxor	xmm4,xmm4
	movdqa	xmm2,xmm5
	pxor	xmm5,xmm5
	lea	rsi,[48+rsi]
	jmp	NEAR $L$cbc_dec_tail_collected

ALIGN	16
$L$cbc_dec_clear_tail_collected:
	pxor	xmm3,xmm3
	pxor	xmm4,xmm4
	pxor	xmm5,xmm5
$L$cbc_dec_tail_collected:
	movups	XMMWORD[r8],xmm10
	and	rdx,15
	jnz	NEAR $L$cbc_dec_tail_partial
	movups	XMMWORD[rsi],xmm2
	pxor	xmm2,xmm2
	jmp	NEAR $L$cbc_dec_ret
ALIGN	16
$L$cbc_dec_tail_partial:
	movaps	XMMWORD[rsp],xmm2
	pxor	xmm2,xmm2
	mov	rcx,16
	mov	rdi,rsi
	sub	rcx,rdx
	lea	rsi,[rsp]
	DD	0x9066A4F3
	movdqa	XMMWORD[rsp],xmm2

$L$cbc_dec_ret:
	xorps	xmm0,xmm0
	pxor	xmm1,xmm1
	movaps	xmm6,XMMWORD[16+rsp]
	movaps	XMMWORD[16+rsp],xmm0
	movaps	xmm7,XMMWORD[32+rsp]
	movaps	XMMWORD[32+rsp],xmm0
	movaps	xmm8,XMMWORD[48+rsp]
	movaps	XMMWORD[48+rsp],xmm0
	movaps	xmm9,XMMWORD[64+rsp]
	movaps	XMMWORD[64+rsp],xmm0
	movaps	xmm10,XMMWORD[80+rsp]
	movaps	XMMWORD[80+rsp],xmm0
	movaps	xmm11,XMMWORD[96+rsp]
	movaps	XMMWORD[96+rsp],xmm0
	movaps	xmm12,XMMWORD[112+rsp]
	movaps	XMMWORD[112+rsp],xmm0
	movaps	xmm13,XMMWORD[128+rsp]
	movaps	XMMWORD[128+rsp],xmm0
	movaps	xmm14,XMMWORD[144+rsp]
	movaps	XMMWORD[144+rsp],xmm0
	movaps	xmm15,XMMWORD[160+rsp]
	movaps	XMMWORD[160+rsp],xmm0
	lea	rsp,[rbp]
	pop	rbp
$L$cbc_ret:
	mov	rdi,QWORD[8+rsp]	;WIN64 epilogue
	mov	rsi,QWORD[16+rsp]
	DB	0F3h,0C3h		;repret
$L$SEH_end_aesni_cbc_encrypt:
global	aesni_set_decrypt_key

ALIGN	16
aesni_set_decrypt_key:
DB	0x48,0x83,0xEC,0x08
	call	__aesni_set_encrypt_key
	shl	edx,4
	test	eax,eax
	jnz	NEAR $L$dec_key_ret
	lea	rcx,[16+rdx*1+r8]

	movups	xmm0,XMMWORD[r8]
	movups	xmm1,XMMWORD[rcx]
	movups	XMMWORD[rcx],xmm0
	movups	XMMWORD[r8],xmm1
	lea	r8,[16+r8]
	lea	rcx,[((-16))+rcx]

$L$dec_key_inverse:
	movups	xmm0,XMMWORD[r8]
	movups	xmm1,XMMWORD[rcx]
DB	102,15,56,219,192
DB	102,15,56,219,201
	lea	r8,[16+r8]
	lea	rcx,[((-16))+rcx]
	movups	XMMWORD[16+rcx],xmm0
	movups	XMMWORD[(-16)+r8],xmm1
	cmp	rcx,r8
	ja	NEAR $L$dec_key_inverse

	movups	xmm0,XMMWORD[r8]
DB	102,15,56,219,192
	pxor	xmm1,xmm1
	movups	XMMWORD[rcx],xmm0
	pxor	xmm0,xmm0
$L$dec_key_ret:
	add	rsp,8
	DB	0F3h,0C3h		;repret
$L$SEH_end_set_decrypt_key:

global	aesni_set_encrypt_key

ALIGN	16
aesni_set_encrypt_key:
__aesni_set_encrypt_key:
DB	0x48,0x83,0xEC,0x08
	mov	rax,-1
	test	rcx,rcx
	jz	NEAR $L$enc_key_ret
	test	r8,r8
	jz	NEAR $L$enc_key_ret

	mov	r10d,268437504
	movups	xmm0,XMMWORD[rcx]
	xorps	xmm4,xmm4
	and	r10d,DWORD[((OPENSSL_ia32cap_P+4))]
	lea	rax,[16+r8]
	cmp	edx,256
	je	NEAR $L$14rounds
	cmp	edx,192
	je	NEAR $L$12rounds
	cmp	edx,128
	jne	NEAR $L$bad_keybits

$L$10rounds:
	mov	edx,9
	cmp	r10d,268435456
	je	NEAR $L$10rounds_alt

	movups	XMMWORD[r8],xmm0
DB	102,15,58,223,200,1
	call	$L$key_expansion_128_cold
DB	102,15,58,223,200,2
	call	$L$key_expansion_128
DB	102,15,58,223,200,4
	call	$L$key_expansion_128
DB	102,15,58,223,200,8
	call	$L$key_expansion_128
DB	102,15,58,223,200,16
	call	$L$key_expansion_128
DB	102,15,58,223,200,32
	call	$L$key_expansion_128
DB	102,15,58,223,200,64
	call	$L$key_expansion_128
DB	102,15,58,223,200,128
	call	$L$key_expansion_128
DB	102,15,58,223,200,27
	call	$L$key_expansion_128
DB	102,15,58,223,200,54
	call	$L$key_expansion_128
	movups	XMMWORD[rax],xmm0
	mov	DWORD[80+rax],edx
	xor	eax,eax
	jmp	NEAR $L$enc_key_ret

ALIGN	16
$L$10rounds_alt:
	movdqa	xmm5,XMMWORD[$L$key_rotate]
	mov	r10d,8
	movdqa	xmm4,XMMWORD[$L$key_rcon1]
	movdqa	xmm2,xmm0
	movdqu	XMMWORD[r8],xmm0
	jmp	NEAR $L$oop_key128

ALIGN	16
$L$oop_key128:
DB	102,15,56,0,197
DB	102,15,56,221,196
	pslld	xmm4,1
	lea	rax,[16+rax]

	movdqa	xmm3,xmm2
	pslldq	xmm2,4
	pxor	xmm3,xmm2
	pslldq	xmm2,4
	pxor	xmm3,xmm2
	pslldq	xmm2,4
	pxor	xmm2,xmm3

	pxor	xmm0,xmm2
	movdqu	XMMWORD[(-16)+rax],xmm0
	movdqa	xmm2,xmm0

	dec	r10d
	jnz	NEAR $L$oop_key128

	movdqa	xmm4,XMMWORD[$L$key_rcon1b]

DB	102,15,56,0,197
DB	102,15,56,221,196
	pslld	xmm4,1

	movdqa	xmm3,xmm2
	pslldq	xmm2,4
	pxor	xmm3,xmm2
	pslldq	xmm2,4
	pxor	xmm3,xmm2
	pslldq	xmm2,4
	pxor	xmm2,xmm3

	pxor	xmm0,xmm2
	movdqu	XMMWORD[rax],xmm0

	movdqa	xmm2,xmm0
DB	102,15,56,0,197
DB	102,15,56,221,196

	movdqa	xmm3,xmm2
	pslldq	xmm2,4
	pxor	xmm3,xmm2
	pslldq	xmm2,4
	pxor	xmm3,xmm2
	pslldq	xmm2,4
	pxor	xmm2,xmm3

	pxor	xmm0,xmm2
	movdqu	XMMWORD[16+rax],xmm0

	mov	DWORD[96+rax],edx
	xor	eax,eax
	jmp	NEAR $L$enc_key_ret

ALIGN	16
$L$12rounds:
	movq	xmm2,QWORD[16+rcx]
	mov	edx,11
	cmp	r10d,268435456
	je	NEAR $L$12rounds_alt

	movups	XMMWORD[r8],xmm0
DB	102,15,58,223,202,1
	call	$L$key_expansion_192a_cold
DB	102,15,58,223,202,2
	call	$L$key_expansion_192b
DB	102,15,58,223,202,4
	call	$L$key_expansion_192a
DB	102,15,58,223,202,8
	call	$L$key_expansion_192b
DB	102,15,58,223,202,16
	call	$L$key_expansion_192a
DB	102,15,58,223,202,32
	call	$L$key_expansion_192b
DB	102,15,58,223,202,64
	call	$L$key_expansion_192a
DB	102,15,58,223,202,128
	call	$L$key_expansion_192b
	movups	XMMWORD[rax],xmm0
	mov	DWORD[48+rax],edx
	xor	rax,rax
	jmp	NEAR $L$enc_key_ret

ALIGN	16
$L$12rounds_alt:
	movdqa	xmm5,XMMWORD[$L$key_rotate192]
	movdqa	xmm4,XMMWORD[$L$key_rcon1]
	mov	r10d,8
	movdqu	XMMWORD[r8],xmm0
	jmp	NEAR $L$oop_key192

ALIGN	16
$L$oop_key192:
	movq	QWORD[rax],xmm2
	movdqa	xmm1,xmm2
DB	102,15,56,0,213
DB	102,15,56,221,212
	pslld	xmm4,1
	lea	rax,[24+rax]

	movdqa	xmm3,xmm0
	pslldq	xmm0,4
	pxor	xmm3,xmm0
	pslldq	xmm0,4
	pxor	xmm3,xmm0
	pslldq	xmm0,4
	pxor	xmm0,xmm3

	pshufd	xmm3,xmm0,0xff
	pxor	xmm3,xmm1
	pslldq	xmm1,4
	pxor	xmm3,xmm1

	pxor	xmm0,xmm2
	pxor	xmm2,xmm3
	movdqu	XMMWORD[(-16)+rax],xmm0

	dec	r10d
	jnz	NEAR $L$oop_key192

	mov	DWORD[32+rax],edx
	xor	eax,eax
	jmp	NEAR $L$enc_key_ret

ALIGN	16
$L$14rounds:
	movups	xmm2,XMMWORD[16+rcx]
	mov	edx,13
	lea	rax,[16+rax]
	cmp	r10d,268435456
	je	NEAR $L$14rounds_alt

	movups	XMMWORD[r8],xmm0
	movups	XMMWORD[16+r8],xmm2
DB	102,15,58,223,202,1
	call	$L$key_expansion_256a_cold
DB	102,15,58,223,200,1
	call	$L$key_expansion_256b
DB	102,15,58,223,202,2
	call	$L$key_expansion_256a
DB	102,15,58,223,200,2
	call	$L$key_expansion_256b
DB	102,15,58,223,202,4
	call	$L$key_expansion_256a
DB	102,15,58,223,200,4
	call	$L$key_expansion_256b
DB	102,15,58,223,202,8
	call	$L$key_expansion_256a
DB	102,15,58,223,200,8
	call	$L$key_expansion_256b
DB	102,15,58,223,202,16
	call	$L$key_expansion_256a
DB	102,15,58,223,200,16
	call	$L$key_expansion_256b
DB	102,15,58,223,202,32
	call	$L$key_expansion_256a
DB	102,15,58,223,200,32
	call	$L$key_expansion_256b
DB	102,15,58,223,202,64
	call	$L$key_expansion_256a
	movups	XMMWORD[rax],xmm0
	mov	DWORD[16+rax],edx
	xor	rax,rax
	jmp	NEAR $L$enc_key_ret

ALIGN	16
$L$14rounds_alt:
	movdqa	xmm5,XMMWORD[$L$key_rotate]
	movdqa	xmm4,XMMWORD[$L$key_rcon1]
	mov	r10d,7
	movdqu	XMMWORD[r8],xmm0
	movdqa	xmm1,xmm2
	movdqu	XMMWORD[16+r8],xmm2
	jmp	NEAR $L$oop_key256

ALIGN	16
$L$oop_key256:
DB	102,15,56,0,213
DB	102,15,56,221,212

	movdqa	xmm3,xmm0
	pslldq	xmm0,4
	pxor	xmm3,xmm0
	pslldq	xmm0,4
	pxor	xmm3,xmm0
	pslldq	xmm0,4
	pxor	xmm0,xmm3
	pslld	xmm4,1

	pxor	xmm0,xmm2
	movdqu	XMMWORD[rax],xmm0

	dec	r10d
	jz	NEAR $L$done_key256

	pshufd	xmm2,xmm0,0xff
	pxor	xmm3,xmm3
DB	102,15,56,221,211

	movdqa	xmm3,xmm1
	pslldq	xmm1,4
	pxor	xmm3,xmm1
	pslldq	xmm1,4
	pxor	xmm3,xmm1
	pslldq	xmm1,4
	pxor	xmm1,xmm3

	pxor	xmm2,xmm1
	movdqu	XMMWORD[16+rax],xmm2
	lea	rax,[32+rax]
	movdqa	xmm1,xmm2

	jmp	NEAR $L$oop_key256

$L$done_key256:
	mov	DWORD[16+rax],edx
	xor	eax,eax
	jmp	NEAR $L$enc_key_ret

ALIGN	16
$L$bad_keybits:
	mov	rax,-2
$L$enc_key_ret:
	pxor	xmm0,xmm0
	pxor	xmm1,xmm1
	pxor	xmm2,xmm2
	pxor	xmm3,xmm3
	pxor	xmm4,xmm4
	pxor	xmm5,xmm5
	add	rsp,8
	DB	0F3h,0C3h		;repret
$L$SEH_end_set_encrypt_key:

ALIGN	16
$L$key_expansion_128:
	movups	XMMWORD[rax],xmm0
	lea	rax,[16+rax]
$L$key_expansion_128_cold:
	shufps	xmm4,xmm0,16
	xorps	xmm0,xmm4
	shufps	xmm4,xmm0,140
	xorps	xmm0,xmm4
	shufps	xmm1,xmm1,255
	xorps	xmm0,xmm1
	DB	0F3h,0C3h		;repret

ALIGN	16
$L$key_expansion_192a:
	movups	XMMWORD[rax],xmm0
	lea	rax,[16+rax]
$L$key_expansion_192a_cold:
	movaps	xmm5,xmm2
$L$key_expansion_192b_warm:
	shufps	xmm4,xmm0,16
	movdqa	xmm3,xmm2
	xorps	xmm0,xmm4
	shufps	xmm4,xmm0,140
	pslldq	xmm3,4
	xorps	xmm0,xmm4
	pshufd	xmm1,xmm1,85
	pxor	xmm2,xmm3
	pxor	xmm0,xmm1
	pshufd	xmm3,xmm0,255
	pxor	xmm2,xmm3
	DB	0F3h,0C3h		;repret

ALIGN	16
$L$key_expansion_192b:
	movaps	xmm3,xmm0
	shufps	xmm5,xmm0,68
	movups	XMMWORD[rax],xmm5
	shufps	xmm3,xmm2,78
	movups	XMMWORD[16+rax],xmm3
	lea	rax,[32+rax]
	jmp	NEAR $L$key_expansion_192b_warm

ALIGN	16
$L$key_expansion_256a:
	movups	XMMWORD[rax],xmm2
	lea	rax,[16+rax]
$L$key_expansion_256a_cold:
	shufps	xmm4,xmm0,16
	xorps	xmm0,xmm4
	shufps	xmm4,xmm0,140
	xorps	xmm0,xmm4
	shufps	xmm1,xmm1,255
	xorps	xmm0,xmm1
	DB	0F3h,0C3h		;repret

ALIGN	16
$L$key_expansion_256b:
	movups	XMMWORD[rax],xmm0
	lea	rax,[16+rax]

	shufps	xmm4,xmm2,16
	xorps	xmm2,xmm4
	shufps	xmm4,xmm2,140
	xorps	xmm2,xmm4
	shufps	xmm1,xmm1,170
	xorps	xmm2,xmm1
	DB	0F3h,0C3h		;repret


ALIGN	64
$L$bswap_mask:
DB	15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,0
$L$increment32:
	DD	6,6,6,0
$L$increment64:
	DD	1,0,0,0
$L$xts_magic:
	DD	0x87,0,1,0
$L$increment1:
DB	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
$L$key_rotate:
	DD	0x0c0f0e0d,0x0c0f0e0d,0x0c0f0e0d,0x0c0f0e0d
$L$key_rotate192:
	DD	0x04070605,0x04070605,0x04070605,0x04070605
$L$key_rcon1:
	DD	1,1,1,1
$L$key_rcon1b:
	DD	0x1b,0x1b,0x1b,0x1b

DB	65,69,83,32,102,111,114,32,73,110,116,101,108,32,65,69
DB	83,45,78,73,44,32,67,82,89,80,84,79,71,65,77,83
DB	32,98,121,32,60,97,112,112,114,111,64,111,112,101,110,115
DB	115,108,46,111,114,103,62,0
ALIGN	64
EXTERN	__imp_RtlVirtualUnwind

ALIGN	16
ecb_ccm64_se_handler:
	push	rsi
	push	rdi
	push	rbx
	push	rbp
	push	r12
	push	r13
	push	r14
	push	r15
	pushfq
	sub	rsp,64

	mov	rax,QWORD[120+r8]
	mov	rbx,QWORD[248+r8]

	mov	rsi,QWORD[8+r9]
	mov	r11,QWORD[56+r9]

	mov	r10d,DWORD[r11]
	lea	r10,[r10*1+rsi]
	cmp	rbx,r10
	jb	NEAR $L$common_seh_tail

	mov	rax,QWORD[152+r8]

	mov	r10d,DWORD[4+r11]
	lea	r10,[r10*1+rsi]
	cmp	rbx,r10
	jae	NEAR $L$common_seh_tail

	lea	rsi,[rax]
	lea	rdi,[512+r8]
	mov	ecx,8
	DD	0xa548f3fc
	lea	rax,[88+rax]

	jmp	NEAR $L$common_seh_tail



ALIGN	16
ctr_xts_se_handler:
	push	rsi
	push	rdi
	push	rbx
	push	rbp
	push	r12
	push	r13
	push	r14
	push	r15
	pushfq
	sub	rsp,64

	mov	rax,QWORD[120+r8]
	mov	rbx,QWORD[248+r8]

	mov	rsi,QWORD[8+r9]
	mov	r11,QWORD[56+r9]

	mov	r10d,DWORD[r11]
	lea	r10,[r10*1+rsi]
	cmp	rbx,r10
	jb	NEAR $L$common_seh_tail

	mov	rax,QWORD[152+r8]

	mov	r10d,DWORD[4+r11]
	lea	r10,[r10*1+rsi]
	cmp	rbx,r10
	jae	NEAR $L$common_seh_tail

	mov	rax,QWORD[160+r8]
	lea	rsi,[((-160))+rax]
	lea	rdi,[512+r8]
	mov	ecx,20
	DD	0xa548f3fc

	jmp	NEAR $L$common_rbp_tail


ALIGN	16
cbc_se_handler:
	push	rsi
	push	rdi
	push	rbx
	push	rbp
	push	r12
	push	r13
	push	r14
	push	r15
	pushfq
	sub	rsp,64

	mov	rax,QWORD[152+r8]
	mov	rbx,QWORD[248+r8]

	lea	r10,[$L$cbc_decrypt_bulk]
	cmp	rbx,r10
	jb	NEAR $L$common_seh_tail

	lea	r10,[$L$cbc_decrypt_body]
	cmp	rbx,r10
	jb	NEAR $L$restore_cbc_rax

	lea	r10,[$L$cbc_ret]
	cmp	rbx,r10
	jae	NEAR $L$common_seh_tail

	lea	rsi,[16+rax]
	lea	rdi,[512+r8]
	mov	ecx,20
	DD	0xa548f3fc

$L$common_rbp_tail:
	mov	rax,QWORD[160+r8]
	mov	rbp,QWORD[rax]
	lea	rax,[8+rax]
	mov	QWORD[160+r8],rbp
	jmp	NEAR $L$common_seh_tail

$L$restore_cbc_rax:
	mov	rax,QWORD[120+r8]

$L$common_seh_tail:
	mov	rdi,QWORD[8+rax]
	mov	rsi,QWORD[16+rax]
	mov	QWORD[152+r8],rax
	mov	QWORD[168+r8],rsi
	mov	QWORD[176+r8],rdi

	mov	rdi,QWORD[40+r9]
	mov	rsi,r8
	mov	ecx,154
	DD	0xa548f3fc

	mov	rsi,r9
	xor	rcx,rcx
	mov	rdx,QWORD[8+rsi]
	mov	r8,QWORD[rsi]
	mov	r9,QWORD[16+rsi]
	mov	r10,QWORD[40+rsi]
	lea	r11,[56+rsi]
	lea	r12,[24+rsi]
	mov	QWORD[32+rsp],r10
	mov	QWORD[40+rsp],r11
	mov	QWORD[48+rsp],r12
	mov	QWORD[56+rsp],rcx
	call	QWORD[__imp_RtlVirtualUnwind]

	mov	eax,1
	add	rsp,64
	popfq
	pop	r15
	pop	r14
	pop	r13
	pop	r12
	pop	rbp
	pop	rbx
	pop	rdi
	pop	rsi
	DB	0F3h,0C3h		;repret


section	.pdata rdata align=4
ALIGN	4
	DD	$L$SEH_begin_aesni_ecb_encrypt wrt ..imagebase
	DD	$L$SEH_end_aesni_ecb_encrypt wrt ..imagebase
	DD	$L$SEH_info_ecb wrt ..imagebase

	DD	$L$SEH_begin_aesni_ccm64_encrypt_blocks wrt ..imagebase
	DD	$L$SEH_end_aesni_ccm64_encrypt_blocks wrt ..imagebase
	DD	$L$SEH_info_ccm64_enc wrt ..imagebase

	DD	$L$SEH_begin_aesni_ccm64_decrypt_blocks wrt ..imagebase
	DD	$L$SEH_end_aesni_ccm64_decrypt_blocks wrt ..imagebase
	DD	$L$SEH_info_ccm64_dec wrt ..imagebase

	DD	$L$SEH_begin_aesni_ctr32_encrypt_blocks wrt ..imagebase
	DD	$L$SEH_end_aesni_ctr32_encrypt_blocks wrt ..imagebase
	DD	$L$SEH_info_ctr32 wrt ..imagebase

	DD	$L$SEH_begin_aesni_xts_encrypt wrt ..imagebase
	DD	$L$SEH_end_aesni_xts_encrypt wrt ..imagebase
	DD	$L$SEH_info_xts_enc wrt ..imagebase

	DD	$L$SEH_begin_aesni_xts_decrypt wrt ..imagebase
	DD	$L$SEH_end_aesni_xts_decrypt wrt ..imagebase
	DD	$L$SEH_info_xts_dec wrt ..imagebase
	DD	$L$SEH_begin_aesni_cbc_encrypt wrt ..imagebase
	DD	$L$SEH_end_aesni_cbc_encrypt wrt ..imagebase
	DD	$L$SEH_info_cbc wrt ..imagebase

	DD	aesni_set_decrypt_key wrt ..imagebase
	DD	$L$SEH_end_set_decrypt_key wrt ..imagebase
	DD	$L$SEH_info_key wrt ..imagebase

	DD	aesni_set_encrypt_key wrt ..imagebase
	DD	$L$SEH_end_set_encrypt_key wrt ..imagebase
	DD	$L$SEH_info_key wrt ..imagebase
section	.xdata rdata align=8
ALIGN	8
$L$SEH_info_ecb:
DB	9,0,0,0
	DD	ecb_ccm64_se_handler wrt ..imagebase
	DD	$L$ecb_enc_body wrt ..imagebase,$L$ecb_enc_ret wrt ..imagebase
$L$SEH_info_ccm64_enc:
DB	9,0,0,0
	DD	ecb_ccm64_se_handler wrt ..imagebase
	DD	$L$ccm64_enc_body wrt ..imagebase,$L$ccm64_enc_ret wrt ..imagebase
$L$SEH_info_ccm64_dec:
DB	9,0,0,0
	DD	ecb_ccm64_se_handler wrt ..imagebase
	DD	$L$ccm64_dec_body wrt ..imagebase,$L$ccm64_dec_ret wrt ..imagebase
$L$SEH_info_ctr32:
DB	9,0,0,0
	DD	ctr_xts_se_handler wrt ..imagebase
	DD	$L$ctr32_body wrt ..imagebase,$L$ctr32_epilogue wrt ..imagebase
$L$SEH_info_xts_enc:
DB	9,0,0,0
	DD	ctr_xts_se_handler wrt ..imagebase
	DD	$L$xts_enc_body wrt ..imagebase,$L$xts_enc_epilogue wrt ..imagebase
$L$SEH_info_xts_dec:
DB	9,0,0,0
	DD	ctr_xts_se_handler wrt ..imagebase
	DD	$L$xts_dec_body wrt ..imagebase,$L$xts_dec_epilogue wrt ..imagebase
$L$SEH_info_cbc:
DB	9,0,0,0
	DD	cbc_se_handler wrt ..imagebase
$L$SEH_info_key:
DB	0x01,0x04,0x01,0x00
DB	0x04,0x02,0x00,0x00
