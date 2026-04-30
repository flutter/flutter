// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/testing/impeller/dl_test_surface_provider_impeller.h"

namespace flutter {
namespace testing {

DlSurfaceProviderImpeller::DlSurfaceProviderImpeller() : DlSurfaceProvider() {}

std::unique_ptr<impeller::PlaygroundImpl>
DlSurfaceProviderImpeller::MakePlayground(impeller::PlaygroundBackend backend) {
  impeller::PlaygroundSwitches switches;
  return impeller::PlaygroundImpl::Create(backend, switches);
}

bool DlSurfaceProviderImpeller::InitializeSurface(size_t width,
                                                  size_t height,
                                                  PixelFormat format) {
  if (format != kN32Premul) {
    // The caller didn't check our supported formats.
    return false;
  }
  primary_ = MakeOffscreenSurface(width, height, format);
  return true;
}

std::shared_ptr<DlSurfaceInstance>
DlSurfaceProviderImpeller::GetPrimarySurface() const {
  return primary_;
}

std::shared_ptr<DlSurfaceInstance>
DlSurfaceProviderImpeller::MakeOffscreenSurface(size_t width,
                                                size_t height,
                                                PixelFormat format) const {
  if (format != kN32Premul) {
    // The caller didn't check our supported formats.
    return nullptr;
  }
  impeller::ISize size(width, height);
  int mip_count = 1;

  impeller::PlaygroundImpl* playground = GetPlayground();
  std::shared_ptr<impeller::Context> context = playground->GetContext();
  impeller::RenderTargetAllocator render_target_allocator =
      impeller::RenderTargetAllocator(context->GetResourceAllocator());
  std::shared_ptr<impeller::RenderTarget> target;
  if (context->GetCapabilities()->SupportsOffscreenMSAA()) {
    target = std::make_shared<impeller::RenderTarget>(
        render_target_allocator.CreateOffscreenMSAA(
            *context,  // context
            size,      // size
            /*mip_count=*/mip_count,
            "Picture Snapshot MSAA",  // label
            impeller::RenderTarget::
                kDefaultColorAttachmentConfigMSAA  // color_attachment_config
            ));
  } else {
    target = std::make_shared<impeller::RenderTarget>(
        render_target_allocator.CreateOffscreen(
            *context,  // context
            size,      // size
            /*mip_count=*/mip_count,
            "Picture Snapshot",  // label
            impeller::RenderTarget::
                kDefaultColorAttachmentConfig  // color_attachment_config
            ));
  }
  if (!target->IsValid()) {
    return nullptr;
  }
  return std::make_shared<DlSurfaceInstanceImpeller>(std::move(context),
                                                     target);
}

bool DlSurfaceProviderImpeller::SupportsPixelFormat(PixelFormat format) const {
  return format == kN32Premul;
}

bool DlSurfaceProviderImpeller::SupportsImpeller() const {
  return true;
}

}  // namespace testing
}  // namespace flutter
