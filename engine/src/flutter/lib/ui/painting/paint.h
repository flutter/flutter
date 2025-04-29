// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_PAINT_H_
#define FLUTTER_LIB_UI_PAINTING_PAINT_H_

#include "flutter/display_list/dl_op_flags.h"
#include "third_party/dart/runtime/include/dart_api.h"

namespace flutter {

DlPaint* CreatePaint(DlPaint& paint,
                     const DisplayListAttributeFlags& flags,
                     DlTileMode tile_mode,
                     Dart_Handle paint_objects,
                     bool has_paint_objects,
                     std::vector<uint8_t>& byte_data);

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_PAINTING_PAINT_H_
