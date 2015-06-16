// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/tools/packager/vm.h"

#include "base/logging.h"
#include "sky/tools/packager/loader.h"
#include "sky/tools/packager/logging.h"

namespace blink {
extern const uint8_t* kDartVmIsolateSnapshotBuffer;
extern const uint8_t* kDartIsolateSnapshotBuffer;
}

void InitDartVM() {
  int argc = 0;
  const char** argv = nullptr;

  CHECK(Dart_SetVMFlags(argc, argv));
  CHECK(Dart_Initialize(blink::kDartVmIsolateSnapshotBuffer, nullptr, nullptr,
                        nullptr, nullptr, nullptr, nullptr, nullptr, nullptr,
                        nullptr));
}

Dart_Isolate CreateDartIsolate() {
  CHECK(blink::kDartIsolateSnapshotBuffer);
  char* error = nullptr;
  Dart_Isolate isolate = Dart_CreateIsolate("http://example.com", "main",
                                            blink::kDartIsolateSnapshotBuffer,
                                            nullptr, nullptr, &error);

  CHECK(isolate) << error;
  CHECK(!LogIfError(Dart_SetLibraryTagHandler(HandleLibraryTag)));
  LoadSkyInternals();

  Dart_ExitIsolate();
  return isolate;
}
