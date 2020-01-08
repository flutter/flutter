// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include <lib/async-loop/cpp/loop.h>
#include <lib/async-loop/default.h>
#include <lib/trace-provider/provider.h>
#include <lib/trace/event.h>

#include <cstdlib>

#include "runner.h"
#include "runtime/dart/utils/tempfs.h"

int main(int argc, char const* argv[]) {
  fml::MessageLoop::EnsureInitializedForCurrentThread();
  auto& message_loop = fml::MessageLoop::GetCurrent();

  std::unique_ptr<trace::TraceProviderWithFdio> provider;
  {
    TRACE_DURATION("flutter", "CreateTraceProvider");
    bool already_started;
    // Use CreateSynchronously to prevent loss of early events.
    trace::TraceProviderWithFdio::CreateSynchronously(
        async_get_default_dispatcher(), "flutter_runner", &provider,
        &already_started);
  }

  // Set up the process-wide /tmp memfs.
  dart_utils::RunnerTemp runner_temp;

  FML_DLOG(INFO) << "Flutter application services initialized.";

  flutter_runner::Runner runner(message_loop);

  message_loop.Run();

  FML_DLOG(INFO) << "Flutter application services terminated.";

  return EXIT_SUCCESS;
}
