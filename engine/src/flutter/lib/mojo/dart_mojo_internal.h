// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_MOJO_DART_MOJO_INTERNAL_H_
#define FLUTTER_LIB_MOJO_DART_MOJO_INTERNAL_H_

#include "lib/ftl/macros.h"
#include "mojo/public/cpp/system/handle.h"

namespace blink {

class DartMojoInternal {
 public:
  static void InitForIsolate();

  static void SetHandleWatcherProducerHandle(MojoHandle handle);

 private:
  FTL_DISALLOW_IMPLICIT_CONSTRUCTORS(DartMojoInternal);
};

}  // namespace blink

#endif  // FLUTTER_LIB_MOJO_DART_MOJO_INTERNAL_H_
