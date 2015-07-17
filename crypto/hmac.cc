// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "crypto/hmac.h"

#include <algorithm>

#include "base/logging.h"
#include "crypto/secure_util.h"
#include "crypto/symmetric_key.h"

namespace crypto {

bool HMAC::Init(SymmetricKey* key) {
  std::string raw_key;
  bool result = key->GetRawKey(&raw_key) && Init(raw_key);
  // Zero out key copy.  This might get optimized away, but one can hope.
  // Using std::string to store key info at all is a larger problem.
  std::fill(raw_key.begin(), raw_key.end(), 0);
  return result;
}

size_t HMAC::DigestLength() const {
  switch (hash_alg_) {
    case SHA1:
      return 20;
    case SHA256:
      return 32;
    default:
      NOTREACHED();
      return 0;
  }
}

bool HMAC::Verify(const base::StringPiece& data,
                  const base::StringPiece& digest) const {
  if (digest.size() != DigestLength())
    return false;
  return VerifyTruncated(data, digest);
}

bool HMAC::VerifyTruncated(const base::StringPiece& data,
                           const base::StringPiece& digest) const {
  if (digest.empty())
    return false;
  size_t digest_length = DigestLength();
  scoped_ptr<unsigned char[]> computed_digest(
      new unsigned char[digest_length]);
  if (!Sign(data, computed_digest.get(), digest_length))
    return false;

  return SecureMemEqual(digest.data(), computed_digest.get(),
                        std::min(digest.size(), digest_length));
}

}  // namespace crypto
