// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gl/gl_context.h"

#include "base/logging.h"
#include "base/memory/ref_counted.h"
#include "base/trace_event/trace_event.h"
#include "ui/gl/gl_context_osmesa.h"

namespace gfx {

class GLShareGroup;

scoped_refptr<GLContext> GLContext::CreateGLContext(
    GLShareGroup* share_group,
    GLSurface* compatible_surface,
    GpuPreference gpu_preference) {
  TRACE_EVENT0("gpu", "GLContext::CreateGLContext");
  scoped_refptr<GLContext> context(new GLContextOSMesa(share_group));
  if (!context->Initialize(compatible_surface, gpu_preference))
    return NULL;

  return context;
}

}  // namespace gfx
