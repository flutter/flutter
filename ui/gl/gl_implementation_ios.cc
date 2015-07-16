// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/base_paths.h"
#include "base/command_line.h"
#include "base/files/file_path.h"
#include "base/logging.h"
#include "base/native_library.h"
#include "ui/gl/gl_bindings.h"
#include "ui/gl/gl_gl_api_implementation.h"
#include "ui/gl/gl_implementation.h"
#include <dlfcn.h>

namespace gfx {

static const char* OpenGLESFrameworkPath =
    "/System/Library/Framework/OpenGLES.framework/OpenGLES";

static void* OpenGLESLibraryHandle(void) {
  static void* library_handle = NULL;
  if (library_handle == NULL) {
    library_handle = dlopen(OpenGLESFrameworkPath, RTLD_NOW);
  }
  DCHECK(library_handle);
  return library_handle;
}

static void* OpenGLESGetProcAddress(const char* name) {
  return dlsym(OpenGLESLibraryHandle(), name);
}

void GetAllowedGLImplementations(std::vector<GLImplementation>* impls) {
  impls->push_back(kGLImplementationAppleGL);
}

bool InitializeStaticGLBindings(GLImplementation implementation) {
  DCHECK_EQ(kGLImplementationNone, GetGLImplementation());

  switch (implementation) {
    case kGLImplementationAppleGL:
      SetGLGetProcAddressProc(&OpenGLESGetProcAddress);
      SetGLImplementation(kGLImplementationAppleGL);
      InitializeStaticGLBindingsGL();

      return true;
    default:
      NOTIMPLEMENTED() << "InitializeStaticGLBindings on iOS";
      return false;
  }

  return false;
}

bool InitializeDynamicGLBindings(GLImplementation implementation,
                                 GLContext* context) {
  switch (implementation) {
    case kGLImplementationAppleGL:
      InitializeDynamicGLBindingsGL(context);
      break;
    default:
      NOTREACHED() << "InitializeDynamicGLBindings on iOS";
      return false;
  }
  return true;
}

void InitializeDebugGLBindings() {
  DCHECK(false);
}

void ClearGLBindings() {
  DCHECK(false);
}

bool GetGLWindowSystemBindingInfo(GLWindowSystemBindingInfo* info) {
  DCHECK(false);
  return false;
}

}  // namespace gfx
