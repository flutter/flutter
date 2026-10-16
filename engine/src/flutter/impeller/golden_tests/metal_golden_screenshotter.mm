// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <dlfcn.h>
#include <filesystem>
#include <memory>

#include "flutter/impeller/golden_tests/metal_golden_screenshotter.h"

#include "flutter/impeller/testing/metal/metal_screenshotter.h"
#include "third_party/glfw/include/GLFW/glfw3.h"

namespace impeller {
namespace testing {

MetalGoldenScreenshotter::MetalGoldenScreenshotter(
    const PlaygroundSwitches& switches) {
  FML_CHECK(::glfwInit() == GLFW_TRUE);
  playground_ = PlaygroundImpl::Create(PlaygroundBackend::kMetal, switches);
}

MetalGoldenScreenshotter::~MetalGoldenScreenshotter() = default;

std::unique_ptr<Screenshot> MetalGoldenScreenshotter::MakeScreenshot(
    const AiksContext& aiks_context,
    const std::shared_ptr<Texture>& texture) {
  return MetalScreenshotter::MakeScreenshot(aiks_context.GetContext(), texture);
}

PlaygroundImpl& MetalGoldenScreenshotter::GetPlayground() {
  return *playground_;
}

}  // namespace testing
}  // namespace impeller
