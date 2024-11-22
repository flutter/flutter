// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_EFFECTS_COLOR_SOURCES_DL_COLOR_COLOR_SOURCE_H_
#define FLUTTER_DISPLAY_LIST_EFFECTS_COLOR_SOURCES_DL_COLOR_COLOR_SOURCE_H_

#include "flutter/display_list/effects/dl_color_source.h"

namespace flutter {

class DlColorColorSource final : public DlColorSource {
 public:
  explicit DlColorColorSource(DlColor color) : color_(color) {}

  bool isUIThreadSafe() const override { return true; }

  std::shared_ptr<DlColorSource> shared() const override {
    return std::make_shared<DlColorColorSource>(color_);
  }

  const DlColorColorSource* asColor() const override { return this; }

  DlColorSourceType type() const override { return DlColorSourceType::kColor; }
  size_t size() const override { return sizeof(*this); }

  bool is_opaque() const override { return color_.getAlpha() == 255; }

  DlColor color() const { return color_; }

 protected:
  bool equals_(DlColorSource const& other) const override;

 private:
  DlColor color_;

  FML_DISALLOW_COPY_ASSIGN_AND_MOVE(DlColorColorSource);
};

}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_EFFECTS_COLOR_SOURCES_DL_COLOR_COLOR_SOURCE_H_
