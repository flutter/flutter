/*
 * sha512.c - implementation of SHA256, SHA384 and SHA512
 *
 * ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1/GPL 2.0/LGPL 2.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is the Netscape security libraries.
 *
 * The Initial Developer of the Original Code is
 * Netscape Communications Corporation.
 * Portions created by the Initial Developer are Copyright (C) 2002
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 *
 * Alternatively, the contents of this file may be used under the terms of
 * either the GNU General Public License Version 2 or later (the "GPL"), or
 * the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
 * in which case the provisions of the GPL or the LGPL are applicable instead
 * of those above. If you wish to allow use of your version of this file only
 * under the terms of either the GPL or the LGPL, and not to allow others to
 * use your version of this file under the terms of the MPL, indicate your
 * decision by deleting the provisions above and replace them with the notice
 * and other provisions required by the GPL or the LGPL. If you do not delete
 * the provisions above, a recipient may use your version of this file under
 * the terms of any one of the MPL, the GPL or the LGPL.
 *
 * ***** END LICENSE BLOCK ***** */
/* $Id: sha512.c,v 1.9 2006/10/13 16:54:04 wtchang%redhat.com Exp $ */

// Prevent manual unrolling in the sha256 code, which reduces the binary code
// size from ~10k to ~1k.  The performance should be reasonable for our use.
#define NOUNROLL256 1

#include "crypto/third_party/nss/chromium-prtypes.h"  /* for PRUintXX */
#if defined(_X86_) || defined(SHA_NO_LONG_LONG)
#define NOUNROLL512 1
#undef HAVE_LONG_LONG
#endif
#include "crypto/third_party/nss/chromium-blapi.h"
#include "crypto/third_party/nss/chromium-sha256.h"    /* for struct SHA256ContextStr */

#include <stdlib.h>
#include <string.h>
#define PORT_New(type) static_cast<type*>(malloc(sizeof(type)))
#define PORT_ZFree(ptr, len) do { memset(ptr, 0, len); free(ptr); } while (0)
#define PORT_Strlen(s) static_cast<unsigned int>(strlen(s))
#define PORT_Memcpy memcpy

/* ============= Common constants and defines ======================= */

#define W ctx->u.w
#define B ctx->u.b
#define H ctx->h

#define SHR(x,n) (x >> n)
#define SHL(x,n) (x << n)
#define Ch(x,y,z)  ((x & y) ^ (~x & z))
#define Maj(x,y,z) ((x & y) ^ (x & z) ^ (y & z))

/* Padding used with all flavors of SHA */
static const PRUint8 pad[240] = {
0x80,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
   /* compiler will fill the rest in with zeros */
};

/* ============= SHA256 implemenmtation ================================== */

/* SHA-256 constants, K256. */
static const PRUint32 K256[64] = {
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
    0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
    0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
    0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
    0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
    0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
    0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
    0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
    0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
};

/* SHA-256 initial hash values */
static const PRUint32 H256[8] = {
    0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
    0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
};

#if defined(_MSC_VER) && defined(_X86_)
#ifndef FORCEINLINE
#if (_MSC_VER >= 1200)
#define FORCEINLINE __forceinline
#else
#define FORCEINLINE __inline
#endif
#endif
#define FASTCALL __fastcall

static FORCEINLINE PRUint32 FASTCALL
swap4b(PRUint32 dwd)
{
    __asm {
    	mov   eax,dwd
	bswap eax
    }
}

#define SHA_HTONL(x) swap4b(x)
#define BYTESWAP4(x)  x = SHA_HTONL(x)

#elif defined(LINUX) && defined(_X86_)
#undef  __OPTIMIZE__
#define __OPTIMIZE__ 1
#undef  __pentium__
#define __pentium__ 1
#include <byteswap.h>
#define SHA_HTONL(x) bswap_32(x)
#define BYTESWAP4(x)  x = SHA_HTONL(x)

#else /* neither windows nor Linux PC */
#define SWAP4MASK  0x00FF00FF
#define SHA_HTONL(x) (t1 = (x), t1 = (t1 << 16) | (t1 >> 16), \
                      ((t1 & SWAP4MASK) << 8) | ((t1 >> 8) & SWAP4MASK))
#define BYTESWAP4(x)  x = SHA_HTONL(x)
#endif

#if defined(_MSC_VER) && defined(_X86_)
#pragma intrinsic (_lrotr, _lrotl)
#define ROTR32(x,n) _lrotr(x,n)
#define ROTL32(x,n) _lrotl(x,n)
#else
#define ROTR32(x,n) ((x >> n) | (x << ((8 * sizeof x) - n)))
#define ROTL32(x,n) ((x << n) | (x >> ((8 * sizeof x) - n)))
#endif

/* Capitol Sigma and lower case sigma functions */
#define S0(x) (ROTR32(x, 2) ^ ROTR32(x,13) ^ ROTR32(x,22))
#define S1(x) (ROTR32(x, 6) ^ ROTR32(x,11) ^ ROTR32(x,25))
#define s0(x) (t1 = x, ROTR32(t1, 7) ^ ROTR32(t1,18) ^ SHR(t1, 3))
#define s1(x) (t2 = x, ROTR32(t2,17) ^ ROTR32(t2,19) ^ SHR(t2,10))

SHA256Context *
SHA256_NewContext(void)
{
    SHA256Context *ctx = PORT_New(SHA256Context);
    return ctx;
}

void
SHA256_DestroyContext(SHA256Context *ctx, PRBool freeit)
{
    if (freeit) {
        PORT_ZFree(ctx, sizeof *ctx);
    }
}

void
SHA256_Begin(SHA256Context *ctx)
{
    memset(ctx, 0, sizeof *ctx);
    memcpy(H, H256, sizeof H256);
}

