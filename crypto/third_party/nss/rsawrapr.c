/*
 * PKCS#1 encoding and decoding functions.
 * This file is believed to contain no code licensed from other parties.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include "seccomon.h"
#include "secerr.h"
#include "sechash.h"

/* Needed for RSA-PSS functions */
static const unsigned char eightZeros[] = { 0, 0, 0, 0, 0, 0, 0, 0 };

/*
 * Mask generation function MGF1 as defined in PKCS #1 v2.1 / RFC 3447.
 */
static SECStatus
MGF1(HASH_HashType hashAlg, unsigned char *mask, unsigned int maskLen,
     const unsigned char *mgfSeed, unsigned int mgfSeedLen)
{
    unsigned int digestLen;
    PRUint32 counter, rounds;
    unsigned char *tempHash, *temp;
    const SECHashObject *hash;
    void *hashContext;
    unsigned char C[4];

    hash = HASH_GetHashObject(hashAlg);
    if (hash == NULL)
        return SECFailure;

    hashContext = (*hash->create)();
    rounds = (maskLen + hash->length - 1) / hash->length;
    for (counter = 0; counter < rounds; counter++) {
        C[0] = (unsigned char)((counter >> 24) & 0xff);
        C[1] = (unsigned char)((counter >> 16) & 0xff);
        C[2] = (unsigned char)((counter >> 8) & 0xff);
        C[3] = (unsigned char)(counter & 0xff);

        /* This could be optimized when the clone functions in
         * rawhash.c are implemented. */
        (*hash->begin)(hashContext);
        (*hash->update)(hashContext, mgfSeed, mgfSeedLen); 
        (*hash->update)(hashContext, C, sizeof C);

        tempHash = mask + counter * hash->length;
        if (counter != (rounds-1)) {
            (*hash->end)(hashContext, tempHash, &digestLen, hash->length);
        } else { /* we're in the last round and need to cut the hash */
            temp = (unsigned char *)PORT_Alloc(hash->length);
            (*hash->end)(hashContext, temp, &digestLen, hash->length);
            PORT_Memcpy(tempHash, temp, maskLen - counter * hash->length);
            PORT_Free(temp);
        }
    }
    (*hash->destroy)(hashContext, PR_TRUE);

    return SECSuccess;
}

/*
 * Verify a RSA-PSS signature.
 * Described in RFC 3447, section 9.1.2.
 * We use mHash instead of M as input.
 * emBits from the RFC is just modBits - 1, see section 8.1.2.
 * We only support MGF1 as the MGF.
 *
 * NOTE: this code assumes modBits is a multiple of 8.
 */
SECStatus
emsa_pss_verify(const unsigned char *mHash,
                const unsigned char *em, unsigned int emLen,
                HASH_HashType hashAlg, HASH_HashType maskHashAlg,
                unsigned int sLen)
{
    const SECHashObject *hash;
    void *hash_context;
    unsigned char *db;
    unsigned char *H_;  /* H' from the RFC */
    unsigned int i, dbMaskLen;
    SECStatus rv;

    hash = HASH_GetHashObject(hashAlg);
    dbMaskLen = emLen - hash->length - 1;

    /* Step 3 + 4 + 6 */
    if ((emLen < (hash->length + sLen + 2)) ||
	(em[emLen - 1] != 0xbc) ||
	((em[0] & 0x80) != 0)) {
	PORT_SetError(SEC_ERROR_BAD_SIGNATURE);
	return SECFailure;
    }

    /* Step 7 */
    db = (unsigned char *)PORT_Alloc(dbMaskLen);
    if (db == NULL) {
	PORT_SetError(SEC_ERROR_NO_MEMORY);
	return SECFailure;
    }
    /* &em[dbMaskLen] points to H, used as mgfSeed */
    MGF1(maskHashAlg, db, dbMaskLen, &em[dbMaskLen], hash->length);

    /* Step 8 */
    for (i = 0; i < dbMaskLen; i++) {
	db[i] ^= em[i];
    }

    /* Step 9 */
    db[0] &= 0x7f;

    /* Step 10 */
    for (i = 0; i < (dbMaskLen - sLen - 1); i++) {
	if (db[i] != 0) {
	    PORT_Free(db);
	    PORT_SetError(SEC_ERROR_BAD_SIGNATURE);
	    return SECFailure;
	}
    }
    if (db[dbMaskLen - sLen - 1] != 0x01) {
	PORT_Free(db);
	PORT_SetError(SEC_ERROR_BAD_SIGNATURE);
	return SECFailure;
    }

    /* Step 12 + 13 */
    H_ = (unsigned char *)PORT_Alloc(hash->length);
    if (H_ == NULL) {
	PORT_Free(db);
	PORT_SetError(SEC_ERROR_NO_MEMORY);
	return SECFailure;
    }
    hash_context = (*hash->create)();
    if (hash_context == NULL) {
	PORT_Free(db);
	PORT_Free(H_);
	PORT_SetError(SEC_ERROR_NO_MEMORY);
	return SECFailure;
    }
    (*hash->begin)(hash_context);
    (*hash->update)(hash_context, eightZeros, 8);
    (*hash->update)(hash_context, mHash, hash->length);
    (*hash->update)(hash_context, &db[dbMaskLen - sLen], sLen);
    (*hash->end)(hash_context, H_, &i, hash->length);
    (*hash->destroy)(hash_context, PR_TRUE);

    PORT_Free(db);

    /* Step 14 */
    if (PORT_Memcmp(H_, &em[dbMaskLen], hash->length) != 0) {
	PORT_SetError(SEC_ERROR_BAD_SIGNATURE);
	rv = SECFailure;
    } else {
	rv = SECSuccess;
    }

    PORT_Free(H_);
    return rv;
}
