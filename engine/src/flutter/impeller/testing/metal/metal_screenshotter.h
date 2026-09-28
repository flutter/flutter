// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_TESTING_METAL_METAL_SCREENSHOTTER_H_
#define FLUTTER_IMPELLER_TESTING_METAL_METAL_SCREENSHOTTER_H_

#include "flutter/impeller/testing/screenshotter.h"
#include "impeller/display_list/aiks_context.h"

namespace impeller {
namespace testing {

/// Converts `Picture`s and `DisplayList`s to `MetalScreenshot`s with the
/// playground backend.
class MetalScreenshotter : public Screenshotter {
 public:
  explicit MetalScreenshotter();

  static std::unique_ptr<Screenshot> MakeScreenshot(
      const std::shared_ptr<Context>& context,
      const std::shared_ptr<Texture>& texture);

  std::unique_ptr<Screenshot> MakeScreenshot(
      const AiksContext& aiks_context,
      const std::shared_ptr<Texture>& texture) override;
};

}  // namespace testing
}  // namespace impeller

#endif  // FLUTTER_IMPELLER_TESTING_METAL_METAL_SCREENSHOTTER_H_
