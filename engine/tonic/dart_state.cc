// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/tonic/dart_state.h"

#include "sky/engine/tonic/dart_class_library.h"
#include "sky/engine/tonic/dart_string_cache.h"
#include "sky/engine/wtf/PassOwnPtr.h"

namespace blink {

DartState::Scope::Scope(DartState* dart_state) {
}

DartState::Scope::~Scope() {
}

DartState::DartState()
    : isolate_(NULL),
      class_library_(adoptPtr(new DartClassLibrary)),
      string_cache_(adoptPtr(new DartStringCache)),
      weak_factory_(this) {
}

DartState::~DartState() {
}

DartState* DartState::From(Dart_Isolate isolate) {
  return static_cast<DartState*>(Dart_IsolateData(isolate));
}

DartState* DartState::Current() {
  return static_cast<DartState*>(Dart_CurrentIsolateData());
}

base::WeakPtr<DartState> DartState::GetWeakPtr() {
  return weak_factory_.GetWeakPtr();
}

}  // namespace blink
