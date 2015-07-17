// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "crypto/aes_128_gcm_helpers_nss.h"

#include <pk11pub.h>
#include <secerr.h>
#include <string>

#include "base/logging.h"
#include "base/rand_util.h"
#include "base/strings/string_number_conversions.h"
#include "base/strings/string_util.h"
#include "crypto/nss_util.h"
#include "crypto/random.h"
#include "crypto/scoped_nss_types.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace crypto {

namespace {

// The AES GCM test vectors come from the gcmDecrypt128.rsp and
// gcmEncryptExtIV128.rsp files downloaded from
// http://csrc.nist.gov/groups/STM/cavp/index.html on 2013-02-01. The test
// vectors in that file look like this:
//
// [Keylen = 128]
// [IVlen = 96]
// [PTlen = 0]
// [AADlen = 0]
// [Taglen = 128]
//
// Count = 0
// Key = cf063a34d4a9a76c2c86787d3f96db71
// IV = 113b9785971864c83b01c787
// CT =
// AAD =
// Tag = 72ac8493e3a5228b5d130a69d2510e42
// PT =
//
// Count = 1
// Key = a49a5e26a2f8cb63d05546c2a62f5343
// IV = 907763b19b9b4ab6bd4f0281
// CT =
// AAD =
// Tag = a2be08210d8c470a8df6e8fbd79ec5cf
// FAIL
//
// ...
//
// These files are huge (2.6 MB and 2.8 MB), so this file contains just a
// selection of test vectors.

// Describes a group of test vectors that all have a given key length, IV
// length, plaintext length, AAD length, and tag length.
struct TestGroupInfo {
  size_t key_len;
  size_t iv_len;
  size_t input_len;
  size_t aad_len;
  size_t tag_len;
};

// Each test vector consists of six strings of lowercase hexadecimal digits.
// The strings may be empty (zero length). A test vector with a NULL |key|
// marks the end of an array of test vectors.
struct TestVector {
  // Input:
  const char* key;
  const char* iv;
  const char* input;
  const char* aad;
  const char* tag;

