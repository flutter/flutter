// Copyright 2010 the V8 project authors. All rights reserved.
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
//       copyright notice, this list of conditions and the following
//       disclaimer in the documentation and/or other materials provided
//       with the distribution.
//     * Neither the name of Google Inc. nor the names of its
//       contributors may be used to endorse or promote products derived
//       from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#include "flutter/sky/engine/wtf/dtoa/bignum.h"
#include "flutter/sky/engine/wtf/dtoa/utils.h"

namespace WTF {

namespace double_conversion {

Bignum::Bignum()
    : bigits_(bigits_buffer_, kBigitCapacity), used_digits_(0), exponent_(0) {
  for (int i = 0; i < kBigitCapacity; ++i) {
    bigits_[i] = 0;
  }
}

template <typename S>
static int BitSize(S value) {
  return 8 * sizeof(value);
}

// Guaranteed to lie in one Bigit.
void Bignum::AssignUInt16(uint16_t value) {
  ASSERT(kBigitSize >= BitSize(value));
  Zero();
  if (value == 0)
    return;

  EnsureCapacity(1);
  bigits_[0] = value;
  used_digits_ = 1;
}

void Bignum::AssignUInt64(uint64_t value) {
  const int kUInt64Size = 64;

  Zero();
  if (value == 0)
    return;

  int needed_bigits = kUInt64Size / kBigitSize + 1;
  EnsureCapacity(needed_bigits);
  for (int i = 0; i < needed_bigits; ++i) {
    bigits_[i] = (uint32_t)value & kBigitMask;
    value = value >> kBigitSize;
  }
  used_digits_ = needed_bigits;
  Clamp();
}

void Bignum::AssignBignum(const Bignum& other) {
  exponent_ = other.exponent_;
  for (int i = 0; i < other.used_digits_; ++i) {
    bigits_[i] = other.bigits_[i];
  }
  // Clear the excess digits (if there were any).
  for (int i = other.used_digits_; i < used_digits_; ++i) {
    bigits_[i] = 0;
  }
  used_digits_ = other.used_digits_;
}

static uint64_t ReadUInt64(Vector<const char> buffer,
                           int from,
                           int digits_to_read) {
  uint64_t result = 0;
  for (int i = from; i < from + digits_to_read; ++i) {
    int digit = buffer[i] - '0';
    ASSERT(0 <= digit && digit <= 9);
    result = result * 10 + digit;
  }
  return result;
}

void Bignum::AssignDecimalString(Vector<const char> value) {
  // 2^64 = 18446744073709551616 > 10^19
  const int kMaxUint64DecimalDigits = 19;
  Zero();
  int length = value.length();
  int pos = 0;
  // Let's just say that each digit needs 4 bits.
  while (length >= kMaxUint64DecimalDigits) {
    uint64_t digits = ReadUInt64(value, pos, kMaxUint64DecimalDigits);
    pos += kMaxUint64DecimalDigits;
    length -= kMaxUint64DecimalDigits;
    MultiplyByPowerOfTen(kMaxUint64DecimalDigits);
    AddUInt64(digits);
  }
  uint64_t digits = ReadUInt64(value, pos, length);
  MultiplyByPowerOfTen(length);
  AddUInt64(digits);
  Clamp();
}

static int HexCharValue(char c) {
  if ('0' <= c && c <= '9')
    return c - '0';
  if ('a' <= c && c <= 'f')
    return 10 + c - 'a';
  if ('A' <= c && c <= 'F')
    return 10 + c - 'A';
  UNREACHABLE();
  return 0;  // To make compiler happy.
}

void Bignum::AssignHexString(Vector<const char> value) {
  Zero();
  int length = value.length();

  int needed_bigits = length * 4 / kBigitSize + 1;
  EnsureCapacity(needed_bigits);
  int string_index = length - 1;
  for (int i = 0; i < needed_bigits - 1; ++i) {
    // These bigits are guaranteed to be "full".
    Chunk current_bigit = 0;
    for (int j = 0; j < kBigitSize / 4; j++) {
      current_bigit += HexCharValue(value[string_index--]) << (j * 4);
    }
    bigits_[i] = current_bigit;
  }
  used_digits_ = needed_bigits - 1;

  Chunk most_significant_bigit = 0;  // Could be = 0;
  for (int j = 0; j <= string_index; ++j) {
    most_significant_bigit <<= 4;
    most_significant_bigit += HexCharValue(value[j]);
  }
  if (most_significant_bigit != 0) {
    bigits_[used_digits_] = most_significant_bigit;
    used_digits_++;
  }
  Clamp();
}

void Bignum::AddUInt64(uint64_t operand) {
  if (operand == 0)
    return;
  Bignum other;
  other.AssignUInt64(operand);
  AddBignum(other);
}

void Bignum::AddBignum(const Bignum& other) {
  ASSERT(IsClamped());
  ASSERT(other.IsClamped());

  // If this has a greater exponent than other append zero-bigits to this.
  // After this call exponent_ <= other.exponent_.
  Align(other);

  // There are two possibilities:
  //   aaaaaaaaaaa 0000  (where the 0s represent a's exponent)
  //     bbbbb 00000000
  //   ----------------
  //   ccccccccccc 0000
  // or
  //    aaaaaaaaaa 0000
  //  bbbbbbbbb 0000000
  //  -----------------
  //  cccccccccccc 0000
  // In both cases we might need a carry bigit.

  EnsureCapacity(1 + Max(BigitLength(), other.BigitLength()) - exponent_);
  Chunk carry = 0;
  int bigit_pos = other.exponent_ - exponent_;
  ASSERT(bigit_pos >= 0);
  for (int i = 0; i < other.used_digits_; ++i) {
    Chunk sum = bigits_[bigit_pos] + other.bigits_[i] + carry;
    bigits_[bigit_pos] = sum & kBigitMask;
    carry = sum >> kBigitSize;
    bigit_pos++;
  }

  while (carry != 0) {
    Chunk sum = bigits_[bigit_pos] + carry;
    bigits_[bigit_pos] = sum & kBigitMask;
    carry = sum >> kBigitSize;
    bigit_pos++;
  }
  used_digits_ = Max(bigit_pos, used_digits_);
  ASSERT(IsClamped());
}

void Bignum::SubtractBignum(const Bignum& other) {
  ASSERT(IsClamped());
  ASSERT(other.IsClamped());
  // We require this to be bigger than other.
  ASSERT(LessEqual(other, *this));

  Align(other);

  int offset = other.exponent_ - exponent_;
  Chunk borrow = 0;
  int i;
  for (i = 0; i < other.used_digits_; ++i) {
    ASSERT((borrow == 0) || (borrow == 1));
    Chunk difference = bigits_[i + offset] - other.bigits_[i] - borrow;
    bigits_[i + offset] = difference & kBigitMask;
    borrow = difference >> (kChunkSize - 1);
  }
  while (borrow != 0) {
    Chunk difference = bigits_[i + offset] - borrow;
    bigits_[i + offset] = difference & kBigitMask;
    borrow = difference >> (kChunkSize - 1);
    ++i;
  }
  Clamp();
}

void Bignum::Shifxleft(int shift_amount) {
  if (used_digits_ == 0)
    return;
  exponent_ += shift_amount / kBigitSize;
  int local_shift = shift_amount % kBigitSize;
  EnsureCapacity(used_digits_ + 1);
  BigitsShifxleft(local_shift);
}

void Bignum::MultiplyByUInt32(uint32_t factor) {
  if (factor == 1)
    return;
  if (factor == 0) {
    Zero();
    return;
  }
  if (used_digits_ == 0)
    return;

  // The product of a bigit with the factor is of size kBigitSize + 32.
  // Assert that this number + 1 (for the carry) fits into double chunk.
  ASSERT(kDoubleChunkSize >= kBigitSize + 32 + 1);
  DoubleChunk carry = 0;
  for (int i = 0; i < used_digits_; ++i) {
    DoubleChunk product = static_cast<DoubleChunk>(factor) * bigits_[i] + carry;
    bigits_[i] = static_cast<Chunk>(product & kBigitMask);
    carry = (product >> kBigitSize);
  }
  while (carry != 0) {
    EnsureCapacity(used_digits_ + 1);
    bigits_[used_digits_] = (uint32_t)carry & kBigitMask;
    used_digits_++;
    carry >>= kBigitSize;
  }
}

void Bignum::MultiplyByUInt64(uint64_t factor) {
  if (factor == 1)
    return;
  if (factor == 0) {
    Zero();
    return;
  }
  ASSERT(kBigitSize < 32);
  uint64_t carry = 0;
  uint64_t low = factor & 0xFFFFFFFF;
  uint64_t high = factor >> 32;
  for (int i = 0; i < used_digits_; ++i) {
    uint64_t product_low = low * bigits_[i];
    uint64_t product_high = high * bigits_[i];
    uint64_t tmp = (carry & kBigitMask) + product_low;
    bigits_[i] = (uint32_t)tmp & kBigitMask;
    carry = (carry >> kBigitSize) + (tmp >> kBigitSize) +
            (product_high << (32 - kBigitSize));
  }
  while (carry != 0) {
    EnsureCapacity(used_digits_ + 1);
    bigits_[used_digits_] = (uint32_t)carry & kBigitMask;
    used_digits_++;
    carry >>= kBigitSize;
  }
}

void Bignum::MultiplyByPowerOfTen(int exponent) {
  const uint64_t kFive27 = UINT64_2PART_C(0x6765c793, fa10079d);
  const uint16_t kFive1 = 5;
  const uint16_t kFive2 = kFive1 * 5;
  const uint16_t kFive3 = kFive2 * 5;
  const uint16_t kFive4 = kFive3 * 5;
  const uint16_t kFive5 = kFive4 * 5;
  const uint16_t kFive6 = kFive5 * 5;
  const uint32_t kFive7 = kFive6 * 5;
  const uint32_t kFive8 = kFive7 * 5;
  const uint32_t kFive9 = kFive8 * 5;
  const uint32_t kFive10 = kFive9 * 5;
  const uint32_t kFive11 = kFive10 * 5;
  const uint32_t kFive12 = kFive11 * 5;
  const uint32_t kFive13 = kFive12 * 5;
  const uint32_t kFive1_to_12[] = {kFive1, kFive2,  kFive3,  kFive4,
                                   kFive5, kFive6,  kFive7,  kFive8,
                                   kFive9, kFive10, kFive11, kFive12};

  ASSERT(exponent >= 0);
  if (exponent == 0)
    return;
  if (used_digits_ == 0)
    return;

  // We shift by exponent at the end just before returning.
  int remaining_exponent = exponent;
  while (remaining_exponent >= 27) {
    MultiplyByUInt64(kFive27);
    remaining_exponent -= 27;
  }
  while (remaining_exponent >= 13) {
    MultiplyByUInt32(kFive13);
    remaining_exponent -= 13;
  }
  if (remaining_exponent > 0) {
    MultiplyByUInt32(kFive1_to_12[remaining_exponent - 1]);
  }
  Shifxleft(exponent);
}

void Bignum::Square() {
  ASSERT(IsClamped());
  int product_length = 2 * used_digits_;
  EnsureCapacity(product_length);

  // Comba multiplication: compute each column separately.
  // Example: r = a2a1a0 * b2b1b0.
  //    r =  1    * a0b0 +
  //        10    * (a1b0 + a0b1) +
  //        100   * (a2b0 + a1b1 + a0b2) +
  //        1000  * (a2b1 + a1b2) +
  //        10000 * a2b2
  //
  // In the worst case we have to accumulate nb-digits products of digit*digit.
  //
  // Assert that the additional number of bits in a DoubleChunk are enough to
  // sum up used_digits of Bigit*Bigit.
  if ((1 << (2 * (kChunkSize - kBigitSize))) <= used_digits_) {
    UNIMPLEMENTED();
  }
  DoubleChunk accumulator = 0;
  // First shift the digits so we don't overwrite them.
  int copy_offset = used_digits_;
  for (int i = 0; i < used_digits_; ++i) {
    bigits_[copy_offset + i] = bigits_[i];
  }
  // We have two loops to avoid some 'if's in the loop.
  for (int i = 0; i < used_digits_; ++i) {
    // Process temporary digit i with power i.
    // The sum of the two indices must be equal to i.
    int bigit_index1 = i;
    int bigit_index2 = 0;
    // Sum all of the sub-products.
    while (bigit_index1 >= 0) {
      Chunk chunk1 = bigits_[copy_offset + bigit_index1];
      Chunk chunk2 = bigits_[copy_offset + bigit_index2];
      accumulator += static_cast<DoubleChunk>(chunk1) * chunk2;
      bigit_index1--;
      bigit_index2++;
    }
    bigits_[i] = static_cast<Chunk>(accumulator) & kBigitMask;
    accumulator >>= kBigitSize;
  }
  for (int i = used_digits_; i < product_length; ++i) {
    int bigit_index1 = used_digits_ - 1;
    int bigit_index2 = i - bigit_index1;
    // Invariant: sum of both indices is again equal to i.
    // Inner loop runs 0 times on last iteration, emptying accumulator.
    while (bigit_index2 < used_digits_) {
      Chunk chunk1 = bigits_[copy_offset + bigit_index1];
      Chunk chunk2 = bigits_[copy_offset + bigit_index2];
      accumulator += static_cast<DoubleChunk>(chunk1) * chunk2;
      bigit_index1--;
      bigit_index2++;
    }
    // The overwritten bigits_[i] will never be read in further loop iterations,
    // because bigit_index1 and bigit_index2 are always greater
    // than i - used_digits_.
    bigits_[i] = static_cast<Chunk>(accumulator) & kBigitMask;
    accumulator >>= kBigitSize;
  }
  // Since the result was guaranteed to lie inside the number the
  // accumulator must be 0 now.
  ASSERT(accumulator == 0);

  // Don't forget to update the used_digits and the exponent.
  used_digits_ = product_length;
  exponent_ *= 2;
  Clamp();
}

void Bignum::AssignPowerUInt16(uint16_t base, int power_exponent) {
  ASSERT(base != 0);
  ASSERT(power_exponent >= 0);
  if (power_exponent == 0) {
    AssignUInt16(1);
    return;
  }
  Zero();
  int shifts = 0;
  // We expect base to be in range 2-32, and most often to be 10.
  // It does not make much sense to implement different algorithms for counting
  // the bits.
  while ((base & 1) == 0) {
    base >>= 1;
    shifts++;
  }
  int bit_size = 0;
  int tmp_base = base;
  while (tmp_base != 0) {
    tmp_base >>= 1;
    bit_size++;
  }
  int final_size = bit_size * power_exponent;
  // 1 extra bigit for the shifting, and one for rounded final_size.
  EnsureCapacity(final_size / kBigitSize + 2);

  // Left to Right exponentiation.
  int mask = 1;
  while (power_exponent >= mask)
    mask <<= 1;

  // The mask is now pointing to the bit above the most significant 1-bit of
  // power_exponent.
  // Get rid of first 1-bit;
  mask >>= 2;
  uint64_t this_value = base;

  bool delayed_multipliciation = false;
  const uint64_t max_32bits = 0xFFFFFFFF;
  while (mask != 0 && this_value <= max_32bits) {
    this_value = this_value * this_value;
    // Verify that there is enough space in this_value to perform the
    // multiplication.  The first bit_size bits must be 0.
    if ((power_exponent & mask) != 0) {
      uint64_t base_bits_mask =
          ~((static_cast<uint64_t>(1) << (64 - bit_size)) - 1);
      bool high_bits_zero = (this_value & base_bits_mask) == 0;
      if (high_bits_zero) {
        this_value *= base;
      } else {
        delayed_multipliciation = true;
      }
    }
    mask >>= 1;
  }
  AssignUInt64(this_value);
  if (delayed_multipliciation) {
    MultiplyByUInt32(base);
  }

  // Now do the same thing as a bignum.
  while (mask != 0) {
    Square();
    if ((power_exponent & mask) != 0) {
      MultiplyByUInt32(base);
    }
    mask >>= 1;
  }

  // And finally add the saved shifts.
  Shifxleft(shifts * power_exponent);
}

// Precondition: this/other < 16bit.
uint16_t Bignum::DivideModuloIntBignum(const Bignum& other) {
  ASSERT(IsClamped());
  ASSERT(other.IsClamped());
  ASSERT(other.used_digits_ > 0);

  // Easy case: if we have less digits than the divisor than the result is 0.
  // Note: this handles the case where this == 0, too.
  if (BigitLength() < other.BigitLength()) {
    return 0;
  }

  Align(other);

  uint16_t result = 0;

  // Start by removing multiples of 'other' until both numbers have the same
  // number of digits.
  while (BigitLength() > other.BigitLength()) {
    // This naive approach is extremely inefficient if the this divided other
    // might be big. This function is implemented for doubleToString where
    // the result should be small (less than 10).
    ASSERT(other.bigits_[other.used_digits_ - 1] >= ((1 << kBigitSize) / 16));
    // Remove the multiples of the first digit.
    // Example this = 23 and other equals 9. -> Remove 2 multiples.
    result += bigits_[used_digits_ - 1];
    SubtractTimes(other, bigits_[used_digits_ - 1]);
  }

  ASSERT(BigitLength() == other.BigitLength());

  // Both bignums are at the same length now.
  // Since other has more than 0 digits we know that the access to
  // bigits_[used_digits_ - 1] is safe.
  Chunk this_bigit = bigits_[used_digits_ - 1];
  Chunk other_bigit = other.bigits_[other.used_digits_ - 1];

  if (other.used_digits_ == 1) {
    // Shortcut for easy (and common) case.
    int quotient = this_bigit / other_bigit;
    bigits_[used_digits_ - 1] = this_bigit - other_bigit * quotient;
    result += quotient;
    Clamp();
    return result;
  }

  int division_estimate = this_bigit / (other_bigit + 1);
  result += division_estimate;
  SubtractTimes(other, division_estimate);

  if (other_bigit * (division_estimate + 1) > this_bigit) {
    // No need to even try to subtract. Even if other's remaining digits were 0
    // another subtraction would be too much.
    return result;
  }

  while (LessEqual(other, *this)) {
    SubtractBignum(other);
    result++;
  }
  return result;
}

template <typename S>
static int SizeInHexChars(S number) {
  ASSERT(number > 0);
  int result = 0;
  while (number != 0) {
    number >>= 4;
    result++;
  }
  return result;
}

static char HexCharOfValue(int value) {
  ASSERT(0 <= value && value <= 16);
  if (value < 10)
    return value + '0';
  return value - 10 + 'A';
}

bool Bignum::ToHexString(char* buffer, int buffer_size) const {
  ASSERT(IsClamped());
  // Each bigit must be printable as separate hex-character.
  ASSERT(kBigitSize % 4 == 0);
  const int kHexCharsPerBigit = kBigitSize / 4;

  if (used_digits_ == 0) {
    if (buffer_size < 2)
      return false;
    buffer[0] = '0';
    buffer[1] = '\0';
    return true;
  }
  // We add 1 for the terminating '\0' character.
  int needed_chars = (BigitLength() - 1) * kHexCharsPerBigit +
                     SizeInHexChars(bigits_[used_digits_ - 1]) + 1;
  if (needed_chars > buffer_size)
    return false;
  int string_index = needed_chars - 1;
  buffer[string_index--] = '\0';
  for (int i = 0; i < exponent_; ++i) {
    for (int j = 0; j < kHexCharsPerBigit; ++j) {
      buffer[string_index--] = '0';
    }
  }
  for (int i = 0; i < used_digits_ - 1; ++i) {
    Chunk current_bigit = bigits_[i];
    for (int j = 0; j < kHexCharsPerBigit; ++j) {
      buffer[string_index--] = HexCharOfValue(current_bigit & 0xF);
      current_bigit >>= 4;
    }
  }
  // And finally the last bigit.
  Chunk most_significant_bigit = bigits_[used_digits_ - 1];
  while (most_significant_bigit != 0) {
    buffer[string_index--] = HexCharOfValue(most_significant_bigit & 0xF);
    most_significant_bigit >>= 4;
  }
  return true;
}

Bignum::Chunk Bignum::BigitAt(int index) const {
  if (index >= BigitLength())
    return 0;
  if (index < exponent_)
    return 0;
  return bigits_[index - exponent_];
}

int Bignum::Compare(const Bignum& a, const Bignum& b) {
  ASSERT(a.IsClamped());
  ASSERT(b.IsClamped());
  int bigit_length_a = a.BigitLength();
  int bigit_length_b = b.BigitLength();
  if (bigit_length_a < bigit_length_b)
    return -1;
  if (bigit_length_a > bigit_length_b)
    return +1;
  for (int i = bigit_length_a - 1; i >= Min(a.exponent_, b.exponent_); --i) {
    Chunk bigit_a = a.BigitAt(i);
    Chunk bigit_b = b.BigitAt(i);
    if (bigit_a < bigit_b)
      return -1;
    if (bigit_a > bigit_b)
      return +1;
    // Otherwise they are equal up to this digit. Try the next digit.
  }
  return 0;
}

int Bignum::PlusCompare(const Bignum& a, const Bignum& b, const Bignum& c) {
  ASSERT(a.IsClamped());
  ASSERT(b.IsClamped());
  ASSERT(c.IsClamped());
  if (a.BigitLength() < b.BigitLength()) {
    return PlusCompare(b, a, c);
  }
  if (a.BigitLength() + 1 < c.BigitLength())
    return -1;
  if (a.BigitLength() > c.BigitLength())
    return +1;
  // The exponent encodes 0-bigits. So if there are more 0-digits in 'a' than
  // 'b' has digits, then the bigit-length of 'a'+'b' must be equal to the one
  // of 'a'.
  if (a.exponent_ >= b.BigitLength() && a.BigitLength() < c.BigitLength()) {
    return -1;
  }

  Chunk borrow = 0;
  // Starting at min_exponent all digits are == 0. So no need to compare them.
  int min_exponent = Min(Min(a.exponent_, b.exponent_), c.exponent_);
  for (int i = c.BigitLength() - 1; i >= min_exponent; --i) {
    Chunk chunk_a = a.BigitAt(i);
    Chunk chunk_b = b.BigitAt(i);
    Chunk chunk_c = c.BigitAt(i);
    Chunk sum = chunk_a + chunk_b;
    if (sum > chunk_c + borrow) {
      return +1;
    } else {
      borrow = chunk_c + borrow - sum;
      if (borrow > 1)
        return -1;
      borrow <<= kBigitSize;
    }
  }
  if (borrow == 0)
    return 0;
  return -1;
}

void Bignum::Clamp() {
  while (used_digits_ > 0 && bigits_[used_digits_ - 1] == 0) {
    used_digits_--;
  }
  if (used_digits_ == 0) {
    // Zero.
    exponent_ = 0;
  }
}

bool Bignum::IsClamped() const {
  return used_digits_ == 0 || bigits_[used_digits_ - 1] != 0;
}

void Bignum::Zero() {
  for (int i = 0; i < used_digits_; ++i) {
    bigits_[i] = 0;
  }
  used_digits_ = 0;
  exponent_ = 0;
}

void Bignum::Align(const Bignum& other) {
  if (exponent_ > other.exponent_) {
    // If "X" represents a "hidden" digit (by the exponent) then we are in the
    // following case (a == this, b == other):
    // a:  aaaaaaXXXX   or a:   aaaaaXXX
    // b:     bbbbbbX      b: bbbbbbbbXX
    // We replace some of the hidden digits (X) of a with 0 digits.
    // a:  aaaaaa000X   or a:   aaaaa0XX
    int zero_digits = exponent_ - other.exponent_;
    EnsureCapacity(used_digits_ + zero_digits);
    for (int i = used_digits_ - 1; i >= 0; --i) {
      bigits_[i + zero_digits] = bigits_[i];
    }
    for (int i = 0; i < zero_digits; ++i) {
      bigits_[i] = 0;
    }
    used_digits_ += zero_digits;
    exponent_ -= zero_digits;
    ASSERT(used_digits_ >= 0);
    ASSERT(exponent_ >= 0);
  }
}

void Bignum::BigitsShifxleft(int shift_amount) {
  ASSERT(shift_amount < kBigitSize);
  ASSERT(shift_amount >= 0);
  Chunk carry = 0;
  for (int i = 0; i < used_digits_; ++i) {
    Chunk new_carry = bigits_[i] >> (kBigitSize - shift_amount);
    bigits_[i] = ((bigits_[i] << shift_amount) + carry) & kBigitMask;
    carry = new_carry;
  }
  if (carry != 0) {
    bigits_[used_digits_] = carry;
    used_digits_++;
  }
}

void Bignum::SubtractTimes(const Bignum& other, int factor) {
  ASSERT(exponent_ <= other.exponent_);
  if (factor < 3) {
    for (int i = 0; i < factor; ++i) {
      SubtractBignum(other);
    }
    return;
  }
  Chunk borrow = 0;
  int exponent_diff = other.exponent_ - exponent_;
  for (int i = 0; i < other.used_digits_; ++i) {
    DoubleChunk product = static_cast<DoubleChunk>(factor) * other.bigits_[i];
    DoubleChunk remove = borrow + product;
    Chunk difference =
        bigits_[i + exponent_diff] - ((uint32_t)remove & kBigitMask);
    bigits_[i + exponent_diff] = difference & kBigitMask;
    borrow = static_cast<Chunk>((difference >> (kChunkSize - 1)) +
                                (remove >> kBigitSize));
  }
  for (int i = other.used_digits_ + exponent_diff; i < used_digits_; ++i) {
    if (borrow == 0)
      return;
    Chunk difference = bigits_[i] - borrow;
    bigits_[i] = difference & kBigitMask;
    borrow = difference >> (kChunkSize - 1);
    ++i;
  }
  Clamp();
}

}  // namespace double_conversion

}  // namespace WTF
