// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_DART_EMBEDDER_VMSERVICE_H_
#define MOJO_DART_EMBEDDER_VMSERVICE_H_

#include "include/dart_api.h"

namespace mojo {
namespace dart {

class VmService {
 public:
  static bool Setup(const char* server_ip, intptr_t server_port);

  // Error message if startup failed.
  static const char* GetErrorMessage();

  // HTTP server's IP.
  static const char* GetServerIP() {
    return &server_ip_[0];
  }

  // HTTP server's port.
  static intptr_t GetServerPort() {
    return server_port_;
  }

 private:
  static const intptr_t kServerIpStringBufferSize = 256;
  friend void ServiceIsolate_TriggerResourceLoad(Dart_NativeArguments args);
  friend void ServiceIsolate_NotifyServerState(Dart_NativeArguments args);

  static void SetServerIPAndPort(const char* ip, intptr_t port);
  static Dart_Handle GetSource(const char* name);
  static Dart_Handle LoadScript(const char* name);
  static Dart_Handle LoadSource(Dart_Handle library, const char* name);
  static Dart_Handle LoadResources(Dart_Handle library);
  static Dart_Handle LoadResource(Dart_Handle library, const char* name);
  static Dart_Handle LibraryTagHandler(Dart_LibraryTag tag, Dart_Handle library,
                                       Dart_Handle url);

  static const char* error_msg_;
  static char server_ip_[kServerIpStringBufferSize];
  static intptr_t server_port_;
};


}  // namespace dart
}  // namespace mojo

#endif  // MOJO_DART_EMBEDDER_VMSERVICE_H_
