// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TONIC_DART_IO_H_
#define FLUTTER_TONIC_DART_IO_H_

#include "base/macros.h"

namespace blink {

class DartIO {
 public:
  static void InitForIsolate();

 private:
  DISALLOW_IMPLICIT_CONSTRUCTORS(DartIO);
};

}  // namespace blink

#endif  // FLUTTER_TONIC_DART_IO_H_
