 /* ***** BEGIN LICENSE BLOCK *****
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
  * Portions created by the Initial Developer are Copyright (C) 1994-2000
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

#ifndef CRYPTO_THIRD_PARTY_NSS_CHROMIUM_NSS_H_
#define CRYPTO_THIRD_PARTY_NSS_CHROMIUM_NSS_H_

// This file contains some functions we borrowed from NSS.

#include <prtypes.h>
#include <hasht.h>
#include <keyhi.h>
#include <secmod.h>

#include "crypto/crypto_export.h"

extern "C" SECStatus emsa_pss_verify(const unsigned char *mHash,
                                     const unsigned char *em,
                                     unsigned int emLen,
                                     HASH_HashType hashAlg,
                                     HASH_HashType maskHashAlg,
                                     unsigned int sLen);

// Like PK11_ImportEncryptedPrivateKeyInfo, but hardcoded for EC, and returns
// the SECKEYPrivateKey.
// See https://bugzilla.mozilla.org/show_bug.cgi?id=211546
// When we use NSS 3.13.2 or later,
// PK11_ImportEncryptedPrivateKeyInfoAndReturnKey can be used instead.
SECStatus ImportEncryptedECPrivateKeyInfoAndReturnKey(
    PK11SlotInfo* slot,
    SECKEYEncryptedPrivateKeyInfo* epki,
    SECItem* password,
    SECItem* nickname,
    SECItem* public_value,
    PRBool permanent,
    PRBool sensitive,
    SECKEYPrivateKey** private_key,
    void* wincx);

// Like SEC_DerSignData.
CRYPTO_EXPORT SECStatus DerSignData(PLArenaPool *arena,
                                    SECItem *result,
                                    SECItem *input,
                                    SECKEYPrivateKey *key,
                                    SECOidTag algo_id);

#endif  // CRYPTO_THIRD_PARTY_NSS_CHROMIUM_NSS_H_
