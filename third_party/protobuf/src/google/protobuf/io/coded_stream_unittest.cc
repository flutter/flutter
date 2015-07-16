// Protocol Buffers - Google's data interchange format
// Copyright 2008 Google Inc.  All rights reserved.
// http://code.google.com/p/protobuf/
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//     * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//     * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
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

// Author: kenton@google.com (Kenton Varda)
//  Based on original Protocol Buffers design by
//  Sanjay Ghemawat, Jeff Dean, and others.
//
// This file contains tests and benchmarks.

#include <vector>

#include <google/protobuf/io/coded_stream.h>

#include <limits.h>

#include <google/protobuf/stubs/common.h>
#include <google/protobuf/testing/googletest.h>
#include <gtest/gtest.h>
#include <google/protobuf/io/zero_copy_stream_impl.h>


// This declares an unsigned long long integer literal in a portable way.
// (The original macro is way too big and ruins my formatting.)
#undef ULL
#define ULL(x) GOOGLE_ULONGLONG(x)

namespace google {
namespace protobuf {
namespace io {
namespace {

// ===================================================================
// Data-Driven Test Infrastructure

// TEST_1D and TEST_2D are macros I'd eventually like to see added to
// gTest.  These macros can be used to declare tests which should be
// run multiple times, once for each item in some input array.  TEST_1D
// tests all cases in a single input array.  TEST_2D tests all
// combinations of cases from two arrays.  The arrays must be statically
// defined such that the GOOGLE_ARRAYSIZE() macro works on them.  Example:
//
// int kCases[] = {1, 2, 3, 4}
// TEST_1D(MyFixture, MyTest, kCases) {
//   EXPECT_GT(kCases_case, 0);
// }
//
// This test iterates through the numbers 1, 2, 3, and 4 and tests that
// they are all grater than zero.  In case of failure, the exact case
// which failed will be printed.  The case type must be printable using
// ostream::operator<<.

// TODO(kenton):  gTest now supports "parameterized tests" which would be
//   a better way to accomplish this.  Rewrite when time permits.

#define TEST_1D(FIXTURE, NAME, CASES)                                      \
  class FIXTURE##_##NAME##_DD : public FIXTURE {                           \
   protected:                                                              \
    template <typename CaseType>                                           \
    void DoSingleCase(const CaseType& CASES##_case);                       \
  };                                                                       \
                                                                           \
  TEST_F(FIXTURE##_##NAME##_DD, NAME) {                                    \
    for (int i = 0; i < GOOGLE_ARRAYSIZE(CASES); i++) {                           \
      SCOPED_TRACE(testing::Message()                                      \
        << #CASES " case #" << i << ": " << CASES[i]);                     \
      DoSingleCase(CASES[i]);                                              \
    }                                                                      \
  }                                                                        \
                                                                           \
  template <typename CaseType>                                             \
  void FIXTURE##_##NAME##_DD::DoSingleCase(const CaseType& CASES##_case)

#define TEST_2D(FIXTURE, NAME, CASES1, CASES2)                             \
  class FIXTURE##_##NAME##_DD : public FIXTURE {                           \
   protected:                                                              \
    template <typename CaseType1, typename CaseType2>                      \
    void DoSingleCase(const CaseType1& CASES1##_case,                      \
                      const CaseType2& CASES2##_case);                     \
  };                                                                       \
                                                                           \
  TEST_F(FIXTURE##_##NAME##_DD, NAME) {                                    \
    for (int i = 0; i < GOOGLE_ARRAYSIZE(CASES1); i++) {                          \
      for (int j = 0; j < GOOGLE_ARRAYSIZE(CASES2); j++) {                        \
        SCOPED_TRACE(testing::Message()                                    \
          << #CASES1 " case #" << i << ": " << CASES1[i] << ", "           \
          << #CASES2 " case #" << j << ": " << CASES2[j]);                 \
        DoSingleCase(CASES1[i], CASES2[j]);                                \
      }                                                                    \
    }                                                                      \
  }                                                                        \
                                                                           \
  template <typename CaseType1, typename CaseType2>                        \
  void FIXTURE##_##NAME##_DD::DoSingleCase(const CaseType1& CASES1##_case, \
                                           const CaseType2& CASES2##_case)

// ===================================================================

class CodedStreamTest : public testing::Test {
 protected:
  // Helper method used by tests for bytes warning. See implementation comment
  // for further information.
  static void SetupTotalBytesLimitWarningTest(
      int total_bytes_limit, int warning_threshold,
      vector<string>* out_errors, vector<string>* out_warnings);

  // Buffer used during most of the tests. This assumes tests run sequentially.
  static const int kBufferSize = 1024 * 64;
  static uint8 buffer_[kBufferSize];
};

uint8 CodedStreamTest::buffer_[CodedStreamTest::kBufferSize];

// We test each operation over a variety of block sizes to insure that
// we test cases where reads or writes cross buffer boundaries, cases
// where they don't, and cases where there is so much buffer left that
// we can use special optimized paths that don't worry about bounds
// checks.
const int kBlockSizes[] = {1, 2, 3, 5, 7, 13, 32, 1024};

// -------------------------------------------------------------------
// Varint tests.

struct VarintCase {
  uint8 bytes[10];          // Encoded bytes.
  int size;                 // Encoded size, in bytes.
  uint64 value;             // Parsed value.
};

inline std::ostream& operator<<(std::ostream& os, const VarintCase& c) {
  return os << c.value;
}

VarintCase kVarintCases[] = {
  // 32-bit values
  {{0x00}      , 1, 0},
  {{0x01}      , 1, 1},
  {{0x7f}      , 1, 127},
  {{0xa2, 0x74}, 2, (0x22 << 0) | (0x74 << 7)},          // 14882
  {{0xbe, 0xf7, 0x92, 0x84, 0x0b}, 5,                    // 2961488830
    (0x3e << 0) | (0x77 << 7) | (0x12 << 14) | (0x04 << 21) |
    (ULL(0x0b) << 28)},

  // 64-bit
  {{0xbe, 0xf7, 0x92, 0x84, 0x1b}, 5,                    // 7256456126
    (0x3e << 0) | (0x77 << 7) | (0x12 << 14) | (0x04 << 21) |
    (ULL(0x1b) << 28)},
  {{0x80, 0xe6, 0xeb, 0x9c, 0xc3, 0xc9, 0xa4, 0x49}, 8,  // 41256202580718336
    (0x00 << 0) | (0x66 << 7) | (0x6b << 14) | (0x1c << 21) |
    (ULL(0x43) << 28) | (ULL(0x49) << 35) | (ULL(0x24) << 42) |
    (ULL(0x49) << 49)},
  // 11964378330978735131
  {{0x9b, 0xa8, 0xf9, 0xc2, 0xbb, 0xd6, 0x80, 0x85, 0xa6, 0x01}, 10,
    (0x1b << 0) | (0x28 << 7) | (0x79 << 14) | (0x42 << 21) |
    (ULL(0x3b) << 28) | (ULL(0x56) << 35) | (ULL(0x00) << 42) |
    (ULL(0x05) << 49) | (ULL(0x26) << 56) | (ULL(0x01) << 63)},
};

TEST_2D(CodedStreamTest, ReadVarint32, kVarintCases, kBlockSizes) {
  memcpy(buffer_, kVarintCases_case.bytes, kVarintCases_case.size);
  ArrayInputStream input(buffer_, sizeof(buffer_), kBlockSizes_case);

  {
    CodedInputStream coded_input(&input);

    uint32 value;
    EXPECT_TRUE(coded_input.ReadVarint32(&value));
    EXPECT_EQ(static_cast<uint32>(kVarintCases_case.value), value);
  }

  EXPECT_EQ(kVarintCases_case.size, input.ByteCount());
}

TEST_2D(CodedStreamTest, ReadTag, kVarintCases, kBlockSizes) {
  memcpy(buffer_, kVarintCases_case.bytes, kVarintCases_case.size);
  ArrayInputStream input(buffer_, sizeof(buffer_), kBlockSizes_case);

  {
    CodedInputStream coded_input(&input);

    uint32 expected_value = static_cast<uint32>(kVarintCases_case.value);
    EXPECT_EQ(expected_value, coded_input.ReadTag());

    EXPECT_TRUE(coded_input.LastTagWas(expected_value));
    EXPECT_FALSE(coded_input.LastTagWas(expected_value + 1));
  }

  EXPECT_EQ(kVarintCases_case.size, input.ByteCount());
}

// This is the regression test that verifies that there is no issues
// with the empty input buffers handling.
TEST_F(CodedStreamTest, EmptyInputBeforeEos) {
  class In : public ZeroCopyInputStream {
   public:
    In() : count_(0) {}
   private:
    virtual bool Next(const void** data, int* size) {
      *data = NULL;
      *size = 0;
      return count_++ < 2;
    }
    virtual void BackUp(int count)  {
      GOOGLE_LOG(FATAL) << "Tests never call this.";
    }
    virtual bool Skip(int count) {
      GOOGLE_LOG(FATAL) << "Tests never call this.";
      return false;
    }
    virtual int64 ByteCount() const { return 0; }
    int count_;
  } in;
  CodedInputStream input(&in);
  input.ReadTag();
  EXPECT_TRUE(input.ConsumedEntireMessage());
}

TEST_1D(CodedStreamTest, ExpectTag, kVarintCases) {
  // Leave one byte at the beginning of the buffer so we can read it
  // to force the first buffer to be loaded.
  buffer_[0] = '\0';
  memcpy(buffer_ + 1, kVarintCases_case.bytes, kVarintCases_case.size);
  ArrayInputStream input(buffer_, sizeof(buffer_));

  {
    CodedInputStream coded_input(&input);

    // Read one byte to force coded_input.Refill() to be called.  Otherwise,
    // ExpectTag() will return a false negative.
    uint8 dummy;
    coded_input.ReadRaw(&dummy, 1);
    EXPECT_EQ((uint)'\0', (uint)dummy);

    uint32 expected_value = static_cast<uint32>(kVarintCases_case.value);

    // ExpectTag() produces false negatives for large values.
    if (kVarintCases_case.size <= 2) {
      EXPECT_FALSE(coded_input.ExpectTag(expected_value + 1));
      EXPECT_TRUE(coded_input.ExpectTag(expected_value));
    } else {
      EXPECT_FALSE(coded_input.ExpectTag(expected_value));
    }
  }

  if (kVarintCases_case.size <= 2) {
    EXPECT_EQ(kVarintCases_case.size + 1, input.ByteCount());
  } else {
    EXPECT_EQ(1, input.ByteCount());
  }
}

TEST_1D(CodedStreamTest, ExpectTagFromArray, kVarintCases) {
  memcpy(buffer_, kVarintCases_case.bytes, kVarintCases_case.size);

  const uint32 expected_value = static_cast<uint32>(kVarintCases_case.value);

  // If the expectation succeeds, it should return a pointer past the tag.
  if (kVarintCases_case.size <= 2) {
    EXPECT_TRUE(NULL ==
                CodedInputStream::ExpectTagFromArray(buffer_,
                                                     expected_value + 1));
    EXPECT_TRUE(buffer_ + kVarintCases_case.size ==
                CodedInputStream::ExpectTagFromArray(buffer_, expected_value));
  } else {
    EXPECT_TRUE(NULL ==
                CodedInputStream::ExpectTagFromArray(buffer_, expected_value));
  }
}

TEST_2D(CodedStreamTest, ReadVarint64, kVarintCases, kBlockSizes) {
  memcpy(buffer_, kVarintCases_case.bytes, kVarintCases_case.size);
  ArrayInputStream input(buffer_, sizeof(buffer_), kBlockSizes_case);

  {
    CodedInputStream coded_input(&input);

    uint64 value;
    EXPECT_TRUE(coded_input.ReadVarint64(&value));
    EXPECT_EQ(kVarintCases_case.value, value);
  }

  EXPECT_EQ(kVarintCases_case.size, input.ByteCount());
}

TEST_2D(CodedStreamTest, WriteVarint32, kVarintCases, kBlockSizes) {
  if (kVarintCases_case.value > ULL(0x00000000FFFFFFFF)) {
    // Skip this test for the 64-bit values.
    return;
  }

  ArrayOutputStream output(buffer_, sizeof(buffer_), kBlockSizes_case);

  {
    CodedOutputStream coded_output(&output);

    coded_output.WriteVarint32(static_cast<uint32>(kVarintCases_case.value));
    EXPECT_FALSE(coded_output.HadError());

    EXPECT_EQ(kVarintCases_case.size, coded_output.ByteCount());
  }

  EXPECT_EQ(kVarintCases_case.size, output.ByteCount());
  EXPECT_EQ(0,
    memcmp(buffer_, kVarintCases_case.bytes, kVarintCases_case.size));
}

TEST_2D(CodedStreamTest, WriteVarint64, kVarintCases, kBlockSizes) {
  ArrayOutputStream output(buffer_, sizeof(buffer_), kBlockSizes_case);

  {
    CodedOutputStream coded_output(&output);

    coded_output.WriteVarint64(kVarintCases_case.value);
    EXPECT_FALSE(coded_output.HadError());

    EXPECT_EQ(kVarintCases_case.size, coded_output.ByteCount());
  }

  EXPECT_EQ(kVarintCases_case.size, output.ByteCount());
  EXPECT_EQ(0,
    memcmp(buffer_, kVarintCases_case.bytes, kVarintCases_case.size));
}

// This test causes gcc 3.3.5 (and earlier?) to give the cryptic error:
//   "sorry, unimplemented: `method_call_expr' not supported by dump_expr"
#if !defined(__GNUC__) || __GNUC__ > 3 || (__GNUC__ == 3 && __GNUC_MINOR__ > 3)

int32 kSignExtendedVarintCases[] = {
  0, 1, -1, 1237894, -37895138
};

TEST_2D(CodedStreamTest, WriteVarint32SignExtended,
        kSignExtendedVarintCases, kBlockSizes) {
  ArrayOutputStream output(buffer_, sizeof(buffer_), kBlockSizes_case);

  {
    CodedOutputStream coded_output(&output);

    coded_output.WriteVarint32SignExtended(kSignExtendedVarintCases_case);
    EXPECT_FALSE(coded_output.HadError());

    if (kSignExtendedVarintCases_case < 0) {
      EXPECT_EQ(10, coded_output.ByteCount());
    } else {
      EXPECT_LE(coded_output.ByteCount(), 5);
    }
  }

  if (kSignExtendedVarintCases_case < 0) {
    EXPECT_EQ(10, output.ByteCount());
  } else {
    EXPECT_LE(output.ByteCount(), 5);
  }

  // Read value back in as a varint64 and insure it matches.
  ArrayInputStream input(buffer_, sizeof(buffer_));

  {
    CodedInputStream coded_input(&input);

    uint64 value;
    EXPECT_TRUE(coded_input.ReadVarint64(&value));

    EXPECT_EQ(kSignExtendedVarintCases_case, static_cast<int64>(value));
  }

  EXPECT_EQ(output.ByteCount(), input.ByteCount());
}

#endif


// -------------------------------------------------------------------
// Varint failure test.

struct VarintErrorCase {
  uint8 bytes[12];
  int size;
  bool can_parse;
};

inline std::ostream& operator<<(std::ostream& os, const VarintErrorCase& c) {
  return os << "size " << c.size;
}

const VarintErrorCase kVarintErrorCases[] = {
  // Control case.  (Insures that there isn't something else wrong that
  // makes parsing always fail.)
  {{0x00}, 1, true},

  // No input data.
  {{}, 0, false},

  // Input ends unexpectedly.
  {{0xf0, 0xab}, 2, false},

  // Input ends unexpectedly after 32 bits.
  {{0xf0, 0xab, 0xc9, 0x9a, 0xf8, 0xb2}, 6, false},

  // Longer than 10 bytes.
  {{0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x01},
   11, false},
};

TEST_2D(CodedStreamTest, ReadVarint32Error, kVarintErrorCases, kBlockSizes) {
  memcpy(buffer_, kVarintErrorCases_case.bytes, kVarintErrorCases_case.size);
  ArrayInputStream input(buffer_, kVarintErrorCases_case.size,
                         kBlockSizes_case);
  CodedInputStream coded_input(&input);

  uint32 value;
  EXPECT_EQ(kVarintErrorCases_case.can_parse, coded_input.ReadVarint32(&value));
}

TEST_2D(CodedStreamTest, ReadVarint64Error, kVarintErrorCases, kBlockSizes) {
  memcpy(buffer_, kVarintErrorCases_case.bytes, kVarintErrorCases_case.size);
  ArrayInputStream input(buffer_, kVarintErrorCases_case.size,
                         kBlockSizes_case);
  CodedInputStream coded_input(&input);

  uint64 value;
  EXPECT_EQ(kVarintErrorCases_case.can_parse, coded_input.ReadVarint64(&value));
}

// -------------------------------------------------------------------
// VarintSize

struct VarintSizeCase {
  uint64 value;
  int size;
};

inline std::ostream& operator<<(std::ostream& os, const VarintSizeCase& c) {
  return os << c.value;
}

VarintSizeCase kVarintSizeCases[] = {
  {0u, 1},
  {1u, 1},
  {127u, 1},
  {128u, 2},
  {758923u, 3},
  {4000000000u, 5},
  {ULL(41256202580718336), 8},
  {ULL(11964378330978735131), 10},
};

TEST_1D(CodedStreamTest, VarintSize32, kVarintSizeCases) {
  if (kVarintSizeCases_case.value > 0xffffffffu) {
    // Skip 64-bit values.
    return;
  }

  EXPECT_EQ(kVarintSizeCases_case.size,
    CodedOutputStream::VarintSize32(
      static_cast<uint32>(kVarintSizeCases_case.value)));
}

TEST_1D(CodedStreamTest, VarintSize64, kVarintSizeCases) {
  EXPECT_EQ(kVarintSizeCases_case.size,
    CodedOutputStream::VarintSize64(kVarintSizeCases_case.value));
}

// -------------------------------------------------------------------
// Fixed-size int tests

struct Fixed32Case {
  uint8 bytes[sizeof(uint32)];          // Encoded bytes.
  uint32 value;                         // Parsed value.
};

struct Fixed64Case {
  uint8 bytes[sizeof(uint64)];          // Encoded bytes.
  uint64 value;                         // Parsed value.
};

inline std::ostream& operator<<(std::ostream& os, const Fixed32Case& c) {
  return os << "0x" << hex << c.value << dec;
}

inline std::ostream& operator<<(std::ostream& os, const Fixed64Case& c) {
  return os << "0x" << hex << c.value << dec;
}

Fixed32Case kFixed32Cases[] = {
  {{0xef, 0xcd, 0xab, 0x90}, 0x90abcdefu},
  {{0x12, 0x34, 0x56, 0x78}, 0x78563412u},
};

Fixed64Case kFixed64Cases[] = {
  {{0xef, 0xcd, 0xab, 0x90, 0x12, 0x34, 0x56, 0x78}, ULL(0x7856341290abcdef)},
  {{0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88}, ULL(0x8877665544332211)},
};

TEST_2D(CodedStreamTest, ReadLittleEndian32, kFixed32Cases, kBlockSizes) {
  memcpy(buffer_, kFixed32Cases_case.bytes, sizeof(kFixed32Cases_case.bytes));
  ArrayInputStream input(buffer_, sizeof(buffer_), kBlockSizes_case);

  {
    CodedInputStream coded_input(&input);

    uint32 value;
    EXPECT_TRUE(coded_input.ReadLittleEndian32(&value));
    EXPECT_EQ(kFixed32Cases_case.value, value);
  }

  EXPECT_EQ(sizeof(uint32), input.ByteCount());
}

TEST_2D(CodedStreamTest, ReadLittleEndian64, kFixed64Cases, kBlockSizes) {
  memcpy(buffer_, kFixed64Cases_case.bytes, sizeof(kFixed64Cases_case.bytes));
  ArrayInputStream input(buffer_, sizeof(buffer_), kBlockSizes_case);

  {
    CodedInputStream coded_input(&input);

    uint64 value;
    EXPECT_TRUE(coded_input.ReadLittleEndian64(&value));
    EXPECT_EQ(kFixed64Cases_case.value, value);
  }

  EXPECT_EQ(sizeof(uint64), input.ByteCount());
}

TEST_2D(CodedStreamTest, WriteLittleEndian32, kFixed32Cases, kBlockSizes) {
  ArrayOutputStream output(buffer_, sizeof(buffer_), kBlockSizes_case);

  {
    CodedOutputStream coded_output(&output);

    coded_output.WriteLittleEndian32(kFixed32Cases_case.value);
    EXPECT_FALSE(coded_output.HadError());

    EXPECT_EQ(sizeof(uint32), coded_output.ByteCount());
  }

  EXPECT_EQ(sizeof(uint32), output.ByteCount());
  EXPECT_EQ(0, memcmp(buffer_, kFixed32Cases_case.bytes, sizeof(uint32)));
}

TEST_2D(CodedStreamTest, WriteLittleEndian64, kFixed64Cases, kBlockSizes) {
  ArrayOutputStream output(buffer_, sizeof(buffer_), kBlockSizes_case);

  {
    CodedOutputStream coded_output(&output);

    coded_output.WriteLittleEndian64(kFixed64Cases_case.value);
    EXPECT_FALSE(coded_output.HadError());

    EXPECT_EQ(sizeof(uint64), coded_output.ByteCount());
  }

  EXPECT_EQ(sizeof(uint64), output.ByteCount());
  EXPECT_EQ(0, memcmp(buffer_, kFixed64Cases_case.bytes, sizeof(uint64)));
}

// Tests using the static methods to read fixed-size values from raw arrays.

TEST_1D(CodedStreamTest, ReadLittleEndian32FromArray, kFixed32Cases) {
  memcpy(buffer_, kFixed32Cases_case.bytes, sizeof(kFixed32Cases_case.bytes));

  uint32 value;
  const uint8* end = CodedInputStream::ReadLittleEndian32FromArray(
      buffer_, &value);
  EXPECT_EQ(kFixed32Cases_case.value, value);
  EXPECT_TRUE(end == buffer_ + sizeof(value));
}

TEST_1D(CodedStreamTest, ReadLittleEndian64FromArray, kFixed64Cases) {
  memcpy(buffer_, kFixed64Cases_case.bytes, sizeof(kFixed64Cases_case.bytes));

  uint64 value;
  const uint8* end = CodedInputStream::ReadLittleEndian64FromArray(
      buffer_, &value);
  EXPECT_EQ(kFixed64Cases_case.value, value);
  EXPECT_TRUE(end == buffer_ + sizeof(value));
}

// -------------------------------------------------------------------
// Raw reads and writes

const char kRawBytes[] = "Some bytes which will be written and read raw.";

TEST_1D(CodedStreamTest, ReadRaw, kBlockSizes) {
  memcpy(buffer_, kRawBytes, sizeof(kRawBytes));
  ArrayInputStream input(buffer_, sizeof(buffer_), kBlockSizes_case);
  char read_buffer[sizeof(kRawBytes)];

  {
    CodedInputStream coded_input(&input);

    EXPECT_TRUE(coded_input.ReadRaw(read_buffer, sizeof(kRawBytes)));
    EXPECT_EQ(0, memcmp(kRawBytes, read_buffer, sizeof(kRawBytes)));
  }

  EXPECT_EQ(sizeof(kRawBytes), input.ByteCount());
}

TEST_1D(CodedStreamTest, WriteRaw, kBlockSizes) {
  ArrayOutputStream output(buffer_, sizeof(buffer_), kBlockSizes_case);

  {
    CodedOutputStream coded_output(&output);

    coded_output.WriteRaw(kRawBytes, sizeof(kRawBytes));
    EXPECT_FALSE(coded_output.HadError());

    EXPECT_EQ(sizeof(kRawBytes), coded_output.ByteCount());
  }

  EXPECT_EQ(sizeof(kRawBytes), output.ByteCount());
  EXPECT_EQ(0, memcmp(buffer_, kRawBytes, sizeof(kRawBytes)));
}

TEST_1D(CodedStreamTest, ReadString, kBlockSizes) {
  memcpy(buffer_, kRawBytes, sizeof(kRawBytes));
  ArrayInputStream input(buffer_, sizeof(buffer_), kBlockSizes_case);

  {
    CodedInputStream coded_input(&input);

    string str;
    EXPECT_TRUE(coded_input.ReadString(&str, strlen(kRawBytes)));
    EXPECT_EQ(kRawBytes, str);
  }

  EXPECT_EQ(strlen(kRawBytes), input.ByteCount());
}

// Check to make sure ReadString doesn't crash on impossibly large strings.
TEST_1D(CodedStreamTest, ReadStringImpossiblyLarge, kBlockSizes) {
  ArrayInputStream input(buffer_, sizeof(buffer_), kBlockSizes_case);

  {
    CodedInputStream coded_input(&input);

    string str;
    // Try to read a gigabyte.
    EXPECT_FALSE(coded_input.ReadString(&str, 1 << 30));
  }
}

TEST_F(CodedStreamTest, ReadStringImpossiblyLargeFromStringOnStack) {
  // Same test as above, except directly use a buffer. This used to cause
  // crashes while the above did not.
  uint8 buffer[8];
  CodedInputStream coded_input(buffer, 8);
  string str;
  EXPECT_FALSE(coded_input.ReadString(&str, 1 << 30));
}

TEST_F(CodedStreamTest, ReadStringImpossiblyLargeFromStringOnHeap) {
  scoped_array<uint8> buffer(new uint8[8]);
  CodedInputStream coded_input(buffer.get(), 8);
  string str;
  EXPECT_FALSE(coded_input.ReadString(&str, 1 << 30));
}


// -------------------------------------------------------------------
// Skip

const char kSkipTestBytes[] =
  "<Before skipping><To be skipped><After skipping>";
const char kSkipOutputTestBytes[] =
  "-----------------<To be skipped>----------------";

TEST_1D(CodedStreamTest, SkipInput, kBlockSizes) {
  memcpy(buffer_, kSkipTestBytes, sizeof(kSkipTestBytes));
  ArrayInputStream input(buffer_, sizeof(buffer_), kBlockSizes_case);

  {
    CodedInputStream coded_input(&input);

    string str;
    EXPECT_TRUE(coded_input.ReadString(&str, strlen("<Before skipping>")));
    EXPECT_EQ("<Before skipping>", str);
    EXPECT_TRUE(coded_input.Skip(strlen("<To be skipped>")));
    EXPECT_TRUE(coded_input.ReadString(&str, strlen("<After skipping>")));
    EXPECT_EQ("<After skipping>", str);
  }

  EXPECT_EQ(strlen(kSkipTestBytes), input.ByteCount());
}

// -------------------------------------------------------------------
// GetDirectBufferPointer

TEST_F(CodedStreamTest, GetDirectBufferPointerInput) {
  ArrayInputStream input(buffer_, sizeof(buffer_), 8);
  CodedInputStream coded_input(&input);

  const void* ptr;
  int size;

  EXPECT_TRUE(coded_input.GetDirectBufferPointer(&ptr, &size));
  EXPECT_EQ(buffer_, ptr);
  EXPECT_EQ(8, size);

  // Peeking again should return the same pointer.
  EXPECT_TRUE(coded_input.GetDirectBufferPointer(&ptr, &size));
  EXPECT_EQ(buffer_, ptr);
  EXPECT_EQ(8, size);

  // Skip forward in the same buffer then peek again.
  EXPECT_TRUE(coded_input.Skip(3));
  EXPECT_TRUE(coded_input.GetDirectBufferPointer(&ptr, &size));
  EXPECT_EQ(buffer_ + 3, ptr);
  EXPECT_EQ(5, size);

  // Skip to end of buffer and peek -- should get next buffer.
  EXPECT_TRUE(coded_input.Skip(5));
  EXPECT_TRUE(coded_input.GetDirectBufferPointer(&ptr, &size));
  EXPECT_EQ(buffer_ + 8, ptr);
  EXPECT_EQ(8, size);
}

TEST_F(CodedStreamTest, GetDirectBufferPointerInlineInput) {
  ArrayInputStream input(buffer_, sizeof(buffer_), 8);
  CodedInputStream coded_input(&input);

  const void* ptr;
  int size;

  coded_input.GetDirectBufferPointerInline(&ptr, &size);
  EXPECT_EQ(buffer_, ptr);
  EXPECT_EQ(8, size);

  // Peeking again should return the same pointer.
  coded_input.GetDirectBufferPointerInline(&ptr, &size);
  EXPECT_EQ(buffer_, ptr);
  EXPECT_EQ(8, size);

  // Skip forward in the same buffer then peek again.
  EXPECT_TRUE(coded_input.Skip(3));
  coded_input.GetDirectBufferPointerInline(&ptr, &size);
  EXPECT_EQ(buffer_ + 3, ptr);
  EXPECT_EQ(5, size);

  // Skip to end of buffer and peek -- should return false and provide an empty
  // buffer. It does not try to Refresh().
  EXPECT_TRUE(coded_input.Skip(5));
  coded_input.GetDirectBufferPointerInline(&ptr, &size);
  EXPECT_EQ(buffer_ + 8, ptr);
  EXPECT_EQ(0, size);
}

TEST_F(CodedStreamTest, GetDirectBufferPointerOutput) {
  ArrayOutputStream output(buffer_, sizeof(buffer_), 8);
  CodedOutputStream coded_output(&output);

  void* ptr;
  int size;

  EXPECT_TRUE(coded_output.GetDirectBufferPointer(&ptr, &size));
  EXPECT_EQ(buffer_, ptr);
  EXPECT_EQ(8, size);

  // Peeking again should return the same pointer.
  EXPECT_TRUE(coded_output.GetDirectBufferPointer(&ptr, &size));
  EXPECT_EQ(buffer_, ptr);
  EXPECT_EQ(8, size);

  // Skip forward in the same buffer then peek again.
  EXPECT_TRUE(coded_output.Skip(3));
  EXPECT_TRUE(coded_output.GetDirectBufferPointer(&ptr, &size));
  EXPECT_EQ(buffer_ + 3, ptr);
  EXPECT_EQ(5, size);

  // Skip to end of buffer and peek -- should get next buffer.
  EXPECT_TRUE(coded_output.Skip(5));
  EXPECT_TRUE(coded_output.GetDirectBufferPointer(&ptr, &size));
  EXPECT_EQ(buffer_ + 8, ptr);
  EXPECT_EQ(8, size);

  // Skip over multiple buffers.
  EXPECT_TRUE(coded_output.Skip(22));
  EXPECT_TRUE(coded_output.GetDirectBufferPointer(&ptr, &size));
  EXPECT_EQ(buffer_ + 30, ptr);
  EXPECT_EQ(2, size);
}

// -------------------------------------------------------------------
// Limits

TEST_1D(CodedStreamTest, BasicLimit, kBlockSizes) {
  ArrayInputStream input(buffer_, sizeof(buffer_), kBlockSizes_case);

  {
    CodedInputStream coded_input(&input);

    EXPECT_EQ(-1, coded_input.BytesUntilLimit());
    CodedInputStream::Limit limit = coded_input.PushLimit(8);

    // Read until we hit the limit.
    uint32 value;
    EXPECT_EQ(8, coded_input.BytesUntilLimit());
    EXPECT_TRUE(coded_input.ReadLittleEndian32(&value));
    EXPECT_EQ(4, coded_input.BytesUntilLimit());
    EXPECT_TRUE(coded_input.ReadLittleEndian32(&value));
    EXPECT_EQ(0, coded_input.BytesUntilLimit());
    EXPECT_FALSE(coded_input.ReadLittleEndian32(&value));
    EXPECT_EQ(0, coded_input.BytesUntilLimit());

    coded_input.PopLimit(limit);

    EXPECT_EQ(-1, coded_input.BytesUntilLimit());
    EXPECT_TRUE(coded_input.ReadLittleEndian32(&value));
  }

  EXPECT_EQ(12, input.ByteCount());
}

// Test what happens when we push two limits where the second (top) one is
// shorter.
TEST_1D(CodedStreamTest, SmallLimitOnTopOfBigLimit, kBlockSizes) {
  ArrayInputStream input(buffer_, sizeof(buffer_), kBlockSizes_case);

  {
    CodedInputStream coded_input(&input);

    EXPECT_EQ(-1, coded_input.BytesUntilLimit());
    CodedInputStream::Limit limit1 = coded_input.PushLimit(8);
    EXPECT_EQ(8, coded_input.BytesUntilLimit());
    CodedInputStream::Limit limit2 = coded_input.PushLimit(4);

    uint32 value;

    // Read until we hit limit2, the top and shortest limit.
    EXPECT_EQ(4, coded_input.BytesUntilLimit());
    EXPECT_TRUE(coded_input.ReadLittleEndian32(&value));
    EXPECT_EQ(0, coded_input.BytesUntilLimit());
    EXPECT_FALSE(coded_input.ReadLittleEndian32(&value));
    EXPECT_EQ(0, coded_input.BytesUntilLimit());

    coded_input.PopLimit(limit2);

    // Read until we hit limit1.
    EXPECT_EQ(4, coded_input.BytesUntilLimit());
    EXPECT_TRUE(coded_input.ReadLittleEndian32(&value));
    EXPECT_EQ(0, coded_input.BytesUntilLimit());
    EXPECT_FALSE(coded_input.ReadLittleEndian32(&value));
    EXPECT_EQ(0, coded_input.BytesUntilLimit());

    coded_input.PopLimit(limit1);

    // No more limits.
    EXPECT_EQ(-1, coded_input.BytesUntilLimit());
    EXPECT_TRUE(coded_input.ReadLittleEndian32(&value));
  }

  EXPECT_EQ(12, input.ByteCount());
}

// Test what happens when we push two limits where the second (top) one is
// longer.  In this case, the top limit is shortened to match the previous
// limit.
TEST_1D(CodedStreamTest, BigLimitOnTopOfSmallLimit, kBlockSizes) {
  ArrayInputStream input(buffer_, sizeof(buffer_), kBlockSizes_case);

  {
    CodedInputStream coded_input(&input);

    EXPECT_EQ(-1, coded_input.BytesUntilLimit());
    CodedInputStream::Limit limit1 = coded_input.PushLimit(4);
    EXPECT_EQ(4, coded_input.BytesUntilLimit());
    CodedInputStream::Limit limit2 = coded_input.PushLimit(8);

    uint32 value;

    // Read until we hit limit2.  Except, wait!  limit1 is shorter, so
    // we end up hitting that first, despite having 4 bytes to go on
    // limit2.
    EXPECT_EQ(4, coded_input.BytesUntilLimit());
    EXPECT_TRUE(coded_input.ReadLittleEndian32(&value));
    EXPECT_EQ(0, coded_input.BytesUntilLimit());
    EXPECT_FALSE(coded_input.ReadLittleEndian32(&value));
    EXPECT_EQ(0, coded_input.BytesUntilLimit());

    coded_input.PopLimit(limit2);

    // OK, popped limit2, now limit1 is on top, which we've already hit.
    EXPECT_EQ(0, coded_input.BytesUntilLimit());
    EXPECT_FALSE(coded_input.ReadLittleEndian32(&value));
    EXPECT_EQ(0, coded_input.BytesUntilLimit());

    coded_input.PopLimit(limit1);

    // No more limits.
    EXPECT_EQ(-1, coded_input.BytesUntilLimit());
    EXPECT_TRUE(coded_input.ReadLittleEndian32(&value));
  }

  EXPECT_EQ(8, input.ByteCount());
}

TEST_F(CodedStreamTest, ExpectAtEnd) {
  // Test ExpectAtEnd(), which is based on limits.
  ArrayInputStream input(buffer_, sizeof(buffer_));
  CodedInputStream coded_input(&input);

  EXPECT_FALSE(coded_input.ExpectAtEnd());

  CodedInputStream::Limit limit = coded_input.PushLimit(4);

  uint32 value;
  EXPECT_TRUE(coded_input.ReadLittleEndian32(&value));
  EXPECT_TRUE(coded_input.ExpectAtEnd());

  coded_input.PopLimit(limit);
  EXPECT_FALSE(coded_input.ExpectAtEnd());
}

TEST_F(CodedStreamTest, NegativeLimit) {
  // Check what happens when we push a negative limit.
  ArrayInputStream input(buffer_, sizeof(buffer_));
  CodedInputStream coded_input(&input);

  CodedInputStream::Limit limit = coded_input.PushLimit(-1234);
  // BytesUntilLimit() returns -1 to mean "no limit", which actually means
  // "the limit is INT_MAX relative to the beginning of the stream".
  EXPECT_EQ(-1, coded_input.BytesUntilLimit());
  coded_input.PopLimit(limit);
}

TEST_F(CodedStreamTest, NegativeLimitAfterReading) {
  // Check what happens when we push a negative limit.
  ArrayInputStream input(buffer_, sizeof(buffer_));
  CodedInputStream coded_input(&input);
  ASSERT_TRUE(coded_input.Skip(128));

  CodedInputStream::Limit limit = coded_input.PushLimit(-64);
  // BytesUntilLimit() returns -1 to mean "no limit", which actually means
  // "the limit is INT_MAX relative to the beginning of the stream".
  EXPECT_EQ(-1, coded_input.BytesUntilLimit());
  coded_input.PopLimit(limit);
}

TEST_F(CodedStreamTest, OverflowLimit) {
  // Check what happens when we push a limit large enough that its absolute
  // position is more than 2GB into the stream.
  ArrayInputStream input(buffer_, sizeof(buffer_));
  CodedInputStream coded_input(&input);
  ASSERT_TRUE(coded_input.Skip(128));

  CodedInputStream::Limit limit = coded_input.PushLimit(INT_MAX);
  // BytesUntilLimit() returns -1 to mean "no limit", which actually means
  // "the limit is INT_MAX relative to the beginning of the stream".
  EXPECT_EQ(-1, coded_input.BytesUntilLimit());
  coded_input.PopLimit(limit);
}

TEST_F(CodedStreamTest, TotalBytesLimit) {
  ArrayInputStream input(buffer_, sizeof(buffer_));
  CodedInputStream coded_input(&input);
  coded_input.SetTotalBytesLimit(16, -1);

  string str;
  EXPECT_TRUE(coded_input.ReadString(&str, 16));

  vector<string> errors;

  {
    ScopedMemoryLog error_log;
    EXPECT_FALSE(coded_input.ReadString(&str, 1));
    errors = error_log.GetMessages(ERROR);
  }

  ASSERT_EQ(1, errors.size());
  EXPECT_PRED_FORMAT2(testing::IsSubstring,
    "A protocol message was rejected because it was too big", errors[0]);

  coded_input.SetTotalBytesLimit(32, -1);
  EXPECT_TRUE(coded_input.ReadString(&str, 16));
}

TEST_F(CodedStreamTest, TotalBytesLimitNotValidMessageEnd) {
  // total_bytes_limit_ is not a valid place for a message to end.

  ArrayInputStream input(buffer_, sizeof(buffer_));
  CodedInputStream coded_input(&input);

  // Set both total_bytes_limit and a regular limit at 16 bytes.
  coded_input.SetTotalBytesLimit(16, -1);
  CodedInputStream::Limit limit = coded_input.PushLimit(16);

  // Read 16 bytes.
  string str;
  EXPECT_TRUE(coded_input.ReadString(&str, 16));

  // Read a tag.  Should fail, but report being a valid endpoint since it's
  // a regular limit.
  EXPECT_EQ(0, coded_input.ReadTag());
  EXPECT_TRUE(coded_input.ConsumedEntireMessage());

  // Pop the limit.
  coded_input.PopLimit(limit);

  // Read a tag.  Should fail, and report *not* being a valid endpoint, since
  // this time we're hitting the total bytes limit.
  EXPECT_EQ(0, coded_input.ReadTag());
  EXPECT_FALSE(coded_input.ConsumedEntireMessage());
}

// This method is used by the tests below.
// It constructs a CodedInputStream with the given limits and tries to read 2KiB
// of data from it. Then it returns the logged errors and warnings in the given
// vectors.
void CodedStreamTest::SetupTotalBytesLimitWarningTest(
    int total_bytes_limit, int warning_threshold,
    vector<string>* out_errors, vector<string>* out_warnings) {
  ArrayInputStream raw_input(buffer_, sizeof(buffer_), 128);

  ScopedMemoryLog scoped_log;
  {
    CodedInputStream input(&raw_input);
    input.SetTotalBytesLimit(total_bytes_limit, warning_threshold);
    string str;
    EXPECT_TRUE(input.ReadString(&str, 2048));
  }

  *out_errors = scoped_log.GetMessages(ERROR);
  *out_warnings = scoped_log.GetMessages(WARNING);
}

TEST_F(CodedStreamTest, TotalBytesLimitWarning) {
  vector<string> errors;
  vector<string> warnings;
  SetupTotalBytesLimitWarningTest(10240, 1024, &errors, &warnings);

  EXPECT_EQ(0, errors.size());

  ASSERT_EQ(2, warnings.size());
  EXPECT_PRED_FORMAT2(testing::IsSubstring,
    "Reading dangerously large protocol message.  If the message turns out to "
    "be larger than 10240 bytes, parsing will be halted for security reasons.",
    warnings[0]);
  EXPECT_PRED_FORMAT2(testing::IsSubstring,
    "The total number of bytes read was 2048",
    warnings[1]);
}

TEST_F(CodedStreamTest, TotalBytesLimitWarningDisabled) {
  vector<string> errors;
  vector<string> warnings;

  // Test with -1
  SetupTotalBytesLimitWarningTest(10240, -1, &errors, &warnings);
  EXPECT_EQ(0, errors.size());
  EXPECT_EQ(0, warnings.size());

  // Test again with -2, expecting the same result
  SetupTotalBytesLimitWarningTest(10240, -2, &errors, &warnings);
  EXPECT_EQ(0, errors.size());
  EXPECT_EQ(0, warnings.size());
}


TEST_F(CodedStreamTest, RecursionLimit) {
  ArrayInputStream input(buffer_, sizeof(buffer_));
  CodedInputStream coded_input(&input);
  coded_input.SetRecursionLimit(4);

  // This is way too much testing for a counter.
  EXPECT_TRUE(coded_input.IncrementRecursionDepth());      // 1
  EXPECT_TRUE(coded_input.IncrementRecursionDepth());      // 2
  EXPECT_TRUE(coded_input.IncrementRecursionDepth());      // 3
  EXPECT_TRUE(coded_input.IncrementRecursionDepth());      // 4
  EXPECT_FALSE(coded_input.IncrementRecursionDepth());     // 5
  EXPECT_FALSE(coded_input.IncrementRecursionDepth());     // 6
  coded_input.DecrementRecursionDepth();                   // 5
  EXPECT_FALSE(coded_input.IncrementRecursionDepth());     // 6
  coded_input.DecrementRecursionDepth();                   // 5
  coded_input.DecrementRecursionDepth();                   // 4
  coded_input.DecrementRecursionDepth();                   // 3
  EXPECT_TRUE(coded_input.IncrementRecursionDepth());      // 4
  EXPECT_FALSE(coded_input.IncrementRecursionDepth());     // 5
  coded_input.DecrementRecursionDepth();                   // 4
  coded_input.DecrementRecursionDepth();                   // 3
  coded_input.DecrementRecursionDepth();                   // 2
  coded_input.DecrementRecursionDepth();                   // 1
  coded_input.DecrementRecursionDepth();                   // 0
  coded_input.DecrementRecursionDepth();                   // 0
  coded_input.DecrementRecursionDepth();                   // 0
  EXPECT_TRUE(coded_input.IncrementRecursionDepth());      // 1
  EXPECT_TRUE(coded_input.IncrementRecursionDepth());      // 2
  EXPECT_TRUE(coded_input.IncrementRecursionDepth());      // 3
  EXPECT_TRUE(coded_input.IncrementRecursionDepth());      // 4
  EXPECT_FALSE(coded_input.IncrementRecursionDepth());     // 5

  coded_input.SetRecursionLimit(6);
  EXPECT_TRUE(coded_input.IncrementRecursionDepth());      // 6
  EXPECT_FALSE(coded_input.IncrementRecursionDepth());     // 7
}


class ReallyBigInputStream : public ZeroCopyInputStream {
 public:
  ReallyBigInputStream() : backup_amount_(0), buffer_count_(0) {}
  ~ReallyBigInputStream() {}

  // implements ZeroCopyInputStream ----------------------------------
  bool Next(const void** data, int* size) {
    // We only expect BackUp() to be called at the end.
    EXPECT_EQ(0, backup_amount_);

    switch (buffer_count_++) {
      case 0:
        *data = buffer_;
        *size = sizeof(buffer_);
        return true;
      case 1:
        // Return an enormously large buffer that, when combined with the 1k
        // returned already, should overflow the total_bytes_read_ counter in
        // CodedInputStream.  Note that we'll only read the first 1024 bytes
        // of this buffer so it's OK that we have it point at buffer_.
        *data = buffer_;
        *size = INT_MAX;
        return true;
      default:
        return false;
    }
  }

  void BackUp(int count) {
    backup_amount_ = count;
  }

  bool Skip(int count)    { GOOGLE_LOG(FATAL) << "Not implemented."; return false; }
  int64 ByteCount() const { GOOGLE_LOG(FATAL) << "Not implemented."; return 0; }

  int backup_amount_;

 private:
  char buffer_[1024];
  int64 buffer_count_;
};

TEST_F(CodedStreamTest, InputOver2G) {
  // CodedInputStream should gracefully handle input over 2G and call
  // input.BackUp() with the correct number of bytes on destruction.
  ReallyBigInputStream input;

  vector<string> errors;

  {
    ScopedMemoryLog error_log;
    CodedInputStream coded_input(&input);
    string str;
    EXPECT_TRUE(coded_input.ReadString(&str, 512));
    EXPECT_TRUE(coded_input.ReadString(&str, 1024));
    errors = error_log.GetMessages(ERROR);
  }

  EXPECT_EQ(INT_MAX - 512, input.backup_amount_);
  EXPECT_EQ(0, errors.size());
}

// ===================================================================


}  // namespace
}  // namespace io
}  // namespace protobuf
}  // namespace google
