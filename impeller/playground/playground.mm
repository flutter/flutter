// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/playground/playground.h"
#include "flutter/testing/testing.h"
#include "impeller/compositor/context.h"
#include "impeller/compositor/render_pass.h"
#include "impeller/compositor/surface.h"

#define GLFW_INCLUDE_NONE
#import "third_party/glfw/include/GLFW/glfw3.h"
#define GLFW_EXPOSE_NATIVE_COCOA
#import "third_party/glfw/include/GLFW/glfw3native.h"

#include <Metal/Metal.h>
#include <QuartzCore/QuartzCore.h>

namespace impeller {

Playground::Playground() = default;

Playground::~Playground() = default;

bool Playground::OpenPlaygroundHere(std::function<bool()> closure) {
  if (!closure) {
    return true;
  }

  Context context(flutter::testing::GetFixturesPath());

  if (!context.IsValid()) {
    return false;
  }

  if (::glfwInit() != GLFW_TRUE) {
    return false;
  }
  fml::ScopedCleanupClosure terminate([]() { ::glfwTerminate(); });

  ::glfwWindowHint(GLFW_CLIENT_API, GLFW_NO_API);

  auto window = ::glfwCreateWindow(800, 600, "Impeller Playground", NULL, NULL);
  if (!window) {
    return false;
  }

  fml::ScopedCleanupClosure close_window(
      [window]() { ::glfwDestroyWindow(window); });

  NSWindow* cocoa_window = ::glfwGetCocoaWindow(window);
  CAMetalLayer* layer = [CAMetalLayer layer];
  layer.device = context.GetMTLDevice();
  layer.pixelFormat = MTLPixelFormatBGRA8Unorm;
  cocoa_window.contentView.layer = layer;
  cocoa_window.contentView.wantsLayer = YES;

  while (true) {
    ::glfwWaitEventsTimeout(1.0 / 30.0);

    if (::glfwWindowShouldClose(window)) {
      return true;
    }

    auto current_drawable = [layer nextDrawable];

    if (!current_drawable) {
      FML_LOG(ERROR) << "Could not acquire current drawable.";
      return false;
    }

    ColorRenderPassAttachment color0;
    color0.texture = std::make_shared<Texture>(current_drawable.texture);
    color0.clear_color = Color::SkyBlue();
    color0.load_action = LoadAction::kClear;
    color0.store_action = StoreAction::kStore;

    RenderPassDescriptor desc;
    desc.SetColorAttachment(color0, 0u);

    Surface surface(desc, [current_drawable, closure]() {
      if (!closure()) {
        return false;
      }
      [current_drawable present];
      return true;
    });

    if (!surface.IsValid()) {
      FML_LOG(ERROR) << "Could not wrap surface to render to into.";
      return false;
    }

    if (!surface.Present()) {
      FML_LOG(ERROR) << "Could not render into playground surface.";
      return false;
    }
  }

  return true;
}

}  // namespace impeller
