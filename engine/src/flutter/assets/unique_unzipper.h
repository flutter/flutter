// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_ASSETS_UNIQUE_UNZIPPER_H_
#define FLUTTER_ASSETS_UNIQUE_UNZIPPER_H_

#include "lib/ftl/memory/unique_object.h"

namespace blink {

struct UniqueUnzipperTraits {
  static inline void* InvalidValue() { return nullptr; }
  static inline bool IsValid(void* value) { return value != InvalidValue(); }
  static void Free(void* file);
};

using UniqueUnzipper = ftl::UniqueObject<void*, UniqueUnzipperTraits>;

}  // namespace blink

#endif  // FLUTTER_ASSETS_UNIQUE_UNZIPPER_H_
