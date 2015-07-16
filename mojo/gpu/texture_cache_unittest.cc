// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/gpu/texture_cache.h"

#include "base/bind.h"
#include "base/message_loop/message_loop.h"
#include "mojo/gpu/gl_context.h"
#include "mojo/gpu/gl_texture.h"
#include "mojo/public/cpp/application/application_impl.h"
#include "mojo/public/cpp/application/application_test_base.h"
#include "mojo/services/geometry/public/interfaces/geometry.mojom.h"
#include "mojo/services/surfaces/public/interfaces/surface_id.mojom.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace {

static const base::TimeDelta kDefaultMessageDelay =
    base::TimeDelta::FromMilliseconds(20);

class TextureCacheTest : public mojo::test::ApplicationTestBase {
 public:
  TextureCacheTest() : weak_factory_(this) {}
  ~TextureCacheTest() override {}

  void SetUp() override {
    mojo::test::ApplicationTestBase::SetUp();
    gl_context_ = mojo::GLContext::Create(application_impl()->shell());
    quit_message_loop_callback_ = base::Bind(
        &TextureCacheTest::QuitMessageLoopCallback, weak_factory_.GetWeakPtr());
  }

  void QuitMessageLoopCallback() { base::MessageLoop::current()->Quit(); }

  void KickMessageLoop() {
    base::MessageLoop::current()->PostDelayedTask(
        FROM_HERE, quit_message_loop_callback_, kDefaultMessageDelay);
    base::MessageLoop::current()->Run();
  }

 protected:
  base::WeakPtr<mojo::GLContext> gl_context_;
  base::Closure quit_message_loop_callback_;
  base::WeakPtrFactory<TextureCacheTest> weak_factory_;

 private:
  DISALLOW_COPY_AND_ASSIGN(TextureCacheTest);
};

TEST_F(TextureCacheTest, GetTextureOnce) {
  mojo::TextureCache texture_cache(gl_context_, nullptr);
  mojo::Size size;
  size.width = 100;
  size.height = 100;
  scoped_ptr<mojo::TextureCache::TextureInfo> texture_info(
      texture_cache.GetTexture(size).Pass());
  EXPECT_NE(texture_info->Texture().get(), nullptr);
}

TEST_F(TextureCacheTest, GetTextureTwice) {
  mojo::TextureCache texture_cache(gl_context_, nullptr);
  mojo::Size size;
  size.width = 100;
  size.height = 100;
  scoped_ptr<mojo::TextureCache::TextureInfo> texture_info_1(
      texture_cache.GetTexture(size).Pass());
  scoped_ptr<mojo::GLTexture> texture_1(texture_info_1->Texture().Pass());
  scoped_ptr<mojo::TextureCache::TextureInfo> texture_info_2(
      texture_cache.GetTexture(size).Pass());
  scoped_ptr<mojo::GLTexture> texture_2(texture_info_2->Texture().Pass());

  EXPECT_NE(texture_1.get(), nullptr);
  EXPECT_NE(texture_2.get(), nullptr);
  EXPECT_NE(texture_1.get(), texture_2.get());
  EXPECT_NE(texture_info_1->ResourceId(), texture_info_2->ResourceId());
}

TEST_F(TextureCacheTest, GetTextureAfterReturnSameSize) {
  mojo::ResourceReturnerPtr resource_returner;
  mojo::TextureCache texture_cache(gl_context_, &resource_returner);
  mojo::Size size;
  size.width = 100;
  size.height = 100;

  // get a texture
  scoped_ptr<mojo::TextureCache::TextureInfo> texture_info_1(
      texture_cache.GetTexture(size).Pass());
  scoped_ptr<mojo::GLTexture> texture(texture_info_1->Texture().Pass());
  mojo::GLTexture* texture_ptr = texture.get();
  EXPECT_NE(texture_ptr, nullptr);

  mojo::Array<mojo::ReturnedResourcePtr> resources;
  mojo::ReturnedResourcePtr returnedResource = mojo::ReturnedResource::New();
  returnedResource->id = texture_info_1->ResourceId();
  returnedResource->sync_point = 0u;
  returnedResource->count = 1u;
  returnedResource->lost = false;
  resources.push_back(returnedResource.Pass());

  // return the texture via resource id
  texture_cache.NotifyPendingResourceReturn(texture_info_1->ResourceId(),
                                            texture.Pass());
  resource_returner->ReturnResources(resources.Pass());

  KickMessageLoop();

  // get a texture of the same size - it should be the same one as before
  scoped_ptr<mojo::TextureCache::TextureInfo> texture_info_2(
      texture_cache.GetTexture(size).Pass());
  scoped_ptr<mojo::GLTexture> texture_2(texture_info_2->Texture().Pass());

  EXPECT_NE(texture_2.get(), nullptr);
  EXPECT_EQ(size.width, texture_2->size().width);
  EXPECT_EQ(size.height, texture_2->size().height);
  EXPECT_EQ(texture_info_1->ResourceId(), texture_info_2->ResourceId());
}

