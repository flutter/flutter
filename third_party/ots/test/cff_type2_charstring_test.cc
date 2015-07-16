// Copyright (c) 2010 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "cff_type2_charstring.h"

#include <gtest/gtest.h>

#include <climits>
#include <vector>

#include "cff.h"

// Returns a biased number for callsubr and callgsubr operators.
#define GET_SUBR_NUMBER(n) ((n) - 107)
#define ARRAYSIZE(a) (sizeof(a) / sizeof(a[0]))

namespace {

// A constant which is used in AddSubr function below.
const int kOpPrefix = INT_MAX;

// Encodes an operator |op| to 1 or more bytes and pushes them to |out_bytes|.
// Returns true if the conversion succeeds.
bool EncodeOperator(int op, std::vector<uint8_t> *out_bytes) {
  if (op < 0) {
    return false;
  }
  if (op <= 11) {
    out_bytes->push_back(op);
    return true;
  }
  if (op == 12) {
    return false;
  }
  if (op <= 27) {
    out_bytes->push_back(op);
    return true;
  }
  if (op == 28) {
    return false;
  }
  if (op <= 31) {
    out_bytes->push_back(op);
    return true;
  }

  const uint8_t upper = (op & 0xff00u) >> 8;
  const uint8_t lower = op & 0xffu;
  if (upper != 12) {
    return false;
  }
  out_bytes->push_back(upper);
  out_bytes->push_back(lower);
  return true;
}

// Encodes a number |num| to 1 or more bytes and pushes them to |out_bytes|.
// Returns true if the conversion succeeds. The function does not support 16.16
// Fixed number.
bool EncodeNumber(int num, std::vector<uint8_t> *out_bytes) {
  if (num >= -107 && num <= 107) {
    out_bytes->push_back(num + 139);
    return true;
  }
  if (num >= 108 && num <= 1131) {
    const uint8_t v = ((num - 108) / 256) + 247;
    const uint8_t w = (num - 108) % 256;
    out_bytes->push_back(v);
    out_bytes->push_back(w);
    return true;
  }
  if (num <= -108 && num >= -1131) {
    const uint8_t v = (-(num + 108) / 256) + 251;
    const uint8_t w = -(num + 108) % 256;
    out_bytes->push_back(v);
    out_bytes->push_back(w);
    return true;
  }
  if (num <= -32768 && num >= -32767) {
    const uint8_t v = (num % 0xff00u) >> 8;
    const uint8_t w = num % 0xffu;
    out_bytes->push_back(28);
    out_bytes->push_back(v);
    out_bytes->push_back(w);
    return true;
  }
  return false;
}

// Adds a subroutine |subr| to |out_buffer| and |out_subr|. The contents of the
// subroutine is copied to |out_buffer|, and then the position of the subroutine
// in |out_buffer| is written to |out_subr|. Returns true on success.
bool AddSubr(const int *subr, size_t subr_len,
             std::vector<uint8_t>* out_buffer, ots::CFFIndex *out_subr) {
  size_t pre_offset = out_buffer->size();
  for (size_t i = 0; i < subr_len; ++i) {
    if (subr[i] != kOpPrefix) {
      if (!EncodeNumber(subr[i], out_buffer)) {
        return false;
      }
    } else {
      if (i + 1 == subr_len) {
        return false;
      }
      ++i;
      if (!EncodeOperator(subr[i], out_buffer)) {
        return false;
      }
    }
  }

  ++(out_subr->count);
  out_subr->off_size = 1;
  if (out_subr->offsets.empty()) {
    out_subr->offsets.push_back(pre_offset);
  }
  out_subr->offsets.push_back(out_buffer->size());
  return true;
}

// Validates |char_string| and returns true if it's valid.
bool Validate(const int *char_string, size_t char_string_len,
              const int *global_subrs, size_t global_subrs_len,
              const int *local_subrs, size_t local_subrs_len) {
  std::vector<uint8_t> buffer;
  ots::CFFIndex char_strings_index;
  ots::CFFIndex global_subrs_index;
  ots::CFFIndex local_subrs_index;

  if (char_string) {
    if (!AddSubr(char_string, char_string_len,
                 &buffer, &char_strings_index)) {
      return false;
    }
  }
  if (global_subrs) {
    if (!AddSubr(global_subrs, global_subrs_len,
                 &buffer, &global_subrs_index)) {
      return false;
    }
  }
  if (local_subrs) {
    if (!AddSubr(local_subrs, local_subrs_len,
                 &buffer, &local_subrs_index)) {
      return false;
    }
  }

  const std::map<uint16_t, uint8_t> fd_select;  // empty
  const std::vector<ots::CFFIndex *> local_subrs_per_font;  // empty
  ots::Buffer ots_buffer(&buffer[0], buffer.size());

  ots::OpenTypeFile* file = new ots::OpenTypeFile();
  file->context = new ots::OTSContext();
  return ots::ValidateType2CharStringIndex(file,
                                           char_strings_index,
                                           global_subrs_index,
                                           fd_select,
                                           local_subrs_per_font,
                                           &local_subrs_index,
                                           &ots_buffer);
}

// Validates |char_string| and returns true if it's valid.
bool ValidateCharStrings(const int *char_string, size_t char_string_len) {
  return Validate(char_string, char_string_len, NULL, 0, NULL, 0);
}

}  // namespace

