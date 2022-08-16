// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_DISPLAY_LIST_BUILDER_MULTIPLEXER_H_
#define FLUTTER_DISPLAY_LIST_DISPLAY_LIST_BUILDER_MULTIPLEXER_H_

#include "flutter/display_list/display_list_builder.h"
#include "flutter/display_list/display_list_image_filter.h"
#include "flutter/display_list/display_list_paint.h"
#include "flutter/fml/macros.h"

namespace flutter {

/// A class that mutiplexes some of the DisplayListBuilder calls to multiple
/// other builders. For now it only implements saveLayer and restore as those
/// are needed to create a replacement for PaintContext::internal_nodes_canvas.
class DisplayListBuilderMultiplexer {
 public:
  DisplayListBuilderMultiplexer() = default;

  void addBuilder(DisplayListBuilder* builder);

  void saveLayer(const SkRect* bounds,
                 const DlPaint* paint,
                 const DlImageFilter* backdrop_filter = nullptr);

  void restore();

 private:
  std::vector<DisplayListBuilder*> builders_;
};

}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_DISPLAY_LIST_BUILDER_MULTIPLEXER_H_
