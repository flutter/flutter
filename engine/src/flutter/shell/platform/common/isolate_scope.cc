// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/common/isolate_scope.h"

namespace flutter {

Isolate Isolate::Current() {
  Dart_Isolate isolate = Dart_CurrentIsolate();
  return Isolate(isolate);
}

IsolateScope::IsolateScope(const Isolate& isolate) {
  isolate_ = isolate.isolate_;
  previous_ = Dart_CurrentIsolate();
  if (previous_ == isolate_) {
    return;
  }
  if (previous_) {
    Dart_ExitIsolate();
  }
  Dart_EnterIsolate(isolate_);
};

IsolateScope::~IsolateScope() {
  Dart_Isolate current = Dart_CurrentIsolate();
  FML_DCHECK(!current || current == isolate_);
  if (previous_ == isolate_) {
    return;
  }
  if (current) {
    Dart_ExitIsolate();
  }
  if (previous_) {
    Dart_EnterIsolate(previous_);
  }
}

}  // namespace flutter
