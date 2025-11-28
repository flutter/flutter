// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_PAINT_H_
#define FLUTTER_LIB_UI_PAINTING_PAINT_H_

#include "flutter/display_list/display_list.h"
#include "flutter/display_list/dl_op_flags.h"
#include "third_party/dart/runtime/include/dart_api.h"

namespace flutter {

class Paint {
 public:
  Paint(Dart_Handle paint_objects, Dart_Handle paint_data);

  const DlPaint* paint(DlPaint& paint,
                       const DisplayListAttributeFlags& flags,
                       DlTileMode tile_mode) const;

  bool isNull() const { return Dart_IsNull(paint_data_); }
  bool isNotNull() const { return !Dart_IsNull(paint_data_); }

 private:
  Dart_Handle paint_objects_;
  Dart_Handle paint_data_;
};

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_PAINTING_PAINT_H_
