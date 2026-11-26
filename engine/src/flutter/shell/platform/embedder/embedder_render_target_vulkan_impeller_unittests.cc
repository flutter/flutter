// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/embedder_render_target_vulkan_impeller.h"

#include "flutter/shell/platform/embedder/embedder_render_target_cache.h"
#include "flutter/testing/testing.h"
#include "flutter/vulkan/procs/vulkan_proc_table.h"
#include "flutter/vulkan/swiftshader_path.h"
#include "impeller/display_list/aiks_context.h"
#include "impeller/entity/vk/entity_shaders_vk.h"
#include "impeller/entity/vk/framebuffer_blend_shaders_vk.h"
#include "impeller/entity/vk/modern_shaders_vk.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/texture_vk.h"

namespace flutter::testing {
namespace {

class VulkanImpellerRenderTargetTest : public ::testing::Test {
 protected:
  void SetUp() override {
    impeller::ContextVK::Settings settings;
    vk_ = fml::MakeRefCounted<vulkan::VulkanProcTable>(VULKAN_SO_PATH);
    ASSERT_TRUE(vk_->HasAcquiredMandatoryProcAddresses());
    settings.proc_address_callback = vk_->NativeGetInstanceProcAddr();
    settings.shader_libraries_data = {
        std::make_shared<fml::NonOwnedMapping>(
            impeller_entity_shaders_vk_data, impeller_entity_shaders_vk_length),
        std::make_shared<fml::NonOwnedMapping>(
            impeller_modern_shaders_vk_data, impeller_modern_shaders_vk_length),
        std::make_shared<fml::NonOwnedMapping>(
            impeller_framebuffer_blend_shaders_vk_data,
            impeller_framebuffer_blend_shaders_vk_length),
    };
    context_ = impeller::ContextVK::Create(std::move(settings));
    ASSERT_NE(context_, nullptr);
    aiks_context_ = std::make_shared<impeller::AiksContext>(context_, nullptr);
    ASSERT_TRUE(aiks_context_->IsValid());
    impeller::TextureDescriptor desc;
    desc.size = {64, 32};
    desc.format = impeller::PixelFormat::kR8G8B8A8UNormInt;
    desc.storage_mode = impeller::StorageMode::kDevicePrivate;
    desc.usage = impeller::TextureUsage::kRenderTarget;
    image_texture_ = context_->GetResourceAllocator()->CreateTexture(desc);
    ASSERT_NE(image_texture_, nullptr);
    image_ = {sizeof(FlutterVulkanImage),
              reinterpret_cast<uint64_t>(static_cast<VkImage>(
                  impeller::TextureVK::Cast(*image_texture_).GetImage())),
              VK_FORMAT_R8G8B8A8_UNORM};
    store_.struct_size = sizeof(store_);
    store_.type = kFlutterBackingStoreTypeVulkan;
    store_.vulkan.struct_size = sizeof(store_.vulkan);
    store_.vulkan.image = &image_;
    store_.vulkan.user_data = this;
    store_.vulkan.destruction_callback = [](void* user_data) {
      auto& fixture = *static_cast<VulkanImpellerRenderTargetTest*>(user_data);
      fixture.events_.push_back("destroy");
      fixture.image_texture_.reset();
    };
    config_.struct_size = sizeof(config_);
    config_.size = {64, 32};
  }

  std::unique_ptr<EmbedderRenderTarget> CreateTarget() {
    return CreateVulkanImpellerRenderTarget(
        store_, config_, aiks_context_,
        fml::ScopedCleanupClosure([this] { events_.push_back("collect"); }));
  }

  void ExpectReleased() {
    EXPECT_EQ(events_, (std::vector<std::string>{"destroy", "collect"}));
    EXPECT_EQ(image_texture_, nullptr);
  }

