// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <fuchsia/ui/scenic/cpp/fidl.h>
#include <lib/async-loop/default.h>
#include <lib/sys/cpp/component_context.h>

#include "flutter/assets/directory_asset_bundle.h"
#include "flutter/common/graphics/persistent_cache.h"
#include "flutter/fml/memory/ref_ptr.h"
#include "flutter/fml/message_loop_impl.h"
#include "flutter/fml/task_runner.h"
#include "flutter/shell/common/serialization_callbacks.h"
#include "flutter/shell/common/thread_host.h"
#include "third_party/skia/include/core/SkPicture.h"
#include "third_party/skia/include/core/SkPictureRecorder.h"
#include "third_party/skia/include/core/SkSerialProcs.h"

#include "flutter/shell/platform/fuchsia/flutter/logging.h"
#include "flutter/shell/platform/fuchsia/flutter/runner.h"
#include "flutter/shell/platform/fuchsia/flutter/vulkan_surface_producer.h"

#include "gtest/gtest.h"

using namespace flutter;

namespace flutter_runner {
namespace testing {
namespace {

std::string GetCurrentTestName() {
  return ::testing::UnitTest::GetInstance()->current_test_info()->name();
}

}  // namespace

class MockTaskRunner : public fml::BasicTaskRunner {
 public:
  MockTaskRunner() {}
  virtual ~MockTaskRunner() {}

  void PostTask(const fml::closure& task) override {
    outstanding_tasks_.push(task);
  }

  int GetTaskCount() { return task_count_; }

  void Run() {
    while (!outstanding_tasks_.empty()) {
      outstanding_tasks_.front()();
      outstanding_tasks_.pop();
      task_count_++;
    }
  }

 private:
  int task_count_ = 0;
  std::queue<const fml::closure> outstanding_tasks_;
};

class EngineTest : public ::testing::Test {
 public:
  void WarmupSkps(
      uint64_t width,
      uint64_t height,
      std::shared_ptr<flutter::AssetManager> asset_manager,
      std::optional<const std::vector<std::string>> skp_names,
      std::optional<std::function<void(uint32_t)>> completion_callback,
      bool synchronous = true) {
    // Have to create a message loop so default async dispatcher gets set,
    // otherwise we segfault creating the VulkanSurfaceProducer
    loop_ = fml::MessageLoopImpl::Create();

    context_ = sys::ComponentContext::CreateAndServeOutgoingDirectory();
    scenic_ = context_->svc()->Connect<fuchsia::ui::scenic::Scenic>();
    session_.emplace(scenic_.get());
    surface_producer_ =
        std::make_shared<VulkanSurfaceProducer>(&session_.value());

    Engine::WarmupSkps(&concurrent_task_runner_, &raster_task_runner_,
                       surface_producer_, SkISize::Make(width, height),
                       asset_manager, skp_names, completion_callback,
                       synchronous);
  }

 protected:
  fml::RefPtr<fml::MessageLoopImpl> loop_;
  MockTaskRunner concurrent_task_runner_;
  MockTaskRunner raster_task_runner_;
  std::shared_ptr<VulkanSurfaceProducer> surface_producer_;

