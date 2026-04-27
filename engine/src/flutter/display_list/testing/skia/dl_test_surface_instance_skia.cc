// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/testing/skia/dl_test_surface_instance_skia.h"

#include "flutter/display_list/skia/dl_sk_conversions.h"
#include "third_party/skia/include/encode/SkPngEncoder.h"
#include "third_party/skia/include/gpu/ganesh/GrDirectContext.h"

namespace flutter {
namespace testing {

DlSurfaceInstanceSkiaBase::DlSurfaceInstanceSkiaBase() {}

DlSurfaceInstanceSkiaBase::~DlSurfaceInstanceSkiaBase() = default;

DlSurfaceInstanceSkia::DlSurfaceInstanceSkia(sk_sp<SkSurface> surface)
    : DlSurfaceInstanceSkiaBase(), surface_(std::move(surface)) {}

DlSurfaceInstanceSkia::~DlSurfaceInstanceSkia() = default;

void DlSurfaceInstanceSkiaBase::Clear(const DlColor& color) {
  GetCanvas()->Clear(color);
}

DlCanvas* DlSurfaceInstanceSkiaBase::GetCanvas() {
  if (adapter_.canvas() == nullptr) {
    adapter_.set_canvas(GetSurface()->getCanvas());
  }
  return &adapter_;
}

void DlSurfaceInstanceSkiaBase::RenderDisplayList(
    const sk_sp<DisplayList>& display_list) {
  GetCanvas()->DrawDisplayList(display_list);
}

void DlSurfaceInstanceSkiaBase::FlushSubmitCpuSync() {
  auto surface = GetSurface();
  if (!surface) {
    return;
  }
  if (GrDirectContext* dContext =
          GrAsDirectContext(surface->recordingContext())) {
    dContext->flushAndSubmit(surface.get(), GrSyncCpu::kYes);
  }
}

bool DlSurfaceInstanceSkiaBase::SnapshotToFile(std::string& filename) const {
  auto surface = GetSurface();
  auto image = surface->makeImageSnapshot();
  if (!image) {
    return false;
  }
  auto raster = image->makeRasterImage(nullptr);
  if (!raster) {
    return false;
  }
  auto data = SkPngEncoder::Encode(nullptr, raster.get(), {});
  if (!data) {
    return false;
  }
  fml::NonOwnedMapping mapping(static_cast<const uint8_t*>(data->data()),
                               data->size());
  return WriteAtomically(OpenFixturesDirectory(), filename.c_str(), mapping);
}

int DlSurfaceInstanceSkiaBase::width() const {
  return GetSurface()->width();
}

int DlSurfaceInstanceSkiaBase::height() const {
  return GetSurface()->height();
}

sk_sp<SkSurface> DlSurfaceInstanceSkia::GetSurface() const {
  return surface_;
}

}  // namespace testing
}  // namespace flutter
