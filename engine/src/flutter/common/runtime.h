// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

namespace flutter {

#define FLUTTER_JIT_RUNTIME                                \
  ((FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_DEBUG) || \
   (FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_JIT_RELEASE))

#define FLUTTER_RELEASE                                      \
  ((FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_RELEASE) || \
   (FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_JIT_RELEASE))

}  // namespace flutter
