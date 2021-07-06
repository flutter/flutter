// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <sstream>

#include "flutter/fml/paths.h"
#include "flutter/testing/testing.h"
#include "impeller/compositor/context.h"
#include "impeller/compositor/formats_metal.h"
#include "impeller/compositor/render_pass.h"
#include "impeller/compositor/renderer.h"
#include "impeller/compositor/surface.h"
#include "impeller/playground/playground.h"

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

static std::string GetWindowTitle(const std::string& test_name) {
  std::stringstream stream;
  stream << "Impeller Playground for '" << test_name
         << "' (Press ESC or 'q' to quit)";
  return stream.str();
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
  // Recreation of the target render buffer is not setup in the playground yet.
  // So prevent users from resizing and getting confused that their math is
  // wrong.
  ::glfwWindowHint(GLFW_RESIZABLE, false);

  auto window_title = GetWindowTitle(flutter::testing::GetCurrentTestName());
  auto window = ::glfwCreateWindow(1024, 768, window_title.c_str(), NULL, NULL);
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

    TextureDescriptor color0_desc;
    color0_desc.format = PixelFormat::kPixelFormat_B8G8R8A8_UNormInt;
    color0_desc.size = {
        static_cast<ISize::Type>(current_drawable.texture.width),
        static_cast<ISize::Type>(current_drawable.texture.height)};

    ColorRenderPassAttachment color0;
    color0.texture =
        std::make_shared<Texture>(color0_desc, current_drawable.texture);
    color0.clear_color = Color::SkyBlue();
    color0.load_action = LoadAction::kClear;
    color0.store_action = StoreAction::kStore;

    RenderPassDescriptor desc;
    desc.SetColorAttachment(color0, 0u);

    Surface surface(desc);

    Renderer::RenderCallback wrapped_callback =
        [render_callback](const auto& surface, auto& pass) {
          pass.SetLabel("Playground Main Render Pass");
          return render_callback(surface, pass);
        };

    if (!renderer_.Render(surface, wrapped_callback)) {
      FML_LOG(ERROR) << "Could not render into the surface.";
      return false;
    }

    [current_drawable present];
  }

  return true;
}

}  // namespace impeller
