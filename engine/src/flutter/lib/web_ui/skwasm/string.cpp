// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "export.h"

#include "third_party/skia/include/core/SkString.h"

SKWASM_EXPORT SkString* skString_allocate(size_t length) {
  return new SkString(length);
}

SKWASM_EXPORT char* skString_getData(SkString* string) {
  return string->data();
}

SKWASM_EXPORT void skString_free(SkString* string) {
  return delete string;
}
