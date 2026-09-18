// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_TASK_RUNNERS_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_TASK_RUNNERS_H_

#include <memory>
#include <mutex>
#include <string>
#include <utility>
#include <vector>

#include "flutter/fml/macros.h"
#include "flutter/fml/message_loop.h"
#include "flutter/fml/task_runner.h"
#include "flutter/fml/thread.h"
#include "flutter/shell/platform/embedder/embedder.h"

namespace flutter {

// Configures Android platform thread priorities (e.g. kDisplay for UI,
// kRaster for rasterizer, kBackground for IO, kNormal for default).
void AndroidThreadPrioritySetter(FlutterThreadPriority priority);

// Configures Android platform thread name, CPU affinity, and OS thread
// priorities.
void AndroidPlatformThreadConfigSetter(const fml::Thread::ThreadConfig& config);

// Manages thread creation and task runner bridging for the Android Embedder.
//
// Wraps FML task runners into FlutterCustomTaskRunners compatible with the
// public Flutter Embedder C-API.
class AndroidTaskRunners {
 public:
  struct SharedState {
    mutable std::mutex mutex;
    FLUTTER_API_SYMBOL(FlutterEngine) engine = nullptr;
    std::vector<std::pair<fml::RefPtr<fml::TaskRunner>, FlutterTask>>
        pending_tasks;
    bool destroyed = false;
  };

  struct TaskRunnerContext {
    std::weak_ptr<SharedState> state;
    fml::RefPtr<fml::TaskRunner> runner;
  };

  // Creates and spawns dedicated threads with Android thread priorities for UI
  // and Raster task runners. If merged_platform_ui_thread is true, the
  // platform task runner is shared as the UI task runner.
  explicit AndroidTaskRunners(const std::string& thread_label,
                              bool merged_platform_ui_thread = false);

  // Creates AndroidTaskRunners using existing task runners.
  AndroidTaskRunners(const std::string& thread_label,
                     fml::RefPtr<fml::TaskRunner> platform_task_runner,
                     fml::RefPtr<fml::TaskRunner> ui_task_runner,
                     fml::RefPtr<fml::TaskRunner> raster_task_runner);

  ~AndroidTaskRunners();

  bool IsValid() const;

  fml::RefPtr<fml::TaskRunner> GetPlatformTaskRunner() const;
  fml::RefPtr<fml::TaskRunner> GetUITaskRunner() const;
  fml::RefPtr<fml::TaskRunner> GetRasterTaskRunner() const;

  // Associates a running FlutterEngine handle with these task runners for
  // task execution and drains any pre-startup pending tasks.
  void SetEngine(FLUTTER_API_SYMBOL(FlutterEngine) engine);
  FLUTTER_API_SYMBOL(FlutterEngine) GetEngine() const;
  size_t GetPendingTasksCount() const;

  // Returns the FlutterCustomTaskRunners description suitable for passing to
  // FlutterProjectArgs::custom_task_runners.
  const FlutterCustomTaskRunners& GetCustomTaskRunners() const;

 private:
  void InitDescriptions(const std::string& thread_label,
                        bool merged_platform_ui_thread);

  std::shared_ptr<SharedState> state_;

  fml::RefPtr<fml::TaskRunner> platform_task_runner_;
  fml::RefPtr<fml::TaskRunner> ui_task_runner_;
  fml::RefPtr<fml::TaskRunner> raster_task_runner_;

  std::unique_ptr<fml::Thread> ui_thread_;
  std::unique_ptr<fml::Thread> raster_thread_;

  std::shared_ptr<TaskRunnerContext> platform_context_;
  std::shared_ptr<TaskRunnerContext> ui_context_;
  std::shared_ptr<TaskRunnerContext> raster_context_;

  FlutterTaskRunnerDescription platform_description_ = {};
  FlutterTaskRunnerDescription ui_description_ = {};
  FlutterTaskRunnerDescription raster_description_ = {};
  FlutterCustomTaskRunners custom_task_runners_ = {};

  FML_DISALLOW_COPY_AND_ASSIGN(AndroidTaskRunners);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_TASK_RUNNERS_H_
