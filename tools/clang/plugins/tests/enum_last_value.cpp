// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// We warn when xxxLAST constants aren't last.
enum BadOne {
  kBadOneInvalid = -1,
  kBadOneRed,
  kBadOneGreen,
  kBadOneBlue,
  kBadOneLast = kBadOneGreen
};

// We warn when xxx_LAST constants aren't last.
enum BadTwo {
  BAD_TWO_INVALID,
  BAD_TWO_RED,
  BAD_TWO_GREEN,
  BAD_TWO_BLUE = 0xfffffffc,
  BAD_TWO_LAST = BAD_TWO_GREEN
};

// We don't warn when xxxLAST constants are last.
enum GoodOne {
  kGoodOneInvalid = -1,
  kGoodOneRed,
  kGoodOneGreen,
  kGoodOneBlue,
  kGoodOneLast = kGoodOneBlue
};

// We don't warn when xxx_LAST constants are last.
enum GoodTwo {
  GOOD_TWO_INVALID,
  GOOD_TWO_RED,
  GOOD_TWO_GREEN,
  GOOD_TWO_BLUE = 0xfffffffc,
  GOOD_TWO_LAST = GOOD_TWO_BLUE
};
