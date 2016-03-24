// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <GLFW/glfw3.h>

#include "base/base_paths.h"
#include "base/command_line.h"
#include "base/files/file_path.h"
#include "base/logging.h"
#include "base/native_library.h"
#include "base/path_service.h"
#include "base/threading/thread_restrictions.h"
#include "ui/gl/gl_bindings.h"
#include "ui/gl/gl_context_stub_with_extensions.h"
#include "ui/gl/gl_gl_api_implementation.h"
#include "ui/gl/gl_implementation.h"
#include "ui/gl/gl_implementation_osmesa.h"
#include "ui/gl/gl_osmesa_api_implementation.h"

namespace gfx {

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

  switch (implementation) {
    case kGLImplementationOSMesaGL: {
      base::FilePath module_path;
      if (!PathService::Get(base::DIR_MODULE, &module_path)) {
        LOG(ERROR) << "PathService::Get failed.";
        return false;
      }

      base::FilePath library_path = module_path.Append("libosmesa.so");
      base::NativeLibrary library = LoadLibraryAndPrintError(library_path);
      if (!library)
        return false;

      GLGetProcAddressProc get_proc_address =
          reinterpret_cast<GLGetProcAddressProc>(
              base::GetFunctionPointerFromNativeLibrary(library,
                  "OSMesaGetProcAddress"));
      if (!get_proc_address) {
        LOG(ERROR) << "OSMesaGetProcAddress not found.";
        base::UnloadNativeLibrary(library);
        return false;
      }

      SetGLGetProcAddressProc(get_proc_address);
      AddGLNativeLibrary(library);
      SetGLImplementation(kGLImplementationOSMesaGL);

      InitializeStaticGLBindingsGL();
      InitializeStaticGLBindingsOSMESA();
      break;
    }
    case kGLImplementationDesktopGL:
    case kGLImplementationEGLGLES2: {
      SetGLGetProcAddressProc(
          reinterpret_cast<GLGetProcAddressProc>(glfwGetProcAddress));
      SetGLImplementation(implementation);

      InitializeStaticGLBindingsGL();
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
  InitializeDebugGLBindingsGL();
}

void ClearGLBindings() {
  ClearGLBindingsGL();
  SetGLImplementation(kGLImplementationNone);

  UnloadGLNativeLibraries();
}

bool GetGLWindowSystemBindingInfo(GLWindowSystemBindingInfo* info) {
  return false;
}

}  // namespace gfx
