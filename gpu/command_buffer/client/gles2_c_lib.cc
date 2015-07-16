// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// These functions emulate GLES2 over command buffers for C.

#include <assert.h>
#include <stdlib.h>
#include "gpu/command_buffer/client/gles2_lib.h"

#ifndef GL_GLEXT_PROTOTYPES
#define GL_GLEXT_PROTOTYPES
#endif
#include <GLES2/gl2ext.h>
#include <GLES2/gl2extchromium.h>

extern "C" {
// Include the auto-generated part of this file. We split this because it means
// we can easily edit the non-auto generated parts right here in this file
// instead of having to edit some template or the code generator.
#include "gpu/command_buffer/client/gles2_c_lib_autogen.h"
}  // extern "C"


