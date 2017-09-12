// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/shader.h"

#include "flutter/common/threads.h"
#include "flutter/lib/ui/painting/utils.h"

namespace blink {

IMPLEMENT_WRAPPERTYPEINFO(ui, Shader);

Shader::Shader(sk_sp<SkShader> shader) : shader_(shader) {}

Shader::~Shader() {
  // Skia objects must be deleted on the IO thread so that any associated GL
  // objects will be cleaned up through the IO thread's GL context.
  SkiaUnrefOnIOThread(&shader_);
}

}  // namespace blink
