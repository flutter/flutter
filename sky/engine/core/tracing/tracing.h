// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_TRACING_TRACING_H_
#define SKY_ENGINE_CORE_TRACING_TRACING_H_

#include "sky/engine/tonic/dart_library_natives.h"

namespace blink {

class Tracing {
 public:
   static void RegisterNatives(DartLibraryNatives* natives);
};

}  // namespace blink

#endif  // SKY_ENGINE_CORE_TRACING_TRACING_H_
