// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_FRAGMENT_SHADER_H_
#define FLUTTER_LIB_UI_PAINTING_FRAGMENT_SHADER_H_

#include "flutter/lib/ui/dart_wrapper.h"
#include "flutter/lib/ui/painting/image.h"
#include "flutter/lib/ui/painting/image_shader.h"
#include "flutter/lib/ui/painting/shader.h"
#include "third_party/skia/include/core/SkShader.h"
#include "third_party/skia/include/effects/SkRuntimeEffect.h"
#include "third_party/tonic/dart_library_natives.h"
#include "third_party/tonic/typed_data/typed_list.h"

#include <string>
#include <vector>

namespace tonic {
class DartLibraryNatives;
}  // namespace tonic

namespace flutter {

class FragmentShader : public Shader {
  DEFINE_WRAPPERTYPEINFO();
  FML_FRIEND_MAKE_REF_COUNTED(FragmentShader);

 public:
  ~FragmentShader() override;
  static fml::RefPtr<FragmentShader> Create(Dart_Handle dart_handle,
                                            sk_sp<SkShader> shader);

  std::shared_ptr<DlColorSource> shader(DlImageSampling) override;

  static void RegisterNatives(tonic::DartLibraryNatives* natives);

 private:
  explicit FragmentShader(sk_sp<SkShader> shader);

  std::shared_ptr<DlColorSource> source_;
};

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_PAINTING_FRAGMENT_SHADER_H_
