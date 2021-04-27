// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <lib/async-loop/cpp/loop.h>
#include <lib/sys/inspect/cpp/component.h>
#include <lib/trace-provider/provider.h>
#include <lib/trace/event.h>

#include <cstdlib>

#include "loop.h"
#include "platform/utils.h"
#include "runner.h"
#include "runtime/dart/utils/root_inspect_node.h"
#include "runtime/dart/utils/tempfs.h"

int main(int argc, char const* argv[]) {
  std::unique_ptr<async::Loop> loop(flutter_runner::MakeObservableLoop(true));

  // Create our component context which is served later.
  auto context = sys::ComponentContext::Create();
  dart_utils::RootInspectNode::Initialize(context.get());

  // We inject the 'vm' node into the dart vm so that it can add any inspect
  // data that it needs to the inspect tree.
  dart::SetDartVmNode(std::make_unique<inspect::Node>(
      dart_utils::RootInspectNode::CreateRootChild("vm")));

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

  flutter_runner::Runner runner(loop.get(), context.get());

  // Wait to serve until we have finished all of our setup.
  context->outgoing()->ServeFromStartupInfo();

  loop->Run();
  FML_DLOG(INFO) << "Flutter application services terminated.";

  return EXIT_SUCCESS;
}
