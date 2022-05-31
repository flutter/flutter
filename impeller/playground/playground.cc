// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <array>
#include <memory>
#include <optional>
#include <sstream>

#include "impeller/image/decompressed_image.h"
#include "impeller/renderer/command_buffer.h"

#define GLFW_INCLUDE_NONE
#include "third_party/glfw/include/GLFW/glfw3.h"

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

struct Playground::GLFWInitializer {
  GLFWInitializer() {
    // This guard is a hack to work around a problem where glfwCreateWindow
    // hangs when opening a second window after GLFW has been reinitialized (for
    // example, when flipping through multiple playground tests).
    //
    // Explanation:
    //  * glfwCreateWindow calls [NSApp run], which begins running the event
    //    loop on the current thread.
    //  * GLFW then immediately stops the loop when
    //    applicationDidFinishLaunching is fired.
    //  * applicationDidFinishLaunching is only ever fired once during the
    //    application's lifetime, so subsequent calls to [NSApp run] will always
    //    hang with this setup.
    //  * glfwInit resets the flag that guards against [NSApp run] being
    //    called a second time, which causes the subsequent `glfwCreateWindow`
    //    to hang indefinitely in the event loop, because
    //    applicationDidFinishLaunching is never fired.
    static std::once_flag sOnceInitializer;
    std::call_once(sOnceInitializer, []() {
      FML_CHECK(::glfwInit() == GLFW_TRUE);
      ::glfwSetErrorCallback([](int code, const char* description) {
        FML_LOG(ERROR) << "GLFW Error '" << description << "'  (" << code
                       << ").";
      });
    });
  }
};

Playground::Playground()
    : glfw_initializer_(std::make_unique<GLFWInitializer>()) {}

Playground::~Playground() = default;

PlaygroundBackend Playground::GetBackend() const {
  return GetParam();
}

std::shared_ptr<Context> Playground::GetContext() const {
  return renderer_ ? renderer_->GetContext() : nullptr;
}

static constexpr bool PlatformSupportsBackend(PlaygroundBackend backend) {
  switch (backend) {
    case PlaygroundBackend::kMetal:
#if IMPELLER_ENABLE_METAL
      return true;
#else   // IMPELLER_ENABLE_METAL
      return false;
#endif  // IMPELLER_ENABLE_METAL
    case PlaygroundBackend::kOpenGLES:
#if IMPELLER_ENABLE_OPENGLES
      return true;
#else   // IMPELLER_ENABLE_OPENGLES
      return false;
#endif  // IMPELLER_ENABLE_OPENGLES
  }
  FML_UNREACHABLE();
}

void Playground::SetUp() {
  if (!PlatformSupportsBackend(GetBackend())) {
    GTEST_SKIP_("This backend is disabled or isn't supported on this platform");
  }

  impl_ = PlaygroundImpl::Create(GetParam());
  if (!impl_) {
    return;
  }
  auto context = impl_->GetContext();
  if (!context) {
    return;
  }
  auto renderer = std::make_unique<Renderer>(std::move(context));
  if (!renderer->IsValid()) {
    return;
  }
  renderer_ = std::move(renderer);
}

