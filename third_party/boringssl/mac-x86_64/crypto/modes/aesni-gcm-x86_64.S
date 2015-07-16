#if defined(__x86_64__)
.text	

.globl	_aesni_gcm_encrypt
.private_extern _aesni_gcm_encrypt

_aesni_gcm_encrypt:
	xorl	%eax,%eax
	.byte	0xf3,0xc3


.globl	_aesni_gcm_decrypt
.private_extern _aesni_gcm_decrypt

_aesni_gcm_decrypt:
	xorl	%eax,%eax
	.byte	0xf3,0xc3

#endif
