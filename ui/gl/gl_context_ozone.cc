// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gl/gl_context.h"

#include "base/logging.h"
#include "base/memory/ref_counted.h"
#include "base/sys_info.h"
#include "ui/gl/gl_bindings.h"
#include "ui/gl/gl_context_egl.h"
#include "ui/gl/gl_context_osmesa.h"
#include "ui/gl/gl_context_stub.h"
#include "ui/gl/gl_implementation.h"
#include "ui/gl/gl_surface.h"

namespace gfx {

// static
scoped_refptr<GLContext> GLContext::CreateGLContext(
    GLShareGroup* share_group,
    GLSurface* compatible_surface,
    GpuPreference gpu_preference) {

  switch (GetGLImplementation()) {
    case kGLImplementationMockGL:
      return scoped_refptr<GLContext>(new GLContextStub());
    case kGLImplementationOSMesaGL: {
      scoped_refptr<GLContext> context(new GLContextOSMesa(share_group));
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
    default:
      NOTREACHED();
      return NULL;
  }
}

}  // namespace gfx

