// Copyright (c) 2009 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/client/gles2_lib.h"
#include <string.h>
#include "gpu/command_buffer/common/thread_local.h"

namespace gles2 {

// This is defined in gles2_c_lib_autogen.h
extern "C" {
extern const NameToFunc g_gles2_function_table[];
}

// TODO(kbr): the use of this anonymous namespace core dumps the
// linker on Mac OS X 10.6 when the symbol ordering file is used
// namespace {
static gpu::ThreadLocalKey g_gl_context_key;
// }  // namespace anonymous

void Initialize() {
  g_gl_context_key = gpu::ThreadLocalAlloc();
}

void Terminate() {
  gpu::ThreadLocalFree(g_gl_context_key);
  g_gl_context_key = 0;
}

gpu::gles2::GLES2Interface* GetGLContext() {
  return static_cast<gpu::gles2::GLES2Interface*>(
    gpu::ThreadLocalGetValue(g_gl_context_key));
}

void SetGLContext(gpu::gles2::GLES2Interface* context) {
  gpu::ThreadLocalSetValue(g_gl_context_key, context);
}

GLES2FunctionPointer GetGLFunctionPointer(const char* name) {
  for (const NameToFunc* named_function = g_gles2_function_table;
       named_function->name;
       ++named_function) {
    if (!strcmp(name, named_function->name)) {
      return named_function->func;
    }
  }
  return NULL;
}

}  // namespace gles2




