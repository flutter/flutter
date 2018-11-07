// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_SHADER_H_
#define FLUTTER_LIB_UI_PAINTING_SHADER_H_

#include "flutter/flow/skia_gpu_object.h"
#include "flutter/lib/ui/dart_wrapper.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "third_party/skia/include/core/SkShader.h"

namespace blink {

class Shader : public RefCountedDartWrappable<Shader> {
  DEFINE_WRAPPERTYPEINFO();
  FML_FRIEND_MAKE_REF_COUNTED(Shader);

 public:
  ~Shader() override;

  sk_sp<SkShader> shader() { return shader_.get(); }

  void set_shader(flow::SkiaGPUObject<SkShader> shader) {
    shader_ = std::move(shader);
  }

 protected:
  Shader(flow::SkiaGPUObject<SkShader> shader = {});

 private:
  flow::SkiaGPUObject<SkShader> shader_;
};

}  // namespace blink

#endif  // FLUTTER_LIB_UI_PAINTING_SHADER_H_
