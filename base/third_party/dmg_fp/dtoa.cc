/****************************************************************
 *
 * The author of this software is David M. Gay.
 *
 * Copyright (c) 1991, 2000, 2001 by Lucent Technologies.
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose without fee is hereby granted, provided that this entire notice
 * is included in all copies of any software which is or includes a copy
 * or modification of this software and in all copies of the supporting
 * documentation for such software.
 *
 * THIS SOFTWARE IS BEING PROVIDED "AS IS", WITHOUT ANY EXPRESS OR IMPLIED
 * WARRANTY.  IN PARTICULAR, NEITHER THE AUTHOR NOR LUCENT MAKES ANY
 * REPRESENTATION OR WARRANTY OF ANY KIND CONCERNING THE MERCHANTABILITY
 * OF THIS SOFTWARE OR ITS FITNESS FOR ANY PARTICULAR PURPOSE.
 *
 ***************************************************************/

/* Please send bug reports to David M. Gay (dmg at acm dot org,
 * with " at " changed at "@" and " dot " changed to ".").	*/

/* On a machine with IEEE extended-precision registers, it is
 * necessary to specify double-precision (53-bit) rounding precision
 * before invoking strtod or dtoa.  If the machine uses (the equivalent
 * of) Intel 80x87 arithmetic, the call
 *	_control87(PC_53, MCW_PC);
 * does this with many compilers.  Whether this or another call is
 * appropriate depends on the compiler; for this to work, it may be
 * necessary to #include "float.h" or another system-dependent header
 * file.
 */

/* strtod for IEEE-, VAX-, and IBM-arithmetic machines.
 *
 * This strtod returns a nearest machine number to the input decimal
 * string (or sets errno to ERANGE).  With IEEE arithmetic, ties are
 * broken by the IEEE round-even rule.  Otherwise ties are broken by
 * biased rounding (add half and chop).
 *
 * Inspired loosely by William D. Clinger's paper "How to Read Floating
 * Point Numbers Accurately" [Proc. ACM SIGPLAN '90, pp. 92-101].
 *
 * Modifications:
 *
 *	1. We only require IEEE, IBM, or VAX double-precision
 *		arithmetic (not IEEE double-extended).
 *	2. We get by with floating-point arithmetic in a case that
 *		Clinger missed -- when we're computing d * 10^n
 *		for a small integer d and the integer n is not too
 *		much larger than 22 (the maximum integer k for which
 *		we can represent 10^k exactly), we may be able to
 *		compute (d*10^k) * 10^(e-k) with just one roundoff.
 *	3. Rather than a bit-at-a-time adjustment of the binary
 *		result in the hard case, we use floating-point
 *		arithmetic to determine the adjustment to within
 *		one bit; only in really hard cases do we need to
 *		compute a second residual.
 *	4. Because of 3., we don't need a large table of powers of 10
 *		for ten-to-e (just some small tables, e.g. of 10^k
 *		for 0 <= k <= 22).
 */

/*
 * #define IEEE_8087 for IEEE-arithmetic machines where the least
 *	significant byte has the lowest address.
 * #define IEEE_MC68k for IEEE-arithmetic machines where the most
 *	significant byte has the lowest address.
 * #define Long int on machines with 32-bit ints and 64-bit longs.
 * #define IBM for IBM mainframe-style floating-point arithmetic.
 * #define VAX for VAX-style floating-point arithmetic (D_floating).
 * #define No_leftright to omit left-right logic in fast floating-point
 *	computation of dtoa.
 * #define Honor_FLT_ROUNDS if FLT_ROUNDS can assume the values 2 or 3
 *	and strtod and dtoa should round accordingly.  Unless Trust_FLT_ROUNDS
 *	is also #defined, fegetround() will be queried for the rounding mode.
 *	Note that both FLT_ROUNDS and fegetround() are specified by the C99
 *	standard (and are specified to be consistent, with fesetround()
 *	affecting the value of FLT_ROUNDS), but that some (Linux) systems
 *	do not work correctly in this regard, so using fegetround() is more
 *	portable than using FLT_FOUNDS directly.
 * #define Check_FLT_ROUNDS if FLT_ROUNDS can assume the values 2 or 3
 *	and Honor_FLT_ROUNDS is not #defined.
 * #define RND_PRODQUOT to use rnd_prod and rnd_quot (assembly routines
 *	that use extended-precision instructions to compute rounded
 *	products and quotients) with IBM.
 * #define ROUND_BIASED for IEEE-format with biased rounding.
 * #define Inaccurate_Divide for IEEE-format with correctly rounded
 *	products but inaccurate quotients, e.g., for Intel i860.
 * #define NO_LONG_LONG on machines that do not have a "long long"
 *	integer type (of >= 64 bits).  On such machines, you can
 *	#define Just_16 to store 16 bits per 32-bit Long when doing
 *	high-precision integer arithmetic.  Whether this speeds things
 *	up or slows things down depends on the machine and the number
 *	being converted.  If long long is available and the name is
 *	something other than "long long", #define Llong to be the name,
 *	and if "unsigned Llong" does not work as an unsigned version of
 *	Llong, #define #ULLong to be the corresponding unsigned type.
 * #define KR_headers for old-style C function headers.
 * #define Bad_float_h if your system lacks a float.h or if it does not
 *	define some or all of DBL_DIG, DBL_MAX_10_EXP, DBL_MAX_EXP,
 *	FLT_RADIX, FLT_ROUNDS, and DBL_MAX.
 * #define MALLOC your_malloc, where your_malloc(n) acts like malloc(n)
 *	if memory is available and otherwise does something you deem
 *	appropriate.  If MALLOC is undefined, malloc will be invoked
 *	directly -- and assumed always to succeed.  Similarly, if you
 *	want something other than the system's free() to be called to
 *	recycle memory acquired from MALLOC, #define FREE to be the
 *	name of the alternate routine.  (FREE or free is only called in
 *	pathological cases, e.g., in a dtoa call after a dtoa return in
 *	mode 3 with thousands of digits requested.)
 * #define Omit_Private_Memory to omit logic (added Jan. 1998) for making
 *	memory allocations from a private pool of memory when possible.
 *	When used, the private pool is PRIVATE_MEM bytes long:  2304 bytes,
 *	unless #defined to be a different length.  This default length
 *	suffices to get rid of MALLOC calls except for unusual cases,
 *	such as decimal-to-binary conversion of a very long string of
 *	digits.  The longest string dtoa can return is about 751 bytes
 *	long.  For conversions by strtod of strings of 800 digits and
 *	all dtoa conversions in single-threaded executions with 8-byte
 *	pointers, PRIVATE_MEM >= 7400 appears to suffice; with 4-byte
 *	pointers, PRIVATE_MEM >= 7112 appears adequate.
 * #define NO_INFNAN_CHECK if you do not wish to have INFNAN_CHECK
 *	#defined automatically on IEEE systems.  On such systems,
 *	when INFNAN_CHECK is #defined, strtod checks
 *	for Infinity and NaN (case insensitively).  On some systems
 *	(e.g., some HP systems), it may be necessary to #define NAN_WORD0
 *	appropriately -- to the most significant word of a quiet NaN.
 *	(On HP Series 700/800 machines, -DNAN_WORD0=0x7ff40000 works.)
 *	When INFNAN_CHECK is #defined and No_Hex_NaN is not #defined,
 *	strtod also accepts (case insensitively) strings of the form
 *	NaN(x), where x is a string of hexadecimal digits and spaces;
 *	if there is only one string of hexadecimal digits, it is taken
 *	for the 52 fraction bits of the resulting NaN; if there are two
 *	or more strings of hex digits, the first is for the high 20 bits,
 *	the second and subsequent for the low 32 bits, with intervening
 *	white space ignored; but if this results in none of the 52
 *	fraction bits being on (an IEEE Infinity symbol), then NAN_WORD0
 *	and NAN_WORD1 are used instead.
 * #define MULTIPLE_THREADS if the system offers preemptively scheduled
 *	multiple threads.  In this case, you must provide (or suitably
 *	#define) two locks, acquired by ACQUIRE_DTOA_LOCK(n) and freed
 *	by FREE_DTOA_LOCK(n) for n = 0 or 1.  (The second lock, accessed
 *	in pow5mult, ensures lazy evaluation of only one copy of high
 *	powers of 5; omitting this lock would introduce a small
 *	probability of wasting memory, but would otherwise be harmless.)
 *	You must also invoke freedtoa(s) to free the value s returned by
 *	dtoa.  You may do so whether or not MULTIPLE_THREADS is #defined.
 * #define NO_IEEE_Scale to disable new (Feb. 1997) logic in strtod that
 *	avoids underflows on inputs whose result does not underflow.
 *	If you #define NO_IEEE_Scale on a machine that uses IEEE-format
 *	floating-point numbers and flushes underflows to zero rather
 *	than implementing gradual underflow, then you must also #define
 *	Sudden_Underflow.
 * #define USE_LOCALE to use the current locale's decimal_point value.
 * #define SET_INEXACT if IEEE arithmetic is being used and extra
 *	computation should be done to set the inexact flag when the
 *	result is inexact and avoid setting inexact when the result
 *	is exact.  In this case, dtoa.c must be compiled in
 *	an environment, perhaps provided by #include "dtoa.c" in a
 *	suitable wrapper, that defines two functions,
 *		int get_inexact(void);
 *		void clear_inexact(void);
 *	such that get_inexact() returns a nonzero value if the
 *	inexact bit is already set, and clear_inexact() sets the
 *	inexact bit to 0.  When SET_INEXACT is #defined, strtod
 *	also does extra computations to set the underflow and overflow
 *	flags when appropriate (i.e., when the result is tiny and
 *	inexact or when it is a numeric value rounded to +-infinity).
 * #define NO_ERRNO if strtod should not assign errno = ERANGE when
 *	the result overflows to +-Infinity or underflows to 0.
 * #define NO_HEX_FP to omit recognition of hexadecimal floating-point
 *	values by strtod.
 * #define NO_STRTOD_BIGCOMP (on IEEE-arithmetic systems only for now)
 *	to disable logic for "fast" testing of very long input strings
 *	to strtod.  This testing proceeds by initially truncating the
 *	input string, then if necessary comparing the whole string with
 *	a decimal expansion to decide close cases. This logic is only
 *	used for input more than STRTOD_DIGLIM digits long (default 40).
 */

#define IEEE_8087
#define NO_HEX_FP

#ifndef Long
#if __LP64__
#define Long int
#else
#define Long long
#endif
#endif
#ifndef ULong
typedef unsigned Long ULong;
#endif

#ifdef DEBUG
#include "stdio.h"
#define Bug(x) {fprintf(stderr, "%s\n", x); exit(1);}
#endif

#include "stdlib.h"
#include "string.h"

#ifdef USE_LOCALE
#include "locale.h"
#endif

#ifdef Honor_FLT_ROUNDS
#ifndef Trust_FLT_ROUNDS
#include <fenv.h>
#endif
#endif

#ifdef MALLOC
#ifdef KR_headers
extern char *MALLOC();
#else
extern void *MALLOC(size_t);
#endif
#else
#define MALLOC malloc
#endif

#ifndef Omit_Private_Memory
#ifndef PRIVATE_MEM
#define PRIVATE_MEM 2304
#endif
#define PRIVATE_mem ((unsigned)((PRIVATE_MEM+sizeof(double)-1)/sizeof(double)))
static double private_mem[PRIVATE_mem], *pmem_next = private_mem;
#endif

#undef IEEE_Arith
#undef Avoid_Underflow
#ifdef IEEE_MC68k
#define IEEE_Arith
#endif
#ifdef IEEE_8087
#define IEEE_Arith
#endif

#ifdef IEEE_Arith
#ifndef NO_INFNAN_CHECK
#undef INFNAN_CHECK
#define INFNAN_CHECK
#endif
#else
#undef INFNAN_CHECK
#define NO_STRTOD_BIGCOMP
#endif

#include "errno.h"

#ifdef Bad_float_h

#ifdef IEEE_Arith
#define DBL_DIG 15
#define DBL_MAX_10_EXP 308
#define DBL_MAX_EXP 1024
#define FLT_RADIX 2
#endif /*IEEE_Arith*/

#ifdef IBM
#define DBL_DIG 16
#define DBL_MAX_10_EXP 75
#define DBL_MAX_EXP 63
#define FLT_RADIX 16
#define DBL_MAX 7.2370055773322621e+75
#endif

#ifdef VAX
#define DBL_DIG 16
#define DBL_MAX_10_EXP 38
#define DBL_MAX_EXP 127
#define FLT_RADIX 2
#define DBL_MAX 1.7014118346046923e+38
#endif

#ifndef LONG_MAX
#define LONG_MAX 2147483647
#endif

#else /* ifndef Bad_float_h */
#include "float.h"
#endif /* Bad_float_h */

#ifndef __MATH_H__
#include "math.h"
#endif

namespace dmg_fp {

#ifndef CONST
#ifdef KR_headers
#define CONST /* blank */
#else
#define CONST const
#endif
#endif

#if defined(IEEE_8087) + defined(IEEE_MC68k) + defined(VAX) + defined(IBM) != 1
Exactly one of IEEE_8087, IEEE_MC68k, VAX, or IBM should be defined.
#endif

typedef union { double d; ULong L[2]; } U;

#ifdef IEEE_8087
#define word0(x) (x)->L[1]
#define word1(x) (x)->L[0]
#else
#define word0(x) (x)->L[0]
#define word1(x) (x)->L[1]
#endif
#define dval(x) (x)->d

#ifndef STRTOD_DIGLIM
#define STRTOD_DIGLIM 40
#endif

#ifdef DIGLIM_DEBUG
extern int strtod_diglim;
#else
#define strtod_diglim STRTOD_DIGLIM
#endif

/* The following definition of Storeinc is appropriate for MIPS processors.
 * An alternative that might be better on some machines is
 * #define Storeinc(a,b,c) (*a++ = b << 16 | c & 0xffff)
 */
#if defined(IEEE_8087) + defined(VAX)
#define Storeinc(a,b,c) (((unsigned short *)a)[1] = (unsigned short)b, \
((unsigned short *)a)[0] = (unsigned short)c, a++)
#else
#define Storeinc(a,b,c) (((unsigned short *)a)[0] = (unsigned short)b, \
((unsigned short *)a)[1] = (unsigned short)c, a++)
#endif

/* #define P DBL_MANT_DIG */
/* Ten_pmax = floor(P*log(2)/log(5)) */
/* Bletch = (highest power of 2 < DBL_MAX_10_EXP) / 16 */
/* Quick_max = floor((P-1)*log(FLT_RADIX)/log(10) - 1) */
/* Int_max = floor(P*log(FLT_RADIX)/log(10) - 1) */

#ifdef IEEE_Arith
#define Exp_shift  20
#define Exp_shift1 20
#define Exp_msk1    0x100000
#define Exp_msk11   0x100000
#define Exp_mask  0x7ff00000
#define P 53
#define Nbits 53
#define Bias 1023
#define Emax 1023
#define Emin (-1022)
#define Exp_1  0x3ff00000
#define Exp_11 0x3ff00000
#define Ebits 11
#define Frac_mask  0xfffff
#define Frac_mask1 0xfffff
#define Ten_pmax 22
#define Bletch 0x10
#define Bndry_mask  0xfffff
#define Bndry_mask1 0xfffff
#define LSB 1
#define Sign_bit 0x80000000
#define Log2P 1
#define Tiny0 0
#define Tiny1 1
#define Quick_max 14
#define Int_max 14
#ifndef NO_IEEE_Scale
#define Avoid_Underflow
#ifdef Flush_Denorm	/* debugging option */
#undef Sudden_Underflow
#endif
#endif

