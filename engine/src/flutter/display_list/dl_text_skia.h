// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_DL_TEXT_SKIA_H_
#define FLUTTER_DISPLAY_LIST_DL_TEXT_SKIA_H_

#include "flutter/display_list/dl_text.h"
#include "flutter/display_list/geometry/dl_geometry_conversions.h"
#include "third_party/skia/include/core/SkTextBlob.h"

namespace flutter {
class DlTextSkia : public DlText {
 public:
  static std::shared_ptr<DlTextSkia> Make(const sk_sp<SkTextBlob>& blob);

  ~DlTextSkia() = default;

  explicit DlTextSkia(const sk_sp<SkTextBlob>& blob);

  DlRect GetBounds() const { return ToDlRect(blob_->bounds()); }

  std::shared_ptr<impeller::TextFrame> GetTextFrame() const { return nullptr; }

  const SkTextBlob* GetTextBlob() const { return blob_.get(); }

 private:
  sk_sp<SkTextBlob> blob_;

  FML_DISALLOW_COPY_AND_ASSIGN(DlTextSkia);
};
}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_DL_TEXT_SKIA_H_
