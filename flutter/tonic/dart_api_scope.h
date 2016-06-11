// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TONIC_DART_API_SCOPE_H_
#define FLUTTER_TONIC_DART_API_SCOPE_H_

#include "base/macros.h"
#include "dart/runtime/include/dart_api.h"

namespace blink {

class DartApiScope {
 public:
  DartApiScope() { Dart_EnterScope(); }
  ~DartApiScope() { Dart_ExitScope(); }

 private:
  DISALLOW_COPY_AND_ASSIGN(DartApiScope);
};

}  // namespace blink

#endif  // FLUTTER_TONIC_DART_API_SCOPE_H_