  // Expected output:
  const char* output;  // An empty string "" means decryption or encryption
                       // succeeded and the plaintext is zero-length. NULL means
                       // that the decryption or encryption failed.
};

const TestGroupInfo test_group_info[] = {
    {128, 96, 0, 0, 128},
    {128, 96, 0, 128, 128},
    {128, 96, 128, 0, 128},
    {128, 96, 408, 160, 128},
    {128, 96, 408, 720, 128},
    {128, 96, 104, 0, 128},
};

const TestVector decryption_test_group_0[] = {
    {"cf063a34d4a9a76c2c86787d3f96db71",
     "113b9785971864c83b01c787",
     "",
     "",
     "72ac8493e3a5228b5d130a69d2510e42",
     ""},
    {
     "a49a5e26a2f8cb63d05546c2a62f5343",
     "907763b19b9b4ab6bd4f0281",
     "",
     "",
     "a2be08210d8c470a8df6e8fbd79ec5cf",
     NULL  // FAIL
    },
    {NULL}};

const TestVector decryption_test_group_1[] = {
    {
     "d1f6af919cde85661208bdce0c27cb22",
     "898c6929b435017bf031c3c5",
     "",
     "7c5faa40e636bbc91107e68010c92b9f",
     "ae45f11777540a2caeb128be8092468a",
     NULL  // FAIL
    },
    {"2370e320d4344208e0ff5683f243b213",
     "04dbb82f044d30831c441228",
     "",
     "d43a8e5089eea0d026c03a85178b27da",
     "2a049c049d25aa95969b451d93c31c6e",
     ""},
    {NULL}};

const TestVector decryption_test_group_2[] = {
    {"e98b72a9881a84ca6b76e0f43e68647a",
     "8b23299fde174053f3d652ba",
     "5a3c1cf1985dbb8bed818036fdd5ab42",
     "",
     "23c7ab0f952b7091cd324835043b5eb5",
     "28286a321293253c3e0aa2704a278032"},
    {"33240636cd3236165f1a553b773e728e",
     "17c4d61493ecdc8f31700b12",
     "47bb7e23f7bdfe05a8091ac90e4f8b2e",
     "",
     "b723c70e931d9785f40fd4ab1d612dc9",
     "95695a5b12f2870b9cc5fdc8f218a97d"},
    {
     "5164df856f1e9cac04a79b808dc5be39",
     "e76925d5355e0584ce871b2b",
     "0216c899c88d6e32c958c7e553daa5bc",
     "",
     "a145319896329c96df291f64efbe0e3a",
     NULL  // FAIL
    },
    {NULL}};

const TestVector decryption_test_group_3[] = {
    {"af57f42c60c0fc5a09adb81ab86ca1c3",
     "a2dc01871f37025dc0fc9a79",
     "b9a535864f48ea7b6b1367914978f9bfa087d854bb0e269bed8d279d2eea1210e48947"
     "338b22f9bad09093276a331e9c79c7f4",
     "41dc38988945fcb44faf2ef72d0061289ef8efd8",
     "4f71e72bde0018f555c5adcce062e005",
     "3803a0727eeb0ade441e0ec107161ded2d425ec0d102f21f51bf2cf9947c7ec4aa7279"
     "5b2f69b041596e8817d0a3c16f8fadeb"},
    {"ebc753e5422b377d3cb64b58ffa41b61",
     "2e1821efaced9acf1f241c9b",
     "069567190554e9ab2b50a4e1fbf9c147340a5025fdbd201929834eaf6532325899ccb9"
     "f401823e04b05817243d2142a3589878",
     "b9673412fd4f88ba0e920f46dd6438ff791d8eef",
     "534d9234d2351cf30e565de47baece0b",
     "39077edb35e9c5a4b1e4c2a6b9bb1fce77f00f5023af40333d6d699014c2bcf4209c18"
     "353a18017f5b36bfc00b1f6dcb7ed485"},
    {
     "52bdbbf9cf477f187ec010589cb39d58",
     "d3be36d3393134951d324b31",
     "700188da144fa692cf46e4a8499510a53d90903c967f7f13e8a1bd8151a74adc4fe63e"
     "32b992760b3a5f99e9a47838867000a9",
     "93c4fc6a4135f54d640b0c976bf755a06a292c33",
     "8ca4e38aa3dfa6b1d0297021ccf3ea5f",
     NULL  // FAIL
    },
    {NULL}};

const TestVector decryption_test_group_4[] = {
    {"da2bb7d581493d692380c77105590201",
     "44aa3e7856ca279d2eb020c6",
     "9290d430c9e89c37f0446dbd620c9a6b34b1274aeb6f911f75867efcf95b6feda69f1a"
     "f4ee16c761b3c9aeac3da03aa9889c88",
     "4cd171b23bddb3a53cdf959d5c1710b481eb3785a90eb20a2345ee00d0bb7868c367ab"
     "12e6f4dd1dee72af4eee1d197777d1d6499cc541f34edbf45cda6ef90b3c024f9272d7"
     "2ec1909fb8fba7db88a4d6f7d3d925980f9f9f72",
     "9e3ac938d3eb0cadd6f5c9e35d22ba38",
     "9bbf4c1a2742f6ac80cb4e8a052e4a8f4f07c43602361355b717381edf9fabd4cb7e3a"
     "d65dbd1378b196ac270588dd0621f642"},
    {"d74e4958717a9d5c0e235b76a926cae8",
     "0b7471141e0c70b1995fd7b1",
     "e701c57d2330bf066f9ff8cf3ca4343cafe4894651cd199bdaaa681ba486b4a65c5a22"
     "b0f1420be29ea547d42c713bc6af66aa",
     "4a42b7aae8c245c6f1598a395316e4b8484dbd6e64648d5e302021b1d3fa0a38f46e22"
     "bd9c8080b863dc0016482538a8562a4bd0ba84edbe2697c76fd039527ac179ec5506cf"
     "34a6039312774cedebf4961f3978b14a26509f96",
     "e192c23cb036f0b31592989119eed55d",
     "840d9fb95e32559fb3602e48590280a172ca36d9b49ab69510f5bd552bfab7a306f85f"
     "f0a34bc305b88b804c60b90add594a17"},
    {
     "1986310c725ac94ecfe6422e75fc3ee7",
     "93ec4214fa8e6dc4e3afc775",
     "b178ec72f85a311ac4168f42a4b2c23113fbea4b85f4b9dabb74e143eb1b8b0a361e02"
     "43edfd365b90d5b325950df0ada058f9",
     "e80b88e62c49c958b5e0b8b54f532d9ff6aa84c8a40132e93e55b59fc24e8decf28463"
     "139f155d1e8ce4ee76aaeefcd245baa0fc519f83a5fb9ad9aa40c4b21126013f576c42"
     "72c2cb136c8fd091cc4539877a5d1e72d607f960",
     "8b347853f11d75e81e8a95010be81f17",
     NULL  // FAIL
    },
    {NULL}};

const TestVector decryption_test_group_5[] = {
    {"387218b246c1a8257748b56980e50c94",
     "dd7e014198672be39f95b69d",
     "cdba9e73eaf3d38eceb2b04a8d",
     "",
     "ecf90f4a47c9c626d6fb2c765d201556",
     "48f5b426baca03064554cc2b30"},
    {"294de463721e359863887c820524b3d4",
     "3338b35c9d57a5d28190e8c9",
     "2f46634e74b8e4c89812ac83b9",
     "",
     "dabd506764e68b82a7e720aa18da0abe",
     "46a2e55c8e264df211bd112685"},
    {"28ead7fd2179e0d12aa6d5d88c58c2dc",
     "5055347f18b4d5add0ae5c41",
     "142d8210c3fb84774cdbd0447a",
     "",
     "5fd321d9cdb01952dc85f034736c2a7d",
     "3b95b981086ee73cc4d0cc1422"},
    {
     "7d7b6c988137b8d470c57bf674a09c87",
     "9edf2aa970d016ac962e1fd8",
     "a85b66c3cb5eab91d5bdc8bc0e",
     "",
     "dc054efc01f3afd21d9c2484819f569a",
     NULL  // FAIL
    },
    {NULL}};

const TestVector encryption_test_group_0[] = {
    {"11754cd72aec309bf52f7687212e8957",
     "3c819d9a9bed087615030b65",
     "",
     "",
     "250327c674aaf477aef2675748cf6971",
     ""},
    {"ca47248ac0b6f8372a97ac43508308ed",
     "ffd2b598feabc9019262d2be",
     "",
     "",
     "60d20404af527d248d893ae495707d1a",
     ""},
    {NULL}};

const TestVector encryption_test_group_1[] = {
    {"77be63708971c4e240d1cb79e8d77feb",
     "e0e00f19fed7ba0136a797f3",
     "",
     "7a43ec1d9c0a5a78a0b16533a6213cab",
     "209fcc8d3675ed938e9c7166709dd946",
     ""},
    {"7680c5d3ca6154758e510f4d25b98820",
     "f8f105f9c3df4965780321f8",
     "",
     "c94c410194c765e3dcc7964379758ed3",
     "94dca8edfcf90bb74b153c8d48a17930",
     ""},
    {NULL}};

const TestVector encryption_test_group_2[] = {
    {"7fddb57453c241d03efbed3ac44e371c",
     "ee283a3fc75575e33efd4887",
     "d5de42b461646c255c87bd2962d3b9a2",
     "",
     "b36d1df9b9d5e596f83e8b7f52971cb3",
     "2ccda4a5415cb91e135c2a0f78c9b2fd"},
    {"ab72c77b97cb5fe9a382d9fe81ffdbed",
     "54cc7dc2c37ec006bcc6d1da",
     "007c5e5b3e59df24a7c355584fc1518d",
     "",
     "2b4401346697138c7a4891ee59867d0c",
     "0e1bde206a07a9c2c1b65300f8c64997"},
    {NULL}};

const TestVector encryption_test_group_3[] = {
    {"fe47fcce5fc32665d2ae399e4eec72ba",
     "5adb9609dbaeb58cbd6e7275",
     "7c0e88c88899a779228465074797cd4c2e1498d259b54390b85e3eef1c02df60e743f1"
     "b840382c4bccaf3bafb4ca8429bea063",
     "88319d6e1d3ffa5f987199166c8a9b56c2aeba5a",
     "291ef1982e4defedaa2249f898556b47",
     "98f4826f05a265e6dd2be82db241c0fbbbf9ffb1c173aa83964b7cf539304373636525"
     "3ddbc5db8778371495da76d269e5db3e"},
    {"ec0c2ba17aa95cd6afffe949da9cc3a8",
     "296bce5b50b7d66096d627ef",
     "b85b3753535b825cbe5f632c0b843c741351f18aa484281aebec2f45bb9eea2d79d987"
     "b764b9611f6c0f8641843d5d58f3a242",
     "f8d00f05d22bf68599bcdeb131292ad6e2df5d14",
     "890147971946b627c40016da1ecf3e77",
     "a7443d31c26bdf2a1c945e29ee4bd344a99cfaf3aa71f8b3f191f83c2adfc7a0716299"
     "5506fde6309ffc19e716eddf1a828c5a"},
    {NULL}};

const TestVector encryption_test_group_4[] = {
    {"2c1f21cf0f6fb3661943155c3e3d8492",
     "23cb5ff362e22426984d1907",
     "42f758836986954db44bf37c6ef5e4ac0adaf38f27252a1b82d02ea949c8a1a2dbc0d6"
     "8b5615ba7c1220ff6510e259f06655d8",
     "5d3624879d35e46849953e45a32a624d6a6c536ed9857c613b572b0333e701557a713e"
     "3f010ecdf9a6bd6c9e3e44b065208645aff4aabee611b391528514170084ccf587177f"
     "4488f33cfb5e979e42b6e1cfc0a60238982a7aec",
     "57a3ee28136e94c74838997ae9823f3a",
     "81824f0e0d523db30d3da369fdc0d60894c7a0a20646dd015073ad2732bd989b14a222"
     "b6ad57af43e1895df9dca2a5344a62cc"},
    {"d9f7d2411091f947b4d6f1e2d1f0fb2e",
     "e1934f5db57cc983e6b180e7",
     "73ed042327f70fe9c572a61545eda8b2a0c6e1d6c291ef19248e973aee6c312012f490"
     "c2c6f6166f4a59431e182663fcaea05a",
     "0a8a18a7150e940c3d87b38e73baee9a5c049ee21795663e264b694a949822b639092d"
     "0e67015e86363583fcf0ca645af9f43375f05fdb4ce84f411dcbca73c2220dea03a201"
     "15d2e51398344b16bee1ed7c499b353d6c597af8",
     "21b51ca862cb637cdd03b99a0f93b134",
     "aaadbd5c92e9151ce3db7210b8714126b73e43436d242677afa50384f2149b831f1d57"
     "3c7891c2a91fbc48db29967ec9542b23"},
    {NULL}};

const TestVector encryption_test_group_5[] = {
    {"fe9bb47deb3a61e423c2231841cfd1fb",
     "4d328eb776f500a2f7fb47aa",
     "f1cc3818e421876bb6b8bbd6c9",
     "",
     "43fd4727fe5cdb4b5b42818dea7ef8c9",
     "b88c5c1977b35b517b0aeae967"},
    {"6703df3701a7f54911ca72e24dca046a",
     "12823ab601c350ea4bc2488c",
     "793cd125b0b84a043e3ac67717",
     "",
     "38e6bcd29962e5f2c13626b85a877101",
     "b2051c80014f42f08735a7b0cd"},
    {NULL}};

const TestVector* const decryption_test_group_array[] = {
    decryption_test_group_0,
    decryption_test_group_1,
    decryption_test_group_2,
    decryption_test_group_3,
    decryption_test_group_4,
    decryption_test_group_5,
};

const TestVector* const encryption_test_group_array[] = {
    encryption_test_group_0,
    encryption_test_group_1,
    encryption_test_group_2,
    encryption_test_group_3,
    encryption_test_group_4,
    encryption_test_group_5,
};

bool DecodeHexString(const base::StringPiece& hex, std::string* bytes) {
  bytes->clear();
  if (hex.empty())
    return true;
  std::vector<uint8> v;
  if (!base::HexStringToBytes(hex.as_string(), &v))
    return false;
  if (!v.empty())
    bytes->assign(reinterpret_cast<const char*>(&v[0]), v.size());
  return true;
}

class Aes128GcmHelpersTest : public ::testing::Test {
 public:
  enum Mode { DECRYPT, ENCRYPT };

