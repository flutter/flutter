// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef CRYPTO_EC_SIGNATURE_CREATOR_H_
#define CRYPTO_EC_SIGNATURE_CREATOR_H_

#include <string>
#include <vector>

#include "base/basictypes.h"
#include "crypto/crypto_export.h"

namespace crypto {

class ECPrivateKey;
class ECSignatureCreator;

class CRYPTO_EXPORT ECSignatureCreatorFactory {
 public:
  virtual ~ECSignatureCreatorFactory() {}

  virtual ECSignatureCreator* Create(ECPrivateKey* key) = 0;
};

// Signs data using a bare private key (as opposed to a full certificate).
// We need this class because SignatureCreator is hardcoded to use
// RSAPrivateKey.
class CRYPTO_EXPORT ECSignatureCreator {
 public:
  virtual ~ECSignatureCreator() {}

  // Create an instance. The caller must ensure that the provided PrivateKey
  // instance outlives the created ECSignatureCreator.
  // TODO(rch):  This is currently hard coded to use SHA256. Ideally, we should
  // pass in the hash algorithm identifier.
  static ECSignatureCreator* Create(ECPrivateKey* key);

  // Set a factory to make the Create function return non-standard
  // ECSignatureCreator objects.  Because the ECDSA algorithm involves
  // randomness, this is useful for higher-level tests that want to have
  // deterministic mocked output to compare.
  static void SetFactoryForTesting(ECSignatureCreatorFactory* factory);

  // Signs |data_len| bytes from |data| and writes the results into
  // |signature| as a DER encoded ECDSA-Sig-Value from RFC 3279.
  //
  //  ECDSA-Sig-Value ::= SEQUENCE {
  //    r     INTEGER,
  //    s     INTEGER }
  virtual bool Sign(const uint8* data,
                    int data_len,
                    std::vector<uint8>* signature) = 0;

  // DecodeSignature converts from a DER encoded ECDSA-Sig-Value (as produced
  // by Sign) to a `raw' ECDSA signature which consists of a pair of
  // big-endian, zero-padded, 256-bit integers, r and s. On success it returns
  // true and puts the raw signature into |out_raw_sig|.
  // (Only P-256 signatures are supported.)
  virtual bool DecodeSignature(const std::vector<uint8>& signature,
                               std::vector<uint8>* out_raw_sig) = 0;
};

}  // namespace crypto

#endif  // CRYPTO_EC_SIGNATURE_CREATOR_H_
