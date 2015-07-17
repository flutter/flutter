// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "crypto/curve25519.h"

#include <string>

#include "crypto/random.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace crypto {

// Test that the basic shared key exchange identity holds: that both parties end
// up with the same shared key. This test starts with a fixed private key for
// two parties: alice and bob. Runs ScalarBaseMult and ScalarMult to compute
// public key and shared key for alice and bob. It asserts that alice and bob
// have the same shared key.
TEST(Curve25519, SharedKeyIdentity) {
  uint8 alice_private_key[curve25519::kScalarBytes] = {3};
  uint8 bob_private_key[curve25519::kScalarBytes] = {5};

  // Get public key for alice and bob.
  uint8 alice_public_key[curve25519::kBytes];
  curve25519::ScalarBaseMult(alice_private_key, alice_public_key);

  uint8 bob_public_key[curve25519::kBytes];
  curve25519::ScalarBaseMult(bob_private_key, bob_public_key);

  // Get the shared key for alice, by using alice's private key and bob's
  // public key.
  uint8 alice_shared_key[curve25519::kBytes];
  curve25519::ScalarMult(alice_private_key, bob_public_key, alice_shared_key);

  // Get the shared key for bob, by using bob's private key and alice's public
  // key.
  uint8 bob_shared_key[curve25519::kBytes];
  curve25519::ScalarMult(bob_private_key, alice_public_key, bob_shared_key);

  // Computed shared key of alice and bob should be the same.
  ASSERT_EQ(0, memcmp(alice_shared_key, bob_shared_key, curve25519::kBytes));
}

}  // namespace crypto
