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

FlutterDesktopViewControllerRef FlutterDesktopViewControllerCreate(
    int width,
    int height,
    FlutterDesktopEngineRef engine) {
  if (s_stub_implementation) {
    return s_stub_implementation->ViewControllerCreate(width, height, engine);
  }
  return nullptr;
}

void FlutterDesktopViewControllerDestroy(
    FlutterDesktopViewControllerRef controller) {
  if (s_stub_implementation) {
    s_stub_implementation->ViewControllerDestroy();
  }
}

FlutterDesktopEngineRef FlutterDesktopViewControllerGetEngine(
    FlutterDesktopViewControllerRef controller) {
  // The stub ignores this, so just return an arbitrary non-zero value.
  return reinterpret_cast<FlutterDesktopEngineRef>(1);
}

FlutterDesktopViewRef FlutterDesktopViewControllerGetView(
    FlutterDesktopViewControllerRef controller) {
  // The stub ignores this, so just return an arbitrary non-zero value.
  return reinterpret_cast<FlutterDesktopViewRef>(1);
}

FlutterDesktopEngineRef FlutterDesktopEngineCreate(
    const FlutterDesktopEngineProperties& engine_properties) {
  if (s_stub_implementation) {
    return s_stub_implementation->EngineCreate(engine_properties);
  }
  return nullptr;
}

bool FlutterDesktopEngineDestroy(FlutterDesktopEngineRef engine_ref) {
  if (s_stub_implementation) {
    return s_stub_implementation->EngineDestroy();
  }
  return true;
}

bool FlutterDesktopEngineRun(FlutterDesktopEngineRef engine,
                             const char* entry_point) {
  if (s_stub_implementation) {
    return s_stub_implementation->EngineRun(entry_point);
  }
  return true;
}

uint64_t FlutterDesktopEngineProcessMessages(FlutterDesktopEngineRef engine) {
  if (s_stub_implementation) {
    return s_stub_implementation->EngineProcessMessages();
  }
  return 0;
}

FlutterDesktopPluginRegistrarRef FlutterDesktopEngineGetPluginRegistrar(
    FlutterDesktopEngineRef engine,
    const char* plugin_name) {
  // The stub ignores this, so just return an arbitrary non-zero value.
  return reinterpret_cast<FlutterDesktopPluginRegistrarRef>(1);
}

HWND FlutterDesktopViewGetHWND(FlutterDesktopViewRef controller) {
  if (s_stub_implementation) {
    return s_stub_implementation->ViewGetHWND();
  }
  return reinterpret_cast<HWND>(-1);
}

FlutterDesktopViewRef FlutterDesktopPluginRegistrarGetView(
    FlutterDesktopPluginRegistrarRef controller) {
  // The stub ignores this, so just return an arbitrary non-zero value.
  return reinterpret_cast<FlutterDesktopViewRef>(1);
}
