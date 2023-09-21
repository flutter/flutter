// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/test_metal_context.h"

#include <Metal/Metal.h>
#include <iostream>

#include "flutter/fml/logging.h"
#include "flutter/fml/platform/darwin/scoped_nsobject.h"
#include "third_party/skia/include/core/SkSurface.h"

namespace flutter {

TestMetalContext::TestMetalContext() {
  auto device = fml::scoped_nsprotocol{MTLCreateSystemDefaultDevice()};
  if (!device) {
    FML_LOG(ERROR) << "Could not acquire Metal device.";
    return;
  }

  auto command_queue = fml::scoped_nsobject{[device.get() newCommandQueue]};
  if (!command_queue) {
    FML_LOG(ERROR) << "Could not create the default command queue.";
    return;
  }

  [command_queue.get() setLabel:@"Flutter Test Queue"];

  // Skia expect arguments to `MakeMetal` transfer ownership of the reference in for release later
  // when the GrDirectContext is collected.
  skia_context_ = GrDirectContext::MakeMetal([device.get() retain], [command_queue.get() retain]);
  if (!skia_context_) {
    FML_LOG(ERROR) << "Could not create the GrDirectContext from the Metal Device "
                      "and command queue.";
  }

  device_ = [device.get() retain];
  command_queue_ = [command_queue.get() retain];
}

TestMetalContext::~TestMetalContext() {
  std::scoped_lock lock(textures_mutex_);
  textures_.clear();
  if (device_) {
    [(__bridge id)device_ release];
  }
  if (command_queue_) {
    [(__bridge id)command_queue_ release];
  }
}

void* TestMetalContext::GetMetalDevice() const {
  return device_;
}

void* TestMetalContext::GetMetalCommandQueue() const {
  return command_queue_;
}

sk_sp<GrDirectContext> TestMetalContext::GetSkiaContext() const {
  return skia_context_;
}

TestMetalContext::TextureInfo TestMetalContext::CreateMetalTexture(const SkISize& size) {
  std::scoped_lock lock(textures_mutex_);
  auto texture_descriptor = fml::scoped_nsobject{
      [[MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm
                                                          width:size.width()
                                                         height:size.height()
                                                      mipmapped:NO] retain]};

  // The most pessimistic option and disables all optimizations but allows tests
  // the most flexible access to the surface. They may read and write to the
  // surface from shaders or use as a pixel view.
  texture_descriptor.get().usage = MTLTextureUsageUnknown;

  if (!texture_descriptor) {
    FML_CHECK(false) << "Invalid texture descriptor.";
    return {.texture_id = -1, .texture = nullptr};
  }

  id<MTLDevice> device = (__bridge id<MTLDevice>)GetMetalDevice();
  sk_cfp<void*> texture = sk_cfp<void*>{[device newTextureWithDescriptor:texture_descriptor.get()]};

  if (!texture) {
    FML_CHECK(false) << "Could not create texture from texture descriptor.";
    return {.texture_id = -1, .texture = nullptr};
  }

  const int64_t texture_id = texture_id_ctr_++;
  textures_[texture_id] = texture;

  return {
      .texture_id = texture_id,
      .texture = texture.get(),
  };
}

// Don't remove the texture from the map here.
bool TestMetalContext::Present(int64_t texture_id) {
  std::scoped_lock lock(textures_mutex_);
  if (textures_.find(texture_id) == textures_.end()) {
    return false;
  } else {
    return true;
  }
}

TestMetalContext::TextureInfo TestMetalContext::GetTextureInfo(int64_t texture_id) {
  std::scoped_lock lock(textures_mutex_);
  if (textures_.find(texture_id) == textures_.end()) {
    FML_CHECK(false) << "Invalid texture id: " << texture_id;
    return {.texture_id = -1, .texture = nullptr};
  } else {
    return {
        .texture_id = texture_id,
        .texture = textures_[texture_id].get(),
    };
  }
}

}  // namespace flutter
