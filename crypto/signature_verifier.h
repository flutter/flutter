// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef CRYPTO_SIGNATURE_VERIFIER_H_
#define CRYPTO_SIGNATURE_VERIFIER_H_

#include <vector>

#include "build/build_config.h"
#include "base/basictypes.h"
#include "crypto/crypto_export.h"

#if defined(USE_OPENSSL)
typedef struct env_md_st EVP_MD;
typedef struct evp_pkey_ctx_st EVP_PKEY_CTX;
#else
typedef struct HASHContextStr HASHContext;
typedef struct SECKEYPublicKeyStr SECKEYPublicKey;
typedef struct VFYContextStr VFYContext;
#endif

namespace crypto {

// The SignatureVerifier class verifies a signature using a bare public key
// (as opposed to a certificate).
class CRYPTO_EXPORT SignatureVerifier {
 public:
  // The set of supported hash functions. Extend as required.
  enum HashAlgorithm {
    SHA1,
    SHA256,
  };

  SignatureVerifier();
  ~SignatureVerifier();

  // Streaming interface:

  // Initiates a signature verification operation.  This should be followed
  // by one or more VerifyUpdate calls and a VerifyFinal call.
  // NOTE: for RSA-PSS signatures, use VerifyInitRSAPSS instead.
  //
  // The signature algorithm is specified as a DER encoded ASN.1
  // AlgorithmIdentifier structure:
  //   AlgorithmIdentifier  ::=  SEQUENCE  {
  //       algorithm               OBJECT IDENTIFIER,
  //       parameters              ANY DEFINED BY algorithm OPTIONAL  }
  //
  // The signature is encoded according to the signature algorithm, but it
  // must not be further encoded in an ASN.1 BIT STRING.
  // Note: An RSA signature is actually a big integer.  It must be in
  // big-endian byte order.
  //
  // The public key is specified as a DER encoded ASN.1 SubjectPublicKeyInfo
  // structure, which contains not only the public key but also its type
  // (algorithm):
  //   SubjectPublicKeyInfo  ::=  SEQUENCE  {
  //       algorithm            AlgorithmIdentifier,
  //       subjectPublicKey     BIT STRING  }
  bool VerifyInit(const uint8* signature_algorithm,
                  int signature_algorithm_len,
                  const uint8* signature,
                  int signature_len,
                  const uint8* public_key_info,
                  int public_key_info_len);

  // Initiates a RSA-PSS signature verification operation.  This should be
  // followed by one or more VerifyUpdate calls and a VerifyFinal call.
  //
  // The RSA-PSS signature algorithm parameters are specified with the
  // |hash_alg|, |mask_hash_alg|, and |salt_len| arguments.
  //
  // An RSA-PSS signature is a nonnegative integer encoded as a byte string
  // (of the same length as the RSA modulus) in big-endian byte order. It
  // must not be further encoded in an ASN.1 BIT STRING.
  //
  // The public key is specified as a DER encoded ASN.1 SubjectPublicKeyInfo
  // structure, which contains not only the public key but also its type
  // (algorithm):
  //   SubjectPublicKeyInfo  ::=  SEQUENCE  {
  //       algorithm            AlgorithmIdentifier,
  //       subjectPublicKey     BIT STRING  }
  bool VerifyInitRSAPSS(HashAlgorithm hash_alg,
                        HashAlgorithm mask_hash_alg,
                        int salt_len,
                        const uint8* signature,
                        int signature_len,
                        const uint8* public_key_info,
                        int public_key_info_len);

  // Feeds a piece of the data to the signature verifier.
  void VerifyUpdate(const uint8* data_part, int data_part_len);

  // Concludes a signature verification operation.  Returns true if the
  // signature is valid.  Returns false if the signature is invalid or an
  // error occurred.
  bool VerifyFinal();

  // Note: we can provide a one-shot interface if there is interest:
  //   bool Verify(const uint8* data,
  //               int data_len,
  //               const uint8* signature_algorithm,
  //               int signature_algorithm_len,
  //               const uint8* signature,
  //               int signature_len,
  //               const uint8* public_key_info,
  //               int public_key_info_len);

 private:
#if defined(USE_OPENSSL)
  bool CommonInit(const EVP_MD* digest,
                  const uint8* signature,
                  int signature_len,
                  const uint8* public_key_info,
                  int public_key_info_len,
                  EVP_PKEY_CTX** pkey_ctx);
#else
  static SECKEYPublicKey* DecodePublicKeyInfo(const uint8* public_key_info,
                                              int public_key_info_len);
#endif

  void Reset();

  std::vector<uint8> signature_;

#if defined(USE_OPENSSL)
  struct VerifyContext;
  VerifyContext* verify_context_;
#else
  // Used for all signature types except RSA-PSS.
  VFYContext* vfy_context_;

  // Used for RSA-PSS signatures.
  HashAlgorithm hash_alg_;
  HashAlgorithm mask_hash_alg_;
  unsigned int salt_len_;
  SECKEYPublicKey* public_key_;
  HASHContext* hash_context_;
#endif
};

}  // namespace crypto

#endif  // CRYPTO_SIGNATURE_VERIFIER_H_
