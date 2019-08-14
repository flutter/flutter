// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/client_wrapper/testing/stub_flutter_windows_api.h"

static flutter::testing::StubFlutterWindowsApi* s_stub_implementation;

namespace flutter {
namespace testing {

// static
void StubFlutterWindowsApi::SetTestStub(StubFlutterWindowsApi* stub) {
  s_stub_implementation = stub;
}

// static
StubFlutterWindowsApi* StubFlutterWindowsApi::GetTestStub() {
  return s_stub_implementation;
}

ScopedStubFlutterWindowsApi::ScopedStubFlutterWindowsApi(
    std::unique_ptr<StubFlutterWindowsApi> stub)
    : stub_(std::move(stub)) {
  previous_stub_ = StubFlutterWindowsApi::GetTestStub();
  StubFlutterWindowsApi::SetTestStub(stub_.get());
}

ScopedStubFlutterWindowsApi::~ScopedStubFlutterWindowsApi() {
  StubFlutterWindowsApi::SetTestStub(previous_stub_);
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

FlutterDesktopWindowControllerRef FlutterDesktopCreateWindow(
    int initial_width,
    int initial_height,
    const char* title,
    const char* assets_path,
    const char* icu_data_path,
    const char** arguments,
    size_t argument_count) {
  if (s_stub_implementation) {
    return s_stub_implementation->CreateWindow(
        initial_width, initial_height, title, assets_path, icu_data_path,
        arguments, argument_count);
  }
  return nullptr;
}

void FlutterDesktopDestroyWindow(FlutterDesktopWindowControllerRef controller) {
  if (s_stub_implementation) {
    s_stub_implementation->DestroyWindow();
  }
}

void FlutterDesktopSetHoverEnabled(FlutterDesktopWindowRef flutter_window,
                                   bool enabled) {
  if (s_stub_implementation) {
    s_stub_implementation->SetHoverEnabled(enabled);
  }
}

void FlutterDesktopSetWindowTitle(FlutterDesktopWindowRef flutter_window,
                                  const char* title) {
  if (s_stub_implementation) {
    s_stub_implementation->SetWindowTitle(title);
  }
}

void FlutterDesktopSetWindowIcon(FlutterDesktopWindowRef flutter_window,
                                 uint8_t* pixel_data,
                                 int width,
                                 int height) {
  if (s_stub_implementation) {
    s_stub_implementation->SetWindowIcon(pixel_data, width, height);
  }
}

void FlutterDesktopRunWindowLoop(FlutterDesktopWindowControllerRef controller) {
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

FlutterDesktopWindowRef FlutterDesktopGetWindow(
    FlutterDesktopWindowControllerRef controller) {
  // The stub ignores this, so just return an arbitrary non-zero value.
  return reinterpret_cast<FlutterDesktopWindowRef>(1);
}

FlutterDesktopPluginRegistrarRef FlutterDesktopGetPluginRegistrar(
    FlutterDesktopWindowControllerRef controller,
    const char* plugin_name) {
  // The stub ignores this, so just return an arbitrary non-zero value.
  return reinterpret_cast<FlutterDesktopPluginRegistrarRef>(1);
}
