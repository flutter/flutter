// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TONIC_DART_MICROTASK_QUEUE_H_
#define FLUTTER_TONIC_DART_MICROTASK_QUEUE_H_

#include "dart/runtime/include/dart_api.h"

namespace blink {

class DartMicrotaskQueue {
 public:
  static void ScheduleMicrotask(Dart_Handle callback);
  static void RunMicrotasks();
};

}  // namespace blink

#endif  // FLUTTER_TONIC_DART_MICROTASK_QUEUE_H_
