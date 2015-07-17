// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "crypto/signature_verifier.h"

#include "base/numerics/safe_conversions.h"
#include "testing/gtest/include/gtest/gtest.h"

TEST(SignatureVerifierTest, BasicTest) {
  // The input data in this test comes from real certificates.
  //
  // tbs_certificate ("to-be-signed certificate", the part of a certificate
  // that is signed), signature_algorithm, and algorithm come from the
  // certificate of bugs.webkit.org.
  //
  // public_key_info comes from the certificate of the issuer, Go Daddy Secure
  // Certification Authority.
  //
  // The bytes in the array initializers are formatted to expose the DER
  // encoding of the ASN.1 structures.

  // The data that is signed is the following ASN.1 structure:
  //    TBSCertificate  ::=  SEQUENCE  {
  //        ...  -- omitted, not important
  //        }
  const uint8 tbs_certificate[1017] = {
    0x30, 0x82, 0x03, 0xf5,  // a SEQUENCE of length 1013 (0x3f5)
    0xa0, 0x03, 0x02, 0x01, 0x02, 0x02, 0x03, 0x43, 0xdd, 0x63, 0x30, 0x0d,
    0x06, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x05, 0x05,
    0x00, 0x30, 0x81, 0xca, 0x31, 0x0b, 0x30, 0x09, 0x06, 0x03, 0x55, 0x04,
    0x06, 0x13, 0x02, 0x55, 0x53, 0x31, 0x10, 0x30, 0x0e, 0x06, 0x03, 0x55,
    0x04, 0x08, 0x13, 0x07, 0x41, 0x72, 0x69, 0x7a, 0x6f, 0x6e, 0x61, 0x31,
    0x13, 0x30, 0x11, 0x06, 0x03, 0x55, 0x04, 0x07, 0x13, 0x0a, 0x53, 0x63,
    0x6f, 0x74, 0x74, 0x73, 0x64, 0x61, 0x6c, 0x65, 0x31, 0x1a, 0x30, 0x18,
    0x06, 0x03, 0x55, 0x04, 0x0a, 0x13, 0x11, 0x47, 0x6f, 0x44, 0x61, 0x64,
    0x64, 0x79, 0x2e, 0x63, 0x6f, 0x6d, 0x2c, 0x20, 0x49, 0x6e, 0x63, 0x2e,
    0x31, 0x33, 0x30, 0x31, 0x06, 0x03, 0x55, 0x04, 0x0b, 0x13, 0x2a, 0x68,
    0x74, 0x74, 0x70, 0x3a, 0x2f, 0x2f, 0x63, 0x65, 0x72, 0x74, 0x69, 0x66,
    0x69, 0x63, 0x61, 0x74, 0x65, 0x73, 0x2e, 0x67, 0x6f, 0x64, 0x61, 0x64,
    0x64, 0x79, 0x2e, 0x63, 0x6f, 0x6d, 0x2f, 0x72, 0x65, 0x70, 0x6f, 0x73,
    0x69, 0x74, 0x6f, 0x72, 0x79, 0x31, 0x30, 0x30, 0x2e, 0x06, 0x03, 0x55,
    0x04, 0x03, 0x13, 0x27, 0x47, 0x6f, 0x20, 0x44, 0x61, 0x64, 0x64, 0x79,
    0x20, 0x53, 0x65, 0x63, 0x75, 0x72, 0x65, 0x20, 0x43, 0x65, 0x72, 0x74,
    0x69, 0x66, 0x69, 0x63, 0x61, 0x74, 0x69, 0x6f, 0x6e, 0x20, 0x41, 0x75,
    0x74, 0x68, 0x6f, 0x72, 0x69, 0x74, 0x79, 0x31, 0x11, 0x30, 0x0f, 0x06,
    0x03, 0x55, 0x04, 0x05, 0x13, 0x08, 0x30, 0x37, 0x39, 0x36, 0x39, 0x32,
    0x38, 0x37, 0x30, 0x1e, 0x17, 0x0d, 0x30, 0x38, 0x30, 0x33, 0x31, 0x38,
    0x32, 0x33, 0x33, 0x35, 0x31, 0x39, 0x5a, 0x17, 0x0d, 0x31, 0x31, 0x30,
    0x33, 0x31, 0x38, 0x32, 0x33, 0x33, 0x35, 0x31, 0x39, 0x5a, 0x30, 0x79,
    0x31, 0x0b, 0x30, 0x09, 0x06, 0x03, 0x55, 0x04, 0x06, 0x13, 0x02, 0x55,
    0x53, 0x31, 0x13, 0x30, 0x11, 0x06, 0x03, 0x55, 0x04, 0x08, 0x13, 0x0a,
    0x43, 0x61, 0x6c, 0x69, 0x66, 0x6f, 0x72, 0x6e, 0x69, 0x61, 0x31, 0x12,
    0x30, 0x10, 0x06, 0x03, 0x55, 0x04, 0x07, 0x13, 0x09, 0x43, 0x75, 0x70,
    0x65, 0x72, 0x74, 0x69, 0x6e, 0x6f, 0x31, 0x13, 0x30, 0x11, 0x06, 0x03,
    0x55, 0x04, 0x0a, 0x13, 0x0a, 0x41, 0x70, 0x70, 0x6c, 0x65, 0x20, 0x49,
    0x6e, 0x63, 0x2e, 0x31, 0x15, 0x30, 0x13, 0x06, 0x03, 0x55, 0x04, 0x0b,
    0x13, 0x0c, 0x4d, 0x61, 0x63, 0x20, 0x4f, 0x53, 0x20, 0x46, 0x6f, 0x72,
    0x67, 0x65, 0x31, 0x15, 0x30, 0x13, 0x06, 0x03, 0x55, 0x04, 0x03, 0x13,
    0x0c, 0x2a, 0x2e, 0x77, 0x65, 0x62, 0x6b, 0x69, 0x74, 0x2e, 0x6f, 0x72,
    0x67, 0x30, 0x81, 0x9f, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
    0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03, 0x81, 0x8d, 0x00, 0x30,
    0x81, 0x89, 0x02, 0x81, 0x81, 0x00, 0xa7, 0x62, 0x79, 0x41, 0xda, 0x28,
    0xf2, 0xc0, 0x4f, 0xe0, 0x25, 0xaa, 0xa1, 0x2e, 0x3b, 0x30, 0x94, 0xb5,
    0xc9, 0x26, 0x3a, 0x1b, 0xe2, 0xd0, 0xcc, 0xa2, 0x95, 0xe2, 0x91, 0xc0,
    0xf0, 0x40, 0x9e, 0x27, 0x6e, 0xbd, 0x6e, 0xde, 0x7c, 0xb6, 0x30, 0x5c,
    0xb8, 0x9b, 0x01, 0x2f, 0x92, 0x04, 0xa1, 0xef, 0x4a, 0xb1, 0x6c, 0xb1,
    0x7e, 0x8e, 0xcd, 0xa6, 0xf4, 0x40, 0x73, 0x1f, 0x2c, 0x96, 0xad, 0xff,
    0x2a, 0x6d, 0x0e, 0xba, 0x52, 0x84, 0x83, 0xb0, 0x39, 0xee, 0xc9, 0x39,
    0xdc, 0x1e, 0x34, 0xd0, 0xd8, 0x5d, 0x7a, 0x09, 0xac, 0xa9, 0xee, 0xca,
    0x65, 0xf6, 0x85, 0x3a, 0x6b, 0xee, 0xe4, 0x5c, 0x5e, 0xf8, 0xda, 0xd1,
    0xce, 0x88, 0x47, 0xcd, 0x06, 0x21, 0xe0, 0xb9, 0x4b, 0xe4, 0x07, 0xcb,
    0x57, 0xdc, 0xca, 0x99, 0x54, 0xf7, 0x0e, 0xd5, 0x17, 0x95, 0x05, 0x2e,
    0xe9, 0xb1, 0x02, 0x03, 0x01, 0x00, 0x01, 0xa3, 0x82, 0x01, 0xce, 0x30,
    0x82, 0x01, 0xca, 0x30, 0x09, 0x06, 0x03, 0x55, 0x1d, 0x13, 0x04, 0x02,
    0x30, 0x00, 0x30, 0x0b, 0x06, 0x03, 0x55, 0x1d, 0x0f, 0x04, 0x04, 0x03,
    0x02, 0x05, 0xa0, 0x30, 0x1d, 0x06, 0x03, 0x55, 0x1d, 0x25, 0x04, 0x16,
    0x30, 0x14, 0x06, 0x08, 0x2b, 0x06, 0x01, 0x05, 0x05, 0x07, 0x03, 0x01,
    0x06, 0x08, 0x2b, 0x06, 0x01, 0x05, 0x05, 0x07, 0x03, 0x02, 0x30, 0x57,
    0x06, 0x03, 0x55, 0x1d, 0x1f, 0x04, 0x50, 0x30, 0x4e, 0x30, 0x4c, 0xa0,
    0x4a, 0xa0, 0x48, 0x86, 0x46, 0x68, 0x74, 0x74, 0x70, 0x3a, 0x2f, 0x2f,
    0x63, 0x65, 0x72, 0x74, 0x69, 0x66, 0x69, 0x63, 0x61, 0x74, 0x65, 0x73,
    0x2e, 0x67, 0x6f, 0x64, 0x61, 0x64, 0x64, 0x79, 0x2e, 0x63, 0x6f, 0x6d,
    0x2f, 0x72, 0x65, 0x70, 0x6f, 0x73, 0x69, 0x74, 0x6f, 0x72, 0x79, 0x2f,
    0x67, 0x6f, 0x64, 0x61, 0x64, 0x64, 0x79, 0x65, 0x78, 0x74, 0x65, 0x6e,
    0x64, 0x65, 0x64, 0x69, 0x73, 0x73, 0x75, 0x69, 0x6e, 0x67, 0x33, 0x2e,
    0x63, 0x72, 0x6c, 0x30, 0x52, 0x06, 0x03, 0x55, 0x1d, 0x20, 0x04, 0x4b,
    0x30, 0x49, 0x30, 0x47, 0x06, 0x0b, 0x60, 0x86, 0x48, 0x01, 0x86, 0xfd,
    0x6d, 0x01, 0x07, 0x17, 0x02, 0x30, 0x38, 0x30, 0x36, 0x06, 0x08, 0x2b,
    0x06, 0x01, 0x05, 0x05, 0x07, 0x02, 0x01, 0x16, 0x2a, 0x68, 0x74, 0x74,
    0x70, 0x3a, 0x2f, 0x2f, 0x63, 0x65, 0x72, 0x74, 0x69, 0x66, 0x69, 0x63,
    0x61, 0x74, 0x65, 0x73, 0x2e, 0x67, 0x6f, 0x64, 0x61, 0x64, 0x64, 0x79,
    0x2e, 0x63, 0x6f, 0x6d, 0x2f, 0x72, 0x65, 0x70, 0x6f, 0x73, 0x69, 0x74,
    0x6f, 0x72, 0x79, 0x30, 0x7f, 0x06, 0x08, 0x2b, 0x06, 0x01, 0x05, 0x05,
    0x07, 0x01, 0x01, 0x04, 0x73, 0x30, 0x71, 0x30, 0x23, 0x06, 0x08, 0x2b,
    0x06, 0x01, 0x05, 0x05, 0x07, 0x30, 0x01, 0x86, 0x17, 0x68, 0x74, 0x74,
    0x70, 0x3a, 0x2f, 0x2f, 0x6f, 0x63, 0x73, 0x70, 0x2e, 0x67, 0x6f, 0x64,
    0x61, 0x64, 0x64, 0x79, 0x2e, 0x63, 0x6f, 0x6d, 0x30, 0x4a, 0x06, 0x08,
    0x2b, 0x06, 0x01, 0x05, 0x05, 0x07, 0x30, 0x02, 0x86, 0x3e, 0x68, 0x74,
    0x74, 0x70, 0x3a, 0x2f, 0x2f, 0x63, 0x65, 0x72, 0x74, 0x69, 0x66, 0x69,
    0x63, 0x61, 0x74, 0x65, 0x73, 0x2e, 0x67, 0x6f, 0x64, 0x61, 0x64, 0x64,
    0x79, 0x2e, 0x63, 0x6f, 0x6d, 0x2f, 0x72, 0x65, 0x70, 0x6f, 0x73, 0x69,
    0x74, 0x6f, 0x72, 0x79, 0x2f, 0x67, 0x64, 0x5f, 0x69, 0x6e, 0x74, 0x65,
    0x72, 0x6d, 0x65, 0x64, 0x69, 0x61, 0x74, 0x65, 0x2e, 0x63, 0x72, 0x74,
    0x30, 0x1d, 0x06, 0x03, 0x55, 0x1d, 0x0e, 0x04, 0x16, 0x04, 0x14, 0x48,
    0xdf, 0x60, 0x32, 0xcc, 0x89, 0x01, 0xb6, 0xdc, 0x2f, 0xe3, 0x73, 0xb5,
    0x9c, 0x16, 0x58, 0x32, 0x68, 0xa9, 0xc3, 0x30, 0x1f, 0x06, 0x03, 0x55,
    0x1d, 0x23, 0x04, 0x18, 0x30, 0x16, 0x80, 0x14, 0xfd, 0xac, 0x61, 0x32,
    0x93, 0x6c, 0x45, 0xd6, 0xe2, 0xee, 0x85, 0x5f, 0x9a, 0xba, 0xe7, 0x76,
    0x99, 0x68, 0xcc, 0xe7, 0x30, 0x23, 0x06, 0x03, 0x55, 0x1d, 0x11, 0x04,
    0x1c, 0x30, 0x1a, 0x82, 0x0c, 0x2a, 0x2e, 0x77, 0x65, 0x62, 0x6b, 0x69,
    0x74, 0x2e, 0x6f, 0x72, 0x67, 0x82, 0x0a, 0x77, 0x65, 0x62, 0x6b, 0x69,
    0x74, 0x2e, 0x6f, 0x72, 0x67
  };

  // The signature algorithm is specified as the following ASN.1 structure:
  //    AlgorithmIdentifier  ::=  SEQUENCE  {
  //        algorithm               OBJECT IDENTIFIER,
  //        parameters              ANY DEFINED BY algorithm OPTIONAL  }
  //
  const uint8 signature_algorithm[15] = {
    0x30, 0x0d,  // a SEQUENCE of length 13 (0xd)
      0x06, 0x09,  // an OBJECT IDENTIFIER of length 9
        // 1.2.840.113549.1.1.5 - sha1WithRSAEncryption
        0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x05,
      0x05, 0x00,  // a NULL of length 0
  };

  // RSA signature, a big integer in the big-endian byte order.
  const uint8 signature[256] = {
    0x1e, 0x6a, 0xe7, 0xe0, 0x4f, 0xe7, 0x4d, 0xd0, 0x69, 0x7c, 0xf8, 0x8f,
    0x99, 0xb4, 0x18, 0x95, 0x36, 0x24, 0x0f, 0x0e, 0xa3, 0xea, 0x34, 0x37,
    0xf4, 0x7d, 0xd5, 0x92, 0x35, 0x53, 0x72, 0x76, 0x3f, 0x69, 0xf0, 0x82,
    0x56, 0xe3, 0x94, 0x7a, 0x1d, 0x1a, 0x81, 0xaf, 0x9f, 0xc7, 0x43, 0x01,
    0x64, 0xd3, 0x7c, 0x0d, 0xc8, 0x11, 0x4e, 0x4a, 0xe6, 0x1a, 0xc3, 0x01,
    0x74, 0xe8, 0x35, 0x87, 0x5c, 0x61, 0xaa, 0x8a, 0x46, 0x06, 0xbe, 0x98,
    0x95, 0x24, 0x9e, 0x01, 0xe3, 0xe6, 0xa0, 0x98, 0xee, 0x36, 0x44, 0x56,
    0x8d, 0x23, 0x9c, 0x65, 0xea, 0x55, 0x6a, 0xdf, 0x66, 0xee, 0x45, 0xe8,
    0xa0, 0xe9, 0x7d, 0x9a, 0xba, 0x94, 0xc5, 0xc8, 0xc4, 0x4b, 0x98, 0xff,
    0x9a, 0x01, 0x31, 0x6d, 0xf9, 0x2b, 0x58, 0xe7, 0xe7, 0x2a, 0xc5, 0x4d,
    0xbb, 0xbb, 0xcd, 0x0d, 0x70, 0xe1, 0xad, 0x03, 0xf5, 0xfe, 0xf4, 0x84,
    0x71, 0x08, 0xd2, 0xbc, 0x04, 0x7b, 0x26, 0x1c, 0xa8, 0x0f, 0x9c, 0xd8,
    0x12, 0x6a, 0x6f, 0x2b, 0x67, 0xa1, 0x03, 0x80, 0x9a, 0x11, 0x0b, 0xe9,
    0xe0, 0xb5, 0xb3, 0xb8, 0x19, 0x4e, 0x0c, 0xa4, 0xd9, 0x2b, 0x3b, 0xc2,
    0xca, 0x20, 0xd3, 0x0c, 0xa4, 0xff, 0x93, 0x13, 0x1f, 0xfc, 0xba, 0x94,
    0x93, 0x8c, 0x64, 0x15, 0x2e, 0x28, 0xa9, 0x55, 0x8c, 0x2c, 0x48, 0xd3,
    0xd3, 0xc1, 0x50, 0x69, 0x19, 0xe8, 0x34, 0xd3, 0xf1, 0x04, 0x9f, 0x0a,
    0x7a, 0x21, 0x87, 0xbf, 0xb9, 0x59, 0x37, 0x2e, 0xf4, 0x71, 0xa5, 0x3e,
    0xbe, 0xcd, 0x70, 0x83, 0x18, 0xf8, 0x8a, 0x72, 0x85, 0x45, 0x1f, 0x08,
    0x01, 0x6f, 0x37, 0xf5, 0x2b, 0x7b, 0xea, 0xb9, 0x8b, 0xa3, 0xcc, 0xfd,
    0x35, 0x52, 0xdd, 0x66, 0xde, 0x4f, 0x30, 0xc5, 0x73, 0x81, 0xb6, 0xe8,
    0x3c, 0xd8, 0x48, 0x8a
  };

  // The public key is specified as the following ASN.1 structure:
  //   SubjectPublicKeyInfo  ::=  SEQUENCE  {
  //       algorithm            AlgorithmIdentifier,
  //       subjectPublicKey     BIT STRING  }
  const uint8 public_key_info[294] = {
    0x30, 0x82, 0x01, 0x22,  // a SEQUENCE of length 290 (0x122)
      // algorithm
      0x30, 0x0d,  // a SEQUENCE of length 13
        0x06, 0x09,  // an OBJECT IDENTIFIER of length 9
          0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x01,
        0x05, 0x00,  // a NULL of length 0
      // subjectPublicKey
      0x03, 0x82, 0x01, 0x0f,  // a BIT STRING of length 271 (0x10f)
        0x00,  // number of unused bits
        0x30, 0x82, 0x01, 0x0a,  // a SEQUENCE of length 266 (0x10a)
          // modulus
          0x02, 0x82, 0x01, 0x01,  // an INTEGER of length 257 (0x101)
            0x00, 0xc4, 0x2d, 0xd5, 0x15, 0x8c, 0x9c, 0x26, 0x4c, 0xec,
            0x32, 0x35, 0xeb, 0x5f, 0xb8, 0x59, 0x01, 0x5a, 0xa6, 0x61,
            0x81, 0x59, 0x3b, 0x70, 0x63, 0xab, 0xe3, 0xdc, 0x3d, 0xc7,
            0x2a, 0xb8, 0xc9, 0x33, 0xd3, 0x79, 0xe4, 0x3a, 0xed, 0x3c,
            0x30, 0x23, 0x84, 0x8e, 0xb3, 0x30, 0x14, 0xb6, 0xb2, 0x87,
            0xc3, 0x3d, 0x95, 0x54, 0x04, 0x9e, 0xdf, 0x99, 0xdd, 0x0b,
            0x25, 0x1e, 0x21, 0xde, 0x65, 0x29, 0x7e, 0x35, 0xa8, 0xa9,
            0x54, 0xeb, 0xf6, 0xf7, 0x32, 0x39, 0xd4, 0x26, 0x55, 0x95,
            0xad, 0xef, 0xfb, 0xfe, 0x58, 0x86, 0xd7, 0x9e, 0xf4, 0x00,
            0x8d, 0x8c, 0x2a, 0x0c, 0xbd, 0x42, 0x04, 0xce, 0xa7, 0x3f,
            0x04, 0xf6, 0xee, 0x80, 0xf2, 0xaa, 0xef, 0x52, 0xa1, 0x69,
            0x66, 0xda, 0xbe, 0x1a, 0xad, 0x5d, 0xda, 0x2c, 0x66, 0xea,
            0x1a, 0x6b, 0xbb, 0xe5, 0x1a, 0x51, 0x4a, 0x00, 0x2f, 0x48,
            0xc7, 0x98, 0x75, 0xd8, 0xb9, 0x29, 0xc8, 0xee, 0xf8, 0x66,
            0x6d, 0x0a, 0x9c, 0xb3, 0xf3, 0xfc, 0x78, 0x7c, 0xa2, 0xf8,
            0xa3, 0xf2, 0xb5, 0xc3, 0xf3, 0xb9, 0x7a, 0x91, 0xc1, 0xa7,
            0xe6, 0x25, 0x2e, 0x9c, 0xa8, 0xed, 0x12, 0x65, 0x6e, 0x6a,
            0xf6, 0x12, 0x44, 0x53, 0x70, 0x30, 0x95, 0xc3, 0x9c, 0x2b,
            0x58, 0x2b, 0x3d, 0x08, 0x74, 0x4a, 0xf2, 0xbe, 0x51, 0xb0,
            0xbf, 0x87, 0xd0, 0x4c, 0x27, 0x58, 0x6b, 0xb5, 0x35, 0xc5,
            0x9d, 0xaf, 0x17, 0x31, 0xf8, 0x0b, 0x8f, 0xee, 0xad, 0x81,
            0x36, 0x05, 0x89, 0x08, 0x98, 0xcf, 0x3a, 0xaf, 0x25, 0x87,
            0xc0, 0x49, 0xea, 0xa7, 0xfd, 0x67, 0xf7, 0x45, 0x8e, 0x97,
            0xcc, 0x14, 0x39, 0xe2, 0x36, 0x85, 0xb5, 0x7e, 0x1a, 0x37,
            0xfd, 0x16, 0xf6, 0x71, 0x11, 0x9a, 0x74, 0x30, 0x16, 0xfe,
            0x13, 0x94, 0xa3, 0x3f, 0x84, 0x0d, 0x4f,
          // public exponent
          0x02, 0x03,  // an INTEGER of length 3
             0x01, 0x00, 0x01
  };

  // We use the signature verifier to perform four signature verification
  // tests.
  crypto::SignatureVerifier verifier;
  bool ok;

  // Test 1: feed all of the data to the verifier at once (a single
  // VerifyUpdate call).
  ok = verifier.VerifyInit(signature_algorithm,
                           sizeof(signature_algorithm),
                           signature, sizeof(signature),
                           public_key_info, sizeof(public_key_info));
  EXPECT_TRUE(ok);
  verifier.VerifyUpdate(tbs_certificate, sizeof(tbs_certificate));
  ok = verifier.VerifyFinal();
  EXPECT_TRUE(ok);

  // Test 2: feed the data to the verifier in three parts (three VerifyUpdate
  // calls).
  ok = verifier.VerifyInit(signature_algorithm,
                           sizeof(signature_algorithm),
                           signature, sizeof(signature),
                           public_key_info, sizeof(public_key_info));
  EXPECT_TRUE(ok);
  verifier.VerifyUpdate(tbs_certificate,       256);
  verifier.VerifyUpdate(tbs_certificate + 256, 256);
  verifier.VerifyUpdate(tbs_certificate + 512, sizeof(tbs_certificate) - 512);
  ok = verifier.VerifyFinal();
  EXPECT_TRUE(ok);

  // Test 3: verify the signature with incorrect data.
  uint8 bad_tbs_certificate[sizeof(tbs_certificate)];
  memcpy(bad_tbs_certificate, tbs_certificate, sizeof(tbs_certificate));
  bad_tbs_certificate[10] += 1;  // Corrupt one byte of the data.
  ok = verifier.VerifyInit(signature_algorithm,
                           sizeof(signature_algorithm),
                           signature, sizeof(signature),
                           public_key_info, sizeof(public_key_info));
  EXPECT_TRUE(ok);
  verifier.VerifyUpdate(bad_tbs_certificate, sizeof(bad_tbs_certificate));
  ok = verifier.VerifyFinal();
  EXPECT_FALSE(ok);

  // Test 4: verify a bad signature.
  uint8 bad_signature[sizeof(signature)];
  memcpy(bad_signature, signature, sizeof(signature));
  bad_signature[10] += 1;  // Corrupt one byte of the signature.
  ok = verifier.VerifyInit(signature_algorithm,
                           sizeof(signature_algorithm),
                           bad_signature, sizeof(bad_signature),
                           public_key_info, sizeof(public_key_info));

  // A crypto library (e.g., NSS) may detect that the signature is corrupted
  // and cause VerifyInit to return false, so it is fine for 'ok' to be false.
  if (ok) {
    verifier.VerifyUpdate(tbs_certificate, sizeof(tbs_certificate));
    ok = verifier.VerifyFinal();
    EXPECT_FALSE(ok);
  }

  // Test 5: import an invalid key.
  uint8_t bad_public_key_info[sizeof(public_key_info)];
  memcpy(bad_public_key_info, public_key_info, sizeof(public_key_info));
  bad_public_key_info[0] += 1;  // Corrupt part of the SPKI syntax.
  ok = verifier.VerifyInit(signature_algorithm,
                           sizeof(signature_algorithm),
                           signature, sizeof(signature),
                           bad_public_key_info, sizeof(bad_public_key_info));
  EXPECT_FALSE(ok);

  // Test 6: import a key with extra data.
  uint8_t long_public_key_info[sizeof(public_key_info) + 5];
  memset(long_public_key_info, 0, sizeof(long_public_key_info));
  memcpy(long_public_key_info, public_key_info, sizeof(public_key_info));
  ok = verifier.VerifyInit(signature_algorithm,
                           sizeof(signature_algorithm),
                           signature, sizeof(signature),
                           long_public_key_info, sizeof(long_public_key_info));
  EXPECT_FALSE(ok);
}

