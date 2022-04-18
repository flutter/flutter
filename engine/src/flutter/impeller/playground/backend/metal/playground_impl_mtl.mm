// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/playground/backend/metal/playground_impl_mtl.h"

#define GLFW_INCLUDE_NONE
#import "third_party/glfw/include/GLFW/glfw3.h"

#define GLFW_EXPOSE_NATIVE_COCOA
#import "third_party/glfw/include/GLFW/glfw3native.h"

#include <Metal/Metal.h>
#include <QuartzCore/QuartzCore.h>

#include "flutter/fml/mapping.h"
#include "impeller/entity/mtl/entity_shaders.h"
#include "impeller/fixtures/mtl/shader_fixtures.h"
#include "impeller/playground/imgui/mtl/imgui_shaders.h"
#include "impeller/renderer/backend/metal/context_mtl.h"
#include "impeller/renderer/backend/metal/formats_mtl.h"
#include "impeller/renderer/backend/metal/surface_mtl.h"
#include "impeller/renderer/backend/metal/texture_mtl.h"

namespace impeller {

struct PlaygroundImplMTL::Data {
  CAMetalLayer* metal_layer = nil;
};

static std::vector<std::shared_ptr<fml::Mapping>>
ShaderLibraryMappingsForPlayground() {
  return {
      std::make_shared<fml::NonOwnedMapping>(impeller_entity_shaders_data,
                                             impeller_entity_shaders_length),
      std::make_shared<fml::NonOwnedMapping>(impeller_shader_fixtures_data,
                                             impeller_shader_fixtures_length),
      std::make_shared<fml::NonOwnedMapping>(impeller_imgui_shaders_data,
                                             impeller_imgui_shaders_length),

  };
}

PlaygroundImplMTL::PlaygroundImplMTL() : data_(std::make_unique<Data>()) {}

PlaygroundImplMTL::~PlaygroundImplMTL() = default;

std::shared_ptr<Context> PlaygroundImplMTL::CreateContext() const {
  return ContextMTL::Create(ShaderLibraryMappingsForPlayground(),
                            "Playground Library");
}

bool PlaygroundImplMTL::SetupWindow(WindowHandle handle,
                                    std::shared_ptr<Context> context) {
  if (handle_ != nullptr) {
    return false;
  }

  handle_ = handle;

  NSWindow* cocoa_window =
      ::glfwGetCocoaWindow(reinterpret_cast<GLFWwindow*>(handle_));
  data_->metal_layer = [CAMetalLayer layer];
  data_->metal_layer.device = ContextMTL::Cast(*context).GetMTLDevice();
  // This pixel format is one of the documented supported formats.
  data_->metal_layer.pixelFormat = ToMTLPixelFormat(PixelFormat::kDefaultColor);
  cocoa_window.contentView.layer = data_->metal_layer;
  cocoa_window.contentView.wantsLayer = YES;
  return true;
}

bool PlaygroundImplMTL::TeardownWindow(WindowHandle handle,
                                       std::shared_ptr<Context> context) {
  if (handle_ != handle) {
    return false;
  }
  handle_ = nullptr;
  data_->metal_layer = nil;
  return true;
}

std::unique_ptr<Surface> PlaygroundImplMTL::AcquireSurfaceFrame(
    std::shared_ptr<Context> context) {
  if (!data_->metal_layer) {
    return nullptr;
  }

  const auto layer_size = data_->metal_layer.bounds.size;
  const auto layer_scale = data_->metal_layer.contentsScale;
  data_->metal_layer.drawableSize = CGSizeMake(layer_size.width * layer_scale,
                                               layer_size.height * layer_scale);
  return SurfaceMTL::WrapCurrentMetalLayerDrawable(context, data_->metal_layer);
}

}  // namespace impeller
