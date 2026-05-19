// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
#include "dart_dl.h"

#include "flutter/fml/logging.h"
#include "include/dart_api_dl.h"

int zircon_dart_dl_initialize(void* initialize_api_dl_data) {
  if (Dart_InitializeApiDL(initialize_api_dl_data) != 0) {
    FML_LOG(ERROR) << "Failed to initialise Dart VM API";
    return -1;
  }
  // Check symbols used are present
  if (Dart_NewFinalizableHandle_DL == NULL) {
    FML_LOG(ERROR) << "Unable to find Dart API finalizer symbols.";
    return -1;
  }
  return 1;
}
