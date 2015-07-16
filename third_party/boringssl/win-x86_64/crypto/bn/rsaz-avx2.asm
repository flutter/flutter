default	rel
%define XMMWORD
%define YMMWORD
%define ZMMWORD
section	.text code align=64


global	rsaz_avx2_eligible

rsaz_avx2_eligible:
	xor	eax,eax
	DB	0F3h,0C3h		;repret


global	rsaz_1024_sqr_avx2
global	rsaz_1024_mul_avx2
global	rsaz_1024_norm2red_avx2
global	rsaz_1024_red2norm_avx2
global	rsaz_1024_scatter5_avx2
global	rsaz_1024_gather5_avx2

rsaz_1024_sqr_avx2:
rsaz_1024_mul_avx2:
rsaz_1024_norm2red_avx2:
rsaz_1024_red2norm_avx2:
rsaz_1024_scatter5_avx2:
rsaz_1024_gather5_avx2:
DB	0x0f,0x0b
	DB	0F3h,0C3h		;repret

