/****************************************************************
 *
 * The author of this software is David M. Gay.
 *
 * Copyright (c) 1991, 2000, 2001 by Lucent Technologies.
 * Copyright (C) 2002, 2005, 2006, 2007, 2008, 2010, 2012 Apple Inc. All rights reserved.
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
 * with " at " changed at "@" and " dot " changed to ".").    */

/* On a machine with IEEE extended-precision registers, it is
 * necessary to specify double-precision (53-bit) rounding precision
 * before invoking strtod or dtoa.  If the machine uses (the equivalent
 * of) Intel 80x87 arithmetic, the call
 *    _control87(PC_53, MCW_PC);
 * does this with many compilers.  Whether this or another call is
 * appropriate depends on the compiler; for this to work, it may be
 * necessary to #include "float.h" or another system-dependent header
 * file.
 */

#include "config.h"
#include "dtoa.h"

#include "wtf/CPU.h"
#include "wtf/MathExtras.h"
#include "wtf/ThreadingPrimitives.h"
#include "wtf/Vector.h"

#if COMPILER(MSVC)
#pragma warning(disable: 4244)
#pragma warning(disable: 4245)
#pragma warning(disable: 4554)
#endif

namespace WTF {

Mutex* s_dtoaP5Mutex;

typedef union {
    double d;
    uint32_t L[2];
} U;

#if CPU(BIG_ENDIAN) || CPU(MIDDLE_ENDIAN)
#define word0(x) (x)->L[0]
#define word1(x) (x)->L[1]
#else
#define word0(x) (x)->L[1]
#define word1(x) (x)->L[0]
#endif
#define dval(x) (x)->d

#define Exp_shift  20
#define Exp_shift1 20
#define Exp_msk1    0x100000
#define Exp_msk11   0x100000
#define Exp_mask  0x7ff00000
#define P 53
#define Bias 1023
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

#define rounded_product(a, b) a *= b
#define rounded_quotient(a, b) a /= b

#define Big0 (Frac_mask1 | Exp_msk1 * (DBL_MAX_EXP + Bias - 1))
#define Big1 0xffffffff

#if CPU(X86_64)
// FIXME: should we enable this on all 64-bit CPUs?
// 64-bit emulation provided by the compiler is likely to be slower than dtoa own code on 32-bit hardware.
#define USE_LONG_LONG
#endif

#ifndef USE_LONG_LONG
/* The following definition of Storeinc is appropriate for MIPS processors.
 * An alternative that might be better on some machines is
 *  *p++ = high << 16 | low & 0xffff;
 */
static ALWAYS_INLINE uint32_t* storeInc(uint32_t* p, uint16_t high, uint16_t low)
{
    uint16_t* p16 = reinterpret_cast<uint16_t*>(p);
#if CPU(BIG_ENDIAN)
    p16[0] = high;
    p16[1] = low;
#else
    p16[1] = high;
    p16[0] = low;
#endif
    return p + 1;
}
#endif

struct BigInt {
    BigInt() : sign(0) { }
    int sign;

    void clear()
    {
        sign = 0;
        m_words.clear();
    }

    size_t size() const
    {
        return m_words.size();
    }

    void resize(size_t s)
    {
        m_words.resize(s);
    }

    uint32_t* words()
    {
        return m_words.data();
    }

    const uint32_t* words() const
    {
        return m_words.data();
    }

    void append(uint32_t w)
    {
        m_words.append(w);
    }

