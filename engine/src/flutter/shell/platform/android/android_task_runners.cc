// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "flutter/shell/platform/android/android_task_runners.h"

#include <pthread.h>
#include <sys/resource.h>
#include <sys/time.h>

#include <atomic>
#include <utility>

#include "flutter/fml/cpu_affinity.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/time/time_point.h"

namespace flutter {

void AndroidThreadPrioritySetter(FlutterThreadPriority priority) {
  switch (priority) {
    case FlutterThreadPriority::kBackground: {
      fml::RequestAffinity(fml::CpuAffinity::kEfficiency);
      if (::setpriority(PRIO_PROCESS, 0, 10) != 0) {
        FML_LOG(ERROR) << "Failed to set IO task runner priority";
      }
      break;
    }
    case FlutterThreadPriority::kDisplay: {
      fml::RequestAffinity(fml::CpuAffinity::kNotEfficiency);
      if (::setpriority(PRIO_PROCESS, 0, -1) != 0) {
        FML_LOG(ERROR) << "Failed to set UI task runner priority";
      }
      break;
    }
    case FlutterThreadPriority::kRaster: {
      fml::RequestAffinity(fml::CpuAffinity::kNotEfficiency);
      // Android describes -8 as "most important display threads, for
      // compositing the screen and retrieving input events". Conservatively
      // set the raster thread to slightly lower priority than it.
      if (::setpriority(PRIO_PROCESS, 0, -5) != 0) {
        // Defensive fallback. Depending on the OEM, it may not be possible
        // to set priority to -5.
        if (::setpriority(PRIO_PROCESS, 0, -2) != 0) {
          FML_LOG(ERROR) << "Failed to set raster task runner priority";
        }
      }
      break;
    }
    case FlutterThreadPriority::kNormal:
    default:
      fml::RequestAffinity(fml::CpuAffinity::kNotPerformance);
      if (::setpriority(PRIO_PROCESS, 0, 0) != 0) {
        FML_LOG(ERROR) << "Failed to set priority";
      }
      break;
  }
}

void AndroidPlatformThreadConfigSetter(
    const fml::Thread::ThreadConfig& config) {
  // Set thread name.
  fml::Thread::SetCurrentThreadName(config);

  // Set thread priority.
  switch (config.priority) {
    case fml::Thread::ThreadPriority::kBackground:
      AndroidThreadPrioritySetter(FlutterThreadPriority::kBackground);
      break;
    case fml::Thread::ThreadPriority::kDisplay:
      AndroidThreadPrioritySetter(FlutterThreadPriority::kDisplay);
      break;
    case fml::Thread::ThreadPriority::kRaster:
      AndroidThreadPrioritySetter(FlutterThreadPriority::kRaster);
      break;
    default:
      AndroidThreadPrioritySetter(FlutterThreadPriority::kNormal);
      break;
  }
}

static void AndroidTaskRunnerPostTask(FlutterTask task,
                                      uint64_t target_time_nanos,
                                      void* user_data) {
  if (!user_data) {
    return;
  }
  auto* context =
      static_cast<AndroidTaskRunners::TaskRunnerContext*>(user_data);
  auto state = context->state.lock();
  if (!state || !context->runner) {
    return;
  }
  fml::TimePoint time_point = fml::TimePoint::FromEpochDelta(
      fml::TimeDelta::FromNanoseconds(target_time_nanos));
  context->runner->PostTaskForTime(
      [weak_state = context->state, runner = context->runner, task]() {
        auto state = weak_state.lock();
        if (!state) {
          return;
        }
        std::lock_guard lock(state->mutex);
        if (state->destroyed) {
          return;
        }
        if (state->engine) {
          FlutterEngineRunTask(state->engine, &task);
        } else {
          // Staging queue for pre-startup tasks posted before SetEngine.
          state->pending_tasks.emplace_back(runner, task);
        }
      },
      time_point);
}

static bool AndroidTaskRunnerRunsTaskOnCurrentThread(void* user_data) {
  if (!user_data) {
    return false;
  }
  auto* context =
      static_cast<AndroidTaskRunners::TaskRunnerContext*>(user_data);
  return context->runner ? context->runner->RunsTasksOnCurrentThread() : false;
}

AndroidTaskRunners::AndroidTaskRunners(const std::string& thread_label,
                                       bool merged_platform_ui_thread)
    : state_(std::make_shared<SharedState>()) {
  fml::MessageLoop::EnsureInitializedForCurrentThread();
  platform_task_runner_ = fml::MessageLoop::GetCurrent().GetTaskRunner();

  if (merged_platform_ui_thread) {
    ui_task_runner_ = platform_task_runner_;
  } else {
    ui_thread_ = std::make_unique<fml::Thread>(
        AndroidPlatformThreadConfigSetter,
        fml::Thread::ThreadConfig("io.flutter." + thread_label + ".ui",
                                  fml::Thread::ThreadPriority::kDisplay));
    ui_task_runner_ = ui_thread_->GetTaskRunner();
  }

  raster_thread_ = std::make_unique<fml::Thread>(
      AndroidPlatformThreadConfigSetter,
      fml::Thread::ThreadConfig("io.flutter." + thread_label + ".raster",
                                fml::Thread::ThreadPriority::kRaster));
  raster_task_runner_ = raster_thread_->GetTaskRunner();

  InitDescriptions(thread_label, merged_platform_ui_thread);
}

AndroidTaskRunners::AndroidTaskRunners(
    const std::string& thread_label,
    fml::RefPtr<fml::TaskRunner> platform_task_runner,
    fml::RefPtr<fml::TaskRunner> ui_task_runner,
    fml::RefPtr<fml::TaskRunner> raster_task_runner)
    : state_(std::make_shared<SharedState>()),
      platform_task_runner_(std::move(platform_task_runner)),
      ui_task_runner_(std::move(ui_task_runner)),
      raster_task_runner_(std::move(raster_task_runner)) {
  bool merged = (platform_task_runner_ == ui_task_runner_);
  InitDescriptions(thread_label, merged);
}

AndroidTaskRunners::~AndroidTaskRunners() {
  if (state_) {
    std::lock_guard lock(state_->mutex);
    state_->destroyed = true;
    state_->engine = nullptr;
    state_->pending_tasks.clear();
  }
}

void AndroidTaskRunners::SetEngine(FLUTTER_API_SYMBOL(FlutterEngine) engine) {
  std::vector<std::pair<fml::RefPtr<fml::TaskRunner>, FlutterTask>>
      tasks_to_drain;
  {
    std::lock_guard lock(state_->mutex);
    state_->engine = engine;
    if (engine) {
      tasks_to_drain.swap(state_->pending_tasks);
    }
  }

  for (const auto& [runner, task] : tasks_to_drain) {
    runner->PostTask([weak_state = std::weak_ptr<SharedState>(state_), task]() {
      auto state = weak_state.lock();
      if (!state) {
        return;
      }
      std::lock_guard lock(state->mutex);
      if (state->engine && !state->destroyed) {
        FlutterEngineRunTask(state->engine, &task);
      }
    });
  }
}

FLUTTER_API_SYMBOL(FlutterEngine) AndroidTaskRunners::GetEngine() const {
  if (!state_) {
    return nullptr;
  }
  std::lock_guard lock(state_->mutex);
  return state_->engine;
}

size_t AndroidTaskRunners::GetPendingTasksCount() const {
  if (!state_) {
    return 0;
  }
  std::lock_guard lock(state_->mutex);
  return state_->pending_tasks.size();
}

void AndroidTaskRunners::InitDescriptions(const std::string& thread_label,
                                          bool merged_platform_ui_thread) {
  static std::atomic<uint64_t> s_task_runner_id{1};

  platform_context_ = std::make_shared<TaskRunnerContext>(
      TaskRunnerContext{state_, platform_task_runner_});
  ui_context_ = std::make_shared<TaskRunnerContext>(
      TaskRunnerContext{state_, ui_task_runner_});
  raster_context_ = std::make_shared<TaskRunnerContext>(
      TaskRunnerContext{state_, raster_task_runner_});

  uint64_t platform_id = s_task_runner_id++;
  uint64_t ui_id = merged_platform_ui_thread ? platform_id : s_task_runner_id++;
  uint64_t raster_id = s_task_runner_id++;

  platform_description_.struct_size = sizeof(FlutterTaskRunnerDescription);
  platform_description_.user_data = platform_context_.get();
  platform_description_.post_task_callback = AndroidTaskRunnerPostTask;
  platform_description_.runs_task_on_current_thread_callback =
      AndroidTaskRunnerRunsTaskOnCurrentThread;
  platform_description_.identifier = platform_id;

  ui_description_.struct_size = sizeof(FlutterTaskRunnerDescription);
  ui_description_.user_data = ui_context_.get();
  ui_description_.post_task_callback = AndroidTaskRunnerPostTask;
  ui_description_.runs_task_on_current_thread_callback =
      AndroidTaskRunnerRunsTaskOnCurrentThread;
  ui_description_.identifier = ui_id;

  raster_description_.struct_size = sizeof(FlutterTaskRunnerDescription);
  raster_description_.user_data = raster_context_.get();
  raster_description_.post_task_callback = AndroidTaskRunnerPostTask;
  raster_description_.runs_task_on_current_thread_callback =
      AndroidTaskRunnerRunsTaskOnCurrentThread;
  raster_description_.identifier = raster_id;

  custom_task_runners_.struct_size = sizeof(FlutterCustomTaskRunners);
  custom_task_runners_.platform_task_runner = &platform_description_;
  custom_task_runners_.ui_task_runner = &ui_description_;
  custom_task_runners_.render_task_runner = &raster_description_;
  custom_task_runners_.thread_priority_setter = &AndroidThreadPrioritySetter;
}

bool AndroidTaskRunners::IsValid() const {
  return platform_task_runner_ && ui_task_runner_ && raster_task_runner_;
}

fml::RefPtr<fml::TaskRunner> AndroidTaskRunners::GetPlatformTaskRunner() const {
  return platform_task_runner_;
}

fml::RefPtr<fml::TaskRunner> AndroidTaskRunners::GetUITaskRunner() const {
  return ui_task_runner_;
}

fml::RefPtr<fml::TaskRunner> AndroidTaskRunners::GetRasterTaskRunner() const {
  return raster_task_runner_;
}

const FlutterCustomTaskRunners& AndroidTaskRunners::GetCustomTaskRunners()
    const {
  return custom_task_runners_;
}

}  // namespace flutter
