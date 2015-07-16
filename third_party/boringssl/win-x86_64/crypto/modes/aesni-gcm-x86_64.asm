default	rel
%define XMMWORD
%define YMMWORD
%define ZMMWORD
section	.text code align=64


global	aesni_gcm_encrypt

aesni_gcm_encrypt:
	xor	eax,eax
	DB	0F3h,0C3h		;repret


global	aesni_gcm_decrypt

aesni_gcm_decrypt:
	xor	eax,eax
	DB	0F3h,0C3h		;repret

