// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_SCRIPT_DART_SERVICE_ISOLATE_H_
#define SKY_ENGINE_CORE_SCRIPT_DART_SERVICE_ISOLATE_H_

#include <string>

#include "include/dart_api.h"

namespace blink {

class DartServiceIsolate {
 public:
  static bool Bootstrap();

  static bool Startup(std::string server_ip,
                      intptr_t server_port,
                      Dart_LibraryTagHandler embedder_tag_handler,
                      bool running_precompiled,
                      bool disable_origin_check,
                      char** error);

  static int GetObservatoryPort();

 private:
  // Native entries.
  static void TriggerResourceLoad(Dart_NativeArguments args);
  static void NotifyServerState(Dart_NativeArguments args);
  static void Shutdown(Dart_NativeArguments args);

  // Script loading.
  static Dart_Handle GetSource(const char* name);
  static Dart_Handle LoadScript(const char* name);
  static Dart_Handle LoadSource(Dart_Handle library, const char* name);
  static Dart_Handle LibraryTagHandler(Dart_LibraryTag tag, Dart_Handle library,
                                       Dart_Handle url);

  // Observatory resource loading.
  static Dart_Handle LoadResources(Dart_Handle library);
  static Dart_Handle LoadResource(Dart_Handle library, const char* name);
};

}  // namespace blink

#endif  // SKY_ENGINE_CORE_SCRIPT_DART_SERVICE_ISOLATE_H_
