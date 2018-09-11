// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_RUNTIME_DART_SERVICE_ISOLATE_H_
#define FLUTTER_RUNTIME_DART_SERVICE_ISOLATE_H_

#include <string>

#include "third_party/dart/runtime/include/dart_api.h"

namespace blink {

class DartServiceIsolate {
 public:
  static bool Startup(std::string server_ip,
                      intptr_t server_port,
                      Dart_LibraryTagHandler embedder_tag_handler,
                      bool disable_origin_check,
                      char** error);

  static std::string GetObservatoryUri();

 private:
  // Native entries.
  static void NotifyServerState(Dart_NativeArguments args);
  static void Shutdown(Dart_NativeArguments args);
};

}  // namespace blink

#endif  // FLUTTER_RUNTIME_DART_SERVICE_ISOLATE_H_