static void
SHA256_Compress(SHA256Context *ctx)
{
  {
    register PRUint32 t1, t2;

#if defined(IS_LITTLE_ENDIAN)
    BYTESWAP4(W[0]);
    BYTESWAP4(W[1]);
    BYTESWAP4(W[2]);
    BYTESWAP4(W[3]);
    BYTESWAP4(W[4]);
    BYTESWAP4(W[5]);
    BYTESWAP4(W[6]);
    BYTESWAP4(W[7]);
    BYTESWAP4(W[8]);
    BYTESWAP4(W[9]);
    BYTESWAP4(W[10]);
    BYTESWAP4(W[11]);
    BYTESWAP4(W[12]);
    BYTESWAP4(W[13]);
    BYTESWAP4(W[14]);
    BYTESWAP4(W[15]);
#endif

#define INITW(t) W[t] = (s1(W[t-2]) + W[t-7] + s0(W[t-15]) + W[t-16])

    /* prepare the "message schedule"   */
#ifdef NOUNROLL256
    {
	int t;
	for (t = 16; t < 64; ++t) {
	    INITW(t);
	}
    }
#else
    INITW(16);
    INITW(17);
    INITW(18);
    INITW(19);

    INITW(20);
    INITW(21);
    INITW(22);
    INITW(23);
    INITW(24);
    INITW(25);
    INITW(26);
    INITW(27);
    INITW(28);
    INITW(29);

    INITW(30);
    INITW(31);
    INITW(32);
    INITW(33);
    INITW(34);
    INITW(35);
    INITW(36);
    INITW(37);
    INITW(38);
    INITW(39);

    INITW(40);
    INITW(41);
    INITW(42);
    INITW(43);
    INITW(44);
    INITW(45);
    INITW(46);
    INITW(47);
    INITW(48);
    INITW(49);

    INITW(50);
    INITW(51);
    INITW(52);
    INITW(53);
    INITW(54);
    INITW(55);
    INITW(56);
    INITW(57);
    INITW(58);
    INITW(59);

    INITW(60);
    INITW(61);
    INITW(62);
    INITW(63);

#endif
#undef INITW
  }
  {
    PRUint32 a, b, c, d, e, f, g, h;

    a = H[0];
    b = H[1];
    c = H[2];
    d = H[3];
    e = H[4];
    f = H[5];
    g = H[6];
    h = H[7];

#define ROUND(n,a,b,c,d,e,f,g,h) \
    h += S1(e) + Ch(e,f,g) + K256[n] + W[n]; \
    d += h; \
    h += S0(a) + Maj(a,b,c);

#ifdef NOUNROLL256
    {
	int t;
	for (t = 0; t < 64; t+= 8) {
	    ROUND(t+0,a,b,c,d,e,f,g,h)
	    ROUND(t+1,h,a,b,c,d,e,f,g)
	    ROUND(t+2,g,h,a,b,c,d,e,f)
	    ROUND(t+3,f,g,h,a,b,c,d,e)
	    ROUND(t+4,e,f,g,h,a,b,c,d)
	    ROUND(t+5,d,e,f,g,h,a,b,c)
	    ROUND(t+6,c,d,e,f,g,h,a,b)
	    ROUND(t+7,b,c,d,e,f,g,h,a)
	}
    }
#else
    ROUND( 0,a,b,c,d,e,f,g,h)
    ROUND( 1,h,a,b,c,d,e,f,g)
    ROUND( 2,g,h,a,b,c,d,e,f)
    ROUND( 3,f,g,h,a,b,c,d,e)
    ROUND( 4,e,f,g,h,a,b,c,d)
    ROUND( 5,d,e,f,g,h,a,b,c)
    ROUND( 6,c,d,e,f,g,h,a,b)
    ROUND( 7,b,c,d,e,f,g,h,a)

    ROUND( 8,a,b,c,d,e,f,g,h)
    ROUND( 9,h,a,b,c,d,e,f,g)
    ROUND(10,g,h,a,b,c,d,e,f)
    ROUND(11,f,g,h,a,b,c,d,e)
    ROUND(12,e,f,g,h,a,b,c,d)
    ROUND(13,d,e,f,g,h,a,b,c)
    ROUND(14,c,d,e,f,g,h,a,b)
    ROUND(15,b,c,d,e,f,g,h,a)

    ROUND(16,a,b,c,d,e,f,g,h)
    ROUND(17,h,a,b,c,d,e,f,g)
    ROUND(18,g,h,a,b,c,d,e,f)
    ROUND(19,f,g,h,a,b,c,d,e)
    ROUND(20,e,f,g,h,a,b,c,d)
    ROUND(21,d,e,f,g,h,a,b,c)
    ROUND(22,c,d,e,f,g,h,a,b)
    ROUND(23,b,c,d,e,f,g,h,a)

    ROUND(24,a,b,c,d,e,f,g,h)
    ROUND(25,h,a,b,c,d,e,f,g)
    ROUND(26,g,h,a,b,c,d,e,f)
    ROUND(27,f,g,h,a,b,c,d,e)
    ROUND(28,e,f,g,h,a,b,c,d)
    ROUND(29,d,e,f,g,h,a,b,c)
    ROUND(30,c,d,e,f,g,h,a,b)
    ROUND(31,b,c,d,e,f,g,h,a)

    ROUND(32,a,b,c,d,e,f,g,h)
    ROUND(33,h,a,b,c,d,e,f,g)
    ROUND(34,g,h,a,b,c,d,e,f)
    ROUND(35,f,g,h,a,b,c,d,e)
    ROUND(36,e,f,g,h,a,b,c,d)
    ROUND(37,d,e,f,g,h,a,b,c)
    ROUND(38,c,d,e,f,g,h,a,b)
    ROUND(39,b,c,d,e,f,g,h,a)

    ROUND(40,a,b,c,d,e,f,g,h)
    ROUND(41,h,a,b,c,d,e,f,g)
    ROUND(42,g,h,a,b,c,d,e,f)
    ROUND(43,f,g,h,a,b,c,d,e)
    ROUND(44,e,f,g,h,a,b,c,d)
    ROUND(45,d,e,f,g,h,a,b,c)
    ROUND(46,c,d,e,f,g,h,a,b)
    ROUND(47,b,c,d,e,f,g,h,a)

    ROUND(48,a,b,c,d,e,f,g,h)
    ROUND(49,h,a,b,c,d,e,f,g)
    ROUND(50,g,h,a,b,c,d,e,f)
    ROUND(51,f,g,h,a,b,c,d,e)
    ROUND(52,e,f,g,h,a,b,c,d)
    ROUND(53,d,e,f,g,h,a,b,c)
    ROUND(54,c,d,e,f,g,h,a,b)
    ROUND(55,b,c,d,e,f,g,h,a)

    ROUND(56,a,b,c,d,e,f,g,h)
    ROUND(57,h,a,b,c,d,e,f,g)
    ROUND(58,g,h,a,b,c,d,e,f)
    ROUND(59,f,g,h,a,b,c,d,e)
    ROUND(60,e,f,g,h,a,b,c,d)
    ROUND(61,d,e,f,g,h,a,b,c)
    ROUND(62,c,d,e,f,g,h,a,b)
    ROUND(63,b,c,d,e,f,g,h,a)
#endif

    H[0] += a;
    H[1] += b;
    H[2] += c;
    H[3] += d;
    H[4] += e;
    H[5] += f;
    H[6] += g;
    H[7] += h;
  }
#undef ROUND
}

#undef s0
#undef s1
#undef S0
#undef S1

