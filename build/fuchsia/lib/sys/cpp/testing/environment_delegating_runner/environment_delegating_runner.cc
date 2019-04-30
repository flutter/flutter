// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <lib/async-loop/cpp/loop.h>
#include <lib/fidl/cpp/binding_set.h>
#include <lib/sys/cpp/component_context.h>

int main() {
  async::Loop loop(&kAsyncLoopConfigAttachToThread);
  auto startup_ctx = sys::ComponentContext::Create();
  auto env_runner = startup_ctx->svc()->Connect<fuchsia::sys::Runner>();
  env_runner.set_error_handler([](zx_status_t) {
    // This program dies here to prevent proxying any further calls from our
    // own environment runner implementation.
    fprintf(stderr, "Lost connection to the environment's fuchsia.sys.Runner");
    exit(1);
  });

  fidl::BindingSet<fuchsia::sys::Runner> runner_bindings;
  startup_ctx->outgoing()->AddPublicService(
      runner_bindings.GetHandler(env_runner.get()));

  loop.Run();
  return 0;
}
