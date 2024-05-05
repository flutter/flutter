/*	$OpenBSD: bcrypt.c,v 1.31 2014/03/22 23:02:03 tedu Exp $	*/

/*
 * Copyright (c) 1997 Niels Provos <provos@umich.edu>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

/* This password hashing algorithm was designed by David Mazieres
 * <dm@lcs.mit.edu> and works as follows:
 *
 * 1. state := InitState ()
 * 2. state := ExpandKey (state, salt, password)
 * 3. REPEAT rounds:
 *    	state := ExpandKey (state, 0, password)
 *    state := ExpandKey (state, 0, salt)
 * 4. ctext := "OrpheanBeholderScryDoubt"
 * 5. REPEAT 64:
 *    	ctext := Encrypt_ECB (state, ctext);
 * 6. RETURN Concatenate (salt, ctext);
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <string.h>

#include "node_blf.h"

#ifdef _WIN32
#define snprintf _snprintf
#endif

//#if !defined(__APPLE__) && !defined(__MACH__)
//#include "bsd/stdlib.h"
//#endif

/* This implementation is adaptable to current computing power.
 * You can have up to 2^31 rounds which should be enough for some
 * time to come.
 */

static void encode_base64(u_int8_t *, u_int8_t *, u_int16_t);
static void decode_base64(u_int8_t *, u_int16_t, u_int8_t *);

const static char* error = ":";

const static u_int8_t Base64Code[] =
"./ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";

const static u_int8_t index_64[128] = {
	255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
	255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
	255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
	255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
	255, 255, 255, 255, 255, 255, 0, 1, 54, 55,
	56, 57, 58, 59, 60, 61, 62, 63, 255, 255,
	255, 255, 255, 255, 255, 2, 3, 4, 5, 6,
	7, 8, 9, 10, 11, 12, 13, 14, 15, 16,
	17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27,
	255, 255, 255, 255, 255, 255, 28, 29, 30,
	31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
	41, 42, 43, 44, 45, 46, 47, 48, 49, 50,
	51, 52, 53, 255, 255, 255, 255, 255
};
#define CHAR64(c)  ( (c) > 127 ? 255 : index_64[(c)])

static void
decode_base64(u_int8_t *buffer, u_int16_t len, u_int8_t *data)
{
	u_int8_t *bp = buffer;
	u_int8_t *p = data;
	u_int8_t c1, c2, c3, c4;
	while (bp < buffer + len) {
		c1 = CHAR64(*p);
		c2 = CHAR64(*(p + 1));

		/* Invalid data */
		if (c1 == 255 || c2 == 255)
			break;

		*bp++ = (c1 << 2) | ((c2 & 0x30) >> 4);
		if (bp >= buffer + len)
			break;

		c3 = CHAR64(*(p + 2));
		if (c3 == 255)
			break;

		*bp++ = ((c2 & 0x0f) << 4) | ((c3 & 0x3c) >> 2);
		if (bp >= buffer + len)
			break;

		c4 = CHAR64(*(p + 3));
		if (c4 == 255)
			break;
		*bp++ = ((c3 & 0x03) << 6) | c4;

		p += 4;
	}
}

void
encode_salt(char *salt, u_int8_t *csalt, char minor, u_int16_t clen, u_int8_t logr)
{
	salt[0] = '$';
	salt[1] = BCRYPT_VERSION;
	salt[2] = minor;
	salt[3] = '$';

    // Max rounds are 31
	snprintf(salt + 4, 4, "%2.2u$", logr & 0x001F);

	encode_base64((u_int8_t *) salt + 7, csalt, clen);
}


/* Generates a salt for this version of crypt.
   Since versions may change. Keeping this here
   seems sensible.
   from: http://mail-index.netbsd.org/tech-crypto/2002/05/24/msg000204.html
*/
void
bcrypt_gensalt(char minor, u_int8_t log_rounds, u_int8_t *seed, char *gsalt)
{
	if (log_rounds < 4)
		log_rounds = 4;
	else if (log_rounds > 31)
		log_rounds = 31;

	encode_salt(gsalt, seed, minor, BCRYPT_MAXSALT, log_rounds);
}

/* We handle $Vers$log2(NumRounds)$salt+passwd$
   i.e. $2$04$iwouldntknowwhattosayetKdJ6iFtacBqJdKe6aW7ou */