  fml::RefPtr<vulkan::VulkanProcTable> vk_;
  std::shared_ptr<impeller::ContextVK> context_;
  std::shared_ptr<impeller::AiksContext> aiks_context_;
  std::shared_ptr<impeller::Texture> image_texture_;
  FlutterVulkanImage image_ = {};
  FlutterBackingStore store_ = {};
  FlutterBackingStoreConfig config_ = {};
  std::vector<std::string> events_;
};

TEST_F(VulkanImpellerRenderTargetTest, ReleasesExactlyOnceAfterUse) {
  auto target = CreateTarget();
  ASSERT_NE(target, nullptr);
  EXPECT_TRUE(target->GetImpellerRenderTarget()->IsValid());
  EXPECT_EQ(target->GetRenderTargetSize(), DlISize(64, 32));
  EXPECT_TRUE(events_.empty());
  target.reset();
  ExpectReleased();
}

TEST_F(VulkanImpellerRenderTargetTest, RetainsContextUntilTargetIsReleased) {
  auto target = CreateTarget();
  ASSERT_NE(target, nullptr);
  std::weak_ptr<impeller::ContextVK> weak_context = context_;
  aiks_context_.reset();
  context_.reset();
  EXPECT_FALSE(weak_context.expired());
  EXPECT_TRUE(events_.empty());
  target.reset();
  ExpectReleased();
  EXPECT_TRUE(weak_context.expired());
}

TEST_F(VulkanImpellerRenderTargetTest, AllowsNullDestructionCallback) {
  store_.vulkan.destruction_callback = nullptr;
  auto target = CreateTarget();
  ASSERT_NE(target, nullptr);
  target.reset();
  EXPECT_EQ(events_, (std::vector<std::string>{"collect"}));
}

TEST_F(VulkanImpellerRenderTargetTest, ReleasesOnMissingContext) {
  aiks_context_.reset();
  EXPECT_EQ(CreateTarget(), nullptr);
  ExpectReleased();
}

TEST_F(VulkanImpellerRenderTargetTest, ReleasesOnMissingRendererContext) {
  aiks_context_ = std::make_shared<impeller::AiksContext>(nullptr, nullptr);
  EXPECT_EQ(CreateTarget(), nullptr);
  ExpectReleased();
}

TEST_F(VulkanImpellerRenderTargetTest, CacheReusesAttachmentsAcrossFrames) {
  EmbedderRenderTargetCache cache;
  auto target = CreateTarget();
  ASSERT_NE(target, nullptr);
  const auto& render_target = *target->GetImpellerRenderTarget();
  auto msaa = render_target.GetColorAttachment(0).texture;
  ASSERT_NE(msaa, nullptr);
  ASSERT_TRUE(render_target.GetStencilAttachment().has_value());
  auto stencil = render_target.GetStencilAttachment()->texture;
  ASSERT_NE(stencil, nullptr);
  cache.CacheRenderTarget(std::move(target));
  for (int frame = 0; frame < 60; frame++) {
    target = cache.GetRenderTarget(
        EmbedderExternalView::RenderTargetDescriptor{DlISize(64, 32)});
    ASSERT_NE(target, nullptr);
    EXPECT_EQ(target->GetImpellerRenderTarget()->GetColorAttachment(0).texture,
              msaa);
    EXPECT_EQ(
        target->GetImpellerRenderTarget()->GetStencilAttachment()->texture,
        stencil);
    cache.CacheRenderTarget(std::move(target));
  }
  RecordProperty("cache_round_trips", 60);
  RecordProperty("distinct_msaa_attachments", 1);
  RecordProperty("distinct_stencil_attachments", 1);
  EXPECT_TRUE(events_.empty());
  // Cache eviction releases the backing store, even with attachment references
  // retained by a previously submitted frame.
  cache.ClearAllRenderTargetsInCache().clear();
  ExpectReleased();
}

TEST_F(VulkanImpellerRenderTargetTest, CacheShutdownReleasesBackingStore) {
  {
    EmbedderRenderTargetCache cache;
    auto target = CreateTarget();
    ASSERT_NE(target, nullptr);
    cache.CacheRenderTarget(std::move(target));
    EXPECT_TRUE(events_.empty());
  }
  ExpectReleased();
}

TEST_F(VulkanImpellerRenderTargetTest, ReleasesOnMissingImage) {
  store_.vulkan.image = nullptr;
  EXPECT_EQ(CreateTarget(), nullptr);
  ExpectReleased();
}

TEST_F(VulkanImpellerRenderTargetTest, ReleasesOnNullImageHandle) {
  image_.image = 0;
  EXPECT_EQ(CreateTarget(), nullptr);
  ExpectReleased();
}

TEST_F(VulkanImpellerRenderTargetTest, ReleasesOnUnsupportedFormat) {
  image_.format = VK_FORMAT_UNDEFINED;
  EXPECT_EQ(CreateTarget(), nullptr);
  ExpectReleased();
}

}  // namespace
}  // namespace flutter::testing
