// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This is why we can't yet export the UI thread to embedders.
#define FML_USED_ON_EMBEDDER

#include "flutter/shell/platform/embedder/embedder_thread_host.h"

#include "flutter/fml/message_loop.h"
#include "flutter/shell/platform/embedder/embedder_safe_access.h"

namespace shell {

static fml::RefPtr<EmbedderTaskRunner> CreateEmbedderTaskRunner(
    const FlutterTaskRunnerDescription* description) {
  if (description == nullptr) {
    return {};
  }

  if (SAFE_ACCESS(description, runs_task_on_current_thread_callback, nullptr) ==
      nullptr) {
    FML_LOG(ERROR) << "FlutterTaskRunnerDescription.runs_task_on_current_"
                      "thread_callback was nullptr.";
    return {};
  }

  if (SAFE_ACCESS(description, post_task_callback, nullptr) == nullptr) {
    FML_LOG(ERROR)
        << "FlutterTaskRunnerDescription.post_task_callback was nullptr.";
    return {};
  }

  auto user_data = SAFE_ACCESS(description, user_data, nullptr);

  // ABI safety checks have been completed.
  auto post_task_callback_c = description->post_task_callback;
  auto runs_task_on_current_thread_callback_c =
      description->runs_task_on_current_thread_callback;

  EmbedderTaskRunner::DispatchTable task_runner_dispatch_table = {
      // .post_task_callback
      [post_task_callback_c, user_data](EmbedderTaskRunner* task_runner,
                                        uint64_t task_baton,
                                        fml::TimePoint target_time) -> void {
        FlutterTask task = {
            // runner
            reinterpret_cast<FlutterTaskRunner>(task_runner),
            // task
            task_baton,
        };
        post_task_callback_c(task, target_time.ToEpochDelta().ToNanoseconds(),
                             user_data);
      },
      // runs_task_on_current_thread_callback
      [runs_task_on_current_thread_callback_c, user_data]() -> bool {
        return runs_task_on_current_thread_callback_c(user_data);
      }};

  return fml::MakeRefCounted<EmbedderTaskRunner>(task_runner_dispatch_table);
}

std::unique_ptr<EmbedderThreadHost>
EmbedderThreadHost::CreateEmbedderOrEngineManagedThreadHost(
    const FlutterCustomTaskRunners* custom_task_runners) {
  {
    auto host = CreateEmbedderManagedThreadHost(custom_task_runners);
    if (host && host->IsValid()) {
      return host;
    }
  }

  // Only attempt to create the engine managed host if the embedder did not
  // specify a custom configuration. We don't want to fallback to the engine
  // managed configuration if the embedder attempted to specify a configuration
  // but messed up with an incorrect configuration.
  if (custom_task_runners == nullptr) {
    auto host = CreateEngineManagedThreadHost();
    if (host && host->IsValid()) {
      return host;
    }
  }

  return nullptr;
}

constexpr const char* kFlutterThreadName = "io.flutter";

// static
std::unique_ptr<EmbedderThreadHost>
EmbedderThreadHost::CreateEmbedderManagedThreadHost(
    const FlutterCustomTaskRunners* custom_task_runners) {
  if (custom_task_runners == nullptr) {
    return nullptr;
  }

  const auto platform_task_runner = CreateEmbedderTaskRunner(
      SAFE_ACCESS(custom_task_runners, platform_task_runner, nullptr));

  // TODO(chinmaygarde): Add more here as we allow more threads to be controlled
  // by the embedder. Create fallbacks as necessary.

  if (!platform_task_runner) {
    return nullptr;
  }

  ThreadHost thread_host(kFlutterThreadName, ThreadHost::Type::GPU |
                                                 ThreadHost::Type::IO |
                                                 ThreadHost::Type::UI);

  blink::TaskRunners task_runners(
      kFlutterThreadName,
      platform_task_runner,                     // platform
      thread_host.gpu_thread->GetTaskRunner(),  // gpu
      thread_host.ui_thread->GetTaskRunner(),   // ui
      thread_host.io_thread->GetTaskRunner()    // io
  );

  if (!task_runners.IsValid()) {
    return nullptr;
  }

  std::set<fml::RefPtr<EmbedderTaskRunner>> embedder_task_runners;
  embedder_task_runners.insert(platform_task_runner);

  auto embedder_host = std::make_unique<EmbedderThreadHost>(
      std::move(thread_host), std::move(task_runners),
      std::move(embedder_task_runners));

  if (embedder_host->IsValid()) {
    return embedder_host;
  }

  return nullptr;
}

// static
std::unique_ptr<EmbedderThreadHost>
EmbedderThreadHost::CreateEngineManagedThreadHost() {
  // Create a thread host with the current thread as the platform thread and all
  // other threads managed.
  ThreadHost thread_host(kFlutterThreadName, ThreadHost::Type::GPU |
                                                 ThreadHost::Type::IO |
                                                 ThreadHost::Type::UI);

  fml::MessageLoop::EnsureInitializedForCurrentThread();

  // For embedder platforms that don't have native message loop interop, this
  // will reference a task runner that points to a null message loop
  // implementation.
  auto platform_task_runner = fml::MessageLoop::GetCurrent().GetTaskRunner();

  blink::TaskRunners task_runners(
      kFlutterThreadName,
      platform_task_runner,                     // platform
      thread_host.gpu_thread->GetTaskRunner(),  // gpu
      thread_host.ui_thread->GetTaskRunner(),   // ui
      thread_host.io_thread->GetTaskRunner()    // io
  );

  if (!task_runners.IsValid()) {
    return nullptr;
  }

  std::set<fml::RefPtr<EmbedderTaskRunner>> empty_embedder_task_runners;

  auto embedder_host = std::make_unique<EmbedderThreadHost>(
      std::move(thread_host), std::move(task_runners),
      empty_embedder_task_runners);

  if (embedder_host->IsValid()) {
    return embedder_host;
  }

  return nullptr;
}

EmbedderThreadHost::EmbedderThreadHost(
    ThreadHost host,
    blink::TaskRunners runners,
    std::set<fml::RefPtr<EmbedderTaskRunner>> embedder_task_runners)
    : host_(std::move(host)), runners_(std::move(runners)) {
  for (const auto& runner : embedder_task_runners) {
    runners_map_[reinterpret_cast<int64_t>(runner.get())] = runner;
  }
}

EmbedderThreadHost::~EmbedderThreadHost() = default;

bool EmbedderThreadHost::IsValid() const {
  return runners_.IsValid();
}

const blink::TaskRunners& EmbedderThreadHost::GetTaskRunners() const {
  return runners_;
}

bool EmbedderThreadHost::PostTask(int64_t runner, uint64_t task) const {
  auto found = runners_map_.find(runner);
  if (found == runners_map_.end()) {
    return false;
  }
  return found->second->PostTask(task);
}

}  // namespace shell