void
SHA256_Update(SHA256Context *ctx, const unsigned char *input,
		    unsigned int inputLen)
{
    unsigned int inBuf = ctx->sizeLo & 0x3f;
    if (!inputLen)
    	return;

    /* Add inputLen into the count of bytes processed, before processing */
    if ((ctx->sizeLo += inputLen) < inputLen)
    	ctx->sizeHi++;

    /* if data already in buffer, attemp to fill rest of buffer */
    if (inBuf) {
    	unsigned int todo = SHA256_BLOCK_LENGTH - inBuf;
	if (inputLen < todo)
	    todo = inputLen;
	memcpy(B + inBuf, input, todo);
	input    += todo;
	inputLen -= todo;
	if (inBuf + todo == SHA256_BLOCK_LENGTH)
	    SHA256_Compress(ctx);
    }

    /* if enough data to fill one or more whole buffers, process them. */
    while (inputLen >= SHA256_BLOCK_LENGTH) {
    	memcpy(B, input, SHA256_BLOCK_LENGTH);
	input    += SHA256_BLOCK_LENGTH;
	inputLen -= SHA256_BLOCK_LENGTH;
	SHA256_Compress(ctx);
    }
    /* if data left over, fill it into buffer */
    if (inputLen)
    	memcpy(B, input, inputLen);
}

void
SHA256_End(SHA256Context *ctx, unsigned char *digest,
           unsigned int *digestLen, unsigned int maxDigestLen)
{
    unsigned int inBuf = ctx->sizeLo & 0x3f;
    unsigned int padLen = (inBuf < 56) ? (56 - inBuf) : (56 + 64 - inBuf);
    PRUint32 hi, lo;
#ifdef SWAP4MASK
    PRUint32 t1;
#endif

    hi = (ctx->sizeHi << 3) | (ctx->sizeLo >> 29);
    lo = (ctx->sizeLo << 3);

    SHA256_Update(ctx, pad, padLen);

#if defined(IS_LITTLE_ENDIAN)
    W[14] = SHA_HTONL(hi);
    W[15] = SHA_HTONL(lo);
#else
    W[14] = hi;
    W[15] = lo;
#endif
    SHA256_Compress(ctx);

    /* now output the answer */
#if defined(IS_LITTLE_ENDIAN)
    BYTESWAP4(H[0]);
    BYTESWAP4(H[1]);
    BYTESWAP4(H[2]);
    BYTESWAP4(H[3]);
    BYTESWAP4(H[4]);
    BYTESWAP4(H[5]);
    BYTESWAP4(H[6]);
    BYTESWAP4(H[7]);
#endif
    padLen = PR_MIN(SHA256_LENGTH, maxDigestLen);
    memcpy(digest, H, padLen);
    if (digestLen)
	*digestLen = padLen;
}

/* Comment out unused code, mostly the SHA384 and SHA512 implementations. */
#if 0
SECStatus
SHA256_HashBuf(unsigned char *dest, const unsigned char *src,
               unsigned int src_length)
{
    SHA256Context ctx;
    unsigned int outLen;

    SHA256_Begin(&ctx);
    SHA256_Update(&ctx, src, src_length);
    SHA256_End(&ctx, dest, &outLen, SHA256_LENGTH);

    return SECSuccess;
}


SECStatus
SHA256_Hash(unsigned char *dest, const char *src)
{
    return SHA256_HashBuf(dest, (const unsigned char *)src, PORT_Strlen(src));
}


void SHA256_TraceState(SHA256Context *ctx) { }

unsigned int
SHA256_FlattenSize(SHA256Context *ctx)
{
    return sizeof *ctx;
}

SECStatus
SHA256_Flatten(SHA256Context *ctx,unsigned char *space)
{
    PORT_Memcpy(space, ctx, sizeof *ctx);
    return SECSuccess;
}

SHA256Context *
SHA256_Resurrect(unsigned char *space, void *arg)
{
    SHA256Context *ctx = SHA256_NewContext();
    if (ctx)
	PORT_Memcpy(ctx, space, sizeof *ctx);
    return ctx;
}

void SHA256_Clone(SHA256Context *dest, SHA256Context *src)
{
    memcpy(dest, src, sizeof *dest);
}


/* ======= SHA512 and SHA384 common constants and defines ================= */

/* common #defines for SHA512 and SHA384 */
#if defined(HAVE_LONG_LONG)
#define ROTR64(x,n) ((x >> n) | (x << (64 - n)))
#define ROTL64(x,n) ((x << n) | (x >> (64 - n)))

#define S0(x) (ROTR64(x,28) ^ ROTR64(x,34) ^ ROTR64(x,39))
#define S1(x) (ROTR64(x,14) ^ ROTR64(x,18) ^ ROTR64(x,41))
#define s0(x) (t1 = x, ROTR64(t1, 1) ^ ROTR64(t1, 8) ^ SHR(t1,7))
#define s1(x) (t2 = x, ROTR64(t2,19) ^ ROTR64(t2,61) ^ SHR(t2,6))

#if PR_BYTES_PER_LONG == 8
#define ULLC(hi,lo) 0x ## hi ## lo ## UL
#elif defined(_MSC_VER)
#define ULLC(hi,lo) 0x ## hi ## lo ## ui64
#else
#define ULLC(hi,lo) 0x ## hi ## lo ## ULL
#endif

#define SHA_MASK16 ULLC(0000FFFF,0000FFFF)
#define SHA_MASK8  ULLC(00FF00FF,00FF00FF)
#define SHA_HTONLL(x) (t1 = x, \
  t1 = ((t1 & SHA_MASK8 ) <<  8) | ((t1 >>  8) & SHA_MASK8 ), \
  t1 = ((t1 & SHA_MASK16) << 16) | ((t1 >> 16) & SHA_MASK16), \
  (t1 >> 32) | (t1 << 32))
#define BYTESWAP8(x)  x = SHA_HTONLL(x)

#else /* no long long */

#if defined(IS_LITTLE_ENDIAN)
#define ULLC(hi,lo) { 0x ## lo ## U, 0x ## hi ## U }
#else
#define ULLC(hi,lo) { 0x ## hi ## U, 0x ## lo ## U }
#endif

#define SHA_HTONLL(x) ( BYTESWAP4(x.lo), BYTESWAP4(x.hi), \
   x.hi ^= x.lo ^= x.hi ^= x.lo, x)
#define BYTESWAP8(x)  do { PRUint32 tmp; BYTESWAP4(x.lo); BYTESWAP4(x.hi); \
   tmp = x.lo; x.lo = x.hi; x.hi = tmp; } while (0)
#endif

