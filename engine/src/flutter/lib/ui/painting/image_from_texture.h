// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_IMAGE_FROM_TEXTURE_H_
#define FLUTTER_LIB_UI_PAINTING_IMAGE_FROM_TEXTURE_H_

#include "third_party/dart/runtime/include/dart_api.h"

namespace flutter {

/// Creates a ui.Image from a registered texture's current content.
///
/// This is the native implementation of Image.fromTextureId() in Dart.
/// It schedules work on the raster thread to create a DlImage from the
/// texture, then wraps it as a CanvasImage and invokes the callback on
/// the UI thread.
///
/// @param texture_id The ID of a registered texture.
/// @param callback_handle A Dart closure to invoke with the result.
void CreateImageFromTextureId(int64_t texture_id, Dart_Handle callback_handle);

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_PAINTING_IMAGE_FROM_TEXTURE_H_
