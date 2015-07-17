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
  *   Dr Stephen Henson <stephen.henson@gemplus.com>
  *   Dr Vipul Gupta <vipul.gupta@sun.com>, and
  *   Douglas Stebila <douglas@stebila.ca>, Sun Microsystems Laboratories
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

#include "crypto/third_party/nss/chromium-nss.h"

#include <pk11pub.h>

#include "base/logging.h"

// Based on PK11_ImportEncryptedPrivateKeyInfo function in
// mozilla/security/nss/lib/pk11wrap/pk11akey.c.
SECStatus ImportEncryptedECPrivateKeyInfoAndReturnKey(
    PK11SlotInfo* slot,
    SECKEYEncryptedPrivateKeyInfo* epki,
    SECItem* password,
    SECItem* nickname,
    SECItem* public_value,
    PRBool permanent,
    PRBool sensitive,
    SECKEYPrivateKey** private_key,
    void* wincx) {
  SECItem* crypto_param = NULL;

  CK_ATTRIBUTE_TYPE usage = CKA_SIGN;

  PK11SymKey* key = PK11_PBEKeyGen(slot,
                                   &epki->algorithm,
                                   password,
                                   PR_FALSE,  // faulty3DES
                                   wincx);
  if (key == NULL) {
    DLOG(ERROR) << "PK11_PBEKeyGen: " << PORT_GetError();
    return SECFailure;
  }

  CK_MECHANISM_TYPE crypto_mech_type = PK11_GetPBECryptoMechanism(
      &epki->algorithm, &crypto_param, password);
  if (crypto_mech_type == CKM_INVALID_MECHANISM) {
    DLOG(ERROR) << "PK11_GetPBECryptoMechanism: " << PORT_GetError();
    PK11_FreeSymKey(key);
    return SECFailure;
  }

  crypto_mech_type = PK11_GetPadMechanism(crypto_mech_type);

  *private_key = PK11_UnwrapPrivKey(slot, key, crypto_mech_type, crypto_param,
                                    &epki->encryptedData, nickname,
                                    public_value, permanent, sensitive, CKK_EC,
                                    &usage, 1, wincx);

  if (crypto_param != NULL)
    SECITEM_ZfreeItem(crypto_param, PR_TRUE);

  PK11_FreeSymKey(key);

  if (!*private_key) {
    DLOG(ERROR) << "PK11_UnwrapPrivKey: " << PORT_GetError();
    return SECFailure;
  }

  return SECSuccess;
}
