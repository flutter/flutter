// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_SKIA_GL_BINDINGS_SKIA_H_
#define MOJO_SKIA_GL_BINDINGS_SKIA_H_

#include "third_party/skia/include/core/SkRefCnt.h"
#include "third_party/skia/include/core/SkTypes.h"

struct GrGLInterface;

namespace mojo {
namespace skia {

// The GPU back-end for skia requires pointers to GL functions. This function
// returns a binding for skia-gpu to the Mojo C GL entry points.
sk_sp<GrGLInterface> CreateMojoSkiaGLBinding();

}  // namespace skia
}  // namespace mojo

#endif  // MOJO_SKIA_GL_BINDINGS_SKIA_H_
