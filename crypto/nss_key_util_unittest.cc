// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "crypto/nss_key_util.h"

#include <keyhi.h>
#include <pk11pub.h>

#include <vector>

#include "crypto/nss_util.h"
#include "crypto/scoped_nss_types.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace crypto {

class NSSKeyUtilTest : public testing::Test {
 public:
  void SetUp() override {
    EnsureNSSInit();

    internal_slot_.reset(PK11_GetInternalSlot());
    ASSERT_TRUE(internal_slot_);
  }

  PK11SlotInfo* internal_slot() { return internal_slot_.get(); }

 private:
  ScopedPK11Slot internal_slot_;
};

TEST_F(NSSKeyUtilTest, GenerateRSAKeyPairNSS) {
  const int kKeySizeBits = 1024;

  ScopedSECKEYPublicKey public_key;
  ScopedSECKEYPrivateKey private_key;
  ASSERT_TRUE(GenerateRSAKeyPairNSS(internal_slot(), kKeySizeBits,
                                    false /* not permanent */, &public_key,
                                    &private_key));

  EXPECT_EQ(rsaKey, SECKEY_GetPublicKeyType(public_key.get()));
  EXPECT_EQ(rsaKey, SECKEY_GetPrivateKeyType(private_key.get()));
  EXPECT_EQ((kKeySizeBits + 7) / 8,
            PK11_GetPrivateModulusLen(private_key.get()));
}

#if defined(USE_NSS_CERTS)
TEST_F(NSSKeyUtilTest, FindNSSKeyFromPublicKeyInfo) {
  // Create an NSS keypair, which will put the keys in the user's NSSDB.
  ScopedSECKEYPublicKey public_key;
  ScopedSECKEYPrivateKey private_key;
  ASSERT_TRUE(GenerateRSAKeyPairNSS(internal_slot(), 512,
                                    false /* not permanent */, &public_key,
                                    &private_key));

  ScopedSECItem item(SECKEY_EncodeDERSubjectPublicKeyInfo(public_key.get()));
  ASSERT_TRUE(item);
  std::vector<uint8_t> public_key_der(item->data, item->data + item->len);

  ScopedSECKEYPrivateKey private_key2 =
      FindNSSKeyFromPublicKeyInfo(public_key_der);
  ASSERT_TRUE(private_key2);
  EXPECT_EQ(private_key->pkcs11ID, private_key2->pkcs11ID);
}

TEST_F(NSSKeyUtilTest, FailedFindNSSKeyFromPublicKeyInfo) {
  // Create an NSS keypair, which will put the keys in the user's NSSDB.
  ScopedSECKEYPublicKey public_key;
  ScopedSECKEYPrivateKey private_key;
  ASSERT_TRUE(GenerateRSAKeyPairNSS(internal_slot(), 512,
                                    false /* not permanent */, &public_key,
                                    &private_key));

  ScopedSECItem item(SECKEY_EncodeDERSubjectPublicKeyInfo(public_key.get()));
  ASSERT_TRUE(item);
  std::vector<uint8_t> public_key_der(item->data, item->data + item->len);

  // Remove the keys from the DB, and make sure we can't find them again.
  PK11_DestroyTokenObject(private_key->pkcs11Slot, private_key->pkcs11ID);
  PK11_DestroyTokenObject(public_key->pkcs11Slot, public_key->pkcs11ID);

  EXPECT_FALSE(FindNSSKeyFromPublicKeyInfo(public_key_der));
}
#endif  // defined(USE_NSS_CERTS)

}  // namespace crypto
