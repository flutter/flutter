// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <stdarg.h>

#include <string>

#include "base/base_paths.h"
#include "base/command_line.h"
#include "base/files/file_path.h"
#include "base/logging.h"
#include "base/path_service.h"
#include "base/process/launch.h"
#include "base/strings/string_util.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace {

void TestProcess(const std::string& name,
                 const std::vector<base::CommandLine::StringType>& args) {
  base::FilePath exe_dir;
  ASSERT_TRUE(PathService::Get(base::DIR_EXE, &exe_dir));
  base::FilePath test_binary =
      exe_dir.AppendASCII("boringssl_" + name);
  base::CommandLine cmd(test_binary);

  for (size_t i = 0; i < args.size(); ++i) {
    cmd.AppendArgNative(args[i]);
  }

  std::string output;
  EXPECT_TRUE(base::GetAppOutput(cmd, &output));
  // Account for Windows line endings.
  ReplaceSubstringsAfterOffset(&output, 0, "\r\n", "\n");

  const bool ok = output.size() >= 5 &&
                  memcmp("PASS\n", &output[output.size() - 5], 5) == 0 &&
                  (output.size() == 5 || output[output.size() - 6] == '\n');

  EXPECT_TRUE(ok) << output;
}

void TestSimple(const std::string& name) {
  std::vector<base::CommandLine::StringType> empty;
  TestProcess(name, empty);
}

bool BoringSSLPath(base::FilePath* result) {
  if (!PathService::Get(base::DIR_SOURCE_ROOT, result))
    return false;

  *result = result->Append(FILE_PATH_LITERAL("third_party"));
  *result = result->Append(FILE_PATH_LITERAL("boringssl"));
  *result = result->Append(FILE_PATH_LITERAL("src"));
  return true;
}

bool CryptoCipherTestPath(base::FilePath *result) {
  if (!BoringSSLPath(result))
    return false;

  *result = result->Append(FILE_PATH_LITERAL("crypto"));
  *result = result->Append(FILE_PATH_LITERAL("cipher"));
  *result = result->Append(FILE_PATH_LITERAL("test"));
  return true;
}

}  // anonymous namespace

struct AEADTest {
  const base::CommandLine::CharType *name;
  const base::FilePath::CharType *test_vector_filename;
};

static const AEADTest kAEADTests[] = {
    {FILE_PATH_LITERAL("aes-128-gcm"),
     FILE_PATH_LITERAL("aes_128_gcm_tests.txt")},
    {FILE_PATH_LITERAL("aes-128-key-wrap"),
     FILE_PATH_LITERAL("aes_128_key_wrap_tests.txt")},
    {FILE_PATH_LITERAL("aes-256-gcm"),
     FILE_PATH_LITERAL("aes_256_gcm_tests.txt")},
    {FILE_PATH_LITERAL("aes-256-key-wrap"),
     FILE_PATH_LITERAL("aes_256_key_wrap_tests.txt")},
    {FILE_PATH_LITERAL("chacha20-poly1305"),
     FILE_PATH_LITERAL("chacha20_poly1305_tests.txt")},
    {FILE_PATH_LITERAL("rc4-md5-tls"),
     FILE_PATH_LITERAL("rc4_md5_tls_tests.txt")},
    {FILE_PATH_LITERAL("rc4-sha1-tls"),
     FILE_PATH_LITERAL("rc4_sha1_tls_tests.txt")},
    {FILE_PATH_LITERAL("aes-128-cbc-sha1-tls"),
     FILE_PATH_LITERAL("aes_128_cbc_sha1_tls_tests.txt")},
    {FILE_PATH_LITERAL("aes-128-cbc-sha1-tls-implicit-iv"),
     FILE_PATH_LITERAL("aes_128_cbc_sha1_tls_implicit_iv_tests.txt")},
    {FILE_PATH_LITERAL("aes-128-cbc-sha256-tls"),
     FILE_PATH_LITERAL("aes_128_cbc_sha256_tls_tests.txt")},
    {FILE_PATH_LITERAL("aes-256-cbc-sha1-tls"),
     FILE_PATH_LITERAL("aes_256_cbc_sha1_tls_tests.txt")},
    {FILE_PATH_LITERAL("aes-256-cbc-sha1-tls-implicit-iv"),
     FILE_PATH_LITERAL("aes_256_cbc_sha1_tls_implicit_iv_tests.txt")},
    {FILE_PATH_LITERAL("aes-256-cbc-sha256-tls"),
     FILE_PATH_LITERAL("aes_256_cbc_sha256_tls_tests.txt")},
    {FILE_PATH_LITERAL("aes-256-cbc-sha384-tls"),
     FILE_PATH_LITERAL("aes_256_cbc_sha384_tls_tests.txt")},
    {FILE_PATH_LITERAL("des-ede3-cbc-sha1-tls"),
     FILE_PATH_LITERAL("des_ede3_cbc_sha1_tls_tests.txt")},
    {FILE_PATH_LITERAL("des-ede3-cbc-sha1-tls-implicit-iv"),
     FILE_PATH_LITERAL("des_ede3_cbc_sha1_tls_implicit_iv_tests.txt")},
    {FILE_PATH_LITERAL("rc4-md5-ssl3"),
     FILE_PATH_LITERAL("rc4_md5_ssl3_tests.txt")},
    {FILE_PATH_LITERAL("rc4-sha1-ssl3"),
     FILE_PATH_LITERAL("rc4_sha1_ssl3_tests.txt")},
    {FILE_PATH_LITERAL("aes-128-cbc-sha1-ssl3"),
     FILE_PATH_LITERAL("aes_128_cbc_sha1_ssl3_tests.txt")},
    {FILE_PATH_LITERAL("aes-256-cbc-sha1-ssl3"),
     FILE_PATH_LITERAL("aes_256_cbc_sha1_ssl3_tests.txt")},
    {FILE_PATH_LITERAL("des-ede3-cbc-sha1-ssl3"),
     FILE_PATH_LITERAL("des_ede3_cbc_sha1_ssl3_tests.txt")},
    {FILE_PATH_LITERAL("aes-128-ctr-hmac-sha256"),
     FILE_PATH_LITERAL("aes_128_ctr_hmac_sha256.txt")},
    {FILE_PATH_LITERAL("aes-256-ctr-hmac-sha256"),
     FILE_PATH_LITERAL("aes_256_ctr_hmac_sha256.txt")},
};

