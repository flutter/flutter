// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_COLOR_FILTER_H_
#define FLUTTER_LIB_UI_COLOR_FILTER_H_

#include "flutter/lib/ui/dart_wrapper.h"
#include "third_party/skia/include/core/SkColorFilter.h"
#include "third_party/tonic/typed_data/typed_list.h"

using tonic::DartPersistentValue;

namespace tonic {
class DartLibraryNatives;
}  // namespace tonic

namespace flutter {

// A handle to an SkCodec object.
//
// Doesn't mirror SkCodec's API but provides a simple sequential access API.
class ColorFilter : public RefCountedDartWrappable<ColorFilter> {
  DEFINE_WRAPPERTYPEINFO();
  FML_FRIEND_MAKE_REF_COUNTED(ColorFilter);

 public:
  static fml::RefPtr<ColorFilter> Create();

  // Flutter still defines the matrix to be biased by 255 in the last column
  // (translate). skia is normalized, treating the last column as 0...1, so we
  // post-scale here before calling the skia factory.
  static sk_sp<SkColorFilter> MakeColorMatrixFilter255(const float array[20]);

  void initMode(int color, int blend_mode);
  void initMatrix(const tonic::Float32List& color_matrix);
  void initSrgbToLinearGamma();
  void initLinearToSrgbGamma();

  ~ColorFilter() override;

  sk_sp<SkColorFilter> filter() const { return filter_; }

  static void RegisterNatives(tonic::DartLibraryNatives* natives);

 private:
  sk_sp<SkColorFilter> filter_;
};

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_COLOR_FILTER_H_
