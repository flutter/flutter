// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This is an implementation of the P224 elliptic curve group. It's written to
// be short and simple rather than fast, although it's still constant-time.
//
// See http://www.imperialviolet.org/2010/12/04/ecc.html ([1]) for background.

#include "crypto/p224.h"

#include <string.h>

#include "base/sys_byteorder.h"

namespace {

using base::HostToNet32;
using base::NetToHost32;

// Field element functions.
//
// The field that we're dealing with is ℤ/pℤ where p = 2**224 - 2**96 + 1.
//
// Field elements are represented by a FieldElement, which is a typedef to an
// array of 8 uint32's. The value of a FieldElement, a, is:
//   a[0] + 2**28·a[1] + 2**56·a[1] + ... + 2**196·a[7]
//
// Using 28-bit limbs means that there's only 4 bits of headroom, which is less
// than we would really like. But it has the useful feature that we hit 2**224
// exactly, making the reflections during a reduce much nicer.

using crypto::p224::FieldElement;

// kP is the P224 prime.
const FieldElement kP = {
  1, 0, 0, 268431360,
  268435455, 268435455, 268435455, 268435455,
};

void Contract(FieldElement* inout);

// IsZero returns 0xffffffff if a == 0 mod p and 0 otherwise.
uint32 IsZero(const FieldElement& a) {
  FieldElement minimal;
  memcpy(&minimal, &a, sizeof(minimal));
  Contract(&minimal);

  uint32 is_zero = 0, is_p = 0;
  for (unsigned i = 0; i < 8; i++) {
    is_zero |= minimal[i];
    is_p |= minimal[i] - kP[i];
  }

  // If either is_zero or is_p is 0, then we should return 1.
  is_zero |= is_zero >> 16;
  is_zero |= is_zero >> 8;
  is_zero |= is_zero >> 4;
  is_zero |= is_zero >> 2;
  is_zero |= is_zero >> 1;

  is_p |= is_p >> 16;
  is_p |= is_p >> 8;
  is_p |= is_p >> 4;
  is_p |= is_p >> 2;
  is_p |= is_p >> 1;

  // For is_zero and is_p, the LSB is 0 iff all the bits are zero.
  is_zero &= is_p & 1;
  is_zero = (~is_zero) << 31;
  is_zero = static_cast<int32>(is_zero) >> 31;
  return is_zero;
}

// Add computes *out = a+b
//
// a[i] + b[i] < 2**32
void Add(FieldElement* out, const FieldElement& a, const FieldElement& b) {
  for (int i = 0; i < 8; i++) {
    (*out)[i] = a[i] + b[i];
  }
}

static const uint32 kTwo31p3 = (1u<<31) + (1u<<3);
static const uint32 kTwo31m3 = (1u<<31) - (1u<<3);
static const uint32 kTwo31m15m3 = (1u<<31) - (1u<<15) - (1u<<3);
// kZero31ModP is 0 mod p where bit 31 is set in all limbs so that we can
// subtract smaller amounts without underflow. See the section "Subtraction" in
// [1] for why.
static const FieldElement kZero31ModP = {
  kTwo31p3, kTwo31m3, kTwo31m3, kTwo31m15m3,
  kTwo31m3, kTwo31m3, kTwo31m3, kTwo31m3
};

// Subtract computes *out = a-b
//
// a[i], b[i] < 2**30
// out[i] < 2**32
void Subtract(FieldElement* out, const FieldElement& a, const FieldElement& b) {
  for (int i = 0; i < 8; i++) {
    // See the section on "Subtraction" in [1] for details.
    (*out)[i] = a[i] + kZero31ModP[i] - b[i];
  }
}

static const uint64 kTwo63p35 = (1ull<<63) + (1ull<<35);
static const uint64 kTwo63m35 = (1ull<<63) - (1ull<<35);
static const uint64 kTwo63m35m19 = (1ull<<63) - (1ull<<35) - (1ull<<19);
// kZero63ModP is 0 mod p where bit 63 is set in all limbs. See the section
// "Subtraction" in [1] for why.
static const uint64 kZero63ModP[8] = {
  kTwo63p35, kTwo63m35, kTwo63m35, kTwo63m35,
  kTwo63m35m19, kTwo63m35, kTwo63m35, kTwo63m35,
};

static const uint32 kBottom28Bits = 0xfffffff;

// LargeFieldElement also represents an element of the field. The limbs are
// still spaced 28-bits apart and in little-endian order. So the limbs are at
// 0, 28, 56, ..., 392 bits, each 64-bits wide.
typedef uint64 LargeFieldElement[15];

// ReduceLarge converts a LargeFieldElement to a FieldElement.
//
// in[i] < 2**62

// GCC 4.9 incorrectly vectorizes the first coefficient elimination loop, so
// disable that optimization via pragma. Don't use the pragma under Clang, since
// clang doesn't understand it.
// TODO(wez): Remove this when crbug.com/439566 is fixed.
#if defined(__GNUC__) && !defined(__clang__)
#pragma GCC optimize("no-tree-vectorize")
#endif

void ReduceLarge(FieldElement* out, LargeFieldElement* inptr) {
  LargeFieldElement& in(*inptr);

  for (int i = 0; i < 8; i++) {
    in[i] += kZero63ModP[i];
  }

  // Eliminate the coefficients at 2**224 and greater while maintaining the
  // same value mod p.
  for (int i = 14; i >= 8; i--) {
    in[i-8] -= in[i];  // reflection off the "+1" term of p.
    in[i-5] += (in[i] & 0xffff) << 12;  // part of the "-2**96" reflection.
    in[i-4] += in[i] >> 16;  // the rest of the "-2**96" reflection.
  }
  in[8] = 0;
  // in[0..8] < 2**64

  // As the values become small enough, we start to store them in |out| and use
  // 32-bit operations.
  for (int i = 1; i < 8; i++) {
    in[i+1] += in[i] >> 28;
    (*out)[i] = static_cast<uint32>(in[i] & kBottom28Bits);
  }
  // Eliminate the term at 2*224 that we introduced while keeping the same
  // value mod p.
  in[0] -= in[8];  // reflection off the "+1" term of p.
  (*out)[3] += static_cast<uint32>(in[8] & 0xffff) << 12;  // "-2**96" term
  (*out)[4] += static_cast<uint32>(in[8] >> 16);  // rest of "-2**96" term
  // in[0] < 2**64
  // out[3] < 2**29
  // out[4] < 2**29
  // out[1,2,5..7] < 2**28

  (*out)[0] = static_cast<uint32>(in[0] & kBottom28Bits);
  (*out)[1] += static_cast<uint32>((in[0] >> 28) & kBottom28Bits);
  (*out)[2] += static_cast<uint32>(in[0] >> 56);
  // out[0] < 2**28
  // out[1..4] < 2**29
  // out[5..7] < 2**28
}

// TODO(wez): Remove this when crbug.com/439566 is fixed.
#if defined(__GNUC__) && !defined(__clang__)
// Reenable "tree-vectorize" optimization if it got disabled for ReduceLarge.
#pragma GCC reset_options
#endif

// Mul computes *out = a*b
//
// a[i] < 2**29, b[i] < 2**30 (or vice versa)
// out[i] < 2**29
void Mul(FieldElement* out, const FieldElement& a, const FieldElement& b) {
  LargeFieldElement tmp;
  memset(&tmp, 0, sizeof(tmp));

  for (int i = 0; i < 8; i++) {
    for (int j = 0; j < 8; j++) {
      tmp[i+j] += static_cast<uint64>(a[i]) * static_cast<uint64>(b[j]);
    }
  }

  ReduceLarge(out, &tmp);
}

// Square computes *out = a*a
//
// a[i] < 2**29
// out[i] < 2**29
void Square(FieldElement* out, const FieldElement& a) {
  LargeFieldElement tmp;
  memset(&tmp, 0, sizeof(tmp));

  for (int i = 0; i < 8; i++) {
    for (int j = 0; j <= i; j++) {
      uint64 r = static_cast<uint64>(a[i]) * static_cast<uint64>(a[j]);
      if (i == j) {
        tmp[i+j] += r;
      } else {
        tmp[i+j] += r << 1;
      }
    }
  }

  ReduceLarge(out, &tmp);
}

// Reduce reduces the coefficients of in_out to smaller bounds.
//
// On entry: a[i] < 2**31 + 2**30
// On exit: a[i] < 2**29
void Reduce(FieldElement* in_out) {
  FieldElement& a = *in_out;

  for (int i = 0; i < 7; i++) {
    a[i+1] += a[i] >> 28;
    a[i] &= kBottom28Bits;
  }
  uint32 top = a[7] >> 28;
  a[7] &= kBottom28Bits;

  // top < 2**4
  // Constant-time: mask = (top != 0) ? 0xffffffff : 0
  uint32 mask = top;
  mask |= mask >> 2;
  mask |= mask >> 1;
  mask <<= 31;
  mask = static_cast<uint32>(static_cast<int32>(mask) >> 31);

  // Eliminate top while maintaining the same value mod p.
  a[0] -= top;
  a[3] += top << 12;

  // We may have just made a[0] negative but, if we did, then we must
  // have added something to a[3], thus it's > 2**12. Therefore we can
  // carry down to a[0].
  a[3] -= 1 & mask;
  a[2] += mask & ((1<<28) - 1);
  a[1] += mask & ((1<<28) - 1);
  a[0] += mask & (1<<28);
}

// Invert calcuates *out = in**-1 by computing in**(2**224 - 2**96 - 1), i.e.
// Fermat's little theorem.
void Invert(FieldElement* out, const FieldElement& in) {
  FieldElement f1, f2, f3, f4;

  Square(&f1, in);                        // 2
  Mul(&f1, f1, in);                       // 2**2 - 1
  Square(&f1, f1);                        // 2**3 - 2
  Mul(&f1, f1, in);                       // 2**3 - 1
  Square(&f2, f1);                        // 2**4 - 2
  Square(&f2, f2);                        // 2**5 - 4
  Square(&f2, f2);                        // 2**6 - 8
  Mul(&f1, f1, f2);                       // 2**6 - 1
  Square(&f2, f1);                        // 2**7 - 2
  for (int i = 0; i < 5; i++) {           // 2**12 - 2**6
    Square(&f2, f2);
  }
  Mul(&f2, f2, f1);                       // 2**12 - 1
  Square(&f3, f2);                        // 2**13 - 2
  for (int i = 0; i < 11; i++) {          // 2**24 - 2**12
    Square(&f3, f3);
  }
  Mul(&f2, f3, f2);                       // 2**24 - 1
  Square(&f3, f2);                        // 2**25 - 2
  for (int i = 0; i < 23; i++) {          // 2**48 - 2**24
    Square(&f3, f3);
  }
  Mul(&f3, f3, f2);                       // 2**48 - 1
  Square(&f4, f3);                        // 2**49 - 2
  for (int i = 0; i < 47; i++) {          // 2**96 - 2**48
    Square(&f4, f4);
  }
  Mul(&f3, f3, f4);                       // 2**96 - 1
  Square(&f4, f3);                        // 2**97 - 2
  for (int i = 0; i < 23; i++) {          // 2**120 - 2**24
    Square(&f4, f4);
  }
  Mul(&f2, f4, f2);                       // 2**120 - 1
  for (int i = 0; i < 6; i++) {           // 2**126 - 2**6
    Square(&f2, f2);
  }
  Mul(&f1, f1, f2);                       // 2**126 - 1
  Square(&f1, f1);                        // 2**127 - 2
  Mul(&f1, f1, in);                       // 2**127 - 1
  for (int i = 0; i < 97; i++) {          // 2**224 - 2**97
    Square(&f1, f1);
  }
  Mul(out, f1, f3);                       // 2**224 - 2**96 - 1
}

// Contract converts a FieldElement to its minimal, distinguished form.
//
// On entry, in[i] < 2**29
// On exit, in[i] < 2**28
void Contract(FieldElement* inout) {
  FieldElement& out = *inout;

  // Reduce the coefficients to < 2**28.
  for (int i = 0; i < 7; i++) {
    out[i+1] += out[i] >> 28;
    out[i] &= kBottom28Bits;
  }
  uint32 top = out[7] >> 28;
  out[7] &= kBottom28Bits;

  // Eliminate top while maintaining the same value mod p.
  out[0] -= top;
  out[3] += top << 12;

  // We may just have made out[0] negative. So we carry down. If we made
  // out[0] negative then we know that out[3] is sufficiently positive
  // because we just added to it.
  for (int i = 0; i < 3; i++) {
    uint32 mask = static_cast<uint32>(static_cast<int32>(out[i]) >> 31);
    out[i] += (1 << 28) & mask;
    out[i+1] -= 1 & mask;
  }

  // We might have pushed out[3] over 2**28 so we perform another, partial
  // carry chain.
  for (int i = 3; i < 7; i++) {
    out[i+1] += out[i] >> 28;
    out[i] &= kBottom28Bits;
  }
  top = out[7] >> 28;
  out[7] &= kBottom28Bits;

  // Eliminate top while maintaining the same value mod p.
  out[0] -= top;
  out[3] += top << 12;

  // There are two cases to consider for out[3]:
  //   1) The first time that we eliminated top, we didn't push out[3] over
  //      2**28. In this case, the partial carry chain didn't change any values
  //      and top is zero.
  //   2) We did push out[3] over 2**28 the first time that we eliminated top.
  //      The first value of top was in [0..16), therefore, prior to eliminating
  //      the first top, 0xfff1000 <= out[3] <= 0xfffffff. Therefore, after
  //      overflowing and being reduced by the second carry chain, out[3] <=
  //      0xf000. Thus it cannot have overflowed when we eliminated top for the
  //      second time.

  // Again, we may just have made out[0] negative, so do the same carry down.
  // As before, if we made out[0] negative then we know that out[3] is
  // sufficiently positive.
  for (int i = 0; i < 3; i++) {
    uint32 mask = static_cast<uint32>(static_cast<int32>(out[i]) >> 31);
    out[i] += (1 << 28) & mask;
    out[i+1] -= 1 & mask;
  }

  // The value is < 2**224, but maybe greater than p. In order to reduce to a
  // unique, minimal value we see if the value is >= p and, if so, subtract p.

  // First we build a mask from the top four limbs, which must all be
  // equal to bottom28Bits if the whole value is >= p. If top_4_all_ones
  // ends up with any zero bits in the bottom 28 bits, then this wasn't
  // true.
  uint32 top_4_all_ones = 0xffffffffu;
  for (int i = 4; i < 8; i++) {
    top_4_all_ones &= out[i];
  }
  top_4_all_ones |= 0xf0000000;
  // Now we replicate any zero bits to all the bits in top_4_all_ones.
  top_4_all_ones &= top_4_all_ones >> 16;
  top_4_all_ones &= top_4_all_ones >> 8;
  top_4_all_ones &= top_4_all_ones >> 4;
  top_4_all_ones &= top_4_all_ones >> 2;
  top_4_all_ones &= top_4_all_ones >> 1;
  top_4_all_ones =
      static_cast<uint32>(static_cast<int32>(top_4_all_ones << 31) >> 31);

  // Now we test whether the bottom three limbs are non-zero.
  uint32 bottom_3_non_zero = out[0] | out[1] | out[2];
  bottom_3_non_zero |= bottom_3_non_zero >> 16;
  bottom_3_non_zero |= bottom_3_non_zero >> 8;
  bottom_3_non_zero |= bottom_3_non_zero >> 4;
  bottom_3_non_zero |= bottom_3_non_zero >> 2;
  bottom_3_non_zero |= bottom_3_non_zero >> 1;
  bottom_3_non_zero =
      static_cast<uint32>(static_cast<int32>(bottom_3_non_zero) >> 31);

  // Everything depends on the value of out[3].
  //    If it's > 0xffff000 and top_4_all_ones != 0 then the whole value is >= p
  //    If it's = 0xffff000 and top_4_all_ones != 0 and bottom_3_non_zero != 0,
  //      then the whole value is >= p
  //    If it's < 0xffff000, then the whole value is < p
  uint32 n = out[3] - 0xffff000;
  uint32 out_3_equal = n;
  out_3_equal |= out_3_equal >> 16;
  out_3_equal |= out_3_equal >> 8;
  out_3_equal |= out_3_equal >> 4;
  out_3_equal |= out_3_equal >> 2;
  out_3_equal |= out_3_equal >> 1;
  out_3_equal =
      ~static_cast<uint32>(static_cast<int32>(out_3_equal << 31) >> 31);

  // If out[3] > 0xffff000 then n's MSB will be zero.
  uint32 out_3_gt = ~static_cast<uint32>(static_cast<int32>(n << 31) >> 31);

  uint32 mask = top_4_all_ones & ((out_3_equal & bottom_3_non_zero) | out_3_gt);
  out[0] -= 1 & mask;
  out[3] -= 0xffff000 & mask;
  out[4] -= 0xfffffff & mask;
  out[5] -= 0xfffffff & mask;
  out[6] -= 0xfffffff & mask;
  out[7] -= 0xfffffff & mask;
}


// Group element functions.
//
// These functions deal with group elements. The group is an elliptic curve
// group with a = -3 defined in FIPS 186-3, section D.2.2.

using crypto::p224::Point;

// kB is parameter of the elliptic curve.
const FieldElement kB = {
  55967668, 11768882, 265861671, 185302395,
  39211076, 180311059, 84673715, 188764328,
};

void CopyConditional(Point* out, const Point& a, uint32 mask);
void DoubleJacobian(Point* out, const Point& a);

// AddJacobian computes *out = a+b where a != b.
void AddJacobian(Point *out,
                 const Point& a,
                 const Point& b) {
  // See http://hyperelliptic.org/EFD/g1p/auto-shortw-jacobian-3.html#addition-add-2007-bl
  FieldElement z1z1, z2z2, u1, u2, s1, s2, h, i, j, r, v;

  uint32 z1_is_zero = IsZero(a.z);
  uint32 z2_is_zero = IsZero(b.z);

  // Z1Z1 = Z1²
  Square(&z1z1, a.z);

  // Z2Z2 = Z2²
  Square(&z2z2, b.z);

  // U1 = X1*Z2Z2
  Mul(&u1, a.x, z2z2);

  // U2 = X2*Z1Z1
  Mul(&u2, b.x, z1z1);

  // S1 = Y1*Z2*Z2Z2
  Mul(&s1, b.z, z2z2);
  Mul(&s1, a.y, s1);

  // S2 = Y2*Z1*Z1Z1
  Mul(&s2, a.z, z1z1);
  Mul(&s2, b.y, s2);

  // H = U2-U1
  Subtract(&h, u2, u1);
  Reduce(&h);
  uint32 x_equal = IsZero(h);

  // I = (2*H)²
  for (int k = 0; k < 8; k++) {
    i[k] = h[k] << 1;
  }
  Reduce(&i);
  Square(&i, i);

  // J = H*I
  Mul(&j, h, i);
  // r = 2*(S2-S1)
  Subtract(&r, s2, s1);
  Reduce(&r);
  uint32 y_equal = IsZero(r);

  if (x_equal && y_equal && !z1_is_zero && !z2_is_zero) {
    // The two input points are the same therefore we must use the dedicated
    // doubling function as the slope of the line is undefined.
    DoubleJacobian(out, a);
    return;
  }

  for (int k = 0; k < 8; k++) {
    r[k] <<= 1;
  }
  Reduce(&r);

  // V = U1*I
  Mul(&v, u1, i);

  // Z3 = ((Z1+Z2)²-Z1Z1-Z2Z2)*H
  Add(&z1z1, z1z1, z2z2);
  Add(&z2z2, a.z, b.z);
  Reduce(&z2z2);
  Square(&z2z2, z2z2);
  Subtract(&out->z, z2z2, z1z1);
  Reduce(&out->z);
  Mul(&out->z, out->z, h);

  // X3 = r²-J-2*V
  for (int k = 0; k < 8; k++) {
    z1z1[k] = v[k] << 1;
  }
  Add(&z1z1, j, z1z1);
  Reduce(&z1z1);
  Square(&out->x, r);
  Subtract(&out->x, out->x, z1z1);
  Reduce(&out->x);

  // Y3 = r*(V-X3)-2*S1*J
  for (int k = 0; k < 8; k++) {
    s1[k] <<= 1;
  }
  Mul(&s1, s1, j);
  Subtract(&z1z1, v, out->x);
  Reduce(&z1z1);
  Mul(&z1z1, z1z1, r);
  Subtract(&out->y, z1z1, s1);
  Reduce(&out->y);

  CopyConditional(out, a, z2_is_zero);
  CopyConditional(out, b, z1_is_zero);
}

// DoubleJacobian computes *out = a+a.
void DoubleJacobian(Point* out, const Point& a) {
  // See http://hyperelliptic.org/EFD/g1p/auto-shortw-jacobian-3.html#doubling-dbl-2001-b
  FieldElement delta, gamma, beta, alpha, t;

  Square(&delta, a.z);
  Square(&gamma, a.y);
  Mul(&beta, a.x, gamma);

  // alpha = 3*(X1-delta)*(X1+delta)
  Add(&t, a.x, delta);
  for (int i = 0; i < 8; i++) {
          t[i] += t[i] << 1;
  }
  Reduce(&t);
  Subtract(&alpha, a.x, delta);
  Reduce(&alpha);
  Mul(&alpha, alpha, t);

  // Z3 = (Y1+Z1)²-gamma-delta
  Add(&out->z, a.y, a.z);
  Reduce(&out->z);
  Square(&out->z, out->z);
  Subtract(&out->z, out->z, gamma);
  Reduce(&out->z);
  Subtract(&out->z, out->z, delta);
  Reduce(&out->z);

  // X3 = alpha²-8*beta
  for (int i = 0; i < 8; i++) {
          delta[i] = beta[i] << 3;
  }
  Reduce(&delta);
  Square(&out->x, alpha);
  Subtract(&out->x, out->x, delta);
  Reduce(&out->x);

  // Y3 = alpha*(4*beta-X3)-8*gamma²
  for (int i = 0; i < 8; i++) {
          beta[i] <<= 2;
  }
  Reduce(&beta);
  Subtract(&beta, beta, out->x);
  Reduce(&beta);
  Square(&gamma, gamma);
  for (int i = 0; i < 8; i++) {
          gamma[i] <<= 3;
  }
  Reduce(&gamma);
  Mul(&out->y, alpha, beta);
  Subtract(&out->y, out->y, gamma);
  Reduce(&out->y);
}

// CopyConditional sets *out=a if mask is 0xffffffff. mask must be either 0 of
// 0xffffffff.
void CopyConditional(Point* out,
                     const Point& a,
                     uint32 mask) {
  for (int i = 0; i < 8; i++) {
    out->x[i] ^= mask & (a.x[i] ^ out->x[i]);
    out->y[i] ^= mask & (a.y[i] ^ out->y[i]);
    out->z[i] ^= mask & (a.z[i] ^ out->z[i]);
  }
}

// ScalarMult calculates *out = a*scalar where scalar is a big-endian number of
// length scalar_len and != 0.
void ScalarMult(Point* out, const Point& a,
                const uint8* scalar, size_t scalar_len) {
  memset(out, 0, sizeof(*out));
  Point tmp;

  for (size_t i = 0; i < scalar_len; i++) {
    for (unsigned int bit_num = 0; bit_num < 8; bit_num++) {
      DoubleJacobian(out, *out);
      uint32 bit = static_cast<uint32>(static_cast<int32>(
          (((scalar[i] >> (7 - bit_num)) & 1) << 31) >> 31));
      AddJacobian(&tmp, a, *out);
      CopyConditional(out, tmp, bit);
    }
  }
}

// Get224Bits reads 7 words from in and scatters their contents in
// little-endian form into 8 words at out, 28 bits per output word.
void Get224Bits(uint32* out, const uint32* in) {
  out[0] = NetToHost32(in[6]) & kBottom28Bits;
  out[1] = ((NetToHost32(in[5]) << 4) |
            (NetToHost32(in[6]) >> 28)) & kBottom28Bits;
  out[2] = ((NetToHost32(in[4]) << 8) |
            (NetToHost32(in[5]) >> 24)) & kBottom28Bits;
  out[3] = ((NetToHost32(in[3]) << 12) |
            (NetToHost32(in[4]) >> 20)) & kBottom28Bits;
  out[4] = ((NetToHost32(in[2]) << 16) |
            (NetToHost32(in[3]) >> 16)) & kBottom28Bits;
  out[5] = ((NetToHost32(in[1]) << 20) |
            (NetToHost32(in[2]) >> 12)) & kBottom28Bits;
  out[6] = ((NetToHost32(in[0]) << 24) |
            (NetToHost32(in[1]) >> 8)) & kBottom28Bits;
  out[7] = (NetToHost32(in[0]) >> 4) & kBottom28Bits;
}

// Put224Bits performs the inverse operation to Get224Bits: taking 28 bits from
// each of 8 input words and writing them in big-endian order to 7 words at
// out.
void Put224Bits(uint32* out, const uint32* in) {
  out[6] = HostToNet32((in[0] >> 0) | (in[1] << 28));
  out[5] = HostToNet32((in[1] >> 4) | (in[2] << 24));
  out[4] = HostToNet32((in[2] >> 8) | (in[3] << 20));
  out[3] = HostToNet32((in[3] >> 12) | (in[4] << 16));
  out[2] = HostToNet32((in[4] >> 16) | (in[5] << 12));
  out[1] = HostToNet32((in[5] >> 20) | (in[6] << 8));
  out[0] = HostToNet32((in[6] >> 24) | (in[7] << 4));
}

}  // anonymous namespace