/* SHA-384 and SHA-512 constants, K512. */
static const PRUint64 K512[80] = {
#if PR_BYTES_PER_LONG == 8
     0x428a2f98d728ae22UL ,  0x7137449123ef65cdUL ,
     0xb5c0fbcfec4d3b2fUL ,  0xe9b5dba58189dbbcUL ,
     0x3956c25bf348b538UL ,  0x59f111f1b605d019UL ,
     0x923f82a4af194f9bUL ,  0xab1c5ed5da6d8118UL ,
     0xd807aa98a3030242UL ,  0x12835b0145706fbeUL ,
     0x243185be4ee4b28cUL ,  0x550c7dc3d5ffb4e2UL ,
     0x72be5d74f27b896fUL ,  0x80deb1fe3b1696b1UL ,
     0x9bdc06a725c71235UL ,  0xc19bf174cf692694UL ,
     0xe49b69c19ef14ad2UL ,  0xefbe4786384f25e3UL ,
     0x0fc19dc68b8cd5b5UL ,  0x240ca1cc77ac9c65UL ,
     0x2de92c6f592b0275UL ,  0x4a7484aa6ea6e483UL ,
     0x5cb0a9dcbd41fbd4UL ,  0x76f988da831153b5UL ,
     0x983e5152ee66dfabUL ,  0xa831c66d2db43210UL ,
     0xb00327c898fb213fUL ,  0xbf597fc7beef0ee4UL ,
     0xc6e00bf33da88fc2UL ,  0xd5a79147930aa725UL ,
     0x06ca6351e003826fUL ,  0x142929670a0e6e70UL ,
     0x27b70a8546d22ffcUL ,  0x2e1b21385c26c926UL ,
     0x4d2c6dfc5ac42aedUL ,  0x53380d139d95b3dfUL ,
     0x650a73548baf63deUL ,  0x766a0abb3c77b2a8UL ,
     0x81c2c92e47edaee6UL ,  0x92722c851482353bUL ,
     0xa2bfe8a14cf10364UL ,  0xa81a664bbc423001UL ,
     0xc24b8b70d0f89791UL ,  0xc76c51a30654be30UL ,
     0xd192e819d6ef5218UL ,  0xd69906245565a910UL ,
     0xf40e35855771202aUL ,  0x106aa07032bbd1b8UL ,
     0x19a4c116b8d2d0c8UL ,  0x1e376c085141ab53UL ,
     0x2748774cdf8eeb99UL ,  0x34b0bcb5e19b48a8UL ,
     0x391c0cb3c5c95a63UL ,  0x4ed8aa4ae3418acbUL ,
     0x5b9cca4f7763e373UL ,  0x682e6ff3d6b2b8a3UL ,
     0x748f82ee5defb2fcUL ,  0x78a5636f43172f60UL ,
     0x84c87814a1f0ab72UL ,  0x8cc702081a6439ecUL ,
     0x90befffa23631e28UL ,  0xa4506cebde82bde9UL ,
     0xbef9a3f7b2c67915UL ,  0xc67178f2e372532bUL ,
     0xca273eceea26619cUL ,  0xd186b8c721c0c207UL ,
     0xeada7dd6cde0eb1eUL ,  0xf57d4f7fee6ed178UL ,
     0x06f067aa72176fbaUL ,  0x0a637dc5a2c898a6UL ,
     0x113f9804bef90daeUL ,  0x1b710b35131c471bUL ,
     0x28db77f523047d84UL ,  0x32caab7b40c72493UL ,
     0x3c9ebe0a15c9bebcUL ,  0x431d67c49c100d4cUL ,
     0x4cc5d4becb3e42b6UL ,  0x597f299cfc657e2aUL ,
     0x5fcb6fab3ad6faecUL ,  0x6c44198c4a475817UL
#else
    ULLC(428a2f98,d728ae22), ULLC(71374491,23ef65cd),
    ULLC(b5c0fbcf,ec4d3b2f), ULLC(e9b5dba5,8189dbbc),
    ULLC(3956c25b,f348b538), ULLC(59f111f1,b605d019),
    ULLC(923f82a4,af194f9b), ULLC(ab1c5ed5,da6d8118),
    ULLC(d807aa98,a3030242), ULLC(12835b01,45706fbe),
    ULLC(243185be,4ee4b28c), ULLC(550c7dc3,d5ffb4e2),
    ULLC(72be5d74,f27b896f), ULLC(80deb1fe,3b1696b1),
    ULLC(9bdc06a7,25c71235), ULLC(c19bf174,cf692694),
    ULLC(e49b69c1,9ef14ad2), ULLC(efbe4786,384f25e3),
    ULLC(0fc19dc6,8b8cd5b5), ULLC(240ca1cc,77ac9c65),
    ULLC(2de92c6f,592b0275), ULLC(4a7484aa,6ea6e483),
    ULLC(5cb0a9dc,bd41fbd4), ULLC(76f988da,831153b5),
    ULLC(983e5152,ee66dfab), ULLC(a831c66d,2db43210),
    ULLC(b00327c8,98fb213f), ULLC(bf597fc7,beef0ee4),
    ULLC(c6e00bf3,3da88fc2), ULLC(d5a79147,930aa725),
    ULLC(06ca6351,e003826f), ULLC(14292967,0a0e6e70),
    ULLC(27b70a85,46d22ffc), ULLC(2e1b2138,5c26c926),
    ULLC(4d2c6dfc,5ac42aed), ULLC(53380d13,9d95b3df),
    ULLC(650a7354,8baf63de), ULLC(766a0abb,3c77b2a8),
    ULLC(81c2c92e,47edaee6), ULLC(92722c85,1482353b),
    ULLC(a2bfe8a1,4cf10364), ULLC(a81a664b,bc423001),
    ULLC(c24b8b70,d0f89791), ULLC(c76c51a3,0654be30),
    ULLC(d192e819,d6ef5218), ULLC(d6990624,5565a910),
    ULLC(f40e3585,5771202a), ULLC(106aa070,32bbd1b8),
    ULLC(19a4c116,b8d2d0c8), ULLC(1e376c08,5141ab53),
    ULLC(2748774c,df8eeb99), ULLC(34b0bcb5,e19b48a8),
    ULLC(391c0cb3,c5c95a63), ULLC(4ed8aa4a,e3418acb),
    ULLC(5b9cca4f,7763e373), ULLC(682e6ff3,d6b2b8a3),
    ULLC(748f82ee,5defb2fc), ULLC(78a5636f,43172f60),
    ULLC(84c87814,a1f0ab72), ULLC(8cc70208,1a6439ec),
    ULLC(90befffa,23631e28), ULLC(a4506ceb,de82bde9),
    ULLC(bef9a3f7,b2c67915), ULLC(c67178f2,e372532b),
    ULLC(ca273ece,ea26619c), ULLC(d186b8c7,21c0c207),
    ULLC(eada7dd6,cde0eb1e), ULLC(f57d4f7f,ee6ed178),
    ULLC(06f067aa,72176fba), ULLC(0a637dc5,a2c898a6),
    ULLC(113f9804,bef90dae), ULLC(1b710b35,131c471b),
    ULLC(28db77f5,23047d84), ULLC(32caab7b,40c72493),
    ULLC(3c9ebe0a,15c9bebc), ULLC(431d67c4,9c100d4c),
    ULLC(4cc5d4be,cb3e42b6), ULLC(597f299c,fc657e2a),
    ULLC(5fcb6fab,3ad6faec), ULLC(6c44198c,4a475817)
#endif
};

