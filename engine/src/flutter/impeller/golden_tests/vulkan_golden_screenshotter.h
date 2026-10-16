// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_GOLDEN_TESTS_VULKAN_GOLDEN_SCREENSHOTTER_H_
#define FLUTTER_IMPELLER_GOLDEN_TESTS_VULKAN_GOLDEN_SCREENSHOTTER_H_

#include "flutter/impeller/golden_tests/golden_screenshotter.h"
#include "impeller/display_list/aiks_context.h"

namespace impeller {
namespace testing {

/// Converts `Picture`s and `DisplayList`s to `MetalScreenshot`s with the
/// playground backend.
class VulkanGoldenScreenshotter : public GoldenScreenshotter {
 public:
  explicit VulkanGoldenScreenshotter(
      const std::unique_ptr<PlaygroundImpl>& playground);

  ~VulkanGoldenScreenshotter();

  std::unique_ptr<Screenshot> MakeScreenshot(
      const AiksContext& aiks_context,
      const std::shared_ptr<Texture>& texture) override;

  PlaygroundImpl& GetPlayground() override;

 private:
  const std::unique_ptr<PlaygroundImpl>& playground_;
};

}  // namespace testing
}  // namespace impeller

#endif  // FLUTTER_IMPELLER_GOLDEN_TESTS_VULKAN_GOLDEN_SCREENSHOTTER_H_
