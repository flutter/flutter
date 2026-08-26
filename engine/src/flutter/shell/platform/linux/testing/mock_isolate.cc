// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/testing/mock_isolate.h"

#include <glib.h>

#include "gtest/gtest.h"

// The Dart snapshot linked into this binary. Contains the core libraries the
// Dart VM needs to make an isolate.
extern "C" {
extern const uint8_t kDartSnapshotData[];
extern const uint8_t kDartSnapshotText[];
}

namespace flutter {
namespace testing {

namespace {

bool entropy_source(uint8_t* buffer, intptr_t length) {
  for (intptr_t i = 0; i < length; i++) {
    buffer[i] = g_random_int_range(0, 256);
  }
  return true;
}

// The Dart VM can only be initialized once per process.
void ensure_vm_initialized() {
  static gsize initialized = 0;
  if (!g_once_init_enter(&initialized)) {
    return;
  }

  char* flags_error = Dart_SetVMFlags(0, nullptr);
  EXPECT_EQ(flags_error, nullptr) << flags_error;

  Dart_InitializeParams params = {};
  params.version = DART_INITIALIZE_PARAMS_CURRENT_VERSION;
  params.entropy_source = entropy_source;
  char* error = Dart_Initialize(&params);
  EXPECT_EQ(error, nullptr) << error;

  g_once_init_leave(&initialized, 1);
}

}  // namespace

MockIsolate::MockIsolate() {
  ensure_vm_initialized();

  Dart_IsolateFlags flags = {};
  Dart_IsolateFlagsInitialize(&flags);
  char* error = nullptr;
  isolate_ = Dart_CreateIsolateGroup("mock", "main", kDartSnapshotData,
                                     kDartSnapshotText, &flags, nullptr,
                                     nullptr, &error);
  EXPECT_NE(isolate_, nullptr) << error;
}

MockIsolate::~MockIsolate() {
  if (isolate_ == nullptr) {
    return;
  }
  // Creating an isolate makes it current, so this shuts down isolate_.
  Dart_ShutdownIsolate();
}

}  // namespace testing
}  // namespace flutter
