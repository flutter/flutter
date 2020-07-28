// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/testing/mock_texture.h"

namespace flutter {
namespace testing {

MockTexture::MockTexture(int64_t textureId) : Texture(textureId) {}

void MockTexture::Paint(SkCanvas& canvas,
                        const SkRect& bounds,
                        bool freeze,
                        GrDirectContext* context,
                        SkFilterQuality filter_quality) {
  paint_calls_.emplace_back(
      PaintCall{canvas, bounds, freeze, context, filter_quality});
}

bool operator==(const MockTexture::PaintCall& a,
                const MockTexture::PaintCall& b) {
  return &a.canvas == &b.canvas && a.bounds == b.bounds &&
         a.context == b.context && a.freeze == b.freeze &&
         a.filter_quality == b.filter_quality;
}

std::ostream& operator<<(std::ostream& os, const MockTexture::PaintCall& data) {
  return os << &data.canvas << " " << data.bounds << " " << data.context << " "
            << data.freeze << " " << data.filter_quality;
}

}  // namespace testing
}  // namespace flutter