void Playground::TearDown() {
  renderer_.reset();
  impl_.reset();
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

Point Playground::GetContentScale() const {
  return impl_->GetContentScale();
}

void Playground::SetCursorPosition(Point pos) {
  cursor_position_ = pos;
}

bool Playground::OpenPlaygroundHere(Renderer::RenderCallback render_callback) {
  if (!is_enabled()) {
    return true;
  }

  if (!render_callback) {
    return true;
  }

  if (!renderer_ || !renderer_->IsValid()) {
    return false;
  }

  IMGUI_CHECKVERSION();
  ImGui::CreateContext();
  fml::ScopedCleanupClosure destroy_imgui_context(
      []() { ImGui::DestroyContext(); });
  ImGui::StyleColorsDark();
  ImGui::GetIO().IniFilename = nullptr;

  auto window = reinterpret_cast<GLFWwindow*>(impl_->GetWindowHandle());
  if (!window) {
    return false;
  }
  ::glfwSetWindowTitle(
      window, GetWindowTitle(flutter::testing::GetCurrentTestName()).c_str());
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

  ImGui_ImplGlfw_InitForOther(window, true);
  fml::ScopedCleanupClosure shutdown_imgui([]() { ImGui_ImplGlfw_Shutdown(); });

  ImGui_ImplImpeller_Init(renderer_->GetContext());
  fml::ScopedCleanupClosure shutdown_imgui_impeller(
      []() { ImGui_ImplImpeller_Shutdown(); });

  ::glfwSetWindowSize(window, GetWindowSize().width, GetWindowSize().height);
  ::glfwSetWindowPos(window, 200, 100);
  ::glfwShowWindow(window);

  while (true) {
    ::glfwWaitEventsTimeout(1.0 / 30.0);

    if (::glfwWindowShouldClose(window)) {
      return true;
    }

    ImGui_ImplGlfw_NewFrame();

    Renderer::RenderCallback wrapped_callback =
        [render_callback,
         &renderer = renderer_](RenderTarget& render_target) -> bool {
      ImGui::NewFrame();
      bool result = render_callback(render_target);
      ImGui::Render();

      // Render ImGui overlay.
      {
        auto buffer = renderer->GetContext()->CreateRenderCommandBuffer();
        if (!buffer) {
          return false;
        }
        buffer->SetLabel("ImGui Command Buffer");

        if (render_target.GetColorAttachments().empty()) {
          return false;
        }
        auto color0 = render_target.GetColorAttachments().find(0)->second;
        color0.load_action = LoadAction::kLoad;
        render_target.SetColorAttachment(color0, 0);
        auto pass = buffer->CreateRenderPass(render_target);
        if (!pass) {
          return false;
        }
        pass->SetLabel("ImGui Render Pass");

        ImGui_ImplImpeller_RenderDrawData(ImGui::GetDrawData(), *pass);

        pass->EncodeCommands(renderer->GetContext()->GetTransientsAllocator());
        if (!buffer->SubmitCommands()) {
          return false;
        }
      }

      return result;
    };

    if (!renderer_->Render(impl_->AcquireSurfaceFrame(renderer_->GetContext()),
                           wrapped_callback)) {
      VALIDATION_LOG << "Could not render into the surface.";
      return false;
    }
  }

  ::glfwHideWindow(window);

  return true;
}

bool Playground::OpenPlaygroundHere(SinglePassCallback pass_callback) {
  return OpenPlaygroundHere(
      [context = GetContext(), &pass_callback](RenderTarget& render_target) {
        auto buffer = context->CreateRenderCommandBuffer();
        if (!buffer) {
          return false;
        }
        buffer->SetLabel("Playground Command Buffer");

        auto pass = buffer->CreateRenderPass(render_target);
        if (!pass) {
          return false;
        }
        pass->SetLabel("Playground Render Pass");

        if (!pass_callback(*pass)) {
          return false;
        }

        pass->EncodeCommands(context->GetTransientsAllocator());
        if (!buffer->SubmitCommands()) {
          return false;
        }
        return true;
      });
}

std::optional<DecompressedImage> Playground::LoadFixtureImageRGBA(
    const char* fixture_name) const {
  if (!renderer_) {
    return std::nullopt;
  }

  auto compressed_image = CompressedImage::Create(
      flutter::testing::OpenFixtureAsMapping(fixture_name));
  if (!compressed_image) {
    VALIDATION_LOG << "Could not create compressed image.";
    return std::nullopt;
  }
  // The decoded image is immediately converted into RGBA as that format is
  // known to be supported everywhere. For image sources that don't need 32
  // bit pixel strides, this is overkill. Since this is a test fixture we
  // aren't necessarily trying to eke out memory savings here and instead
  // favor simplicity.
  auto image = compressed_image->Decode().ConvertToRGBA();
  if (!image.IsValid()) {
    VALIDATION_LOG << "Could not find fixture named " << fixture_name;
    return std::nullopt;
  }

  return image;
}

std::shared_ptr<Texture> Playground::CreateTextureForFixture(
    const char* fixture_name) const {
  auto image = LoadFixtureImageRGBA(fixture_name);
  if (!image.has_value()) {
    return nullptr;
  }

  auto texture_descriptor = TextureDescriptor{};
  texture_descriptor.format = PixelFormat::kR8G8B8A8UNormInt;
  texture_descriptor.size = image->GetSize();
  texture_descriptor.mip_count = 1u;

  auto texture =
      renderer_->GetContext()->GetPermanentsAllocator()->CreateTexture(
          StorageMode::kHostVisible, texture_descriptor);
  if (!texture) {
    VALIDATION_LOG << "Could not allocate texture for fixture " << fixture_name;
    return nullptr;
  }
  texture->SetLabel(fixture_name);

  auto uploaded = texture->SetContents(image->GetAllocation());
  if (!uploaded) {
    VALIDATION_LOG << "Could not upload texture to device memory for fixture "
                   << fixture_name;
    return nullptr;
  }
  return texture;
}

std::shared_ptr<Texture> Playground::CreateTextureCubeForFixture(
    std::array<const char*, 6> fixture_names) const {
  std::array<DecompressedImage, 6> images;
  for (size_t i = 0; i < fixture_names.size(); i++) {
    auto image = LoadFixtureImageRGBA(fixture_names[i]);
    if (!image.has_value()) {
      return nullptr;
    }
    images[i] = image.value();
  }

  auto texture_descriptor = TextureDescriptor{};
  texture_descriptor.type = TextureType::kTextureCube;
  texture_descriptor.format = PixelFormat::kR8G8B8A8UNormInt;
  texture_descriptor.size = images[0].GetSize();
  texture_descriptor.mip_count = 1u;

  auto texture =
      renderer_->GetContext()->GetPermanentsAllocator()->CreateTexture(
          StorageMode::kHostVisible, texture_descriptor);
  if (!texture) {
    VALIDATION_LOG << "Could not allocate texture cube.";
    return nullptr;
  }
  texture->SetLabel("Texture cube");

  for (size_t i = 0; i < fixture_names.size(); i++) {
    auto uploaded =
        texture->SetContents(images[i].GetAllocation()->GetMapping(),
                             images[i].GetAllocation()->GetSize(), i);
    if (!uploaded) {
      VALIDATION_LOG << "Could not upload texture to device memory.";
      return nullptr;
    }
  }

  return texture;
}

void Playground::SetWindowSize(ISize size) {
  window_size_ = size;
}

}  // namespace impeller
