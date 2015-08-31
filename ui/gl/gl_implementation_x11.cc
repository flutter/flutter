// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <vector>

#include "base/command_line.h"
#include "base/logging.h"
#include "base/threading/thread_restrictions.h"
#include "ui/gl/gl_bindings.h"
#include "ui/gl/gl_context_stub_with_extensions.h"
#include "ui/gl/gl_egl_api_implementation.h"
#include "ui/gl/gl_gl_api_implementation.h"
#include "ui/gl/gl_glx_api_implementation.h"
#include "ui/gl/gl_implementation.h"
#include "ui/gl/gl_implementation_osmesa.h"
#include "ui/gl/gl_osmesa_api_implementation.h"
#include "ui/gl/gl_switches.h"

namespace gfx {
namespace {

// TODO(piman): it should be Desktop GL marshalling from double to float. Today
// on native GLES, we do float->double->float.
void GL_BINDING_CALL MarshalClearDepthToClearDepthf(GLclampd depth) {
  glClearDepthf(static_cast<GLclampf>(depth));
}

void GL_BINDING_CALL MarshalDepthRangeToDepthRangef(GLclampd z_near,
                                                    GLclampd z_far) {
  glDepthRangef(static_cast<GLclampf>(z_near), static_cast<GLclampf>(z_far));
}

#if defined(OS_OPENBSD)
const char kGLLibraryName[] = "libGL.so";
#else
const char kGLLibraryName[] = "libGL.so.1";
#endif

const char kGLESv2LibraryName[] = "libGLESv2.so.2";
const char kEGLLibraryName[] = "libEGL.so.1";

}  // namespace

void GetAllowedGLImplementations(std::vector<GLImplementation>* impls) {
  impls->push_back(kGLImplementationDesktopGL);
  impls->push_back(kGLImplementationEGLGLES2);
  impls->push_back(kGLImplementationOSMesaGL);
}

bool InitializeStaticGLBindings(GLImplementation implementation) {
  // Prevent reinitialization with a different implementation. Once the gpu
  // unit tests have initialized with kGLImplementationMock, we don't want to
  // later switch to another GL implementation.
  DCHECK_EQ(kGLImplementationNone, GetGLImplementation());

  // Allow the main thread or another to initialize these bindings
  // after instituting restrictions on I/O. Going forward they will
  // likely be used in the browser process on most platforms. The
  // one-time initialization cost is small, between 2 and 5 ms.
  base::ThreadRestrictions::ScopedAllowIO allow_io;

  switch (implementation) {
    case kGLImplementationOSMesaGL:
      return InitializeStaticGLBindingsOSMesaGL();
    case kGLImplementationDesktopGL: {
      base::NativeLibrary library = NULL;
      const base::CommandLine* command_line =
          base::CommandLine::ForCurrentProcess();

      if (command_line->HasSwitch(switches::kTestGLLib))
        library = LoadLibraryAndPrintError(
            command_line->GetSwitchValueASCII(switches::kTestGLLib).c_str());

      if (!library) {
        library = LoadLibraryAndPrintError(kGLLibraryName);
      }

      if (!library)
        return false;

      GLGetProcAddressProc get_proc_address =
          reinterpret_cast<GLGetProcAddressProc>(
              base::GetFunctionPointerFromNativeLibrary(
                  library, "glXGetProcAddress"));
      if (!get_proc_address) {
        LOG(ERROR) << "glxGetProcAddress not found.";
        base::UnloadNativeLibrary(library);
        return false;
      }

      SetGLGetProcAddressProc(get_proc_address);
      AddGLNativeLibrary(library);
      SetGLImplementation(kGLImplementationDesktopGL);

      InitializeStaticGLBindingsGL();
      InitializeStaticGLBindingsGLX();
      break;
    }
    case kGLImplementationEGLGLES2: {
      base::NativeLibrary gles_library =
          LoadLibraryAndPrintError(kGLESv2LibraryName);
      if (!gles_library)
        return false;
      base::NativeLibrary egl_library =
          LoadLibraryAndPrintError(kEGLLibraryName);
      if (!egl_library) {
        base::UnloadNativeLibrary(gles_library);
        return false;
      }

      GLGetProcAddressProc get_proc_address =
          reinterpret_cast<GLGetProcAddressProc>(
              base::GetFunctionPointerFromNativeLibrary(
                  egl_library, "eglGetProcAddress"));
      if (!get_proc_address) {
        LOG(ERROR) << "eglGetProcAddress not found.";
        base::UnloadNativeLibrary(egl_library);
        base::UnloadNativeLibrary(gles_library);
        return false;
      }

      SetGLGetProcAddressProc(get_proc_address);
      AddGLNativeLibrary(egl_library);
      AddGLNativeLibrary(gles_library);
      SetGLImplementation(kGLImplementationEGLGLES2);

      InitializeStaticGLBindingsGL();
      InitializeStaticGLBindingsEGL();

      // These two functions take single precision float rather than double
      // precision float parameters in GLES.
      ::gfx::g_driver_gl.fn.glClearDepthFn = MarshalClearDepthToClearDepthf;
      ::gfx::g_driver_gl.fn.glDepthRangeFn = MarshalDepthRangeToDepthRangef;
      break;
    }
    case kGLImplementationMockGL: {
      SetGLImplementation(kGLImplementationMockGL);
      InitializeStaticGLBindingsGL();
      break;
    }
    default:
      return false;
  }


  return true;
}

bool InitializeDynamicGLBindings(GLImplementation implementation,
    GLContext* context) {
  switch (implementation) {
    case kGLImplementationOSMesaGL:
   case kGLImplementationDesktopGL:
    case kGLImplementationEGLGLES2:
      InitializeDynamicGLBindingsGL(context);
      break;
    case kGLImplementationMockGL:
      if (!context) {
        scoped_refptr<GLContextStubWithExtensions> mock_context(
            new GLContextStubWithExtensions());
        mock_context->SetGLVersionString("3.0");
        InitializeDynamicGLBindingsGL(mock_context.get());
      } else
        InitializeDynamicGLBindingsGL(context);
      break;
    default:
      return false;
  }

  return true;
}

void InitializeDebugGLBindings() {
  InitializeDebugGLBindingsEGL();
  InitializeDebugGLBindingsGL();
  InitializeDebugGLBindingsGLX();
  InitializeDebugGLBindingsOSMESA();
}

void ClearGLBindings() {
  ClearGLBindingsEGL();
  ClearGLBindingsGL();
  ClearGLBindingsGLX();
  ClearGLBindingsOSMESA();
  SetGLImplementation(kGLImplementationNone);

  UnloadGLNativeLibraries();
}

bool GetGLWindowSystemBindingInfo(GLWindowSystemBindingInfo* info) {
  switch (GetGLImplementation()) {
    case kGLImplementationDesktopGL:
      return GetGLWindowSystemBindingInfoGLX(info);
    case kGLImplementationEGLGLES2:
      return GetGLWindowSystemBindingInfoEGL(info);
    default:
      return false;
  }
  return false;
}

}  // namespace gfx