//////////////////////////////////////////////////////////////////////
//
// RSA-PSS signature verification known answer test
//
//////////////////////////////////////////////////////////////////////

// The following RSA-PSS signature test vectors come from the pss-vect.txt
// file downloaded from
// ftp://ftp.rsasecurity.com/pub/pkcs/pkcs-1/pkcs-1v2-1-vec.zip.
//
// For each key, 6 random messages of length between 1 and 256 octets have
// been RSASSA-PSS signed.
//
// Hash function: SHA-1
// Mask generation function: MGF1 with SHA-1
// Salt length: 20 octets

// Example 1: A 1024-bit RSA Key Pair"

// RSA modulus n:
static const char rsa_modulus_n_1[] =
  "a5 6e 4a 0e 70 10 17 58 9a 51 87 dc 7e a8 41 d1 "
  "56 f2 ec 0e 36 ad 52 a4 4d fe b1 e6 1f 7a d9 91 "
  "d8 c5 10 56 ff ed b1 62 b4 c0 f2 83 a1 2a 88 a3 "
  "94 df f5 26 ab 72 91 cb b3 07 ce ab fc e0 b1 df "
  "d5 cd 95 08 09 6d 5b 2b 8b 6d f5 d6 71 ef 63 77 "
  "c0 92 1c b2 3c 27 0a 70 e2 59 8e 6f f8 9d 19 f1 "
  "05 ac c2 d3 f0 cb 35 f2 92 80 e1 38 6b 6f 64 c4 "
  "ef 22 e1 e1 f2 0d 0c e8 cf fb 22 49 bd 9a 21 37 ";
