// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/tools/sky_snapshot/vm.h"

#include "base/logging.h"
#include "sky/tools/sky_snapshot/loader.h"
#include "sky/tools/sky_snapshot/logging.h"

#include <iostream>

extern "C" {
extern void* kDartVmIsolateSnapshotBuffer;
extern void* kDartIsolateSnapshotBuffer;
}

static const char* kDartArgs[] = {
    "--enable_mirrors=false",
    "--load_deferred_eagerly=true",
    "--conditional_directives",
    // TODO(chinmaygarde): The experimental interpreter for iOS device targets
    // does not support all these flags. The build process uses its own version
    // of this snapshotter. Till support for all these flags is added, make
    // sure the snapshotter does not error out on unrecognized flags.
    "--ignore-unrecognized-flags",
};

void InitDartVM() {
  CHECK(Dart_SetVMFlags(arraysize(kDartArgs), kDartArgs));
  char* init_message = Dart_Initialize(
      reinterpret_cast<uint8_t*>(&kDartVmIsolateSnapshotBuffer), nullptr,
      nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, nullptr,
      nullptr, nullptr, nullptr, nullptr);
  if (init_message != nullptr) {
    std::cerr << "Dart_Initialize Error: " << init_message << std::endl;
    free(init_message);
    CHECK(false);
  }
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
