// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/tonic/dart_isolate_scope.h"

namespace blink {

DartIsolateScope::DartIsolateScope(Dart_Isolate isolate) {
  isolate_ = isolate;
  previous_ = Dart_CurrentIsolate();
  if (previous_ == isolate_)
    return;
  if (previous_)
    Dart_ExitIsolate();
  Dart_EnterIsolate(isolate_);
}

DartIsolateScope::~DartIsolateScope() {
  DCHECK(Dart_CurrentIsolate() == isolate_);
  if (previous_ == isolate_)
    return;
  Dart_ExitIsolate();
  if (previous_)
    Dart_EnterIsolate(previous_);
}

}  // namespace blink