// RSA public exponent e: "
static const char rsa_public_exponent_e_1[] =
  "01 00 01 ";

// RSASSA-PSS Signature Example 1.1
// Message to be signed:
static const char message_1_1[] =
  "cd c8 7d a2 23 d7 86 df 3b 45 e0 bb bc 72 13 26 "
  "d1 ee 2a f8 06 cc 31 54 75 cc 6f 0d 9c 66 e1 b6 "
  "23 71 d4 5c e2 39 2e 1a c9 28 44 c3 10 10 2f 15 "
  "6a 0d 8d 52 c1 f4 c4 0b a3 aa 65 09 57 86 cb 76 "
  "97 57 a6 56 3b a9 58 fe d0 bc c9 84 e8 b5 17 a3 "
  "d5 f5 15 b2 3b 8a 41 e7 4a a8 67 69 3f 90 df b0 "
  "61 a6 e8 6d fa ae e6 44 72 c0 0e 5f 20 94 57 29 "
  "cb eb e7 7f 06 ce 78 e0 8f 40 98 fb a4 1f 9d 61 "
  "93 c0 31 7e 8b 60 d4 b6 08 4a cb 42 d2 9e 38 08 "
  "a3 bc 37 2d 85 e3 31 17 0f cb f7 cc 72 d0 b7 1c "
  "29 66 48 b3 a4 d1 0f 41 62 95 d0 80 7a a6 25 ca "
  "b2 74 4f d9 ea 8f d2 23 c4 25 37 02 98 28 bd 16 "
  "be 02 54 6f 13 0f d2 e3 3b 93 6d 26 76 e0 8a ed "
  "1b 73 31 8b 75 0a 01 67 d0 ";
// Salt:
static const char salt_1_1[] =
  "de e9 59 c7 e0 64 11 36 14 20 ff 80 18 5e d5 7f "
  "3e 67 76 af ";
// Signature:
static const char signature_1_1[] =
  "90 74 30 8f b5 98 e9 70 1b 22 94 38 8e 52 f9 71 "
  "fa ac 2b 60 a5 14 5a f1 85 df 52 87 b5 ed 28 87 "
  "e5 7c e7 fd 44 dc 86 34 e4 07 c8 e0 e4 36 0b c2 "
  "26 f3 ec 22 7f 9d 9e 54 63 8e 8d 31 f5 05 12 15 "
  "df 6e bb 9c 2f 95 79 aa 77 59 8a 38 f9 14 b5 b9 "
  "c1 bd 83 c4 e2 f9 f3 82 a0 d0 aa 35 42 ff ee 65 "
  "98 4a 60 1b c6 9e b2 8d eb 27 dc a1 2c 82 c2 d4 "
  "c3 f6 6c d5 00 f1 ff 2b 99 4d 8a 4e 30 cb b3 3c ";

// RSASSA-PSS Signature Example 1.2
// Message to be signed:
static const char message_1_2[] =
  "85 13 84 cd fe 81 9c 22 ed 6c 4c cb 30 da eb 5c "
  "f0 59 bc 8e 11 66 b7 e3 53 0c 4c 23 3e 2b 5f 8f "
  "71 a1 cc a5 82 d4 3e cc 72 b1 bc a1 6d fc 70 13 "
  "22 6b 9e ";
// Salt:
static const char salt_1_2[] =
  "ef 28 69 fa 40 c3 46 cb 18 3d ab 3d 7b ff c9 8f "
  "d5 6d f4 2d ";
// Signature:
static const char signature_1_2[] =
  "3e f7 f4 6e 83 1b f9 2b 32 27 41 42 a5 85 ff ce "
  "fb dc a7 b3 2a e9 0d 10 fb 0f 0c 72 99 84 f0 4e "
  "f2 9a 9d f0 78 07 75 ce 43 73 9b 97 83 83 90 db "
  "0a 55 05 e6 3d e9 27 02 8d 9d 29 b2 19 ca 2c 45 "
  "17 83 25 58 a5 5d 69 4a 6d 25 b9 da b6 60 03 c4 "
  "cc cd 90 78 02 19 3b e5 17 0d 26 14 7d 37 b9 35 "
  "90 24 1b e5 1c 25 05 5f 47 ef 62 75 2c fb e2 14 "
  "18 fa fe 98 c2 2c 4d 4d 47 72 4f db 56 69 e8 43 ";

