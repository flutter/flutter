// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/painting/Shader.h"

namespace blink {

IMPLEMENT_WRAPPERTYPEINFO(Shader);

Shader::Shader(PassRefPtr<SkShader> shader)
    : shader_(shader) {
}

Shader::~Shader() {
}

} // namespace blink
