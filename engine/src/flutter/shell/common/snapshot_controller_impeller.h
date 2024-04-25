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

  sk_sp<DlImage> MakeRasterSnapshot(sk_sp<DisplayList> display_list,
                                    SkISize size) override;

  sk_sp<SkImage> ConvertToRasterImage(sk_sp<SkImage> image) override;

  void CacheRuntimeStage(
      const std::shared_ptr<impeller::RuntimeStage>& runtime_stage) override;

 private:
  sk_sp<DlImage> DoMakeRasterSnapshot(const sk_sp<DisplayList>& display_list,
                                      SkISize size);

  FML_DISALLOW_COPY_AND_ASSIGN(SnapshotControllerImpeller);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_COMMON_SNAPSHOT_CONTROLLER_IMPELLER_H_
