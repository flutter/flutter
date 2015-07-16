#include "arm_arch.h"

.text
.fpu	neon
.code	32
.global	gcm_init_v8
.type	gcm_init_v8,%function
.align	4
gcm_init_v8:
	vld1.64		{q9},[r1]		@ load H
	vmov.i8		q8,#0xe1
	vext.8		q3,q9,q9,#8
	vshl.i64	q8,q8,#57
	vshr.u64	q10,q8,#63
	vext.8		q8,q10,q8,#8		@ t0=0xc2....01
	vdup.32	q9,d18[1]
	vshr.u64	q11,q3,#63
	vshr.s32	q9,q9,#31		@ broadcast carry bit
	vand		q11,q11,q8
	vshl.i64	q3,q3,#1
	vext.8		q11,q11,q11,#8
	vand		q8,q8,q9
	vorr		q3,q3,q11		@ H<<<=1
	veor		q3,q3,q8		@ twisted H
	vst1.64		{q3},[r0]

	bx	lr
.size	gcm_init_v8,.-gcm_init_v8

.global	gcm_gmult_v8
.type	gcm_gmult_v8,%function
.align	4
gcm_gmult_v8:
	vld1.64		{q9},[r0]		@ load Xi
	vmov.i8		q11,#0xe1
	vld1.64		{q12},[r1]		@ load twisted H
	vshl.u64	q11,q11,#57
#ifndef __ARMEB__
	vrev64.8	q9,q9
#endif
	vext.8		q13,q12,q12,#8
	mov		r3,#0
	vext.8		q3,q9,q9,#8
	mov		r12,#0
	veor		q13,q13,q12		@ Karatsuba pre-processing
	mov		r2,r0
	b		.Lgmult_v8
.size	gcm_gmult_v8,.-gcm_gmult_v8

.global	gcm_ghash_v8
.type	gcm_ghash_v8,%function
.align	4
gcm_ghash_v8:
	vld1.64		{q0},[r0]		@ load [rotated] Xi
	subs		r3,r3,#16
	vmov.i8		q11,#0xe1
	mov		r12,#16
	vld1.64		{q12},[r1]		@ load twisted H
	moveq	r12,#0
	vext.8		q0,q0,q0,#8
	vshl.u64	q11,q11,#57
	vld1.64		{q9},[r2],r12	@ load [rotated] inp
	vext.8		q13,q12,q12,#8
#ifndef __ARMEB__
	vrev64.8	q0,q0
	vrev64.8	q9,q9
#endif
	veor		q13,q13,q12		@ Karatsuba pre-processing
	vext.8		q3,q9,q9,#8
	b		.Loop_v8

.align	4
.Loop_v8:
	vext.8		q10,q0,q0,#8
	veor		q3,q3,q0		@ inp^=Xi
	veor		q9,q9,q10		@ q9 is rotated inp^Xi

.Lgmult_v8:
	.byte	0x86,0x0e,0xa8,0xf2	@ pmull q0,q12,q3		@ H.lo·Xi.lo
	veor		q9,q9,q3		@ Karatsuba pre-processing
	.byte	0x87,0x4e,0xa9,0xf2	@ pmull2 q2,q12,q3		@ H.hi·Xi.hi
	subs		r3,r3,#16
	.byte	0xa2,0x2e,0xaa,0xf2	@ pmull q1,q13,q9		@ (H.lo+H.hi)·(Xi.lo+Xi.hi)
	moveq	r12,#0

	vext.8		q9,q0,q2,#8		@ Karatsuba post-processing
	veor		q10,q0,q2
	veor		q1,q1,q9
	 vld1.64	{q9},[r2],r12	@ load [rotated] inp
	veor		q1,q1,q10
	.byte	0x26,0x4e,0xe0,0xf2	@ pmull q10,q0,q11		@ 1st phase

	vmov		d4,d3		@ Xh|Xm - 256-bit result
	vmov		d3,d0		@ Xm is rotated Xl
#ifndef __ARMEB__
	 vrev64.8	q9,q9
#endif
	veor		q0,q1,q10
	 vext.8		q3,q9,q9,#8

	vext.8		q10,q0,q0,#8		@ 2nd phase
	.byte	0x26,0x0e,0xa0,0xf2	@ pmull q0,q0,q11
	veor		q10,q10,q2
	veor		q0,q0,q10
	bhs		.Loop_v8

#ifndef __ARMEB__
	vrev64.8	q0,q0
#endif
	vext.8		q0,q0,q0,#8
	vst1.64		{q0},[r0]		@ write out Xi

	bx	lr
.size	gcm_ghash_v8,.-gcm_ghash_v8
.asciz  "GHASH for ARMv8, CRYPTOGAMS by <appro@openssl.org>"
.align  2
