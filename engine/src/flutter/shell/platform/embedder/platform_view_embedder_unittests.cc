// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/platform_view_embedder.h"

#include "flutter/shell/common/thread_host.h"
#include "flutter/testing/testing.h"

#include "gmock/gmock.h"
#include "gtest/gtest.h"

#include <cstring>

namespace flutter {
namespace testing {
namespace {
class MockDelegate : public PlatformView::Delegate {
  MOCK_METHOD1(OnPlatformViewCreated, void(std::unique_ptr<Surface>));
  MOCK_METHOD0(OnPlatformViewDestroyed, void());
  MOCK_METHOD0(OnPlatformViewScheduleFrame, void());
  MOCK_METHOD1(OnPlatformViewSetNextFrameCallback,
               void(const fml::closure& closure));
  MOCK_METHOD2(OnPlatformViewSetViewportMetrics,
               void(int64_t view_id, const ViewportMetrics& metrics));
  MOCK_METHOD1(OnPlatformViewDispatchPlatformMessage,
               void(std::unique_ptr<PlatformMessage> message));
  MOCK_METHOD1(OnPlatformViewDispatchPointerDataPacket,
               void(std::unique_ptr<PointerDataPacket> packet));
  MOCK_METHOD3(OnPlatformViewDispatchSemanticsAction,
               void(int32_t id,
                    SemanticsAction action,
                    fml::MallocMapping args));
  MOCK_METHOD1(OnPlatformViewSetSemanticsEnabled, void(bool enabled));
  MOCK_METHOD1(OnPlatformViewSetAccessibilityFeatures, void(int32_t flags));
  MOCK_METHOD1(OnPlatformViewRegisterTexture,
               void(std::shared_ptr<Texture> texture));
  MOCK_METHOD1(OnPlatformViewUnregisterTexture, void(int64_t texture_id));
  MOCK_METHOD1(OnPlatformViewMarkTextureFrameAvailable,
               void(int64_t texture_id));
  MOCK_METHOD3(LoadDartDeferredLibrary,
               void(intptr_t loading_unit_id,
                    std::unique_ptr<const fml::Mapping> snapshot_data,
                    std::unique_ptr<const fml::Mapping> snapshot_instructions));
  MOCK_METHOD3(LoadDartDeferredLibraryError,
               void(intptr_t loading_unit_id,
                    const std::string error_message,
                    bool transient));
  MOCK_METHOD2(UpdateAssetResolverByType,
               void(std::unique_ptr<AssetResolver> updated_asset_resolver,
                    AssetResolver::AssetResolverType type));
  MOCK_CONST_METHOD0(OnPlatformViewGetSettings, const Settings&());
};

class MockResponse : public PlatformMessageResponse {
 public:
  MOCK_METHOD1(Complete, void(std::unique_ptr<fml::Mapping> data));
  MOCK_METHOD0(CompleteEmpty, void());
};
}  // namespace

TEST(PlatformViewEmbedderTest, HasPlatformMessageHandler) {
  ThreadHost thread_host("io.flutter.test." + GetCurrentTestName() + ".",
                         ThreadHost::Type::Platform);
  flutter::TaskRunners task_runners = flutter::TaskRunners(
      "HasPlatformMessageHandler", thread_host.platform_thread->GetTaskRunner(),
      nullptr, nullptr, nullptr);
  fml::AutoResetWaitableEvent latch;
  task_runners.GetPlatformTaskRunner()->PostTask([&latch, task_runners] {
    MockDelegate delegate;
    EmbedderSurfaceSoftware::SoftwareDispatchTable software_dispatch_table;
    PlatformViewEmbedder::PlatformDispatchTable platform_dispatch_table;
    std::shared_ptr<EmbedderExternalViewEmbedder> external_view_embedder;
    auto embedder = std::make_unique<PlatformViewEmbedder>(
        delegate, task_runners, software_dispatch_table,
        platform_dispatch_table, external_view_embedder);

    ASSERT_TRUE(embedder->GetPlatformMessageHandler());
    latch.Signal();
  });
  latch.Wait();
}

TEST(PlatformViewEmbedderTest, Dispatches) {
  ThreadHost thread_host("io.flutter.test." + GetCurrentTestName() + ".",
                         ThreadHost::Type::Platform);
  flutter::TaskRunners task_runners = flutter::TaskRunners(
      "HasPlatformMessageHandler", thread_host.platform_thread->GetTaskRunner(),
      nullptr, nullptr, nullptr);
  bool did_call = false;
  std::unique_ptr<PlatformViewEmbedder> embedder;
  {
    fml::AutoResetWaitableEvent latch;
    task_runners.GetPlatformTaskRunner()->PostTask([&latch, task_runners,
                                                    &did_call, &embedder] {
      MockDelegate delegate;
      EmbedderSurfaceSoftware::SoftwareDispatchTable software_dispatch_table;
      PlatformViewEmbedder::PlatformDispatchTable platform_dispatch_table;
      platform_dispatch_table.platform_message_response_callback =
          [&did_call](std::unique_ptr<PlatformMessage> message) {
            did_call = true;
          };
      std::shared_ptr<EmbedderExternalViewEmbedder> external_view_embedder;
      embedder = std::make_unique<PlatformViewEmbedder>(
          delegate, task_runners, software_dispatch_table,
          platform_dispatch_table, external_view_embedder);
      auto platform_message_handler = embedder->GetPlatformMessageHandler();
      fml::RefPtr<PlatformMessageResponse> response =
          fml::MakeRefCounted<MockResponse>();
      std::unique_ptr<PlatformMessage> message =
          std::make_unique<PlatformMessage>("foo", response);
      platform_message_handler->HandlePlatformMessage(std::move(message));
      latch.Signal();
    });
    latch.Wait();
  }
  {
    fml::AutoResetWaitableEvent latch;
    thread_host.platform_thread->GetTaskRunner()->PostTask([&latch, &embedder] {
      embedder.reset();
      latch.Signal();
    });
    latch.Wait();
  }

  EXPECT_TRUE(did_call);
}

TEST(PlatformViewEmbedderTest, DeletionDisabledDispatch) {
  ThreadHost thread_host("io.flutter.test." + GetCurrentTestName() + ".",
                         ThreadHost::Type::Platform);
  flutter::TaskRunners task_runners = flutter::TaskRunners(
      "HasPlatformMessageHandler", thread_host.platform_thread->GetTaskRunner(),
      nullptr, nullptr, nullptr);
  bool did_call = false;
  {
    fml::AutoResetWaitableEvent latch;
    task_runners.GetPlatformTaskRunner()->PostTask([&latch, task_runners,
                                                    &did_call] {
      MockDelegate delegate;
      EmbedderSurfaceSoftware::SoftwareDispatchTable software_dispatch_table;
      PlatformViewEmbedder::PlatformDispatchTable platform_dispatch_table;
      platform_dispatch_table.platform_message_response_callback =
          [&did_call](std::unique_ptr<PlatformMessage> message) {
            did_call = true;
          };
      std::shared_ptr<EmbedderExternalViewEmbedder> external_view_embedder;
      auto embedder = std::make_unique<PlatformViewEmbedder>(
          delegate, task_runners, software_dispatch_table,
          platform_dispatch_table, external_view_embedder);
      auto platform_message_handler = embedder->GetPlatformMessageHandler();
      fml::RefPtr<PlatformMessageResponse> response =
          fml::MakeRefCounted<MockResponse>();
      std::unique_ptr<PlatformMessage> message =
          std::make_unique<PlatformMessage>("foo", response);
      platform_message_handler->HandlePlatformMessage(std::move(message));
      embedder.reset();
      latch.Signal();
    });
    latch.Wait();
  }
  {
    fml::AutoResetWaitableEvent latch;
    thread_host.platform_thread->GetTaskRunner()->PostTask(
        [&latch] { latch.Signal(); });
    latch.Wait();
  }

  EXPECT_FALSE(did_call);
}

}  // namespace testing
}  // namespace flutter
