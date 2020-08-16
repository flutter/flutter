// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_COMMON_CPP_CLIENT_WRAPPER_TESTING_STUB_FLUTTER_API_H_
#define FLUTTER_SHELL_PLATFORM_COMMON_CPP_CLIENT_WRAPPER_TESTING_STUB_FLUTTER_API_H_

#include <memory>

#include "flutter/shell/platform/common/cpp/public/flutter_messenger.h"
#include "flutter/shell/platform/common/cpp/public/flutter_plugin_registrar.h"

namespace flutter {
namespace testing {

// Base class for a object that provides test implementations of the APIs in
// the headers in platform/common/cpp/public/.

// Linking this class into a test binary will provide dummy forwarding
// implementantions of that C API, so that the wrapper can be tested separately
// from the actual library.
class StubFlutterApi {
 public:
  // Used by the callers to simulate a result from the engine when sending a
  // message.
  bool message_engine_result = true;

  // Sets |stub| as the instance to which calls to the Flutter library C APIs
  // will be forwarded.
  static void SetTestStub(StubFlutterApi* stub);

  // Returns the current stub, as last set by SetTestFluttterStub.
  static StubFlutterApi* GetTestStub();

  virtual ~StubFlutterApi() {}

  // Called for FlutterDesktopRegistrarSetDestructionHandler.
  virtual void RegistrarSetDestructionHandler(
      FlutterDesktopOnRegistrarDestroyed callback) {}

  // Called for FlutterDesktopRegistrarEnableInputBlocking.
  virtual void RegistrarEnableInputBlocking(const char* channel) {}

  // Called for FlutterDesktopMessengerSend.
  virtual bool MessengerSend(const char* channel,
                             const uint8_t* message,
                             const size_t message_size) {
    return message_engine_result;
  }

  // Called for FlutterDesktopMessengerSendWithReply.
  virtual bool MessengerSendWithReply(const char* channel,
                                      const uint8_t* message,
                                      const size_t message_size,
                                      const FlutterDesktopBinaryReply reply,
                                      void* user_data) {
    return message_engine_result;
  }

  // Called for FlutterDesktopMessengerSendResponse.
  virtual void MessengerSendResponse(
      const FlutterDesktopMessageResponseHandle* handle,
      const uint8_t* data,
      size_t data_length) {}

  // Called for FlutterDesktopMessengerSetCallback.
  virtual void MessengerSetCallback(const char* channel,
                                    FlutterDesktopMessageCallback callback,
                                    void* user_data) {}
};

// A test helper that owns a stub implementation, making it the test stub for
// the lifetime of the object, then restoring the previous value.
class ScopedStubFlutterApi {
 public:
  // Calls SetTestFlutterStub with |stub|.
  ScopedStubFlutterApi(std::unique_ptr<StubFlutterApi> stub);

  // Restores the previous test stub.
  ~ScopedStubFlutterApi();

  StubFlutterApi* stub() { return stub_.get(); }

 private:
  std::unique_ptr<StubFlutterApi> stub_;
  // The previous stub.
  StubFlutterApi* previous_stub_;
};

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_COMMON_CPP_CLIENT_WRAPPER_TESTING_STUB_FLUTTER_API_H_