  void SetUp() override { EnsureNSSInit(); }

  bool DecryptOrEncrypt(Mode mode,
                        const base::StringPiece& input,
                        const base::StringPiece& key,
                        const base::StringPiece& nonce,
                        const base::StringPiece& aad,
                        size_t auth_tag_size,
                        std::string* output) {
    DCHECK(output);

    const CK_ATTRIBUTE_TYPE cka_mode =
        mode == DECRYPT ? CKA_DECRYPT : CKA_ENCRYPT;

    SECItem key_item;
    key_item.type = siBuffer;
    key_item.data = const_cast<unsigned char*>(
        reinterpret_cast<const unsigned char*>(key.data()));
    key_item.len = key.size();

    crypto::ScopedPK11Slot slot(PK11_GetInternalSlot());
    DCHECK(slot);

    crypto::ScopedPK11SymKey aead_key(
        PK11_ImportSymKey(slot.get(), CKM_AES_GCM, PK11_OriginUnwrap, cka_mode,
                          &key_item, nullptr));

    CK_GCM_PARAMS gcm_params;
    gcm_params.pIv = const_cast<unsigned char*>(
        reinterpret_cast<const unsigned char*>(nonce.data()));
    gcm_params.ulIvLen = nonce.size();

    gcm_params.pAAD = const_cast<unsigned char*>(
        reinterpret_cast<const unsigned char*>(aad.data()));

    gcm_params.ulAADLen = aad.size();

    gcm_params.ulTagBits = auth_tag_size * 8;

    SECItem param;
    param.type = siBuffer;
    param.data = reinterpret_cast<unsigned char*>(&gcm_params);
    param.len = sizeof(CK_GCM_PARAMS);

    size_t maximum_output_length = input.size();
    if (mode == ENCRYPT)
      maximum_output_length += auth_tag_size;

    unsigned int output_length = 0;
    unsigned char* raw_input = const_cast<unsigned char*>(
        reinterpret_cast<const unsigned char*>(input.data()));
    unsigned char* raw_output = reinterpret_cast<unsigned char*>(
        base::WriteInto(output, maximum_output_length + 1 /* null */));

    PK11Helper_TransformFunction* transform_function =
        mode == DECRYPT ? PK11DecryptHelper : PK11EncryptHelper;

    const SECStatus result = transform_function(
        aead_key.get(), CKM_AES_GCM, &param, raw_output, &output_length,
        maximum_output_length, raw_input, input.size());

    if (result != SECSuccess)
      return false;

    const size_t expected_output_length = mode == DECRYPT
                                              ? input.size() - auth_tag_size
                                              : input.size() + auth_tag_size;

    EXPECT_EQ(expected_output_length, output_length);

    output->resize(expected_output_length);
    return true;
  }

