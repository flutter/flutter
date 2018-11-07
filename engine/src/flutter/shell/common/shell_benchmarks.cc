// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/benchmarking/benchmarking.h"
#include "flutter/fml/logging.h"
#include "flutter/shell/common/shell.h"
#include "flutter/shell/common/thread_host.h"

namespace shell {

static void StartupAndShutdownShell(benchmark::State& state,
                                    bool measure_startup,
                                    bool measure_shutdown) {
  std::unique_ptr<Shell> shell;
  std::unique_ptr<ThreadHost> thread_host;
  {
    benchmarking::ScopedPauseTiming pause(state, !measure_startup);
    blink::Settings settings = {};
    settings.task_observer_add = [](intptr_t, fml::closure) {};
    settings.task_observer_remove = [](intptr_t) {};

    // Measure the time it takes to setup the threads as well.
    thread_host = std::make_unique<ThreadHost>(
        "io.flutter.bench.", ThreadHost::Type::Platform |
                                 ThreadHost::Type::GPU | ThreadHost::Type::IO |
                                 ThreadHost::Type::UI);

    blink::TaskRunners task_runners(
        "test", thread_host->platform_thread->GetTaskRunner(),
        thread_host->gpu_thread->GetTaskRunner(),
        thread_host->ui_thread->GetTaskRunner(),
        thread_host->io_thread->GetTaskRunner());

    shell = Shell::Create(
        std::move(task_runners), settings,
        [](Shell& shell) {
          return std::make_unique<PlatformView>(shell, shell.GetTaskRunners());
        },
        [](Shell& shell) {
          return std::make_unique<Rasterizer>(shell.GetTaskRunners());
        });
  }

  FML_CHECK(shell);

  {
    benchmarking::ScopedPauseTiming pause(state, !measure_shutdown);
    shell.reset();  // Shutdown is synchronous.
    thread_host.reset();
  }

  FML_CHECK(!shell);
}

static void BM_ShellInitialization(benchmark::State& state) {
  while (state.KeepRunning()) {
    StartupAndShutdownShell(state, true, false);
  }
}

BENCHMARK(BM_ShellInitialization);

static void BM_ShellShutdown(benchmark::State& state) {
  while (state.KeepRunning()) {
    StartupAndShutdownShell(state, false, true);
  }
}

BENCHMARK(BM_ShellShutdown);

static void BM_ShellInitializationAndShutdown(benchmark::State& state) {
  while (state.KeepRunning()) {
    StartupAndShutdownShell(state, true, true);
  }
}

BENCHMARK(BM_ShellInitializationAndShutdown);

}  // namespace shell
