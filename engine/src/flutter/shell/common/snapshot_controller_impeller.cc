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

std::shared_ptr<impeller::Texture> DoMakeRasterSnapshot(
    const sk_sp<DisplayList>& display_list,
    DlISize size,
    const std::shared_ptr<impeller::AiksContext>& context,
    SnapshotPixelFormat pixel_format) {
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

  std::optional<impeller::PixelFormat> impeller_pixel_format;
  switch (pixel_format) {
    case SnapshotPixelFormat::kDontCare:
      impeller_pixel_format = std::nullopt;
      break;
    case SnapshotPixelFormat::kRGBA32Float:
      impeller_pixel_format = impeller::PixelFormat::kR32G32B32A32Float;
      break;
    case SnapshotPixelFormat::kR32Float:
      impeller_pixel_format = impeller::PixelFormat::kR32Float;
      break;
  }

  return impeller::DisplayListToTexture(
      display_list, render_target_size, *context,
      /*reset_host_buffer=*/false,
      /*generate_mips=*/false, impeller_pixel_format);
}

/// The rendering context state a snapshot needs. |pbuffer_surface| and
/// |context_result| must be kept alive for the duration of the snapshot to
/// keep the context current.
struct SnapshotContext {
  // Destroyed in reverse order: the context result is released before the
  // offscreen surface it made current.
  std::unique_ptr<Surface> pbuffer_surface;
  std::unique_ptr<GLContextResult> context_result;
  std::shared_ptr<impeller::AiksContext> aiks_context;
};

/// Makes a rendering context current and selects the single AiksContext a
/// snapshot must use.
///
/// Constructing an AiksContext issues graphics commands, so on backends that
/// need a current context (OpenGL ES) the AiksContext is only obtained once a
/// context is current. If no context can be made current, the returned
/// |aiks_context| is nullptr and the snapshot must fail.
SnapshotContext MakeSnapshotContextCurrent(
    const SnapshotController::Delegate& delegate) {
  SnapshotContext result;
  if (const std::unique_ptr<Surface>& surface = delegate.GetSurface()) {
    result.context_result = surface->MakeRenderContextCurrent();
    if (!result.context_result || !result.context_result->GetResult()) {
      return result;
    }
    result.aiks_context = delegate.GetAiksContext();
  } else if (const std::unique_ptr<SnapshotSurfaceProducer>& producer =
                 delegate.GetSnapshotSurfaceProducer()) {
    // The producer makes its offscreen surface current before it constructs
    // the surface's AiksContext, so reuse that AiksContext rather than asking
    // the delegate, which would construct yet another one.
    result.pbuffer_surface = producer->CreateSnapshotSurface();
    if (!result.pbuffer_surface) {
      return result;
    }
    result.context_result = result.pbuffer_surface->MakeRenderContextCurrent();
    if (!result.context_result || !result.context_result->GetResult()) {
      return result;
    }
    result.aiks_context = result.pbuffer_surface->GetAiksContext();
  } else {
    // No surface and no way to make one. Backends that get here (Metal,
    // Vulkan) have no notion of a current context, so constructing an
    // AiksContext is safe.
    result.aiks_context = delegate.GetAiksContext();
  }
  return result;
}

std::shared_ptr<impeller::Texture> DoMakeRasterSnapshot(
    const SnapshotDelegate::SnapshotDisplayListProvider& provider,
    DlISize size,
    const SnapshotController::Delegate& delegate,
    SnapshotPixelFormat pixel_format) {
  SnapshotContext snapshot_context = MakeSnapshotContextCurrent(delegate);
  const std::shared_ptr<impeller::AiksContext>& aiks_context =
      snapshot_context.aiks_context;
  if (!aiks_context) {
    return nullptr;
  }
  // Produce the display list (for example, flatten a layer tree) only now that
  // a context is current, and with the AiksContext that renders it.
  sk_sp<DisplayList> display_list = provider(aiks_context.get());
  if (!display_list) {
    return nullptr;
  }
  return DoMakeRasterSnapshot(display_list, size, aiks_context, pixel_format);
}

std::shared_ptr<impeller::Texture> DoMakeRasterSnapshot(
    sk_sp<DisplayList> display_list,
    DlISize picture_size,
    const std::shared_ptr<const fml::SyncSwitch>& sync_switch,
    const std::shared_ptr<impeller::AiksContext>& context,
    SnapshotPixelFormat pixel_format) {
  std::shared_ptr<impeller::Texture> result;
  sync_switch->Execute(fml::SyncSwitch::Handlers()
                           .SetIfTrue([&] {
                             // Do nothing.
                           })
                           .SetIfFalse([&] {
                             result = DoMakeRasterSnapshot(
                                 display_list, picture_size, context,
                                 pixel_format);
                           }));

  return result;
}
}  // namespace