void
bcrypt(const char *key, size_t key_len, const char *salt, char *encrypted)
{
	blf_ctx state;
	u_int32_t rounds, i, k;
	u_int16_t j;
	u_int8_t salt_len, logr, minor;
	u_int8_t ciphertext[4 * BCRYPT_BLOCKS+1] = "OrpheanBeholderScryDoubt";
	u_int8_t csalt[BCRYPT_MAXSALT];
	u_int32_t cdata[BCRYPT_BLOCKS];
	int n;

	/* Discard "$" identifier */
	salt++;

	if (*salt > BCRYPT_VERSION) {
		/* How do I handle errors ? Return ':' */
		strcpy(encrypted, error);
		return;
	}

	/* Check for minor versions */
	if (salt[1] != '$') {
		 switch (salt[1]) {
		 case 'a': /* 'ab' should not yield the same as 'abab' */
		 case 'b': /* cap input length at 72 bytes */
			 minor = salt[1];
			 salt++;
			 break;
		 default:
			 strcpy(encrypted, error);
			 return;
		 }
	} else
		 minor = 0;

	/* Discard version + "$" identifier */
	salt += 2;

	if (salt[2] != '$') {
		/* Out of sync with passwd entry */
		strcpy(encrypted, error);
		return;
	}

	/* Computer power doesn't increase linear, 2^x should be fine */
	n = atoi(salt);
	if (n > 31 || n < 0) {
		strcpy(encrypted, error);
		return;
	}
	logr = (u_int8_t)n;
	if ((rounds = (u_int32_t) 1 << logr) < BCRYPT_MINROUNDS) {
		strcpy(encrypted, error);
		return;
	}

	/* Discard num rounds + "$" identifier */
	salt += 3;

	if (strlen(salt) * 3 / 4 < BCRYPT_MAXSALT) {
		strcpy(encrypted, error);
		return;
	}

	/* We dont want the base64 salt but the raw data */
	decode_base64(csalt, BCRYPT_MAXSALT, (u_int8_t *) salt);
	salt_len = BCRYPT_MAXSALT;
	if (minor <= 'a')
		key_len = (u_int8_t)(key_len + (minor >= 'a' ? 1 : 0));
	else
	{
		/* cap key_len at the actual maximum supported
		* length here to avoid integer wraparound */
		if (key_len > 72)
			key_len = 72;
		key_len++; /* include the NUL */
	}


	/* Setting up S-Boxes and Subkeys */
	Blowfish_initstate(&state);
	Blowfish_expandstate(&state, csalt, salt_len,
		(u_int8_t *) key, key_len);
	for (k = 0; k < rounds; k++) {
		Blowfish_expand0state(&state, (u_int8_t *) key, key_len);
		Blowfish_expand0state(&state, csalt, salt_len);
	}

 	/* This can be precomputed later */
	j = 0;
	for (i = 0; i < BCRYPT_BLOCKS; i++)
		cdata[i] = Blowfish_stream2word(ciphertext, 4 * BCRYPT_BLOCKS, &j);

	/* Now do the encryption */
	for (k = 0; k < 64; k++)
		blf_enc(&state, cdata, BCRYPT_BLOCKS / 2);

	for (i = 0; i < BCRYPT_BLOCKS; i++) {
		ciphertext[4 * i + 3] = cdata[i] & 0xff;
		cdata[i] = cdata[i] >> 8;
		ciphertext[4 * i + 2] = cdata[i] & 0xff;
		cdata[i] = cdata[i] >> 8;
		ciphertext[4 * i + 1] = cdata[i] & 0xff;
		cdata[i] = cdata[i] >> 8;
		ciphertext[4 * i + 0] = cdata[i] & 0xff;
	}

	i = 0;
	encrypted[i++] = '$';
	encrypted[i++] = BCRYPT_VERSION;
	if (minor)
		encrypted[i++] = minor;
	encrypted[i++] = '$';

	snprintf(encrypted + i, 4, "%2.2u$", logr & 0x001F);

	encode_base64((u_int8_t *) encrypted + i + 3, csalt, BCRYPT_MAXSALT);
	encode_base64((u_int8_t *) encrypted + strlen(encrypted), ciphertext,
		4 * BCRYPT_BLOCKS - 1);
	memset(&state, 0, sizeof(state));
	memset(ciphertext, 0, sizeof(ciphertext));
	memset(csalt, 0, sizeof(csalt));
	memset(cdata, 0, sizeof(cdata));
}

u_int32_t bcrypt_get_rounds(const char * hash)
{
  /* skip past the leading "$" */
  if (!hash || *(hash++) != '$') return 0;

  /* skip past version */
  if (0 == (*hash++)) return 0;
  if (*hash && *hash != '$') hash++;
  if (*hash++ != '$') return 0;

  return  atoi(hash);
}

static void
encode_base64(u_int8_t *buffer, u_int8_t *data, u_int16_t len)
{
	u_int8_t *bp = buffer;
	u_int8_t *p = data;
	u_int8_t c1, c2;
	while (p < data + len) {
		c1 = *p++;
		*bp++ = Base64Code[(c1 >> 2)];
		c1 = (c1 & 0x03) << 4;
		if (p >= data + len) {
			*bp++ = Base64Code[c1];
			break;
		}
		c2 = *p++;
		c1 |= (c2 >> 4) & 0x0f;
		*bp++ = Base64Code[c1];
		c1 = (c2 & 0x0f) << 2;
		if (p >= data + len) {
			*bp++ = Base64Code[c1];
			break;
		}
		c2 = *p++;
		c1 |= (c2 >> 6) & 0x03;
		*bp++ = Base64Code[c1];
		*bp++ = Base64Code[c2 & 0x3f];
	}
	*bp = '\0';
}
