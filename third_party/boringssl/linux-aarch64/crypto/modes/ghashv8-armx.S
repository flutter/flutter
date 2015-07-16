#include "arm_arch.h"

.text
.arch	armv8-a+crypto
.global	gcm_init_v8
.type	gcm_init_v8,%function
.align	4
gcm_init_v8:
	ld1		{v17.2d},[x1]		//load H
	movi		v16.16b,#0xe1
	ext		v3.16b,v17.16b,v17.16b,#8
	shl	v16.2d,v16.2d,#57
	ushr	v18.2d,v16.2d,#63
	ext		v16.16b,v18.16b,v16.16b,#8		//t0=0xc2....01
	dup		v17.4s,v17.s[1]
	ushr	v19.2d,v3.2d,#63
	sshr	v17.4s,v17.4s,#31		//broadcast carry bit
	and		v19.16b,v19.16b,v16.16b
	shl	v3.2d,v3.2d,#1
	ext		v19.16b,v19.16b,v19.16b,#8
	and		v16.16b,v16.16b,v17.16b
	orr		v3.16b,v3.16b,v19.16b		//H<<<=1
	eor		v3.16b,v3.16b,v16.16b		//twisted H
	st1		{v3.2d},[x0]

	ret
.size	gcm_init_v8,.-gcm_init_v8

.global	gcm_gmult_v8
.type	gcm_gmult_v8,%function
.align	4
gcm_gmult_v8:
	ld1		{v17.2d},[x0]		//load Xi
	movi		v19.16b,#0xe1
	ld1		{v20.2d},[x1]		//load twisted H
	shl	v19.2d,v19.2d,#57
#ifndef __ARMEB__
	rev64	v17.16b,v17.16b
#endif
	ext		v21.16b,v20.16b,v20.16b,#8
	mov		x3,#0
	ext		v3.16b,v17.16b,v17.16b,#8
	mov		x12,#0
	eor		v21.16b,v21.16b,v20.16b		//Karatsuba pre-processing
	mov		x2,x0
	b		.Lgmult_v8
.size	gcm_gmult_v8,.-gcm_gmult_v8

.global	gcm_ghash_v8
.type	gcm_ghash_v8,%function
.align	4
gcm_ghash_v8:
	ld1		{v0.2d},[x0]		//load [rotated] Xi
	subs		x3,x3,#16
	movi		v19.16b,#0xe1
	mov		x12,#16
	ld1		{v20.2d},[x1]		//load twisted H
	csel	x12,xzr,x12,eq
	ext		v0.16b,v0.16b,v0.16b,#8
	shl	v19.2d,v19.2d,#57
	ld1		{v17.2d},[x2],x12	//load [rotated] inp
	ext		v21.16b,v20.16b,v20.16b,#8
#ifndef __ARMEB__
	rev64	v0.16b,v0.16b
	rev64	v17.16b,v17.16b
#endif
	eor		v21.16b,v21.16b,v20.16b		//Karatsuba pre-processing
	ext		v3.16b,v17.16b,v17.16b,#8
	b		.Loop_v8

.align	4
.Loop_v8:
	ext		v18.16b,v0.16b,v0.16b,#8
	eor		v3.16b,v3.16b,v0.16b		//inp^=Xi
	eor		v17.16b,v17.16b,v18.16b		//v17.16b is rotated inp^Xi

.Lgmult_v8:
	pmull	v0.1q,v20.1d,v3.1d		//H.lo·Xi.lo
	eor		v17.16b,v17.16b,v3.16b		//Karatsuba pre-processing
	pmull2	v2.1q,v20.2d,v3.2d		//H.hi·Xi.hi
	subs		x3,x3,#16
	pmull	v1.1q,v21.1d,v17.1d		//(H.lo+H.hi)·(Xi.lo+Xi.hi)
	csel	x12,xzr,x12,eq

	ext		v17.16b,v0.16b,v2.16b,#8		//Karatsuba post-processing
	eor		v18.16b,v0.16b,v2.16b
	eor		v1.16b,v1.16b,v17.16b
	 ld1	{v17.2d},[x2],x12	//load [rotated] inp
	eor		v1.16b,v1.16b,v18.16b
	pmull	v18.1q,v0.1d,v19.1d		//1st phase

	ins	v2.d[0],v1.d[1]
	ins	v1.d[1],v0.d[0]
#ifndef __ARMEB__
	 rev64	v17.16b,v17.16b
#endif
	eor		v0.16b,v1.16b,v18.16b
	 ext		v3.16b,v17.16b,v17.16b,#8

	ext		v18.16b,v0.16b,v0.16b,#8		//2nd phase
	pmull	v0.1q,v0.1d,v19.1d
	eor		v18.16b,v18.16b,v2.16b
	eor		v0.16b,v0.16b,v18.16b
	b.hs		.Loop_v8

#ifndef __ARMEB__
	rev64	v0.16b,v0.16b
#endif
	ext		v0.16b,v0.16b,v0.16b,#8
	st1		{v0.2d},[x0]		//write out Xi

	ret
.size	gcm_ghash_v8,.-gcm_ghash_v8
.asciz  "GHASH for ARMv8, CRYPTOGAMS by <appro@openssl.org>"
.align  2
