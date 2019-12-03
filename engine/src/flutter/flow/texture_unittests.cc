// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/texture.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

class MockTexture : public Texture {
 public:
  MockTexture(int64_t textureId) : Texture(textureId) {}

  ~MockTexture() override = default;

  // Called from GPU thread.
  void Paint(SkCanvas& canvas,
             const SkRect& bounds,
             bool freeze,
             GrContext* context) override {}

  void OnGrContextCreated() override {}

  void OnGrContextDestroyed() override {}

  void MarkNewFrameAvailable() override {}

  void OnTextureUnregistered() override { unregistered_ = true; }

  bool unregistered() { return unregistered_; }

 private:
  bool unregistered_ = false;
};

TEST(TextureRegistry, UnregisterTextureCallbackTriggered) {
  TextureRegistry textureRegistry;
  std::shared_ptr<MockTexture> mockTexture = std::make_shared<MockTexture>(0);
  textureRegistry.RegisterTexture(mockTexture);
  textureRegistry.UnregisterTexture(0);
  ASSERT_TRUE(mockTexture->unregistered());
}

}  // namespace testing
}  // namespace flutter
