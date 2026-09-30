// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/image_generator_registry.h"

#include <thread>
#include <vector>

#include "flutter/fml/concurrent_message_loop.h"
#include "flutter/fml/mapping.h"
#include "flutter/lib/ui/painting/image_generator_registry_test.h"
#include "flutter/shell/common/shell_test.h"
#include "flutter/testing/post_task_sync.h"
#include "flutter/testing/testing.h"

#include "third_party/skia/include/codec/SkCodecAnimation.h"

namespace flutter {
namespace testing {

static sk_sp<SkData> LoadValidImageFixture() {
  auto fixture_mapping = OpenFixtureAsMapping("DashInNooglerHat.jpg");

  // Remap to sk_sp<SkData>.
  SkData::ReleaseProc on_release = [](const void* ptr, void* context) -> void {
    delete reinterpret_cast<fml::FileMapping*>(context);
  };
  auto data = SkData::MakeWithProc(fixture_mapping->GetMapping(),
                                   fixture_mapping->GetSize(), on_release,
                                   fixture_mapping.get());

  if (data) {
    fixture_mapping.release();
  }

  return data;
}

TEST_F(ShellTest, CreateCompatibleReturnsBuiltinImageGeneratorForValidImage) {
  auto data = LoadValidImageFixture();

  // Fetch the generator and query for basic info
  auto result = CreateTestImageGenerator(data);
  auto info = result->GetInfo();
  ASSERT_EQ(info.width(), 3024);
  ASSERT_EQ(info.height(), 4032);
}

TEST_F(ShellTest, CreateCompatibleReturnsNullptrForInvalidImage) {
  auto result = CreateTestImageGenerator(SkData::MakeEmpty());
  ASSERT_EQ(result, nullptr);
}

class FakeImageGenerator : public ImageGenerator {
 public:
  explicit FakeImageGenerator(int identifiableFakeWidth)
      : info_(SkImageInfo::Make(identifiableFakeWidth,
                                identifiableFakeWidth,
                                SkColorType::kRGBA_8888_SkColorType,
                                SkAlphaType::kOpaque_SkAlphaType)) {};
  ~FakeImageGenerator() = default;
  const SkImageInfo& GetInfo() { return info_; }

  unsigned int GetFrameCount() const { return 1; }

  unsigned int GetPlayCount() const { return 1; }

  const ImageGenerator::FrameInfo GetFrameInfo(unsigned int frame_index) {
    return {std::nullopt, 0, SkCodecAnimation::DisposalMethod::kKeep};
  }

  SkISize GetScaledDimensions(float scale) {
    return SkISize::Make(info_.width(), info_.height());
  }

  bool GetPixels(const SkImageInfo& info,
                 void* pixels,
                 size_t row_bytes,
                 unsigned int frame_index,
                 std::optional<unsigned int> prior_frame) {
    return false;
  };

