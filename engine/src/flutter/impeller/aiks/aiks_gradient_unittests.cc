// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/aiks/aiks_unittests.h"

#include "impeller/aiks/canvas.h"
#include "impeller/entity/contents/conical_gradient_contents.h"
#include "impeller/entity/contents/linear_gradient_contents.h"
#include "impeller/entity/contents/radial_gradient_contents.h"
#include "impeller/entity/contents/sweep_gradient_contents.h"
#include "impeller/geometry/geometry_asserts.h"
#include "impeller/geometry/path_builder.h"
#include "impeller/playground/widgets.h"
#include "third_party/imgui/imgui.h"

////////////////////////////////////////////////////////////////////////////////
// This is for tests of Canvas that are interested the results of rendering
// gradients.
////////////////////////////////////////////////////////////////////////////////

namespace impeller {
namespace testing {

#define APPLY_COLOR_FILTER_GRADIENT_TEST(name)                                 \
  TEST_P(AiksTest, name##GradientApplyColorFilter) {                           \
    auto contents = name##GradientContents();                                  \
    contents.SetColors({Color::CornflowerBlue().WithAlpha(0.75)});             \
    auto result = contents.ApplyColorFilter([](const Color& color) {           \
      return color.Blend(Color::LimeGreen().WithAlpha(0.75),                   \
                         BlendMode::kScreen);                                  \
    });                                                                        \
    ASSERT_TRUE(result);                                                       \
                                                                               \
    std::vector<Color> expected = {Color(0.433247, 0.879523, 0.825324, 0.75)}; \
    ASSERT_COLORS_NEAR(contents.GetColors(), expected);                        \
  }

APPLY_COLOR_FILTER_GRADIENT_TEST(Linear);
APPLY_COLOR_FILTER_GRADIENT_TEST(Radial);
APPLY_COLOR_FILTER_GRADIENT_TEST(Conical);
APPLY_COLOR_FILTER_GRADIENT_TEST(Sweep);

}  // namespace testing
}  // namespace impeller