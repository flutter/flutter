// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GFX_TEST_GFX_UTIL_H_
#define UI_GFX_TEST_GFX_UTIL_H_

#include <iosfwd>
#include <string>

#include "testing/gtest/include/gtest/gtest.h"
#include "third_party/skia/include/core/SkColor.h"
#include "ui/gfx/box_f.h"
#include "ui/gfx/geometry/rect_f.h"

namespace gfx {

// Checks that the box coordinates are each almost equal floats.
#define EXPECT_BOXF_EQ(a, b) \
  EXPECT_PRED_FORMAT2(::gfx::AssertBoxFloatEqual, a, b)

::testing::AssertionResult AssertBoxFloatEqual(const char* lhs_expr,
                                               const char* rhs_expr,
                                               const BoxF& lhs,
                                               const BoxF& rhs);

#define EXPECT_RECTF_EQ(a, b) \
  EXPECT_PRED_FORMAT2(::gfx::AssertRectFloatEqual, a, b)

::testing::AssertionResult AssertRectFloatEqual(const char* lhs_expr,
                                                const char* rhs_expr,
                                                const RectF& lhs,
                                                const RectF& rhs);

#define EXPECT_SKCOLOR_EQ(a, b) \
  EXPECT_PRED_FORMAT2(::gfx::AssertSkColorsEqual, a, b)

::testing::AssertionResult AssertSkColorsEqual(const char* lhs_expr,
                                               const char* rhs_expr,
                                               SkColor lhs,
                                               SkColor rhs);

}  // namespace gfx

#endif  // UI_GFX_TEST_GFX_UTIL_H_
