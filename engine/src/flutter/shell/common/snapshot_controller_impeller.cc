// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/snapshot_controller_impeller.h"

#include <algorithm>

#include "flutter/flow/surface.h"
#include "flutter/fml/build_config.h"
#include "flutter/fml/trace_event.h"
#include "flutter/impeller/display_list/dl_dispatcher.h"
#include "flutter/impeller/display_list/dl_image_impeller.h"
#include "flutter/impeller/geometry/size.h"
#include "flutter/shell/common/snapshot_controller.h"
#include "impeller/entity/contents/runtime_effect_contents.h"

namespace flutter {

namespace {

sk_sp<DlImage> DoMakeRasterSnapshot(
    const sk_sp<DisplayList>& display_list,
    DlISize size,
    const std::shared_ptr<impeller::AiksContext>& context,
    int32_t target_format) {
  TRACE_EVENT0("flutter", __FUNCTION__);
  if (!context) {
    return nullptr;
  }
  // Determine render target size.
  auto max_size = context->GetContext()
                      ->GetResourceAllocator()
                      ->GetMaxTextureSizeSupported();
  double scale_factor_x =
      static_cast<double>(max_size.width) / static_cast<double>(size.width);
  double scale_factor_y =
      static_cast<double>(max_size.height) / static_cast<double>(size.height);
  double scale_factor = std::min({1.0, scale_factor_x, scale_factor_y});

  auto render_target_size = impeller::ISize(size.width, size.height);

  // Scale down the render target size to the max supported by the
  // GPU if necessary. Exceeding the max would otherwise cause a
  // null result.
  if (scale_factor < 1.0) {
    render_target_size.width *= scale_factor;
    render_target_size.height *= scale_factor;
  }

  std::optional<impeller::PixelFormat> pixel_format;
  switch (target_format) {
    case 0:
      break;
    case 1:
      pixel_format = impeller::PixelFormat::kR32G32B32A32Float;
      break;
    default:
      FML_DCHECK(false) << "unrecognized format";
      break;
  }

  return impeller::DlImageImpeller::Make(
      impeller::DisplayListToTexture(display_list, render_target_size, *context,
                                     /*reset_host_buffer=*/false,
                                     /*generate_mips=*/true, pixel_format),
      DlImage::OwningContext::kRaster);
}

sk_sp<DlImage> DoMakeRasterSnapshot(
    const sk_sp<DisplayList>& display_list,
    DlISize size,
    const SnapshotController::Delegate& delegate,
    int32_t target_format) {
  // Ensure that the current thread has a rendering context. This must be done
  // before calling GetAiksContext because constructing the AiksContext may
  // invoke graphics APIs.
  std::unique_ptr<Surface> pbuffer_surface;
  if (delegate.GetSurface()) {
    delegate.GetSurface()->MakeRenderContextCurrent();
  } else if (delegate.GetSnapshotSurfaceProducer()) {
    pbuffer_surface =
        delegate.GetSnapshotSurfaceProducer()->CreateSnapshotSurface();
    if (pbuffer_surface) {
      pbuffer_surface->MakeRenderContextCurrent();
    }
  }

  return DoMakeRasterSnapshot(display_list, size, delegate.GetAiksContext(),
                              target_format);
}

sk_sp<DlImage> DoMakeRasterSnapshot(
    sk_sp<DisplayList> display_list,
    DlISize picture_size,
    const std::shared_ptr<const fml::SyncSwitch>& sync_switch,
    const std::shared_ptr<impeller::AiksContext>& context,
    int32_t target_format) {
  sk_sp<DlImage> result;
  sync_switch->Execute(fml::SyncSwitch::Handlers()
                           .SetIfTrue([&] {
                             // Do nothing.
                           })
                           .SetIfFalse([&] {
                             result = DoMakeRasterSnapshot(
                                 display_list, picture_size, context,
                                 target_format);
                           }));

  return result;
}
}  // namespace

void SnapshotControllerImpeller::MakeRasterSnapshot(
    sk_sp<DisplayList> display_list,
    DlISize picture_size,
    std::function<void(const sk_sp<DlImage>&)> callback,
    int32_t target_format) {
  std::shared_ptr<const fml::SyncSwitch> sync_switch =
      GetDelegate().GetIsGpuDisabledSyncSwitch();
  sync_switch->Execute(
      fml::SyncSwitch::Handlers()
          .SetIfTrue([&] {
            std::shared_ptr<impeller::AiksContext> context =
                GetDelegate().GetAiksContext();
            if (context) {
              context->GetContext()->StoreTaskForGPU(
                  [context, sync_switch, display_list = std::move(display_list),
                   picture_size, callback, target_format] {
                    callback(DoMakeRasterSnapshot(display_list, picture_size,
                                                  sync_switch, context,
                                                  target_format));
                  },
                  [callback]() { callback(nullptr); });
            } else {
#if FML_OS_IOS_SIMULATOR
              callback(impeller::DlImageImpeller::Make(
                  nullptr, DlImage::OwningContext::kRaster,
                  /*is_fake_image=*/true));
#else
              callback(nullptr);

#endif  // FML_OS_IOS_SIMULATOR
            }
          })
          .SetIfFalse([&] {
#if FML_OS_IOS_SIMULATOR
            if (!GetDelegate().GetAiksContext()) {
              callback(impeller::DlImageImpeller::Make(
                  nullptr, DlImage::OwningContext::kRaster,
                  /*is_fake_image=*/true));
              return;
            }
#endif
            callback(DoMakeRasterSnapshot(display_list, picture_size,
                                          GetDelegate(), target_format));
          }));
}

sk_sp<DlImage> SnapshotControllerImpeller::MakeRasterSnapshotSync(
    sk_sp<DisplayList> display_list,
    DlISize picture_size,
    int32_t target_format) {
  return DoMakeRasterSnapshot(display_list, picture_size, GetDelegate(),
                              target_format);
}

void SnapshotControllerImpeller::CacheRuntimeStage(
    const std::shared_ptr<impeller::RuntimeStage>& runtime_stage) {
  if (!GetDelegate().IsAiksContextInitialized()) {
    return;
  }
  auto context = GetDelegate().GetAiksContext();
  if (!context) {
    return;
  }
  impeller::RuntimeEffectContents runtime_effect;
  runtime_effect.SetRuntimeStage(runtime_stage);
  runtime_effect.BootstrapShader(context->GetContentContext());
}

sk_sp<SkImage> SnapshotControllerImpeller::ConvertToRasterImage(
    sk_sp<SkImage> image) {
  FML_UNREACHABLE();
}

bool SnapshotControllerImpeller::MakeRenderContextCurrent() {
  const std::unique_ptr<Surface>& surface = GetDelegate().GetSurface();
  if (!surface) {
    // Some backends (such as Metal) can operate without a surface and do not
    // require MakeRenderContextCurrent.
    return true;
  }
  return surface->MakeRenderContextCurrent()->GetResult();
}

}  // namespace flutter
