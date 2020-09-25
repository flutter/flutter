// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_EMBEDDER_TESTS_EMBEDDER_UNITTESTS_UTIL_H_
#define FLUTTER_SHELL_PLATFORM_EMBEDDER_TESTS_EMBEDDER_UNITTESTS_UTIL_H_

#define FML_USED_ON_EMBEDDER

#include <future>

#include "embedder.h"
#include "flutter/fml/mapping.h"
#include "flutter/fml/message_loop.h"
#include "flutter/fml/paths.h"
#include "flutter/shell/platform/embedder/tests/embedder_assertions.h"
#include "flutter/shell/platform/embedder/tests/embedder_config_builder.h"
#include "flutter/shell/platform/embedder/tests/embedder_test.h"
#include "third_party/skia/include/core/SkSurface.h"

namespace flutter {
namespace testing {

sk_sp<SkSurface> CreateRenderSurface(const FlutterLayer& layer,
                                     GrDirectContext* context);

bool RasterImagesAreSame(sk_sp<SkImage> a, sk_sp<SkImage> b);

bool WriteImageToDisk(const fml::UniqueFD& directory,
                      const std::string& name,
                      sk_sp<SkImage> image);

bool ImageMatchesFixture(const std::string& fixture_file_name,
                         sk_sp<SkImage> scene_image);

bool ImageMatchesFixture(const std::string& fixture_file_name,
                         std::future<sk_sp<SkImage>>& scene_image);

void FilterMutationsByType(
    const FlutterPlatformViewMutation** mutations,
    size_t count,
    FlutterPlatformViewMutationType type,
    std::function<void(const FlutterPlatformViewMutation& mutation)> handler);

void FilterMutationsByType(
    const FlutterPlatformView* view,
    FlutterPlatformViewMutationType type,
    std::function<void(const FlutterPlatformViewMutation& mutation)> handler);

SkMatrix GetTotalMutationTransformationMatrix(
    const FlutterPlatformViewMutation** mutations,
    size_t count);

SkMatrix GetTotalMutationTransformationMatrix(const FlutterPlatformView* view);

//------------------------------------------------------------------------------
/// @brief      A task runner that we expect the embedder to provide but whose
///             implementation is a real FML task runner.
///
class EmbedderTestTaskRunner {
 public:
  using TaskExpiryCallback = std::function<void(FlutterTask)>;
  EmbedderTestTaskRunner(fml::RefPtr<fml::TaskRunner> real_task_runner,
                         TaskExpiryCallback on_task_expired)
      : identifier_(++sEmbedderTaskRunnerIdentifiers),
        real_task_runner_(real_task_runner),
        on_task_expired_(on_task_expired) {
    FML_CHECK(real_task_runner_);
    FML_CHECK(on_task_expired_);

    task_runner_description_.struct_size = sizeof(FlutterTaskRunnerDescription);
    task_runner_description_.user_data = this;
    task_runner_description_.runs_task_on_current_thread_callback =
        [](void* user_data) -> bool {
      return reinterpret_cast<EmbedderTestTaskRunner*>(user_data)
          ->real_task_runner_->RunsTasksOnCurrentThread();
    };
    task_runner_description_.post_task_callback = [](FlutterTask task,
                                                     uint64_t target_time_nanos,
                                                     void* user_data) -> void {
      auto thiz = reinterpret_cast<EmbedderTestTaskRunner*>(user_data);

      auto target_time = fml::TimePoint::FromEpochDelta(
          fml::TimeDelta::FromNanoseconds(target_time_nanos));
      auto on_task_expired = thiz->on_task_expired_;
      auto invoke_task = [task, on_task_expired]() { on_task_expired(task); };
      auto real_task_runner = thiz->real_task_runner_;

      real_task_runner->PostTaskForTime(invoke_task, target_time);
    };
    task_runner_description_.identifier = identifier_;
  }

  const FlutterTaskRunnerDescription& GetFlutterTaskRunnerDescription() {
    return task_runner_description_;
  }

 private:
  static std::atomic_size_t sEmbedderTaskRunnerIdentifiers;
  const size_t identifier_;
  fml::RefPtr<fml::TaskRunner> real_task_runner_;
  TaskExpiryCallback on_task_expired_;
  FlutterTaskRunnerDescription task_runner_description_ = {};

  FML_DISALLOW_COPY_AND_ASSIGN(EmbedderTestTaskRunner);
};

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_EMBEDDER_TESTS_EMBEDDER_UNITTESTS_UTIL_H_
