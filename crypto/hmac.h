// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Utility class for calculating the HMAC for a given message. We currently
// only support SHA1 for the hash algorithm, but this can be extended easily.

#ifndef CRYPTO_HMAC_H_
#define CRYPTO_HMAC_H_

#include "base/basictypes.h"
#include "base/compiler_specific.h"
#include "base/memory/scoped_ptr.h"
#include "base/strings/string_piece.h"
#include "crypto/crypto_export.h"

namespace crypto {

// Simplify the interface and reduce includes by abstracting out the internals.
struct HMACPlatformData;
class SymmetricKey;

class CRYPTO_EXPORT HMAC {
 public:
  // The set of supported hash functions. Extend as required.
  enum HashAlgorithm {
    SHA1,
    SHA256,
  };

  explicit HMAC(HashAlgorithm hash_alg);
  ~HMAC();

  // Returns the length of digest that this HMAC will create.
  size_t DigestLength() const;

  // TODO(abarth): Add a PreferredKeyLength() member function.

  // Initializes this instance using |key| of the length |key_length|. Call Init
  // only once. It returns false on the second or later calls.
  //
  // NOTE: the US Federal crypto standard FIPS 198, Section 3 says:
  //   The size of the key, K, shall be equal to or greater than L/2, where L
  //   is the size of the hash function output.
  // In FIPS 198-1 (and SP-800-107, which describes key size recommendations),
  // this requirement is gone.  But a system crypto library may still enforce
  // this old requirement.  If the key is shorter than this recommended value,
  // Init() may fail.
  bool Init(const unsigned char* key, size_t key_length) WARN_UNUSED_RESULT;

  // Initializes this instance using |key|. Call Init
  // only once. It returns false on the second or later calls.
  bool Init(SymmetricKey* key) WARN_UNUSED_RESULT;

  // Initializes this instance using |key|. Call Init only once. It returns
  // false on the second or later calls.
  bool Init(const base::StringPiece& key) WARN_UNUSED_RESULT {
    return Init(reinterpret_cast<const unsigned char*>(key.data()),
                key.size());
  }

  // Calculates the HMAC for the message in |data| using the algorithm supplied
  // to the constructor and the key supplied to the Init method. The HMAC is
  // returned in |digest|, which has |digest_length| bytes of storage available.
  bool Sign(const base::StringPiece& data, unsigned char* digest,
            size_t digest_length) const WARN_UNUSED_RESULT;

  // Verifies that the HMAC for the message in |data| equals the HMAC provided
  // in |digest|, using the algorithm supplied to the constructor and the key
  // supplied to the Init method. Use of this method is strongly recommended
  // over using Sign() with a manual comparison (such as memcmp), as such
  // comparisons may result in side-channel disclosures, such as timing, that
  // undermine the cryptographic integrity. |digest| must be exactly
  // |DigestLength()| bytes long.
  bool Verify(const base::StringPiece& data,
              const base::StringPiece& digest) const WARN_UNUSED_RESULT;

  // Verifies a truncated HMAC, behaving identical to Verify(), except
  // that |digest| is allowed to be smaller than |DigestLength()|.
  bool VerifyTruncated(
      const base::StringPiece& data,
      const base::StringPiece& digest) const WARN_UNUSED_RESULT;

 private:
  HashAlgorithm hash_alg_;
  scoped_ptr<HMACPlatformData> plat_;

  DISALLOW_COPY_AND_ASSIGN(HMAC);
};

}  // namespace crypto

#endif  // CRYPTO_HMAC_H_
