// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_IO_DART_IO_H_
#define FLUTTER_LIB_IO_DART_IO_H_

#include <cstdint>

#include "lib/fxl/macros.h"

namespace blink {

class DartIO {
 public:
  static void InitForIsolate();
  static bool EntropySource(uint8_t* buffer, intptr_t length);

 private:
  FXL_DISALLOW_IMPLICIT_CONSTRUCTORS(DartIO);
};

}  // namespace blink

#endif  // FLUTTER_LIB_IO_DART_IO_H_
