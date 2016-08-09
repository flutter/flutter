// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/tonic/dart_state.h"

#include "lib/tonic/converter/dart_converter.h"
#include "flutter/tonic/dart_library_loader.h"

namespace blink {

DartState::DartState()
    : library_loader_(new DartLibraryLoader(this)) {}

DartState::~DartState() {}

DartState* DartState::From(Dart_Isolate isolate) {
  return static_cast<DartState*>(tonic::DartState::From(isolate));
}

DartState* DartState::Current() {
  return static_cast<DartState*>(tonic::DartState::Current());
}

}  // namespace blink