 private:
  // The prototype of PK11_Decrypt and PK11_Encrypt.
  using PK11Helper_TransformFunction = SECStatus(PK11SymKey* symKey,
                                                 CK_MECHANISM_TYPE mechanism,
                                                 SECItem* param,
                                                 unsigned char* out,
                                                 unsigned int* outLen,
                                                 unsigned int maxLen,
                                                 const unsigned char* data,
                                                 unsigned int dataLen);
};

}  // namespace

TEST_F(Aes128GcmHelpersTest, RoundTrip) {
  const std::string message = "Hello, world!";

  const size_t kKeySize = 16;
  const size_t kNonceSize = 16;

  std::string key, nonce;
  RandBytes(base::WriteInto(&key, kKeySize + 1), kKeySize);
  RandBytes(base::WriteInto(&nonce, kNonceSize + 1), kNonceSize);

  // AEAD_AES_128_GCM is defined with a default authentication tag size of 16,
  // but RFC 5282 extends this to authentication tag sizes of 8 and 12 as well.
  size_t auth_tag_size = base::RandInt(2, 4) * 4;

  std::string encrypted;
  ASSERT_TRUE(DecryptOrEncrypt(ENCRYPT, message, key, nonce,
                               base::StringPiece(), auth_tag_size, &encrypted));

  std::string decrypted;
  ASSERT_TRUE(DecryptOrEncrypt(DECRYPT, encrypted, key, nonce,
                               base::StringPiece(), auth_tag_size, &decrypted));

  EXPECT_EQ(message, decrypted);
}

