// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/testing/mock_texture.h"
#include "flutter/flow/layers/layer.h"
#include "flutter/flow/testing/skia_gpu_object_layer_test.h"

namespace flutter {
namespace testing {

MockTexture::MockTexture(int64_t textureId) : Texture(textureId) {}

void MockTexture::Paint(PaintContext& context,
                        const SkRect& bounds,
                        bool freeze,
                        const DlImageSampling sampling) {
  paint_calls_.emplace_back(PaintCall{*(context.canvas), bounds, freeze,
                                      context.gr_context, sampling,
                                      context.paint});
}

bool operator==(const MockTexture::PaintCall& a,
                const MockTexture::PaintCall& b) {
  return &a.canvas == &b.canvas && a.bounds == b.bounds &&
         a.context == b.context && a.freeze == b.freeze &&
         a.sampling == b.sampling && a.paint == b.paint;
}

std::ostream& operator<<(std::ostream& os, const MockTexture::PaintCall& data) {
  return os << &data.canvas << " " << data.bounds << " " << data.context << " "
            << data.freeze << " " << data.sampling << " " << data.paint;
}

}  // namespace testing
}  // namespace flutter
