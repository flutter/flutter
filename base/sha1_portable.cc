// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/sha1.h"

#include <string.h>

#include "base/basictypes.h"

namespace base {

// Implementation of SHA-1. Only handles data in byte-sized blocks,
// which simplifies the code a fair bit.

// Identifier names follow notation in FIPS PUB 180-3, where you'll
// also find a description of the algorithm:
// http://csrc.nist.gov/publications/fips/fips180-3/fips180-3_final.pdf

// Usage example:
//
// SecureHashAlgorithm sha;
// while(there is data to hash)
//   sha.Update(moredata, size of data);
// sha.Final();
// memcpy(somewhere, sha.Digest(), 20);
//
// to reuse the instance of sha, call sha.Init();

// TODO(jhawkins): Replace this implementation with a per-platform
// implementation using each platform's crypto library.  See
// http://crbug.com/47218

class SecureHashAlgorithm {
 public:
  SecureHashAlgorithm() { Init(); }

  static const int kDigestSizeBytes;

  void Init();
  void Update(const void* data, size_t nbytes);
  void Final();

  // 20 bytes of message digest.
  const unsigned char* Digest() const {
    return reinterpret_cast<const unsigned char*>(H);
  }

 private:
  void Pad();
  void Process();

  uint32 A, B, C, D, E;

  uint32 H[5];

  union {
    uint32 W[80];
    uint8 M[64];
  };

  uint32 cursor;
  uint64 l;
};

static inline uint32 f(uint32 t, uint32 B, uint32 C, uint32 D) {
  if (t < 20) {
    return (B & C) | ((~B) & D);
  } else if (t < 40) {
    return B ^ C ^ D;
  } else if (t < 60) {
    return (B & C) | (B & D) | (C & D);
  } else {
    return B ^ C ^ D;
  }
}

static inline uint32 S(uint32 n, uint32 X) {
  return (X << n) | (X >> (32-n));
}

static inline uint32 K(uint32 t) {
  if (t < 20) {
    return 0x5a827999;
  } else if (t < 40) {
    return 0x6ed9eba1;
  } else if (t < 60) {
    return 0x8f1bbcdc;
  } else {
    return 0xca62c1d6;
  }
}

static inline void swapends(uint32* t) {
  *t = (*t >> 24) | ((*t >> 8) & 0xff00) | ((*t & 0xff00) << 8) | (*t << 24);
}

const int SecureHashAlgorithm::kDigestSizeBytes = 20;

void SecureHashAlgorithm::Init() {
  A = 0;
  B = 0;
  C = 0;
  D = 0;
  E = 0;
  cursor = 0;
  l = 0;
  H[0] = 0x67452301;
  H[1] = 0xefcdab89;
  H[2] = 0x98badcfe;
  H[3] = 0x10325476;
  H[4] = 0xc3d2e1f0;
}

void SecureHashAlgorithm::Final() {
  Pad();
  Process();

  for (int t = 0; t < 5; ++t)
    swapends(&H[t]);
}

void SecureHashAlgorithm::Update(const void* data, size_t nbytes) {
  const uint8* d = reinterpret_cast<const uint8*>(data);
  while (nbytes--) {
    M[cursor++] = *d++;
    if (cursor >= 64)
      Process();
    l += 8;
  }
}

void SecureHashAlgorithm::Pad() {
  M[cursor++] = 0x80;

  if (cursor > 64-8) {
    // pad out to next block
    while (cursor < 64)
      M[cursor++] = 0;

    Process();
  }

  while (cursor < 64-8)
    M[cursor++] = 0;

  M[cursor++] = (l >> 56) & 0xff;
  M[cursor++] = (l >> 48) & 0xff;
  M[cursor++] = (l >> 40) & 0xff;
  M[cursor++] = (l >> 32) & 0xff;
  M[cursor++] = (l >> 24) & 0xff;
  M[cursor++] = (l >> 16) & 0xff;
  M[cursor++] = (l >> 8) & 0xff;
  M[cursor++] = l & 0xff;
}

void SecureHashAlgorithm::Process() {
  uint32 t;

  // Each a...e corresponds to a section in the FIPS 180-3 algorithm.

  // a.
  //
  // W and M are in a union, so no need to memcpy.
  // memcpy(W, M, sizeof(M));
  for (t = 0; t < 16; ++t)
    swapends(&W[t]);

  // b.
  for (t = 16; t < 80; ++t)
    W[t] = S(1, W[t - 3] ^ W[t - 8] ^ W[t - 14] ^ W[t - 16]);

  // c.
  A = H[0];
  B = H[1];
  C = H[2];
  D = H[3];
  E = H[4];

  // d.
  for (t = 0; t < 80; ++t) {
    uint32 TEMP = S(5, A) + f(t, B, C, D) + E + W[t] + K(t);
    E = D;
    D = C;
    C = S(30, B);
    B = A;
    A = TEMP;
  }

  // e.
  H[0] += A;
  H[1] += B;
  H[2] += C;
  H[3] += D;
  H[4] += E;

  cursor = 0;
}

std::string SHA1HashString(const std::string& str) {
  char hash[SecureHashAlgorithm::kDigestSizeBytes];
  SHA1HashBytes(reinterpret_cast<const unsigned char*>(str.c_str()),
                str.length(), reinterpret_cast<unsigned char*>(hash));
  return std::string(hash, SecureHashAlgorithm::kDigestSizeBytes);
}

void SHA1HashBytes(const unsigned char* data, size_t len,
                   unsigned char* hash) {
  SecureHashAlgorithm sha;
  sha.Update(data, len);
  sha.Final();

  memcpy(hash, sha.Digest(), SecureHashAlgorithm::kDigestSizeBytes);
}

}  // namespace base
