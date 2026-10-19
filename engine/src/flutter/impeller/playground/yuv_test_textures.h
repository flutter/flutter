// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_PLAYGROUND_YUV_TEST_TEXTURES_H_
#define FLUTTER_IMPELLER_PLAYGROUND_YUV_TEST_TEXTURES_H_

#include <memory>

#include "impeller/core/texture.h"
#include "impeller/geometry/color.h"
#include "impeller/renderer/context.h"
#include "third_party/abseil-cpp/absl/status/statusor.h"

namespace impeller {

/// The planes of a small bi-planar YUV test image.
struct TestYUVTextures {
  /// 8x8 `PixelFormat::kR8UNormInt` luma plane.
  std::shared_ptr<Texture> y;
  /// 4x4 `PixelFormat::kR8G8UNormInt` interleaved (U, V) chroma plane.
  std::shared_ptr<Texture> uv;
};

/// Creates and uploads Y and UV planes holding four solid horizontal bands
/// (red, green, blue, white from top to bottom) encoded in `yuv_color_space`.
///
/// Intended for exercising the YUV to RGB conversion filter. Returns an error
/// describing the step that failed if the textures could not be created or
/// uploaded.
absl::StatusOr<TestYUVTextures> CreateTestYUVTextures(
    const Context& context,
    YUVColorSpace yuv_color_space);

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_PLAYGROUND_YUV_TEST_TEXTURES_H_
