// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "flutter/impeller/aiks/picture.h"
#include "flutter/impeller/golden_tests/metal_screenshot.h"
#include "flutter/impeller/playground/playground_impl.h"

namespace impeller {
namespace testing {

/// Converts `Picture`s and `DisplayList`s to `MetalScreenshot`s with the
/// playground backend.
class MetalScreenshotter {
 public:
  MetalScreenshotter();

  std::unique_ptr<MetalScreenshot> MakeScreenshot(AiksContext& aiks_context,
                                                  const Picture& picture,
                                                  const ISize& size = {300,
                                                                       300},
                                                  bool scale_content = true);

  const PlaygroundImpl& GetPlayground() const { return *playground_; }

 private:
  std::unique_ptr<PlaygroundImpl> playground_;
};

}  // namespace testing
}  // namespace impeller
