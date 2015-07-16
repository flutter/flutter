// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_SCRIPT_DART_INIT_H_
#define SKY_ENGINE_CORE_SCRIPT_DART_INIT_H_

#include "dart/runtime/include/dart_api.h"

namespace blink {

extern const uint8_t* kDartVmIsolateSnapshotBuffer;
extern const uint8_t* kDartIsolateSnapshotBuffer;

void InitDartVM();
Dart_Handle DartLibraryTagHandler(Dart_LibraryTag tag,
                                  Dart_Handle library,
                                  Dart_Handle url);
void EnsureHandleWatcherStarted();

}

#endif // SKY_ENGINE_CORE_SCRIPT_DART_INIT_H_
