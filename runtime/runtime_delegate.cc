// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/runtime/runtime_delegate.h"

namespace blink {

RuntimeDelegate::~RuntimeDelegate() {}

void RuntimeDelegate::DidCreateMainIsolate(Dart_Isolate isolate) {}

void RuntimeDelegate::DidCreateSecondaryIsolate(Dart_Isolate isolate) {}

void RuntimeDelegate::DidShutdownMainIsolate() {}

}  // namespace blink
