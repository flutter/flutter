// Copyright (c) 2010 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef OTS_CFF_TYPE2_CHARSTRING_H_
#define OTS_CFF_TYPE2_CHARSTRING_H_

#include "cff.h"
#include "ots.h"

#include <map>
#include <vector>

namespace ots {

// Validates all charstrings in |char_strings_index|. Charstring is a small
// language for font hinting defined in Adobe Technical Note #5177.
// http://www.adobe.com/devnet/font/pdfs/5177.Type2.pdf
//
// The validation will fail if one of the following conditions is met:
//  1. The code uses more than 48 values of argument stack.
//  2. The code uses deeply nested subroutine calls (more than 10 levels.)
//  3. The code passes invalid number of operands to an operator.
//  4. The code calls an undefined global or local subroutine.
//  5. The code uses one of the following operators that are unlikely used in
//     an ordinary fonts, and could be dangerous: random, put, get, index, roll.
//
// Arguments:
//  global_subrs_index: Global subroutines which could be called by a charstring
//                      in |char_strings_index|.
//  fd_select: A map from glyph # to font #.
//  local_subrs_per_font: A list of Local Subrs associated with FDArrays. Can be
//                        empty.
//  local_subrs: A Local Subrs associated with Top DICT. Can be NULL.
//  cff_table: A buffer which contains actual byte code of charstring, global
//             subroutines and local subroutines.
bool ValidateType2CharStringIndex(
    OpenTypeFile *file,
    const CFFIndex &char_strings_index,
    const CFFIndex &global_subrs_index,
    const std::map<uint16_t, uint8_t> &fd_select,
    const std::vector<CFFIndex *> &local_subrs_per_font,
    const CFFIndex *local_subrs,
    Buffer *cff_table);

// The list of Operators. See Appendix. A in Adobe Technical Note #5177.
enum Type2CharStringOperator {
  kHStem = 1,
  kVStem = 3,
  kVMoveTo = 4,
  kRLineTo = 5,
  kHLineTo = 6,
  kVLineTo = 7,
  kRRCurveTo = 8,
  kCallSubr = 10,
  kReturn = 11,
  kEndChar = 14,
  kHStemHm = 18,
  kHintMask = 19,
  kCntrMask = 20,
  kRMoveTo = 21,
  kHMoveTo = 22,
  kVStemHm = 23,
  kRCurveLine = 24,
  kRLineCurve = 25,
  kVVCurveTo = 26,
  kHHCurveTo = 27,
  kCallGSubr = 29,
  kVHCurveTo = 30,
  kHVCurveTo = 31,
  kDotSection = 12 << 8,
  kAnd = (12 << 8) + 3,
  kOr = (12 << 8) + 4,
  kNot = (12 << 8) + 5,
  kAbs = (12 << 8) + 9,
  kAdd = (12 << 8) + 10,
  kSub = (12 << 8) + 11,
  kDiv = (12 << 8) + 12,
  kNeg = (12 << 8) + 14,
  kEq = (12 << 8) + 15,
  kDrop = (12 << 8) + 18,
  kPut = (12 << 8) + 20,
  kGet = (12 << 8) + 21,
  kIfElse = (12 << 8) + 22,
  kRandom = (12 << 8) + 23,
  kMul = (12 << 8) + 24,
  kSqrt = (12 << 8) + 26,
  kDup = (12 << 8) + 27,
  kExch = (12 << 8) + 28,
  kIndex = (12 << 8) + 29,
  kRoll = (12 << 8) + 30,
  kHFlex = (12 << 8) + 34,
  kFlex = (12 << 8) + 35,
  kHFlex1 = (12 << 8) + 36,
  kFlex1 = (12 << 8) + 37,
  // Operators that are undocumented, such as 'blend', will be rejected.
};

}  // namespace ots

#endif  // OTS_CFF_TYPE2_CHARSTRING_H_
