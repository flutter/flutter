// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/test_metal_surface_impl.h"

#include <Metal/Metal.h>

#include "flutter/fml/logging.h"
#include "flutter/fml/platform/darwin/scoped_nsobject.h"
#include "third_party/skia/include/core/SkSurface.h"

namespace flutter {

TestMetalSurfaceImpl::TestMetalSurfaceImpl(SkISize surface_size) {
  if (surface_size.isEmpty()) {
    FML_LOG(ERROR) << "Size of test Metal surface was empty.";
    return;
  }

  auto device = fml::scoped_nsobject{[MTLCreateSystemDefaultDevice() retain]};
  if (!device) {
    FML_LOG(ERROR) << "Could not acquire Metal device.";
    return;
  }

  auto command_queue = fml::scoped_nsobject{[device.get() newCommandQueue]};
  if (!command_queue) {
    FML_LOG(ERROR) << "Could not create the default command queue.";
    return;
  }

  auto texture_descriptor = fml::scoped_nsobject{
      [[MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm
                                                          width:surface_size.width()
                                                         height:surface_size.height()
                                                      mipmapped:NO] retain]};

  // The most pessimistic option and disables all optimizations but allows tests
  // the most flexible access to the surface. They may read and write to the
  // surface from shaders or use as a pixel view.
  texture_descriptor.get().usage = MTLTextureUsageUnknown;

  if (!texture_descriptor) {
    FML_LOG(ERROR) << "Invalid texture descriptor.";
    return;
  }

  auto texture =
      fml::scoped_nsobject{[device.get() newTextureWithDescriptor:texture_descriptor.get()]};

  if (!texture) {
    FML_LOG(ERROR) << "Could not create texture from texture descriptor.";
    return;
  }

  auto skia_context = GrDirectContext::MakeMetal(device.get(), command_queue.get());

  if (skia_context) {
    // Skia wants ownership of the device and queue. If a context was created,
    // we now no longer own the argument. Release the arguments only on
    // successful creation of the context.
    FML_ALLOW_UNUSED_LOCAL(device.release());
    FML_ALLOW_UNUSED_LOCAL(command_queue.release());
  } else {
    FML_LOG(ERROR) << "Could not create the GrDirectContext from the Metal Device "
                      "and command queue.";
    return;
  }

  GrMtlTextureInfo skia_texture_info;
  skia_texture_info.fTexture = sk_cf_obj<const void*>{[texture.get() retain]};

  auto backend_render_target = GrBackendRenderTarget{
      surface_size.width(),   // width
      surface_size.height(),  // height
      1,                      // sample count
      skia_texture_info       // texture info
  };

  auto surface = SkSurface::MakeFromBackendRenderTarget(
      skia_context.get(),        // context
      backend_render_target,     // backend render target
      kTopLeft_GrSurfaceOrigin,  // surface origin
      kBGRA_8888_SkColorType,    // color type
      nullptr,                   // color space
      nullptr,                   // surface properties
      nullptr,                   // release proc (texture is already ref counted in sk_cf_obj)
      nullptr                    // release context
  );

  if (!surface) {
    FML_LOG(ERROR) << "Could not create Skia surface from a Metal texture.";
    return;
  }

  surface_ = std::move(surface);
  context_ = std::move(skia_context);

  is_valid_ = true;
}

// |TestMetalSurface|
TestMetalSurfaceImpl::~TestMetalSurfaceImpl() = default;

// |TestMetalSurface|
bool TestMetalSurfaceImpl::IsValid() const {
  return is_valid_;
}
// |TestMetalSurface|
sk_sp<GrDirectContext> TestMetalSurfaceImpl::GetGrContext() const {
  return IsValid() ? context_ : nullptr;
}
// |TestMetalSurface|
sk_sp<SkSurface> TestMetalSurfaceImpl::GetSurface() const {
  return IsValid() ? surface_ : nullptr;
}

}  // namespace flutter
