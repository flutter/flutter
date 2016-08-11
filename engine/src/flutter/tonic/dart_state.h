// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TONIC_DART_STATE_H_
#define FLUTTER_TONIC_DART_STATE_H_

#include "dart/runtime/include/dart_api.h"
#include "lib/tonic/dart_persistent_value.h"
#include "lib/tonic/dart_state.h"
#include "lib/tonic/scopes/dart_api_scope.h"
#include "lib/tonic/scopes/dart_isolate_scope.h"

namespace blink {

class DartState : public tonic::DartState {
 public:
  DartState();
  virtual ~DartState();

  static DartState* From(Dart_Isolate isolate);
  static DartState* Current();

 protected:
  FTL_DISALLOW_COPY_AND_ASSIGN(DartState);
};

}  // namespace blink

#endif  // FLUTTER_TONIC_DART_STATE_H_