#ifndef Flt_Rounds
#ifdef FLT_ROUNDS
#define Flt_Rounds FLT_ROUNDS
#else
#define Flt_Rounds 1
#endif
#endif /*Flt_Rounds*/

#ifdef Honor_FLT_ROUNDS
#undef Check_FLT_ROUNDS
#define Check_FLT_ROUNDS
#else
#define Rounding Flt_Rounds
#endif

#else /* ifndef IEEE_Arith */
#undef Check_FLT_ROUNDS
#undef Honor_FLT_ROUNDS
#undef SET_INEXACT
#undef  Sudden_Underflow
#define Sudden_Underflow
#ifdef IBM
#undef Flt_Rounds
#define Flt_Rounds 0
#define Exp_shift  24
#define Exp_shift1 24
#define Exp_msk1   0x1000000
#define Exp_msk11  0x1000000
#define Exp_mask  0x7f000000
#define P 14
#define Nbits 56
#define Bias 65
#define Emax 248
#define Emin (-260)
#define Exp_1  0x41000000
#define Exp_11 0x41000000
#define Ebits 8	/* exponent has 7 bits, but 8 is the right value in b2d */
#define Frac_mask  0xffffff
#define Frac_mask1 0xffffff
#define Bletch 4
#define Ten_pmax 22
#define Bndry_mask  0xefffff
#define Bndry_mask1 0xffffff
#define LSB 1
#define Sign_bit 0x80000000
#define Log2P 4
#define Tiny0 0x100000
#define Tiny1 0
#define Quick_max 14
#define Int_max 15
#else /* VAX */
#undef Flt_Rounds
#define Flt_Rounds 1
#define Exp_shift  23
#define Exp_shift1 7
#define Exp_msk1    0x80
#define Exp_msk11   0x800000
#define Exp_mask  0x7f80
#define P 56
#define Nbits 56
#define Bias 129
#define Emax 126
#define Emin (-129)
#define Exp_1  0x40800000
#define Exp_11 0x4080
#define Ebits 8
#define Frac_mask  0x7fffff
#define Frac_mask1 0xffff007f
#define Ten_pmax 24
#define Bletch 2
#define Bndry_mask  0xffff007f
#define Bndry_mask1 0xffff007f
#define LSB 0x10000
#define Sign_bit 0x8000
#define Log2P 1
#define Tiny0 0x80
#define Tiny1 0
#define Quick_max 15
#define Int_max 15
#endif /* IBM, VAX */
#endif /* IEEE_Arith */

#ifndef IEEE_Arith
#define ROUND_BIASED
#endif

#ifdef RND_PRODQUOT
#define rounded_product(a,b) a = rnd_prod(a, b)
#define rounded_quotient(a,b) a = rnd_quot(a, b)
#ifdef KR_headers
extern double rnd_prod(), rnd_quot();
#else
extern double rnd_prod(double, double), rnd_quot(double, double);
#endif
#else
#define rounded_product(a,b) a *= b
#define rounded_quotient(a,b) a /= b
#endif

#define Big0 (Frac_mask1 | Exp_msk1*(DBL_MAX_EXP+Bias-1))
#define Big1 0xffffffff

#ifndef Pack_32
#define Pack_32
#endif

typedef struct BCinfo BCinfo;
 struct
BCinfo { int dp0, dp1, dplen, dsign, e0, inexact, nd, nd0, rounding, scale, uflchk; };

#ifdef KR_headers
#define FFFFFFFF ((((unsigned long)0xffff)<<16)|(unsigned long)0xffff)
#else
#define FFFFFFFF 0xffffffffUL
#endif

#ifdef NO_LONG_LONG
#undef ULLong
#ifdef Just_16
#undef Pack_32
/* When Pack_32 is not defined, we store 16 bits per 32-bit Long.
 * This makes some inner loops simpler and sometimes saves work
 * during multiplications, but it often seems to make things slightly
 * slower.  Hence the default is now to store 32 bits per Long.
 */
#endif
#else	/* long long available */
#ifndef Llong
#define Llong long long
#endif
#ifndef ULLong
#define ULLong unsigned Llong
#endif
#endif /* NO_LONG_LONG */

#ifndef MULTIPLE_THREADS
#define ACQUIRE_DTOA_LOCK(n)	/*nothing*/
#define FREE_DTOA_LOCK(n)	/*nothing*/
#endif

#define Kmax 7

double strtod(const char *s00, char **se);
char *dtoa(double d, int mode, int ndigits,
			int *decpt, int *sign, char **rve);

 struct
Bigint {
	struct Bigint *next;
	int k, maxwds, sign, wds;
	ULong x[1];
	};

 typedef struct Bigint Bigint;

 static Bigint *freelist[Kmax+1];

 static Bigint *
Balloc
#ifdef KR_headers
	(k) int k;
#else
	(int k)
#endif
{
	int x;
	Bigint *rv;
#ifndef Omit_Private_Memory
	unsigned int len;
#endif

	ACQUIRE_DTOA_LOCK(0);
	/* The k > Kmax case does not need ACQUIRE_DTOA_LOCK(0), */
	/* but this case seems very unlikely. */
	if (k <= Kmax && freelist[k]) {
		rv = freelist[k];
		freelist[k] = rv->next;
		}
	else {
		x = 1 << k;
#ifdef Omit_Private_Memory
		rv = (Bigint *)MALLOC(sizeof(Bigint) + (x-1)*sizeof(ULong));
#else
		len = (sizeof(Bigint) + (x-1)*sizeof(ULong) + sizeof(double) - 1)
			/sizeof(double);
		if (k <= Kmax && pmem_next - private_mem + len <= PRIVATE_mem) {
			rv = (Bigint*)pmem_next;
			pmem_next += len;
			}
		else
			rv = (Bigint*)MALLOC(len*sizeof(double));
#endif
		rv->k = k;
		rv->maxwds = x;
		}
	FREE_DTOA_LOCK(0);
	rv->sign = rv->wds = 0;
	return rv;
	}

 static void
Bfree
#ifdef KR_headers
	(v) Bigint *v;
#else
	(Bigint *v)
#endif
{
	if (v) {
		if (v->k > Kmax)
#ifdef FREE
			FREE((void*)v);
#else
			free((void*)v);
#endif
		else {
			ACQUIRE_DTOA_LOCK(0);
			v->next = freelist[v->k];
			freelist[v->k] = v;
			FREE_DTOA_LOCK(0);
			}
		}
	}

#define Bcopy(x,y) memcpy((char *)&x->sign, (char *)&y->sign, \
y->wds*sizeof(Long) + 2*sizeof(int))

 static Bigint *
multadd
#ifdef KR_headers
	(b, m, a) Bigint *b; int m, a;
#else
	(Bigint *b, int m, int a)	/* multiply by m and add a */
#endif
{
	int i, wds;
#ifdef ULLong
	ULong *x;
	ULLong carry, y;
#else
	ULong carry, *x, y;
#ifdef Pack_32
	ULong xi, z;
#endif
#endif
	Bigint *b1;

	wds = b->wds;
	x = b->x;
	i = 0;
	carry = a;
	do {
#ifdef ULLong
		y = *x * (ULLong)m + carry;
		carry = y >> 32;
		*x++ = y & FFFFFFFF;
#else
#ifdef Pack_32
		xi = *x;
		y = (xi & 0xffff) * m + carry;
		z = (xi >> 16) * m + (y >> 16);
		carry = z >> 16;
		*x++ = (z << 16) + (y & 0xffff);
#else
		y = *x * m + carry;
		carry = y >> 16;
		*x++ = y & 0xffff;
#endif
#endif
		}
		while(++i < wds);
	if (carry) {
		if (wds >= b->maxwds) {
			b1 = Balloc(b->k+1);
			Bcopy(b1, b);
			Bfree(b);
			b = b1;
			}
		b->x[wds++] = (ULong)carry;
		b->wds = wds;
		}
	return b;
	}

 static Bigint *
s2b
#ifdef KR_headers
	(s, nd0, nd, y9, dplen) CONST char *s; int nd0, nd, dplen; ULong y9;
#else
	(CONST char *s, int nd0, int nd, ULong y9, int dplen)
#endif
{
	Bigint *b;
	int i, k;
	Long x, y;

	x = (nd + 8) / 9;
	for(k = 0, y = 1; x > y; y <<= 1, k++) ;
#ifdef Pack_32
	b = Balloc(k);
	b->x[0] = y9;
	b->wds = 1;
#else
	b = Balloc(k+1);
	b->x[0] = y9 & 0xffff;
	b->wds = (b->x[1] = y9 >> 16) ? 2 : 1;
#endif

	i = 9;
	if (9 < nd0) {
		s += 9;
		do b = multadd(b, 10, *s++ - '0');
			while(++i < nd0);
		s += dplen;
		}
	else
		s += dplen + 9;
	for(; i < nd; i++)
		b = multadd(b, 10, *s++ - '0');
	return b;
	}

 static int
hi0bits
#ifdef KR_headers
	(x) ULong x;
#else
	(ULong x)
#endif
{
	int k = 0;

	if (!(x & 0xffff0000)) {
		k = 16;
		x <<= 16;
		}
	if (!(x & 0xff000000)) {
		k += 8;
		x <<= 8;
		}
	if (!(x & 0xf0000000)) {
		k += 4;
		x <<= 4;
		}
	if (!(x & 0xc0000000)) {
		k += 2;
		x <<= 2;
		}
	if (!(x & 0x80000000)) {
		k++;
		if (!(x & 0x40000000))
			return 32;
		}
	return k;
	}

 static int
lo0bits
#ifdef KR_headers
	(y) ULong *y;
#else
	(ULong *y)
#endif
{
	int k;
	ULong x = *y;

	if (x & 7) {
		if (x & 1)
			return 0;
		if (x & 2) {
			*y = x >> 1;
			return 1;
			}
		*y = x >> 2;
		return 2;
		}
	k = 0;
	if (!(x & 0xffff)) {
		k = 16;
		x >>= 16;
		}
	if (!(x & 0xff)) {
		k += 8;
		x >>= 8;
		}
	if (!(x & 0xf)) {
		k += 4;
		x >>= 4;
		}
	if (!(x & 0x3)) {
		k += 2;
		x >>= 2;
		}
	if (!(x & 1)) {
		k++;
		x >>= 1;
		if (!x)
			return 32;
		}
	*y = x;
	return k;
	}

 static Bigint *
i2b
#ifdef KR_headers
	(i) int i;
#else
	(int i)
#endif
{
	Bigint *b;

	b = Balloc(1);
	b->x[0] = i;
	b->wds = 1;
	return b;
	}

 static Bigint *
mult
#ifdef KR_headers
	(a, b) Bigint *a, *b;
#else
	(Bigint *a, Bigint *b)
#endif
{
	Bigint *c;
	int k, wa, wb, wc;
	ULong *x, *xa, *xae, *xb, *xbe, *xc, *xc0;
	ULong y;
#ifdef ULLong
	ULLong carry, z;
#else
	ULong carry, z;
#ifdef Pack_32
	ULong z2;
#endif
#endif

	if (a->wds < b->wds) {
		c = a;
		a = b;
		b = c;
		}
	k = a->k;
	wa = a->wds;
	wb = b->wds;
	wc = wa + wb;
	if (wc > a->maxwds)
		k++;
	c = Balloc(k);
	for(x = c->x, xa = x + wc; x < xa; x++)
		*x = 0;
	xa = a->x;
	xae = xa + wa;
	xb = b->x;
	xbe = xb + wb;
	xc0 = c->x;
#ifdef ULLong
	for(; xb < xbe; xc0++) {
		y = *xb++;
		if (y) {
			x = xa;
			xc = xc0;
			carry = 0;
			do {
				z = *x++ * (ULLong)y + *xc + carry;
				carry = z >> 32;
				*xc++ = z & FFFFFFFF;
				}
				while(x < xae);
			*xc = (ULong)carry;
			}
		}
#else
#ifdef Pack_32
	for(; xb < xbe; xb++, xc0++) {
		if (y = *xb & 0xffff) {
			x = xa;
			xc = xc0;
			carry = 0;
			do {
				z = (*x & 0xffff) * y + (*xc & 0xffff) + carry;
				carry = z >> 16;
				z2 = (*x++ >> 16) * y + (*xc >> 16) + carry;
				carry = z2 >> 16;
				Storeinc(xc, z2, z);
				}
				while(x < xae);
			*xc = carry;
			}
		if (y = *xb >> 16) {
			x = xa;
			xc = xc0;
			carry = 0;
			z2 = *xc;
			do {
				z = (*x & 0xffff) * y + (*xc >> 16) + carry;
				carry = z >> 16;
				Storeinc(xc, z, z2);
				z2 = (*x++ >> 16) * y + (*xc & 0xffff) + carry;
				carry = z2 >> 16;
				}
				while(x < xae);
			*xc = z2;
			}
		}
#else
	for(; xb < xbe; xc0++) {
		if (y = *xb++) {
			x = xa;
			xc = xc0;
			carry = 0;
			do {
				z = *x++ * y + *xc + carry;
				carry = z >> 16;
				*xc++ = z & 0xffff;
				}
				while(x < xae);
			*xc = carry;
			}
		}
#endif
#endif
	for(xc0 = c->x, xc = xc0 + wc; wc > 0 && !*--xc; --wc) ;
	c->wds = wc;
	return c;
	}

 static Bigint *p5s;

 static Bigint *
pow5mult
#ifdef KR_headers
	(b, k) Bigint *b; int k;
#else
	(Bigint *b, int k)
#endif
{
	Bigint *b1, *p5, *p51;
	int i;
	static int p05[3] = { 5, 25, 125 };

	i = k & 3;
	if (i)
		b = multadd(b, p05[i-1], 0);

	if (!(k >>= 2))
		return b;
	p5 = p5s;
	if (!p5) {
		/* first time */
#ifdef MULTIPLE_THREADS
		ACQUIRE_DTOA_LOCK(1);
		p5 = p5s;
		if (!p5) {
			p5 = p5s = i2b(625);
			p5->next = 0;
			}
		FREE_DTOA_LOCK(1);
#else
		p5 = p5s = i2b(625);
		p5->next = 0;
#endif
		}
	for(;;) {
		if (k & 1) {
			b1 = mult(b, p5);
			Bfree(b);
			b = b1;
			}
		if (!(k >>= 1))
			break;
		p51 = p5->next;
		if (!p51) {
#ifdef MULTIPLE_THREADS
			ACQUIRE_DTOA_LOCK(1);
			p51 = p5->next;
			if (!p51) {
				p51 = p5->next = mult(p5,p5);
				p51->next = 0;
				}
			FREE_DTOA_LOCK(1);
#else
			p51 = p5->next = mult(p5,p5);
			p51->next = 0;
#endif
			}
		p5 = p51;
		}
	return b;
	}

 static Bigint *
