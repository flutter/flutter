/*
 * Signature stuff.
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
 * Portions created by the Initial Developer are Copyright (C) 1994-2000
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 *   Dr Vipul Gupta <vipul.gupta@sun.com>, Sun Microsystems Laboratories
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

#include <vector>

#include <cryptohi.h>
#include <pk11pub.h>
#include <secerr.h>
#include <sechash.h>

#include "base/basictypes.h"
#include "base/logging.h"
#include "build/build_config.h"

SECStatus DerSignData(PLArenaPool *arena,
                      SECItem *result,
                      SECItem *input,
                      SECKEYPrivateKey *key,
                      SECOidTag algo_id) {
  if (key->keyType != ecKey) {
    return SEC_DerSignData(arena, result, input->data, input->len, key,
                           algo_id);
  }

  // NSS has a private function sec_DecodeSigAlg it uses to figure out the
  // correct hash from the algorithm id.
  HASH_HashType hash_type;
  switch (algo_id) {
    case SEC_OID_ANSIX962_ECDSA_SHA1_SIGNATURE:
      hash_type = HASH_AlgSHA1;
      break;
#ifdef SHA224_LENGTH
    case SEC_OID_ANSIX962_ECDSA_SHA224_SIGNATURE:
      hash_type = HASH_AlgSHA224;
      break;
#endif
    case SEC_OID_ANSIX962_ECDSA_SHA256_SIGNATURE:
      hash_type = HASH_AlgSHA256;
      break;
    case SEC_OID_ANSIX962_ECDSA_SHA384_SIGNATURE:
      hash_type = HASH_AlgSHA384;
      break;
    case SEC_OID_ANSIX962_ECDSA_SHA512_SIGNATURE:
      hash_type = HASH_AlgSHA512;
      break;
    default:
      PORT_SetError(SEC_ERROR_INVALID_ALGORITHM);
      return SECFailure;
  }

  // Hash the input.
  std::vector<uint8> hash_data(HASH_ResultLen(hash_type));
  SECStatus rv = HASH_HashBuf(
      hash_type, &hash_data[0], input->data, input->len);
  if (rv != SECSuccess)
    return rv;
  SECItem hash = {siBuffer, &hash_data[0], 
		  static_cast<unsigned int>(hash_data.size())};

  // Compute signature of hash.
  int signature_len = PK11_SignatureLen(key);
  std::vector<uint8> signature_data(signature_len);
  SECItem sig = {siBuffer, &signature_data[0], 
		 static_cast<unsigned int>(signature_len)};
  rv = PK11_Sign(key, &sig, &hash);
  if (rv != SECSuccess)
    return rv;

  CERTSignedData sd;
  PORT_Memset(&sd, 0, sizeof(sd));
  // Fill in tbsCertificate.
  sd.data.data = (unsigned char*) input->data;
  sd.data.len = input->len;

  // Fill in signatureAlgorithm.
  rv = SECOID_SetAlgorithmID(arena, &sd.signatureAlgorithm, algo_id, 0);
  if (rv != SECSuccess)
    return rv;

  // Fill in signatureValue.
  rv = DSAU_EncodeDerSigWithLen(&sd.signature, &sig, sig.len);
  if (rv != SECSuccess)
    return rv;
  sd.signature.len <<=  3;  // Convert to bit string.

  // DER encode the signed data object.
  void* encode_result = SEC_ASN1EncodeItem(
      arena, result, &sd, SEC_ASN1_GET(CERT_SignedDataTemplate));

  PORT_Free(sd.signature.data);

  return encode_result ? SECSuccess : SECFailure;
}