  std::unique_ptr<sys::ComponentContext> context_;
  fuchsia::ui::scenic::ScenicPtr scenic_;
  std::optional<scenic::Session> session_;
};

TEST_F(EngineTest, ThreadNames) {
  std::string prefix = GetCurrentTestName();
  flutter::ThreadHost engine_thread_host = Engine::CreateThreadHost(prefix);

  char thread_name[ZX_MAX_NAME_LEN];
  zx::thread::self()->get_property(ZX_PROP_NAME, thread_name,
                                   sizeof(thread_name));
  EXPECT_EQ(std::string(thread_name), prefix + std::string(".platform"));
  EXPECT_EQ(engine_thread_host.platform_thread, nullptr);

  engine_thread_host.raster_thread->GetTaskRunner()->PostTask([&prefix]() {
    char thread_name[ZX_MAX_NAME_LEN];
    zx::thread::self()->get_property(ZX_PROP_NAME, thread_name,
                                     sizeof(thread_name));
    EXPECT_EQ(std::string(thread_name), prefix + std::string(".raster"));
  });
  engine_thread_host.raster_thread->Join();

  engine_thread_host.ui_thread->GetTaskRunner()->PostTask([&prefix]() {
    char thread_name[ZX_MAX_NAME_LEN];
    zx::thread::self()->get_property(ZX_PROP_NAME, thread_name,
                                     sizeof(thread_name));
    EXPECT_EQ(std::string(thread_name), prefix + std::string(".ui"));
  });
  engine_thread_host.ui_thread->Join();

  engine_thread_host.io_thread->GetTaskRunner()->PostTask([&prefix]() {
    char thread_name[ZX_MAX_NAME_LEN];
    zx::thread::self()->get_property(ZX_PROP_NAME, thread_name,
                                     sizeof(thread_name));
    EXPECT_EQ(std::string(thread_name), prefix + std::string(".io"));
  });
  engine_thread_host.io_thread->Join();
}

TEST_F(EngineTest, SkpWarmup) {
  SkISize draw_size = SkISize::Make(100, 100);
  SkPictureRecorder recorder;
  auto canvas = recorder.beginRecording(draw_size.width(), draw_size.height());

  // adapted from https://fiddle.skia.org/c/@Canvas_drawLine
  SkPaint paint;
  paint.setColor(0xFF9a67be);
  paint.setStrokeWidth(20);
  canvas->drawLine(0, 0, draw_size.width(), draw_size.height(), paint);
  canvas->drawLine(0, draw_size.height(), draw_size.width(), 0, paint);

  sk_sp<SkPicture> picture = recorder.finishRecordingAsPicture();
  SkSerialProcs procs = {0};
  procs.fImageProc = SerializeImageWithoutData;
  procs.fTypefaceProc = SerializeTypefaceWithoutData;
  sk_sp<SkData> data = picture->serialize(&procs);
  ASSERT_TRUE(data);
  ASSERT_GT(data->size(), 0u);

  fml::NonOwnedMapping mapping(data->bytes(), data->size());

  fml::ScopedTemporaryDirectory asset_dir;
  fml::UniqueFD asset_dir_fd = fml::OpenDirectory(
      asset_dir.path().c_str(), false, fml::FilePermission::kRead);
  fml::UniqueFD subdir_fd = fml::OpenDirectory(asset_dir_fd, "shaders", true,
                                               fml::FilePermission::kReadWrite);

  bool success = fml::WriteAtomically(subdir_fd, "test.skp", mapping);
  ASSERT_TRUE(success);

  auto asset_manager = std::make_shared<AssetManager>();
  asset_manager->PushBack(
      std::make_unique<DirectoryAssetBundle>(std::move(asset_dir_fd), false));

  WarmupSkps(draw_size.width(), draw_size.height(), asset_manager, std::nullopt,
             [](uint32_t count) { EXPECT_EQ(1u, count); });
  concurrent_task_runner_.Run();
  raster_task_runner_.Run();

  EXPECT_EQ(concurrent_task_runner_.GetTaskCount(), 1);
  EXPECT_EQ(raster_task_runner_.GetTaskCount(), 1);
}

TEST_F(EngineTest, SkpWarmupAsync) {
  SkISize draw_size = SkISize::Make(100, 100);
  SkPictureRecorder recorder;
  auto canvas = recorder.beginRecording(draw_size.width(), draw_size.height());

  // adapted from https://fiddle.skia.org/c/@Canvas_drawLine
  SkPaint paint;
  paint.setColor(0xFF9a67be);
  paint.setStrokeWidth(20);
  canvas->drawLine(0, 0, draw_size.width(), draw_size.height(), paint);
  canvas->drawLine(0, draw_size.height(), draw_size.width(), 0, paint);

  sk_sp<SkPicture> picture = recorder.finishRecordingAsPicture();
  SkSerialProcs procs = {0};
  procs.fImageProc = SerializeImageWithoutData;
  procs.fTypefaceProc = SerializeTypefaceWithoutData;
  sk_sp<SkData> data = picture->serialize(&procs);
  ASSERT_TRUE(data);
  ASSERT_GT(data->size(), 0u);

  fml::NonOwnedMapping mapping(data->bytes(), data->size());

  fml::ScopedTemporaryDirectory asset_dir;
  fml::UniqueFD asset_dir_fd = fml::OpenDirectory(
      asset_dir.path().c_str(), false, fml::FilePermission::kRead);
  std::string subdir_name = "shaders";
  fml::UniqueFD subdir_fd = fml::OpenDirectory(
      asset_dir_fd, subdir_name.c_str(), true, fml::FilePermission::kReadWrite);
  std::string skp_name = "test.skp";

  bool success = fml::WriteAtomically(subdir_fd, skp_name.c_str(), mapping);
  ASSERT_TRUE(success);

  auto asset_manager = std::make_shared<AssetManager>();
  asset_manager->PushBack(
      std::make_unique<DirectoryAssetBundle>(std::move(asset_dir_fd), false));

  std::vector<std::string> skp_names = {subdir_name + "/" + skp_name};

  WarmupSkps(draw_size.width(), draw_size.height(), asset_manager, skp_names,
             [](uint32_t count) { EXPECT_EQ(1u, count); });
  concurrent_task_runner_.Run();
  raster_task_runner_.Run();

  EXPECT_EQ(concurrent_task_runner_.GetTaskCount(), 1);
  EXPECT_EQ(raster_task_runner_.GetTaskCount(), 1);
}

}  // namespace testing
}  // namespace flutter_runner
