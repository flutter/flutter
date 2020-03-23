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

FlutterDesktopViewControllerRef FlutterDesktopCreateViewController(
    int width,
    int height,
    const FlutterDesktopEngineProperties& engine_properties) {
  if (s_stub_implementation) {
    return s_stub_implementation->CreateViewController(width, height,
                                                       engine_properties);
  }
  return nullptr;
}

FlutterDesktopViewControllerRef FlutterDesktopCreateViewControllerLegacy(
    int initial_width,
    int initial_height,
    const char* assets_path,
    const char* icu_data_path,
    const char** arguments,
    size_t argument_count) {
  if (s_stub_implementation) {
    // This stub will be removed shortly, and the current tests don't need the
    // arguments, so there's no need to translate them to engine_properties.
    FlutterDesktopEngineProperties engine_properties;
    return s_stub_implementation->CreateViewController(
        initial_width, initial_height, engine_properties);
  }
  return nullptr;
}

void FlutterDesktopDestroyViewController(
    FlutterDesktopViewControllerRef controller) {
  if (s_stub_implementation) {
    s_stub_implementation->DestroyViewController();
  }
}

FlutterDesktopViewRef FlutterDesktopGetView(
    FlutterDesktopViewControllerRef controller) {
  // The stub ignores this, so just return an arbitrary non-zero value.
  return reinterpret_cast<FlutterDesktopViewRef>(1);
}

uint64_t FlutterDesktopProcessMessages(
    FlutterDesktopViewControllerRef controller) {
  if (s_stub_implementation) {
    return s_stub_implementation->ProcessMessages();
  }
  return 0;
}

HWND FlutterDesktopViewGetHWND(FlutterDesktopViewRef controller) {
  if (s_stub_implementation) {
    return s_stub_implementation->ViewGetHWND();
  }
  return reinterpret_cast<HWND>(-1);
}

FlutterDesktopEngineRef FlutterDesktopRunEngine(
    const FlutterDesktopEngineProperties& engine_properties) {
  if (s_stub_implementation) {
    return s_stub_implementation->RunEngine(engine_properties);
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
    FlutterDesktopViewControllerRef controller,
    const char* plugin_name) {
  // The stub ignores this, so just return an arbitrary non-zero value.
  return reinterpret_cast<FlutterDesktopPluginRegistrarRef>(1);
}

FlutterDesktopViewRef FlutterDesktopRegistrarGetView(
    FlutterDesktopPluginRegistrarRef controller) {
  // The stub ignores this, so just return an arbitrary non-zero value.
  return reinterpret_cast<FlutterDesktopViewRef>(1);
}