 private:
  SkImageInfo info_;
};

TEST_F(ShellTest, PositivePriorityTakesPrecedentOverDefaultGenerators) {
  const int fake_width = 1337;
  auto result = CreateTestImageGenerator(
      LoadValidImageFixture(), [&](ImageGeneratorRegistry& registry) {
        registry.AddFactory(
            [fake_width](const sk_sp<SkData>& buffer) {
              return std::make_unique<FakeImageGenerator>(fake_width);
            },
            1);
      });
  ASSERT_TRUE(result);
  ASSERT_EQ(result->GetInfo().width(), fake_width);
}

TEST_F(ShellTest, DefaultGeneratorsTakePrecedentOverNegativePriority) {
  auto result = CreateTestImageGenerator(
      LoadValidImageFixture(), [](ImageGeneratorRegistry& registry) {
        registry.AddFactory(
            [](const sk_sp<SkData>& buffer) {
              return std::make_unique<FakeImageGenerator>(1337);
            },
            -1);
      });
  ASSERT_TRUE(result);
  ASSERT_EQ(result->GetInfo().width(), 3024);
}

TEST_F(ShellTest, DefaultGeneratorsTakePrecedentOverZeroPriority) {
  auto result = CreateTestImageGenerator(
      LoadValidImageFixture(), [](ImageGeneratorRegistry& registry) {
        registry.AddFactory(
            [](const sk_sp<SkData>& buffer) {
              return std::make_unique<FakeImageGenerator>(1337);
            },
            0);
      });
  ASSERT_TRUE(result);
  ASSERT_EQ(result->GetInfo().width(), 3024);
}

TEST_F(ShellTest, ImageGeneratorsWithSamePriorityCascadeChronologically) {
  auto result = CreateTestImageGenerator(
      SkData::MakeEmpty(), [](ImageGeneratorRegistry& registry) {
        registry.AddFactory(
            [](const sk_sp<SkData>& buffer) {
              return std::make_unique<FakeImageGenerator>(1337);
            },
            5);
        registry.AddFactory(
            [](const sk_sp<SkData>& buffer) {
              return std::make_unique<FakeImageGenerator>(7777);
            },
            5);
      });
  ASSERT_TRUE(result);
  ASSERT_EQ(result->GetInfo().width(), 1337);
}

TEST_F(ShellTest, AsyncResolutionPreservesOrderAcrossTaskRunners) {
  auto ui_task_runner = CreateNewThread("ui");
  auto concurrent_loop = fml::ConcurrentMessageLoop::Create(1u);
  fml::AutoResetWaitableEvent latch;
  std::thread::id ui_thread;
  std::vector<std::thread::id> factory_threads;
  std::thread::id result_callback_thread;
  bool callback_called = false;

  PostTaskSync(ui_task_runner, [&]() {
    ImageGeneratorRegistry registry;
    ui_thread = std::this_thread::get_id();

    // Alternate between the UI and concurrent task runners. The first
    // concurrent factory rejects the data; the second accepts it and stops the
    // search before the final factory.
    registry.AddFactory(
        [&](const sk_sp<SkData>&) {
          factory_threads.push_back(std::this_thread::get_id());
          return nullptr;
        },
        100);
    registry.AddFactory(
        [&](const sk_sp<SkData>&) {
          factory_threads.push_back(std::this_thread::get_id());
          return nullptr;
        },
        99, ImageGeneratorFactoryExecution::kConcurrentTaskRunner);
    registry.AddFactory(
        [&](const sk_sp<SkData>&) {
          factory_threads.push_back(std::this_thread::get_id());
          return nullptr;
        },
        98);
    registry.AddFactory(
        [&](const sk_sp<SkData>&) {
          factory_threads.push_back(std::this_thread::get_id());
          return std::make_unique<FakeImageGenerator>(7331);
        },
        97, ImageGeneratorFactoryExecution::kConcurrentTaskRunner);
    registry.AddFactory(
        [&](const sk_sp<SkData>&) {
          factory_threads.push_back(std::this_thread::get_id());
          return std::make_unique<FakeImageGenerator>(1337);
        },
        96);

    registry.CreateCompatibleGenerator(
        SkData::MakeEmpty(), concurrent_loop->GetTaskRunner(), ui_task_runner,
        [&](const std::shared_ptr<ImageGenerator>& result) {
          callback_called = true;
          result_callback_thread = std::this_thread::get_id();
          if (result) {
            EXPECT_EQ(result->GetInfo().width(), 7331);
          } else {
            ADD_FAILURE() << "Expected an image generator";
          }
          latch.Signal();
        });

    EXPECT_FALSE(callback_called);
    // Destroy the registry while resolution is still pending.
  });
  latch.Wait();

  EXPECT_TRUE(callback_called);
  ASSERT_EQ(factory_threads.size(), 4u);
  EXPECT_EQ(factory_threads[0], ui_thread);
  EXPECT_NE(factory_threads[1], ui_thread);
  EXPECT_EQ(factory_threads[2], ui_thread);
  EXPECT_NE(factory_threads[3], ui_thread);
  EXPECT_EQ(result_callback_thread, ui_thread);
}

}  // namespace testing
}  // namespace flutter