void SnapshotControllerImpeller::MakeSkiaSnapshot(
    sk_sp<DisplayList> display_list,
    DlISize picture_size,
    std::function<void(const sk_sp<SkImage>&)> callback,
    SnapshotPixelFormat pixel_format) {
  FML_UNREACHABLE();
}

sk_sp<SkImage> SnapshotControllerImpeller::MakeSkiaSnapshotSync(
    sk_sp<DisplayList> display_list,
    DlISize picture_size,
    SnapshotPixelFormat pixel_format) {
  FML_UNREACHABLE();
}

void SnapshotControllerImpeller::MakeImpellerSnapshot(
    SnapshotDelegate::SnapshotDisplayListProvider provider,
    DlISize picture_size,
    std::function<void(const std::shared_ptr<impeller::Texture>&)> callback,
    SnapshotPixelFormat pixel_format) {
  FML_DCHECK(provider);
  std::shared_ptr<const fml::SyncSwitch> sync_switch =
      GetDelegate().GetIsGpuDisabledSyncSwitch();
  sync_switch->Execute(
      fml::SyncSwitch::Handlers()
          .SetIfTrue([&] {
            std::shared_ptr<impeller::AiksContext> context =
                GetDelegate().GetAiksContext();
            if (!context) {
              callback(nullptr);
              return;
            }
            // Only iOS disables the GPU, and Metal has no current context to
            // make. Produce the display list now so the layer tree (if any)
            // is not kept alive until the GPU becomes available.
            sk_sp<DisplayList> display_list = provider(context.get());
            if (!display_list) {
              callback(nullptr);
              return;
            }
            context->GetContext()->StoreTaskForGPU(
                [context, sync_switch, display_list = std::move(display_list),
                 picture_size, callback, pixel_format] {
                  callback(DoMakeRasterSnapshot(display_list, picture_size,
                                                sync_switch, context,
                                                pixel_format));
                },
                [callback]() { callback(nullptr); });
          })
          .SetIfFalse([&] {
            callback(DoMakeRasterSnapshot(provider, picture_size, GetDelegate(),
                                          pixel_format));
          }));
}

std::shared_ptr<impeller::Texture>
SnapshotControllerImpeller::MakeImpellerSnapshotSync(
    SnapshotDelegate::SnapshotDisplayListProvider provider,
    DlISize picture_size,
    SnapshotPixelFormat pixel_format) {
  FML_DCHECK(provider);
  return DoMakeRasterSnapshot(provider, picture_size, GetDelegate(),
                              pixel_format);
}

sk_sp<SkImage> SnapshotControllerImpeller::MakeSkiaTextureImage(
    sk_sp<SkImage> image,
    SnapshotPixelFormat pixel_format) {
  return nullptr;
}

std::shared_ptr<impeller::Texture>
SnapshotControllerImpeller::MakeImpellerTextureImage(
    sk_sp<SkImage> image,
    SnapshotPixelFormat pixel_format) {
  auto aiks_context = GetDelegate().GetAiksContext();
  if (!aiks_context) {
    return nullptr;
  }
  auto context = aiks_context->GetContext();
  if (!context) {
    return nullptr;
  }

  impeller::TextureDescriptor desc;
  desc.storage_mode = impeller::StorageMode::kDevicePrivate;
  desc.format = impeller::PixelFormat::kR8G8B8A8UNormInt;
  desc.size = impeller::ISize(image->width(), image->height());
  desc.mip_count = 1;

  auto texture = context->GetResourceAllocator()->CreateTexture(desc);
  if (!texture) {
    return nullptr;
  }

  size_t byte_size = image->width() * image->height() * 4;
  auto buffer = context->GetResourceAllocator()->CreateBuffer(
      impeller::DeviceBufferDescriptor{
          .storage_mode = impeller::StorageMode::kHostVisible,
          .size = byte_size,
      });

  if (!buffer) {
    return nullptr;
  }

  {
    uint8_t* map = buffer->OnGetContents();
    if (!map) {
      return nullptr;
    }
    SkImageInfo info =
        SkImageInfo::Make(image->width(), image->height(),
                          kRGBA_8888_SkColorType, kPremul_SkAlphaType);
    if (!image->readPixels(info, map, image->width() * 4, 0, 0)) {
      return nullptr;
    }
    buffer->Flush(impeller::Range(0, byte_size));
  }

  auto command_buffer = context->CreateCommandBuffer();
  if (!command_buffer) {
    return nullptr;
  }
  auto blit_pass = command_buffer->CreateBlitPass();
  if (!blit_pass) {
    return nullptr;
  }

  blit_pass->AddCopy(
      impeller::BufferView{buffer, impeller::Range(0, byte_size)}, texture);
  blit_pass->EncodeCommands();

  if (!context->GetCommandQueue()->Submit({command_buffer}).ok()) {
    return nullptr;
  }

  return texture;
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
  impeller::RuntimeEffectContents runtime_effect(nullptr);
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
