// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_DL_TEXT_H_
#define FLUTTER_DISPLAY_LIST_DL_TEXT_H_

#include <memory>

#include "flutter/display_list/geometry/dl_geometry_types.h"

namespace impeller {
class TextFrame;
}

class SkTextBlob;

namespace flutter {
class DlText {
 public:
  virtual DlRect GetBounds() const = 0;
  virtual std::shared_ptr<impeller::TextFrame> GetTextFrame() const = 0;
  virtual const SkTextBlob* GetTextBlob() const = 0;

  bool operator==(const DlText& other) const;

 protected:
  DlText() = default;
  virtual ~DlText() = default;

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(DlText);
};
}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_DL_TEXT_H_
