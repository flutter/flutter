// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GL_GL_IMPLEMENTATION_OSMESA_
#define UI_GL_GL_IMPLEMENTATION_OSMESA_

#include "base/files/file_path.h"
#include "base/native_library.h"

namespace gfx {

bool InitializeStaticGLBindingsOSMesaGL();
base::NativeLibrary LoadLibraryAndPrintError(const char* filename);
base::NativeLibrary LoadLibraryAndPrintError(const base::FilePath& filename);

}  // namespace gfx

#endif  // UI_GL_GL_IMPLEMENTATION_OSMESA_
