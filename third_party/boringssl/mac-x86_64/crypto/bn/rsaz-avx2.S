#if defined(__x86_64__)
.text	

.globl	_rsaz_avx2_eligible
.private_extern _rsaz_avx2_eligible

_rsaz_avx2_eligible:
	xorl	%eax,%eax
	.byte	0xf3,0xc3


.globl	_rsaz_1024_sqr_avx2
.private_extern _rsaz_1024_sqr_avx2
.globl	_rsaz_1024_mul_avx2
.private_extern _rsaz_1024_mul_avx2
.globl	_rsaz_1024_norm2red_avx2
.private_extern _rsaz_1024_norm2red_avx2
.globl	_rsaz_1024_red2norm_avx2
.private_extern _rsaz_1024_red2norm_avx2
.globl	_rsaz_1024_scatter5_avx2
.private_extern _rsaz_1024_scatter5_avx2
.globl	_rsaz_1024_gather5_avx2
.private_extern _rsaz_1024_gather5_avx2

_rsaz_1024_sqr_avx2:
_rsaz_1024_mul_avx2:
_rsaz_1024_norm2red_avx2:
_rsaz_1024_red2norm_avx2:
_rsaz_1024_scatter5_avx2:
_rsaz_1024_gather5_avx2:
.byte	0x0f,0x0b
	.byte	0xf3,0xc3

#endif