struct SHA512ContextStr {
    union {
	PRUint64 w[80];	    /* message schedule, input buffer, plus 64 words */
	PRUint32 l[160];
	PRUint8  b[640];
    } u;
    PRUint64 h[8];	    /* 8 state variables */
    PRUint64 sizeLo;	    /* 64-bit count of hashed bytes. */
};

/* =========== SHA512 implementation ===================================== */

/* SHA-512 initial hash values */
static const PRUint64 H512[8] = {
#if PR_BYTES_PER_LONG == 8
     0x6a09e667f3bcc908UL ,  0xbb67ae8584caa73bUL ,
     0x3c6ef372fe94f82bUL ,  0xa54ff53a5f1d36f1UL ,
     0x510e527fade682d1UL ,  0x9b05688c2b3e6c1fUL ,
     0x1f83d9abfb41bd6bUL ,  0x5be0cd19137e2179UL
#else
    ULLC(6a09e667,f3bcc908), ULLC(bb67ae85,84caa73b),
    ULLC(3c6ef372,fe94f82b), ULLC(a54ff53a,5f1d36f1),
    ULLC(510e527f,ade682d1), ULLC(9b05688c,2b3e6c1f),
    ULLC(1f83d9ab,fb41bd6b), ULLC(5be0cd19,137e2179)
#endif
};


SHA512Context *
SHA512_NewContext(void)
{
    SHA512Context *ctx = PORT_New(SHA512Context);
    return ctx;
}

void
SHA512_DestroyContext(SHA512Context *ctx, PRBool freeit)
{
    if (freeit) {
        PORT_ZFree(ctx, sizeof *ctx);
    }
}

void
SHA512_Begin(SHA512Context *ctx)
{
    memset(ctx, 0, sizeof *ctx);
    memcpy(H, H512, sizeof H512);
}

#if defined(SHA512_TRACE)
#if defined(HAVE_LONG_LONG)
#define DUMP(n,a,d,e,h) printf(" t = %2d, %s = %016lx, %s = %016lx\n", \
			       n, #e, d, #a, h);
#else
#define DUMP(n,a,d,e,h) printf(" t = %2d, %s = %08x%08x, %s = %08x%08x\n", \
			       n, #e, d.hi, d.lo, #a, h.hi, h.lo);
#endif
#else
#define DUMP(n,a,d,e,h)
#endif

#if defined(HAVE_LONG_LONG)

#define ADDTO(x,y) y += x

#define INITW(t) W[t] = (s1(W[t-2]) + W[t-7] + s0(W[t-15]) + W[t-16])

#define ROUND(n,a,b,c,d,e,f,g,h) \
    h += S1(e) + Ch(e,f,g) + K512[n] + W[n]; \
    d += h; \
    h += S0(a) + Maj(a,b,c); \
    DUMP(n,a,d,e,h)

#else /* use only 32-bit variables, and don't unroll loops */

#undef  NOUNROLL512
#define NOUNROLL512 1

#define ADDTO(x,y) y.lo += x.lo; y.hi += x.hi + (x.lo > y.lo)

#define ROTR64a(x,n,lo,hi) (x.lo >> n | x.hi << (32-n))
#define ROTR64A(x,n,lo,hi) (x.lo << (64-n) | x.hi >> (n-32))
#define  SHR64a(x,n,lo,hi) (x.lo >> n | x.hi << (32-n))

/* Capitol Sigma and lower case sigma functions */
#define s0lo(x) (ROTR64a(x,1,lo,hi) ^ ROTR64a(x,8,lo,hi) ^ SHR64a(x,7,lo,hi))
#define s0hi(x) (ROTR64a(x,1,hi,lo) ^ ROTR64a(x,8,hi,lo) ^ (x.hi >> 7))

#define s1lo(x) (ROTR64a(x,19,lo,hi) ^ ROTR64A(x,61,lo,hi) ^ SHR64a(x,6,lo,hi))
#define s1hi(x) (ROTR64a(x,19,hi,lo) ^ ROTR64A(x,61,hi,lo) ^ (x.hi >> 6))

#define S0lo(x)(ROTR64a(x,28,lo,hi) ^ ROTR64A(x,34,lo,hi) ^ ROTR64A(x,39,lo,hi))
#define S0hi(x)(ROTR64a(x,28,hi,lo) ^ ROTR64A(x,34,hi,lo) ^ ROTR64A(x,39,hi,lo))

#define S1lo(x)(ROTR64a(x,14,lo,hi) ^ ROTR64a(x,18,lo,hi) ^ ROTR64A(x,41,lo,hi))
#define S1hi(x)(ROTR64a(x,14,hi,lo) ^ ROTR64a(x,18,hi,lo) ^ ROTR64A(x,41,hi,lo))

/* 32-bit versions of Ch and Maj */
#define Chxx(x,y,z,lo) ((x.lo & y.lo) ^ (~x.lo & z.lo))
#define Majx(x,y,z,lo) ((x.lo & y.lo) ^ (x.lo & z.lo) ^ (y.lo & z.lo))

#define INITW(t) \
    do { \
	PRUint32 lo, tm; \
	PRUint32 cy = 0; \
	lo = s1lo(W[t-2]); \
	lo += (tm = W[t-7].lo);     if (lo < tm) cy++; \
	lo += (tm = s0lo(W[t-15])); if (lo < tm) cy++; \
	lo += (tm = W[t-16].lo);    if (lo < tm) cy++; \
	W[t].lo = lo; \
	W[t].hi = cy + s1hi(W[t-2]) + W[t-7].hi + s0hi(W[t-15]) + W[t-16].hi; \
    } while (0)

#define ROUND(n,a,b,c,d,e,f,g,h) \
    { \
	PRUint32 lo, tm, cy; \
	lo  = S1lo(e); \
	lo += (tm = Chxx(e,f,g,lo));    cy = (lo < tm); \
	lo += (tm = K512[n].lo);	if (lo < tm) cy++; \
	lo += (tm =    W[n].lo);	if (lo < tm) cy++; \
	h.lo += lo;			if (h.lo < lo) cy++; \
	h.hi += cy + S1hi(e) + Chxx(e,f,g,hi) + K512[n].hi + W[n].hi; \
	d.lo += h.lo; \
	d.hi += h.hi + (d.lo < h.lo); \
	lo  = S0lo(a);  \
	lo += (tm = Majx(a,b,c,lo));	cy = (lo < tm); \
	h.lo += lo;			if (h.lo < lo) cy++; \
	h.hi += cy + S0hi(a) + Majx(a,b,c,hi); \
	DUMP(n,a,d,e,h) \
    }
