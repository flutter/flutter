// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_FRAGMENT_UNIFORMS_GLES_H_
#define FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_FRAGMENT_UNIFORMS_GLES_H_

#include <cstddef>
#include <string_view>

namespace impeller {

// Fragment uniform blocks leave stale pixels with this driver.
// https://github.com/flutter/flutter/issues/196426
// Only select the plain-uniform archives for this observed driver and a
// device with at least the vector budget used to compile those archives.
inline bool ShouldUsePlainFragmentUniforms(
    std::string_view renderer,
    std::string_view version,
    size_t max_fragment_uniform_vectors) {
  constexpr std::string_view kDriver = "OpenGL ES 3.2 v1.g24p0-";
  return renderer == "Mali-G52" && version.size() > kDriver.size() &&
         version.substr(0, kDriver.size()) == kDriver &&
         max_fragment_uniform_vectors >= 4096;
}

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_FRAGMENT_UNIFORMS_GLES_H_
