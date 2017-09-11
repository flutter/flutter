// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_SHADER_H_
#define FLUTTER_LIB_UI_PAINTING_SHADER_H_

#include "lib/tonic/dart_wrappable.h"
#include "third_party/skia/include/core/SkShader.h"

namespace blink {

class Shader : public fxl::RefCountedThreadSafe<Shader>,
               public tonic::DartWrappable {
  DEFINE_WRAPPERTYPEINFO();
  FRIEND_MAKE_REF_COUNTED(Shader);

 public:
  ~Shader() override;

  const sk_sp<SkShader>& shader() { return shader_; }
  void set_shader(sk_sp<SkShader> shader) { shader_ = std::move(shader); }

 protected:
  Shader(sk_sp<SkShader> shader);

 private:
  sk_sp<SkShader> shader_;
};

}  // namespace blink

#endif  // FLUTTER_LIB_UI_PAINTING_SHADER_H_
