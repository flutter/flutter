// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/display_list_builder.h"

namespace flutter {

DisplayListBuilder::DisplayListBuilder(const SkRect& cull_rect,
                                       bool prepare_rtree)
    : DisplayListBuilder(
          std::make_shared<DlOpRecorder>(cull_rect, prepare_rtree)) {}

DisplayListBuilder::DisplayListBuilder(
    const std::shared_ptr<DlOpRecorder>& recorder)
    : DlCanvasToReceiver(recorder), recorder_(recorder) {}

sk_sp<DisplayList> DisplayListBuilder::Build() {
  FML_CHECK(recorder_ != nullptr);
  FML_CHECK(receiver_ != nullptr);

  RestoreToCount(1);

  sk_sp<DisplayList> dl =
      recorder_->Build(current_group_opacity_compatibility(),
                       current_affects_transparent_layer());

  recorder_ = nullptr;
  receiver_ = nullptr;

  return dl;
}

}  // namespace flutter