#endif

static void
SHA512_Compress(SHA512Context *ctx)
{
#if defined(IS_LITTLE_ENDIAN)
  {
#if defined(HAVE_LONG_LONG)
    PRUint64 t1;
#else
    PRUint32 t1;
#endif
    BYTESWAP8(W[0]);
    BYTESWAP8(W[1]);
    BYTESWAP8(W[2]);
    BYTESWAP8(W[3]);
    BYTESWAP8(W[4]);
    BYTESWAP8(W[5]);
    BYTESWAP8(W[6]);
    BYTESWAP8(W[7]);
    BYTESWAP8(W[8]);
    BYTESWAP8(W[9]);
    BYTESWAP8(W[10]);
    BYTESWAP8(W[11]);
    BYTESWAP8(W[12]);
    BYTESWAP8(W[13]);
    BYTESWAP8(W[14]);
    BYTESWAP8(W[15]);
  }
#endif

  {
    PRUint64 t1, t2;
#ifdef NOUNROLL512
    {
	/* prepare the "message schedule"   */
	int t;
	for (t = 16; t < 80; ++t) {
	    INITW(t);
	}
    }
#else
    INITW(16);
    INITW(17);
    INITW(18);
    INITW(19);

    INITW(20);
    INITW(21);
    INITW(22);
    INITW(23);
    INITW(24);
    INITW(25);
    INITW(26);
    INITW(27);
    INITW(28);
    INITW(29);

    INITW(30);
    INITW(31);
    INITW(32);
    INITW(33);
    INITW(34);
    INITW(35);
    INITW(36);
    INITW(37);
    INITW(38);
    INITW(39);

    INITW(40);
    INITW(41);
    INITW(42);
    INITW(43);
    INITW(44);
    INITW(45);
    INITW(46);
    INITW(47);
    INITW(48);
    INITW(49);

    INITW(50);
    INITW(51);
    INITW(52);
    INITW(53);
    INITW(54);
    INITW(55);
    INITW(56);
    INITW(57);
    INITW(58);
    INITW(59);

    INITW(60);
    INITW(61);
    INITW(62);
    INITW(63);
    INITW(64);
    INITW(65);
    INITW(66);
    INITW(67);
    INITW(68);
    INITW(69);

    INITW(70);
    INITW(71);
    INITW(72);
    INITW(73);
    INITW(74);
    INITW(75);
    INITW(76);
    INITW(77);
    INITW(78);
    INITW(79);
#endif
  }
#ifdef SHA512_TRACE
  {
    int i;
    for (i = 0; i < 80; ++i) {
#ifdef HAVE_LONG_LONG
	printf("W[%2d] = %016lx\n", i, W[i]);
#else
	printf("W[%2d] = %08x%08x\n", i, W[i].hi, W[i].lo);
#endif
    }
  }
#endif
  {
    PRUint64 a, b, c, d, e, f, g, h;

    a = H[0];
    b = H[1];
    c = H[2];
    d = H[3];
    e = H[4];
    f = H[5];
    g = H[6];
    h = H[7];

#ifdef NOUNROLL512
    {
	int t;
	for (t = 0; t < 80; t+= 8) {
	    ROUND(t+0,a,b,c,d,e,f,g,h)
	    ROUND(t+1,h,a,b,c,d,e,f,g)
	    ROUND(t+2,g,h,a,b,c,d,e,f)
	    ROUND(t+3,f,g,h,a,b,c,d,e)
	    ROUND(t+4,e,f,g,h,a,b,c,d)
	    ROUND(t+5,d,e,f,g,h,a,b,c)
	    ROUND(t+6,c,d,e,f,g,h,a,b)
	    ROUND(t+7,b,c,d,e,f,g,h,a)
	}
    }
#else
    ROUND( 0,a,b,c,d,e,f,g,h)
    ROUND( 1,h,a,b,c,d,e,f,g)
    ROUND( 2,g,h,a,b,c,d,e,f)
    ROUND( 3,f,g,h,a,b,c,d,e)
    ROUND( 4,e,f,g,h,a,b,c,d)
    ROUND( 5,d,e,f,g,h,a,b,c)
    ROUND( 6,c,d,e,f,g,h,a,b)
    ROUND( 7,b,c,d,e,f,g,h,a)

    ROUND( 8,a,b,c,d,e,f,g,h)
    ROUND( 9,h,a,b,c,d,e,f,g)
    ROUND(10,g,h,a,b,c,d,e,f)
    ROUND(11,f,g,h,a,b,c,d,e)
    ROUND(12,e,f,g,h,a,b,c,d)
    ROUND(13,d,e,f,g,h,a,b,c)
    ROUND(14,c,d,e,f,g,h,a,b)
    ROUND(15,b,c,d,e,f,g,h,a)

    ROUND(16,a,b,c,d,e,f,g,h)
    ROUND(17,h,a,b,c,d,e,f,g)
    ROUND(18,g,h,a,b,c,d,e,f)
    ROUND(19,f,g,h,a,b,c,d,e)
    ROUND(20,e,f,g,h,a,b,c,d)
    ROUND(21,d,e,f,g,h,a,b,c)
    ROUND(22,c,d,e,f,g,h,a,b)
    ROUND(23,b,c,d,e,f,g,h,a)

    ROUND(24,a,b,c,d,e,f,g,h)
    ROUND(25,h,a,b,c,d,e,f,g)
    ROUND(26,g,h,a,b,c,d,e,f)
    ROUND(27,f,g,h,a,b,c,d,e)
    ROUND(28,e,f,g,h,a,b,c,d)
    ROUND(29,d,e,f,g,h,a,b,c)
    ROUND(30,c,d,e,f,g,h,a,b)
    ROUND(31,b,c,d,e,f,g,h,a)

    ROUND(32,a,b,c,d,e,f,g,h)
    ROUND(33,h,a,b,c,d,e,f,g)
    ROUND(34,g,h,a,b,c,d,e,f)
    ROUND(35,f,g,h,a,b,c,d,e)
    ROUND(36,e,f,g,h,a,b,c,d)
    ROUND(37,d,e,f,g,h,a,b,c)
    ROUND(38,c,d,e,f,g,h,a,b)
    ROUND(39,b,c,d,e,f,g,h,a)

    ROUND(40,a,b,c,d,e,f,g,h)
    ROUND(41,h,a,b,c,d,e,f,g)
    ROUND(42,g,h,a,b,c,d,e,f)
    ROUND(43,f,g,h,a,b,c,d,e)
    ROUND(44,e,f,g,h,a,b,c,d)
    ROUND(45,d,e,f,g,h,a,b,c)
    ROUND(46,c,d,e,f,g,h,a,b)
    ROUND(47,b,c,d,e,f,g,h,a)

    ROUND(48,a,b,c,d,e,f,g,h)
    ROUND(49,h,a,b,c,d,e,f,g)
    ROUND(50,g,h,a,b,c,d,e,f)
    ROUND(51,f,g,h,a,b,c,d,e)
    ROUND(52,e,f,g,h,a,b,c,d)
    ROUND(53,d,e,f,g,h,a,b,c)
    ROUND(54,c,d,e,f,g,h,a,b)
    ROUND(55,b,c,d,e,f,g,h,a)

    ROUND(56,a,b,c,d,e,f,g,h)
    ROUND(57,h,a,b,c,d,e,f,g)
    ROUND(58,g,h,a,b,c,d,e,f)
    ROUND(59,f,g,h,a,b,c,d,e)
    ROUND(60,e,f,g,h,a,b,c,d)
    ROUND(61,d,e,f,g,h,a,b,c)
    ROUND(62,c,d,e,f,g,h,a,b)
    ROUND(63,b,c,d,e,f,g,h,a)

    ROUND(64,a,b,c,d,e,f,g,h)
    ROUND(65,h,a,b,c,d,e,f,g)
    ROUND(66,g,h,a,b,c,d,e,f)
    ROUND(67,f,g,h,a,b,c,d,e)
    ROUND(68,e,f,g,h,a,b,c,d)
    ROUND(69,d,e,f,g,h,a,b,c)
    ROUND(70,c,d,e,f,g,h,a,b)
    ROUND(71,b,c,d,e,f,g,h,a)

    ROUND(72,a,b,c,d,e,f,g,h)
    ROUND(73,h,a,b,c,d,e,f,g)
    ROUND(74,g,h,a,b,c,d,e,f)
    ROUND(75,f,g,h,a,b,c,d,e)
    ROUND(76,e,f,g,h,a,b,c,d)
    ROUND(77,d,e,f,g,h,a,b,c)
    ROUND(78,c,d,e,f,g,h,a,b)
    ROUND(79,b,c,d,e,f,g,h,a)
#endif

    ADDTO(a,H[0]);
    ADDTO(b,H[1]);
    ADDTO(c,H[2]);
    ADDTO(d,H[3]);
    ADDTO(e,H[4]);
    ADDTO(f,H[5]);
    ADDTO(g,H[6]);
    ADDTO(h,H[7]);
  }
}

