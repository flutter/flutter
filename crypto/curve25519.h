// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef CRYPTO_CURVE25519_H
#define CRYPTO_CURVE25519_H

#include "base/basictypes.h"
#include "crypto/crypto_export.h"

namespace crypto {

// Curve25519 implements the elliptic curve group known as Curve25519, as
// described in "Curve 25519: new Diffie-Hellman Speed Records",
// by D.J. Bernstein. Additional information is available at
// http://cr.yp.to/ecdh.html.
namespace curve25519 {

// kBytes is the number of bytes in the result of the Diffie-Hellman operation,
// which is an element of GF(2^255-19).
static const size_t kBytes = 32;

// kScalarBytes is the number of bytes in an element of the scalar field:
// GF(2^252 + 27742317777372353535851937790883648493).
static const size_t kScalarBytes = 32;

// ScalarMult computes the |shared_key| from |private_key| and
// |peer_public_key|. This method is a wrapper for |curve25519_donna()|. It
// calls that function with |private_key| as |secret| and |peer_public_key| as
// basepoint. |private_key| should be of length |kScalarBytes| and
// |peer_public_key| should be of length |kBytes|.
// See "Computing shared secrets" section of/ http://cr.yp.to/ecdh.html.
CRYPTO_EXPORT void ScalarMult(const uint8* private_key,
                              const uint8* peer_public_key,
                              uint8* shared_key);

// ScalarBaseMult computes the |public_key| from |private_key|. This method is a
// wrapper for |curve25519_donna()|. It calls that function with |private_key|
// as |secret| and |kBasePoint| as basepoint. |private_key| should be of length
// |kScalarBytes|. See "Computing public keys" section of
// http://cr.yp.to/ecdh.html.
CRYPTO_EXPORT void ScalarBaseMult(const uint8* private_key, uint8* public_key);

}  // namespace curve25519

}  // namespace crypto

#endif  // CRYPTO_CURVE25519_H
