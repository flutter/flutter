// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/glfw/client_wrapper/testing/stub_flutter_glfw_api.h"

static flutter::testing::StubFlutterGlfwApi* s_stub_implementation;

namespace flutter {
namespace testing {

// static
void StubFlutterGlfwApi::SetTestStub(StubFlutterGlfwApi* stub) {
  s_stub_implementation = stub;
}

// static
StubFlutterGlfwApi* StubFlutterGlfwApi::GetTestStub() {
  return s_stub_implementation;
}

ScopedStubFlutterGlfwApi::ScopedStubFlutterGlfwApi(
    std::unique_ptr<StubFlutterGlfwApi> stub)
    : stub_(std::move(stub)) {
  previous_stub_ = StubFlutterGlfwApi::GetTestStub();
  StubFlutterGlfwApi::SetTestStub(stub_.get());
}

ScopedStubFlutterGlfwApi::~ScopedStubFlutterGlfwApi() {
  StubFlutterGlfwApi::SetTestStub(previous_stub_);
}

}  // namespace testing
}  // namespace flutter

// Forwarding dummy implementations of the C API.

bool FlutterDesktopInit() {
  if (s_stub_implementation) {
    s_stub_implementation->Init();
  }
  return true;
}

void FlutterDesktopTerminate() {
  if (s_stub_implementation) {
    s_stub_implementation->Terminate();
  }
}

FlutterDesktopWindowRef FlutterDesktopCreateWindow(int initial_width,
                                                   int initial_height,
                                                   const char* assets_path,
                                                   const char* icu_data_path,
                                                   const char** arguments,
                                                   size_t argument_count) {
  if (s_stub_implementation) {
    return s_stub_implementation->CreateWindow(initial_width, initial_height,
                                               assets_path, icu_data_path,
                                               arguments, argument_count);
  }
  return nullptr;
}

void FlutterDesktopSetHoverEnabled(FlutterDesktopWindowRef flutter_window,
                                   bool enabled) {
  if (s_stub_implementation) {
    s_stub_implementation->SetHoverEnabled(enabled);
  }
}

void FlutterDesktopRunWindowLoop(FlutterDesktopWindowRef flutter_window) {
  if (s_stub_implementation) {
    s_stub_implementation->RunWindowLoop();
  }
}

FlutterDesktopEngineRef FlutterDesktopRunEngine(const char* assets_path,
                                                const char* icu_data_path,
                                                const char** arguments,
                                                size_t argument_count) {
  if (s_stub_implementation) {
    return s_stub_implementation->RunEngine(assets_path, icu_data_path,
                                            arguments, argument_count);
  }
  return nullptr;
}

bool FlutterDesktopShutDownEngine(FlutterDesktopEngineRef engine_ref) {
  if (s_stub_implementation) {
    return s_stub_implementation->ShutDownEngine();
  }
  return true;
}

FlutterDesktopPluginRegistrarRef FlutterDesktopGetPluginRegistrar(
    FlutterDesktopWindowRef flutter_window,
    const char* plugin_name) {
  // The stub ignores this, so just return an arbitrary non-zero value.
  return reinterpret_cast<FlutterDesktopPluginRegistrarRef>(1);
}
