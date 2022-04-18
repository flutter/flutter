// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <sstream>

#define GLFW_INCLUDE_NONE
#import "third_party/glfw/include/GLFW/glfw3.h"

#include "flutter/fml/paths.h"
#include "flutter/testing/testing.h"
#include "impeller/base/validation.h"
#include "impeller/image/compressed_image.h"
#include "impeller/playground/imgui/imgui_impl_impeller.h"
#include "impeller/playground/playground.h"
#include "impeller/playground/playground_impl.h"
#include "impeller/renderer/allocator.h"
#include "impeller/renderer/context.h"
#include "impeller/renderer/formats.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/renderer.h"
#include "third_party/imgui/backends/imgui_impl_glfw.h"
#include "third_party/imgui/imgui.h"

namespace impeller {

std::string PlaygroundBackendToString(PlaygroundBackend backend) {
  switch (backend) {
    case PlaygroundBackend::kMetal:
      return "Metal";
    case PlaygroundBackend::kOpenGLES:
      return "OpenGLES";
  }
  FML_UNREACHABLE();
}

Playground::Playground()
    : impl_(PlaygroundImpl::Create(GetParam())),
      renderer_(impl_->CreateContext()),
      is_valid_(Playground::is_enabled() && renderer_.IsValid()) {}

Playground::~Playground() = default;

bool Playground::IsValid() const {
  return is_valid_;
}

PlaygroundBackend Playground::GetBackend() const {
  return GetParam();
}

std::shared_ptr<Context> Playground::GetContext() const {
  return IsValid() ? renderer_.GetContext() : nullptr;
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

Point Playground::GetCursorPosition() const {
  return cursor_position_;
}

ISize Playground::GetWindowSize() const {
  return window_size_;
}

void Playground::SetCursorPosition(Point pos) {
  cursor_position_ = pos;
}

bool Playground::OpenPlaygroundHere(Renderer::RenderCallback render_callback) {
  if (!is_enabled()) {
    return true;
  }

  if (!IsValid()) {
    return false;
  }

  if (!render_callback) {
    return true;
  }

  if (!renderer_.IsValid()) {
    return false;
  }

  IMGUI_CHECKVERSION();
  ImGui::CreateContext();
  fml::ScopedCleanupClosure destroy_imgui_context(
      []() { ImGui::DestroyContext(); });
  ImGui::StyleColorsDark();
  ImGui::GetIO().IniFilename = nullptr;

  // This guard is a hack to work around a problem where glfwCreateWindow
  // hangs when opening a second window after GLFW has been reinitialized (for
  // example, when flipping through multiple playground tests).
  //
  // Explanation:
  //  * glfwCreateWindow calls [NSApp run], which begins running the event loop
  //    on the current thread.
  //  * GLFW then immediately stops the loop when applicationDidFinishLaunching
  //    is fired.
  //  * applicationDidFinishLaunching is only ever fired once during the
  //    application's lifetime, so subsequent calls to [NSApp run] will always
  //    hang with this setup.
  //  * glfwInit resets the flag that guards against [NSApp run] being
  //    called a second time, which causes the subsequent `glfwCreateWindow` to
  //    hang indefinitely in the event loop, because
  //    applicationDidFinishLaunching is never fired.
  static bool first_run = true;
  if (first_run) {
    first_run = false;
    if (::glfwInit() != GLFW_TRUE) {
      return false;
    }
  }

  ::glfwWindowHint(GLFW_CLIENT_API, GLFW_NO_API);

  auto window_title = GetWindowTitle(flutter::testing::GetCurrentTestName());
  auto window =
      ::glfwCreateWindow(GetWindowSize().width, GetWindowSize().height,
                         window_title.c_str(), NULL, NULL);
  if (!window) {
    return false;
  }

  ::glfwSetWindowUserPointer(window, this);
  ::glfwSetWindowSizeCallback(
      window, [](GLFWwindow* window, int width, int height) -> void {
        auto playground =
            reinterpret_cast<Playground*>(::glfwGetWindowUserPointer(window));
        if (!playground) {
          return;
        }
        playground->SetWindowSize(
            ISize{std::max(width, 0), std::max(height, 0)});
      });
  ::glfwSetKeyCallback(window, &PlaygroundKeyCallback);
  ::glfwSetCursorPosCallback(window, [](GLFWwindow* window, double x,
                                        double y) {
    reinterpret_cast<Playground*>(::glfwGetWindowUserPointer(window))
        ->SetCursorPosition({static_cast<Scalar>(x), static_cast<Scalar>(y)});
  });

  fml::ScopedCleanupClosure close_window(
      [window]() { ::glfwDestroyWindow(window); });

  ImGui_ImplGlfw_InitForOther(window, true);
  fml::ScopedCleanupClosure shutdown_imgui([]() { ImGui_ImplGlfw_Shutdown(); });

  ImGui_ImplImpeller_Init(renderer_.GetContext());
  fml::ScopedCleanupClosure shutdown_imgui_impeller(
      []() { ImGui_ImplImpeller_Shutdown(); });

  if (!impl_->SetupWindow(window, renderer_.GetContext())) {
    return false;
  }

  while (true) {
    ::glfwWaitEventsTimeout(1.0 / 30.0);

    if (::glfwWindowShouldClose(window)) {
      return true;
    }

    ImGui_ImplGlfw_NewFrame();

    Renderer::RenderCallback wrapped_callback = [render_callback](auto& pass) {
      pass.SetLabel("Playground Main Render Pass");

      ImGui::NewFrame();
      bool result = render_callback(pass);
      ImGui::Render();
      ImGui_ImplImpeller_RenderDrawData(ImGui::GetDrawData(), pass);
      return result;
    };

    if (!renderer_.Render(impl_->AcquireSurfaceFrame(renderer_.GetContext()),
                          wrapped_callback)) {
      VALIDATION_LOG << "Could not render into the surface.";
      return false;
    }
  }

  if (!impl_->TeardownWindow(window, renderer_.GetContext())) {
    return false;
  }

  return true;
}

std::shared_ptr<Texture> Playground::CreateTextureForFixture(
    const char* fixture_name) const {
  if (!IsValid()) {
    return nullptr;
  }

  auto compressed_image = CompressedImage::Create(
      flutter::testing::OpenFixtureAsMapping(fixture_name));
  if (!compressed_image) {
    VALIDATION_LOG << "Could not create compressed image.";
    return nullptr;
  }
  // The decoded image is immediately converted into RGBA as that format is
  // known to be supported everywhere. For image sources that don't need 32
  // bit pixel strides, this is overkill. Since this is a test fixture we
  // aren't necessarily trying to eke out memory savings here and instead
  // favor simplicity.
  auto image = compressed_image->Decode().ConvertToRGBA();
  if (!image.IsValid()) {
    VALIDATION_LOG << "Could not find fixture named " << fixture_name;
    return nullptr;
  }

  auto texture_descriptor = TextureDescriptor{};
  // We just converted to RGBA above.
  texture_descriptor.format = PixelFormat::kR8G8B8A8UNormInt;
  texture_descriptor.size = image.GetSize();
  texture_descriptor.mip_count = 1u;

  auto texture =
      renderer_.GetContext()->GetPermanentsAllocator()->CreateTexture(
          StorageMode::kHostVisible, texture_descriptor);
  if (!texture) {
    VALIDATION_LOG << "Could not allocate texture for fixture " << fixture_name;
    return nullptr;
  }
  texture->SetLabel(fixture_name);

  auto uploaded = texture->SetContents(image.GetAllocation()->GetMapping(),
                                       image.GetAllocation()->GetSize());
  if (!uploaded) {
    VALIDATION_LOG << "Could not upload texture to device memory for fixture "
                   << fixture_name;
    return nullptr;
  }
  return texture;
}

void Playground::SetWindowSize(ISize size) {
  window_size_ = size;
}

}  // namespace impeller