TEST_F(Aes128GcmHelpersTest, DecryptionVectors) {
  for (size_t i = 0; i < arraysize(decryption_test_group_array); i++) {
    SCOPED_TRACE(i);
    const TestVector* test_vectors = decryption_test_group_array[i];
    const TestGroupInfo& test_info = test_group_info[i];

    for (size_t j = 0; test_vectors[j].key != nullptr; j++) {
      // If not present then decryption is expected to fail.
      bool has_output = test_vectors[j].output;

      // Decode the test vector.
      std::string key, iv, input, aad, tag, expected_output;
      ASSERT_TRUE(DecodeHexString(test_vectors[j].key, &key));
      ASSERT_TRUE(DecodeHexString(test_vectors[j].iv, &iv));
      ASSERT_TRUE(DecodeHexString(test_vectors[j].input, &input));
      ASSERT_TRUE(DecodeHexString(test_vectors[j].aad, &aad));
      ASSERT_TRUE(DecodeHexString(test_vectors[j].tag, &tag));
      if (has_output)
        ASSERT_TRUE(DecodeHexString(test_vectors[j].output, &expected_output));

      // The test vector's lengths should look sane. Note that the lengths
      // in |test_info| are in bits.
      EXPECT_EQ(test_info.key_len, key.length() * 8);
      EXPECT_EQ(test_info.iv_len, iv.length() * 8);
      EXPECT_EQ(test_info.input_len, input.length() * 8);
      EXPECT_EQ(test_info.aad_len, aad.length() * 8);
      EXPECT_EQ(test_info.tag_len, tag.length() * 8);
      if (has_output)
        EXPECT_EQ(test_info.input_len, expected_output.length() * 8);

      const std::string ciphertext = input + tag;
      std::string output;

      if (!DecryptOrEncrypt(DECRYPT, ciphertext, key, iv, aad, tag.length(),
                            &output)) {
        EXPECT_FALSE(has_output);
        continue;
      }

      EXPECT_TRUE(has_output);
      EXPECT_EQ(expected_output, output);
    }
  }
}

