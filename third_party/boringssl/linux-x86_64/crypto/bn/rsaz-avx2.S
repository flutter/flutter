#if defined(__x86_64__)
.text	

.globl	rsaz_avx2_eligible
.hidden rsaz_avx2_eligible
.type	rsaz_avx2_eligible,@function
rsaz_avx2_eligible:
	xorl	%eax,%eax
	.byte	0xf3,0xc3
.size	rsaz_avx2_eligible,.-rsaz_avx2_eligible

.globl	rsaz_1024_sqr_avx2
.hidden rsaz_1024_sqr_avx2
.globl	rsaz_1024_mul_avx2
.hidden rsaz_1024_mul_avx2
.globl	rsaz_1024_norm2red_avx2
.hidden rsaz_1024_norm2red_avx2
.globl	rsaz_1024_red2norm_avx2
.hidden rsaz_1024_red2norm_avx2
.globl	rsaz_1024_scatter5_avx2
.hidden rsaz_1024_scatter5_avx2
.globl	rsaz_1024_gather5_avx2
.hidden rsaz_1024_gather5_avx2
.type	rsaz_1024_sqr_avx2,@function
rsaz_1024_sqr_avx2:
rsaz_1024_mul_avx2:
rsaz_1024_norm2red_avx2:
rsaz_1024_red2norm_avx2:
rsaz_1024_scatter5_avx2:
rsaz_1024_gather5_avx2:
.byte	0x0f,0x0b
	.byte	0xf3,0xc3
.size	rsaz_1024_sqr_avx2,.-rsaz_1024_sqr_avx2
#endif