void
SHA512_Update(SHA512Context *ctx, const unsigned char *input,
              unsigned int inputLen)
{
    unsigned int inBuf;
    if (!inputLen)
    	return;

#if defined(HAVE_LONG_LONG)
    inBuf = (unsigned int)ctx->sizeLo & 0x7f;
    /* Add inputLen into the count of bytes processed, before processing */
    ctx->sizeLo += inputLen;
#else
    inBuf = (unsigned int)ctx->sizeLo.lo & 0x7f;
    ctx->sizeLo.lo += inputLen;
    if (ctx->sizeLo.lo < inputLen) ctx->sizeLo.hi++;
#endif

    /* if data already in buffer, attemp to fill rest of buffer */
    if (inBuf) {
    	unsigned int todo = SHA512_BLOCK_LENGTH - inBuf;
	if (inputLen < todo)
	    todo = inputLen;
	memcpy(B + inBuf, input, todo);
	input    += todo;
	inputLen -= todo;
	if (inBuf + todo == SHA512_BLOCK_LENGTH)
	    SHA512_Compress(ctx);
    }

    /* if enough data to fill one or more whole buffers, process them. */
    while (inputLen >= SHA512_BLOCK_LENGTH) {
    	memcpy(B, input, SHA512_BLOCK_LENGTH);
	input    += SHA512_BLOCK_LENGTH;
	inputLen -= SHA512_BLOCK_LENGTH;
	SHA512_Compress(ctx);
    }
    /* if data left over, fill it into buffer */
    if (inputLen)
    	memcpy(B, input, inputLen);
}

void
SHA512_End(SHA512Context *ctx, unsigned char *digest,
           unsigned int *digestLen, unsigned int maxDigestLen)
{
#if defined(HAVE_LONG_LONG)
    unsigned int inBuf  = (unsigned int)ctx->sizeLo & 0x7f;
    unsigned int padLen = (inBuf < 112) ? (112 - inBuf) : (112 + 128 - inBuf);
    PRUint64 lo, t1;
    lo = (ctx->sizeLo << 3);
#else
    unsigned int inBuf  = (unsigned int)ctx->sizeLo.lo & 0x7f;
    unsigned int padLen = (inBuf < 112) ? (112 - inBuf) : (112 + 128 - inBuf);
    PRUint64 lo = ctx->sizeLo;
    PRUint32 t1;
    lo.lo <<= 3;
#endif

    SHA512_Update(ctx, pad, padLen);

#if defined(HAVE_LONG_LONG)
    W[14] = 0;
#else
    W[14].lo = 0;
    W[14].hi = 0;
#endif

    W[15] = lo;
#if defined(IS_LITTLE_ENDIAN)
    BYTESWAP8(W[15]);
#endif
    SHA512_Compress(ctx);

    /* now output the answer */
#if defined(IS_LITTLE_ENDIAN)
    BYTESWAP8(H[0]);
    BYTESWAP8(H[1]);
    BYTESWAP8(H[2]);
    BYTESWAP8(H[3]);
    BYTESWAP8(H[4]);
    BYTESWAP8(H[5]);
    BYTESWAP8(H[6]);
    BYTESWAP8(H[7]);
#endif
    padLen = PR_MIN(SHA512_LENGTH, maxDigestLen);
    memcpy(digest, H, padLen);
    if (digestLen)
	*digestLen = padLen;
}

SECStatus
SHA512_HashBuf(unsigned char *dest, const unsigned char *src,
               unsigned int src_length)
{
    SHA512Context ctx;
    unsigned int outLen;

    SHA512_Begin(&ctx);
    SHA512_Update(&ctx, src, src_length);
    SHA512_End(&ctx, dest, &outLen, SHA512_LENGTH);

    return SECSuccess;
}


SECStatus
SHA512_Hash(unsigned char *dest, const char *src)
{
    return SHA512_HashBuf(dest, (const unsigned char *)src, PORT_Strlen(src));
}


void SHA512_TraceState(SHA512Context *ctx) { }

