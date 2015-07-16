// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// These functions emulate GLES2 over command buffers.

#ifndef GPU_COMMAND_BUFFER_CLIENT_GLES2_LIB_H_
#define GPU_COMMAND_BUFFER_CLIENT_GLES2_LIB_H_

#include "gpu/command_buffer/client/gles2_c_lib_export.h"
#include "gpu/command_buffer/client/gles2_interface.h"

namespace gles2 {

typedef void (*GLES2FunctionPointer)(void);

struct NameToFunc {
  const char* name;
  gles2::GLES2FunctionPointer func;
};

// Initialize the GLES2 library.
GLES2_C_LIB_EXPORT void Initialize();

// Terminate the GLES2 library.
GLES2_C_LIB_EXPORT void Terminate();

// Get the current GL context.
GLES2_C_LIB_EXPORT gpu::gles2::GLES2Interface* GetGLContext();

// Set the current GL context.
GLES2_C_LIB_EXPORT void SetGLContext(gpu::gles2::GLES2Interface* impl);

GLES2_C_LIB_EXPORT GLES2FunctionPointer GetGLFunctionPointer(const char* name);

}  // namespace gles2

#endif  // GPU_COMMAND_BUFFER_CLIENT_GLES2_LIB_H_
