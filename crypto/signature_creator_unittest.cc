// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <vector>

#include "base/memory/scoped_ptr.h"
#include "base/sha1.h"
#include "crypto/rsa_private_key.h"
#include "crypto/sha2.h"
#include "crypto/signature_creator.h"
#include "crypto/signature_verifier.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace {

// This is the algorithm ID for SHA-1 with RSA encryption.
const uint8 kSHA1WithRSAAlgorithmID[] = {
  0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
  0xf7, 0x0d, 0x01, 0x01, 0x05, 0x05, 0x00
};

// This is the algorithm ID for SHA-1 with RSA encryption.
const uint8 kSHA256WithRSAAlgorithmID[] = {
  0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
  0xf7, 0x0d, 0x01, 0x01, 0x0B, 0x05, 0x00
};

}

TEST(SignatureCreatorTest, BasicTest) {
  // Do a verify round trip.
  scoped_ptr<crypto::RSAPrivateKey> key_original(
      crypto::RSAPrivateKey::Create(1024));
  ASSERT_TRUE(key_original.get());

  std::vector<uint8> key_info;
  key_original->ExportPrivateKey(&key_info);
  scoped_ptr<crypto::RSAPrivateKey> key(
      crypto::RSAPrivateKey::CreateFromPrivateKeyInfo(key_info));
  ASSERT_TRUE(key.get());

  scoped_ptr<crypto::SignatureCreator> signer(
      crypto::SignatureCreator::Create(key.get(),
                                       crypto::SignatureCreator::SHA1));
  ASSERT_TRUE(signer.get());

  std::string data("Hello, World!");
  ASSERT_TRUE(signer->Update(reinterpret_cast<const uint8*>(data.c_str()),
                             data.size()));

  std::vector<uint8> signature;
  ASSERT_TRUE(signer->Final(&signature));

  std::vector<uint8> public_key_info;
  ASSERT_TRUE(key_original->ExportPublicKey(&public_key_info));

  crypto::SignatureVerifier verifier;
  ASSERT_TRUE(verifier.VerifyInit(
      kSHA1WithRSAAlgorithmID, sizeof(kSHA1WithRSAAlgorithmID),
      &signature.front(), signature.size(),
      &public_key_info.front(), public_key_info.size()));

  verifier.VerifyUpdate(reinterpret_cast<const uint8*>(data.c_str()),
                        data.size());
  ASSERT_TRUE(verifier.VerifyFinal());
}

TEST(SignatureCreatorTest, SignDigestTest) {
  // Do a verify round trip.
  scoped_ptr<crypto::RSAPrivateKey> key_original(
      crypto::RSAPrivateKey::Create(1024));
  ASSERT_TRUE(key_original.get());

  std::vector<uint8> key_info;
  key_original->ExportPrivateKey(&key_info);
  scoped_ptr<crypto::RSAPrivateKey> key(
      crypto::RSAPrivateKey::CreateFromPrivateKeyInfo(key_info));
  ASSERT_TRUE(key.get());

  std::string data("Hello, World!");
  std::string sha1 = base::SHA1HashString(data);
  // Sign sha1 of the input data.
  std::vector<uint8> signature;
  ASSERT_TRUE(crypto::SignatureCreator::Sign(
      key.get(),
      crypto::SignatureCreator::SHA1,
      reinterpret_cast<const uint8*>(sha1.c_str()),
      sha1.size(),
      &signature));

  std::vector<uint8> public_key_info;
  ASSERT_TRUE(key_original->ExportPublicKey(&public_key_info));

  // Verify the input data.
  crypto::SignatureVerifier verifier;
  ASSERT_TRUE(verifier.VerifyInit(
      kSHA1WithRSAAlgorithmID, sizeof(kSHA1WithRSAAlgorithmID),
      &signature.front(), signature.size(),
      &public_key_info.front(), public_key_info.size()));

  verifier.VerifyUpdate(reinterpret_cast<const uint8*>(data.c_str()),
                        data.size());
  ASSERT_TRUE(verifier.VerifyFinal());
}

TEST(SignatureCreatorTest, SignSHA256DigestTest) {
  // Do a verify round trip.
  scoped_ptr<crypto::RSAPrivateKey> key_original(
      crypto::RSAPrivateKey::Create(1024));
  ASSERT_TRUE(key_original.get());

  std::vector<uint8> key_info;
  key_original->ExportPrivateKey(&key_info);
  scoped_ptr<crypto::RSAPrivateKey> key(
      crypto::RSAPrivateKey::CreateFromPrivateKeyInfo(key_info));
  ASSERT_TRUE(key.get());

  std::string data("Hello, World!");
  std::string sha256 = crypto::SHA256HashString(data);
  // Sign sha256 of the input data.
  std::vector<uint8> signature;
  ASSERT_TRUE(crypto::SignatureCreator::Sign(
      key.get(),
      crypto::SignatureCreator::HashAlgorithm::SHA256,
      reinterpret_cast<const uint8*>(sha256.c_str()),
      sha256.size(),
      &signature));

  std::vector<uint8> public_key_info;
  ASSERT_TRUE(key_original->ExportPublicKey(&public_key_info));

  // Verify the input data.
  crypto::SignatureVerifier verifier;
  ASSERT_TRUE(verifier.VerifyInit(
      kSHA256WithRSAAlgorithmID, sizeof(kSHA256WithRSAAlgorithmID),
      &signature.front(), signature.size(),
      &public_key_info.front(), public_key_info.size()));

  verifier.VerifyUpdate(reinterpret_cast<const uint8*>(data.c_str()),
                        data.size());
  ASSERT_TRUE(verifier.VerifyFinal());
}
