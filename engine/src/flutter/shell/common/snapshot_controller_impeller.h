// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_COMMON_SNAPSHOT_CONTROLLER_IMPELLER_H_
#define FLUTTER_SHELL_COMMON_SNAPSHOT_CONTROLLER_IMPELLER_H_

#include "flutter/shell/common/snapshot_controller.h"
#include "impeller/runtime_stage/runtime_stage.h"

namespace flutter {

class SnapshotControllerImpeller : public SnapshotController {
 public:
  explicit SnapshotControllerImpeller(
      const SnapshotController::Delegate& delegate)
      : SnapshotController(delegate) {}

  void MakeSkiaSnapshot(sk_sp<DisplayList> display_list,
                        DlISize picture_size,
                        std::function<void(const sk_sp<SkImage>&)> callback,
                        SnapshotPixelFormat pixel_format) override;

  sk_sp<SkImage> MakeSkiaSnapshotSync(
      sk_sp<DisplayList> display_list,
      DlISize size,
      SnapshotPixelFormat pixel_format) override;

  void MakeImpellerSnapshot(
      sk_sp<DisplayList> display_list,
      DlISize picture_size,
      std::function<void(const std::shared_ptr<impeller::Texture>&)> callback,
      SnapshotPixelFormat pixel_format) override;

  std::shared_ptr<impeller::Texture> MakeImpellerSnapshotSync(
      sk_sp<DisplayList> display_list,
      DlISize picture_size,
      SnapshotPixelFormat pixel_format) override;

  sk_sp<SkImage> MakeSkiaTextureImage(
      sk_sp<SkImage> image,
      SnapshotPixelFormat pixel_format) override;

  std::shared_ptr<impeller::Texture> MakeImpellerTextureImage(
      sk_sp<SkImage> image,
      SnapshotPixelFormat pixel_format) override;

  sk_sp<SkImage> ConvertToRasterImage(sk_sp<SkImage> image) override;

  void CacheRuntimeStage(
      const std::shared_ptr<impeller::RuntimeStage>& runtime_stage) override;

  virtual bool MakeRenderContextCurrent() override;

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(SnapshotControllerImpeller);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_COMMON_SNAPSHOT_CONTROLLER_IMPELLER_H_
