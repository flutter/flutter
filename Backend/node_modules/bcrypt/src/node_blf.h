/* $OpenBSD: blf.h,v 1.7 2007/03/14 17:59:41 grunk Exp $ */
/*
 * Blowfish - a fast block cipher designed by Bruce Schneier
 *
 * Copyright 1997 Niels Provos <provos@physnet.uni-hamburg.de>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. All advertising materials mentioning features or use of this software
 *    must display the following acknowledgement:
 *      This product includes software developed by Niels Provos.
 * 4. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef _NODE_BLF_H_
#define _NODE_BLF_H_

#include <sys/types.h>

/* Solaris compatibility */
#ifdef __sun
#define u_int8_t uint8_t
#define u_int16_t uint16_t
#define u_int32_t uint32_t
#define u_int64_t uint64_t
#endif

#ifdef _WIN32
#define u_int8_t unsigned __int8
#define u_int16_t unsigned __int16
#define u_int32_t unsigned __int32
#define u_int64_t unsigned __int64
#endif

/* Windows ssize_t compatibility */
#if defined(_WIN32) || defined(_WIN64)
#  if defined(_WIN64)
     typedef __int64 LONG_PTR;
#  else
     typedef long LONG_PTR;
#  endif
  typedef LONG_PTR SSIZE_T;
  typedef SSIZE_T ssize_t;
#endif

/* z/OS compatibility */
#ifdef __MVS__
typedef unsigned char u_int8_t;
typedef unsigned short u_int16_t;
typedef unsigned int u_int32_t;
typedef unsigned long long u_int64_t;
#endif

#define BCRYPT_VERSION '2'
#define BCRYPT_MAXSALT 16	/* Precomputation is just so nice */
#define BCRYPT_BLOCKS 6		/* Ciphertext blocks */
#define BCRYPT_MINROUNDS 16	/* we have log2(rounds) in salt */

/* Schneier specifies a maximum key length of 56 bytes.
 * This ensures that every key bit affects every cipher
 * bit.  However, the subkeys can hold up to 72 bytes.
 * Warning: For normal blowfish encryption only 56 bytes
 * of the key affect all cipherbits.
 */

#define BLF_N	16			/* Number of Subkeys */
#define BLF_MAXKEYLEN ((BLF_N-2)*4)	/* 448 bits */
#define BLF_MAXUTILIZED ((BLF_N+2)*4)	/* 576 bits */

#define _PASSWORD_LEN   128             /* max length, not counting NUL */
#define _SALT_LEN       32              /* max length */

/* Blowfish context */
typedef struct BlowfishContext {
	u_int32_t S[4][256];	/* S-Boxes */
	u_int32_t P[BLF_N + 2];	/* Subkeys */
} blf_ctx;

/* Raw access to customized Blowfish
 *	blf_key is just:
 *	Blowfish_initstate( state )
 *	Blowfish_expand0state( state, key, keylen )
 */

void Blowfish_encipher(blf_ctx *, u_int32_t *, u_int32_t *);
void Blowfish_decipher(blf_ctx *, u_int32_t *, u_int32_t *);
void Blowfish_initstate(blf_ctx *);
void Blowfish_expand0state(blf_ctx *, const u_int8_t *, u_int16_t);
void Blowfish_expandstate
(blf_ctx *, const u_int8_t *, u_int16_t, const u_int8_t *, u_int16_t);

/* Standard Blowfish */

void blf_key(blf_ctx *, const u_int8_t *, u_int16_t);
void blf_enc(blf_ctx *, u_int32_t *, u_int16_t);
void blf_dec(blf_ctx *, u_int32_t *, u_int16_t);

void blf_ecb_encrypt(blf_ctx *, u_int8_t *, u_int32_t);
void blf_ecb_decrypt(blf_ctx *, u_int8_t *, u_int32_t);

void blf_cbc_encrypt(blf_ctx *, u_int8_t *, u_int8_t *, u_int32_t);
void blf_cbc_decrypt(blf_ctx *, u_int8_t *, u_int8_t *, u_int32_t);

/* Converts u_int8_t to u_int32_t */
u_int32_t Blowfish_stream2word(const u_int8_t *, u_int16_t , u_int16_t *);

/* bcrypt functions*/
void bcrypt_gensalt(char, u_int8_t, u_int8_t*, char *);
void bcrypt(const char *, size_t key_len, const char *, char *);
void encode_salt(char *, u_int8_t *, char, u_int16_t, u_int8_t);
u_int32_t bcrypt_get_rounds(const char *);

#endif
