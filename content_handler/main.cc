// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <trace-provider/provider.h>
#include <cstdlib>

#include "application_runner.h"
#include "lib/fsl/tasks/message_loop.h"

int main(int argc, char const* argv[]) {
  fsl::MessageLoop loop;

  trace::TraceProvider provider(loop.async());
  FXL_DCHECK(provider.is_valid()) << "Trace provider must be valid.";

  FXL_LOG(INFO) << "Flutter application services initialized.";
  flutter::ApplicationRunner runner([&loop]() {
    loop.PostQuitTask();
    FXL_LOG(INFO) << "Flutter application services terminated. Good bye...";
  });

  loop.Run();

  return EXIT_SUCCESS;
}
