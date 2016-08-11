// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/tonic/dart_state.h"

namespace blink {

DartState::DartState() {}

DartState::~DartState() {}

DartState* DartState::From(Dart_Isolate isolate) {
  return static_cast<DartState*>(tonic::DartState::From(isolate));
}

DartState* DartState::Current() {
  return static_cast<DartState*>(tonic::DartState::Current());
}

}  // namespace blink
