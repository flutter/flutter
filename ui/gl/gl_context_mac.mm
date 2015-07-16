// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/basictypes.h"
#include "base/logging.h"
#include "base/memory/scoped_ptr.h"
#include "base/trace_event/trace_event.h"
#include "ui/gl/gl_context_cgl.h"
#include "ui/gl/gl_context_stub.h"
#include "ui/gl/gl_implementation.h"
#include "ui/gl/gl_surface.h"
#include "ui/gl/gl_switches.h"

namespace gfx {

class GLShareGroup;

scoped_refptr<GLContext> GLContext::CreateGLContext(
    GLShareGroup* share_group,
    GLSurface* compatible_surface,
    GpuPreference gpu_preference) {
  TRACE_EVENT0("gpu", "GLContext::CreateGLContext");
  switch (GetGLImplementation()) {
    case kGLImplementationDesktopGL:
    case kGLImplementationAppleGL: {
      scoped_refptr<GLContext> context;
      // Note that with virtualization we might still be able to make current
      // a different onscreen surface with this context later. But we should
      // always be creating the context with an offscreen surface first.
      DCHECK(compatible_surface->IsOffscreen());
      context = new GLContextCGL(share_group);
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