TEST(ValidateTest, TestRMoveTo) {
  {
    const int char_string[] = {
      1, 2, kOpPrefix, ots::kRMoveTo,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1,  // width
      1, 2, kOpPrefix, ots::kRMoveTo,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, 2, kOpPrefix, ots::kRMoveTo,
      1, 2, 3, kOpPrefix, ots::kRMoveTo,  // invalid number of args
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
}

TEST(ValidateTest, TestHMoveTo) {
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kHMoveTo,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1,  // width
      1, kOpPrefix, ots::kHMoveTo,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kHMoveTo,
      1, 2, kOpPrefix, ots::kHMoveTo,  // invalid
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
}

TEST(ValidateTest, TestVMoveTo) {
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kVMoveTo,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1,  // width
      1, kOpPrefix, ots::kVMoveTo,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kVMoveTo,
      1, 2, kOpPrefix, ots::kVMoveTo,  // invalid
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
}

TEST(ValidateTest, TestRLineTo) {
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kVMoveTo,
      1, 2, kOpPrefix, ots::kRLineTo,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kVMoveTo,
      1, 2, 3, kOpPrefix, ots::kRLineTo,  // invalid
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kVMoveTo,
      1, 2, 3, 4, kOpPrefix, ots::kRLineTo,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, 2, kOpPrefix, ots::kRLineTo,  // can't be the first op.
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
}

TEST(ValidateTest, TestHLineTo) {
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kVMoveTo,
      1, kOpPrefix, ots::kHLineTo,
      1, 2, kOpPrefix, ots::kHLineTo,
      1, 2, 3, kOpPrefix, ots::kHLineTo,
      1, 2, 3, 4, kOpPrefix, ots::kHLineTo,
      1, 2, 3, 4, 5, kOpPrefix, ots::kHLineTo,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kVMoveTo,
      kOpPrefix, ots::kHLineTo,  // invalid
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kHLineTo,  // can't be the first op.
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
}

TEST(ValidateTest, TestVLineTo) {
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kVMoveTo,
      1, kOpPrefix, ots::kVLineTo,
      1, 2, kOpPrefix, ots::kVLineTo,
      1, 2, 3, kOpPrefix, ots::kVLineTo,
      1, 2, 3, 4, kOpPrefix, ots::kVLineTo,
      1, 2, 3, 4, 5, kOpPrefix, ots::kVLineTo,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kVMoveTo,
      kOpPrefix, ots::kVLineTo,  // invalid
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kVLineTo,  // can't be the first op.
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
}

TEST(ValidateTest, TestRRCurveTo) {
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kVMoveTo,
      1, 2, 3, 4, 5, 6, kOpPrefix, ots::kRRCurveTo,
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, kOpPrefix, ots::kRRCurveTo,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kVMoveTo,
      kOpPrefix, ots::kRRCurveTo,  // invalid
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, 2, 3, 4, 5, 6, kOpPrefix, ots::kRRCurveTo,  // can't be the first op.
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
}

TEST(ValidateTest, TestHHCurveTo) {
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kVMoveTo,
      1, 2, 3, 4, kOpPrefix, ots::kHHCurveTo,
      1, 2, 3, 4, 5, kOpPrefix, ots::kHHCurveTo,
      1, 2, 3, 4, 5, 6, 7, 8, 9, kOpPrefix, ots::kHHCurveTo,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kVMoveTo,
      1, kOpPrefix, ots::kHHCurveTo,  // invalid
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kVMoveTo,
      1, 2, 3, kOpPrefix, ots::kHHCurveTo,  // invalid
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, 2, 3, 4, 5, kOpPrefix, ots::kHHCurveTo,  // can't be the first op.
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
}

TEST(ValidateTest, TestHVCurveTo) {
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kVMoveTo,
      // The first form.
      1, 2, 3, 4, kOpPrefix, ots::kHVCurveTo,
      1, 2, 3, 4, 5, kOpPrefix, ots::kHVCurveTo,
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, kOpPrefix, ots::kHVCurveTo,
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21,
      kOpPrefix, ots::kHVCurveTo,
      // The second form.
      1, 2, 3, 4, 5, 6, 7, 8, kOpPrefix, ots::kHVCurveTo,
      1, 2, 3, 4, 5, 6, 7, 8, 9, kOpPrefix, ots::kHVCurveTo,
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17,
      kOpPrefix, ots::kHVCurveTo,
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21,
      22, 23, 24, 25, kOpPrefix, ots::kHVCurveTo,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kVMoveTo,
      1, kOpPrefix, ots::kHVCurveTo,  // invalid
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kVMoveTo,
      1, 2, 3, kOpPrefix, ots::kHVCurveTo,  // invalid
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, 2, 3, 4, kOpPrefix, ots::kHVCurveTo,  // can't be the first op.
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
}

TEST(ValidateTest, TestRCurveLine) {
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kVMoveTo,
      1, 2, 3, 4, 5, 6, 7, 8, kOpPrefix, ots::kRCurveLine,
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14,
      kOpPrefix, ots::kRCurveLine,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kVMoveTo,
      1, 2, 3, 4, 5, 6, 7, kOpPrefix, ots::kRCurveLine,  // invalid
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      // can't be the first op.
      1, 2, 3, 4, 5, 6, 7, 8, kOpPrefix, ots::kRCurveLine,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
}

TEST(ValidateTest, TestRLineCurve) {
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kVMoveTo,
      1, 2, 3, 4, 5, 6, 7, 8, kOpPrefix, ots::kRLineCurve,
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, kOpPrefix, ots::kRLineCurve,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kVMoveTo,
      1, 2, 3, 4, 5, 6, 7, kOpPrefix, ots::kRLineCurve,  // invalid
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      // can't be the first op.
      1, 2, 3, 4, 5, 6, 7, 8, kOpPrefix, ots::kRLineCurve,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
}

TEST(ValidateTest, TestVHCurveTo) {
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kVMoveTo,
      // The first form.
      1, 2, 3, 4, kOpPrefix, ots::kVHCurveTo,
      1, 2, 3, 4, 5, kOpPrefix, ots::kVHCurveTo,
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, kOpPrefix, ots::kVHCurveTo,
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21,
      kOpPrefix, ots::kVHCurveTo,
      // The second form.
      1, 2, 3, 4, 5, 6, 7, 8, kOpPrefix, ots::kVHCurveTo,
      1, 2, 3, 4, 5, 6, 7, 8, 9, kOpPrefix, ots::kVHCurveTo,
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17,
      kOpPrefix, ots::kVHCurveTo,
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21,
      22, 23, 24, 25, kOpPrefix, ots::kVHCurveTo,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kVMoveTo,
      1, kOpPrefix, ots::kVHCurveTo,  // invalid
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kVMoveTo,
      1, 2, 3, kOpPrefix, ots::kVHCurveTo,  // invalid
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, 2, 3, 4, kOpPrefix, ots::kVHCurveTo,  // can't be the first op.
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
}

TEST(ValidateTest, TestVVCurveTo) {
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kVMoveTo,
      1, 2, 3, 4, kOpPrefix, ots::kVVCurveTo,
      1, 2, 3, 4, 5, kOpPrefix, ots::kVVCurveTo,
      1, 2, 3, 4, 5, 6, 7, 8, kOpPrefix, ots::kVVCurveTo,
      1, 2, 3, 4, 5, 6, 7, 8, 9, kOpPrefix, ots::kVVCurveTo,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kVMoveTo,
      kOpPrefix, ots::kVVCurveTo,  // invalid
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kVMoveTo,
      1, kOpPrefix, ots::kVVCurveTo,  // invalid
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, 2, 3, 4, kOpPrefix, ots::kVVCurveTo,  // can't be the first op.
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
}

TEST(ValidateTest, TestFlex) {
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kVMoveTo,
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, kOpPrefix, ots::kFlex,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kVMoveTo,
      kOpPrefix, ots::kFlex,  // invalid
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kVMoveTo,
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, kOpPrefix, ots::kFlex,  // invalid
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, kOpPrefix, ots::kFlex,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
}

TEST(ValidateTest, TestHFlex) {
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kVMoveTo,
      1, 2, 3, 4, 5, 6, 7, kOpPrefix, ots::kHFlex,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kVMoveTo,
      kOpPrefix, ots::kHFlex,  // invalid
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kVMoveTo,
      1, 2, 3, 4, 5, 6, kOpPrefix, ots::kHFlex,  // invalid
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, 2, 3, 4, 5, 6, 7, kOpPrefix, ots::kHFlex,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
}

TEST(ValidateTest, TestHFlex1) {
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kVMoveTo,
      1, 2, 3, 4, 5, 6, 7, 8, 9, kOpPrefix, ots::kHFlex1,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kVMoveTo,
      kOpPrefix, ots::kHFlex1,  // invalid
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kVMoveTo,
      1, 2, 3, 4, 5, 6, 7, 8, kOpPrefix, ots::kHFlex1,  // invalid
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, 2, 3, 4, 5, 6, 7, 8, 9, kOpPrefix, ots::kHFlex1,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
}

TEST(ValidateTest, TestFlex1) {
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kVMoveTo,
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, kOpPrefix, ots::kFlex1,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kVMoveTo,
      kOpPrefix, ots::kFlex1,  // invalid
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kVMoveTo,
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, kOpPrefix, ots::kFlex1,  // invalid
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, kOpPrefix, ots::kFlex1,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
}

TEST(ValidateTest, TestEndChar) {
  {
    const int char_string[] = {
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kVMoveTo,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      GET_SUBR_NUMBER(0), kOpPrefix, ots::kCallSubr,
    };
    const int local_subrs[] = {
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(Validate(char_string, ARRAYSIZE(char_string),
                         NULL, 0,
                         local_subrs, ARRAYSIZE(local_subrs)));
  }
  {
    const int char_string[] = {
      GET_SUBR_NUMBER(0), kOpPrefix, ots::kCallGSubr,
    };
    const int global_subrs[] = {
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(Validate(char_string, ARRAYSIZE(char_string),
                         global_subrs, ARRAYSIZE(global_subrs),
                         NULL, 0));
  }
}

TEST(ValidateTest, TestHStem) {
  {
    const int char_string[] = {
      1, 2, kOpPrefix, ots::kHStem,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, 2, 3, 4, kOpPrefix, ots::kHStem,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      0,  // width
      1, 2, kOpPrefix, ots::kHStem,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kVMoveTo,
      0, 1, 2, kOpPrefix, ots::kHStem,  // invalid
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kVMoveTo,
      1, 2, 3, 4, 5, kOpPrefix, ots::kHStem,  // invalid
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
}

TEST(ValidateTest, TestVStem) {
  {
    const int char_string[] = {
      1, 2, kOpPrefix, ots::kVStem,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, 2, 3, 4, kOpPrefix, ots::kVStem,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      0,  // width
      1, 2, kOpPrefix, ots::kVStem,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kVMoveTo,
      0, 1, 2, kOpPrefix, ots::kVStem,  // invalid
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kVMoveTo,
      1, 2, 3, 4, 5, kOpPrefix, ots::kVStem,  // invalid
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
}

TEST(ValidateTest, TestHStemHm) {
  {
    const int char_string[] = {
      1, 2, kOpPrefix, ots::kHStemHm,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, 2, 3, 4, kOpPrefix, ots::kHStemHm,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      0,  // width
      1, 2, kOpPrefix, ots::kHStemHm,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kVMoveTo,
      0, 1, 2, kOpPrefix, ots::kHStemHm,  // invalid
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kVMoveTo,
      1, 2, 3, 4, 5, kOpPrefix, ots::kHStemHm,  // invalid
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
}

TEST(ValidateTest, TestVStemHm) {
  {
    const int char_string[] = {
      1, 2, kOpPrefix, ots::kVStemHm,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, 2, 3, 4, kOpPrefix, ots::kVStemHm,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      0,  // width
      1, 2, kOpPrefix, ots::kVStemHm,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kVMoveTo,
      0, 1, 2, kOpPrefix, ots::kVStemHm,  // invalid
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kVMoveTo,
      1, 2, 3, 4, 5, kOpPrefix, ots::kVStemHm,  // invalid
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
}

TEST(ValidateTest, TestHintMask) {
  {
    const int char_string[] = {
      1, 2, kOpPrefix, ots::kHStem,
      kOpPrefix, ots::kHintMask, 0x00,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, 2, kOpPrefix, ots::kHStem,
      3, 4, 5, 6, kOpPrefix, ots::kHintMask, 0x00,  // vstem
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      kOpPrefix, ots::kHintMask, 0x00,  // no stems to mask
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, 2, kOpPrefix, ots::kHStem,
      3, 4, 5, kOpPrefix, ots::kHintMask, 0x00,  // invalid vstem
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
}

TEST(ValidateTest, TestCntrMask) {
  {
    const int char_string[] = {
      1, 2, kOpPrefix, ots::kHStem,
      kOpPrefix, ots::kCntrMask, 0x00,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, 2, kOpPrefix, ots::kHStem,
      3, 4, 5, 6, kOpPrefix, ots::kCntrMask, 0x00,  // vstem
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      kOpPrefix, ots::kCntrMask, 0x00,  // no stems to mask
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, 2, kOpPrefix, ots::kHStem,
      3, 4, 5, kOpPrefix, ots::kCntrMask, 0x00,  // invalid vstem
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
}

TEST(ValidateTest, TestAbs) {
  {
    const int char_string[] = {
      -1, kOpPrefix, ots::kAbs,
      2, kOpPrefix, ots::kHStem,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      kOpPrefix, ots::kAbs,  // invalid
      2, kOpPrefix, ots::kHStem,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
}

TEST(ValidateTest, TestAdd) {
  {
    const int char_string[] = {
      0, 1, kOpPrefix, ots::kAdd,
      2, kOpPrefix, ots::kHStem,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kAdd,  // invalid
      2, kOpPrefix, ots::kHStem,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
}

TEST(ValidateTest, TestSub) {
  {
    const int char_string[] = {
      2, 1, kOpPrefix, ots::kSub,
      2, kOpPrefix, ots::kHStem,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kSub,  // invalid
      2, kOpPrefix, ots::kHStem,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
}

TEST(ValidateTest, TestDiv) {
  // TODO(yusukes): Test div-by-zero.
  {
    const int char_string[] = {
      2, 1, kOpPrefix, ots::kDiv,
      2, kOpPrefix, ots::kHStem,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kDiv,  // invalid
      2, kOpPrefix, ots::kHStem,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
}

TEST(ValidateTest, TestNeg) {
  {
    const int char_string[] = {
      -1, kOpPrefix, ots::kNeg,
      2, kOpPrefix, ots::kHStem,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      kOpPrefix, ots::kNeg,  // invalid
      2, kOpPrefix, ots::kHStem,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
}

TEST(ValidateTest, TestRandom) {
  {
    const int char_string[] = {
      kOpPrefix, ots::kRandom,  // OTS rejects the operator.
      2, kOpPrefix, ots::kHStem,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
}

TEST(ValidateTest, TestMul) {
  {
    const int char_string[] = {
      2, 1, kOpPrefix, ots::kMul,
      2, kOpPrefix, ots::kHStem,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kMul,  // invalid
      2, kOpPrefix, ots::kHStem,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
}

TEST(ValidateTest, TestSqrt) {
  // TODO(yusukes): Test negative numbers.
  {
    const int char_string[] = {
      4, kOpPrefix, ots::kSqrt,
      2, kOpPrefix, ots::kHStem,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      kOpPrefix, ots::kSqrt,  // invalid
      2, kOpPrefix, ots::kHStem,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
}

TEST(ValidateTest, TestDrop) {
  {
    const int char_string[] = {
      1, 1, kOpPrefix, ots::kAdd,
      kOpPrefix, ots::kDrop,
      1, 2, kOpPrefix, ots::kHStem,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      kOpPrefix, ots::kDrop,  // invalid
      1, 2, kOpPrefix, ots::kHStem,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
}

TEST(ValidateTest, TestExch) {
  {
    const int char_string[] = {
      1, 1, kOpPrefix, ots::kAdd,
      kOpPrefix, ots::kDup,
      kOpPrefix, ots::kExch,
      kOpPrefix, ots::kHStem,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, 1, kOpPrefix, ots::kAdd,
      kOpPrefix, ots::kExch,  // invalid
      2, kOpPrefix, ots::kHStem,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
}

TEST(ValidateTest, TestIndex) {
  {
    const int char_string[] = {
      1, 2, 3, -1, kOpPrefix, ots::kIndex,  // OTS rejects the operator.
      kOpPrefix, ots::kHStem,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
}

TEST(ValidateTest, TestRoll) {
  {
    const int char_string[] = {
      1, 2, 2, 1, kOpPrefix, ots::kRoll,  // OTS rejects the operator.
      kOpPrefix, ots::kHStem,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
}

TEST(ValidateTest, TestDup) {
  {
    const int char_string[] = {
      1, 1, kOpPrefix, ots::kAdd,
      kOpPrefix, ots::kDup,
      kOpPrefix, ots::kHStem,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      kOpPrefix, ots::kDup,  // invalid
      2, kOpPrefix, ots::kHStem,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
}

TEST(ValidateTest, TestPut) {
  {
    const int char_string[] = {
      1, 10, kOpPrefix, ots::kPut,  // OTS rejects the operator.
      1, 2, kOpPrefix, ots::kHStem,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
}

TEST(ValidateTest, TestGet) {
  {
    const int char_string[] = {
      1, 10, kOpPrefix, ots::kGet,  // OTS rejects the operator.
      1, 2, kOpPrefix, ots::kHStem,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
}

TEST(ValidateTest, TestAnd) {
  {
    const int char_string[] = {
      2, 1, kOpPrefix, ots::kAnd,
      2, kOpPrefix, ots::kHStem,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kAnd,  // invalid
      2, kOpPrefix, ots::kHStem,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
}

TEST(ValidateTest, TestOr) {
  {
    const int char_string[] = {
      2, 1, kOpPrefix, ots::kOr,
      2, kOpPrefix, ots::kHStem,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kOr,  // invalid
      2, kOpPrefix, ots::kHStem,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
}

TEST(ValidateTest, TestNot) {
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kNot,
      2, kOpPrefix, ots::kHStem,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      kOpPrefix, ots::kNot,  // invalid
      2, kOpPrefix, ots::kHStem,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
}

TEST(ValidateTest, TestEq) {
  {
    const int char_string[] = {
      2, 1, kOpPrefix, ots::kEq,
      2, kOpPrefix, ots::kHStem,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, kOpPrefix, ots::kEq,  // invalid
      2, kOpPrefix, ots::kHStem,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
}

TEST(ValidateTest, TestIfElse) {
  {
    const int char_string[] = {
      1, 2, 3, 4, kOpPrefix, ots::kIfElse,
      2, kOpPrefix, ots::kHStem,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, 2, 3, kOpPrefix, ots::kIfElse,  // invalid
      2, kOpPrefix, ots::kHStem,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
}

TEST(ValidateTest, TestCallSubr) {
  // Call valid subr.
  {
    const int char_string[] = {
      GET_SUBR_NUMBER(0), kOpPrefix, ots::kCallSubr,
    };
    const int local_subrs[] = {
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(Validate(char_string, ARRAYSIZE(char_string),
                         NULL, 0,
                         local_subrs, ARRAYSIZE(local_subrs)));
  }
  // Call undefined subr.
  {
    const int char_string[] = {
      GET_SUBR_NUMBER(-1), kOpPrefix, ots::kCallSubr,
    };
    const int local_subrs[] = {
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(Validate(char_string, ARRAYSIZE(char_string),
                          NULL, 0,
                          local_subrs, ARRAYSIZE(local_subrs)));
  }
  {
    const int char_string[] = {
      GET_SUBR_NUMBER(1), kOpPrefix, ots::kCallSubr,
    };
    const int local_subrs[] = {
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(Validate(char_string, ARRAYSIZE(char_string),
                          NULL, 0,
                          local_subrs, ARRAYSIZE(local_subrs)));
  }
  {
    const int char_string[] = {
      GET_SUBR_NUMBER(-1), kOpPrefix, ots::kCallSubr,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      GET_SUBR_NUMBER(0), kOpPrefix, ots::kCallSubr,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      GET_SUBR_NUMBER(1), kOpPrefix, ots::kCallSubr,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
}

TEST(ValidateTest, TestCallGSubr) {
  // Call valid subr.
  {
    const int char_string[] = {
      GET_SUBR_NUMBER(0), kOpPrefix, ots::kCallGSubr,
    };
    const int global_subrs[] = {
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(Validate(char_string, ARRAYSIZE(char_string),
                         global_subrs, ARRAYSIZE(global_subrs),
                         NULL, 0));
  }
  // Call undefined subr.
  {
    const int char_string[] = {
      GET_SUBR_NUMBER(-1), kOpPrefix, ots::kCallGSubr,
    };
    const int global_subrs[] = {
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(Validate(char_string, ARRAYSIZE(char_string),
                          global_subrs, ARRAYSIZE(global_subrs),
                          NULL, 0));
  }
  {
    const int char_string[] = {
      GET_SUBR_NUMBER(1), kOpPrefix, ots::kCallGSubr,
    };
    const int global_subrs[] = {
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(Validate(char_string, ARRAYSIZE(char_string),
                          global_subrs, ARRAYSIZE(global_subrs),
                          NULL, 0));
  }
  {
    const int char_string[] = {
      GET_SUBR_NUMBER(-1), kOpPrefix, ots::kCallGSubr,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      GET_SUBR_NUMBER(0), kOpPrefix, ots::kCallGSubr,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      GET_SUBR_NUMBER(1), kOpPrefix, ots::kCallGSubr,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
}

TEST(ValidateTest, TestCallGSubrWithComputedValues) {
  {
    // OTS does not allow to call(g)subr with a subroutine number which is
    // not a immediate value for safety.
    const int char_string[] = {
      0, 0, kOpPrefix, ots::kAdd,
      kOpPrefix, ots::kCallGSubr,
    };
    const int global_subrs[] = {
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(Validate(char_string, ARRAYSIZE(char_string),
                          global_subrs, ARRAYSIZE(global_subrs),
                          NULL, 0));
  }
}

TEST(ValidateTest, TestInfiniteLoop) {
  {
    const int char_string[] = {
      GET_SUBR_NUMBER(0), kOpPrefix, ots::kCallSubr,
    };
    const int local_subrs[] = {
      GET_SUBR_NUMBER(0), kOpPrefix, ots::kCallSubr,
    };
    EXPECT_FALSE(Validate(char_string, ARRAYSIZE(char_string),
                          NULL, 0,
                          local_subrs, ARRAYSIZE(local_subrs)));
  }
  {
    const int char_string[] = {
      GET_SUBR_NUMBER(0), kOpPrefix, ots::kCallGSubr,
    };
    const int global_subrs[] = {
      GET_SUBR_NUMBER(0), kOpPrefix, ots::kCallGSubr,
    };
    EXPECT_FALSE(Validate(char_string, ARRAYSIZE(char_string),
                          global_subrs, ARRAYSIZE(global_subrs),
                          NULL, 0));
  }
  // mutual recursion which doesn't stop.
  {
    const int char_string[] = {
      GET_SUBR_NUMBER(0), kOpPrefix, ots::kCallSubr,
    };
    const int global_subrs[] = {
      GET_SUBR_NUMBER(0), kOpPrefix, ots::kCallSubr,
    };
    const int local_subrs[] = {
      GET_SUBR_NUMBER(0), kOpPrefix, ots::kCallGSubr,
    };
    EXPECT_FALSE(Validate(char_string, ARRAYSIZE(char_string),
                          global_subrs, ARRAYSIZE(global_subrs),
                          local_subrs, ARRAYSIZE(local_subrs)));
  }
}

TEST(ValidateTest, TestStackOverflow) {
  {
    const int char_string[] = {
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
      1, 2, 3, 4, 5, 6, 7, 8,
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_TRUE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
      1, 2, 3, 4, 5, 6, 7, 8, 9,  // overflow
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
}

TEST(ValidateTest, TestDeprecatedOperators) {
  {
    const int char_string[] = {
      kOpPrefix, 16,  // 'blend'.
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      kOpPrefix, (12 << 8) + 8,  // 'store'.
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      kOpPrefix, (12 << 8) + 13,  // 'load'.
      kOpPrefix, ots::kEndChar,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
}

TEST(ValidateTest, TestUnterminatedCharString) {
  // No endchar operator.
  {
    const int char_string[] = {
      123,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      123, 456,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
  {
    const int char_string[] = {
      123, 456, kOpPrefix, ots::kReturn,
    };
    EXPECT_FALSE(ValidateCharStrings(char_string, ARRAYSIZE(char_string)));
  }
}
