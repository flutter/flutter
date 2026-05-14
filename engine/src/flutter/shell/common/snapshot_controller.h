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

  virtual void MakeImpellerSnapshot(
      sk_sp<DisplayList> display_list,
      DlISize picture_size,
      std::function<void(const std::shared_ptr<impeller::Texture>&)> callback,
      SnapshotPixelFormat pixel_format) = 0;

  virtual std::shared_ptr<impeller::Texture> MakeImpellerSnapshotSync(
      sk_sp<DisplayList> display_list,
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
