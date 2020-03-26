// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/texture.h"
#include "flutter/testing/assertions_skia.h"

#include <ostream>
#include <vector>

namespace flutter {
namespace testing {

// Mock implementation of the |Texture| interface that does not interact with
// the GPU.  It simply records the list of various calls made so the test can
// later verify them against expected data.
class MockTexture : public Texture {
 public:
  struct PaintCall {
    SkCanvas& canvas;
    SkRect bounds;
    bool freeze;
    GrContext* context;
  };

  explicit MockTexture(int64_t textureId);

  // Called from raster thread.
  void Paint(SkCanvas& canvas,
             const SkRect& bounds,
             bool freeze,
             GrContext* context) override;

  void OnGrContextCreated() override { gr_context_created_ = true; }
  void OnGrContextDestroyed() override { gr_context_destroyed_ = true; }
  void MarkNewFrameAvailable() override {}
  void OnTextureUnregistered() override { unregistered_ = true; }

  const std::vector<PaintCall>& paint_calls() { return paint_calls_; }
  bool gr_context_created() { return gr_context_created_; }
  bool gr_context_destroyed() { return gr_context_destroyed_; }
  bool unregistered() { return unregistered_; }

 private:
  std::vector<PaintCall> paint_calls_;
  bool gr_context_created_ = false;
  bool gr_context_destroyed_ = false;
  bool unregistered_ = false;
};

extern bool operator==(const MockTexture::PaintCall& a,
                       const MockTexture::PaintCall& b);
extern std::ostream& operator<<(std::ostream& os,
                                const MockTexture::PaintCall& data);

}  // namespace testing
}  // namespace flutter