// RSASSA-PSS Signature Example 1.3
// Message to be signed:
static const char message_1_3[] =
  "a4 b1 59 94 17 61 c4 0c 6a 82 f2 b8 0d 1b 94 f5 "
  "aa 26 54 fd 17 e1 2d 58 88 64 67 9b 54 cd 04 ef "
  "8b d0 30 12 be 8d c3 7f 4b 83 af 79 63 fa ff 0d "
  "fa 22 54 77 43 7c 48 01 7f f2 be 81 91 cf 39 55 "
  "fc 07 35 6e ab 3f 32 2f 7f 62 0e 21 d2 54 e5 db "
  "43 24 27 9f e0 67 e0 91 0e 2e 81 ca 2c ab 31 c7 "
  "45 e6 7a 54 05 8e b5 0d 99 3c db 9e d0 b4 d0 29 "
  "c0 6d 21 a9 4c a6 61 c3 ce 27 fa e1 d6 cb 20 f4 "
  "56 4d 66 ce 47 67 58 3d 0e 5f 06 02 15 b5 90 17 "
  "be 85 ea 84 89 39 12 7b d8 c9 c4 d4 7b 51 05 6c "
  "03 1c f3 36 f1 7c 99 80 f3 b8 f5 b9 b6 87 8e 8b "
  "79 7a a4 3b 88 26 84 33 3e 17 89 3f e9 ca a6 aa "
  "29 9f 7e d1 a1 8e e2 c5 48 64 b7 b2 b9 9b 72 61 "
  "8f b0 25 74 d1 39 ef 50 f0 19 c9 ee f4 16 97 13 "
  "38 e7 d4 70 ";
// Salt:
static const char salt_1_3[] =
  "71 0b 9c 47 47 d8 00 d4 de 87 f1 2a fd ce 6d f1 "
  "81 07 cc 77 ";
// Signature:
static const char signature_1_3[] =
  "66 60 26 fb a7 1b d3 e7 cf 13 15 7c c2 c5 1a 8e "
  "4a a6 84 af 97 78 f9 18 49 f3 43 35 d1 41 c0 01 "
  "54 c4 19 76 21 f9 62 4a 67 5b 5a bc 22 ee 7d 5b "
  "aa ff aa e1 c9 ba ca 2c c3 73 b3 f3 3e 78 e6 14 "
  "3c 39 5a 91 aa 7f ac a6 64 eb 73 3a fd 14 d8 82 "
  "72 59 d9 9a 75 50 fa ca 50 1e f2 b0 4e 33 c2 3a "
  "a5 1f 4b 9e 82 82 ef db 72 8c c0 ab 09 40 5a 91 "
  "60 7c 63 69 96 1b c8 27 0d 2d 4f 39 fc e6 12 b1 ";

// RSASSA-PSS Signature Example 1.4
// Message to be signed:
static const char message_1_4[] =
  "bc 65 67 47 fa 9e af b3 f0 ";
// Salt:
static const char salt_1_4[] =
  "05 6f 00 98 5d e1 4d 8e f5 ce a9 e8 2f 8c 27 be "
  "f7 20 33 5e ";
// Signature:
static const char signature_1_4[] =
  "46 09 79 3b 23 e9 d0 93 62 dc 21 bb 47 da 0b 4f "
  "3a 76 22 64 9a 47 d4 64 01 9b 9a ea fe 53 35 9c "
  "17 8c 91 cd 58 ba 6b cb 78 be 03 46 a7 bc 63 7f "
  "4b 87 3d 4b ab 38 ee 66 1f 19 96 34 c5 47 a1 ad "
  "84 42 e0 3d a0 15 b1 36 e5 43 f7 ab 07 c0 c1 3e "
  "42 25 b8 de 8c ce 25 d4 f6 eb 84 00 f8 1f 7e 18 "
  "33 b7 ee 6e 33 4d 37 09 64 ca 79 fd b8 72 b4 d7 "
  "52 23 b5 ee b0 81 01 59 1f b5 32 d1 55 a6 de 87 ";

// RSASSA-PSS Signature Example 1.5
// Message to be signed:
static const char message_1_5[] =
  "b4 55 81 54 7e 54 27 77 0c 76 8e 8b 82 b7 55 64 "
  "e0 ea 4e 9c 32 59 4d 6b ff 70 65 44 de 0a 87 76 "
  "c7 a8 0b 45 76 55 0e ee 1b 2a ca bc 7e 8b 7d 3e "
  "f7 bb 5b 03 e4 62 c1 10 47 ea dd 00 62 9a e5 75 "
  "48 0a c1 47 0f e0 46 f1 3a 2b f5 af 17 92 1d c4 "
  "b0 aa 8b 02 be e6 33 49 11 65 1d 7f 85 25 d1 0f "
  "32 b5 1d 33 be 52 0d 3d df 5a 70 99 55 a3 df e7 "
  "82 83 b9 e0 ab 54 04 6d 15 0c 17 7f 03 7f dc cc "
  "5b e4 ea 5f 68 b5 e5 a3 8c 9d 7e dc cc c4 97 5f "
  "45 5a 69 09 b4 ";
// Salt:
static const char salt_1_5[] =
  "80 e7 0f f8 6a 08 de 3e c6 09 72 b3 9b 4f bf dc "
  "ea 67 ae 8e ";
// Signature:
static const char signature_1_5[] =
  "1d 2a ad 22 1c a4 d3 1d df 13 50 92 39 01 93 98 "
  "e3 d1 4b 32 dc 34 dc 5a f4 ae ae a3 c0 95 af 73 "
  "47 9c f0 a4 5e 56 29 63 5a 53 a0 18 37 76 15 b1 "
  "6c b9 b1 3b 3e 09 d6 71 eb 71 e3 87 b8 54 5c 59 "
  "60 da 5a 64 77 6e 76 8e 82 b2 c9 35 83 bf 10 4c "
  "3f db 23 51 2b 7b 4e 89 f6 33 dd 00 63 a5 30 db "
  "45 24 b0 1c 3f 38 4c 09 31 0e 31 5a 79 dc d3 d6 "
  "84 02 2a 7f 31 c8 65 a6 64 e3 16 97 8b 75 9f ad ";

// RSASSA-PSS Signature Example 1.6
// Message to be signed:
static const char message_1_6[] =
  "10 aa e9 a0 ab 0b 59 5d 08 41 20 7b 70 0d 48 d7 "
  "5f ae dd e3 b7 75 cd 6b 4c c8 8a e0 6e 46 94 ec "
  "74 ba 18 f8 52 0d 4f 5e a6 9c bb e7 cc 2b eb a4 "
  "3e fd c1 02 15 ac 4e b3 2d c3 02 a1 f5 3d c6 c4 "
  "35 22 67 e7 93 6c fe bf 7c 8d 67 03 57 84 a3 90 "
  "9f a8 59 c7 b7 b5 9b 8e 39 c5 c2 34 9f 18 86 b7 "
  "05 a3 02 67 d4 02 f7 48 6a b4 f5 8c ad 5d 69 ad "
  "b1 7a b8 cd 0c e1 ca f5 02 5a f4 ae 24 b1 fb 87 "
  "94 c6 07 0c c0 9a 51 e2 f9 91 13 11 e3 87 7d 00 "
  "44 c7 1c 57 a9 93 39 50 08 80 6b 72 3a c3 83 73 "
  "d3 95 48 18 18 52 8c 1e 70 53 73 92 82 05 35 29 "
  "51 0e 93 5c d0 fa 77 b8 fa 53 cc 2d 47 4b d4 fb "
  "3c c5 c6 72 d6 ff dc 90 a0 0f 98 48 71 2c 4b cf "
  "e4 6c 60 57 36 59 b1 1e 64 57 e8 61 f0 f6 04 b6 "
  "13 8d 14 4f 8c e4 e2 da 73 ";
// Salt:
static const char salt_1_6[] =
  "a8 ab 69 dd 80 1f 00 74 c2 a1 fc 60 64 98 36 c6 "
  "16 d9 96 81 ";
// Signature:
static const char signature_1_6[] =
  "2a 34 f6 12 5e 1f 6b 0b f9 71 e8 4f bd 41 c6 32 "
  "be 8f 2c 2a ce 7d e8 b6 92 6e 31 ff 93 e9 af 98 "
  "7f bc 06 e5 1e 9b e1 4f 51 98 f9 1f 3f 95 3b d6 "
  "7d a6 0a 9d f5 97 64 c3 dc 0f e0 8e 1c be f0 b7 "
  "5f 86 8d 10 ad 3f ba 74 9f ef 59 fb 6d ac 46 a0 "
  "d6 e5 04 36 93 31 58 6f 58 e4 62 8f 39 aa 27 89 "
  "82 54 3b c0 ee b5 37 dc 61 95 80 19 b3 94 fb 27 "
  "3f 21 58 58 a0 a0 1a c4 d6 50 b9 55 c6 7f 4c 58 ";

// Example 9: A 1536-bit RSA Key Pair

// RSA modulus n:
static const char rsa_modulus_n_9[] =
  "e6 bd 69 2a c9 66 45 79 04 03 fd d0 f5 be b8 b9 "
  "bf 92 ed 10 00 7f c3 65 04 64 19 dd 06 c0 5c 5b "
  "5b 2f 48 ec f9 89 e4 ce 26 91 09 97 9c bb 40 b4 "
  "a0 ad 24 d2 24 83 d1 ee 31 5a d4 cc b1 53 42 68 "
  "35 26 91 c5 24 f6 dd 8e 6c 29 d2 24 cf 24 69 73 "
  "ae c8 6c 5b f6 b1 40 1a 85 0d 1b 9a d1 bb 8c bc "
  "ec 47 b0 6f 0f 8c 7f 45 d3 fc 8f 31 92 99 c5 43 "
  "3d db c2 b3 05 3b 47 de d2 ec d4 a4 ca ef d6 14 "
  "83 3d c8 bb 62 2f 31 7e d0 76 b8 05 7f e8 de 3f "
  "84 48 0a d5 e8 3e 4a 61 90 4a 4f 24 8f b3 97 02 "
  "73 57 e1 d3 0e 46 31 39 81 5c 6f d4 fd 5a c5 b8 "
  "17 2a 45 23 0e cb 63 18 a0 4f 14 55 d8 4e 5a 8b ";
// RSA public exponent e:
static const char rsa_public_exponent_e_9[] =
  "01 00 01 ";

// RSASSA-PSS Signature Example 9.1
// Message to be signed:
static const char message_9_1[] =
  "a8 8e 26 58 55 e9 d7 ca 36 c6 87 95 f0 b3 1b 59 "
  "1c d6 58 7c 71 d0 60 a0 b3 f7 f3 ea ef 43 79 59 "
  "22 02 8b c2 b6 ad 46 7c fc 2d 7f 65 9c 53 85 aa "
  "70 ba 36 72 cd de 4c fe 49 70 cc 79 04 60 1b 27 "
  "88 72 bf 51 32 1c 4a 97 2f 3c 95 57 0f 34 45 d4 "
  "f5 79 80 e0 f2 0d f5 48 46 e6 a5 2c 66 8f 12 88 "
  "c0 3f 95 00 6e a3 2f 56 2d 40 d5 2a f9 fe b3 2f "
  "0f a0 6d b6 5b 58 8a 23 7b 34 e5 92 d5 5c f9 79 "
  "f9 03 a6 42 ef 64 d2 ed 54 2a a8 c7 7d c1 dd 76 "
  "2f 45 a5 93 03 ed 75 e5 41 ca 27 1e 2b 60 ca 70 "
  "9e 44 fa 06 61 13 1e 8d 5d 41 63 fd 8d 39 85 66 "
  "ce 26 de 87 30 e7 2f 9c ca 73 76 41 c2 44 15 94 "
  "20 63 70 28 df 0a 18 07 9d 62 08 ea 8b 47 11 a2 "
  "c7 50 f5 ";
