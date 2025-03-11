// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/logging.h"
#include "third_party/dart/runtime/include/dart_api.h"

#ifndef FLUTTER_SHELL_PLATFORM_COMMON_ISOLATE_SCOPE_H_
#define FLUTTER_SHELL_PLATFORM_COMMON_ISOLATE_SCOPE_H_

namespace flutter {

class Isolate {
 public:
  Isolate() : isolate_(Dart_CurrentIsolate()) {
    FML_DCHECK(isolate_ != nullptr);
  }
  ~Isolate() = default;

 private:
  friend class IsolateScope;
  Dart_Isolate isolate_;
};

class IsolateScope {
 public:
  explicit IsolateScope(const Isolate& isolate) {
    if (Dart_CurrentIsolate() == nullptr) {
      Dart_EnterIsolate(isolate.isolate_);
      should_exit_isolate_ = true;
    } else {
      FML_DCHECK(Dart_CurrentIsolate() == isolate.isolate_);
    }
  };

  ~IsolateScope() {
    if (should_exit_isolate_) {
      Dart_ExitIsolate();
    }
  }

 private:
  bool should_exit_isolate_ = false;
  IsolateScope() = delete;
  IsolateScope(IsolateScope const&) = delete;
};
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_COMMON_ISOLATE_SCOPE_H_
