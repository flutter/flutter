// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "crypto/ec_signature_creator.h"

#include <string>
#include <vector>

#include "base/memory/scoped_ptr.h"
#include "crypto/ec_private_key.h"
#include "crypto/signature_verifier.h"
#include "testing/gtest/include/gtest/gtest.h"

// TODO(rch): Add some exported keys from each to
// test interop between NSS and OpenSSL.

TEST(ECSignatureCreatorTest, BasicTest) {
  // Do a verify round trip.
  scoped_ptr<crypto::ECPrivateKey> key_original(
      crypto::ECPrivateKey::Create());
  ASSERT_TRUE(key_original.get());

  std::vector<uint8> key_info;
  ASSERT_TRUE(
      key_original->ExportEncryptedPrivateKey(std::string(), 1000, &key_info));
  std::vector<uint8> pubkey_info;
  ASSERT_TRUE(key_original->ExportPublicKey(&pubkey_info));

  scoped_ptr<crypto::ECPrivateKey> key(
      crypto::ECPrivateKey::CreateFromEncryptedPrivateKeyInfo(
          std::string(), key_info, pubkey_info));
  ASSERT_TRUE(key.get());
  ASSERT_TRUE(key->key() != NULL);

  scoped_ptr<crypto::ECSignatureCreator> signer(
      crypto::ECSignatureCreator::Create(key.get()));
  ASSERT_TRUE(signer.get());

  std::string data("Hello, World!");
  std::vector<uint8> signature;
  ASSERT_TRUE(signer->Sign(reinterpret_cast<const uint8*>(data.c_str()),
                           data.size(),
                           &signature));

  std::vector<uint8> public_key_info;
  ASSERT_TRUE(key_original->ExportPublicKey(&public_key_info));

  // This is the algorithm ID for ECDSA with SHA-256. Parameters are ABSENT.
  // RFC 5758:
  //   ecdsa-with-SHA256 OBJECT IDENTIFIER ::= { iso(1) member-body(2)
  //        us(840) ansi-X9-62(10045) signatures(4) ecdsa-with-SHA2(3) 2 }
  //   ...
  //   When the ecdsa-with-SHA224, ecdsa-with-SHA256, ecdsa-with-SHA384, or
  //   ecdsa-with-SHA512 algorithm identifier appears in the algorithm field
  //   as an AlgorithmIdentifier, the encoding MUST omit the parameters
  //   field.  That is, the AlgorithmIdentifier SHALL be a SEQUENCE of one
  //   component, the OID ecdsa-with-SHA224, ecdsa-with-SHA256, ecdsa-with-
  //   SHA384, or ecdsa-with-SHA512.
  // See also RFC 5480, Appendix A.
  const uint8 kECDSAWithSHA256AlgorithmID[] = {
    0x30, 0x0a,
      0x06, 0x08,
        0x2a, 0x86, 0x48, 0xce, 0x3d, 0x04, 0x03, 0x02,
  };
  crypto::SignatureVerifier verifier;
  ASSERT_TRUE(verifier.VerifyInit(
      kECDSAWithSHA256AlgorithmID, sizeof(kECDSAWithSHA256AlgorithmID),
      &signature[0], signature.size(),
      &public_key_info.front(), public_key_info.size()));

  verifier.VerifyUpdate(reinterpret_cast<const uint8*>(data.c_str()),
                        data.size());
  ASSERT_TRUE(verifier.VerifyFinal());
}