// Salt:
static const char salt_9_1[] =
  "c0 a4 25 31 3d f8 d7 56 4b d2 43 4d 31 15 23 d5 "
  "25 7e ed 80 ";
// Signature:
static const char signature_9_1[] =
  "58 61 07 22 6c 3c e0 13 a7 c8 f0 4d 1a 6a 29 59 "
  "bb 4b 8e 20 5b a4 3a 27 b5 0f 12 41 11 bc 35 ef "
  "58 9b 03 9f 59 32 18 7c b6 96 d7 d9 a3 2c 0c 38 "
  "30 0a 5c dd a4 83 4b 62 d2 eb 24 0a f3 3f 79 d1 "
  "3d fb f0 95 bf 59 9e 0d 96 86 94 8c 19 64 74 7b "
  "67 e8 9c 9a ba 5c d8 50 16 23 6f 56 6c c5 80 2c "
  "b1 3e ad 51 bc 7c a6 be f3 b9 4d cb db b1 d5 70 "
  "46 97 71 df 0e 00 b1 a8 a0 67 77 47 2d 23 16 27 "
  "9e da e8 64 74 66 8d 4e 1e ff f9 5f 1d e6 1c 60 "
  "20 da 32 ae 92 bb f1 65 20 fe f3 cf 4d 88 f6 11 "
  "21 f2 4b bd 9f e9 1b 59 ca f1 23 5b 2a 93 ff 81 "
  "fc 40 3a dd f4 eb de a8 49 34 a9 cd af 8e 1a 9e ";

// RSASSA-PSS Signature Example 9.2
// Message to be signed:
static const char message_9_2[] =
  "c8 c9 c6 af 04 ac da 41 4d 22 7e f2 3e 08 20 c3 "
  "73 2c 50 0d c8 72 75 e9 5b 0d 09 54 13 99 3c 26 "
  "58 bc 1d 98 85 81 ba 87 9c 2d 20 1f 14 cb 88 ce "
  "d1 53 a0 19 69 a7 bf 0a 7b e7 9c 84 c1 48 6b c1 "
  "2b 3f a6 c5 98 71 b6 82 7c 8c e2 53 ca 5f ef a8 "
  "a8 c6 90 bf 32 6e 8e 37 cd b9 6d 90 a8 2e ba b6 "
  "9f 86 35 0e 18 22 e8 bd 53 6a 2e ";
// Salt:
static const char salt_9_2[] =
  "b3 07 c4 3b 48 50 a8 da c2 f1 5f 32 e3 78 39 ef "
  "8c 5c 0e 91 ";
// Signature:
static const char signature_9_2[] =
  "80 b6 d6 43 25 52 09 f0 a4 56 76 38 97 ac 9e d2 "
  "59 d4 59 b4 9c 28 87 e5 88 2e cb 44 34 cf d6 6d "
  "d7 e1 69 93 75 38 1e 51 cd 7f 55 4f 2c 27 17 04 "
  "b3 99 d4 2b 4b e2 54 0a 0e ca 61 95 1f 55 26 7f "
  "7c 28 78 c1 22 84 2d ad b2 8b 01 bd 5f 8c 02 5f "
  "7e 22 84 18 a6 73 c0 3d 6b c0 c7 36 d0 a2 95 46 "
  "bd 67 f7 86 d9 d6 92 cc ea 77 8d 71 d9 8c 20 63 "
  "b7 a7 10 92 18 7a 4d 35 af 10 81 11 d8 3e 83 ea "
  "e4 6c 46 aa 34 27 7e 06 04 45 89 90 37 88 f1 d5 "
  "e7 ce e2 5f b4 85 e9 29 49 11 88 14 d6 f2 c3 ee "
  "36 14 89 01 6f 32 7f b5 bc 51 7e b5 04 70 bf fa "
  "1a fa 5f 4c e9 aa 0c e5 b8 ee 19 bf 55 01 b9 58 ";

// RSASSA-PSS Signature Example 9.3
// Message to be signed:
static const char message_9_3[] =
  "0a fa d4 2c cd 4f c6 06 54 a5 50 02 d2 28 f5 2a "
  "4a 5f e0 3b 8b bb 08 ca 82 da ca 55 8b 44 db e1 "
  "26 6e 50 c0 e7 45 a3 6d 9d 29 04 e3 40 8a bc d1 "
  "fd 56 99 94 06 3f 4a 75 cc 72 f2 fe e2 a0 cd 89 "
  "3a 43 af 1c 5b 8b 48 7d f0 a7 16 10 02 4e 4f 6d "
  "df 9f 28 ad 08 13 c1 aa b9 1b cb 3c 90 64 d5 ff "
  "74 2d ef fe a6 57 09 41 39 36 9e 5e a6 f4 a9 63 "
  "19 a5 cc 82 24 14 5b 54 50 62 75 8f ef d1 fe 34 "
  "09 ae 16 92 59 c6 cd fd 6b 5f 29 58 e3 14 fa ec "
  "be 69 d2 ca ce 58 ee 55 17 9a b9 b3 e6 d1 ec c1 "
  "4a 55 7c 5f eb e9 88 59 52 64 fc 5d a1 c5 71 46 "
  "2e ca 79 8a 18 a1 a4 94 0c da b4 a3 e9 20 09 cc "
  "d4 2e 1e 94 7b 13 14 e3 22 38 a2 de ce 7d 23 a8 "
  "9b 5b 30 c7 51 fd 0a 4a 43 0d 2c 54 85 94 ";
// Salt:
static const char salt_9_3[] =
  "9a 2b 00 7e 80 97 8b bb 19 2c 35 4e b7 da 9a ed "
  "fc 74 db f5 ";
// Signature:
static const char signature_9_3[] =
  "48 44 08 f3 89 8c d5 f5 34 83 f8 08 19 ef bf 27 "
  "08 c3 4d 27 a8 b2 a6 fa e8 b3 22 f9 24 02 37 f9 "
  "81 81 7a ca 18 46 f1 08 4d aa 6d 7c 07 95 f6 e5 "
  "bf 1a f5 9c 38 e1 85 84 37 ce 1f 7e c4 19 b9 8c "
  "87 36 ad f6 dd 9a 00 b1 80 6d 2b d3 ad 0a 73 77 "
  "5e 05 f5 2d fe f3 a5 9a b4 b0 81 43 f0 df 05 cd "
  "1a d9 d0 4b ec ec a6 da a4 a2 12 98 03 e2 00 cb "
  "c7 77 87 ca f4 c1 d0 66 3a 6c 59 87 b6 05 95 20 "
  "19 78 2c af 2e c1 42 6d 68 fb 94 ed 1d 4b e8 16 "
  "a7 ed 08 1b 77 e6 ab 33 0b 3f fc 07 38 20 fe cd "
  "e3 72 7f cb e2 95 ee 61 a0 50 a3 43 65 86 37 c3 "
  "fd 65 9c fb 63 73 6d e3 2d 9f 90 d3 c2 f6 3e ca ";

// RSASSA-PSS Signature Example 9.4
// Message to be signed:
static const char message_9_4[] =
  "1d fd 43 b4 6c 93 db 82 62 9b da e2 bd 0a 12 b8 "
  "82 ea 04 c3 b4 65 f5 cf 93 02 3f 01 05 96 26 db "
  "be 99 f2 6b b1 be 94 9d dd d1 6d c7 f3 de bb 19 "
  "a1 94 62 7f 0b 22 44 34 df 7d 87 00 e9 e9 8b 06 "
  "e3 60 c1 2f db e3 d1 9f 51 c9 68 4e b9 08 9e cb "
  "b0 a2 f0 45 03 99 d3 f5 9e ac 72 94 08 5d 04 4f "
  "53 93 c6 ce 73 74 23 d8 b8 6c 41 53 70 d3 89 e3 "
  "0b 9f 0a 3c 02 d2 5d 00 82 e8 ad 6f 3f 1e f2 4a "
  "45 c3 cf 82 b3 83 36 70 63 a4 d4 61 3e 42 64 f0 "
  "1b 2d ac 2e 5a a4 20 43 f8 fb 5f 69 fa 87 1d 14 "
  "fb 27 3e 76 7a 53 1c 40 f0 2f 34 3b c2 fb 45 a0 "
  "c7 e0 f6 be 25 61 92 3a 77 21 1d 66 a6 e2 db b4 "
  "3c 36 63 50 be ae 22 da 3a c2 c1 f5 07 70 96 fc "
  "b5 c4 bf 25 5f 75 74 35 1a e0 b1 e1 f0 36 32 81 "
  "7c 08 56 d4 a8 ba 97 af bd c8 b8 58 55 40 2b c5 "
  "69 26 fc ec 20 9f 9e a8 ";
// Salt:
static const char salt_9_4[] =
  "70 f3 82 bd df 4d 5d 2d d8 8b 3b c7 b7 30 8b e6 "
  "32 b8 40 45 ";
// Signature:
static const char signature_9_4[] =
  "84 eb eb 48 1b e5 98 45 b4 64 68 ba fb 47 1c 01 "
  "12 e0 2b 23 5d 84 b5 d9 11 cb d1 92 6e e5 07 4a "
  "e0 42 44 95 cb 20 e8 23 08 b8 eb b6 5f 41 9a 03 "
  "fb 40 e7 2b 78 98 1d 88 aa d1 43 05 36 85 17 2c "
  "97 b2 9c 8b 7b f0 ae 73 b5 b2 26 3c 40 3d a0 ed "
  "2f 80 ff 74 50 af 78 28 eb 8b 86 f0 02 8b d2 a8 "
  "b1 76 a4 d2 28 cc ce a1 83 94 f2 38 b0 9f f7 58 "
  "cc 00 bc 04 30 11 52 35 57 42 f2 82 b5 4e 66 3a "
  "91 9e 70 9d 8d a2 4a de 55 00 a7 b9 aa 50 22 6e "
  "0c a5 29 23 e6 c2 d8 60 ec 50 ff 48 0f a5 74 77 "
  "e8 2b 05 65 f4 37 9f 79 c7 72 d5 c2 da 80 af 9f "
  "bf 32 5e ce 6f c2 0b 00 96 16 14 be e8 9a 18 3e ";