lshift
#ifdef KR_headers
	(b, k) Bigint *b; int k;
#else
	(Bigint *b, int k)
#endif
{
	int i, k1, n, n1;
	Bigint *b1;
	ULong *x, *x1, *xe, z;

#ifdef Pack_32
	n = k >> 5;
#else
	n = k >> 4;
#endif
	k1 = b->k;
	n1 = n + b->wds + 1;
	for(i = b->maxwds; n1 > i; i <<= 1)
		k1++;
	b1 = Balloc(k1);
	x1 = b1->x;
	for(i = 0; i < n; i++)
		*x1++ = 0;
	x = b->x;
	xe = x + b->wds;
#ifdef Pack_32
	if (k &= 0x1f) {
		k1 = 32 - k;
		z = 0;
		do {
			*x1++ = *x << k | z;
			z = *x++ >> k1;
			}
			while(x < xe);
		*x1 = z;
		if (*x1)
			++n1;
		}
#else
	if (k &= 0xf) {
		k1 = 16 - k;
		z = 0;
		do {
			*x1++ = *x << k  & 0xffff | z;
			z = *x++ >> k1;
			}
			while(x < xe);
		if (*x1 = z)
			++n1;
		}
#endif
	else do
		*x1++ = *x++;
		while(x < xe);
	b1->wds = n1 - 1;
	Bfree(b);
	return b1;
	}

 static int
cmp
#ifdef KR_headers
	(a, b) Bigint *a, *b;
#else
	(Bigint *a, Bigint *b)
#endif
{
	ULong *xa, *xa0, *xb, *xb0;
	int i, j;

	i = a->wds;
	j = b->wds;
#ifdef DEBUG
	if (i > 1 && !a->x[i-1])
		Bug("cmp called with a->x[a->wds-1] == 0");
	if (j > 1 && !b->x[j-1])
		Bug("cmp called with b->x[b->wds-1] == 0");
#endif
	if (i -= j)
		return i;
	xa0 = a->x;
	xa = xa0 + j;
	xb0 = b->x;
	xb = xb0 + j;
	for(;;) {
		if (*--xa != *--xb)
			return *xa < *xb ? -1 : 1;
		if (xa <= xa0)
			break;
		}
	return 0;
	}

 static Bigint *
diff
#ifdef KR_headers
	(a, b) Bigint *a, *b;
#else
	(Bigint *a, Bigint *b)
#endif
{
	Bigint *c;
	int i, wa, wb;
	ULong *xa, *xae, *xb, *xbe, *xc;
#ifdef ULLong
	ULLong borrow, y;
#else
	ULong borrow, y;
#ifdef Pack_32
	ULong z;
#endif
#endif

	i = cmp(a,b);
	if (!i) {
		c = Balloc(0);
		c->wds = 1;
		c->x[0] = 0;
		return c;
		}
	if (i < 0) {
		c = a;
		a = b;
		b = c;
		i = 1;
		}
	else
		i = 0;
	c = Balloc(a->k);
	c->sign = i;
	wa = a->wds;
	xa = a->x;
	xae = xa + wa;
	wb = b->wds;
	xb = b->x;
	xbe = xb + wb;
	xc = c->x;
	borrow = 0;
#ifdef ULLong
	do {
		y = (ULLong)*xa++ - *xb++ - borrow;
		borrow = y >> 32 & (ULong)1;
		*xc++ = y & FFFFFFFF;
		}
		while(xb < xbe);
	while(xa < xae) {
		y = *xa++ - borrow;
		borrow = y >> 32 & (ULong)1;
		*xc++ = y & FFFFFFFF;
		}
#else
#ifdef Pack_32
	do {
		y = (*xa & 0xffff) - (*xb & 0xffff) - borrow;
		borrow = (y & 0x10000) >> 16;
		z = (*xa++ >> 16) - (*xb++ >> 16) - borrow;
		borrow = (z & 0x10000) >> 16;
		Storeinc(xc, z, y);
		}
		while(xb < xbe);
	while(xa < xae) {
		y = (*xa & 0xffff) - borrow;
		borrow = (y & 0x10000) >> 16;
		z = (*xa++ >> 16) - borrow;
		borrow = (z & 0x10000) >> 16;
		Storeinc(xc, z, y);
		}
#else
	do {
		y = *xa++ - *xb++ - borrow;
		borrow = (y & 0x10000) >> 16;
		*xc++ = y & 0xffff;
		}
		while(xb < xbe);
	while(xa < xae) {
		y = *xa++ - borrow;
		borrow = (y & 0x10000) >> 16;
		*xc++ = y & 0xffff;
		}
#endif
#endif
	while(!*--xc)
		wa--;
	c->wds = wa;
	return c;
	}

 static double
ulp
#ifdef KR_headers
	(x) U *x;
#else
	(U *x)
#endif
{
	Long L;
	U u;

	L = (word0(x) & Exp_mask) - (P-1)*Exp_msk1;
#ifndef Avoid_Underflow
#ifndef Sudden_Underflow
	if (L > 0) {
#endif
#endif
#ifdef IBM
		L |= Exp_msk1 >> 4;
#endif
		word0(&u) = L;
		word1(&u) = 0;
#ifndef Avoid_Underflow
#ifndef Sudden_Underflow
		}
	else {
		L = -L >> Exp_shift;
		if (L < Exp_shift) {
			word0(&u) = 0x80000 >> L;
			word1(&u) = 0;
			}
		else {
			word0(&u) = 0;
			L -= Exp_shift;
			word1(&u) = L >= 31 ? 1 : 1 << 31 - L;
			}
		}
#endif
#endif
	return dval(&u);
	}

 static double
b2d
#ifdef KR_headers
	(a, e) Bigint *a; int *e;
#else
	(Bigint *a, int *e)
#endif
{
	ULong *xa, *xa0, w, y, z;
	int k;
	U d;
#ifdef VAX
	ULong d0, d1;
#else
#define d0 word0(&d)
#define d1 word1(&d)
#endif

	xa0 = a->x;
	xa = xa0 + a->wds;
	y = *--xa;
#ifdef DEBUG
	if (!y) Bug("zero y in b2d");
#endif
	k = hi0bits(y);
	*e = 32 - k;
#ifdef Pack_32
	if (k < Ebits) {
		d0 = Exp_1 | y >> (Ebits - k);
		w = xa > xa0 ? *--xa : 0;
		d1 = y << ((32-Ebits) + k) | w >> (Ebits - k);
		goto ret_d;
		}
	z = xa > xa0 ? *--xa : 0;
	if (k -= Ebits) {
		d0 = Exp_1 | y << k | z >> (32 - k);
		y = xa > xa0 ? *--xa : 0;
		d1 = z << k | y >> (32 - k);
		}
	else {
		d0 = Exp_1 | y;
		d1 = z;
		}
#else
	if (k < Ebits + 16) {
		z = xa > xa0 ? *--xa : 0;
		d0 = Exp_1 | y << k - Ebits | z >> Ebits + 16 - k;
		w = xa > xa0 ? *--xa : 0;
		y = xa > xa0 ? *--xa : 0;
		d1 = z << k + 16 - Ebits | w << k - Ebits | y >> 16 + Ebits - k;
		goto ret_d;
		}
	z = xa > xa0 ? *--xa : 0;
	w = xa > xa0 ? *--xa : 0;
	k -= Ebits + 16;
	d0 = Exp_1 | y << k + 16 | z << k | w >> 16 - k;
	y = xa > xa0 ? *--xa : 0;
	d1 = w << k + 16 | y << k;
#endif
 ret_d:
#ifdef VAX
	word0(&d) = d0 >> 16 | d0 << 16;
	word1(&d) = d1 >> 16 | d1 << 16;
#else
#undef d0
#undef d1
#endif
	return dval(&d);
	}

 static Bigint *
d2b
#ifdef KR_headers
	(d, e, bits) U *d; int *e, *bits;
#else
	(U *d, int *e, int *bits)
#endif
{
	Bigint *b;
	int de, k;
	ULong *x, y, z;
#ifndef Sudden_Underflow
	int i;
#endif
#ifdef VAX
	ULong d0, d1;
	d0 = word0(d) >> 16 | word0(d) << 16;
	d1 = word1(d) >> 16 | word1(d) << 16;
#else
#define d0 word0(d)
#define d1 word1(d)
#endif

#ifdef Pack_32
	b = Balloc(1);
#else
	b = Balloc(2);
#endif
	x = b->x;

	z = d0 & Frac_mask;
	d0 &= 0x7fffffff;	/* clear sign bit, which we ignore */
#ifdef Sudden_Underflow
	de = (int)(d0 >> Exp_shift);
#ifndef IBM
	z |= Exp_msk11;
#endif
#else
	de = (int)(d0 >> Exp_shift);
	if (de)
		z |= Exp_msk1;
#endif
#ifdef Pack_32
	y = d1;
	if (y) {
		k = lo0bits(&y);
		if (k) {
			x[0] = y | z << (32 - k);
			z >>= k;
			}
		else
			x[0] = y;
		x[1] = z;
		b->wds = x[1] ? 2 : 1;
#ifndef Sudden_Underflow
		i = b->wds;
#endif
		}
	else {
		k = lo0bits(&z);
		x[0] = z;
#ifndef Sudden_Underflow
		i =
#endif
		    b->wds = 1;
		k += 32;
		}
#else
	if (y = d1) {
		if (k = lo0bits(&y))
			if (k >= 16) {
				x[0] = y | z << 32 - k & 0xffff;
				x[1] = z >> k - 16 & 0xffff;
				x[2] = z >> k;
				i = 2;
				}
			else {
				x[0] = y & 0xffff;
				x[1] = y >> 16 | z << 16 - k & 0xffff;
				x[2] = z >> k & 0xffff;
				x[3] = z >> k+16;
				i = 3;
				}
		else {
			x[0] = y & 0xffff;
			x[1] = y >> 16;
			x[2] = z & 0xffff;
			x[3] = z >> 16;
			i = 3;
			}
		}
	else {
#ifdef DEBUG
		if (!z)
			Bug("Zero passed to d2b");
#endif
		k = lo0bits(&z);
		if (k >= 16) {
			x[0] = z;
			i = 0;
			}
		else {
			x[0] = z & 0xffff;
			x[1] = z >> 16;
			i = 1;
			}
		k += 32;
		}
	while(!x[i])
		--i;
	b->wds = i + 1;
#endif
#ifndef Sudden_Underflow
	if (de) {
#endif
#ifdef IBM
		*e = (de - Bias - (P-1) << 2) + k;
		*bits = 4*P + 8 - k - hi0bits(word0(d) & Frac_mask);
#else
		*e = de - Bias - (P-1) + k;
		*bits = P - k;
#endif
#ifndef Sudden_Underflow
		}
	else {
		*e = de - Bias - (P-1) + 1 + k;
#ifdef Pack_32
		*bits = 32*i - hi0bits(x[i-1]);
#else
		*bits = (i+2)*16 - hi0bits(x[i]);
#endif
		}
#endif
	return b;
	}
#undef d0
#undef d1

 static double
ratio
#ifdef KR_headers
	(a, b) Bigint *a, *b;
#else
	(Bigint *a, Bigint *b)
#endif
{
	U da, db;
	int k, ka, kb;

	dval(&da) = b2d(a, &ka);
	dval(&db) = b2d(b, &kb);
#ifdef Pack_32
	k = ka - kb + 32*(a->wds - b->wds);
#else
	k = ka - kb + 16*(a->wds - b->wds);
#endif
#ifdef IBM
	if (k > 0) {
		word0(&da) += (k >> 2)*Exp_msk1;
		if (k &= 3)
			dval(&da) *= 1 << k;
		}
	else {
		k = -k;
		word0(&db) += (k >> 2)*Exp_msk1;
		if (k &= 3)
			dval(&db) *= 1 << k;
		}
#else
	if (k > 0)
		word0(&da) += k*Exp_msk1;
	else {
		k = -k;
		word0(&db) += k*Exp_msk1;
		}
#endif
	return dval(&da) / dval(&db);
	}

 static CONST double
tens[] = {
		1e0, 1e1, 1e2, 1e3, 1e4, 1e5, 1e6, 1e7, 1e8, 1e9,
		1e10, 1e11, 1e12, 1e13, 1e14, 1e15, 1e16, 1e17, 1e18, 1e19,
		1e20, 1e21, 1e22
#ifdef VAX
		, 1e23, 1e24
#endif
		};

 static CONST double
#ifdef IEEE_Arith
bigtens[] = { 1e16, 1e32, 1e64, 1e128, 1e256 };
static CONST double tinytens[] = { 1e-16, 1e-32, 1e-64, 1e-128,
#ifdef Avoid_Underflow
		9007199254740992.*9007199254740992.e-256
		/* = 2^106 * 1e-256 */
#else
		1e-256
#endif
		};
/* The factor of 2^53 in tinytens[4] helps us avoid setting the underflow */
/* flag unnecessarily.  It leads to a song and dance at the end of strtod. */
#define Scale_Bit 0x10
#define n_bigtens 5
#else
#ifdef IBM
bigtens[] = { 1e16, 1e32, 1e64 };
static CONST double tinytens[] = { 1e-16, 1e-32, 1e-64 };
#define n_bigtens 3
#else
bigtens[] = { 1e16, 1e32 };
static CONST double tinytens[] = { 1e-16, 1e-32 };
#define n_bigtens 2
#endif
#endif

#undef Need_Hexdig
#ifdef INFNAN_CHECK
#ifndef No_Hex_NaN
#define Need_Hexdig
#endif
#endif

#ifndef Need_Hexdig
#ifndef NO_HEX_FP
#define Need_Hexdig
#endif
#endif

#ifdef Need_Hexdig /*{*/
static unsigned char hexdig[256];

 static void
#ifdef KR_headers
htinit(h, s, inc) unsigned char *h; unsigned char *s; int inc;
#else
htinit(unsigned char *h, unsigned char *s, int inc)
#endif
{
	int i, j;
	for(i = 0; (j = s[i]) !=0; i++)
		h[j] = (unsigned char)(i + inc);
	}

 static void
#ifdef KR_headers
hexdig_init()
#else
hexdig_init(void)
#endif
{
#define USC (unsigned char *)
	htinit(hexdig, USC "0123456789", 0x10);
	htinit(hexdig, USC "abcdef", 0x10 + 10);
	htinit(hexdig, USC "ABCDEF", 0x10 + 10);
	}
#endif /* } Need_Hexdig */

#ifdef INFNAN_CHECK

#ifndef NAN_WORD0
#define NAN_WORD0 0x7ff80000
#endif

#ifndef NAN_WORD1
#define NAN_WORD1 0
#endif

 static int
match
#ifdef KR_headers
	(sp, t) char **sp, *t;
#else
	(CONST char **sp, CONST char *t)
#endif
{
	int c, d;
	CONST char *s = *sp;

	for(d = *t++; d; d = *t++) {
		if ((c = *++s) >= 'A' && c <= 'Z')
			c += 'a' - 'A';
		if (c != d)
			return 0;
		}
	*sp = s + 1;
	return 1;
	}

#ifndef No_Hex_NaN
 static void
hexnan
#ifdef KR_headers
	(rvp, sp) U *rvp; CONST char **sp;
