// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/services/dynamic/dynamic_service.h"

#include <assert.h>

#include "sky/services/dynamic/dynamic_service_dylib.h"
#include "mojo/public/cpp/environment/environment.h"

static bool g_did_initialize_environment = false;

void FlutterServiceOnLoad(const MojoAsyncWaiter* waiter,
                          const MojoLogger* logger) {
  // Assert that the dylib environment is not already initialized somehow.
  assert(!g_did_initialize_environment);
  g_did_initialize_environment = true;
  mojo::Environment::SetDefaultAsyncWaiter(waiter);
  mojo::Environment::SetDefaultLogger(logger);
}

void FlutterServiceInvoke(MojoHandle client_handle, const char* service_name) {
  assert(g_did_initialize_environment);

  // The service is always responsible for releasing the client handle. Create
  // a scoped handle immediately.
  mojo::MessagePipeHandle message_pipe_handle(client_handle);
  mojo::ScopedMessagePipeHandle scoped_handle(message_pipe_handle);

  mojo::String name(service_name);

  // Call the user callback
  FlutterServicePerform(scoped_handle.Pass(), name);
}

void FlutterServiceOnUnload() {
  // Make sure the library is not being unloaded without the OnLoad callback
  // being called already.
  assert(g_did_initialize_environment);
  g_did_initialize_environment = false;
}