    Vector<uint32_t, 16> m_words;
};

static void multadd(BigInt& b, int m, int a)    /* multiply by m and add a */
{
#ifdef USE_LONG_LONG
    unsigned long long carry;
#else
    uint32_t carry;
#endif

    int wds = b.size();
    uint32_t* x = b.words();
    int i = 0;
    carry = a;
    do {
#ifdef USE_LONG_LONG
        unsigned long long y = *x * (unsigned long long)m + carry;
        carry = y >> 32;
        *x++ = (uint32_t)y & 0xffffffffUL;
#else
        uint32_t xi = *x;
        uint32_t y = (xi & 0xffff) * m + carry;
        uint32_t z = (xi >> 16) * m + (y >> 16);
        carry = z >> 16;
        *x++ = (z << 16) + (y & 0xffff);
#endif
    } while (++i < wds);

    if (carry)
        b.append((uint32_t)carry);
}

static int hi0bits(uint32_t x)
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

static int lo0bits(uint32_t* y)
{
    int k;
    uint32_t x = *y;

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

static void i2b(BigInt& b, int i)
{
    b.sign = 0;
    b.resize(1);
    b.words()[0] = i;
}

static void mult(BigInt& aRef, const BigInt& bRef)
{
    const BigInt* a = &aRef;
    const BigInt* b = &bRef;
    BigInt c;
    int wa, wb, wc;
    const uint32_t* x = 0;
    const uint32_t* xa;
    const uint32_t* xb;
    const uint32_t* xae;
    const uint32_t* xbe;
    uint32_t* xc;
    uint32_t* xc0;
    uint32_t y;
#ifdef USE_LONG_LONG
    unsigned long long carry, z;
#else
    uint32_t carry, z;
#endif

    if (a->size() < b->size()) {
        const BigInt* tmp = a;
        a = b;
        b = tmp;
    }

    wa = a->size();
    wb = b->size();
    wc = wa + wb;
    c.resize(wc);

    for (xc = c.words(), xa = xc + wc; xc < xa; xc++)
        *xc = 0;
    xa = a->words();
    xae = xa + wa;
    xb = b->words();
    xbe = xb + wb;
    xc0 = c.words();
#ifdef USE_LONG_LONG
    for (; xb < xbe; xc0++) {
        if ((y = *xb++)) {
            x = xa;
            xc = xc0;
            carry = 0;
            do {
                z = *x++ * (unsigned long long)y + *xc + carry;
                carry = z >> 32;
                *xc++ = (uint32_t)z & 0xffffffffUL;
            } while (x < xae);
            *xc = (uint32_t)carry;
        }
    }
#else
    for (; xb < xbe; xb++, xc0++) {
        if ((y = *xb & 0xffff)) {
            x = xa;
            xc = xc0;
            carry = 0;
            do {
                z = (*x & 0xffff) * y + (*xc & 0xffff) + carry;
                carry = z >> 16;
                uint32_t z2 = (*x++ >> 16) * y + (*xc >> 16) + carry;
                carry = z2 >> 16;
                xc = storeInc(xc, z2, z);
            } while (x < xae);
            *xc = carry;
        }
        if ((y = *xb >> 16)) {
            x = xa;
            xc = xc0;
            carry = 0;
            uint32_t z2 = *xc;
            do {
                z = (*x & 0xffff) * y + (*xc >> 16) + carry;
                carry = z >> 16;
                xc = storeInc(xc, z, z2);
                z2 = (*x++ >> 16) * y + (*xc & 0xffff) + carry;
                carry = z2 >> 16;
            } while (x < xae);
            *xc = z2;
        }
    }
#endif
    for (xc0 = c.words(), xc = xc0 + wc; wc > 0 && !*--xc; --wc) { }
    c.resize(wc);
    aRef = c;
}

struct P5Node {
    WTF_MAKE_NONCOPYABLE(P5Node); WTF_MAKE_FAST_ALLOCATED;
public:
    P5Node() { }
    BigInt val;
    P5Node* next;
};

static P5Node* p5s;
static int p5sCount;

static ALWAYS_INLINE void pow5mult(BigInt& b, int k)
{
    static int p05[3] = { 5, 25, 125 };

    if (int i = k & 3)
        multadd(b, p05[i - 1], 0);

    if (!(k >>= 2))
        return;

    s_dtoaP5Mutex->lock();
    P5Node* p5 = p5s;

    if (!p5) {
        /* first time */
        p5 = new P5Node;
        i2b(p5->val, 625);
        p5->next = 0;
        p5s = p5;
        p5sCount = 1;
    }

    int p5sCountLocal = p5sCount;
    s_dtoaP5Mutex->unlock();
    int p5sUsed = 0;

    for (;;) {
        if (k & 1)
            mult(b, p5->val);

        if (!(k >>= 1))
            break;

        if (++p5sUsed == p5sCountLocal) {
            s_dtoaP5Mutex->lock();
            if (p5sUsed == p5sCount) {
                ASSERT(!p5->next);
                p5->next = new P5Node;
                p5->next->next = 0;
                p5->next->val = p5->val;
                mult(p5->next->val, p5->next->val);
                ++p5sCount;
            }

            p5sCountLocal = p5sCount;
            s_dtoaP5Mutex->unlock();
        }
        p5 = p5->next;
    }
}

static ALWAYS_INLINE void lshift(BigInt& b, int k)
{
    int n = k >> 5;

    int origSize = b.size();
    int n1 = n + origSize + 1;

    if (k &= 0x1f)
        b.resize(b.size() + n + 1);
    else
        b.resize(b.size() + n);

    const uint32_t* srcStart = b.words();
    uint32_t* dstStart = b.words();
    const uint32_t* src = srcStart + origSize - 1;
    uint32_t* dst = dstStart + n1 - 1;
    if (k) {
        uint32_t hiSubword = 0;
        int s = 32 - k;
        for (; src >= srcStart; --src) {
            *dst-- = hiSubword | *src >> s;
            hiSubword = *src << k;
        }
        *dst = hiSubword;
        ASSERT(dst == dstStart + n);

        b.resize(origSize + n + !!b.words()[n1 - 1]);
    }
    else {
        do {
            *--dst = *src--;
        } while (src >= srcStart);
    }
    for (dst = dstStart + n; dst != dstStart; )
        *--dst = 0;

    ASSERT(b.size() <= 1 || b.words()[b.size() - 1]);
}

static int cmp(const BigInt& a, const BigInt& b)
{
    const uint32_t *xa, *xa0, *xb, *xb0;
    int i, j;

    i = a.size();
    j = b.size();
    ASSERT(i <= 1 || a.words()[i - 1]);
    ASSERT(j <= 1 || b.words()[j - 1]);
    if (i -= j)
        return i;
    xa0 = a.words();
    xa = xa0 + j;
    xb0 = b.words();
    xb = xb0 + j;
    for (;;) {
        if (*--xa != *--xb)
            return *xa < *xb ? -1 : 1;
        if (xa <= xa0)
            break;
    }
    return 0;
}

static ALWAYS_INLINE void diff(BigInt& c, const BigInt& aRef, const BigInt& bRef)
{
    const BigInt* a = &aRef;
    const BigInt* b = &bRef;
    int i, wa, wb;
    uint32_t* xc;

    i = cmp(*a, *b);
    if (!i) {
        c.sign = 0;
        c.resize(1);
        c.words()[0] = 0;
        return;
    }
    if (i < 0) {
        const BigInt* tmp = a;
        a = b;
        b = tmp;
        i = 1;
    } else
        i = 0;

    wa = a->size();
    const uint32_t* xa = a->words();
    const uint32_t* xae = xa + wa;
    wb = b->size();
    const uint32_t* xb = b->words();
    const uint32_t* xbe = xb + wb;

    c.resize(wa);
    c.sign = i;
    xc = c.words();
#ifdef USE_LONG_LONG
    unsigned long long borrow = 0;
    do {
        unsigned long long y = (unsigned long long)*xa++ - *xb++ - borrow;
        borrow = y >> 32 & (uint32_t)1;
        *xc++ = (uint32_t)y & 0xffffffffUL;
    } while (xb < xbe);
    while (xa < xae) {
        unsigned long long y = *xa++ - borrow;
        borrow = y >> 32 & (uint32_t)1;
        *xc++ = (uint32_t)y & 0xffffffffUL;
    }
#else
    uint32_t borrow = 0;
    do {
        uint32_t y = (*xa & 0xffff) - (*xb & 0xffff) - borrow;
        borrow = (y & 0x10000) >> 16;
        uint32_t z = (*xa++ >> 16) - (*xb++ >> 16) - borrow;
        borrow = (z & 0x10000) >> 16;
        xc = storeInc(xc, z, y);
    } while (xb < xbe);
    while (xa < xae) {
        uint32_t y = (*xa & 0xffff) - borrow;
        borrow = (y & 0x10000) >> 16;
        uint32_t z = (*xa++ >> 16) - borrow;
        borrow = (z & 0x10000) >> 16;
        xc = storeInc(xc, z, y);
    }
#endif
    while (!*--xc)
        wa--;
    c.resize(wa);
}

static ALWAYS_INLINE void d2b(BigInt& b, U* d, int* e, int* bits)
{
    int de, k;
    uint32_t* x;
    uint32_t y, z;
    int i;
#define d0 word0(d)
#define d1 word1(d)

    b.sign = 0;
    b.resize(1);
    x = b.words();

    z = d0 & Frac_mask;
    d0 &= 0x7fffffff;    /* clear sign bit, which we ignore */
    if ((de = (int)(d0 >> Exp_shift)))
        z |= Exp_msk1;
    if ((y = d1)) {
        if ((k = lo0bits(&y))) {
            x[0] = y | (z << (32 - k));
            z >>= k;
        } else
            x[0] = y;
        if (z) {
            b.resize(2);
            x[1] = z;
        }

        i = b.size();
    } else {
        k = lo0bits(&z);
        x[0] = z;
        i = 1;
        b.resize(1);
        k += 32;
    }
    if (de) {
        *e = de - Bias - (P - 1) + k;
        *bits = P - k;
    } else {
        *e = 0 - Bias - (P - 1) + 1 + k;
        *bits = (32 * i) - hi0bits(x[i - 1]);
    }
}
#undef d0
#undef d1

static const double tens[] = {
    1e0, 1e1, 1e2, 1e3, 1e4, 1e5, 1e6, 1e7, 1e8, 1e9,
    1e10, 1e11, 1e12, 1e13, 1e14, 1e15, 1e16, 1e17, 1e18, 1e19,
    1e20, 1e21, 1e22
};

static const double bigtens[] = { 1e16, 1e32, 1e64, 1e128, 1e256 };

#define Scale_Bit 0x10
#define n_bigtens 5

static ALWAYS_INLINE int quorem(BigInt& b, BigInt& S)
{
    size_t n;
    uint32_t* bx;
    uint32_t* bxe;
    uint32_t q;
    uint32_t* sx;
    uint32_t* sxe;
#ifdef USE_LONG_LONG
    unsigned long long borrow, carry, y, ys;
#else
    uint32_t borrow, carry, y, ys;
    uint32_t si, z, zs;
#endif
    ASSERT(b.size() <= 1 || b.words()[b.size() - 1]);
    ASSERT(S.size() <= 1 || S.words()[S.size() - 1]);

    n = S.size();
    ASSERT_WITH_MESSAGE(b.size() <= n, "oversize b in quorem");
    if (b.size() < n)
        return 0;
    sx = S.words();
    sxe = sx + --n;
    bx = b.words();
    bxe = bx + n;
    q = *bxe / (*sxe + 1);    /* ensure q <= true quotient */
    ASSERT_WITH_MESSAGE(q <= 9, "oversized quotient in quorem");
    if (q) {
        borrow = 0;
        carry = 0;
        do {
#ifdef USE_LONG_LONG
            ys = *sx++ * (unsigned long long)q + carry;
            carry = ys >> 32;
            y = *bx - (ys & 0xffffffffUL) - borrow;
            borrow = y >> 32 & (uint32_t)1;
            *bx++ = (uint32_t)y & 0xffffffffUL;
#else
            si = *sx++;
            ys = (si & 0xffff) * q + carry;
            zs = (si >> 16) * q + (ys >> 16);
            carry = zs >> 16;
            y = (*bx & 0xffff) - (ys & 0xffff) - borrow;
            borrow = (y & 0x10000) >> 16;
            z = (*bx >> 16) - (zs & 0xffff) - borrow;
            borrow = (z & 0x10000) >> 16;
            bx = storeInc(bx, z, y);
#endif
        } while (sx <= sxe);
        if (!*bxe) {
            bx = b.words();
            while (--bxe > bx && !*bxe)
                --n;
            b.resize(n);
        }
    }
    if (cmp(b, S) >= 0) {
        q++;
        borrow = 0;
        carry = 0;
        bx = b.words();
        sx = S.words();
        do {
#ifdef USE_LONG_LONG
            ys = *sx++ + carry;
            carry = ys >> 32;
            y = *bx - (ys & 0xffffffffUL) - borrow;
            borrow = y >> 32 & (uint32_t)1;
            *bx++ = (uint32_t)y & 0xffffffffUL;
#else
            si = *sx++;
            ys = (si & 0xffff) + carry;
            zs = (si >> 16) + (ys >> 16);
            carry = zs >> 16;
            y = (*bx & 0xffff) - (ys & 0xffff) - borrow;
            borrow = (y & 0x10000) >> 16;
            z = (*bx >> 16) - (zs & 0xffff) - borrow;
            borrow = (z & 0x10000) >> 16;
            bx = storeInc(bx, z, y);
#endif
        } while (sx <= sxe);
        bx = b.words();
        bxe = bx + n;
        if (!*bxe) {
            while (--bxe > bx && !*bxe)
                --n;
            b.resize(n);
        }
    }
    return q;
}

/* dtoa for IEEE arithmetic (dmg): convert double to ASCII string.
 *
 * Inspired by "How to Print Floating-Point Numbers Accurately" by
 * Guy L. Steele, Jr. and Jon L. White [Proc. ACM SIGPLAN '90, pp. 112-126].
 *
 * Modifications:
 *    1. Rather than iterating, we use a simple numeric overestimate
 *       to determine k = floor(log10(d)).  We scale relevant
 *       quantities using O(log2(k)) rather than O(k) multiplications.
 *    2. For some modes > 2 (corresponding to ecvt and fcvt), we don't
 *       try to generate digits strictly left to right.  Instead, we
 *       compute with fewer bits and propagate the carry if necessary
 *       when rounding the final digit up.  This is often faster.
 *    3. Under the assumption that input will be rounded nearest,
 *       mode 0 renders 1e23 as 1e23 rather than 9.999999999999999e22.
 *       That is, we allow equality in stopping tests when the
 *       round-nearest rule will give the same floating-point value
 *       as would satisfaction of the stopping test with strict
 *       inequality.
 *    4. We remove common factors of powers of 2 from relevant
 *       quantities.
 *    5. When converting floating-point integers less than 1e16,
 *       we use floating-point arithmetic rather than resorting
 *       to multiple-precision integers.
 *    6. When asked to produce fewer than 15 digits, we first try
 *       to get by with floating-point arithmetic; we resort to
 *       multiple-precision integer arithmetic only if we cannot
 *       guarantee that the floating-point calculation has given
 *       the correctly rounded result.  For k requested digits and
 *       "uniformly" distributed input, the probability is
 *       something like 10^(k-15) that we must resort to the int32_t
 *       calculation.
 *
 * Note: 'leftright' translates to 'generate shortest possible string'.
 */
template<bool roundingNone, bool roundingSignificantFigures, bool roundingDecimalPlaces, bool leftright>
void dtoa(DtoaBuffer result, double dd, int ndigits, bool& signOut, int& exponentOut, unsigned& precisionOut)
{
    // Exactly one rounding mode must be specified.
    ASSERT(roundingNone + roundingSignificantFigures + roundingDecimalPlaces == 1);
    // roundingNone only allowed (only sensible?) with leftright set.
    ASSERT(!roundingNone || leftright);

    ASSERT(std::isfinite(dd));

    int bbits, b2, b5, be, dig, i, ieps, ilim = 0, ilim0, ilim1 = 0,
        j, j1, k, k0, k_check, m2, m5, s2, s5,
        spec_case;
    int32_t L;
    int denorm;
    uint32_t x;
    BigInt b, delta, mlo, mhi, S;
    U d2, eps, u;
    double ds;
    char* s;
    char* s0;

    u.d = dd;

    /* Infinity or NaN */
    ASSERT((word0(&u) & Exp_mask) != Exp_mask);

    // JavaScript toString conversion treats -0 as 0.
    if (!dval(&u)) {
        signOut = false;
        exponentOut = 0;
        precisionOut = 1;
        result[0] = '0';
        result[1] = '\0';
        return;
    }

    if (word0(&u) & Sign_bit) {
        signOut = true;
        word0(&u) &= ~Sign_bit; // clear sign bit
    } else
        signOut = false;

    d2b(b, &u, &be, &bbits);
    if ((i = (int)(word0(&u) >> Exp_shift1 & (Exp_mask >> Exp_shift1)))) {
        dval(&d2) = dval(&u);
        word0(&d2) &= Frac_mask1;
        word0(&d2) |= Exp_11;

        /* log(x)    ~=~ log(1.5) + (x-1.5)/1.5
         * log10(x)     =  log(x) / log(10)
         *        ~=~ log(1.5)/log(10) + (x-1.5)/(1.5*log(10))
         * log10(d) = (i-Bias)*log(2)/log(10) + log10(d2)
         *
         * This suggests computing an approximation k to log10(d) by
         *
         * k = (i - Bias)*0.301029995663981
         *    + ( (d2-1.5)*0.289529654602168 + 0.176091259055681 );
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
        denorm = 0;
    } else {
        /* d is denormalized */

        i = bbits + be + (Bias + (P - 1) - 1);
        x = (i > 32) ? (word0(&u) << (64 - i)) | (word1(&u) >> (i - 32))
                : word1(&u) << (32 - i);
        dval(&d2) = x;
        word0(&d2) -= 31 * Exp_msk1; /* adjust exponent */
        i -= (Bias + (P - 1) - 1) + 1;
        denorm = 1;
    }
    ds = (dval(&d2) - 1.5) * 0.289529654602168 + 0.1760912590558 + (i * 0.301029995663981);
    k = (int)ds;
    if (ds < 0. && ds != k)
        k--;    /* want k = floor(ds) */
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
    } else {
        b2 = -j;
        s2 = 0;
    }
    if (k >= 0) {
        b5 = 0;
        s5 = k;
        s2 += k;
    } else {
        b2 -= k;
        b5 = -k;
        s5 = 0;
    }

    if (roundingNone) {
        ilim = ilim1 = -1;
        i = 18;
        ndigits = 0;
    }
    if (roundingSignificantFigures) {
        if (ndigits <= 0)
            ndigits = 1;
        ilim = ilim1 = i = ndigits;
    }
    if (roundingDecimalPlaces) {
        i = ndigits + k + 1;
        ilim = i;
        ilim1 = i - 1;
        if (i <= 0)
            i = 1;
    }

    s = s0 = result;

    if (ilim >= 0 && ilim <= Quick_max) {
        /* Try to get by with floating-point arithmetic. */

        i = 0;
        dval(&d2) = dval(&u);
        k0 = k;
        ilim0 = ilim;
        ieps = 2; /* conservative */
        if (k > 0) {
            ds = tens[k & 0xf];
            j = k >> 4;
            if (j & Bletch) {
                /* prevent overflows */
                j &= Bletch - 1;
                dval(&u) /= bigtens[n_bigtens - 1];
                ieps++;
            }
            for (; j; j >>= 1, i++) {
                if (j & 1) {
                    ieps++;
                    ds *= bigtens[i];
                }
            }
            dval(&u) /= ds;
        } else if ((j1 = -k)) {
            dval(&u) *= tens[j1 & 0xf];
            for (j = j1 >> 4; j; j >>= 1, i++) {
                if (j & 1) {
                    ieps++;
                    dval(&u) *= bigtens[i];
                }
            }
        }
        if (k_check && dval(&u) < 1. && ilim > 0) {
            if (ilim1 <= 0)
                goto fastFailed;
            ilim = ilim1;
            k--;
            dval(&u) *= 10.;
            ieps++;
        }
        dval(&eps) = (ieps * dval(&u)) + 7.;
        word0(&eps) -= (P - 1) * Exp_msk1;
        if (!ilim) {
            S.clear();
            mhi.clear();
            dval(&u) -= 5.;
            if (dval(&u) > dval(&eps))
                goto oneDigit;
            if (dval(&u) < -dval(&eps))
                goto noDigits;
            goto fastFailed;
        }
        if (leftright) {
            /* Use Steele & White method of only
             * generating digits needed.
             */
            dval(&eps) = (0.5 / tens[ilim - 1]) - dval(&eps);
            for (i = 0;;) {
                L = (long int)dval(&u);
                dval(&u) -= L;
                *s++ = '0' + (int)L;
                if (dval(&u) < dval(&eps))
                    goto ret;
                if (1. - dval(&u) < dval(&eps))
                    goto bumpUp;
                if (++i >= ilim)
                    break;
                dval(&eps) *= 10.;
                dval(&u) *= 10.;
            }
        } else {
            /* Generate ilim digits, then fix them up. */
            dval(&eps) *= tens[ilim - 1];
            for (i = 1;; i++, dval(&u) *= 10.) {
                L = (int32_t)(dval(&u));
                if (!(dval(&u) -= L))
                    ilim = i;
                *s++ = '0' + (int)L;
                if (i == ilim) {
                    if (dval(&u) > 0.5 + dval(&eps))
                        goto bumpUp;
                    if (dval(&u) < 0.5 - dval(&eps)) {
                        while (*--s == '0') { }
                        s++;
                        goto ret;
                    }
                    break;
                }
            }
        }
fastFailed:
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
            S.clear();
            mhi.clear();
            if (ilim < 0 || dval(&u) <= 5 * ds)
                goto noDigits;
            goto oneDigit;
        }
        for (i = 1;; i++, dval(&u) *= 10.) {
            L = (int32_t)(dval(&u) / ds);
            dval(&u) -= L * ds;
            *s++ = '0' + (int)L;
            if (!dval(&u)) {
                break;
            }
            if (i == ilim) {
                dval(&u) += dval(&u);
                if (dval(&u) > ds || (dval(&u) == ds && (L & 1))) {
bumpUp:
                    while (*--s == '9')
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
        goto ret;
    }

    m2 = b2;
    m5 = b5;
    mhi.clear();
    mlo.clear();
    if (leftright) {
        i = denorm ? be + (Bias + (P - 1) - 1 + 1) : 1 + P - bbits;
        b2 += i;
        s2 += i;
        i2b(mhi, 1);
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
                pow5mult(mhi, m5);
                mult(b, mhi);
            }
            if ((j = b5 - m5))
                pow5mult(b, j);
        } else
            pow5mult(b, b5);
    }
    i2b(S, 1);
    if (s5 > 0)
        pow5mult(S, s5);

    /* Check for special case that d is a normalized power of 2. */

    spec_case = 0;
    if ((roundingNone || leftright) && (!word1(&u) && !(word0(&u) & Bndry_mask) && word0(&u) & (Exp_mask & ~Exp_msk1))) {
        /* The special case */
        b2 += Log2P;
        s2 += Log2P;
        spec_case = 1;
    }

    /* Arrange for convenient computation of quotients:
     * shift left if necessary so divisor has 4 leading 0 bits.
     *
     * Perhaps we should just compute leading 28 bits of S once
     * and for all and pass them and a shift to quorem, so it
     * can do shifts and ors to compute the numerator for q.
     */
    if ((i = ((s5 ? 32 - hi0bits(S.words()[S.size() - 1]) : 1) + s2) & 0x1f))
        i = 32 - i;
    if (i > 4) {
        i -= 4;
        b2 += i;
        m2 += i;
        s2 += i;
    } else if (i < 4) {
        i += 28;
        b2 += i;
        m2 += i;
        s2 += i;
    }
    if (b2 > 0)
        lshift(b, b2);
    if (s2 > 0)
        lshift(S, s2);
    if (k_check) {
        if (cmp(b, S) < 0) {
            k--;
            multadd(b, 10, 0);    /* we botched the k estimate */
            if (leftright)
                multadd(mhi, 10, 0);
            ilim = ilim1;
        }
    }
    if (ilim <= 0 && roundingDecimalPlaces) {
        if (ilim < 0)
            goto noDigits;
        multadd(S, 5, 0);
        // For IEEE-754 unbiased rounding this check should be <=, such that 0.5 would flush to zero.
        if (cmp(b, S) < 0)
            goto noDigits;
        goto oneDigit;
    }
    if (leftright) {
        if (m2 > 0)
            lshift(mhi, m2);

        /* Compute mlo -- check for special case
         * that d is a normalized power of 2.
         */

        mlo = mhi;
        if (spec_case)
            lshift(mhi, Log2P);

        for (i = 1;;i++) {
            dig = quorem(b, S) + '0';
            /* Do we yet have the shortest decimal string
             * that will round to d?
             */
            j = cmp(b, mlo);
            diff(delta, S, mhi);
            j1 = delta.sign ? 1 : cmp(b, delta);
#ifdef DTOA_ROUND_BIASED
            if (j < 0 || !j) {
#else
            // FIXME: ECMA-262 specifies that equidistant results round away from
            // zero, which probably means we shouldn't be on the unbiased code path
            // (the (word1(&u) & 1) clause is looking highly suspicious). I haven't
            // yet understood this code well enough to make the call, but we should
            // probably be enabling DTOA_ROUND_BIASED. I think the interesting corner
            // case to understand is probably "Math.pow(0.5, 24).toString()".
            // I believe this value is interesting because I think it is precisely
            // representable in binary floating point, and its decimal representation
            // has a single digit that Steele & White reduction can remove, with the
            // value 5 (thus equidistant from the next numbers above and below).
            // We produce the correct answer using either codepath, and I don't as
            // yet understand why. :-)
            if (!j1 && !(word1(&u) & 1)) {
                if (dig == '9')
                    goto round9up;
                if (j > 0)
                    dig++;
                *s++ = dig;
                goto ret;
            }
            if (j < 0 || (!j && !(word1(&u) & 1))) {
#endif
                if ((b.words()[0] || b.size() > 1) && (j1 > 0)) {
                    lshift(b, 1);
                    j1 = cmp(b, S);
                    // For IEEE-754 round-to-even, this check should be (j1 > 0 || (!j1 && (dig & 1))),
                    // but ECMA-262 specifies that equidistant values (e.g. (.5).toFixed()) should
                    // be rounded away from zero.
                    if (j1 >= 0) {
                        if (dig == '9')
                            goto round9up;
                        dig++;
                    }
                }
                *s++ = dig;
                goto ret;
            }
            if (j1 > 0) {
                if (dig == '9') { /* possible if i == 1 */
round9up:
                    *s++ = '9';
                    goto roundoff;
                }
                *s++ = dig + 1;
                goto ret;
            }
            *s++ = dig;
            if (i == ilim)
                break;
            multadd(b, 10, 0);
            multadd(mlo, 10, 0);
            multadd(mhi, 10, 0);
        }
    } else {
        for (i = 1;; i++) {
            *s++ = dig = quorem(b, S) + '0';
            if (!b.words()[0] && b.size() <= 1)
                goto ret;
            if (i >= ilim)
                break;
            multadd(b, 10, 0);
        }
    }

    /* Round off last digit */

    lshift(b, 1);
    j = cmp(b, S);
    // For IEEE-754 round-to-even, this check should be (j > 0 || (!j && (dig & 1))),
    // but ECMA-262 specifies that equidistant values (e.g. (.5).toFixed()) should
    // be rounded away from zero.
    if (j >= 0) {
roundoff:
        while (*--s == '9')
            if (s == s0) {
                k++;
                *s++ = '1';
                goto ret;
            }
        ++*s++;
    } else {
        while (*--s == '0') { }
        s++;
    }
    goto ret;
noDigits:
    exponentOut = 0;
    precisionOut = 1;
    result[0] = '0';
    result[1] = '\0';
    return;
oneDigit:
    *s++ = '1';
    k++;
    goto ret;
ret:
    ASSERT(s > result);
    *s = 0;
    exponentOut = k;
    precisionOut = s - result;
}

void dtoa(DtoaBuffer result, double dd, bool& sign, int& exponent, unsigned& precision)
{
    // flags are roundingNone, leftright.
    dtoa<true, false, false, true>(result, dd, 0, sign, exponent, precision);
}

void dtoaRoundSF(DtoaBuffer result, double dd, int ndigits, bool& sign, int& exponent, unsigned& precision)
{
    // flag is roundingSignificantFigures.
    dtoa<false, true, false, false>(result, dd, ndigits, sign, exponent, precision);
}

void dtoaRoundDP(DtoaBuffer result, double dd, int ndigits, bool& sign, int& exponent, unsigned& precision)
{
    // flag is roundingDecimalPlaces.
    dtoa<false, false, true, false>(result, dd, ndigits, sign, exponent, precision);
}

const char* numberToString(double d, NumberToStringBuffer buffer)
{
    double_conversion::StringBuilder builder(buffer, NumberToStringBufferLength);
    const double_conversion::DoubleToStringConverter& converter = double_conversion::DoubleToStringConverter::EcmaScriptConverter();
    converter.ToShortest(d, &builder);
    return builder.Finalize();
}

static inline const char* formatStringTruncatingTrailingZerosIfNeeded(NumberToStringBuffer buffer, double_conversion::StringBuilder& builder)
{
    size_t length = builder.position();
    size_t decimalPointPosition = 0;
    for (; decimalPointPosition < length; ++decimalPointPosition) {
        if (buffer[decimalPointPosition] == '.')
            break;
    }

    // No decimal seperator found, early exit.
    if (decimalPointPosition == length)
        return builder.Finalize();

    size_t truncatedLength = length - 1;
    for (; truncatedLength > decimalPointPosition; --truncatedLength) {
        if (buffer[truncatedLength] != '0')
            break;
    }

    // No trailing zeros found to strip.
    if (truncatedLength == length - 1)
        return builder.Finalize();

    // If we removed all trailing zeros, remove the decimal point as well.
    if (truncatedLength == decimalPointPosition) {
        ASSERT(truncatedLength > 0);
        --truncatedLength;
    }

    // Truncate the StringBuilder, and return the final result.
    builder.SetPosition(truncatedLength + 1);
    return builder.Finalize();
}

const char* numberToFixedPrecisionString(double d, unsigned significantFigures, NumberToStringBuffer buffer, bool truncateTrailingZeros)
{
    // Mimic String::format("%.[precision]g", ...), but use dtoas rounding facilities.
    // "g": Signed value printed in f or e format, whichever is more compact for the given value and precision.
    // The e format is used only when the exponent of the value is less than –4 or greater than or equal to the
    // precision argument. Trailing zeros are truncated, and the decimal point appears only if one or more digits follow it.
    // "precision": The precision specifies the maximum number of significant digits printed.
    double_conversion::StringBuilder builder(buffer, NumberToStringBufferLength);
    const double_conversion::DoubleToStringConverter& converter = double_conversion::DoubleToStringConverter::EcmaScriptConverter();
    converter.ToPrecision(d, significantFigures, &builder);
    if (!truncateTrailingZeros)
        return builder.Finalize();
    return formatStringTruncatingTrailingZerosIfNeeded(buffer, builder);
}

const char* numberToFixedWidthString(double d, unsigned decimalPlaces, NumberToStringBuffer buffer)
{
    // Mimic String::format("%.[precision]f", ...), but use dtoas rounding facilities.
    // "f": Signed value having the form [ – ]dddd.dddd, where dddd is one or more decimal digits.
    // The number of digits before the decimal point depends on the magnitude of the number, and
    // the number of digits after the decimal point depends on the requested precision.
    // "precision": The precision value specifies the number of digits after the decimal point.
    // If a decimal point appears, at least one digit appears before it.
    // The value is rounded to the appropriate number of digits.
    double_conversion::StringBuilder builder(buffer, NumberToStringBufferLength);
    const double_conversion::DoubleToStringConverter& converter = double_conversion::DoubleToStringConverter::EcmaScriptConverter();
    converter.ToFixed(d, decimalPlaces, &builder);
    return builder.Finalize();
}

namespace Internal {

double parseDoubleFromLongString(const UChar* string, size_t length, size_t& parsedLength)
{
    Vector<LChar> conversionBuffer(length);
    for (size_t i = 0; i < length; ++i)
        conversionBuffer[i] = isASCII(string[i]) ? string[i] : 0;
    return parseDouble(conversionBuffer.data(), length, parsedLength);
}

} // namespace Internal

} // namespace WTF