namespace crypto {

namespace p224 {

bool Point::SetFromString(const base::StringPiece& in) {
  if (in.size() != 2*28)
    return false;
  const uint32* inwords = reinterpret_cast<const uint32*>(in.data());
  Get224Bits(x, inwords);
  Get224Bits(y, inwords + 7);
  memset(&z, 0, sizeof(z));
  z[0] = 1;

  // Check that the point is on the curve, i.e. that y² = x³ - 3x + b.
  FieldElement lhs;
  Square(&lhs, y);
  Contract(&lhs);

  FieldElement rhs;
  Square(&rhs, x);
  Mul(&rhs, x, rhs);

  FieldElement three_x;
  for (int i = 0; i < 8; i++) {
    three_x[i] = x[i] * 3;
  }
  Reduce(&three_x);
  Subtract(&rhs, rhs, three_x);
  Reduce(&rhs);

  ::Add(&rhs, rhs, kB);
  Contract(&rhs);
  return memcmp(&lhs, &rhs, sizeof(lhs)) == 0;
}

std::string Point::ToString() const {
  FieldElement zinv, zinv_sq, xx, yy;

  // If this is the point at infinity we return a string of all zeros.
  if (IsZero(this->z)) {
    static const char zeros[56] = {0};
    return std::string(zeros, sizeof(zeros));
  }

  Invert(&zinv, this->z);
  Square(&zinv_sq, zinv);
  Mul(&xx, x, zinv_sq);
  Mul(&zinv_sq, zinv_sq, zinv);
  Mul(&yy, y, zinv_sq);

  Contract(&xx);
  Contract(&yy);

  uint32 outwords[14];
  Put224Bits(outwords, xx);
  Put224Bits(outwords + 7, yy);
  return std::string(reinterpret_cast<const char*>(outwords), sizeof(outwords));
}

void ScalarMult(const Point& in, const uint8* scalar, Point* out) {
  ::ScalarMult(out, in, scalar, 28);
}

// kBasePoint is the base point (generator) of the elliptic curve group.
static const Point kBasePoint = {
  {22813985, 52956513, 34677300, 203240812,
   12143107, 133374265, 225162431, 191946955},
  {83918388, 223877528, 122119236, 123340192,
   266784067, 263504429, 146143011, 198407736},
  {1, 0, 0, 0, 0, 0, 0, 0},
};

void ScalarBaseMult(const uint8* scalar, Point* out) {
  ::ScalarMult(out, kBasePoint, scalar, 28);
}

void Add(const Point& a, const Point& b, Point* out) {
  AddJacobian(out, a, b);
}

void Negate(const Point& in, Point* out) {
  // Guide to elliptic curve cryptography, page 89 suggests that (X : X+Y : Z)
  // is the negative in Jacobian coordinates, but it doesn't actually appear to
  // be true in testing so this performs the negation in affine coordinates.
  FieldElement zinv, zinv_sq, y;
  Invert(&zinv, in.z);
  Square(&zinv_sq, zinv);
  Mul(&out->x, in.x, zinv_sq);
  Mul(&zinv_sq, zinv_sq, zinv);
  Mul(&y, in.y, zinv_sq);

  Subtract(&out->y, kP, y);
  Reduce(&out->y);

  memset(&out->z, 0, sizeof(out->z));
  out->z[0] = 1;
}

}  // namespace p224

}  // namespace crypto
