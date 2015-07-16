// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/gpu/texture_uploader.h"

#include "base/bind.h"
#include "base/message_loop/message_loop.h"
#include "mojo/gpu/texture_cache.h"
#include "mojo/public/cpp/application/application_impl.h"
#include "mojo/public/cpp/application/application_test_base.h"
#include "mojo/public/cpp/application/connect.h"
#include "mojo/services/surfaces/public/interfaces/surface_id.mojom.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace {

class TextureUploaderTest : public mojo::test::ApplicationTestBase {
 public:
  TextureUploaderTest() : surface_id_(1u), weak_factory_(this) {}
  ~TextureUploaderTest() override {}

  void SetUp() override {
    mojo::test::ApplicationTestBase::SetUp();

    mojo::ServiceProviderPtr surfaces_service_provider;
    application_impl()->shell()->ConnectToApplication(
        "mojo:surfaces_service", mojo::GetProxy(&surfaces_service_provider),
        nullptr);
    mojo::ConnectToService(surfaces_service_provider.get(), &surface_);
    gl_context_ = mojo::GLContext::Create(application_impl()->shell());
    surface_->CreateSurface(surface_id_);
    texture_cache_.reset(new mojo::TextureCache(gl_context_, nullptr));
  }

  void OnFrameCompleteExit() { base::MessageLoop::current()->Quit(); }

 protected:
  uint32_t surface_id_;
  base::WeakPtr<mojo::GLContext> gl_context_;
  scoped_ptr<mojo::TextureCache> texture_cache_;
  mojo::SurfacePtr surface_;
  base::WeakPtrFactory<TextureUploaderTest> weak_factory_;

 private:
  DISALLOW_COPY_AND_ASSIGN(TextureUploaderTest);
};

TEST_F(TextureUploaderTest, Base) {
  mojo::Size size;
  size.width = 100;
  size.height = 100;
  scoped_ptr<mojo::TextureCache::TextureInfo> texture_info(
      texture_cache_->GetTexture(size).Pass());
  mojo::FramePtr frame = mojo::TextureUploader::GetUploadFrame(
      gl_context_, texture_info->ResourceId(), texture_info->Texture());
  EXPECT_FALSE(frame.is_null());
}

}  // namespace