TEST_F(TextureCacheTest, GetTextureAfterReturnDifferentSize) {
  mojo::ResourceReturnerPtr resource_returner;
  mojo::TextureCache texture_cache(gl_context_, &resource_returner);
  mojo::Size size;
  size.width = 100;
  size.height = 100;

  // get a texture
  scoped_ptr<mojo::TextureCache::TextureInfo> texture_info_1(
      texture_cache.GetTexture(size).Pass());
  scoped_ptr<mojo::GLTexture> texture(texture_info_1->Texture().Pass());
  mojo::GLTexture* texture_ptr = texture.get();
  EXPECT_NE(texture_ptr, nullptr);

  mojo::Array<mojo::ReturnedResourcePtr> resources;
  mojo::ReturnedResourcePtr returnedResource = mojo::ReturnedResource::New();
  returnedResource->id = texture_info_1->ResourceId();
  returnedResource->sync_point = 0u;
  returnedResource->count = 1u;
  returnedResource->lost = false;
  resources.push_back(returnedResource.Pass());

  // return the texture via resource id
  texture_cache.NotifyPendingResourceReturn(texture_info_1->ResourceId(),
                                            texture.Pass());
  resource_returner->ReturnResources(resources.Pass());

  KickMessageLoop();

  mojo::Size different_size;
  different_size.width = size.width - 1;
  different_size.height = size.height - 1;

  // get a texture of the different size - it should not be the same one as
  // before
  scoped_ptr<mojo::TextureCache::TextureInfo> texture_info_2(
      texture_cache.GetTexture(different_size).Pass());
  scoped_ptr<mojo::GLTexture> texture_2(texture_info_2->Texture().Pass());

  EXPECT_NE(texture_2.get(), nullptr);
  EXPECT_NE(size.width, texture_2->size().width);
  EXPECT_NE(size.height, texture_2->size().height);
  EXPECT_EQ(different_size.width, texture_2->size().width);
  EXPECT_EQ(different_size.height, texture_2->size().height);
  EXPECT_NE(texture_info_1->ResourceId(), texture_info_2->ResourceId());
}

TEST_F(TextureCacheTest, GetTextureReleasedGlContext) {
  gl_context_.reset();
  mojo::TextureCache texture_cache(gl_context_, nullptr);
  mojo::Size size;
  size.width = 100;
  size.height = 100;

  EXPECT_EQ(texture_cache.GetTexture(size).get(), nullptr);
}

TEST_F(TextureCacheTest, ReturnResourcesReleasedGlContext) {
  mojo::ResourceReturnerPtr resource_returner;
  mojo::TextureCache texture_cache(gl_context_, &resource_returner);
  mojo::Size size;
  size.width = 100;
  size.height = 100;

  // get a texture
  scoped_ptr<mojo::TextureCache::TextureInfo> texture_info(
      texture_cache.GetTexture(size).Pass());
  scoped_ptr<mojo::GLTexture> texture(texture_info->Texture().Pass());
  mojo::GLTexture* texture_ptr = texture.get();
  EXPECT_NE(texture_ptr, nullptr);

  gl_context_.reset();

  mojo::Array<mojo::ReturnedResourcePtr> resources;
  mojo::ReturnedResourcePtr returnedResource = mojo::ReturnedResource::New();
  returnedResource->id = texture_info->ResourceId();
  returnedResource->sync_point = 0u;
  returnedResource->count = 1u;
  returnedResource->lost = false;
  resources.push_back(returnedResource.Pass());

  // return the texture via resource id
  texture_cache.NotifyPendingResourceReturn(texture_info->ResourceId(),
                                            texture.Pass());
  resource_returner->ReturnResources(resources.Pass());

  KickMessageLoop();
}

}  // namespace