// RSASSA-PSS Signature Example 9.5
// Message to be signed:
static const char message_9_5[] =
  "1b dc 6e 7c 98 fb 8c f5 4e 9b 09 7b 66 a8 31 e9 "
  "cf e5 2d 9d 48 88 44 8e e4 b0 97 80 93 ba 1d 7d "
  "73 ae 78 b3 a6 2b a4 ad 95 cd 28 9c cb 9e 00 52 "
  "26 bb 3d 17 8b cc aa 82 1f b0 44 a4 e2 1e e9 76 "
  "96 c1 4d 06 78 c9 4c 2d ae 93 b0 ad 73 92 22 18 "
  "55 3d aa 7e 44 eb e5 77 25 a7 a4 5c c7 2b 9b 21 "
  "38 a6 b1 7c 8d b4 11 ce 82 79 ee 12 41 af f0 a8 "
  "be c6 f7 7f 87 ed b0 c6 9c b2 72 36 e3 43 5a 80 "
  "0b 19 2e 4f 11 e5 19 e3 fe 30 fc 30 ea cc ca 4f "
  "bb 41 76 90 29 bf 70 8e 81 7a 9e 68 38 05 be 67 "
  "fa 10 09 84 68 3b 74 83 8e 3b cf fa 79 36 6e ed "
  "1d 48 1c 76 72 91 18 83 8f 31 ba 8a 04 8a 93 c1 "
  "be 44 24 59 8e 8d f6 32 8b 7a 77 88 0a 3f 9c 7e "
  "2e 8d fc a8 eb 5a 26 fb 86 bd c5 56 d4 2b be 01 "
  "d9 fa 6e d8 06 46 49 1c 93 41 ";
// Salt:
static const char salt_9_5[] =
  "d6 89 25 7a 86 ef fa 68 21 2c 5e 0c 61 9e ca 29 "
  "5f b9 1b 67 ";
// Signature:
static const char signature_9_5[] =
  "82 10 2d f8 cb 91 e7 17 99 19 a0 4d 26 d3 35 d6 "
  "4f bc 2f 87 2c 44 83 39 43 24 1d e8 45 48 10 27 "
  "4c df 3d b5 f4 2d 42 3d b1 52 af 71 35 f7 01 42 "
  "0e 39 b4 94 a6 7c bf d1 9f 91 19 da 23 3a 23 da "
  "5c 64 39 b5 ba 0d 2b c3 73 ee e3 50 70 01 37 8d "
  "4a 40 73 85 6b 7f e2 ab a0 b5 ee 93 b2 7f 4a fe "
  "c7 d4 d1 20 92 1c 83 f6 06 76 5b 02 c1 9e 4d 6a "
  "1a 3b 95 fa 4c 42 29 51 be 4f 52 13 10 77 ef 17 "
  "17 97 29 cd df bd b5 69 50 db ac ee fe 78 cb 16 "
  "64 0a 09 9e a5 6d 24 38 9e ef 10 f8 fe cb 31 ba "
  "3e a3 b2 27 c0 a8 66 98 bb 89 e3 e9 36 39 05 bf "
  "22 77 7b 2a 3a a5 21 b6 5b 4c ef 76 d8 3b de 4c ";

// RSASSA-PSS Signature Example 9.6
// Message to be signed:
static const char message_9_6[] =
  "88 c7 a9 f1 36 04 01 d9 0e 53 b1 01 b6 1c 53 25 "
  "c3 c7 5d b1 b4 11 fb eb 8e 83 0b 75 e9 6b 56 67 "
  "0a d2 45 40 4e 16 79 35 44 ee 35 4b c6 13 a9 0c "
  "c9 84 87 15 a7 3d b5 89 3e 7f 6d 27 98 15 c0 c1 "
  "de 83 ef 8e 29 56 e3 a5 6e d2 6a 88 8d 7a 9c dc "
  "d0 42 f4 b1 6b 7f a5 1e f1 a0 57 36 62 d1 6a 30 "
  "2d 0e c5 b2 85 d2 e0 3a d9 65 29 c8 7b 3d 37 4d "
  "b3 72 d9 5b 24 43 d0 61 b6 b1 a3 50 ba 87 80 7e "
  "d0 83 af d1 eb 05 c3 f5 2f 4e ba 5e d2 22 77 14 "
  "fd b5 0b 9d 9d 9d d6 81 4f 62 f6 27 2f cd 5c db "
  "ce 7a 9e f7 97 ";
// Salt:
static const char salt_9_6[] =
  "c2 5f 13 bf 67 d0 81 67 1a 04 81 a1 f1 82 0d 61 "
  "3b ba 22 76 ";
// Signature:
static const char signature_9_6[] =
  "a7 fd b0 d2 59 16 5c a2 c8 8d 00 bb f1 02 8a 86 "
  "7d 33 76 99 d0 61 19 3b 17 a9 64 8e 14 cc bb aa "
  "de ac aa cd ec 81 5e 75 71 29 4e bb 8a 11 7a f2 "
  "05 fa 07 8b 47 b0 71 2c 19 9e 3a d0 51 35 c5 04 "
  "c2 4b 81 70 51 15 74 08 02 48 79 92 ff d5 11 d4 "
  "af c6 b8 54 49 1e b3 f0 dd 52 31 39 54 2f f1 5c "
  "31 01 ee 85 54 35 17 c6 a3 c7 94 17 c6 7e 2d d9 "
  "aa 74 1e 9a 29 b0 6d cb 59 3c 23 36 b3 67 0a e3 "
  "af ba c7 c3 e7 6e 21 54 73 e8 66 e3 38 ca 24 4d "
  "e0 0b 62 62 4d 6b 94 26 82 2c ea e9 f8 cc 46 08 "
  "95 f4 12 50 07 3f d4 5c 5a 1e 7b 42 5c 20 4a 42 "
  "3a 69 91 59 f6 90 3e 71 0b 37 a7 bb 2b c8 04 9f ";

// Example 10: A 2048-bit RSA Key Pair

// RSA modulus n:
static const char rsa_modulus_n_10[] =
  "a5 dd 86 7a c4 cb 02 f9 0b 94 57 d4 8c 14 a7 70 "
  "ef 99 1c 56 c3 9c 0e c6 5f d1 1a fa 89 37 ce a5 "
  "7b 9b e7 ac 73 b4 5c 00 17 61 5b 82 d6 22 e3 18 "
  "75 3b 60 27 c0 fd 15 7b e1 2f 80 90 fe e2 a7 ad "
  "cd 0e ef 75 9f 88 ba 49 97 c7 a4 2d 58 c9 aa 12 "
  "cb 99 ae 00 1f e5 21 c1 3b b5 43 14 45 a8 d5 ae "
  "4f 5e 4c 7e 94 8a c2 27 d3 60 40 71 f2 0e 57 7e "
  "90 5f be b1 5d fa f0 6d 1d e5 ae 62 53 d6 3a 6a "
  "21 20 b3 1a 5d a5 da bc 95 50 60 0e 20 f2 7d 37 "
  "39 e2 62 79 25 fe a3 cc 50 9f 21 df f0 4e 6e ea "
  "45 49 c5 40 d6 80 9f f9 30 7e ed e9 1f ff 58 73 "
  "3d 83 85 a2 37 d6 d3 70 5a 33 e3 91 90 09 92 07 "
  "0d f7 ad f1 35 7c f7 e3 70 0c e3 66 7d e8 3f 17 "
  "b8 df 17 78 db 38 1d ce 09 cb 4a d0 58 a5 11 00 "
  "1a 73 81 98 ee 27 cf 55 a1 3b 75 45 39 90 65 82 "
  "ec 8b 17 4b d5 8d 5d 1f 3d 76 7c 61 37 21 ae 05 ";
// RSA public exponent e:
static const char rsa_public_exponent_e_10[] =
  "01 00 01 ";

// RSASSA-PSS Signature Example 10.1
// Message to be signed:
static const char message_10_1[] =
  "88 31 77 e5 12 6b 9b e2 d9 a9 68 03 27 d5 37 0c "
  "6f 26 86 1f 58 20 c4 3d a6 7a 3a d6 09 ";
// Salt:
static const char salt_10_1[] =
  "04 e2 15 ee 6f f9 34 b9 da 70 d7 73 0c 87 34 ab "
  "fc ec de 89 ";
// Signature:
static const char signature_10_1[] =
  "82 c2 b1 60 09 3b 8a a3 c0 f7 52 2b 19 f8 73 54 "
  "06 6c 77 84 7a bf 2a 9f ce 54 2d 0e 84 e9 20 c5 "
  "af b4 9f fd fd ac e1 65 60 ee 94 a1 36 96 01 14 "
  "8e ba d7 a0 e1 51 cf 16 33 17 91 a5 72 7d 05 f2 "
  "1e 74 e7 eb 81 14 40 20 69 35 d7 44 76 5a 15 e7 "
  "9f 01 5c b6 6c 53 2c 87 a6 a0 59 61 c8 bf ad 74 "
  "1a 9a 66 57 02 28 94 39 3e 72 23 73 97 96 c0 2a "
  "77 45 5d 0f 55 5b 0e c0 1d df 25 9b 62 07 fd 0f "
  "d5 76 14 ce f1 a5 57 3b aa ff 4e c0 00 69 95 16 "
  "59 b8 5f 24 30 0a 25 16 0c a8 52 2d c6 e6 72 7e "
  "57 d0 19 d7 e6 36 29 b8 fe 5e 89 e2 5c c1 5b eb "
  "3a 64 75 77 55 92 99 28 0b 9b 28 f7 9b 04 09 00 "
  "0b e2 5b bd 96 40 8b a3 b4 3c c4 86 18 4d d1 c8 "
  "e6 25 53 fa 1a f4 04 0f 60 66 3d e7 f5 e4 9c 04 "
  "38 8e 25 7f 1c e8 9c 95 da b4 8a 31 5d 9b 66 b1 "
  "b7 62 82 33 87 6f f2 38 52 30 d0 70 d0 7e 16 66 ";

// RSASSA-PSS Signature Example 10.2
// Message to be signed:
static const char message_10_2[] =
  "dd 67 0a 01 46 58 68 ad c9 3f 26 13 19 57 a5 0c "
  "52 fb 77 7c db aa 30 89 2c 9e 12 36 11 64 ec 13 "
  "97 9d 43 04 81 18 e4 44 5d b8 7b ee 58 dd 98 7b "
  "34 25 d0 20 71 d8 db ae 80 70 8b 03 9d bb 64 db "
  "d1 de 56 57 d9 fe d0 c1 18 a5 41 43 74 2e 0f f3 "
  "c8 7f 74 e4 58 57 64 7a f3 f7 9e b0 a1 4c 9d 75 "
  "ea 9a 1a 04 b7 cf 47 8a 89 7a 70 8f d9 88 f4 8e "
  "80 1e db 0b 70 39 df 8c 23 bb 3c 56 f4 e8 21 ac ";
// Salt:
static const char salt_10_2[] =
  "8b 2b dd 4b 40 fa f5 45 c7 78 dd f9 bc 1a 49 cb "
  "57 f9 b7 1b ";
