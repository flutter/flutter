// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <lib/async-loop/cpp/loop.h>
#include <lib/trace-provider/provider.h>
#include <lib/trace/event.h>

#include <cstdlib>

#include "loop.h"
#include "platform/utils.h"
#include "runner.h"
#include "runtime/dart/utils/tempfs.h"

int main(int argc, char const* argv[]) {
  std::unique_ptr<async::Loop> loop(flutter_runner::MakeObservableLoop(true));

  std::unique_ptr<trace::TraceProviderWithFdio> provider;
  {
    bool already_started;
    // Use CreateSynchronously to prevent loss of early events.
    trace::TraceProviderWithFdio::CreateSynchronously(
        loop->dispatcher(), "flutter_runner", &provider, &already_started);
  }

  // Set up the process-wide /tmp memfs.
  dart_utils::RunnerTemp runner_temp;

  FML_DLOG(INFO) << "Flutter application services initialized.";

  flutter_runner::Runner runner(loop.get(), dart::ComponentContext());

  loop->Run();
  FML_DLOG(INFO) << "Flutter application services terminated.";

  return EXIT_SUCCESS;
}
