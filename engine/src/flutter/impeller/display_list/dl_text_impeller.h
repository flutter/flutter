// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_DISPLAY_LIST_DL_TEXT_IMPELLER_H_
#define FLUTTER_IMPELLER_DISPLAY_LIST_DL_TEXT_IMPELLER_H_

#include "flutter/display_list/dl_text.h"
#include "flutter/impeller/typographer/text_frame.h"

namespace flutter {
class DlTextImpeller : public DlText {
 public:
  static std::shared_ptr<DlTextImpeller> Make(
      const std::shared_ptr<impeller::TextFrame>& frame) {
    return std::make_shared<DlTextImpeller>(frame);
  }

  ~DlTextImpeller() = default;

  explicit DlTextImpeller(const std::shared_ptr<impeller::TextFrame>& frame)
      : frame_(frame) {}

  DlRect getBounds() const { return frame_->GetBounds(); }

  std::shared_ptr<impeller::TextFrame> getTextFrame() const { return frame_; }

  sk_sp<SkTextBlob> getTextBlob() const { return nullptr; }

 private:
  std::shared_ptr<impeller::TextFrame> frame_;

  FML_DISALLOW_COPY_AND_ASSIGN(DlTextImpeller);
};
}  // namespace flutter

#endif  // FLUTTER_IMPELLER_DISPLAY_LIST_DL_TEXT_IMPELLER_H_
