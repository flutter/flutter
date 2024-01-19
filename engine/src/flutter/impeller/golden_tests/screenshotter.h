// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_GOLDEN_TESTS_SCREENSHOTTER_H_
#define FLUTTER_IMPELLER_GOLDEN_TESTS_SCREENSHOTTER_H_

#include "flutter/fml/macros.h"
#include "flutter/impeller/aiks/picture.h"
#include "flutter/impeller/golden_tests/screenshot.h"
#include "flutter/impeller/playground/playground_impl.h"

namespace impeller {
namespace testing {

/// Converts `Picture`s and `DisplayList`s to `MetalScreenshot`s with the
/// playground backend.
class Screenshotter {
 public:
  virtual ~Screenshotter() = default;

  virtual std::unique_ptr<Screenshot> MakeScreenshot(
      AiksContext& aiks_context,
      const Picture& picture,
      const ISize& size = {300, 300},
      bool scale_content = true) = 0;

  virtual PlaygroundImpl& GetPlayground() = 0;
};

}  // namespace testing
}  // namespace impeller

#endif  // FLUTTER_IMPELLER_GOLDEN_TESTS_SCREENSHOTTER_H_
