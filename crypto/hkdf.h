// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef CRYPTO_HKDF_H_
#define CRYPTO_HKDF_H_

#include <vector>

#include "base/basictypes.h"
#include "base/strings/string_piece.h"
#include "crypto/crypto_export.h"

namespace crypto {

// HKDF implements the key derivation function specified in RFC 5869 (using
// SHA-256) and outputs key material, as needed by QUIC.
// See https://tools.ietf.org/html/rfc5869 for details.
class CRYPTO_EXPORT HKDF {
 public:
  // |secret|: the input shared secret (or, from RFC 5869, the IKM).
  // |salt|: an (optional) public salt / non-secret random value. While
  // optional, callers are strongly recommended to provide a salt. There is no
  // added security value in making this larger than the SHA-256 block size of
  // 64 bytes.
  // |info|: an (optional) label to distinguish different uses of HKDF. It is
  // optional context and application specific information (can be a zero-length
  // string).
  // |key_bytes_to_generate|: the number of bytes of key material to generate
  // for both client and server.
  // |iv_bytes_to_generate|: the number of bytes of IV to generate for both
  // client and server.
  // |subkey_secret_bytes_to_generate|: the number of bytes of subkey secret to
  // generate, shared between client and server.
  HKDF(const base::StringPiece& secret,
       const base::StringPiece& salt,
       const base::StringPiece& info,
       size_t key_bytes_to_generate,
       size_t iv_bytes_to_generate,
       size_t subkey_secret_bytes_to_generate);
  ~HKDF();

  base::StringPiece client_write_key() const {
    return client_write_key_;
  }
  base::StringPiece client_write_iv() const {
    return client_write_iv_;
  }
  base::StringPiece server_write_key() const {
    return server_write_key_;
  }
  base::StringPiece server_write_iv() const {
    return server_write_iv_;
  }
  base::StringPiece subkey_secret() const {
    return subkey_secret_;
  }

 private:
  std::vector<uint8> output_;

  base::StringPiece client_write_key_;
  base::StringPiece server_write_key_;
  base::StringPiece client_write_iv_;
  base::StringPiece server_write_iv_;
  base::StringPiece subkey_secret_;
};

}  // namespace crypto

#endif  // CRYPTO_HKDF_H_
