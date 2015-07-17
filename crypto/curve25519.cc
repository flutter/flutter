// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "crypto/curve25519.h"

// Curve25519 is specified in terms of byte strings, not numbers, so all
// implementations take and return the same sequence of bits. So the byte
// order is implicitly specified as in, say, SHA1.
//
// Prototype for |curve25519_donna| function in
// third_party/curve25519-donna/curve25519-donna.c
extern "C" int curve25519_donna(uint8*, const uint8*, const uint8*);

namespace crypto {

namespace curve25519 {

void ScalarMult(const uint8* private_key,
                const uint8* peer_public_key,
                uint8* shared_key) {
  curve25519_donna(shared_key, private_key, peer_public_key);
}

// kBasePoint is the base point (generator) of the elliptic curve group.
// It is little-endian version of '9' followed by 31 zeros.
// See "Computing public keys" section of http://cr.yp.to/ecdh.html.
static const unsigned char kBasePoint[32] = {9};

void ScalarBaseMult(const uint8* private_key, uint8* public_key) {
  curve25519_donna(public_key, private_key, kBasePoint);
}

}  // namespace curve25519

}  // namespace crypto
