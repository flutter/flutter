// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/playground/playground.h"
#include "flutter/fml/paths.h"
#include "flutter/testing/testing.h"
#include "impeller/compositor/context.h"
#include "impeller/compositor/render_pass.h"
#include "impeller/compositor/renderer.h"
#include "impeller/compositor/surface.h"

#define GLFW_INCLUDE_NONE
#import "third_party/glfw/include/GLFW/glfw3.h"
#define GLFW_EXPOSE_NATIVE_COCOA
#import "third_party/glfw/include/GLFW/glfw3native.h"

#include <Metal/Metal.h>
#include <QuartzCore/QuartzCore.h>

namespace impeller {

static std::string ShaderLibraryDirectory() {
  auto path_result = fml::paths::GetExecutableDirectoryPath();
  if (!path_result.first) {
    return {};
  }
  return fml::paths::JoinPaths({path_result.second, "shaders"});
}

Playground::Playground() : renderer_(ShaderLibraryDirectory()) {}

Playground::~Playground() = default;

std::shared_ptr<Context> Playground::GetContext() const {
  return renderer_.IsValid() ? renderer_.GetContext() : nullptr;
}

static void PlaygroundKeyCallback(GLFWwindow* window,
                                  int key,
                                  int scancode,
                                  int action,
                                  int mods) {
  if ((key == GLFW_KEY_ESCAPE || key == GLFW_KEY_Q) && action == GLFW_RELEASE) {
    ::glfwSetWindowShouldClose(window, GLFW_TRUE);
  }
}

bool Playground::OpenPlaygroundHere(Renderer::RenderCallback render_callback) {
  if (!render_callback) {
    return true;
  }

  if (!renderer_.IsValid()) {
    return false;
  }

  if (::glfwInit() != GLFW_TRUE) {
    return false;
  }
  fml::ScopedCleanupClosure terminate([]() { ::glfwTerminate(); });

  ::glfwWindowHint(GLFW_CLIENT_API, GLFW_NO_API);

  auto window = ::glfwCreateWindow(
      800, 600, "Impeller Playground (Press ESC or 'q' to quit)", NULL, NULL);
  if (!window) {
    return false;
  }

  ::glfwSetWindowUserPointer(window, this);
  ::glfwSetKeyCallback(window, &PlaygroundKeyCallback);

  fml::ScopedCleanupClosure close_window(
      [window]() { ::glfwDestroyWindow(window); });

  NSWindow* cocoa_window = ::glfwGetCocoaWindow(window);
  CAMetalLayer* layer = [CAMetalLayer layer];
  layer.device = renderer_.GetContext()->GetMTLDevice();
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

    Surface surface(desc);

    if (!renderer_.Render(surface, render_callback)) {
      FML_LOG(ERROR) << "Could not render into the surface.";
      return false;
    }

    [current_drawable present];
  }

  return true;
}

}  // namespace impeller
