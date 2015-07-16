// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_TOOLS_PACKAGER_SCOPE_H_
#define SKY_TOOLS_PACKAGER_SCOPE_H_

#include "base/basictypes.h"
#include "base/logging.h"
#include "dart/runtime/include/dart_api.h"

class DartIsolateScope {
 public:
  explicit DartIsolateScope(Dart_Isolate isolate) {
    CHECK(!Dart_CurrentIsolate());
    Dart_EnterIsolate(isolate);
  }
  ~DartIsolateScope() { Dart_ExitIsolate(); }

 private:
  DISALLOW_COPY_AND_ASSIGN(DartIsolateScope);
};

class DartApiScope {
 public:
  DartApiScope() { Dart_EnterScope(); }
  ~DartApiScope() { Dart_ExitScope(); }

 private:
  DISALLOW_COPY_AND_ASSIGN(DartApiScope);
};

#endif  // SKY_TOOLS_PACKAGER_SCOPE_H_
