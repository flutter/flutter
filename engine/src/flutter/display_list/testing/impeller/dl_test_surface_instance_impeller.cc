// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/testing/impeller/dl_test_surface_instance_impeller.h"

#include "flutter/display_list/testing/impeller/dl_test_surface_provider_impeller.h"
#include "flutter/fml/safe_math.h"
#include "flutter/impeller/display_list/dl_dispatcher.h"
#include "flutter/impeller/display_list/dl_image_impeller.h"
#include "flutter/impeller/typographer/backends/skia/typographer_context_skia.h"

namespace {

class DlImpellerPixelData : public flutter::testing::DlPixelData {
 public:
  explicit DlImpellerPixelData(
      std::unique_ptr<impeller::testing::Screenshot> screenshot)
      : screenshot_(std::move(screenshot)) {}
  ~DlImpellerPixelData() override = default;

  virtual const uint32_t* addr32(uint32_t x, uint32_t y) const override {
    if (x >= width() || y >= height()) {
      return nullptr;
    }
    fml::SafeMath safe_math;
    size_t offset = safe_math.mul(screenshot_->GetBytesPerRow(), y);
    offset += safe_math.mul(x, 4u);
    if (safe_math.overflow_detected()) {
      return nullptr;
    }
    return reinterpret_cast<const uint32_t*>(screenshot_->GetBytes() + offset);
  }

  virtual size_t width() const override { return screenshot_->GetWidth(); }
  virtual size_t height() const override { return screenshot_->GetHeight(); }

  virtual bool write(const std::string& path) const override {
    return screenshot_->WriteToPNG(path);
  }

 private:
  std::unique_ptr<impeller::testing::Screenshot> screenshot_;
};

}  // namespace

namespace flutter {
namespace testing {

DlSurfaceInstanceImpeller::DlSurfaceInstanceImpeller(
    std::shared_ptr<impeller::Context> context,
    std::shared_ptr<impeller::Surface> surface)
    : context_(std::move(context)),
      surface_(std::move(surface)),
      aiks_context_(context_, typographer_context_) {}

DlSurfaceInstanceImpeller::DlSurfaceInstanceImpeller(
    std::shared_ptr<impeller::Context> context,
    std::shared_ptr<impeller::RenderTarget> target)
    : context_(std::move(context)),
      target_holder_(std::move(target)),
      aiks_context_(context_, typographer_context_) {}

DlSurfaceInstanceImpeller::~DlSurfaceInstanceImpeller() = default;

inline const impeller::RenderTarget&
DlSurfaceInstanceImpeller::GetRenderTarget() const {
  if (surface_) {
    return surface_->GetRenderTarget();
  }
  if (target_holder_) {
    return *target_holder_;
  }
  FML_UNREACHABLE();
}

void DlSurfaceInstanceImpeller::Clear(const DlColor& color) {
  if (!builder_.IsEmpty()) {
    // Use the Build method to clear whatever is in the builder as it is
    // now irrelevant and ignore the returned DisplayList as it would be
    // useless to try to render it before a surface clear.
    std::ignore = builder_.Build();
  }
  builder_.Clear(color);
  DoRenderDisplayList(builder_.Build());
}

DlCanvas* DlSurfaceInstanceImpeller::GetCanvas() {
  return &builder_;
}

void DlSurfaceInstanceImpeller::RenderDisplayList(
    const sk_sp<DisplayList>& display_list) {
  Flush();
  DoRenderDisplayList(display_list);
}

void DlSurfaceInstanceImpeller::FlushSubmitCpuSync() {
  Flush();
  if (!context_->FinishQueue()) {
    FML_LOG(ERROR) << "Impeller backend did not implement FinishQueue";
    FML_UNREACHABLE();
  }
}

inline void DlSurfaceInstanceImpeller::Flush() {
  if (!builder_.IsEmpty()) {
    // Render anything accumulated previously by making calls on GetCanvas().
    DoRenderDisplayList(builder_.Build());
  }
}

void DlSurfaceInstanceImpeller::DoRenderDisplayList(
    const sk_sp<DisplayList>& display_list) {
  // RenderToTarget requires us to pass in a cull_rect, but we don't want
  // benchmarks to do extra overhead for culling, so we make a large enough
  // cull rect that the dispatcher decides to do a regular sequential dispatch.
  DlRect cull_rect = display_list->GetBounds().Expand(1.0f);
  impeller::RenderToTarget(aiks_context_.GetContentContext(), GetRenderTarget(),
                           display_list, cull_rect, false, false);
}

std::unique_ptr<DlPixelData> DlSurfaceInstanceImpeller::SnapshotToPixelData()
    const {
  std::unique_ptr<impeller::testing::Screenshot> snapshot =
      snapshotter_.MakeScreenshot(aiks_context_,
                                  GetRenderTarget().GetRenderTargetTexture());
  return snapshot ? std::make_unique<DlImpellerPixelData>(std::move(snapshot))
                  : nullptr;
}

sk_sp<DlImage> DlSurfaceInstanceImpeller::SnapshotToImage() const {
  auto texture = GetRenderTarget().GetRenderTargetTexture();
  // temp_image will not be a snapshot, so we must make a copy of it to
  // satisfy the demands of the "SnapshotToImage" API.
  auto temp_image = impeller::DlImageImpeller::Make(texture);

  // Make a temporary "image surface" into which we can copy our current
  // texture so that we can return a stable snapshot DlImage from the copy.
  auto image_surface = DlSurfaceProviderImpeller::MakeOffscreenSurface(
      context_, temp_image->width(), temp_image->height(),
      DlSurfaceProvider::PixelFormat::kN32Premul);

  // Copy the temp_image made from our texture into the image surface.
  image_surface->GetCanvas()->DrawImage(temp_image, DlPoint(0, 0),
                                        DlImageSampling::kNearestNeighbor);
  image_surface->FlushSubmitCpuSync();

  // Return an image based on the temporary, but stable, image_surface's
  // texture.
  return impeller::DlImageImpeller::Make(
      image_surface->GetRenderTarget().GetRenderTargetTexture());
}

bool DlSurfaceInstanceImpeller::SnapshotToFile(std::string& filename) const {
  return false;
}

int DlSurfaceInstanceImpeller::width() const {
  return GetRenderTarget().GetRenderTargetSize().width;
}

int DlSurfaceInstanceImpeller::height() const {
  return GetRenderTarget().GetRenderTargetSize().height;
}

std::shared_ptr<impeller::TypographerContext>
    DlSurfaceInstanceImpeller::typographer_context_ =
        impeller::TypographerContextSkia::Make();

impeller::testing::MetalScreenshotter DlSurfaceInstanceImpeller::snapshotter_ =
    impeller::testing::MetalScreenshotter(impeller::PlaygroundSwitches());

}  // namespace testing
}  // namespace flutter
