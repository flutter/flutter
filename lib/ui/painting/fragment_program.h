// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_FRAGMENT_PROGRAM_H_
#define FLUTTER_LIB_UI_PAINTING_FRAGMENT_PROGRAM_H_

#include "flutter/lib/ui/dart_wrapper.h"
#include "flutter/lib/ui/painting/fragment_shader.h"
#include "third_party/skia/include/effects/SkRuntimeEffect.h"
#include "third_party/tonic/dart_library_natives.h"
#include "third_party/tonic/typed_data/typed_list.h"

#include <string>
#include <vector>

namespace tonic {
class DartLibraryNatives;
}  // namespace tonic

namespace flutter {

class FragmentProgram : public RefCountedDartWrappable<FragmentProgram> {
  DEFINE_WRAPPERTYPEINFO();
  FML_FRIEND_MAKE_REF_COUNTED(FragmentProgram);

 public:
  ~FragmentProgram() override;
  static fml::RefPtr<FragmentProgram> Create();

  void init(std::string sksl, bool debugPrintSksl);

  fml::RefPtr<FragmentShader> shader(Dart_Handle shader,
                                     tonic::Float32List& uniforms,
                                     Dart_Handle samplers);

  static void RegisterNatives(tonic::DartLibraryNatives* natives);

 private:
  FragmentProgram();
  sk_sp<SkRuntimeEffect> runtime_effect_;
};

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_PAINTING_FRAGMENT_PROGRAM_H_