unsigned int
SHA512_FlattenSize(SHA512Context *ctx)
{
    return sizeof *ctx;
}

SECStatus
SHA512_Flatten(SHA512Context *ctx,unsigned char *space)
{
    PORT_Memcpy(space, ctx, sizeof *ctx);
    return SECSuccess;
}

SHA512Context *
SHA512_Resurrect(unsigned char *space, void *arg)
{
    SHA512Context *ctx = SHA512_NewContext();
    if (ctx)
	PORT_Memcpy(ctx, space, sizeof *ctx);
    return ctx;
}

void SHA512_Clone(SHA512Context *dest, SHA512Context *src)
{
    memcpy(dest, src, sizeof *dest);
}

/* ======================================================================= */
/* SHA384 uses a SHA512Context as the real context.
** The only differences between SHA384 an SHA512 are:
** a) the intialization values for the context, and
** b) the number of bytes of data produced as output.
*/

/* SHA-384 initial hash values */
static const PRUint64 H384[8] = {
#if PR_BYTES_PER_LONG == 8
     0xcbbb9d5dc1059ed8UL ,  0x629a292a367cd507UL ,
     0x9159015a3070dd17UL ,  0x152fecd8f70e5939UL ,
     0x67332667ffc00b31UL ,  0x8eb44a8768581511UL ,
     0xdb0c2e0d64f98fa7UL ,  0x47b5481dbefa4fa4UL
#else
    ULLC(cbbb9d5d,c1059ed8), ULLC(629a292a,367cd507),
    ULLC(9159015a,3070dd17), ULLC(152fecd8,f70e5939),
    ULLC(67332667,ffc00b31), ULLC(8eb44a87,68581511),
    ULLC(db0c2e0d,64f98fa7), ULLC(47b5481d,befa4fa4)
#endif
};

SHA384Context *
SHA384_NewContext(void)
{
    return SHA512_NewContext();
}

void
SHA384_DestroyContext(SHA384Context *ctx, PRBool freeit)
{
    SHA512_DestroyContext(ctx, freeit);
}

void
SHA384_Begin(SHA384Context *ctx)
{
    memset(ctx, 0, sizeof *ctx);
    memcpy(H, H384, sizeof H384);
}

void
SHA384_Update(SHA384Context *ctx, const unsigned char *input,
		    unsigned int inputLen)
{
    SHA512_Update(ctx, input, inputLen);
}

void
SHA384_End(SHA384Context *ctx, unsigned char *digest,
		 unsigned int *digestLen, unsigned int maxDigestLen)
{
#define SHA_MIN(a,b) (a < b ? a : b)
    unsigned int maxLen = SHA_MIN(maxDigestLen, SHA384_LENGTH);
    SHA512_End(ctx, digest, digestLen, maxLen);
}

SECStatus
SHA384_HashBuf(unsigned char *dest, const unsigned char *src,
			  unsigned int src_length)
{
    SHA512Context ctx;
    unsigned int outLen;

    SHA384_Begin(&ctx);
    SHA512_Update(&ctx, src, src_length);
    SHA512_End(&ctx, dest, &outLen, SHA384_LENGTH);

    return SECSuccess;
}

SECStatus
SHA384_Hash(unsigned char *dest, const char *src)
{
    return SHA384_HashBuf(dest, (const unsigned char *)src, PORT_Strlen(src));
}

void SHA384_TraceState(SHA384Context *ctx) { }

unsigned int
SHA384_FlattenSize(SHA384Context *ctx)
{
    return sizeof(SHA384Context);
}

SECStatus
SHA384_Flatten(SHA384Context *ctx,unsigned char *space)
{
    return SHA512_Flatten(ctx, space);
}

SHA384Context *
SHA384_Resurrect(unsigned char *space, void *arg)
{
    return SHA512_Resurrect(space, arg);
}

void SHA384_Clone(SHA384Context *dest, SHA384Context *src)
{
    memcpy(dest, src, sizeof *dest);
}
#endif  /* Comment out unused code. */

/* ======================================================================= */
#ifdef SELFTEST
#include <stdio.h>

static const char abc[] = { "abc" };
static const char abcdbc[] = {
    "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"
};
static const char abcdef[] = {
    "abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmn"
    "hijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu"
};

void
dumpHash32(const unsigned char *buf, unsigned int bufLen)
{
    unsigned int i;
    for (i = 0; i < bufLen; i += 4) {
	printf(" %02x%02x%02x%02x", buf[i], buf[i+1], buf[i+2], buf[i+3]);
    }
    printf("\n");
}

void test256(void)
{
    unsigned char outBuf[SHA256_LENGTH];

    printf("SHA256, input = %s\n", abc);
    SHA256_Hash(outBuf, abc);
    dumpHash32(outBuf, sizeof outBuf);

    printf("SHA256, input = %s\n", abcdbc);
    SHA256_Hash(outBuf, abcdbc);
    dumpHash32(outBuf, sizeof outBuf);
}

void
dumpHash64(const unsigned char *buf, unsigned int bufLen)
{
    unsigned int i;
    for (i = 0; i < bufLen; i += 8) {
    	if (i % 32 == 0)
	    printf("\n");
	printf(" %02x%02x%02x%02x%02x%02x%02x%02x",
	       buf[i  ], buf[i+1], buf[i+2], buf[i+3],
	       buf[i+4], buf[i+5], buf[i+6], buf[i+7]);
    }
    printf("\n");
}

void test512(void)
{
    unsigned char outBuf[SHA512_LENGTH];

    printf("SHA512, input = %s\n", abc);
    SHA512_Hash(outBuf, abc);
    dumpHash64(outBuf, sizeof outBuf);

    printf("SHA512, input = %s\n", abcdef);
    SHA512_Hash(outBuf, abcdef);
    dumpHash64(outBuf, sizeof outBuf);
}

void time512(void)
{
    unsigned char outBuf[SHA512_LENGTH];

    SHA512_Hash(outBuf, abc);
    SHA512_Hash(outBuf, abcdef);
}

void test384(void)
{
    unsigned char outBuf[SHA384_LENGTH];

    printf("SHA384, input = %s\n", abc);
    SHA384_Hash(outBuf, abc);
    dumpHash64(outBuf, sizeof outBuf);

    printf("SHA384, input = %s\n", abcdef);
    SHA384_Hash(outBuf, abcdef);
    dumpHash64(outBuf, sizeof outBuf);
}

int main (int argc, char *argv[], char *envp[])
{
    int i = 1;
    if (argc > 1) {
    	i = atoi(argv[1]);
    }
    if (i < 2) {
	test256();
	test512();
	test384();
    } else {
    	while (i-- > 0) {
	    time512();
	}
	printf("done\n");
    }
    return 0;
}

#endif