#else
	(U *rvp, CONST char **sp)
#endif
{
	ULong c, x[2];
	CONST char *s;
	int c1, havedig, udx0, xshift;

	if (!hexdig['0'])
		hexdig_init();
	x[0] = x[1] = 0;
	havedig = xshift = 0;
	udx0 = 1;
	s = *sp;
	/* allow optional initial 0x or 0X */
	for(c = *(CONST unsigned char*)(s+1); c && c <= ' '; c = *(CONST unsigned char*)(s+1))
		++s;
	if (s[1] == '0' && (s[2] == 'x' || s[2] == 'X'))
		s += 2;
	for(c = *(CONST unsigned char*)++s; c; c = *(CONST unsigned char*)++s) {
		c1 = hexdig[c];
		if (c1)
			c  = c1 & 0xf;
		else if (c <= ' ') {
			if (udx0 && havedig) {
				udx0 = 0;
				xshift = 1;
				}
			continue;
			}
#ifdef GDTOA_NON_PEDANTIC_NANCHECK
		else if (/*(*/ c == ')' && havedig) {
			*sp = s + 1;
			break;
			}
		else
			return;	/* invalid form: don't change *sp */
#else
		else {
			do {
				if (/*(*/ c == ')') {
					*sp = s + 1;
					break;
					}
				c = *++s;
				} while(c);
			break;
			}
#endif
		havedig = 1;
		if (xshift) {
			xshift = 0;
			x[0] = x[1];
			x[1] = 0;
			}
		if (udx0)
			x[0] = (x[0] << 4) | (x[1] >> 28);
		x[1] = (x[1] << 4) | c;
		}
	if ((x[0] &= 0xfffff) || x[1]) {
		word0(rvp) = Exp_mask | x[0];
		word1(rvp) = x[1];
		}
	}
#endif /*No_Hex_NaN*/
#endif /* INFNAN_CHECK */

#ifdef Pack_32
#define ULbits 32
#define kshift 5
#define kmask 31
#else
#define ULbits 16
#define kshift 4
#define kmask 15
#endif
#ifndef NO_HEX_FP /*{*/

 static void
#ifdef KR_headers
rshift(b, k) Bigint *b; int k;
#else
rshift(Bigint *b, int k)
#endif
{
	ULong *x, *x1, *xe, y;
	int n;

	x = x1 = b->x;
	n = k >> kshift;
	if (n < b->wds) {
		xe = x + b->wds;
		x += n;
		if (k &= kmask) {
			n = 32 - k;
			y = *x++ >> k;
			while(x < xe) {
				*x1++ = (y | (*x << n)) & 0xffffffff;
				y = *x++ >> k;
				}
			if ((*x1 = y) !=0)
				x1++;
			}
		else
			while(x < xe)
				*x1++ = *x++;
		}
	if ((b->wds = x1 - b->x) == 0)
		b->x[0] = 0;
	}

 static ULong
#ifdef KR_headers
any_on(b, k) Bigint *b; int k;
#else
any_on(Bigint *b, int k)
#endif
{
	int n, nwds;
	ULong *x, *x0, x1, x2;

	x = b->x;
	nwds = b->wds;
	n = k >> kshift;
	if (n > nwds)
		n = nwds;
	else if (n < nwds && (k &= kmask)) {
		x1 = x2 = x[n];
		x1 >>= k;
		x1 <<= k;
		if (x1 != x2)
			return 1;
		}
	x0 = x;
	x += n;
	while(x > x0)
		if (*--x)
			return 1;
	return 0;
	}

enum {	/* rounding values: same as FLT_ROUNDS */
	Round_zero = 0,
	Round_near = 1,
	Round_up = 2,
	Round_down = 3
	};

 static Bigint *
#ifdef KR_headers
increment(b) Bigint *b;
#else
increment(Bigint *b)
#endif
{
	ULong *x, *xe;
	Bigint *b1;

	x = b->x;
	xe = x + b->wds;
	do {
		if (*x < (ULong)0xffffffffL) {
			++*x;
			return b;
			}
		*x++ = 0;
		} while(x < xe);
	{
		if (b->wds >= b->maxwds) {
			b1 = Balloc(b->k+1);
			Bcopy(b1,b);
			Bfree(b);
			b = b1;
			}
		b->x[b->wds++] = 1;
		}
	return b;
	}

 void
#ifdef KR_headers
gethex(sp, rvp, rounding, sign)
	CONST char **sp; U *rvp; int rounding, sign;
