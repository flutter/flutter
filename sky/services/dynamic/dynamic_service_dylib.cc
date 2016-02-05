// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/services/dynamic/dynamic_service.h"

#include <assert.h>

#include "sky/services/dynamic/dynamic_service_dylib.h"
#include "mojo/public/cpp/environment/environment.h"

static mojo::Environment* g_dylib_environment;

void FlutterServiceOnLoad(const MojoAsyncWaiter* waiter,
                          const MojoLogger* logger) {
  // Assert that the dylib environment is not already initialized somehow.
  assert(g_dylib_environment == nullptr);
  g_dylib_environment = new mojo::Environment(waiter, logger);
}

void FlutterServiceInvoke(MojoHandle client_handle, const char* service_name) {
  assert(g_dylib_environment != nullptr);

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
  assert(g_dylib_environment != nullptr);
  delete g_dylib_environment;
  g_dylib_environment = nullptr;
}
