// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "crypto/rsa_private_key.h"

#include <algorithm>
#include <list>

#include "base/logging.h"
#include "base/memory/scoped_ptr.h"
#include "base/strings/string_util.h"

// This file manually encodes and decodes RSA private keys using PrivateKeyInfo
// from PKCS #8 and RSAPrivateKey from PKCS #1. These structures are:
//
// PrivateKeyInfo ::= SEQUENCE {
//   version Version,
//   privateKeyAlgorithm PrivateKeyAlgorithmIdentifier,
//   privateKey PrivateKey,
//   attributes [0] IMPLICIT Attributes OPTIONAL
// }
//
// RSAPrivateKey ::= SEQUENCE {
//   version Version,
//   modulus INTEGER,
//   publicExponent INTEGER,
//   privateExponent INTEGER,
//   prime1 INTEGER,
//   prime2 INTEGER,
//   exponent1 INTEGER,
//   exponent2 INTEGER,
//   coefficient INTEGER
// }

namespace {
// Helper for error handling during key import.
#define READ_ASSERT(truth) \
  if (!(truth)) { \
    NOTREACHED(); \
    return false; \
  }
}  // namespace

namespace crypto {

const uint8 PrivateKeyInfoCodec::kRsaAlgorithmIdentifier[] = {
  0x30, 0x0D, 0x06, 0x09, 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x01,
  0x05, 0x00
};

PrivateKeyInfoCodec::PrivateKeyInfoCodec(bool big_endian)
    : big_endian_(big_endian) {}

PrivateKeyInfoCodec::~PrivateKeyInfoCodec() {}

bool PrivateKeyInfoCodec::Export(std::vector<uint8>* output) {
  std::list<uint8> content;

  // Version (always zero)
  uint8 version = 0;

  PrependInteger(coefficient_, &content);
  PrependInteger(exponent2_, &content);
  PrependInteger(exponent1_, &content);
  PrependInteger(prime2_, &content);
  PrependInteger(prime1_, &content);
  PrependInteger(private_exponent_, &content);
  PrependInteger(public_exponent_, &content);
  PrependInteger(modulus_, &content);
  PrependInteger(&version, 1, &content);
  PrependTypeHeaderAndLength(kSequenceTag, content.size(), &content);
  PrependTypeHeaderAndLength(kOctetStringTag, content.size(), &content);

  // RSA algorithm OID
  for (size_t i = sizeof(kRsaAlgorithmIdentifier); i > 0; --i)
    content.push_front(kRsaAlgorithmIdentifier[i - 1]);

  PrependInteger(&version, 1, &content);
  PrependTypeHeaderAndLength(kSequenceTag, content.size(), &content);

  // Copy everying into the output.
  output->reserve(content.size());
  output->assign(content.begin(), content.end());

  return true;
}

bool PrivateKeyInfoCodec::ExportPublicKeyInfo(std::vector<uint8>* output) {
  // Create a sequence with the modulus (n) and public exponent (e).
  std::vector<uint8> bit_string;
  if (!ExportPublicKey(&bit_string))
    return false;

  // Add the sequence as the contents of a bit string.
  std::list<uint8> content;
  PrependBitString(&bit_string[0], static_cast<int>(bit_string.size()),
                   &content);

  // Add the RSA algorithm OID.
  for (size_t i = sizeof(kRsaAlgorithmIdentifier); i > 0; --i)
    content.push_front(kRsaAlgorithmIdentifier[i - 1]);

  // Finally, wrap everything in a sequence.
  PrependTypeHeaderAndLength(kSequenceTag, content.size(), &content);

  // Copy everything into the output.
  output->reserve(content.size());
  output->assign(content.begin(), content.end());

  return true;
}

bool PrivateKeyInfoCodec::ExportPublicKey(std::vector<uint8>* output) {
  // Create a sequence with the modulus (n) and public exponent (e).
  std::list<uint8> content;
  PrependInteger(&public_exponent_[0],
                 static_cast<int>(public_exponent_.size()),
                 &content);
  PrependInteger(&modulus_[0],  static_cast<int>(modulus_.size()), &content);
  PrependTypeHeaderAndLength(kSequenceTag, content.size(), &content);

  // Copy everything into the output.
  output->reserve(content.size());
  output->assign(content.begin(), content.end());

  return true;
}

bool PrivateKeyInfoCodec::Import(const std::vector<uint8>& input) {
  if (input.empty()) {
    return false;
  }

  // Parse the private key info up to the public key values, ignoring
  // the subsequent private key values.
  uint8* src = const_cast<uint8*>(&input.front());
  uint8* end = src + input.size();
  if (!ReadSequence(&src, end) ||
      !ReadVersion(&src, end) ||
      !ReadAlgorithmIdentifier(&src, end) ||
      !ReadTypeHeaderAndLength(&src, end, kOctetStringTag, NULL) ||
      !ReadSequence(&src, end) ||
      !ReadVersion(&src, end) ||
      !ReadInteger(&src, end, &modulus_))
    return false;

  int mod_size = modulus_.size();
  READ_ASSERT(mod_size % 2 == 0);
  int primes_size = mod_size / 2;

  if (!ReadIntegerWithExpectedSize(&src, end, 4, &public_exponent_) ||
      !ReadIntegerWithExpectedSize(&src, end, mod_size, &private_exponent_) ||
      !ReadIntegerWithExpectedSize(&src, end, primes_size, &prime1_) ||
      !ReadIntegerWithExpectedSize(&src, end, primes_size, &prime2_) ||
      !ReadIntegerWithExpectedSize(&src, end, primes_size, &exponent1_) ||
      !ReadIntegerWithExpectedSize(&src, end, primes_size, &exponent2_) ||
      !ReadIntegerWithExpectedSize(&src, end, primes_size, &coefficient_))
    return false;

  READ_ASSERT(src == end);


  return true;
}

void PrivateKeyInfoCodec::PrependInteger(const std::vector<uint8>& in,
                                         std::list<uint8>* out) {
  uint8* ptr = const_cast<uint8*>(&in.front());
  PrependIntegerImpl(ptr, in.size(), out, big_endian_);
}

// Helper to prepend an ASN.1 integer.
void PrivateKeyInfoCodec::PrependInteger(uint8* val,
                                         int num_bytes,
                                         std::list<uint8>* data) {
  PrependIntegerImpl(val, num_bytes, data, big_endian_);
}

void PrivateKeyInfoCodec::PrependIntegerImpl(uint8* val,
                                             int num_bytes,
                                             std::list<uint8>* data,
                                             bool big_endian) {
 // Reverse input if little-endian.
 std::vector<uint8> tmp;
 if (!big_endian) {
   tmp.assign(val, val + num_bytes);
   std::reverse(tmp.begin(), tmp.end());
   val = &tmp.front();
 }

  // ASN.1 integers are unpadded byte arrays, so skip any null padding bytes
  // from the most-significant end of the integer.
  int start = 0;
  while (start < (num_bytes - 1) && val[start] == 0x00) {
    start++;
    num_bytes--;
  }
  PrependBytes(val, start, num_bytes, data);

  // ASN.1 integers are signed. To encode a positive integer whose sign bit
  // (the most significant bit) would otherwise be set and make the number
  // negative, ASN.1 requires a leading null byte to force the integer to be
  // positive.
  uint8 front = data->front();
  if ((front & 0x80) != 0) {
    data->push_front(0x00);
    num_bytes++;
  }

  PrependTypeHeaderAndLength(kIntegerTag, num_bytes, data);
}

bool PrivateKeyInfoCodec::ReadInteger(uint8** pos,
                                      uint8* end,
                                      std::vector<uint8>* out) {
  return ReadIntegerImpl(pos, end, out, big_endian_);
}

bool PrivateKeyInfoCodec::ReadIntegerWithExpectedSize(uint8** pos,
                                                      uint8* end,
                                                      size_t expected_size,
                                                      std::vector<uint8>* out) {
  std::vector<uint8> temp;
  if (!ReadIntegerImpl(pos, end, &temp, true))  // Big-Endian
    return false;

  int pad = expected_size - temp.size();
  int index = 0;
  if (out->size() == expected_size + 1) {
    READ_ASSERT(out->front() == 0x00);
    pad++;
    index++;
  } else {
    READ_ASSERT(out->size() <= expected_size);
  }

  out->insert(out->end(), pad, 0x00);
  out->insert(out->end(), temp.begin(), temp.end());

  // Reverse output if little-endian.
  if (!big_endian_)
    std::reverse(out->begin(), out->end());
  return true;
}

bool PrivateKeyInfoCodec::ReadIntegerImpl(uint8** pos,
                                          uint8* end,
                                          std::vector<uint8>* out,
                                          bool big_endian) {
  uint32 length = 0;
  if (!ReadTypeHeaderAndLength(pos, end, kIntegerTag, &length) || !length)
    return false;

  // The first byte can be zero to force positiveness. We can ignore this.
  if (**pos == 0x00) {
    ++(*pos);
    --length;
  }

  if (length)
    out->insert(out->end(), *pos, (*pos) + length);

  (*pos) += length;

  // Reverse output if little-endian.
  if (!big_endian)
    std::reverse(out->begin(), out->end());
  return true;
}

void PrivateKeyInfoCodec::PrependBytes(uint8* val,
                                       int start,
                                       int num_bytes,
                                       std::list<uint8>* data) {
  while (num_bytes > 0) {
    --num_bytes;
    data->push_front(val[start + num_bytes]);
  }
}

void PrivateKeyInfoCodec::PrependLength(size_t size, std::list<uint8>* data) {
  // The high bit is used to indicate whether additional octets are needed to
  // represent the length.
  if (size < 0x80) {
    data->push_front(static_cast<uint8>(size));
  } else {
    uint8 num_bytes = 0;
    while (size > 0) {
      data->push_front(static_cast<uint8>(size & 0xFF));
      size >>= 8;
      num_bytes++;
    }
    CHECK_LE(num_bytes, 4);
    data->push_front(0x80 | num_bytes);
  }
}

void PrivateKeyInfoCodec::PrependTypeHeaderAndLength(uint8 type,
                                                     uint32 length,
                                                     std::list<uint8>* output) {
  PrependLength(length, output);
  output->push_front(type);
}

void PrivateKeyInfoCodec::PrependBitString(uint8* val,
                                           int num_bytes,
                                           std::list<uint8>* output) {
  // Start with the data.
  PrependBytes(val, 0, num_bytes, output);
  // Zero unused bits.
  output->push_front(0);
  // Add the length.
  PrependLength(num_bytes + 1, output);
  // Finally, add the bit string tag.
  output->push_front((uint8) kBitStringTag);
}

bool PrivateKeyInfoCodec::ReadLength(uint8** pos, uint8* end, uint32* result) {
  READ_ASSERT(*pos < end);
  int length = 0;

  // If the MSB is not set, the length is just the byte itself.
  if (!(**pos & 0x80)) {
    length = **pos;
    (*pos)++;
  } else {
    // Otherwise, the lower 7 indicate the length of the length.
    int length_of_length = **pos & 0x7F;
    READ_ASSERT(length_of_length <= 4);
    (*pos)++;
    READ_ASSERT(*pos + length_of_length < end);

    length = 0;
    for (int i = 0; i < length_of_length; ++i) {
      length <<= 8;
      length |= **pos;
      (*pos)++;
    }
  }

  READ_ASSERT(*pos + length <= end);
  if (result) *result = length;
  return true;
}

bool PrivateKeyInfoCodec::ReadTypeHeaderAndLength(uint8** pos,
                                                  uint8* end,
                                                  uint8 expected_tag,
                                                  uint32* length) {
  READ_ASSERT(*pos < end);
  READ_ASSERT(**pos == expected_tag);
  (*pos)++;

  return ReadLength(pos, end, length);
}

bool PrivateKeyInfoCodec::ReadSequence(uint8** pos, uint8* end) {
  return ReadTypeHeaderAndLength(pos, end, kSequenceTag, NULL);
}

bool PrivateKeyInfoCodec::ReadAlgorithmIdentifier(uint8** pos, uint8* end) {
  READ_ASSERT(*pos + sizeof(kRsaAlgorithmIdentifier) < end);
  READ_ASSERT(memcmp(*pos, kRsaAlgorithmIdentifier,
                     sizeof(kRsaAlgorithmIdentifier)) == 0);
  (*pos) += sizeof(kRsaAlgorithmIdentifier);
  return true;
}

bool PrivateKeyInfoCodec::ReadVersion(uint8** pos, uint8* end) {
  uint32 length = 0;
  if (!ReadTypeHeaderAndLength(pos, end, kIntegerTag, &length))
    return false;

  // The version should be zero.
  for (uint32 i = 0; i < length; ++i) {
    READ_ASSERT(**pos == 0x00);
    (*pos)++;
  }

  return true;
}

}  // namespace crypto
