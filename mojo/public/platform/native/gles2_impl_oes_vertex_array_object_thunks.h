// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_PUBLIC_PLATFORM_NATIVE_GLES2_IMPL_OES_VERTEX_ARRAY_OBJECT_THUNKS_H_
#define MOJO_PUBLIC_PLATFORM_NATIVE_GLES2_IMPL_OES_VERTEX_ARRAY_OBJECT_THUNKS_H_

#include <stddef.h>

#include "mojo/public/c/gles2/oes_vertex_array_object.h"

// Specifies the frozen API for the Vertex Array Object Extension.
#pragma pack(push, 8)
struct MojoGLES2ImplOesVertexArrayObjectThunks {
  size_t size;  // Should be set to sizeof(*this).

#define VISIT_GL_CALL(Function, ReturnType, PARAMETERS, ARGUMENTS) \
  ReturnType(*Function) PARAMETERS;
#include "mojo/public/c/gles2/gles2_call_visitor_oes_vertex_array_object_autogen.h"
#undef VISIT_GL_CALL
};
#pragma pack(pop)

// Intended to be called from the embedder to get the embedder's implementation
// of GLES2.
inline MojoGLES2ImplOesVertexArrayObjectThunks
MojoMakeGLES2ImplOesVertexArrayObjectThunks() {
  MojoGLES2ImplOesVertexArrayObjectThunks
      gles2_impl_oes_vertex_array_object_thunks = {
          sizeof(MojoGLES2ImplOesVertexArrayObjectThunks),
#define VISIT_GL_CALL(Function, ReturnType, PARAMETERS, ARGUMENTS) gl##Function,
#include "mojo/public/c/gles2/gles2_call_visitor_oes_vertex_array_object_autogen.h"
#undef VISIT_GL_CALL
      };

  return gles2_impl_oes_vertex_array_object_thunks;
}

// Use this type for the function found by dynamically discovering it in
// a DSO linked with mojo_system.
// The contents of |gles2_impl_oes_vertex_array_object_thunks| are copied.
typedef size_t (*MojoSetGLES2ImplOesVertexArrayObjectThunksFn)(
    const MojoGLES2ImplOesVertexArrayObjectThunks* thunks);

#endif  // MOJO_PUBLIC_PLATFORM_NATIVE_GLES2_IMPL_OES_VERTEX_ARRAY_OBJECT_THUNKS_H_
