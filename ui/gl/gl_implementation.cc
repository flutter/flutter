// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gl/gl_implementation.h"

#include <algorithm>
#include <string>

#include "base/at_exit.h"
#include "base/command_line.h"
#include "base/logging.h"
#include "ui/gl/gl_bindings.h"
#include "ui/gl/gl_gl_api_implementation.h"

namespace gfx {

namespace {

const struct {
  const char* name;
  GLImplementation implementation;
} kGLImplementationNamePairs[] = {
  { kGLImplementationDesktopName, kGLImplementationDesktopGL },
  { kGLImplementationOSMesaName, kGLImplementationOSMesaGL },
  { kGLImplementationEGLName, kGLImplementationEGLGLES2 },
  { kGLImplementationMockName, kGLImplementationMockGL }
};

typedef std::vector<base::NativeLibrary> LibraryArray;

GLImplementation g_gl_implementation = kGLImplementationNone;
LibraryArray* g_libraries;
GLGetProcAddressProc g_get_proc_address;

void CleanupNativeLibraries(void* unused) {
  if (g_libraries) {
    // We do not call base::UnloadNativeLibrary() for these libraries as
    // unloading libGL without closing X display is not allowed. See
    // crbug.com/250813 for details.
    delete g_libraries;
    g_libraries = NULL;
  }
}

}

base::ThreadLocalPointer<GLApi>* g_current_gl_context_tls = NULL;
OSMESAApi* g_current_osmesa_context;

#if defined(USE_X11)

EGLApi* g_current_egl_context;
GLXApi* g_current_glx_context;

#elif defined(USE_OZONE)

EGLApi* g_current_egl_context;

#elif defined(OS_ANDROID)

EGLApi* g_current_egl_context;

#endif

GLImplementation GetNamedGLImplementation(const std::string& name) {
  for (size_t i = 0; i < arraysize(kGLImplementationNamePairs); ++i) {
    if (name == kGLImplementationNamePairs[i].name)
      return kGLImplementationNamePairs[i].implementation;
  }

  return kGLImplementationNone;
}

const char* GetGLImplementationName(GLImplementation implementation) {
  for (size_t i = 0; i < arraysize(kGLImplementationNamePairs); ++i) {
    if (implementation == kGLImplementationNamePairs[i].implementation)
      return kGLImplementationNamePairs[i].name;
  }

  return "unknown";
}

void SetGLImplementation(GLImplementation implementation) {
  g_gl_implementation = implementation;
}

GLImplementation GetGLImplementation() {
  return g_gl_implementation;
}

bool HasDesktopGLFeatures() {
  return kGLImplementationDesktopGL == g_gl_implementation ||
         kGLImplementationOSMesaGL == g_gl_implementation ||
         kGLImplementationAppleGL == g_gl_implementation;
}

void AddGLNativeLibrary(base::NativeLibrary library) {
  DCHECK(library);

  if (!g_libraries) {
    g_libraries = new LibraryArray;
    base::AtExitManager::RegisterCallback(CleanupNativeLibraries, NULL);
  }

  g_libraries->push_back(library);
}

void UnloadGLNativeLibraries() {
  CleanupNativeLibraries(NULL);
}

void SetGLGetProcAddressProc(GLGetProcAddressProc proc) {
  DCHECK(proc);
  g_get_proc_address = proc;
}

void* GetGLProcAddress(const char* name) {
  DCHECK(g_gl_implementation != kGLImplementationNone);

  if (g_libraries) {
    for (size_t i = 0; i < g_libraries->size(); ++i) {
      void* proc = base::GetFunctionPointerFromNativeLibrary((*g_libraries)[i],
                                                             name);
      if (proc)
        return proc;
    }
  }
  if (g_get_proc_address) {
    void* proc = g_get_proc_address(name);
    if (proc)
      return proc;
  }

  return NULL;
}

void InitializeNullDrawGLBindings() {
  // This is platform independent, so it does not need to live in a platform
  // specific implementation file.
  InitializeNullDrawGLBindingsGL();
}

bool HasInitializedNullDrawGLBindings() {
  return HasInitializedNullDrawGLBindingsGL();
}

DisableNullDrawGLBindings::DisableNullDrawGLBindings() {
  initial_enabled_ = SetNullDrawGLBindingsEnabledGL(false);
}

DisableNullDrawGLBindings::~DisableNullDrawGLBindings() {
  SetNullDrawGLBindingsEnabledGL(initial_enabled_);
}

GLWindowSystemBindingInfo::GLWindowSystemBindingInfo()
    : direct_rendering(true) {}

}  // namespace gfx
