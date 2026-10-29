// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_COMMON_SNAPSHOT_CONTROLLER_H_
#define FLUTTER_SHELL_COMMON_SNAPSHOT_CONTROLLER_H_

#include "flutter/common/settings.h"
#include "flutter/display_list/image/dl_image.h"
#include "flutter/flow/surface.h"
#include "flutter/fml/synchronization/sync_switch.h"
#include "flutter/lib/ui/snapshot_delegate.h"
#include "flutter/shell/common/snapshot_pixel_format.h"
#include "flutter/shell/common/snapshot_surface_producer.h"

namespace impeller {
class AiksContext;
class Texture;
class RuntimeStage;
}  // namespace impeller

namespace flutter {

class SnapshotController {
 public:
  class Delegate {
   public:
    virtual ~Delegate() = default;
    virtual const std::unique_ptr<Surface>& GetSurface() const = 0;
    virtual bool IsAiksContextInitialized() const = 0;
    /// Returns the onscreen surface's AiksContext or, if there is no onscreen
    /// surface, may construct a new AiksContext.
    ///
    /// Constructing an AiksContext issues graphics commands. On backends that
    /// need a current context (OpenGL ES), make a rendering context current
    /// before calling this when |GetSurface| is null.
    virtual std::shared_ptr<impeller::AiksContext> GetAiksContext() const = 0;
    virtual const std::unique_ptr<SnapshotSurfaceProducer>&
    GetSnapshotSurfaceProducer() const = 0;
    virtual std::shared_ptr<const fml::SyncSwitch> GetIsGpuDisabledSyncSwitch()
        const = 0;
  };

  static std::unique_ptr<SnapshotController> Make(const Delegate& delegate,
                                                  const Settings& settings);

  virtual ~SnapshotController() = default;

  virtual void MakeSkiaSnapshot(
      sk_sp<DisplayList> display_list,
      DlISize picture_size,
      std::function<void(const sk_sp<SkImage>&)> callback,
      SnapshotPixelFormat pixel_format) = 0;

  virtual sk_sp<SkImage> MakeSkiaSnapshotSync(
      sk_sp<DisplayList> display_list,
      DlISize picture_size,
      SnapshotPixelFormat pixel_format) = 0;

  //----------------------------------------------------------------------------
  /// @brief      Renders the display list produced by `provider` into a new
  ///             texture. Impeller only.
  ///
  ///             Before `provider` is invoked, a rendering context is made
  ///             current on the calling (raster) thread, and the AiksContext
  ///             that will render the snapshot is selected:
  ///
  ///             1. If the delegate has an onscreen surface, its render
  ///                context is made current and the delegate's AiksContext is
  ///                used.
  ///             2. Otherwise, if the delegate has a snapshot surface
  ///                producer, an offscreen surface is created and made
  ///                current, and that surface's AiksContext is used. On
  ///                Android OpenGL ES this happens before the window surface
  ///                exists or after it has been destroyed.
  ///             3. Otherwise the delegate's AiksContext is used. This is only
  ///                expected for backends with no notion of a current context
  ///                (Metal, Vulkan).
  ///
  ///             If a context cannot be made current, `provider` is not
  ///             invoked and `callback` receives nullptr.
  ///
  ///             While the GPU is disabled (iOS, in the background),
  ///             `provider` is invoked immediately with the delegate's
  ///             AiksContext, and rendering is deferred until the GPU becomes
  ///             available again. In that case `callback` is invoked later,
  ///             on the platform thread, and receives nullptr if the deferred
  ///             task is dropped.
  ///
  /// @param[in]  provider      Produces the display list to render. Invoked at
  ///                           most once, and only with a non-null AiksContext.
  ///                           It may flatten a layer tree with that context.
  ///                           Returning nullptr fails the snapshot.
  /// @param[in]  picture_size  The size of the snapshot. Scaled down if it
  ///                           exceeds the maximum texture size.
  /// @param[in]  callback      Invoked exactly once with the texture, or
  ///                           nullptr on failure.
  /// @param[in]  pixel_format  The requested pixel format of the texture.
  ///
  /// @see        |SnapshotDelegate::MakeImpellerSnapshot|
  ///
  virtual void MakeImpellerSnapshot(
      SnapshotDelegate::SnapshotDisplayListProvider provider,
      DlISize picture_size,
      std::function<void(const std::shared_ptr<impeller::Texture>&)> callback,
      SnapshotPixelFormat pixel_format) = 0;

  //----------------------------------------------------------------------------
  /// @brief      Synchronous version of |MakeImpellerSnapshot|. Impeller only.
  ///
  ///             Selects a context and invokes `provider` exactly as
  ///             |MakeImpellerSnapshot| does, but renders immediately on the
  ///             calling thread and does not defer while the GPU is disabled.
  ///
  /// @param[in]  provider      Produces the display list to render. Invoked at
  ///                           most once, and only with a non-null AiksContext.
  ///                           Returning nullptr fails the snapshot.
  /// @param[in]  picture_size  The size of the snapshot. Scaled down if it
  ///                           exceeds the maximum texture size.
  /// @param[in]  pixel_format  The requested pixel format of the texture.
  ///
  /// @return     The texture, or nullptr if no rendering context could be
  ///             made current, `provider` returned nullptr, or rendering
  ///             failed.
  ///
  /// @see        |SnapshotDelegate::MakeImpellerSnapshotSync|
  ///
  virtual std::shared_ptr<impeller::Texture> MakeImpellerSnapshotSync(
      SnapshotDelegate::SnapshotDisplayListProvider provider,
      DlISize picture_size,
      SnapshotPixelFormat pixel_format) = 0;

  /// Creates a texture-backed DlImage from the provided SkImage.
  ///
  /// This is primarily used by `decodeImageFromPixelsSync` to upload pixels
  /// to the GPU synchronously.
  virtual sk_sp<SkImage> MakeSkiaTextureImage(
      sk_sp<SkImage> image,
      SnapshotPixelFormat pixel_format) = 0;

  virtual std::shared_ptr<impeller::Texture> MakeImpellerTextureImage(
      sk_sp<SkImage> image,
      SnapshotPixelFormat pixel_format) = 0;

  virtual sk_sp<SkImage> ConvertToRasterImage(sk_sp<SkImage> image) = 0;

  virtual void CacheRuntimeStage(
      const std::shared_ptr<impeller::RuntimeStage>& runtime_stage) = 0;

  virtual bool MakeRenderContextCurrent() = 0;

 protected:
  explicit SnapshotController(const Delegate& delegate);
  const Delegate& GetDelegate() { return delegate_; }

 private:
  const Delegate& delegate_;

  FML_DISALLOW_COPY_AND_ASSIGN(SnapshotController);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_COMMON_SNAPSHOT_CONTROLLER_H_
