// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gl/gl_context.h"

#include "base/logging.h"
#include "base/memory/scoped_ptr.h"
#include "base/trace_event/trace_event.h"
#include "ui/gl/gl_bindings.h"
#include "ui/gl/gl_context_egl.h"
#include "ui/gl/gl_context_glx.h"
#include "ui/gl/gl_context_osmesa.h"
#include "ui/gl/gl_context_stub.h"
#include "ui/gl/gl_implementation.h"
#include "ui/gl/gl_surface_egl.h"
#include "ui/gl/gl_surface_glx.h"
#include "ui/gl/gl_surface_osmesa.h"
#include "ui/gl/gl_surface_stub.h"

namespace gfx {

class GLShareGroup;

scoped_refptr<GLContext> GLContext::CreateGLContext(
    GLShareGroup* share_group,
    GLSurface* compatible_surface,
    GpuPreference gpu_preference) {
  TRACE_EVENT0("gpu", "GLContext::CreateGLContext");
  switch (GetGLImplementation()) {
    case kGLImplementationOSMesaGL: {
      scoped_refptr<GLContext> context(new GLContextOSMesa(share_group));
      if (!context->Initialize(compatible_surface, gpu_preference))
        return NULL;

      return context;
    }
    case kGLImplementationDesktopGL: {
      scoped_refptr<GLContext> context(new GLContextGLX(share_group));
      if (!context->Initialize(compatible_surface, gpu_preference))
        return NULL;

      return context;
    }
    case kGLImplementationEGLGLES2: {
      scoped_refptr<GLContext> context(new GLContextEGL(share_group));
      if (!context->Initialize(compatible_surface, gpu_preference))
        return NULL;

      return context;
    }
    case kGLImplementationMockGL:
      return new GLContextStub;
    default:
      NOTREACHED();
      return NULL;
  }
}

}  // namespace gfx
