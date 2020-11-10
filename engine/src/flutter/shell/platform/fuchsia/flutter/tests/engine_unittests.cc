// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <fuchsia/scenic/scheduling/cpp/fidl.h>
#include <fuchsia/ui/policy/cpp/fidl.h>
#include <fuchsia/ui/scenic/cpp/fidl.h>
#include <lib/async-loop/default.h>
#include <lib/sys/cpp/component_context.h>

#include "assets/directory_asset_bundle.h"
#include "flutter/common/graphics/persistent_cache.h"
#include "flutter/fml/memory/ref_ptr.h"
#include "flutter/fml/message_loop_impl.h"
#include "flutter/fml/task_runner.h"
#include "flutter/shell/common/serialization_callbacks.h"
#include "flutter/shell/platform/fuchsia/flutter/logging.h"
#include "flutter/shell/platform/fuchsia/flutter/runner.h"
#include "flutter/shell/platform/fuchsia/flutter/session_connection.h"
#include "gtest/gtest.h"
#include "include/core/SkPicture.h"
#include "include/core/SkPictureRecorder.h"
#include "include/core/SkSerialProcs.h"

using namespace flutter_runner;
using namespace flutter;

namespace flutter_runner {
namespace testing {

class MockTaskRunner : public fml::BasicTaskRunner {
 public:
  MockTaskRunner() {}
  virtual ~MockTaskRunner() {}

  void PostTask(const fml::closure& task) override {
    task_count_++;
    task();
  }

  int GetTaskCount() { return task_count_; }

 private:
  int task_count_ = 0;
};

class EngineTest : public ::testing::Test {
 public:
  void WarmupSkps() {
    // Have to create a message loop so default async dispatcher gets set,
    // otherwise we segfault creating the VulkanSurfaceProducer
    auto loop = fml::MessageLoopImpl::Create();

    fuchsia::ui::scenic::SessionPtr session_ptr;
    scenic::Session session(std::move(session_ptr));
    VulkanSurfaceProducer surface_producer(&session);

    Engine::WarmupSkps(&concurrent_task_runner_, &raster_task_runner_,
                       surface_producer);
  }

 protected:
  MockTaskRunner concurrent_task_runner_;
  MockTaskRunner raster_task_runner_;
};

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

  bool success = fml::WriteAtomically(asset_dir_fd, "test.skp", mapping);
  ASSERT_TRUE(success);

  auto asset_manager = std::make_shared<AssetManager>();
  asset_manager->PushBack(
      std::make_unique<DirectoryAssetBundle>(std::move(asset_dir_fd), false));

  PersistentCache::GetCacheForProcess()->SetAssetManager(asset_manager);

  WarmupSkps();

  EXPECT_EQ(concurrent_task_runner_.GetTaskCount(), 1);
  EXPECT_EQ(raster_task_runner_.GetTaskCount(), 1);
}

}  // namespace testing
}  // namespace flutter_runner