// Signature:
static const char signature_10_2[] =
  "14 ae 35 d9 dd 06 ba 92 f7 f3 b8 97 97 8a ed 7c "
  "d4 bf 5f f0 b5 85 a4 0b d4 6c e1 b4 2c d2 70 30 "
  "53 bb 90 44 d6 4e 81 3d 8f 96 db 2d d7 00 7d 10 "
  "11 8f 6f 8f 84 96 09 7a d7 5e 1f f6 92 34 1b 28 "
  "92 ad 55 a6 33 a1 c5 5e 7f 0a 0a d5 9a 0e 20 3a "
  "5b 82 78 ae c5 4d d8 62 2e 28 31 d8 71 74 f8 ca "
  "ff 43 ee 6c 46 44 53 45 d8 4a 59 65 9b fb 92 ec "
  "d4 c8 18 66 86 95 f3 47 06 f6 68 28 a8 99 59 63 "
  "7f 2b f3 e3 25 1c 24 bd ba 4d 4b 76 49 da 00 22 "
  "21 8b 11 9c 84 e7 9a 65 27 ec 5b 8a 5f 86 1c 15 "
  "99 52 e2 3e c0 5e 1e 71 73 46 fa ef e8 b1 68 68 "
  "25 bd 2b 26 2f b2 53 10 66 c0 de 09 ac de 2e 42 "
  "31 69 07 28 b5 d8 5e 11 5a 2f 6b 92 b7 9c 25 ab "
  "c9 bd 93 99 ff 8b cf 82 5a 52 ea 1f 56 ea 76 dd "
  "26 f4 3b aa fa 18 bf a9 2a 50 4c bd 35 69 9e 26 "
  "d1 dc c5 a2 88 73 85 f3 c6 32 32 f0 6f 32 44 c3 ";

// RSASSA-PSS Signature Example 10.3
// Message to be signed:
static const char message_10_3[] =
  "48 b2 b6 a5 7a 63 c8 4c ea 85 9d 65 c6 68 28 4b "
  "08 d9 6b dc aa be 25 2d b0 e4 a9 6c b1 ba c6 01 "
  "93 41 db 6f be fb 8d 10 6b 0e 90 ed a6 bc c6 c6 "
  "26 2f 37 e7 ea 9c 7e 5d 22 6b d7 df 85 ec 5e 71 "
  "ef ff 2f 54 c5 db 57 7f f7 29 ff 91 b8 42 49 1d "
  "e2 74 1d 0c 63 16 07 df 58 6b 90 5b 23 b9 1a f1 "
  "3d a1 23 04 bf 83 ec a8 a7 3e 87 1f f9 db ";
// Salt:
static const char salt_10_3[] =
  "4e 96 fc 1b 39 8f 92 b4 46 71 01 0c 0d c3 ef d6 "
  "e2 0c 2d 73 ";
// Signature:
static const char signature_10_3[] =
  "6e 3e 4d 7b 6b 15 d2 fb 46 01 3b 89 00 aa 5b bb "
  "39 39 cf 2c 09 57 17 98 70 42 02 6e e6 2c 74 c5 "
  "4c ff d5 d7 d5 7e fb bf 95 0a 0f 5c 57 4f a0 9d "
  "3f c1 c9 f5 13 b0 5b 4f f5 0d d8 df 7e df a2 01 "
  "02 85 4c 35 e5 92 18 01 19 a7 0c e5 b0 85 18 2a "
  "a0 2d 9e a2 aa 90 d1 df 03 f2 da ae 88 5b a2 f5 "
  "d0 5a fd ac 97 47 6f 06 b9 3b 5b c9 4a 1a 80 aa "
  "91 16 c4 d6 15 f3 33 b0 98 89 2b 25 ff ac e2 66 "
  "f5 db 5a 5a 3b cc 10 a8 24 ed 55 aa d3 5b 72 78 "
  "34 fb 8c 07 da 28 fc f4 16 a5 d9 b2 22 4f 1f 8b "
  "44 2b 36 f9 1e 45 6f de a2 d7 cf e3 36 72 68 de "
  "03 07 a4 c7 4e 92 41 59 ed 33 39 3d 5e 06 55 53 "
  "1c 77 32 7b 89 82 1b de df 88 01 61 c7 8c d4 19 "
  "6b 54 19 f7 ac c3 f1 3e 5e bf 16 1b 6e 7c 67 24 "
  "71 6c a3 3b 85 c2 e2 56 40 19 2a c2 85 96 51 d5 "
  "0b de 7e b9 76 e5 1c ec 82 8b 98 b6 56 3b 86 bb ";

// RSASSA-PSS Signature Example 10.4
// Message to be signed:
static const char message_10_4[] =
  "0b 87 77 c7 f8 39 ba f0 a6 4b bb db c5 ce 79 75 "
  "5c 57 a2 05 b8 45 c1 74 e2 d2 e9 05 46 a0 89 c4 "
  "e6 ec 8a df fa 23 a7 ea 97 ba e6 b6 5d 78 2b 82 "
  "db 5d 2b 5a 56 d2 2a 29 a0 5e 7c 44 33 e2 b8 2a "
  "62 1a bb a9 0a dd 05 ce 39 3f c4 8a 84 05 42 45 "
  "1a ";
// Salt:
static const char salt_10_4[] =
  "c7 cd 69 8d 84 b6 51 28 d8 83 5e 3a 8b 1e b0 e0 "
  "1c b5 41 ec ";
// Signature:
static const char signature_10_4[] =
  "34 04 7f f9 6c 4d c0 dc 90 b2 d4 ff 59 a1 a3 61 "
  "a4 75 4b 25 5d 2e e0 af 7d 8b f8 7c 9b c9 e7 dd "
  "ee de 33 93 4c 63 ca 1c 0e 3d 26 2c b1 45 ef 93 "
  "2a 1f 2c 0a 99 7a a6 a3 4f 8e ae e7 47 7d 82 cc "
  "f0 90 95 a6 b8 ac ad 38 d4 ee c9 fb 7e ab 7a d0 "
  "2d a1 d1 1d 8e 54 c1 82 5e 55 bf 58 c2 a2 32 34 "
  "b9 02 be 12 4f 9e 90 38 a8 f6 8f a4 5d ab 72 f6 "
  "6e 09 45 bf 1d 8b ac c9 04 4c 6f 07 09 8c 9f ce "
  "c5 8a 3a ab 10 0c 80 51 78 15 5f 03 0a 12 4c 45 "
  "0e 5a cb da 47 d0 e4 f1 0b 80 a2 3f 80 3e 77 4d "
  "02 3b 00 15 c2 0b 9f 9b be 7c 91 29 63 38 d5 ec "
  "b4 71 ca fb 03 20 07 b6 7a 60 be 5f 69 50 4a 9f "
  "01 ab b3 cb 46 7b 26 0e 2b ce 86 0b e8 d9 5b f9 "
  "2c 0c 8e 14 96 ed 1e 52 85 93 a4 ab b6 df 46 2d "
  "de 8a 09 68 df fe 46 83 11 68 57 a2 32 f5 eb f6 "
  "c8 5b e2 38 74 5a d0 f3 8f 76 7a 5f db f4 86 fb ";

// RSASSA-PSS Signature Example 10.5
// Message to be signed:
static const char message_10_5[] =
  "f1 03 6e 00 8e 71 e9 64 da dc 92 19 ed 30 e1 7f "
  "06 b4 b6 8a 95 5c 16 b3 12 b1 ed df 02 8b 74 97 "
  "6b ed 6b 3f 6a 63 d4 e7 78 59 24 3c 9c cc dc 98 "
  "01 65 23 ab b0 24 83 b3 55 91 c3 3a ad 81 21 3b "
  "b7 c7 bb 1a 47 0a ab c1 0d 44 25 6c 4d 45 59 d9 "
  "16 ";
// Salt:
static const char salt_10_5[] =
  "ef a8 bf f9 62 12 b2 f4 a3 f3 71 a1 0d 57 41 52 "
  "65 5f 5d fb ";
// Signature:
static const char signature_10_5[] =
  "7e 09 35 ea 18 f4 d6 c1 d1 7c e8 2e b2 b3 83 6c "
  "55 b3 84 58 9c e1 9d fe 74 33 63 ac 99 48 d1 f3 "
  "46 b7 bf dd fe 92 ef d7 8a db 21 fa ef c8 9a de "
  "42 b1 0f 37 40 03 fe 12 2e 67 42 9a 1c b8 cb d1 "
  "f8 d9 01 45 64 c4 4d 12 01 16 f4 99 0f 1a 6e 38 "
  "77 4c 19 4b d1 b8 21 32 86 b0 77 b0 49 9d 2e 7b "
  "3f 43 4a b1 22 89 c5 56 68 4d ee d7 81 31 93 4b "
  "b3 dd 65 37 23 6f 7c 6f 3d cb 09 d4 76 be 07 72 "
  "1e 37 e1 ce ed 9b 2f 7b 40 68 87 bd 53 15 73 05 "
  "e1 c8 b4 f8 4d 73 3b c1 e1 86 fe 06 cc 59 b6 ed "
  "b8 f4 bd 7f fe fd f4 f7 ba 9c fb 9d 57 06 89 b5 "
  "a1 a4 10 9a 74 6a 69 08 93 db 37 99 25 5a 0c b9 "
  "21 5d 2d 1c d4 90 59 0e 95 2e 8c 87 86 aa 00 11 "
  "26 52 52 47 0c 04 1d fb c3 ee c7 c3 cb f7 1c 24 "
  "86 9d 11 5c 0c b4 a9 56 f5 6d 53 0b 80 ab 58 9a "
  "cf ef c6 90 75 1d df 36 e8 d3 83 f8 3c ed d2 cc ";

// RSASSA-PSS Signature Example 10.6
// Message to be signed:
static const char message_10_6[] =
  "25 f1 08 95 a8 77 16 c1 37 45 0b b9 51 9d fa a1 "
  "f2 07 fa a9 42 ea 88 ab f7 1e 9c 17 98 00 85 b5 "
  "55 ae ba b7 62 64 ae 2a 3a b9 3c 2d 12 98 11 91 "
  "dd ac 6f b5 94 9e b3 6a ee 3c 5d a9 40 f0 07 52 "
  "c9 16 d9 46 08 fa 7d 97 ba 6a 29 15 b6 88 f2 03 "
  "23 d4 e9 d9 68 01 d8 9a 72 ab 58 92 dc 21 17 c0 "
  "74 34 fc f9 72 e0 58 cf 8c 41 ca 4b 4f f5 54 f7 "
  "d5 06 8a d3 15 5f ce d0 f3 12 5b c0 4f 91 93 37 "
  "8a 8f 5c 4c 3b 8c b4 dd 6d 1c c6 9d 30 ec ca 6e "
  "aa 51 e3 6a 05 73 0e 9e 34 2e 85 5b af 09 9d ef "
  "b8 af d7 ";
// Salt:
static const char salt_10_6[] =
  "ad 8b 15 23 70 36 46 22 4b 66 0b 55 08 85 91 7c "
  "a2 d1 df 28 ";
