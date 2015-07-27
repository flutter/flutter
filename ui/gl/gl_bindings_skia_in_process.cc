// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


#include "ui/gl/gl_bindings_skia_in_process.h"

#include "base/logging.h"
#include "third_party/skia/include/gpu/gl/GrGLInterface.h"
#include "ui/gl/gl_bindings.h"
#include "ui/gl/gl_implementation.h"

namespace gfx {

const GrGLInterface* CreateInProcessSkiaGLBinding() {
  return GrGLCreateNativeInterface();
}

}  // namespace gfx
