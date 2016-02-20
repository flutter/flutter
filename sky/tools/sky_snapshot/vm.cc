// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/tools/sky_snapshot/vm.h"

#include "base/logging.h"
#include "sky/tools/sky_snapshot/loader.h"
#include "sky/tools/sky_snapshot/logging.h"

extern "C" {
extern void* kDartVmIsolateSnapshotBuffer;
extern void* kDartIsolateSnapshotBuffer;
}

static const char* kDartArgs[] = {
    "--enable_mirrors=false",
    "--load_deferred_eagerly=true",
};

void InitDartVM() {
  CHECK(Dart_SetVMFlags(arraysize(kDartArgs), kDartArgs));
  CHECK(Dart_Initialize(
            reinterpret_cast<uint8_t*>(&kDartVmIsolateSnapshotBuffer), nullptr,
            nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, nullptr,
            nullptr, nullptr, nullptr, nullptr) == nullptr);
}

Dart_Isolate CreateDartIsolate() {
  CHECK(kDartIsolateSnapshotBuffer);
  char* error = nullptr;
  Dart_Isolate isolate = Dart_CreateIsolate(
      "dart:snapshot", "main",
      reinterpret_cast<uint8_t*>(&kDartIsolateSnapshotBuffer), nullptr, nullptr,
      &error);

  CHECK(isolate) << error;
  CHECK(!LogIfError(Dart_SetLibraryTagHandler(HandleLibraryTag)));

  Dart_ExitIsolate();
  return isolate;
}
