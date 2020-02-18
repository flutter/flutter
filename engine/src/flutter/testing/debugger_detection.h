// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TESTING_DEBUGGER_DETECTION_H_
#define FLUTTER_TESTING_DEBUGGER_DETECTION_H_

#include "flutter/fml/macros.h"

namespace flutter {
namespace testing {

enum class DebuggerStatus {
  kDontKnow,
  kAttached,
};

DebuggerStatus GetDebuggerStatus();

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_TESTING_DEBUGGER_DETECTION_H_