#else
gethex( CONST char **sp, U *rvp, int rounding, int sign)
#endif
{
	Bigint *b;
	CONST unsigned char *decpt, *s0, *s, *s1;
	Long e, e1;
	ULong L, lostbits, *x;
	int big, denorm, esign, havedig, k, n, nbits, up, zret;
#ifdef IBM
	int j;
#endif
	enum {
#ifdef IEEE_Arith /*{{*/
		emax = 0x7fe - Bias - P + 1,
		emin = Emin - P + 1
#else /*}{*/
		emin = Emin - P,
#ifdef VAX
		emax = 0x7ff - Bias - P + 1
#endif
#ifdef IBM
		emax = 0x7f - Bias - P
#endif
#endif /*}}*/
		};
#ifdef USE_LOCALE
	int i;
#ifdef NO_LOCALE_CACHE
	const unsigned char *decimalpoint = (unsigned char*)
		localeconv()->decimal_point;
#else
	const unsigned char *decimalpoint;
	static unsigned char *decimalpoint_cache;
	if (!(s0 = decimalpoint_cache)) {
		s0 = (unsigned char*)localeconv()->decimal_point;
		if ((decimalpoint_cache = (unsigned char*)
				MALLOC(strlen((CONST char*)s0) + 1))) {
			strcpy((char*)decimalpoint_cache, (CONST char*)s0);
			s0 = decimalpoint_cache;
			}
		}
	decimalpoint = s0;
#endif
#endif

	if (!hexdig['0'])
		hexdig_init();
	havedig = 0;
	s0 = *(CONST unsigned char **)sp + 2;
	while(s0[havedig] == '0')
		havedig++;
	s0 += havedig;
	s = s0;
	decpt = 0;
	zret = 0;
	e = 0;
	if (hexdig[*s])
		havedig++;
	else {
		zret = 1;
#ifdef USE_LOCALE
		for(i = 0; decimalpoint[i]; ++i) {
			if (s[i] != decimalpoint[i])
				goto pcheck;
			}
		decpt = s += i;
#else
		if (*s != '.')
			goto pcheck;
		decpt = ++s;
#endif
		if (!hexdig[*s])
			goto pcheck;
		while(*s == '0')
			s++;
		if (hexdig[*s])
			zret = 0;
		havedig = 1;
		s0 = s;
		}
	while(hexdig[*s])
		s++;
#ifdef USE_LOCALE
	if (*s == *decimalpoint && !decpt) {
		for(i = 1; decimalpoint[i]; ++i) {
			if (s[i] != decimalpoint[i])
				goto pcheck;
			}
		decpt = s += i;
#else
	if (*s == '.' && !decpt) {
		decpt = ++s;
#endif
		while(hexdig[*s])
			s++;
		}/*}*/
	if (decpt)
		e = -(((Long)(s-decpt)) << 2);
 pcheck:
	s1 = s;
	big = esign = 0;
	switch(*s) {
	  case 'p':
	  case 'P':
		switch(*++s) {
		  case '-':
			esign = 1;
			/* no break */
		  case '+':
			s++;
		  }
		if ((n = hexdig[*s]) == 0 || n > 0x19) {
			s = s1;
			break;
			}
		e1 = n - 0x10;
		while((n = hexdig[*++s]) !=0 && n <= 0x19) {
			if (e1 & 0xf8000000)
				big = 1;
			e1 = 10*e1 + n - 0x10;
			}
		if (esign)
			e1 = -e1;
		e += e1;
	  }
	*sp = (char*)s;
	if (!havedig)
		*sp = (char*)s0 - 1;
	if (zret)
		goto retz1;
	if (big) {
		if (esign) {
#ifdef IEEE_Arith
			switch(rounding) {
			  case Round_up:
				if (sign)
					break;
				goto ret_tiny;
			  case Round_down:
				if (!sign)
					break;
				goto ret_tiny;
			  }
#endif
			goto retz;
#ifdef IEEE_Arith
 ret_tiny:
#ifndef NO_ERRNO
			errno = ERANGE;
#endif
			word0(rvp) = 0;
			word1(rvp) = 1;
			return;
#endif /* IEEE_Arith */
			}
		switch(rounding) {
		  case Round_near:
			goto ovfl1;
		  case Round_up:
			if (!sign)
				goto ovfl1;
			goto ret_big;
		  case Round_down:
			if (sign)
				goto ovfl1;
			goto ret_big;
		  }
 ret_big:
		word0(rvp) = Big0;
		word1(rvp) = Big1;
		return;
		}
	n = s1 - s0 - 1;
	for(k = 0; n > (1 << (kshift-2)) - 1; n >>= 1)
		k++;
	b = Balloc(k);
	x = b->x;
	n = 0;
	L = 0;
#ifdef USE_LOCALE
	for(i = 0; decimalpoint[i+1]; ++i);
#endif
	while(s1 > s0) {
#ifdef USE_LOCALE
		if (*--s1 == decimalpoint[i]) {
			s1 -= i;
			continue;
			}
#else
		if (*--s1 == '.')
			continue;
#endif
		if (n == ULbits) {
			*x++ = L;
			L = 0;
			n = 0;
			}
		L |= (hexdig[*s1] & 0x0f) << n;
		n += 4;
		}
	*x++ = L;
	b->wds = n = x - b->x;
	n = ULbits*n - hi0bits(L);
	nbits = Nbits;
	lostbits = 0;
	x = b->x;
	if (n > nbits) {
		n -= nbits;
		if (any_on(b,n)) {
			lostbits = 1;
			k = n - 1;
			if (x[k>>kshift] & 1 << (k & kmask)) {
				lostbits = 2;
				if (k > 0 && any_on(b,k))
					lostbits = 3;
				}
			}
		rshift(b, n);
		e += n;
		}
	else if (n < nbits) {
		n = nbits - n;
		b = lshift(b, n);
		e -= n;
		x = b->x;
		}
	if (e > Emax) {
 ovfl:
		Bfree(b);
 ovfl1:
#ifndef NO_ERRNO
		errno = ERANGE;
#endif
		word0(rvp) = Exp_mask;
		word1(rvp) = 0;
		return;
		}
	denorm = 0;
	if (e < emin) {
		denorm = 1;
		n = emin - e;
		if (n >= nbits) {
#ifdef IEEE_Arith /*{*/
			switch (rounding) {
			  case Round_near:
				if (n == nbits && (n < 2 || any_on(b,n-1)))
					goto ret_tiny;
				break;
			  case Round_up:
				if (!sign)
					goto ret_tiny;
				break;
			  case Round_down:
				if (sign)
					goto ret_tiny;
			  }
#endif /* } IEEE_Arith */
			Bfree(b);
 retz:
#ifndef NO_ERRNO
			errno = ERANGE;
#endif
 retz1:
			rvp->d = 0.;
			return;
			}
		k = n - 1;
		if (lostbits)
			lostbits = 1;
		else if (k > 0)
			lostbits = any_on(b,k);
		if (x[k>>kshift] & 1 << (k & kmask))
			lostbits |= 2;
		nbits -= n;
		rshift(b,n);
		e = emin;
		}
	if (lostbits) {
		up = 0;
		switch(rounding) {
		  case Round_zero:
			break;
		  case Round_near:
			if (lostbits & 2
			 && (lostbits & 1) | (x[0] & 1))
				up = 1;
			break;
		  case Round_up:
			up = 1 - sign;
			break;
		  case Round_down:
			up = sign;
		  }
		if (up) {
			k = b->wds;
			b = increment(b);
			x = b->x;
			if (denorm) {
#if 0
				if (nbits == Nbits - 1
				 && x[nbits >> kshift] & 1 << (nbits & kmask))
					denorm = 0; /* not currently used */
#endif
				}
			else if (b->wds > k
			 || ((n = nbits & kmask) !=0
			     && hi0bits(x[k-1]) < 32-n)) {
				rshift(b,1);
				if (++e > Emax)
					goto ovfl;
				}
			}
		}
#ifdef IEEE_Arith
	if (denorm)
		word0(rvp) = b->wds > 1 ? b->x[1] & ~0x100000 : 0;
	else
		word0(rvp) = (b->x[1] & ~0x100000) | ((e + 0x3ff + 52) << 20);
	word1(rvp) = b->x[0];
#endif
#ifdef IBM
	if ((j = e & 3)) {
		k = b->x[0] & ((1 << j) - 1);
		rshift(b,j);
		if (k) {
			switch(rounding) {
			  case Round_up:
				if (!sign)
					increment(b);
				break;
			  case Round_down:
				if (sign)
					increment(b);
				break;
			  case Round_near:
				j = 1 << (j-1);
				if (k & j && ((k & (j-1)) | lostbits))
					increment(b);
			  }
			}
		}
	e >>= 2;
	word0(rvp) = b->x[1] | ((e + 65 + 13) << 24);
	word1(rvp) = b->x[0];
#endif
#ifdef VAX
	/* The next two lines ignore swap of low- and high-order 2 bytes. */
	/* word0(rvp) = (b->x[1] & ~0x800000) | ((e + 129 + 55) << 23); */
	/* word1(rvp) = b->x[0]; */
	word0(rvp) = ((b->x[1] & ~0x800000) >> 16) | ((e + 129 + 55) << 7) | (b->x[1] << 16);
	word1(rvp) = (b->x[0] >> 16) | (b->x[0] << 16);
#endif
	Bfree(b);
	}
#endif /*}!NO_HEX_FP*/

 static int
#ifdef KR_headers
dshift(b, p2) Bigint *b; int p2;
#else
dshift(Bigint *b, int p2)
#endif
{
	int rv = hi0bits(b->x[b->wds-1]) - 4;
	if (p2 > 0)
		rv -= p2;
	return rv & kmask;
	}

 static int
quorem
#ifdef KR_headers
	(b, S) Bigint *b, *S;
#else
	(Bigint *b, Bigint *S)
#endif
{
	int n;
	ULong *bx, *bxe, q, *sx, *sxe;
#ifdef ULLong
	ULLong borrow, carry, y, ys;
#else
	ULong borrow, carry, y, ys;
#ifdef Pack_32
	ULong si, z, zs;
#endif
#endif

	n = S->wds;
#ifdef DEBUG
	/*debug*/ if (b->wds > n)
	/*debug*/	Bug("oversize b in quorem");
#endif
	if (b->wds < n)
		return 0;
	sx = S->x;
	sxe = sx + --n;
	bx = b->x;
	bxe = bx + n;
	q = *bxe / (*sxe + 1);	/* ensure q <= true quotient */
#ifdef DEBUG
	/*debug*/ if (q > 9)
	/*debug*/	Bug("oversized quotient in quorem");
#endif
	if (q) {
		borrow = 0;
		carry = 0;
		do {
#ifdef ULLong
			ys = *sx++ * (ULLong)q + carry;
			carry = ys >> 32;
			y = *bx - (ys & FFFFFFFF) - borrow;
			borrow = y >> 32 & (ULong)1;
			*bx++ = y & FFFFFFFF;
#else
#ifdef Pack_32
			si = *sx++;
			ys = (si & 0xffff) * q + carry;
			zs = (si >> 16) * q + (ys >> 16);
			carry = zs >> 16;
			y = (*bx & 0xffff) - (ys & 0xffff) - borrow;
			borrow = (y & 0x10000) >> 16;
			z = (*bx >> 16) - (zs & 0xffff) - borrow;
			borrow = (z & 0x10000) >> 16;
			Storeinc(bx, z, y);
#else
			ys = *sx++ * q + carry;
			carry = ys >> 16;
			y = *bx - (ys & 0xffff) - borrow;
			borrow = (y & 0x10000) >> 16;
			*bx++ = y & 0xffff;
#endif
#endif
			}
			while(sx <= sxe);
		if (!*bxe) {
			bx = b->x;
			while(--bxe > bx && !*bxe)
				--n;
			b->wds = n;
			}
		}
	if (cmp(b, S) >= 0) {
		q++;
		borrow = 0;
		carry = 0;
		bx = b->x;
		sx = S->x;
		do {
#ifdef ULLong
			ys = *sx++ + carry;
			carry = ys >> 32;
			y = *bx - (ys & FFFFFFFF) - borrow;
			borrow = y >> 32 & (ULong)1;
			*bx++ = y & FFFFFFFF;
#else
#ifdef Pack_32
			si = *sx++;
			ys = (si & 0xffff) + carry;
			zs = (si >> 16) + (ys >> 16);
			carry = zs >> 16;
			y = (*bx & 0xffff) - (ys & 0xffff) - borrow;
			borrow = (y & 0x10000) >> 16;
			z = (*bx >> 16) - (zs & 0xffff) - borrow;
			borrow = (z & 0x10000) >> 16;
			Storeinc(bx, z, y);
#else
			ys = *sx++ + carry;
			carry = ys >> 16;
			y = *bx - (ys & 0xffff) - borrow;
			borrow = (y & 0x10000) >> 16;
			*bx++ = y & 0xffff;
#endif
#endif
			}
			while(sx <= sxe);
		bx = b->x;
		bxe = bx + n;
		if (!*bxe) {
			while(--bxe > bx && !*bxe)
				--n;
			b->wds = n;
			}
		}
	return q;
	}

#ifndef NO_STRTOD_BIGCOMP

 static void
bigcomp
#ifdef KR_headers
	(rv, s0, bc)
	U *rv; CONST char *s0; BCinfo *bc;
#else
	(U *rv, CONST char *s0, BCinfo *bc)
#endif
{
	Bigint *b, *d;
	int b2, bbits, d2, dd, dig, dsign, i, j, nd, nd0, p2, p5, speccase;

	dsign = bc->dsign;
	nd = bc->nd;
	nd0 = bc->nd0;
	p5 = nd + bc->e0 - 1;
	dd = speccase = 0;
#ifndef Sudden_Underflow
	if (rv->d == 0.) {	/* special case: value near underflow-to-zero */
				/* threshold was rounded to zero */
		b = i2b(1);
		p2 = Emin - P + 1;
		bbits = 1;
#ifdef Avoid_Underflow
		word0(rv) = (P+2) << Exp_shift;
#else
		word1(rv) = 1;
#endif
		i = 0;
#ifdef Honor_FLT_ROUNDS
		if (bc->rounding == 1)
#endif
			{
			speccase = 1;
			--p2;
			dsign = 0;
			goto have_i;
			}
		}
	else
#endif
		b = d2b(rv, &p2, &bbits);
#ifdef Avoid_Underflow
	p2 -= bc->scale;
#endif
	/* floor(log2(rv)) == bbits - 1 + p2 */
	/* Check for denormal case. */
	i = P - bbits;
	if (i > (j = P - Emin - 1 + p2)) {
#ifdef Sudden_Underflow
		Bfree(b);
		b = i2b(1);
		p2 = Emin;
		i = P - 1;
#ifdef Avoid_Underflow
		word0(rv) = (1 + bc->scale) << Exp_shift;
#else
		word0(rv) = Exp_msk1;
#endif
		word1(rv) = 0;
#else
		i = j;
#endif
		}
#ifdef Honor_FLT_ROUNDS
	if (bc->rounding != 1) {
		if (i > 0)
			b = lshift(b, i);
		if (dsign)
			b = increment(b);
		}
	else
#endif
		{
		b = lshift(b, ++i);
		b->x[0] |= 1;
		}
#ifndef Sudden_Underflow
 have_i:
#endif
	p2 -= p5 + i;
	d = i2b(1);
	/* Arrange for convenient computation of quotients:
	 * shift left if necessary so divisor has 4 leading 0 bits.
	 */
	if (p5 > 0)
		d = pow5mult(d, p5);
	else if (p5 < 0)
		b = pow5mult(b, -p5);
	if (p2 > 0) {
		b2 = p2;
		d2 = 0;
		}
	else {
		b2 = 0;
		d2 = -p2;
		}
	i = dshift(d, d2);
	if ((b2 += i) > 0)
		b = lshift(b, b2);
	if ((d2 += i) > 0)
		d = lshift(d, d2);

	/* Now b/d = exactly half-way between the two floating-point values */
	/* on either side of the input string.  Compute first digit of b/d. */

	dig = quorem(b,d);
	if (!dig) {
		b = multadd(b, 10, 0);	/* very unlikely */
		dig = quorem(b,d);
		}

	/* Compare b/d with s0 */

	for(i = 0; i < nd0; ) {
		dd = s0[i++] - '0' - dig;
		if (dd)
			goto ret;
		if (!b->x[0] && b->wds == 1) {
			if (i < nd)
				dd = 1;
			goto ret;
			}
		b = multadd(b, 10, 0);
		dig = quorem(b,d);
		}
	for(j = bc->dp1; i++ < nd;) {
		dd = s0[j++] - '0' - dig;
		if (dd)
			goto ret;
		if (!b->x[0] && b->wds == 1) {
			if (i < nd)
				dd = 1;
			goto ret;
			}
		b = multadd(b, 10, 0);
		dig = quorem(b,d);
		}
	if (b->x[0] || b->wds > 1)
		dd = -1;
 ret:
	Bfree(b);
	Bfree(d);
#ifdef Honor_FLT_ROUNDS
	if (bc->rounding != 1) {
		if (dd < 0) {
			if (bc->rounding == 0) {
				if (!dsign)
					goto retlow1;
				}
			else if (dsign)
				goto rethi1;
			}
		else if (dd > 0) {
			if (bc->rounding == 0) {
				if (dsign)
					goto rethi1;
				goto ret1;
				}
			if (!dsign)
				goto rethi1;
			dval(rv) += 2.*ulp(rv);
			}
		else {
			bc->inexact = 0;
			if (dsign)
				goto rethi1;
			}
		}
	else
#endif
	if (speccase) {
		if (dd <= 0)
			rv->d = 0.;
		}
	else if (dd < 0) {
		if (!dsign)	/* does not happen for round-near */
retlow1:
			dval(rv) -= ulp(rv);
		}
	else if (dd > 0) {
		if (dsign) {
 rethi1:
			dval(rv) += ulp(rv);
			}
		}
	else {
		/* Exact half-way case:  apply round-even rule. */
		if (word1(rv) & 1) {
			if (dsign)
				goto rethi1;
			goto retlow1;
			}
		}

#ifdef Honor_FLT_ROUNDS
 ret1:
#endif
	return;
	}
#endif /* NO_STRTOD_BIGCOMP */

 double
strtod
#ifdef KR_headers
	(s00, se) CONST char *s00; char **se;
#else
	(CONST char *s00, char **se)
#endif
{
	int bb2, bb5, bbe, bd2, bd5, bbbits, bs2, c, e, e1;
	int esign, i, j, k, nd, nd0, nf, nz, nz0, sign;
	CONST char *s, *s0, *s1;
	double aadj, aadj1;
	Long L;
	U aadj2, adj, rv, rv0;
	ULong y, z;
	BCinfo bc;
	Bigint *bb, *bb1, *bd, *bd0, *bs, *delta;
#ifdef SET_INEXACT
	int oldinexact;
#endif
#ifdef Honor_FLT_ROUNDS /*{*/
#ifdef Trust_FLT_ROUNDS /*{{ only define this if FLT_ROUNDS really works! */
	bc.rounding = Flt_Rounds;
#else /*}{*/
	bc.rounding = 1;
	switch(fegetround()) {
	  case FE_TOWARDZERO:	bc.rounding = 0; break;
	  case FE_UPWARD:	bc.rounding = 2; break;
	  case FE_DOWNWARD:	bc.rounding = 3;
	  }
#endif /*}}*/
#endif /*}*/
#ifdef USE_LOCALE
	CONST char *s2;
#endif

	sign = nz0 = nz = bc.dplen = bc.uflchk = 0;
	dval(&rv) = 0.;
	for(s = s00;;s++) switch(*s) {
		case '-':
			sign = 1;
			/* no break */
		case '+':
			if (*++s)
				goto break2;
			/* no break */
		case 0:
			goto ret0;
		case '\t':
		case '\n':
		case '\v':
		case '\f':
		case '\r':
		case ' ':
			continue;
		default:
			goto break2;
		}
 break2:
	if (*s == '0') {
#ifndef NO_HEX_FP /*{*/
		switch(s[1]) {
		  case 'x':
		  case 'X':
#ifdef Honor_FLT_ROUNDS
			gethex(&s, &rv, bc.rounding, sign);
#else
			gethex(&s, &rv, 1, sign);
#endif
			goto ret;
		  }
#endif /*}*/
		nz0 = 1;
		while(*++s == '0') ;
		if (!*s)
			goto ret;
		}
	s0 = s;
	y = z = 0;
	for(nd = nf = 0; (c = *s) >= '0' && c <= '9'; nd++, s++)
		if (nd < 9)
			y = 10*y + c - '0';
		else if (nd < 16)
			z = 10*z + c - '0';
	nd0 = nd;
	bc.dp0 = bc.dp1 = s - s0;
#ifdef USE_LOCALE
	s1 = localeconv()->decimal_point;
	if (c == *s1) {
		c = '.';
		if (*++s1) {
			s2 = s;
			for(;;) {
				if (*++s2 != *s1) {
					c = 0;
					break;
					}
				if (!*++s1) {
					s = s2;
					break;
					}
				}
			}
		}
#endif
	if (c == '.') {
		c = *++s;
		bc.dp1 = s - s0;
		bc.dplen = bc.dp1 - bc.dp0;
		if (!nd) {
			for(; c == '0'; c = *++s)
				nz++;
			if (c > '0' && c <= '9') {
				s0 = s;
				nf += nz;
				nz = 0;
				goto have_dig;
				}
			goto dig_done;
			}
		for(; c >= '0' && c <= '9'; c = *++s) {
 have_dig:
			nz++;
			if (c -= '0') {
				nf += nz;
				for(i = 1; i < nz; i++)
					if (nd++ < 9)
						y *= 10;
					else if (nd <= DBL_DIG + 1)
						z *= 10;
				if (nd++ < 9)
					y = 10*y + c;
				else if (nd <= DBL_DIG + 1)
					z = 10*z + c;
				nz = 0;
				}
			}
		}
 dig_done:
	e = 0;
	if (c == 'e' || c == 'E') {
		if (!nd && !nz && !nz0) {
			goto ret0;
			}
		s00 = s;
		esign = 0;
		switch(c = *++s) {
			case '-':
				esign = 1;
			case '+':
				c = *++s;
			}
		if (c >= '0' && c <= '9') {
			while(c == '0')
				c = *++s;
			if (c > '0' && c <= '9') {
				L = c - '0';
				s1 = s;
				while((c = *++s) >= '0' && c <= '9')
					L = 10*L + c - '0';
				if (s - s1 > 8 || L > 19999)
					/* Avoid confusion from exponents
					 * so large that e might overflow.
					 */
					e = 19999; /* safe for 16 bit ints */
				else
					e = (int)L;
				if (esign)
					e = -e;
				}
			else
				e = 0;
			}
		else
			s = s00;
		}
	if (!nd) {
		if (!nz && !nz0) {
#ifdef INFNAN_CHECK
			/* Check for Nan and Infinity */
			if (!bc.dplen)
			 switch(c) {
			  case 'i':
			  case 'I':
				if (match(&s,"nf")) {
					--s;
					if (!match(&s,"inity"))
						++s;
					word0(&rv) = 0x7ff00000;
					word1(&rv) = 0;
					goto ret;
					}
				break;
			  case 'n':
			  case 'N':
				if (match(&s, "an")) {
					word0(&rv) = NAN_WORD0;
					word1(&rv) = NAN_WORD1;
#ifndef No_Hex_NaN
					if (*s == '(') /*)*/
						hexnan(&rv, &s);
#endif
					goto ret;
					}
			  }
#endif /* INFNAN_CHECK */
 ret0:
			s = s00;
			sign = 0;
			}
		goto ret;
		}
	bc.e0 = e1 = e -= nf;

	/* Now we have nd0 digits, starting at s0, followed by a
	 * decimal point, followed by nd-nd0 digits.  The number we're
	 * after is the integer represented by those digits times
	 * 10**e */

	if (!nd0)
		nd0 = nd;
	k = nd < DBL_DIG + 1 ? nd : DBL_DIG + 1;
	dval(&rv) = y;
	if (k > 9) {
#ifdef SET_INEXACT
		if (k > DBL_DIG)
			oldinexact = get_inexact();
#endif
		dval(&rv) = tens[k - 9] * dval(&rv) + z;
		}
	bd0 = 0;
	if (nd <= DBL_DIG
#ifndef RND_PRODQUOT
#ifndef Honor_FLT_ROUNDS
		&& Flt_Rounds == 1
#endif
#endif
			) {
		if (!e)
			goto ret;
		if (e > 0) {
			if (e <= Ten_pmax) {
#ifdef VAX
				goto vax_ovfl_check;
#else
#ifdef Honor_FLT_ROUNDS
				/* round correctly FLT_ROUNDS = 2 or 3 */
				if (sign) {
					rv.d = -rv.d;
					sign = 0;
					}
#endif
				/* rv = */ rounded_product(dval(&rv), tens[e]);
				goto ret;
#endif
				}
			i = DBL_DIG - nd;
			if (e <= Ten_pmax + i) {
				/* A fancier test would sometimes let us do
				 * this for larger i values.
				 */
#ifdef Honor_FLT_ROUNDS
				/* round correctly FLT_ROUNDS = 2 or 3 */
				if (sign) {
					rv.d = -rv.d;
					sign = 0;
					}
#endif
				e -= i;
				dval(&rv) *= tens[i];
#ifdef VAX
				/* VAX exponent range is so narrow we must
				 * worry about overflow here...
				 */
 vax_ovfl_check:
				word0(&rv) -= P*Exp_msk1;
				/* rv = */ rounded_product(dval(&rv), tens[e]);
				if ((word0(&rv) & Exp_mask)
				 > Exp_msk1*(DBL_MAX_EXP+Bias-1-P))
					goto ovfl;
				word0(&rv) += P*Exp_msk1;
#else
				/* rv = */ rounded_product(dval(&rv), tens[e]);
#endif
				goto ret;
				}
			}
#ifndef Inaccurate_Divide
		else if (e >= -Ten_pmax) {
#ifdef Honor_FLT_ROUNDS
			/* round correctly FLT_ROUNDS = 2 or 3 */
			if (sign) {
				rv.d = -rv.d;
				sign = 0;
				}
#endif
			/* rv = */ rounded_quotient(dval(&rv), tens[-e]);
			goto ret;
			}
#endif
		}
	e1 += nd - k;

#ifdef IEEE_Arith
#ifdef SET_INEXACT
	bc.inexact = 1;
	if (k <= DBL_DIG)
		oldinexact = get_inexact();
#endif
#ifdef Avoid_Underflow
	bc.scale = 0;
#endif
#ifdef Honor_FLT_ROUNDS
	if (bc.rounding >= 2) {
		if (sign)
			bc.rounding = bc.rounding == 2 ? 0 : 2;
		else
			if (bc.rounding != 2)
				bc.rounding = 0;
		}
#endif
#endif /*IEEE_Arith*/

	/* Get starting approximation = rv * 10**e1 */

	if (e1 > 0) {
		i = e1 & 15;
		if (i)
			dval(&rv) *= tens[i];
		if (e1 &= ~15) {
			if (e1 > DBL_MAX_10_EXP) {
 ovfl:
#ifndef NO_ERRNO
				errno = ERANGE;
#endif
				/* Can't trust HUGE_VAL */
#ifdef IEEE_Arith
#ifdef Honor_FLT_ROUNDS
				switch(bc.rounding) {
				  case 0: /* toward 0 */
				  case 3: /* toward -infinity */
					word0(&rv) = Big0;
					word1(&rv) = Big1;
					break;
				  default:
					word0(&rv) = Exp_mask;
					word1(&rv) = 0;
				  }
#else /*Honor_FLT_ROUNDS*/
				word0(&rv) = Exp_mask;
				word1(&rv) = 0;
#endif /*Honor_FLT_ROUNDS*/
#ifdef SET_INEXACT
				/* set overflow bit */
				dval(&rv0) = 1e300;
				dval(&rv0) *= dval(&rv0);
#endif
#else /*IEEE_Arith*/
				word0(&rv) = Big0;
				word1(&rv) = Big1;
#endif /*IEEE_Arith*/
				goto ret;
				}
			e1 >>= 4;
			for(j = 0; e1 > 1; j++, e1 >>= 1)
				if (e1 & 1)
					dval(&rv) *= bigtens[j];
		/* The last multiplication could overflow. */
			word0(&rv) -= P*Exp_msk1;
			dval(&rv) *= bigtens[j];
			if ((z = word0(&rv) & Exp_mask)
			 > Exp_msk1*(DBL_MAX_EXP+Bias-P))
				goto ovfl;
			if (z > Exp_msk1*(DBL_MAX_EXP+Bias-1-P)) {
				/* set to largest number */
				/* (Can't trust DBL_MAX) */
				word0(&rv) = Big0;
				word1(&rv) = Big1;
				}
			else
				word0(&rv) += P*Exp_msk1;
			}
		}
	else if (e1 < 0) {
		e1 = -e1;
		i = e1 & 15;
		if (i)
			dval(&rv) /= tens[i];
		if (e1 >>= 4) {
			if (e1 >= 1 << n_bigtens)
				goto undfl;
#ifdef Avoid_Underflow
			if (e1 & Scale_Bit)
				bc.scale = 2*P;
			for(j = 0; e1 > 0; j++, e1 >>= 1)
				if (e1 & 1)
					dval(&rv) *= tinytens[j];
			if (bc.scale && (j = 2*P + 1 - ((word0(&rv) & Exp_mask)
						>> Exp_shift)) > 0) {
				/* scaled rv is denormal; clear j low bits */
				if (j >= 32) {
					word1(&rv) = 0;
					if (j >= 53)
					 word0(&rv) = (P+2)*Exp_msk1;
					else
					 word0(&rv) &= 0xffffffff << (j-32);
					}
				else
					word1(&rv) &= 0xffffffff << j;
				}
#else
			for(j = 0; e1 > 1; j++, e1 >>= 1)
				if (e1 & 1)
					dval(&rv) *= tinytens[j];
			/* The last multiplication could underflow. */
			dval(&rv0) = dval(&rv);
			dval(&rv) *= tinytens[j];
			if (!dval(&rv)) {
				dval(&rv) = 2.*dval(&rv0);
				dval(&rv) *= tinytens[j];
#endif
				if (!dval(&rv)) {
 undfl:
					dval(&rv) = 0.;
#ifndef NO_ERRNO
					errno = ERANGE;
#endif
					goto ret;
					}
#ifndef Avoid_Underflow
				word0(&rv) = Tiny0;
				word1(&rv) = Tiny1;
				/* The refinement below will clean
				 * this approximation up.
				 */
				}
#endif
			}
		}

	/* Now the hard part -- adjusting rv to the correct value.*/

	/* Put digits into bd: true value = bd * 10^e */

	bc.nd = nd;
#ifndef NO_STRTOD_BIGCOMP
	bc.nd0 = nd0;	/* Only needed if nd > strtod_diglim, but done here */
			/* to silence an erroneous warning about bc.nd0 */
			/* possibly not being initialized. */
	if (nd > strtod_diglim) {
		/* ASSERT(strtod_diglim >= 18); 18 == one more than the */
		/* minimum number of decimal digits to distinguish double values */
		/* in IEEE arithmetic. */
		i = j = 18;
		if (i > nd0)
			j += bc.dplen;
		for(;;) {
			if (--j <= bc.dp1 && j >= bc.dp0)
				j = bc.dp0 - 1;
			if (s0[j] != '0')
				break;
			--i;
			}
		e += nd - i;
		nd = i;
		if (nd0 > nd)
			nd0 = nd;
		if (nd < 9) { /* must recompute y */
			y = 0;
			for(i = 0; i < nd0; ++i)
				y = 10*y + s0[i] - '0';
			for(j = bc.dp1; i < nd; ++i)
				y = 10*y + s0[j++] - '0';
			}
		}
#endif
	bd0 = s2b(s0, nd0, nd, y, bc.dplen);

	for(;;) {
		bd = Balloc(bd0->k);
		Bcopy(bd, bd0);
		bb = d2b(&rv, &bbe, &bbbits);	/* rv = bb * 2^bbe */
		bs = i2b(1);

		if (e >= 0) {
			bb2 = bb5 = 0;
			bd2 = bd5 = e;
			}
		else {
			bb2 = bb5 = -e;
			bd2 = bd5 = 0;
			}
		if (bbe >= 0)
			bb2 += bbe;
		else
			bd2 -= bbe;
		bs2 = bb2;
#ifdef Honor_FLT_ROUNDS
		if (bc.rounding != 1)
			bs2++;
#endif
#ifdef Avoid_Underflow
		j = bbe - bc.scale;
		i = j + bbbits - 1;	/* logb(rv) */
		if (i < Emin)	/* denormal */
			j += P - Emin;
		else
			j = P + 1 - bbbits;
#else /*Avoid_Underflow*/
#ifdef Sudden_Underflow
#ifdef IBM
		j = 1 + 4*P - 3 - bbbits + ((bbe + bbbits - 1) & 3);
#else
		j = P + 1 - bbbits;
#endif
#else /*Sudden_Underflow*/
		j = bbe;
		i = j + bbbits - 1;	/* logb(rv) */
		if (i < Emin)	/* denormal */
			j += P - Emin;
		else
			j = P + 1 - bbbits;
#endif /*Sudden_Underflow*/
#endif /*Avoid_Underflow*/
		bb2 += j;
		bd2 += j;
#ifdef Avoid_Underflow
		bd2 += bc.scale;
#endif
		i = bb2 < bd2 ? bb2 : bd2;
		if (i > bs2)
			i = bs2;
		if (i > 0) {
			bb2 -= i;
			bd2 -= i;
			bs2 -= i;
			}
		if (bb5 > 0) {
			bs = pow5mult(bs, bb5);
			bb1 = mult(bs, bb);
			Bfree(bb);
			bb = bb1;
			}
		if (bb2 > 0)
			bb = lshift(bb, bb2);
		if (bd5 > 0)
			bd = pow5mult(bd, bd5);
		if (bd2 > 0)
			bd = lshift(bd, bd2);
		if (bs2 > 0)
			bs = lshift(bs, bs2);
		delta = diff(bb, bd);
		bc.dsign = delta->sign;
		delta->sign = 0;
		i = cmp(delta, bs);
#ifndef NO_STRTOD_BIGCOMP
		if (bc.nd > nd && i <= 0) {
			if (bc.dsign)
				break;	/* Must use bigcomp(). */
#ifdef Honor_FLT_ROUNDS
			if (bc.rounding != 1) {
				if (i < 0)
					break;
				}
			else
#endif
				{
				bc.nd = nd;
				i = -1;	/* Discarded digits make delta smaller. */
				}
			}
#endif
#ifdef Honor_FLT_ROUNDS
		if (bc.rounding != 1) {
			if (i < 0) {
				/* Error is less than an ulp */
				if (!delta->x[0] && delta->wds <= 1) {
					/* exact */
#ifdef SET_INEXACT
					bc.inexact = 0;
#endif
					break;
					}
				if (bc.rounding) {
					if (bc.dsign) {
						adj.d = 1.;
						goto apply_adj;
						}
					}
				else if (!bc.dsign) {
					adj.d = -1.;
					if (!word1(&rv)
					 && !(word0(&rv) & Frac_mask)) {
						y = word0(&rv) & Exp_mask;
#ifdef Avoid_Underflow
						if (!bc.scale || y > 2*P*Exp_msk1)
#else
						if (y)
#endif
						  {
						  delta = lshift(delta,Log2P);
						  if (cmp(delta, bs) <= 0)
							adj.d = -0.5;
						  }
						}
 apply_adj:
#ifdef Avoid_Underflow
					if (bc.scale && (y = word0(&rv) & Exp_mask)
						<= 2*P*Exp_msk1)
					  word0(&adj) += (2*P+1)*Exp_msk1 - y;
#else
#ifdef Sudden_Underflow
					if ((word0(&rv) & Exp_mask) <=
							P*Exp_msk1) {
						word0(&rv) += P*Exp_msk1;
						dval(&rv) += adj.d*ulp(dval(&rv));
						word0(&rv) -= P*Exp_msk1;
						}
					else
#endif /*Sudden_Underflow*/
#endif /*Avoid_Underflow*/
					dval(&rv) += adj.d*ulp(&rv);
					}
				break;
				}
			adj.d = ratio(delta, bs);
			if (adj.d < 1.)
				adj.d = 1.;
			if (adj.d <= 0x7ffffffe) {
				/* adj = rounding ? ceil(adj) : floor(adj); */
				y = adj.d;
				if (y != adj.d) {
					if (!((bc.rounding>>1) ^ bc.dsign))
						y++;
					adj.d = y;
					}
				}
#ifdef Avoid_Underflow
			if (bc.scale && (y = word0(&rv) & Exp_mask) <= 2*P*Exp_msk1)
				word0(&adj) += (2*P+1)*Exp_msk1 - y;
#else
#ifdef Sudden_Underflow
			if ((word0(&rv) & Exp_mask) <= P*Exp_msk1) {
				word0(&rv) += P*Exp_msk1;
				adj.d *= ulp(dval(&rv));
				if (bc.dsign)
					dval(&rv) += adj.d;
				else
					dval(&rv) -= adj.d;
				word0(&rv) -= P*Exp_msk1;
				goto cont;
				}
#endif /*Sudden_Underflow*/
#endif /*Avoid_Underflow*/
			adj.d *= ulp(&rv);
			if (bc.dsign) {
				if (word0(&rv) == Big0 && word1(&rv) == Big1)
					goto ovfl;
				dval(&rv) += adj.d;
				}
			else
				dval(&rv) -= adj.d;
			goto cont;
			}
#endif /*Honor_FLT_ROUNDS*/

		if (i < 0) {
			/* Error is less than half an ulp -- check for
			 * special case of mantissa a power of two.
			 */
			if (bc.dsign || word1(&rv) || word0(&rv) & Bndry_mask
#ifdef IEEE_Arith
#ifdef Avoid_Underflow
			 || (word0(&rv) & Exp_mask) <= (2*P+1)*Exp_msk1
#else
			 || (word0(&rv) & Exp_mask) <= Exp_msk1
#endif
#endif
				) {
#ifdef SET_INEXACT
				if (!delta->x[0] && delta->wds <= 1)
					bc.inexact = 0;
#endif
				break;
				}
			if (!delta->x[0] && delta->wds <= 1) {
				/* exact result */
#ifdef SET_INEXACT
				bc.inexact = 0;
#endif
				break;
				}
			delta = lshift(delta,Log2P);
			if (cmp(delta, bs) > 0)
				goto drop_down;
			break;
			}
		if (i == 0) {
			/* exactly half-way between */
			if (bc.dsign) {
				if ((word0(&rv) & Bndry_mask1) == Bndry_mask1
				 &&  word1(&rv) == (
#ifdef Avoid_Underflow
			(bc.scale && (y = word0(&rv) & Exp_mask) <= 2*P*Exp_msk1)
		? (0xffffffff & (0xffffffff << (2*P+1-(y>>Exp_shift)))) :
#endif
						   0xffffffff)) {
					/*boundary case -- increment exponent*/
					word0(&rv) = (word0(&rv) & Exp_mask)
						+ Exp_msk1
#ifdef IBM
						| Exp_msk1 >> 4
#endif
						;
					word1(&rv) = 0;
#ifdef Avoid_Underflow
					bc.dsign = 0;
#endif
					break;
					}
				}
			else if (!(word0(&rv) & Bndry_mask) && !word1(&rv)) {
 drop_down:
				/* boundary case -- decrement exponent */
#ifdef Sudden_Underflow /*{{*/
				L = word0(&rv) & Exp_mask;
#ifdef IBM
				if (L <  Exp_msk1)
#else
#ifdef Avoid_Underflow
				if (L <= (bc.scale ? (2*P+1)*Exp_msk1 : Exp_msk1))
#else
				if (L <= Exp_msk1)
#endif /*Avoid_Underflow*/
#endif /*IBM*/
					{
					if (bc.nd >nd) {
						bc.uflchk = 1;
						break;
						}
					goto undfl;
					}
				L -= Exp_msk1;
#else /*Sudden_Underflow}{*/
#ifdef Avoid_Underflow
				if (bc.scale) {
					L = word0(&rv) & Exp_mask;
					if (L <= (2*P+1)*Exp_msk1) {
						if (L > (P+2)*Exp_msk1)
							/* round even ==> */
							/* accept rv */
							break;
						/* rv = smallest denormal */
						if (bc.nd >nd) {
							bc.uflchk = 1;
							break;
							}
						goto undfl;
						}
					}
#endif /*Avoid_Underflow*/
				L = (word0(&rv) & Exp_mask) - Exp_msk1;
#endif /*Sudden_Underflow}}*/
				word0(&rv) = L | Bndry_mask1;
				word1(&rv) = 0xffffffff;
#ifdef IBM
				goto cont;
#else
				break;
#endif
				}
#ifndef ROUND_BIASED
			if (!(word1(&rv) & LSB))
				break;
#endif
			if (bc.dsign)
				dval(&rv) += ulp(&rv);
#ifndef ROUND_BIASED
			else {
				dval(&rv) -= ulp(&rv);
#ifndef Sudden_Underflow
				if (!dval(&rv)) {
					if (bc.nd >nd) {
						bc.uflchk = 1;
						break;
						}
					goto undfl;
					}
#endif
				}
#ifdef Avoid_Underflow
			bc.dsign = 1 - bc.dsign;
#endif
#endif
			break;
			}
		if ((aadj = ratio(delta, bs)) <= 2.) {
			if (bc.dsign)
				aadj = aadj1 = 1.;
			else if (word1(&rv) || word0(&rv) & Bndry_mask) {
#ifndef Sudden_Underflow
				if (word1(&rv) == Tiny1 && !word0(&rv)) {
					if (bc.nd >nd) {
						bc.uflchk = 1;
						break;
						}
					goto undfl;
					}
#endif
				aadj = 1.;
				aadj1 = -1.;
				}
			else {
				/* special case -- power of FLT_RADIX to be */
				/* rounded down... */

				if (aadj < 2./FLT_RADIX)
					aadj = 1./FLT_RADIX;
				else
					aadj *= 0.5;
				aadj1 = -aadj;
				}
			}
		else {
			aadj *= 0.5;
			aadj1 = bc.dsign ? aadj : -aadj;
#ifdef Check_FLT_ROUNDS
			switch(bc.rounding) {
				case 2: /* towards +infinity */
					aadj1 -= 0.5;
					break;
				case 0: /* towards 0 */
				case 3: /* towards -infinity */
					aadj1 += 0.5;
				}
#else
			if (Flt_Rounds == 0)
				aadj1 += 0.5;
#endif /*Check_FLT_ROUNDS*/
			}
		y = word0(&rv) & Exp_mask;

		/* Check for overflow */

		if (y == Exp_msk1*(DBL_MAX_EXP+Bias-1)) {
			dval(&rv0) = dval(&rv);
			word0(&rv) -= P*Exp_msk1;
			adj.d = aadj1 * ulp(&rv);
			dval(&rv) += adj.d;
			if ((word0(&rv) & Exp_mask) >=
					Exp_msk1*(DBL_MAX_EXP+Bias-P)) {
				if (word0(&rv0) == Big0 && word1(&rv0) == Big1)
					goto ovfl;
				word0(&rv) = Big0;
				word1(&rv) = Big1;
				goto cont;
				}
			else
				word0(&rv) += P*Exp_msk1;
			}
		else {
#ifdef Avoid_Underflow
			if (bc.scale && y <= 2*P*Exp_msk1) {
				if (aadj <= 0x7fffffff) {
					if ((z = (ULong)aadj) <= 0)
						z = 1;
					aadj = z;
					aadj1 = bc.dsign ? aadj : -aadj;
					}
				dval(&aadj2) = aadj1;
				word0(&aadj2) += (2*P+1)*Exp_msk1 - y;
				aadj1 = dval(&aadj2);
				}
			adj.d = aadj1 * ulp(&rv);
			dval(&rv) += adj.d;
#else
#ifdef Sudden_Underflow
			if ((word0(&rv) & Exp_mask) <= P*Exp_msk1) {
				dval(&rv0) = dval(&rv);
				word0(&rv) += P*Exp_msk1;
				adj.d = aadj1 * ulp(&rv);
				dval(&rv) += adj.d;
#ifdef IBM
				if ((word0(&rv) & Exp_mask) <  P*Exp_msk1)
#else
				if ((word0(&rv) & Exp_mask) <= P*Exp_msk1)
#endif
					{
					if (word0(&rv0) == Tiny0
					 && word1(&rv0) == Tiny1) {
						if (bc.nd >nd) {
							bc.uflchk = 1;
							break;
							}
						goto undfl;
						}
					word0(&rv) = Tiny0;
					word1(&rv) = Tiny1;
					goto cont;
					}
				else
					word0(&rv) -= P*Exp_msk1;
				}
			else {
				adj.d = aadj1 * ulp(&rv);
				dval(&rv) += adj.d;
				}
#else /*Sudden_Underflow*/
			/* Compute adj so that the IEEE rounding rules will
			 * correctly round rv + adj in some half-way cases.
			 * If rv * ulp(rv) is denormalized (i.e.,
			 * y <= (P-1)*Exp_msk1), we must adjust aadj to avoid
			 * trouble from bits lost to denormalization;
			 * example: 1.2e-307 .
			 */
			if (y <= (P-1)*Exp_msk1 && aadj > 1.) {
				aadj1 = (double)(int)(aadj + 0.5);
				if (!bc.dsign)
					aadj1 = -aadj1;
				}
			adj.d = aadj1 * ulp(&rv);
			dval(&rv) += adj.d;
#endif /*Sudden_Underflow*/
#endif /*Avoid_Underflow*/
			}
		z = word0(&rv) & Exp_mask;
#ifndef SET_INEXACT
		if (bc.nd == nd) {
#ifdef Avoid_Underflow
		if (!bc.scale)
#endif
		if (y == z) {
			/* Can we stop now? */
			L = (Long)aadj;
			aadj -= L;
			/* The tolerances below are conservative. */
			if (bc.dsign || word1(&rv) || word0(&rv) & Bndry_mask) {
				if (aadj < .4999999 || aadj > .5000001)
					break;
				}
			else if (aadj < .4999999/FLT_RADIX)
				break;
			}
		}
#endif
 cont:
		Bfree(bb);
		Bfree(bd);
		Bfree(bs);
		Bfree(delta);
		}
	Bfree(bb);
	Bfree(bd);
	Bfree(bs);
	Bfree(bd0);
	Bfree(delta);
#ifndef NO_STRTOD_BIGCOMP
	if (bc.nd > nd)
		bigcomp(&rv, s0, &bc);
#endif
#ifdef SET_INEXACT
	if (bc.inexact) {
		if (!oldinexact) {
			word0(&rv0) = Exp_1 + (70 << Exp_shift);
			word1(&rv0) = 0;
			dval(&rv0) += 1.;
			}
		}
	else if (!oldinexact)
		clear_inexact();
#endif
#ifdef Avoid_Underflow
	if (bc.scale) {
		word0(&rv0) = Exp_1 - 2*P*Exp_msk1;
		word1(&rv0) = 0;
		dval(&rv) *= dval(&rv0);
#ifndef NO_ERRNO
		/* try to avoid the bug of testing an 8087 register value */
#ifdef IEEE_Arith
		if (!(word0(&rv) & Exp_mask))
#else
		if (word0(&rv) == 0 && word1(&rv) == 0)
#endif
			errno = ERANGE;
#endif
		}
#endif /* Avoid_Underflow */
#ifdef SET_INEXACT
	if (bc.inexact && !(word0(&rv) & Exp_mask)) {
		/* set underflow bit */
		dval(&rv0) = 1e-300;
		dval(&rv0) *= dval(&rv0);
		}
#endif
 ret:
	if (se)
		*se = (char *)s;
	return sign ? -dval(&rv) : dval(&rv);
	}

#ifndef MULTIPLE_THREADS
 static char *dtoa_result;
#endif

 static char *
#ifdef KR_headers
rv_alloc(i) int i;
#else
rv_alloc(int i)
#endif
{
	int j, k, *r;

	j = sizeof(ULong);
	for(k = 0;
		sizeof(Bigint) - sizeof(ULong) - sizeof(int) + j <= (size_t)i;
		j <<= 1)
			k++;
	r = (int*)Balloc(k);
	*r = k;
	return
#ifndef MULTIPLE_THREADS
	dtoa_result =
#endif
		(char *)(r+1);
	}

 static char *
#ifdef KR_headers
nrv_alloc(s, rve, n) char *s, **rve; int n;
#else
nrv_alloc(CONST char *s, char **rve, int n)
#endif
{
	char *rv, *t;

	t = rv = rv_alloc(n);
	for(*t = *s++; *t; *t = *s++) t++;
	if (rve)
		*rve = t;
	return rv;
	}

/* freedtoa(s) must be used to free values s returned by dtoa
 * when MULTIPLE_THREADS is #defined.  It should be used in all cases,
 * but for consistency with earlier versions of dtoa, it is optional
 * when MULTIPLE_THREADS is not defined.
 */

 void
#ifdef KR_headers
freedtoa(s) char *s;
#else
freedtoa(char *s)
#endif
{
	Bigint *b = (Bigint *)((int *)s - 1);
	b->maxwds = 1 << (b->k = *(int*)b);
	Bfree(b);
#ifndef MULTIPLE_THREADS
	if (s == dtoa_result)
		dtoa_result = 0;
#endif
	}

/* dtoa for IEEE arithmetic (dmg): convert double to ASCII string.
 *
 * Inspired by "How to Print Floating-Point Numbers Accurately" by
 * Guy L. Steele, Jr. and Jon L. White [Proc. ACM SIGPLAN '90, pp. 112-126].
 *
 * Modifications:
 *	1. Rather than iterating, we use a simple numeric overestimate
 *	   to determine k = floor(log10(d)).  We scale relevant
 *	   quantities using O(log2(k)) rather than O(k) multiplications.
 *	2. For some modes > 2 (corresponding to ecvt and fcvt), we don't
 *	   try to generate digits strictly left to right.  Instead, we
 *	   compute with fewer bits and propagate the carry if necessary
 *	   when rounding the final digit up.  This is often faster.
 *	3. Under the assumption that input will be rounded nearest,
 *	   mode 0 renders 1e23 as 1e23 rather than 9.999999999999999e22.
 *	   That is, we allow equality in stopping tests when the
 *	   round-nearest rule will give the same floating-point value
 *	   as would satisfaction of the stopping test with strict
 *	   inequality.
 *	4. We remove common factors of powers of 2 from relevant
 *	   quantities.
 *	5. When converting floating-point integers less than 1e16,
 *	   we use floating-point arithmetic rather than resorting
 *	   to multiple-precision integers.
 *	6. When asked to produce fewer than 15 digits, we first try
 *	   to get by with floating-point arithmetic; we resort to
 *	   multiple-precision integer arithmetic only if we cannot
 *	   guarantee that the floating-point calculation has given
 *	   the correctly rounded result.  For k requested digits and
 *	   "uniformly" distributed input, the probability is
 *	   something like 10^(k-15) that we must resort to the Long
 *	   calculation.
 */

 char *
dtoa
#ifdef KR_headers
	(dd, mode, ndigits, decpt, sign, rve)
	double dd; int mode, ndigits, *decpt, *sign; char **rve;
#else
	(double dd, int mode, int ndigits, int *decpt, int *sign, char **rve)
#endif
{
 /*	Arguments ndigits, decpt, sign are similar to those
	of ecvt and fcvt; trailing zeros are suppressed from
	the returned string.  If not null, *rve is set to point
	to the end of the return value.  If d is +-Infinity or NaN,
	then *decpt is set to 9999.

	mode:
		0 ==> shortest string that yields d when read in
			and rounded to nearest.
		1 ==> like 0, but with Steele & White stopping rule;
			e.g. with IEEE P754 arithmetic , mode 0 gives
			1e23 whereas mode 1 gives 9.999999999999999e22.
		2 ==> max(1,ndigits) significant digits.  This gives a
			return value similar to that of ecvt, except
			that trailing zeros are suppressed.
		3 ==> through ndigits past the decimal point.  This
			gives a return value similar to that from fcvt,
			except that trailing zeros are suppressed, and
			ndigits can be negative.
		4,5 ==> similar to 2 and 3, respectively, but (in
			round-nearest mode) with the tests of mode 0 to
			possibly return a shorter string that rounds to d.
			With IEEE arithmetic and compilation with
			-DHonor_FLT_ROUNDS, modes 4 and 5 behave the same
			as modes 2 and 3 when FLT_ROUNDS != 1.
		6-9 ==> Debugging modes similar to mode - 4:  don't try
			fast floating-point estimate (if applicable).

		Values of mode other than 0-9 are treated as mode 0.

		Sufficient space is allocated to the return value
		to hold the suppressed trailing zeros.
	*/

	int bbits, b2, b5, be, dig, i, ieps, ilim, ilim0, ilim1,
		j, j1, k, k0, k_check, leftright, m2, m5, s2, s5,
		spec_case, try_quick;
	Long L;
#ifndef Sudden_Underflow
	int denorm;
	ULong x;
#endif
	Bigint *b, *b1, *delta, *mlo = NULL, *mhi, *S;
	U d2, eps, u;
	double ds;
	char *s, *s0;
#ifdef SET_INEXACT
	int inexact, oldinexact;
#endif
#ifdef Honor_FLT_ROUNDS /*{*/
	int Rounding;
#ifdef Trust_FLT_ROUNDS /*{{ only define this if FLT_ROUNDS really works! */
	Rounding = Flt_Rounds;
#else /*}{*/
	Rounding = 1;
	switch(fegetround()) {
	  case FE_TOWARDZERO:	Rounding = 0; break;
	  case FE_UPWARD:	Rounding = 2; break;
	  case FE_DOWNWARD:	Rounding = 3;
	  }
#endif /*}}*/
#endif /*}*/

#ifndef MULTIPLE_THREADS
	if (dtoa_result) {
		freedtoa(dtoa_result);
		dtoa_result = 0;
		}
#endif

	u.d = dd;
	if (word0(&u) & Sign_bit) {
		/* set sign for everything, including 0's and NaNs */
		*sign = 1;
		word0(&u) &= ~Sign_bit;	/* clear sign bit */
		}
	else
		*sign = 0;

#if defined(IEEE_Arith) + defined(VAX)
#ifdef IEEE_Arith
	if ((word0(&u) & Exp_mask) == Exp_mask)
#else
	if (word0(&u)  == 0x8000)
#endif
		{
		/* Infinity or NaN */
		*decpt = 9999;
#ifdef IEEE_Arith
		if (!word1(&u) && !(word0(&u) & 0xfffff))
			return nrv_alloc("Infinity", rve, 8);
#endif
		return nrv_alloc("NaN", rve, 3);
		}
#endif
#ifdef IBM
	dval(&u) += 0; /* normalize */
#endif
	if (!dval(&u)) {
		*decpt = 1;
		return nrv_alloc("0", rve, 1);
		}

#ifdef SET_INEXACT
	try_quick = oldinexact = get_inexact();
	inexact = 1;
#endif
#ifdef Honor_FLT_ROUNDS
	if (Rounding >= 2) {
		if (*sign)
			Rounding = Rounding == 2 ? 0 : 2;
		else
			if (Rounding != 2)
				Rounding = 0;
		}
#endif

	b = d2b(&u, &be, &bbits);
	i = (int)(word0(&u) >> Exp_shift1 & (Exp_mask>>Exp_shift1));
#ifndef Sudden_Underflow
	if (i) {
#endif
		dval(&d2) = dval(&u);
		word0(&d2) &= Frac_mask1;
		word0(&d2) |= Exp_11;
#ifdef IBM
		if (j = 11 - hi0bits(word0(&d2) & Frac_mask))
			dval(&d2) /= 1 << j;
#endif

		/* log(x)	~=~ log(1.5) + (x-1.5)/1.5
		 * log10(x)	 =  log(x) / log(10)
		 *		~=~ log(1.5)/log(10) + (x-1.5)/(1.5*log(10))
		 * log10(d) = (i-Bias)*log(2)/log(10) + log10(d2)
		 *
		 * This suggests computing an approximation k to log10(d) by
		 *
		 * k = (i - Bias)*0.301029995663981
		 *	+ ( (d2-1.5)*0.289529654602168 + 0.176091259055681 );
		 *
		 * We want k to be too large rather than too small.
		 * The error in the first-order Taylor series approximation
		 * is in our favor, so we just round up the constant enough
		 * to compensate for any error in the multiplication of
		 * (i - Bias) by 0.301029995663981; since |i - Bias| <= 1077,
		 * and 1077 * 0.30103 * 2^-52 ~=~ 7.2e-14,
		 * adding 1e-13 to the constant term more than suffices.
		 * Hence we adjust the constant term to 0.1760912590558.
		 * (We could get a more accurate k by invoking log10,
		 *  but this is probably not worthwhile.)
		 */

		i -= Bias;
#ifdef IBM
		i <<= 2;
		i += j;
#endif
#ifndef Sudden_Underflow
		denorm = 0;
		}
	else {
		/* d is denormalized */

		i = bbits + be + (Bias + (P-1) - 1);
		x = i > 32  ? word0(&u) << (64 - i) | word1(&u) >> (i - 32)
			    : word1(&u) << (32 - i);
		dval(&d2) = x;
		word0(&d2) -= 31*Exp_msk1; /* adjust exponent */
		i -= (Bias + (P-1) - 1) + 1;
		denorm = 1;
		}
#endif
	ds = (dval(&d2)-1.5)*0.289529654602168 + 0.1760912590558 + i*0.301029995663981;
	k = (int)ds;
	if (ds < 0. && ds != k)
		k--;	/* want k = floor(ds) */
	k_check = 1;
	if (k >= 0 && k <= Ten_pmax) {
		if (dval(&u) < tens[k])
			k--;
		k_check = 0;
		}
	j = bbits - i - 1;
	if (j >= 0) {
		b2 = 0;
		s2 = j;
		}
	else {
		b2 = -j;
		s2 = 0;
		}
	if (k >= 0) {
		b5 = 0;
		s5 = k;
		s2 += k;
		}
	else {
		b2 -= k;
		b5 = -k;
		s5 = 0;
		}
	if (mode < 0 || mode > 9)
		mode = 0;

#ifndef SET_INEXACT
#ifdef Check_FLT_ROUNDS
	try_quick = Rounding == 1;
#else
	try_quick = 1;
#endif
#endif /*SET_INEXACT*/

	if (mode > 5) {
		mode -= 4;
		try_quick = 0;
		}
	leftright = 1;
	ilim = ilim1 = -1;	/* Values for cases 0 and 1; done here to */
				/* silence erroneous "gcc -Wall" warning. */
	switch(mode) {
		case 0:
		case 1:
			i = 18;
			ndigits = 0;
			break;
		case 2:
			leftright = 0;
			/* no break */
		case 4:
			if (ndigits <= 0)
				ndigits = 1;
			ilim = ilim1 = i = ndigits;
			break;
		case 3:
			leftright = 0;
			/* no break */
		case 5:
			i = ndigits + k + 1;
			ilim = i;
			ilim1 = i - 1;
			if (i <= 0)
				i = 1;
		}
	s = s0 = rv_alloc(i);

#ifdef Honor_FLT_ROUNDS
	if (mode > 1 && Rounding != 1)
		leftright = 0;
#endif

	if (ilim >= 0 && ilim <= Quick_max && try_quick) {

		/* Try to get by with floating-point arithmetic. */

		i = 0;
		dval(&d2) = dval(&u);
		k0 = k;
		ilim0 = ilim;
		ieps = 2; /* conservative */
		if (k > 0) {
			ds = tens[k&0xf];
			j = k >> 4;
			if (j & Bletch) {
				/* prevent overflows */
				j &= Bletch - 1;
				dval(&u) /= bigtens[n_bigtens-1];
				ieps++;
				}
			for(; j; j >>= 1, i++)
				if (j & 1) {
					ieps++;
					ds *= bigtens[i];
					}
			dval(&u) /= ds;
			}
		else {
			j1 = -k;
			if (j1) {
				dval(&u) *= tens[j1 & 0xf];
				for(j = j1 >> 4; j; j >>= 1, i++)
					if (j & 1) {
						ieps++;
						dval(&u) *= bigtens[i];
						}
				}
			}
		if (k_check && dval(&u) < 1. && ilim > 0) {
			if (ilim1 <= 0)
				goto fast_failed;
			ilim = ilim1;
			k--;
			dval(&u) *= 10.;
			ieps++;
			}
		dval(&eps) = ieps*dval(&u) + 7.;
		word0(&eps) -= (P-1)*Exp_msk1;
		if (ilim == 0) {
			S = mhi = 0;
			dval(&u) -= 5.;
			if (dval(&u) > dval(&eps))
				goto one_digit;
			if (dval(&u) < -dval(&eps))
				goto no_digits;
			goto fast_failed;
			}
#ifndef No_leftright
		if (leftright) {
			/* Use Steele & White method of only
			 * generating digits needed.
			 */
			dval(&eps) = 0.5/tens[ilim-1] - dval(&eps);
			for(i = 0;;) {
				L = (long)dval(&u);
				dval(&u) -= L;
				*s++ = '0' + (char)L;
				if (dval(&u) < dval(&eps))
					goto ret1;
				if (1. - dval(&u) < dval(&eps))
					goto bump_up;
				if (++i >= ilim)
					break;
				dval(&eps) *= 10.;
				dval(&u) *= 10.;
				}
			}
		else {
#endif
			/* Generate ilim digits, then fix them up. */
			dval(&eps) *= tens[ilim-1];
			for(i = 1;; i++, dval(&u) *= 10.) {
				L = (Long)(dval(&u));
				if (!(dval(&u) -= L))
					ilim = i;
				*s++ = '0' + (char)L;
				if (i == ilim) {
					if (dval(&u) > 0.5 + dval(&eps))
						goto bump_up;
					else if (dval(&u) < 0.5 - dval(&eps)) {
						while(*--s == '0') {}
						s++;
						goto ret1;
						}
					break;
					}
				}
#ifndef No_leftright
			}
#endif
 fast_failed:
		s = s0;
		dval(&u) = dval(&d2);
		k = k0;
		ilim = ilim0;
		}

	/* Do we have a "small" integer? */

	if (be >= 0 && k <= Int_max) {
		/* Yes. */
		ds = tens[k];
		if (ndigits < 0 && ilim <= 0) {
			S = mhi = 0;
			if (ilim < 0 || dval(&u) <= 5*ds)
				goto no_digits;
			goto one_digit;
			}
		for(i = 1; i <= k + 1; i++, dval(&u) *= 10.) {
			L = (Long)(dval(&u) / ds);
			dval(&u) -= L*ds;
#ifdef Check_FLT_ROUNDS
			/* If FLT_ROUNDS == 2, L will usually be high by 1 */
			if (dval(&u) < 0) {
				L--;
				dval(&u) += ds;
				}
#endif
			*s++ = '0' + (char)L;
			if (!dval(&u)) {
#ifdef SET_INEXACT
				inexact = 0;
#endif
				break;
				}
			if (i == ilim) {
#ifdef Honor_FLT_ROUNDS
				if (mode > 1)
				switch(Rounding) {
				  case 0: goto ret1;
				  case 2: goto bump_up;
				  }
#endif
				dval(&u) += dval(&u);
				if (dval(&u) > ds || (dval(&u) == ds && L & 1)) {
 bump_up:
					while(*--s == '9')
						if (s == s0) {
							k++;
							*s = '0';
							break;
							}
					++*s++;
					}
				break;
				}
			}
		goto ret1;
		}

	m2 = b2;
	m5 = b5;
	mhi = mlo = 0;
	if (leftright) {
		i =
#ifndef Sudden_Underflow
			denorm ? be + (Bias + (P-1) - 1 + 1) :
#endif
#ifdef IBM
			1 + 4*P - 3 - bbits + ((bbits + be - 1) & 3);
#else
			1 + P - bbits;
#endif
		b2 += i;
		s2 += i;
		mhi = i2b(1);
		}
	if (m2 > 0 && s2 > 0) {
		i = m2 < s2 ? m2 : s2;
		b2 -= i;
		m2 -= i;
		s2 -= i;
		}
	if (b5 > 0) {
		if (leftright) {
			if (m5 > 0) {
				mhi = pow5mult(mhi, m5);
				b1 = mult(mhi, b);
				Bfree(b);
				b = b1;
				}
			j = b5 - m5;
			if (j)
				b = pow5mult(b, j);
			}
		else
			b = pow5mult(b, b5);
		}
	S = i2b(1);
	if (s5 > 0)
		S = pow5mult(S, s5);

	/* Check for special case that d is a normalized power of 2. */

	spec_case = 0;
	if ((mode < 2 || leftright)
#ifdef Honor_FLT_ROUNDS
			&& Rounding == 1
#endif
				) {
		if (!word1(&u) && !(word0(&u) & Bndry_mask)
#ifndef Sudden_Underflow
		 && word0(&u) & (Exp_mask & ~Exp_msk1)
#endif
				) {
			/* The special case */
			b2 += Log2P;
			s2 += Log2P;
			spec_case = 1;
			}
		}

	/* Arrange for convenient computation of quotients:
	 * shift left if necessary so divisor has 4 leading 0 bits.
	 *
	 * Perhaps we should just compute leading 28 bits of S once
	 * and for all and pass them and a shift to quorem, so it
	 * can do shifts and ors to compute the numerator for q.
	 */
#ifdef Pack_32
	i = ((s5 ? 32 - hi0bits(S->x[S->wds-1]) : 1) + s2) & 0x1f;
	if (i)
		i = 32 - i;
#define iInc 28
#else
	if (i = ((s5 ? 32 - hi0bits(S->x[S->wds-1]) : 1) + s2) & 0xf)
		i = 16 - i;
#define iInc 12
#endif
	i = dshift(S, s2);
	b2 += i;
	m2 += i;
	s2 += i;
	if (b2 > 0)
		b = lshift(b, b2);
	if (s2 > 0)
		S = lshift(S, s2);
	if (k_check) {
		if (cmp(b,S) < 0) {
			k--;
			b = multadd(b, 10, 0);	/* we botched the k estimate */
			if (leftright)
				mhi = multadd(mhi, 10, 0);
			ilim = ilim1;
			}
		}
	if (ilim <= 0 && (mode == 3 || mode == 5)) {
		if (ilim < 0 || cmp(b,S = multadd(S,5,0)) <= 0) {
			/* no digits, fcvt style */
 no_digits:
			k = -1 - ndigits;
			goto ret;
			}
 one_digit:
		*s++ = '1';
		k++;
		goto ret;
		}
	if (leftright) {
		if (m2 > 0)
			mhi = lshift(mhi, m2);

		/* Compute mlo -- check for special case
		 * that d is a normalized power of 2.
		 */

		mlo = mhi;
		if (spec_case) {
			mhi = Balloc(mhi->k);
			Bcopy(mhi, mlo);
			mhi = lshift(mhi, Log2P);
			}

		for(i = 1;;i++) {
			dig = quorem(b,S) + '0';
			/* Do we yet have the shortest decimal string
			 * that will round to d?
			 */
			j = cmp(b, mlo);
			delta = diff(S, mhi);
			j1 = delta->sign ? 1 : cmp(b, delta);
			Bfree(delta);
#ifndef ROUND_BIASED
			if (j1 == 0 && mode != 1 && !(word1(&u) & 1)
#ifdef Honor_FLT_ROUNDS
				&& Rounding >= 1
#endif
								   ) {
				if (dig == '9')
					goto round_9_up;
				if (j > 0)
					dig++;
#ifdef SET_INEXACT
				else if (!b->x[0] && b->wds <= 1)
					inexact = 0;
#endif
				*s++ = (char)dig;
				goto ret;
				}
#endif
			if (j < 0 || (j == 0 && mode != 1
#ifndef ROUND_BIASED
							&& !(word1(&u) & 1)
#endif
					)) {
				if (!b->x[0] && b->wds <= 1) {
#ifdef SET_INEXACT
					inexact = 0;
#endif
					goto accept_dig;
					}
#ifdef Honor_FLT_ROUNDS
				if (mode > 1)
				 switch(Rounding) {
				  case 0: goto accept_dig;
				  case 2: goto keep_dig;
				  }
#endif /*Honor_FLT_ROUNDS*/
				if (j1 > 0) {
					b = lshift(b, 1);
					j1 = cmp(b, S);
					if ((j1 > 0 || (j1 == 0 && dig & 1))
					&& dig++ == '9')
						goto round_9_up;
					}
 accept_dig:
				*s++ = (char)dig;
				goto ret;
				}
			if (j1 > 0) {
#ifdef Honor_FLT_ROUNDS
				if (!Rounding)
					goto accept_dig;
#endif
				if (dig == '9') { /* possible if i == 1 */
 round_9_up:
					*s++ = '9';
					goto roundoff;
					}
				*s++ = (char)dig + 1;
				goto ret;
				}
#ifdef Honor_FLT_ROUNDS
 keep_dig:
#endif
			*s++ = (char)dig;
			if (i == ilim)
				break;
			b = multadd(b, 10, 0);
			if (mlo == mhi)
				mlo = mhi = multadd(mhi, 10, 0);
			else {
				mlo = multadd(mlo, 10, 0);
				mhi = multadd(mhi, 10, 0);
				}
			}
		}
	else
		for(i = 1;; i++) {
			dig = quorem(b,S) + '0';
			*s++ = (char)dig;
			if (!b->x[0] && b->wds <= 1) {
#ifdef SET_INEXACT
				inexact = 0;
#endif
				goto ret;
				}
			if (i >= ilim)
				break;
			b = multadd(b, 10, 0);
			}

	/* Round off last digit */

#ifdef Honor_FLT_ROUNDS
	switch(Rounding) {
	  case 0: goto trimzeros;
	  case 2: goto roundoff;
	  }
#endif
	b = lshift(b, 1);
	j = cmp(b, S);
	if (j > 0 || (j == 0 && dig & 1)) {
 roundoff:
		while(*--s == '9')
			if (s == s0) {
				k++;
				*s++ = '1';
				goto ret;
				}
		++*s++;
		}
	else {
#ifdef Honor_FLT_ROUNDS
 trimzeros:
#endif
		while(*--s == '0') {}
		s++;
		}
 ret:
	Bfree(S);
	if (mhi) {
		if (mlo && mlo != mhi)
			Bfree(mlo);
		Bfree(mhi);
		}
 ret1:
#ifdef SET_INEXACT
	if (inexact) {
		if (!oldinexact) {
			word0(&u) = Exp_1 + (70 << Exp_shift);
			word1(&u) = 0;
			dval(&u) += 1.;
			}
		}
	else if (!oldinexact)
		clear_inexact();
#endif
	Bfree(b);
	*s = 0;
	*decpt = k + 1;
	if (rve)
		*rve = s;
	return s0;
	}

}  // namespace dmg_fp
