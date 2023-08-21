// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_DISPLAY_LIST_BUILDER_H_
#define FLUTTER_DISPLAY_LIST_DISPLAY_LIST_BUILDER_H_

#include "flutter/display_list/dl_canvas.h"
#include "flutter/display_list/dl_canvas_to_receiver.h"
#include "flutter/display_list/dl_op_flags.h"
#include "flutter/display_list/dl_op_receiver.h"
#include "flutter/display_list/dl_op_recorder.h"
#include "flutter/display_list/utils/dl_bounds_accumulator.h"
#include "flutter/display_list/utils/dl_matrix_clip_tracker.h"
#include "flutter/fml/macros.h"

namespace flutter {

// The primary class used to build a display list. The list of methods
// here matches the list of methods invoked on a |DlOpReceiver| combined
// with the list of methods invoked on a |DlCanvas|.
class DisplayListBuilder final : public DlCanvasToReceiver,  //
                                 public SkRefCnt {
 public:
  static constexpr SkRect kMaxCullRect =
      SkRect::MakeLTRB(-1E9F, -1E9F, 1E9F, 1E9F);

  explicit DisplayListBuilder(bool prepare_rtree)
      : DisplayListBuilder(kMaxCullRect, prepare_rtree) {}

  explicit DisplayListBuilder(const SkRect& cull_rect = kMaxCullRect,
                              bool prepare_rtree = false);

  ~DisplayListBuilder() = default;

  sk_sp<DisplayList> Build();

 private:
  explicit DisplayListBuilder(const std::shared_ptr<DlOpRecorder>& recorder);

  std::shared_ptr<DlOpRecorder> recorder_;

  // This method exposes the internal stateful DlOpReceiver implementation
  // of the DisplayListBuilder, primarily for testing purposes. Its use
  // is obsolete and forbidden in every other case and is only shared to a
  // pair of "friend" accessors in the benchmark/unittest files.
  DlOpReceiver& asReceiver() { return *receiver_; }

  friend DlOpReceiver& DisplayListBuilderBenchmarkAccessor(
      DisplayListBuilder& builder);
  friend DlOpReceiver& DisplayListBuilderTestingAccessor(
      DisplayListBuilder& builder);
  friend DlPaint DisplayListBuilderTestingAttributes(
      DisplayListBuilder& builder);
};

}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_DISPLAY_LIST_BUILDER_H_