TEST(BoringSSL, AEADs) {
  base::FilePath test_vector_dir;
  ASSERT_TRUE(CryptoCipherTestPath(&test_vector_dir));

  for (size_t i = 0; i < arraysize(kAEADTests); i++) {
    const AEADTest& test = kAEADTests[i];
    SCOPED_TRACE(test.name);

    base::FilePath test_vector_file =
        test_vector_dir.Append(test.test_vector_filename);

    std::vector<base::CommandLine::StringType> args;
    args.push_back(test.name);
    args.push_back(test_vector_file.value());

    TestProcess("aead_test", args);
  }
}

TEST(BoringSSL, Base64) {
  TestSimple("base64_test");
}

TEST(BoringSSL, BIO) {
  TestSimple("bio_test");
}

TEST(BoringSSL, BN) {
  TestSimple("bn_test");
}

TEST(BoringSSL, ByteString) {
  TestSimple("bytestring_test");
}

TEST(BoringSSL, ConstantTime) {
  TestSimple("constant_time_test");
}

TEST(BoringSSL, Cipher) {
  base::FilePath data_file;
  ASSERT_TRUE(CryptoCipherTestPath(&data_file));
  data_file = data_file.Append(FILE_PATH_LITERAL("cipher_test.txt"));

  std::vector<base::CommandLine::StringType> args;
  args.push_back(data_file.value());

  TestProcess("cipher_test", args);
}

TEST(BoringSSL, DH) {
  TestSimple("dh_test");
}

TEST(BoringSSL, Digest) {
  TestSimple("digest_test");
}

TEST(BoringSSL, DSA) {
  TestSimple("dsa_test");
}

TEST(BoringSSL, EC) {
  TestSimple("ec_test");
}

TEST(BoringSSL, ECDSA) {
  TestSimple("ecdsa_test");
}

TEST(BoringSSL, ERR) {
  TestSimple("err_test");
}

TEST(BoringSSL, GCM) {
  TestSimple("gcm_test");
}

TEST(BoringSSL, HMAC) {
  TestSimple("hmac_test");
}

TEST(BoringSSL, LH) {
  TestSimple("lhash_test");
}

TEST(BoringSSL, RSA) {
  TestSimple("rsa_test");
}

TEST(BoringSSL, PKCS7) {
  TestSimple("pkcs7_test");
}

TEST(BoringSSL, PKCS12) {
  TestSimple("pkcs12_test");
}

TEST(BoringSSL, ExampleMul) {
  TestSimple("example_mul");
}

TEST(BoringSSL, EVP) {
  TestSimple("evp_test");
}

TEST(BoringSSL, SSL) {
  TestSimple("ssl_test");
}

TEST(BoringSSL, PQueue) {
  TestSimple("pqueue_test");
}

TEST(BoringSSL, HKDF) {
  TestSimple("hkdf_test");                                                     
}

TEST(BoringSSL, PBKDF) {
  TestSimple("pbkdf_test");                                                     
}
