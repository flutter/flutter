// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_WRAPPER_TESTING_STUB_FLUTTER_WINDOWS_API_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_WRAPPER_TESTING_STUB_FLUTTER_WINDOWS_API_H_

#include <memory>

#include "flutter/shell/platform/windows/public/flutter_windows.h"

namespace flutter {
namespace testing {

// Base class for a object that provides test implementations of the APIs in
// the headers in platform/windows/public/.

// Linking this class into a test binary will provide dummy forwarding
// implementantions of that C API, so that the wrapper can be tested separately
// from the actual library.
class StubFlutterWindowsApi {
 public:
  // Sets |stub| as the instance to which calls to the Flutter library C APIs
  // will be forwarded.
  static void SetTestStub(StubFlutterWindowsApi* stub);

  // Returns the current stub, as last set by SetTestFluttterStub.
  static StubFlutterWindowsApi* GetTestStub();

  virtual ~StubFlutterWindowsApi() {}

  // Called for FlutterDesktopCreateViewController.
  virtual FlutterDesktopViewControllerRef CreateViewController(
      int width,
      int height,
      const FlutterDesktopEngineProperties& engine_properties) {
    return nullptr;
  }

  // Called for FlutterDesktopDestroyView.
  virtual void DestroyViewController() {}

  // Called for FlutterDesktopProcessMessages.
  virtual uint64_t ProcessMessages() { return 0; }

  // Called for FlutterDesktopViewGetHWND.
  virtual HWND ViewGetHWND() { return reinterpret_cast<HWND>(1); }

  // Called for FlutterDesktopRunEngine.
  virtual FlutterDesktopEngineRef RunEngine(
      const FlutterDesktopEngineProperties& engine_properties) {
    return nullptr;
  }

  // Called for FlutterDesktopShutDownEngine.
  virtual bool ShutDownEngine() { return true; }
};

// A test helper that owns a stub implementation, making it the test stub for
// the lifetime of the object, then restoring the previous value.
class ScopedStubFlutterWindowsApi {
 public:
  // Calls SetTestFlutterStub with |stub|.
  ScopedStubFlutterWindowsApi(std::unique_ptr<StubFlutterWindowsApi> stub);

  // Restores the previous test stub.
  ~ScopedStubFlutterWindowsApi();

  StubFlutterWindowsApi* stub() { return stub_.get(); }

 private:
  std::unique_ptr<StubFlutterWindowsApi> stub_;
  // The previous stub.
  StubFlutterWindowsApi* previous_stub_;
};

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_CLIENT_WRAPPER_TESTING_STUB_FLUTTER_WINDOWS_API_H_
