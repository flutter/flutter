// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/testing/mock_texture.h"
#include "flutter/flow/texture.h"

#include "gtest/gtest.h"

namespace flutter {
namespace testing {

TEST(TextureRegistryTest, UnregisterTextureCallbackTriggered) {
  TextureRegistry registry;
  auto mock_texture1 = std::make_shared<MockTexture>(0);
  auto mock_texture2 = std::make_shared<MockTexture>(1);

  registry.RegisterTexture(mock_texture1);
  registry.RegisterTexture(mock_texture2);
  ASSERT_EQ(registry.GetTexture(0), mock_texture1);
  ASSERT_EQ(registry.GetTexture(1), mock_texture2);
  ASSERT_FALSE(mock_texture1->unregistered());
  ASSERT_FALSE(mock_texture2->unregistered());

  registry.UnregisterTexture(0);
  ASSERT_EQ(registry.GetTexture(0), nullptr);
  ASSERT_TRUE(mock_texture1->unregistered());
  ASSERT_FALSE(mock_texture2->unregistered());

  registry.UnregisterTexture(1);
  ASSERT_EQ(registry.GetTexture(1), nullptr);
  ASSERT_TRUE(mock_texture1->unregistered());
  ASSERT_TRUE(mock_texture2->unregistered());
}

TEST(TextureRegistryTest, GrContextCallbackTriggered) {
  TextureRegistry registry;
  auto mock_texture1 = std::make_shared<MockTexture>(0);
  auto mock_texture2 = std::make_shared<MockTexture>(1);

  registry.RegisterTexture(mock_texture1);
  registry.RegisterTexture(mock_texture2);
  ASSERT_FALSE(mock_texture1->gr_context_created());
  ASSERT_FALSE(mock_texture2->gr_context_created());
  ASSERT_FALSE(mock_texture1->gr_context_destroyed());
  ASSERT_FALSE(mock_texture2->gr_context_destroyed());

  registry.OnGrContextCreated();
  ASSERT_TRUE(mock_texture1->gr_context_created());
  ASSERT_TRUE(mock_texture2->gr_context_created());

  registry.UnregisterTexture(0);
  registry.OnGrContextDestroyed();
  ASSERT_FALSE(mock_texture1->gr_context_destroyed());
  ASSERT_TRUE(mock_texture2->gr_context_created());
}

TEST(TextureRegistryTest, RegisterTextureTwice) {
  TextureRegistry registry;
  auto mock_texture1 = std::make_shared<MockTexture>(0);
  auto mock_texture2 = std::make_shared<MockTexture>(0);

  registry.RegisterTexture(mock_texture1);
  ASSERT_EQ(registry.GetTexture(0), mock_texture1);
  registry.RegisterTexture(mock_texture2);
  ASSERT_EQ(registry.GetTexture(0), mock_texture2);
  ASSERT_FALSE(mock_texture1->unregistered());
  ASSERT_FALSE(mock_texture2->unregistered());

  registry.UnregisterTexture(0);
  ASSERT_EQ(registry.GetTexture(0), nullptr);
  ASSERT_FALSE(mock_texture1->unregistered());
  ASSERT_TRUE(mock_texture2->unregistered());
}

TEST(TextureRegistryTest, ReuseSameTextureSlot) {
  TextureRegistry registry;
  auto mock_texture1 = std::make_shared<MockTexture>(0);
  auto mock_texture2 = std::make_shared<MockTexture>(0);

  registry.RegisterTexture(mock_texture1);
  ASSERT_EQ(registry.GetTexture(0), mock_texture1);

  registry.UnregisterTexture(0);
  ASSERT_EQ(registry.GetTexture(0), nullptr);
  ASSERT_TRUE(mock_texture1->unregistered());
  ASSERT_FALSE(mock_texture2->unregistered());

  registry.RegisterTexture(mock_texture2);
  ASSERT_EQ(registry.GetTexture(0), mock_texture2);

  registry.UnregisterTexture(0);
  ASSERT_EQ(registry.GetTexture(0), nullptr);
  ASSERT_TRUE(mock_texture1->unregistered());
  ASSERT_TRUE(mock_texture2->unregistered());
}

}  // namespace testing
}  // namespace flutter
