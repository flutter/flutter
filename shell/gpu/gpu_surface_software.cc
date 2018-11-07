// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/gpu/gpu_surface_software.h"

#include <memory>
#include "flutter/fml/logging.h"

namespace shell {

flow::ExternalViewEmbedder*
GPUSurfaceSoftwareDelegate::GetExternalViewEmbedder() {
  return nullptr;
}

GPUSurfaceSoftware::GPUSurfaceSoftware(GPUSurfaceSoftwareDelegate* delegate)
    : delegate_(delegate), weak_factory_(this) {}

GPUSurfaceSoftware::~GPUSurfaceSoftware() = default;

// |shell::Surface|
bool GPUSurfaceSoftware::IsValid() {
  return delegate_ != nullptr;
}

// |shell::Surface|
std::unique_ptr<SurfaceFrame> GPUSurfaceSoftware::AcquireFrame(
    const SkISize& logical_size) {
  if (!IsValid()) {
    return nullptr;
  }

  const auto size = SkISize::Make(logical_size.width(), logical_size.height());

  sk_sp<SkSurface> backing_store = delegate_->AcquireBackingStore(size);

  if (backing_store == nullptr) {
    return nullptr;
  }

  if (size != SkISize::Make(backing_store->width(), backing_store->height())) {
    return nullptr;
  }

  // If the surface has been scaled, we need to apply the inverse scaling to the
  // underlying canvas so that coordinates are mapped to the same spot
  // irrespective of surface scaling.
  SkCanvas* canvas = backing_store->getCanvas();
  canvas->resetMatrix();

  SurfaceFrame::SubmitCallback on_submit =
      [self = weak_factory_.GetWeakPtr()](const SurfaceFrame& surface_frame,
                                          SkCanvas* canvas) -> bool {
    // If the surface itself went away, there is nothing more to do.
    if (!self || !self->IsValid() || canvas == nullptr) {
      return false;
    }

    canvas->flush();

    return self->delegate_->PresentBackingStore(surface_frame.SkiaSurface());
  };

  return std::make_unique<SurfaceFrame>(backing_store, on_submit);
}

// |shell::Surface|
SkMatrix GPUSurfaceSoftware::GetRootTransformation() const {
  // This backend does not currently support root surface transformations. Just
  // return identity.
  SkMatrix matrix;
  matrix.reset();
  return matrix;
}

// |shell::Surface|
GrContext* GPUSurfaceSoftware::GetContext() {
  // There is no GrContext associated with a software surface.
  return nullptr;
}

// |shell::Surface|
flow::ExternalViewEmbedder* GPUSurfaceSoftware::GetExternalViewEmbedder() {
  return delegate_->GetExternalViewEmbedder();
}

}  // namespace shell