// Signature:
static const char signature_10_6[] =
  "6d 3b 5b 87 f6 7e a6 57 af 21 f7 54 41 97 7d 21 "
  "80 f9 1b 2c 5f 69 2d e8 29 55 69 6a 68 67 30 d9 "
  "b9 77 8d 97 07 58 cc b2 60 71 c2 20 9f fb d6 12 "
  "5b e2 e9 6e a8 1b 67 cb 9b 93 08 23 9f da 17 f7 "
  "b2 b6 4e cd a0 96 b6 b9 35 64 0a 5a 1c b4 2a 91 "
  "55 b1 c9 ef 7a 63 3a 02 c5 9f 0d 6e e5 9b 85 2c "
  "43 b3 50 29 e7 3c 94 0f f0 41 0e 8f 11 4e ed 46 "
  "bb d0 fa e1 65 e4 2b e2 52 8a 40 1c 3b 28 fd 81 "
  "8e f3 23 2d ca 9f 4d 2a 0f 51 66 ec 59 c4 23 96 "
  "d6 c1 1d bc 12 15 a5 6f a1 71 69 db 95 75 34 3e "
  "f3 4f 9d e3 2a 49 cd c3 17 49 22 f2 29 c2 3e 18 "
  "e4 5d f9 35 31 19 ec 43 19 ce dc e7 a1 7c 64 08 "
  "8c 1f 6f 52 be 29 63 41 00 b3 91 9d 38 f3 d1 ed "
  "94 e6 89 1e 66 a7 3b 8f b8 49 f5 87 4d f5 94 59 "
  "e2 98 c7 bb ce 2e ee 78 2a 19 5a a6 6f e2 d0 73 "
  "2b 25 e5 95 f5 7d 3e 06 1b 1f c3 e4 06 3b f9 8f ";

struct SignatureExample {
  const char* message;
  const char* salt;
  const char* signature;
};

struct PSSTestVector {
  const char* modulus_n;
  const char* public_exponent_e;
  SignatureExample example[6];
};

static const PSSTestVector pss_test[] = {
  {
    rsa_modulus_n_1,
    rsa_public_exponent_e_1,
    {
      { message_1_1, salt_1_1, signature_1_1 },
      { message_1_2, salt_1_2, signature_1_2 },
      { message_1_3, salt_1_3, signature_1_3 },
      { message_1_4, salt_1_4, signature_1_4 },
      { message_1_5, salt_1_5, signature_1_5 },
      { message_1_6, salt_1_6, signature_1_6 },
    }
  },
  {
    rsa_modulus_n_9,
    rsa_public_exponent_e_9,
    {
      { message_9_1, salt_9_1, signature_9_1 },
      { message_9_2, salt_9_2, signature_9_2 },
      { message_9_3, salt_9_3, signature_9_3 },
      { message_9_4, salt_9_4, signature_9_4 },
      { message_9_5, salt_9_5, signature_9_5 },
      { message_9_6, salt_9_6, signature_9_6 },
    }
  },
  {
    rsa_modulus_n_10,
    rsa_public_exponent_e_10,
    {
      { message_10_1, salt_10_1, signature_10_1 },
      { message_10_2, salt_10_2, signature_10_2 },
      { message_10_3, salt_10_3, signature_10_3 },
      { message_10_4, salt_10_4, signature_10_4 },
      { message_10_5, salt_10_5, signature_10_5 },
      { message_10_6, salt_10_6, signature_10_6 },
    }
  },
};

static uint8 HexDigitValue(char digit) {
  if ('0' <= digit && digit <= '9')
    return digit - '0';
  if ('a' <= digit && digit <= 'f')
    return digit - 'a' + 10;
  return digit - 'A' + 10;
}

static bool DecodeTestInput(const char* in, std::vector<uint8>* out) {
  out->clear();
  while (in[0] != '\0') {
    if (!isxdigit(in[0]) || !isxdigit(in[1]) || in[2] != ' ')
      return false;
    uint8 octet = HexDigitValue(in[0]) * 16 + HexDigitValue(in[1]);
    out->push_back(octet);
    in += 3;
  }
  return true;
}

// PrependASN1Length prepends an ASN.1 serialized length to the beginning of
// |out|.
static void PrependASN1Length(std::vector<uint8>* out, size_t len) {
  if (len < 128) {
    out->insert(out->begin(), static_cast<uint8>(len));
  } else if (len < 256) {
    out->insert(out->begin(), static_cast<uint8>(len));
    out->insert(out->begin(), 0x81);
  } else if (len < 0x10000) {
    out->insert(out->begin(), static_cast<uint8>(len));
    out->insert(out->begin(), static_cast<uint8>(len >> 8));
    out->insert(out->begin(), 0x82);
  } else {
    CHECK(false) << "ASN.1 length not handled: " << len;
  }
}

static bool EncodeRSAPublicKey(const std::vector<uint8>& modulus_n,
                               const std::vector<uint8>& public_exponent_e,
                               std::vector<uint8>* public_key_info) {
  // The public key is specified as the following ASN.1 structure:
  //   SubjectPublicKeyInfo  ::=  SEQUENCE  {
  //       algorithm            AlgorithmIdentifier,
  //       subjectPublicKey     BIT STRING  }
  //
  // The signature algorithm is specified as the following ASN.1 structure:
  //    AlgorithmIdentifier  ::=  SEQUENCE  {
  //        algorithm               OBJECT IDENTIFIER,
  //        parameters              ANY DEFINED BY algorithm OPTIONAL  }
  //
  // An RSA public key is specified as the following ASN.1 structure:
  //    RSAPublicKey ::= SEQUENCE {
  //        modulus           INTEGER,  -- n
  //        publicExponent    INTEGER   -- e
  //    }
  static const uint8 kIntegerTag = 0x02;
  static const uint8 kBitStringTag = 0x03;
  static const uint8 kSequenceTag = 0x30;
  public_key_info->clear();

  // Encode the public exponent e as an INTEGER.
  public_key_info->insert(public_key_info->begin(),
                          public_exponent_e.begin(),
                          public_exponent_e.end());
  PrependASN1Length(public_key_info, public_exponent_e.size());
  public_key_info->insert(public_key_info->begin(), kIntegerTag);

  // Encode the modulus n as an INTEGER.
  public_key_info->insert(public_key_info->begin(),
                          modulus_n.begin(), modulus_n.end());
  size_t modulus_size = modulus_n.size();
  if (modulus_n[0] & 0x80) {
    public_key_info->insert(public_key_info->begin(), 0x00);
    modulus_size++;
  }
  PrependASN1Length(public_key_info, modulus_size);
  public_key_info->insert(public_key_info->begin(), kIntegerTag);

  // Encode the RSAPublicKey SEQUENCE.
  PrependASN1Length(public_key_info, public_key_info->size());
  public_key_info->insert(public_key_info->begin(), kSequenceTag);

  // Encode the BIT STRING.
  // Number of unused bits.
  public_key_info->insert(public_key_info->begin(), 0x00);
  PrependASN1Length(public_key_info, public_key_info->size());
  public_key_info->insert(public_key_info->begin(), kBitStringTag);

  // Encode the AlgorithmIdentifier.
  static const uint8 algorithm[] = {
    0x30, 0x0d,  // a SEQUENCE of length 13
      0x06, 0x09,  // an OBJECT IDENTIFIER of length 9
        0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x01,
      0x05, 0x00,
  };
  public_key_info->insert(public_key_info->begin(),
                          algorithm, algorithm + sizeof(algorithm));

  // Encode the outermost SEQUENCE.
  PrependASN1Length(public_key_info, public_key_info->size());
  public_key_info->insert(public_key_info->begin(), kSequenceTag);

  return true;
}

TEST(SignatureVerifierTest, VerifyRSAPSS) {
  for (unsigned int i = 0; i < arraysize(pss_test); i++) {
    SCOPED_TRACE(i);
    std::vector<uint8> modulus_n;
    std::vector<uint8> public_exponent_e;
    ASSERT_TRUE(DecodeTestInput(pss_test[i].modulus_n, &modulus_n));
    ASSERT_TRUE(DecodeTestInput(pss_test[i].public_exponent_e,
                                &public_exponent_e));
    std::vector<uint8> public_key_info;
    ASSERT_TRUE(EncodeRSAPublicKey(modulus_n, public_exponent_e,
                                   &public_key_info));

    for (unsigned int j = 0; j < arraysize(pss_test[i].example); j++) {
      SCOPED_TRACE(j);
      std::vector<uint8> message;
      std::vector<uint8> salt;
      std::vector<uint8> signature;
      ASSERT_TRUE(DecodeTestInput(pss_test[i].example[j].message, &message));
      ASSERT_TRUE(DecodeTestInput(pss_test[i].example[j].salt, &salt));
      ASSERT_TRUE(DecodeTestInput(pss_test[i].example[j].signature,
                                  &signature));

      crypto::SignatureVerifier verifier;
      bool ok;

      // Positive test.
      ok = verifier.VerifyInitRSAPSS(crypto::SignatureVerifier::SHA1,
                                     crypto::SignatureVerifier::SHA1,
                                     salt.size(),
                                     &signature[0], signature.size(),
                                     &public_key_info[0],
                                     public_key_info.size());
      ASSERT_TRUE(ok);
      verifier.VerifyUpdate(&message[0], message.size());
      ok = verifier.VerifyFinal();
      EXPECT_TRUE(ok);

      // Modify the first byte of the message.
      ok = verifier.VerifyInitRSAPSS(crypto::SignatureVerifier::SHA1,
                                     crypto::SignatureVerifier::SHA1,
                                     salt.size(),
                                     &signature[0], signature.size(),
                                     &public_key_info[0],
                                     public_key_info.size());
      ASSERT_TRUE(ok);
      message[0] += 1;
      verifier.VerifyUpdate(&message[0], message.size());
      message[0] -= 1;
      ok = verifier.VerifyFinal();
      EXPECT_FALSE(ok);

      // Truncate the message.
      ASSERT_FALSE(message.empty());
      ok = verifier.VerifyInitRSAPSS(crypto::SignatureVerifier::SHA1,
                                     crypto::SignatureVerifier::SHA1,
                                     salt.size(),
                                     &signature[0], signature.size(),
                                     &public_key_info[0],
                                     public_key_info.size());
      ASSERT_TRUE(ok);
      verifier.VerifyUpdate(&message[0], message.size() - 1);
      ok = verifier.VerifyFinal();
      EXPECT_FALSE(ok);

      // Corrupt the signature.
      signature[0] += 1;
      ok = verifier.VerifyInitRSAPSS(crypto::SignatureVerifier::SHA1,
                                     crypto::SignatureVerifier::SHA1,
                                     salt.size(),
                                     &signature[0], signature.size(),
                                     &public_key_info[0],
                                     public_key_info.size());
      signature[0] -= 1;
      ASSERT_TRUE(ok);
      verifier.VerifyUpdate(&message[0], message.size());
      ok = verifier.VerifyFinal();
      EXPECT_FALSE(ok);
    }
  }
}
