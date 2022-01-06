// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <sstream>

#include "flutter/fml/paths.h"
#include "flutter/impeller/entity/entity_shaders.h"
#include "flutter/impeller/fixtures/shader_fixtures.h"
#include "flutter/testing/testing.h"
#include "impeller/base/validation.h"
#include "impeller/image/compressed_image.h"
#include "impeller/playground/playground.h"
#include "impeller/renderer/allocator.h"
#include "impeller/renderer/backend/metal/context_mtl.h"
#include "impeller/renderer/backend/metal/formats_mtl.h"
#include "impeller/renderer/backend/metal/surface_mtl.h"
#include "impeller/renderer/backend/metal/texture_mtl.h"
#include "impeller/renderer/context.h"
#include "impeller/renderer/formats.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/renderer.h"

#define GLFW_INCLUDE_NONE
#import "third_party/glfw/include/GLFW/glfw3.h"
#define GLFW_EXPOSE_NATIVE_COCOA
#import "third_party/glfw/include/GLFW/glfw3native.h"

#include <Metal/Metal.h>
#include <QuartzCore/QuartzCore.h>

namespace impeller {

static std::vector<std::shared_ptr<fml::Mapping>>
ShaderLibraryMappingsForPlayground() {
  return {
      std::make_shared<fml::NonOwnedMapping>(impeller_entity_shaders_data,
                                             impeller_entity_shaders_length),
      std::make_shared<fml::NonOwnedMapping>(impeller_shader_fixtures_data,
                                             impeller_shader_fixtures_length),

  };
}

Playground::Playground()
    : renderer_(ContextMTL::Create(ShaderLibraryMappingsForPlayground())) {}

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

  NSWindow* cocoa_window = ::glfwGetCocoaWindow(window);
  CAMetalLayer* layer = [CAMetalLayer layer];
  layer.device = ContextMTL::Cast(*renderer_.GetContext()).GetMTLDevice();
  // This pixel format is one of the documented supported formats.
  layer.pixelFormat = ToMTLPixelFormat(PixelFormat::kDefaultColor);
  cocoa_window.contentView.layer = layer;
  cocoa_window.contentView.wantsLayer = YES;

  while (true) {
    ::glfwWaitEventsTimeout(1.0 / 30.0);

    if (::glfwWindowShouldClose(window)) {
      return true;
    }

    const auto layer_size = layer.bounds.size;
    const auto layer_scale = layer.contentsScale;
    layer.drawableSize = CGSizeMake(layer_size.width * layer_scale,
                                    layer_size.height * layer_scale);

    Renderer::RenderCallback wrapped_callback = [render_callback](auto& pass) {
      pass.SetLabel("Playground Main Render Pass");
      return render_callback(pass);
    };

    if (!renderer_.Render(SurfaceMTL::WrapCurrentMetalLayerDrawable(
                              renderer_.GetContext(), layer),
                          wrapped_callback)) {
      VALIDATION_LOG << "Could not render into the surface.";
      return false;
    }
  }

  return true;
}

std::shared_ptr<Texture> Playground::CreateTextureForFixture(
    const char* fixture_name) const {
  CompressedImage compressed_image(
      flutter::testing::OpenFixtureAsMapping(fixture_name));
  // The decoded image is immediately converted into RGBA as that format is
  // known to be supported everywhere. For image sources that don't need 32
  // bit pixel strides, this is overkill. Since this is a test fixture we
  // aren't necessarily trying to eke out memory savings here and instead
  // favor simplicity.
  auto image = compressed_image.Decode().ConvertToRGBA();
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
