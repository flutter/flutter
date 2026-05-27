// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/testing/skia/dl_test_surface_instance_skia.h"

#include "flutter/display_list/image/dl_image_skia.h"
#include "flutter/display_list/skia/dl_sk_conversions.h"
#include "flutter/fml/safe_math.h"
#include "third_party/skia/include/encode/SkPngEncoder.h"
#include "third_party/skia/include/gpu/ganesh/GrDirectContext.h"

namespace {

class DlSkiaPixelData : public flutter::testing::DlPixelData {
 private:
  struct FreeDeleter {
    void operator()(uint8_t* p) { std::free(p); }
  };

 public:
  static std::unique_ptr<DlSkiaPixelData> MakeFromRasterImage(
      const sk_sp<SkImage>& raster_image) {
    SkImageInfo info = raster_image->imageInfo();
    info = SkImageInfo::MakeN32Premul(info.dimensions());
    FML_CHECK(info.bytesPerPixel() == 4);

    size_t min_row_bytes = info.minRowBytes();
    size_t byte_count = info.computeByteSize(min_row_bytes);
    if (byte_count == std::numeric_limits<size_t>::max()) {
      return nullptr;
    }

    std::unique_ptr<uint8_t, FreeDeleter> pixels;
    pixels.reset(static_cast<uint8_t*>(std::malloc(byte_count)));
    if (!pixels.get()) {
      return nullptr;
    }

    SkPixmap pixmap;
    // Resetting the pixmap does not give ownership of pixels to it.
    pixmap.reset(info, pixels.get(), info.minRowBytes());
    if (!raster_image->readPixels(pixmap, 0, 0)) {
      return nullptr;
    }

    // We could hand in the already established SkPixmap object, but the
    // pixel ownership needs to be explicitly transferred via std::move.
    // Passing the pixmap doesn't transfer that ownership and passing it
    // while additionally transferring the ownership creates an odd
    // case of the pixmap having a pointer in it that is undergoing a
    // transfer. Safer to pass in the raw info and then re-establish the
    // pixmap field (for ease of the access methods) in the constructor.
    return std::make_unique<DlSkiaPixelData>(info, min_row_bytes,
                                             std::move(pixels));
  }

  DlSkiaPixelData(const SkImageInfo& info,
                  size_t row_bytes,
                  std::unique_ptr<uint8_t, FreeDeleter> pixels)
      : pixels_(std::move(pixels)) {
    // Resetting the pixmap_ does not give ownership of pixels to it.
    pixmap_.reset(info, pixels_.get(), row_bytes);
  }

  ~DlSkiaPixelData() override = default;

  const uint32_t* addr32(uint32_t x, uint32_t y) const override {
    if (x >= width() || y >= height()) {
      return nullptr;
    }
    return static_cast<const uint32_t*>(pixmap_.addr(x, y));
  }

  size_t width() const override { return pixmap_.info().width(); }
  size_t height() const override { return pixmap_.info().height(); }

  virtual bool write(const std::string& path) const override {
    sk_sp<SkData> data = SkPngEncoder::Encode(pixmap_, {});
    if (!data) {
      return false;
    }
    fml::NonOwnedMapping mapping(static_cast<const uint8_t*>(data->data()),
                                 data->size());
    return WriteAtomically(flutter::testing::OpenFixturesDirectory(),
                           path.c_str(), mapping);
  }

 private:
  std::unique_ptr<uint8_t, FreeDeleter> pixels_;
  SkPixmap pixmap_;
};

}  // namespace

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
    adapter_.canvas()->save();
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
  adapter_.canvas()->restoreToCount(0);
  adapter_.canvas()->save();
}

bool DlSurfaceInstanceSkiaBase::SnapshotToFile(std::string& filename) const {
  sk_sp<SkImage> raster = GetRasterImage();
  if (!raster) {
    return false;
  }
  sk_sp<SkData> data = SkPngEncoder::Encode(nullptr, raster.get(), {});
  if (!data) {
    return false;
  }
  fml::NonOwnedMapping mapping(static_cast<const uint8_t*>(data->data()),
                               data->size());
  return WriteAtomically(OpenFixturesDirectory(), filename.c_str(), mapping);
}

std::unique_ptr<DlPixelData> DlSurfaceInstanceSkiaBase::SnapshotToPixelData()
    const {
  sk_sp<SkImage> raster = GetRasterImage();

  return raster ? DlSkiaPixelData::MakeFromRasterImage(raster) : nullptr;
}

sk_sp<DlImage> DlSurfaceInstanceSkiaBase::SnapshotToImage() const {
  return DlImageSkia::Make(GetRasterImage());
}

int DlSurfaceInstanceSkiaBase::width() const {
  return GetSurface()->width();
}

int DlSurfaceInstanceSkiaBase::height() const {
  return GetSurface()->height();
}

sk_sp<SkImage> DlSurfaceInstanceSkiaBase::GetRasterImage() const {
  auto surface = GetSurface();
  auto image = surface->makeImageSnapshot();
  if (!image) {
    return nullptr;
  }
  return image->makeRasterImage(nullptr);
}

sk_sp<SkSurface> DlSurfaceInstanceSkia::GetSurface() const {
  return surface_;
}

}  // namespace testing
}  // namespace flutter
