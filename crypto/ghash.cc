// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "crypto/ghash.h"

#include <algorithm>

#include "base/logging.h"
#include "base/sys_byteorder.h"

namespace crypto {

// GaloisHash is a polynomial authenticator that works in GF(2^128).
//
// Elements of the field are represented in `little-endian' order (which
// matches the description in the paper[1]), thus the most significant bit is
// the right-most bit. (This is backwards from the way that everybody else does
// it.)
//
// We store field elements in a pair of such `little-endian' uint64s. So the
// value one is represented by {low = 2**63, high = 0} and doubling a value
// involves a *right* shift.
//
// [1] http://csrc.nist.gov/groups/ST/toolkit/BCM/documents/proposedmodes/gcm/gcm-revised-spec.pdf

namespace {

// Get64 reads a 64-bit, big-endian number from |bytes|.
uint64 Get64(const uint8 bytes[8]) {
  uint64 t;
  memcpy(&t, bytes, sizeof(t));
  return base::NetToHost64(t);
}

// Put64 writes |x| to |bytes| as a 64-bit, big-endian number.
void Put64(uint8 bytes[8], uint64 x) {
  x = base::HostToNet64(x);
  memcpy(bytes, &x, sizeof(x));
}

// Reverse reverses the order of the bits of 4-bit number in |i|.
int Reverse(int i) {
  i = ((i << 2) & 0xc) | ((i >> 2) & 0x3);
  i = ((i << 1) & 0xa) | ((i >> 1) & 0x5);
  return i;
}

}  // namespace

GaloisHash::GaloisHash(const uint8 key[16]) {
  Reset();

  // We precompute 16 multiples of |key|. However, when we do lookups into this
  // table we'll be using bits from a field element and therefore the bits will
  // be in the reverse order. So normally one would expect, say, 4*key to be in
  // index 4 of the table but due to this bit ordering it will actually be in
  // index 0010 (base 2) = 2.
  FieldElement x = {Get64(key), Get64(key+8)};
  product_table_[0].low = 0;
  product_table_[0].hi = 0;
  product_table_[Reverse(1)] = x;

  for (int i = 0; i < 16; i += 2) {
    product_table_[Reverse(i)] = Double(product_table_[Reverse(i/2)]);
    product_table_[Reverse(i+1)] = Add(product_table_[Reverse(i)], x);
  }
}

void GaloisHash::Reset() {
  state_ = kHashingAdditionalData;
  additional_bytes_ = 0;
  ciphertext_bytes_ = 0;
  buf_used_ = 0;
  y_.low = 0;
  y_.hi = 0;
}

void GaloisHash::UpdateAdditional(const uint8* data, size_t length) {
  DCHECK_EQ(state_, kHashingAdditionalData);
  additional_bytes_ += length;
  Update(data, length);
}

void GaloisHash::UpdateCiphertext(const uint8* data, size_t length) {
  if (state_ == kHashingAdditionalData) {
    // If there's any remaining additional data it's zero padded to the next
    // full block.
    if (buf_used_ > 0) {
      memset(&buf_[buf_used_], 0, sizeof(buf_)-buf_used_);
      UpdateBlocks(buf_, 1);
      buf_used_ = 0;
    }
    state_ = kHashingCiphertext;
  }

  DCHECK_EQ(state_, kHashingCiphertext);
  ciphertext_bytes_ += length;
  Update(data, length);
}

void GaloisHash::Finish(void* output, size_t len) {
  DCHECK(state_ != kComplete);

  if (buf_used_ > 0) {
    // If there's any remaining data (additional data or ciphertext), it's zero
    // padded to the next full block.
    memset(&buf_[buf_used_], 0, sizeof(buf_)-buf_used_);
    UpdateBlocks(buf_, 1);
    buf_used_ = 0;
  }

  state_ = kComplete;

  // The lengths of the additional data and ciphertext are included as the last
  // block. The lengths are the number of bits.
  y_.low ^= additional_bytes_*8;
  y_.hi ^= ciphertext_bytes_*8;
  MulAfterPrecomputation(product_table_, &y_);

  uint8 *result, result_tmp[16];
  if (len >= 16) {
    result = reinterpret_cast<uint8*>(output);
  } else {
    result = result_tmp;
  }

  Put64(result, y_.low);
  Put64(result + 8, y_.hi);

  if (len < 16)
    memcpy(output, result_tmp, len);
}

// static
GaloisHash::FieldElement GaloisHash::Add(
    const FieldElement& x,
    const FieldElement& y) {
  // Addition in a characteristic 2 field is just XOR.
  FieldElement z = {x.low^y.low, x.hi^y.hi};
  return z;
}

// static
GaloisHash::FieldElement GaloisHash::Double(const FieldElement& x) {
  const bool msb_set = x.hi & 1;

  FieldElement xx;
  // Because of the bit-ordering, doubling is actually a right shift.
  xx.hi = x.hi >> 1;
  xx.hi |= x.low << 63;
  xx.low = x.low >> 1;

  // If the most-significant bit was set before shifting then it, conceptually,
  // becomes a term of x^128. This is greater than the irreducible polynomial
  // so the result has to be reduced. The irreducible polynomial is
  // 1+x+x^2+x^7+x^128. We can subtract that to eliminate the term at x^128
  // which also means subtracting the other four terms. In characteristic 2
  // fields, subtraction == addition == XOR.
  if (msb_set)
    xx.low ^= 0xe100000000000000ULL;

  return xx;
}

void GaloisHash::MulAfterPrecomputation(const FieldElement* table,
                                        FieldElement* x) {
  FieldElement z = {0, 0};

  // In order to efficiently multiply, we use the precomputed table of i*key,
  // for i in 0..15, to handle four bits at a time. We could obviously use
  // larger tables for greater speedups but the next convenient table size is
  // 4K, which is a little large.
  //
  // In other fields one would use bit positions spread out across the field in
  // order to reduce the number of doublings required. However, in
  // characteristic 2 fields, repeated doublings are exceptionally cheap and
  // it's not worth spending more precomputation time to eliminate them.
  for (unsigned i = 0; i < 2; i++) {
    uint64 word;
    if (i == 0) {
      word = x->hi;
    } else {
      word = x->low;
    }

    for (unsigned j = 0; j < 64; j += 4) {
      Mul16(&z);
      // the values in |table| are ordered for little-endian bit positions. See
      // the comment in the constructor.
      const FieldElement& t = table[word & 0xf];
      z.low ^= t.low;
      z.hi ^= t.hi;
      word >>= 4;
    }
  }

  *x = z;
}

// kReductionTable allows for rapid multiplications by 16. A multiplication by
// 16 is a right shift by four bits, which results in four bits at 2**128.
// These terms have to be eliminated by dividing by the irreducible polynomial.
// In GHASH, the polynomial is such that all the terms occur in the
// least-significant 8 bits, save for the term at x^128. Therefore we can
// precompute the value to be added to the field element for each of the 16 bit
// patterns at 2**128 and the values fit within 12 bits.
static const uint16 kReductionTable[16] = {
  0x0000, 0x1c20, 0x3840, 0x2460, 0x7080, 0x6ca0, 0x48c0, 0x54e0,
  0xe100, 0xfd20, 0xd940, 0xc560, 0x9180, 0x8da0, 0xa9c0, 0xb5e0,
};

// static
void GaloisHash::Mul16(FieldElement* x) {
  const unsigned msw = x->hi & 0xf;
  x->hi >>= 4;
  x->hi |= x->low << 60;
  x->low >>= 4;
  x->low ^= static_cast<uint64>(kReductionTable[msw]) << 48;
}

void GaloisHash::UpdateBlocks(const uint8* bytes, size_t num_blocks) {
  for (size_t i = 0; i < num_blocks; i++) {
    y_.low ^= Get64(bytes);
    bytes += 8;
    y_.hi ^= Get64(bytes);
    bytes += 8;
    MulAfterPrecomputation(product_table_, &y_);
  }
}

void GaloisHash::Update(const uint8* data, size_t length) {
  if (buf_used_ > 0) {
    const size_t n = std::min(length, sizeof(buf_) - buf_used_);
    memcpy(&buf_[buf_used_], data, n);
    buf_used_ += n;
    length -= n;
    data += n;

    if (buf_used_ == sizeof(buf_)) {
      UpdateBlocks(buf_, 1);
      buf_used_ = 0;
    }
  }

  if (length >= 16) {
    const size_t n = length / 16;
    UpdateBlocks(data, n);
    length -= n*16;
    data += n*16;
  }

  if (length > 0) {
    memcpy(buf_, data, length);
    buf_used_ = length;
  }
}

}  // namespace crypto
