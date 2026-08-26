// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_TESTING_MOCK_ISOLATE_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_TESTING_MOCK_ISOLATE_H_

#include "flutter/fml/macros.h"
#include "third_party/dart/runtime/include/dart_api.h"

namespace flutter {
namespace testing {

// Makes a Dart isolate current for the lifetime of this object.
//
// Tests need this to cover code that records the isolate it was called from
// using flutter::Isolate, which requires an isolate to be current. The isolate
// is only used as a target for these recordings; no Dart code is run in it.
class MockIsolate {
 public:
  MockIsolate();
  ~MockIsolate();

 private:
  Dart_Isolate isolate_ = nullptr;

  FML_DISALLOW_COPY_AND_ASSIGN(MockIsolate);
};

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_TESTING_MOCK_ISOLATE_H_
