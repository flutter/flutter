// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/snapshot_controller_impeller.h"

#include <algorithm>

#include "flutter/flow/surface.h"
#include "flutter/fml/trace_event.h"
#include "flutter/impeller/display_list/display_list_dispatcher.h"
#include "flutter/impeller/display_list/display_list_image_impeller.h"
#include "flutter/impeller/geometry/size.h"
#include "flutter/shell/common/snapshot_controller.h"

namespace flutter {

sk_sp<DlImage> SnapshotControllerImpeller::MakeRasterSnapshot(
    sk_sp<DisplayList> display_list,
    SkISize size) {
  sk_sp<DlImage> result;
  GetDelegate().GetIsGpuDisabledSyncSwitch()->Execute(
      fml::SyncSwitch::Handlers()
          .SetIfTrue([&] {
            // Do nothing.
          })
          .SetIfFalse(
              [&] { result = DoMakeRasterSnapshot(display_list, size); }));

  return result;
}

sk_sp<DlImage> SnapshotControllerImpeller::DoMakeRasterSnapshot(
    const sk_sp<DisplayList>& display_list,
    SkISize size) {
  impeller::DisplayListDispatcher dispatcher;
  display_list->Dispatch(dispatcher);
  impeller::Picture picture = dispatcher.EndRecordingAsPicture();
  auto context = GetDelegate().GetAiksContext();
  if (context) {
    auto max_size = context->GetContext()
                        ->GetResourceAllocator()
                        ->GetMaxTextureSizeSupported();
    double scale_factor_x =
        static_cast<double>(max_size.width) / static_cast<double>(size.width());
    double scale_factor_y = static_cast<double>(max_size.height) /
                            static_cast<double>(size.height());
    double scale_factor =
        std::min(1.0, std::min(scale_factor_x, scale_factor_y));

    auto render_target_size = impeller::ISize(size.width(), size.height());

    // Scale down the render target size to the max supported by the
    // GPU if necessary. Exceeding the max would otherwise cause a
    // null result.
    if (scale_factor < 1.0) {
      render_target_size.width *= scale_factor;
      render_target_size.height *= scale_factor;
    }

    std::shared_ptr<impeller::Image> image =
        picture.ToImage(*context, render_target_size);
    if (image) {
      return impeller::DlImageImpeller::Make(image->GetTexture(),
                                             DlImage::OwningContext::kRaster);
    }
  }

  return nullptr;
}

sk_sp<SkImage> SnapshotControllerImpeller::ConvertToRasterImage(
    sk_sp<SkImage> image) {
  FML_UNREACHABLE();
}

}  // namespace flutter
