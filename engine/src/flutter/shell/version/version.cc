// Copyright 2018 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/version/version.h"

namespace shell {

const char* GetFlutterEngineVersion() {
  return SHELL_FLUTTER_ENGINE_VERSION;
}

const char* GetSkiaVersion() {
  return SHELL_SKIA_VERSION;
}

const char* GetDartVersion() {
  return SHELL_DART_VERSION;
}

}  // namespace shell
