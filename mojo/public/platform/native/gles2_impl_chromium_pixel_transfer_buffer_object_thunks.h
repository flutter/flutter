// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_PUBLIC_PLATFORM_NATIVE_GLES2_IMPL_CHROMIUM_PIXEL_TRANSFER_BUFFER_OBJECT_THUNKS_H_
#define MOJO_PUBLIC_PLATFORM_NATIVE_GLES2_IMPL_CHROMIUM_PIXEL_TRANSFER_BUFFER_OBJECT_THUNKS_H_

#include <stddef.h>

#include "mojo/public/c/gles2/chromium_pixel_transfer_buffer_object.h"

// Specifies the frozen API for the GLES2 CHROMIUM_pixel_transfer_buffer_object extension.
#pragma pack(push, 8)
struct MojoGLES2ImplChromiumPixelTransferBufferObjectThunks {
  size_t size;  // Should be set to sizeof(*this).

#define VISIT_GL_CALL(Function, ReturnType, PARAMETERS, ARGUMENTS) \
  ReturnType(*Function) PARAMETERS;
#include "mojo/public/c/gles2/gles2_call_visitor_chromium_pixel_transfer_buffer_object_autogen.h"
#undef VISIT_GL_CALL
};
#pragma pack(pop)

// Intended to be called from the embedder to get the embedder's implementation
// of GLES2.
inline MojoGLES2ImplChromiumPixelTransferBufferObjectThunks
MojoMakeGLES2ImplChromiumPixelTransferBufferObjectThunks() {
  MojoGLES2ImplChromiumPixelTransferBufferObjectThunks gles2_impl_chromium_pixel_transfer_buffer_object_thunks = {
      sizeof(MojoGLES2ImplChromiumPixelTransferBufferObjectThunks),
#define VISIT_GL_CALL(Function, ReturnType, PARAMETERS, ARGUMENTS) gl##Function,
#include "mojo/public/c/gles2/gles2_call_visitor_chromium_pixel_transfer_buffer_object_autogen.h"
#undef VISIT_GL_CALL
  };

  return gles2_impl_chromium_pixel_transfer_buffer_object_thunks;
}

// Use this type for the function found by dynamically discovering it in
// a DSO linked with mojo_system.
// The contents of |gles2_impl_chromium_pixel_transfer_buffer_object_thunks| are copied.
typedef size_t (*MojoSetGLES2ImplChromiumPixelTransferBufferObjectThunksFn)(
    const MojoGLES2ImplChromiumPixelTransferBufferObjectThunks* thunks);

#endif  // MOJO_PUBLIC_PLATFORM_NATIVE_GLES2_IMPL_CHROMIUM_PIXEL_TRANSFER_BUFFER_OBJECT_THUNKS_H_
