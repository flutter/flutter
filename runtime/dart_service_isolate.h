// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_RUNTIME_DART_SERVICE_ISOLATE_H_
#define FLUTTER_RUNTIME_DART_SERVICE_ISOLATE_H_

#include <functional>
#include <mutex>
#include <set>
#include <string>

#include "flutter/fml/compiler_specific.h"
#include "flutter/fml/synchronization/thread_annotations.h"

#include "third_party/dart/runtime/include/dart_api.h"

namespace blink {

class DartServiceIsolate {
 public:
  using ObservatoryServerStateCallback =
      std::function<void(const std::string&)>;

  static bool Startup(std::string server_ip,
                      intptr_t server_port,
                      Dart_LibraryTagHandler embedder_tag_handler,
                      bool disable_origin_check,
                      char** error);

  static std::string GetObservatoryUri();

  using CallbackHandle = ptrdiff_t;

  // Returns a handle for the callback that can be used in
  // RemoveServerStatusCallback
  FML_WARN_UNUSED_RESULT
  static CallbackHandle AddServerStatusCallback(
      ObservatoryServerStateCallback callback);

  // Accepts the handle returned by AddServerStatusCallback
  static bool RemoveServerStatusCallback(CallbackHandle handle);

 private:
  // Native entries.
  static void NotifyServerState(Dart_NativeArguments args);
  static void Shutdown(Dart_NativeArguments args);

  static std::mutex callbacks_mutex_;
  static std::set<std::unique_ptr<ObservatoryServerStateCallback>> callbacks_
      FML_GUARDED_BY(callbacks_mutex_);
};

}  // namespace blink

#endif  // FLUTTER_RUNTIME_DART_SERVICE_ISOLATE_H_
