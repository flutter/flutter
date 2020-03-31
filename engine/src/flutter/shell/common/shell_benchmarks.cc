// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/benchmarking/benchmarking.h"
#include "flutter/fml/logging.h"
#include "flutter/runtime/dart_vm.h"
#include "flutter/shell/common/shell.h"
#include "flutter/shell/common/thread_host.h"
#include "flutter/testing/elf_loader.h"
#include "flutter/testing/testing.h"

namespace flutter {

static void StartupAndShutdownShell(benchmark::State& state,
                                    bool measure_startup,
                                    bool measure_shutdown) {
  auto assets_dir = fml::OpenDirectory(testing::GetFixturesPath(), false,
                                       fml::FilePermission::kRead);
  std::unique_ptr<Shell> shell;
  std::unique_ptr<ThreadHost> thread_host;
  testing::ELFAOTSymbols aot_symbols;

  {
    benchmarking::ScopedPauseTiming pause(state, !measure_startup);
    Settings settings = {};
    settings.task_observer_add = [](intptr_t, fml::closure) {};
    settings.task_observer_remove = [](intptr_t) {};

    if (DartVM::IsRunningPrecompiledCode()) {
      aot_symbols = testing::LoadELFSymbolFromFixturesIfNeccessary();
      FML_CHECK(
          testing::PrepareSettingsForAOTWithSymbols(settings, aot_symbols))
          << "Could not setup settings with AOT symbols.";
    } else {
      settings.application_kernels = [&]() {
        std::vector<std::unique_ptr<const fml::Mapping>> kernel_mappings;
        kernel_mappings.emplace_back(
            fml::FileMapping::CreateReadOnly(assets_dir, "kernel_blob.bin"));
        return kernel_mappings;
      };
    }

    thread_host = std::make_unique<ThreadHost>(
        "io.flutter.bench.", ThreadHost::Type::Platform |
                                 ThreadHost::Type::GPU | ThreadHost::Type::IO |
                                 ThreadHost::Type::UI);

    TaskRunners task_runners("test",
                             thread_host->platform_thread->GetTaskRunner(),
                             thread_host->raster_thread->GetTaskRunner(),
                             thread_host->ui_thread->GetTaskRunner(),
                             thread_host->io_thread->GetTaskRunner());

    shell = Shell::Create(
        std::move(task_runners), settings,
        [](Shell& shell) {
          return std::make_unique<PlatformView>(shell, shell.GetTaskRunners());
        },
        [](Shell& shell) {
          return std::make_unique<Rasterizer>(shell, shell.GetTaskRunners());
        });
  }

  FML_CHECK(shell);

  {
    benchmarking::ScopedPauseTiming pause(state, !measure_shutdown);
    // Shutdown must occur synchronously on the platform thread.
    fml::AutoResetWaitableEvent latch;
    fml::TaskRunner::RunNowOrPostTask(
        thread_host->platform_thread->GetTaskRunner(),
        [&shell, &latch]() mutable {
          shell.reset();
          latch.Signal();
        });
    latch.Wait();
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

}  // namespace flutter
