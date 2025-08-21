// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_DL_TEXT_H_
#define FLUTTER_DISPLAY_LIST_DL_TEXT_H_

#include "flutter/display_list/geometry/dl_geometry_types.h"
#include "third_party/skia/include/core/SkRefCnt.h"

namespace impeller {
class TextFrame;
}

class SkTextBlob;

namespace flutter {
class DlText {
 public:
  virtual DlRect getBounds() const = 0;
  virtual std::shared_ptr<impeller::TextFrame> getTextFrame() const = 0;
  virtual sk_sp<SkTextBlob> getTextBlob() const = 0;

 protected:
  DlText() = default;
  virtual ~DlText() = default;

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(DlText);
};
}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_DL_TEXT_H_