TEST_F(Aes128GcmHelpersTest, EncryptionVectors) {
  for (size_t i = 0; i < arraysize(encryption_test_group_array); i++) {
    SCOPED_TRACE(i);
    const TestVector* test_vectors = encryption_test_group_array[i];
    const TestGroupInfo& test_info = test_group_info[i];

    for (size_t j = 0; test_vectors[j].key != nullptr; j++) {
      // If not present then decryption is expected to fail.
      bool has_output = test_vectors[j].output;

      // Decode the test vector.
      std::string key, iv, input, aad, tag, expected_output;
      ASSERT_TRUE(DecodeHexString(test_vectors[j].key, &key));
      ASSERT_TRUE(DecodeHexString(test_vectors[j].iv, &iv));
      ASSERT_TRUE(DecodeHexString(test_vectors[j].input, &input));
      ASSERT_TRUE(DecodeHexString(test_vectors[j].aad, &aad));
      ASSERT_TRUE(DecodeHexString(test_vectors[j].tag, &tag));
      if (has_output)
        ASSERT_TRUE(DecodeHexString(test_vectors[j].output, &expected_output));

      // The test vector's lengths should look sane. Note that the lengths
      // in |test_info| are in bits.
      EXPECT_EQ(test_info.key_len, key.length() * 8);
      EXPECT_EQ(test_info.iv_len, iv.length() * 8);
      EXPECT_EQ(test_info.input_len, input.length() * 8);
      EXPECT_EQ(test_info.aad_len, aad.length() * 8);
      EXPECT_EQ(test_info.tag_len, tag.length() * 8);
      if (has_output)
        EXPECT_EQ(test_info.input_len, expected_output.length() * 8);

      std::string output;

      if (!DecryptOrEncrypt(ENCRYPT, input, key, iv, aad, tag.length(),
                            &output)) {
        EXPECT_FALSE(has_output);
        continue;
      }

      const std::string expected_output_with_tag = expected_output + tag;

      EXPECT_TRUE(has_output);
      EXPECT_EQ(expected_output_with_tag, output);
    }
  }
}

}  // namespace crypto
