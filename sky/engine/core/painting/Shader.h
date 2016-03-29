// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_PAINTING_SHADER_H_
#define SKY_ENGINE_CORE_PAINTING_SHADER_H_

#include "sky/engine/tonic/dart_wrappable.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/ThreadSafeRefCounted.h"
#include "third_party/skia/include/core/SkShader.h"

namespace blink {

class Shader : public ThreadSafeRefCounted<Shader>, public DartWrappable {
  DEFINE_WRAPPERTYPEINFO();
 public:
  ~Shader() override;

  sk_sp<SkShader> shader() { return shader_; }
  void set_shader(sk_sp<SkShader> shader) { shader_ = shader; }

 protected:
  Shader(sk_sp<SkShader> shader);

 private:
  sk_sp<SkShader> shader_;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_PAINTING_SHADER_H_
