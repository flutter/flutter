// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/base_paths.h"
#include "base/command_line.h"
#include "base/files/file_path.h"
#include "base/logging.h"
#include "base/mac/foundation_util.h"
#include "base/native_library.h"
#include "base/path_service.h"
#include "base/threading/thread_restrictions.h"
#include "ui/gl/gl_bindings.h"
#include "ui/gl/gl_context_stub_with_extensions.h"
#include "ui/gl/gl_gl_api_implementation.h"
#include "ui/gl/gl_implementation.h"
#include "ui/gl/gl_osmesa_api_implementation.h"

namespace gfx {
namespace {
const char kOpenGLFrameworkPath[] =
    "/System/Library/Frameworks/OpenGL.framework/Versions/Current/OpenGL";
}  // namespace

void GetAllowedGLImplementations(std::vector<GLImplementation>* impls) {
  impls->push_back(kGLImplementationDesktopGL);
  impls->push_back(kGLImplementationAppleGL);
  impls->push_back(kGLImplementationOSMesaGL);
}

bool InitializeStaticGLBindings(GLImplementation implementation) {
  // Prevent reinitialization with a different implementation. Once the gpu
  // unit tests have initialized with kGLImplementationMock, we don't want to
  // later switch to another GL implementation.
  DCHECK_EQ(kGLImplementationNone, GetGLImplementation());

  switch (implementation) {
    case kGLImplementationOSMesaGL: {
      // osmesa.so is located in the build directory. This code path is only
      // valid in a developer build environment.
      base::FilePath exe_path;
      if (!PathService::Get(base::FILE_EXE, &exe_path)) {
        LOG(ERROR) << "PathService::Get failed.";
        return false;
      }
      base::FilePath bundle_path = base::mac::GetAppBundlePath(exe_path);
      // Some unit test targets depend on osmesa but aren't built as app
      // bundles. In that case, the .so is next to the executable.
      if (bundle_path.empty())
        bundle_path = exe_path;
      base::FilePath build_dir_path = bundle_path.DirName();
      base::FilePath osmesa_path = build_dir_path.Append("osmesa.so");

      // When using OSMesa, just use OSMesaGetProcAddress to find entry points.
      base::NativeLibrary library = base::LoadNativeLibrary(osmesa_path, NULL);
      if (!library) {
        LOG(ERROR) << "osmesa.so not found at " << osmesa_path.value();
        return false;
      }

      GLGetProcAddressProc get_proc_address =
          reinterpret_cast<GLGetProcAddressProc>(
              base::GetFunctionPointerFromNativeLibrary(
                  library, "OSMesaGetProcAddress"));
      if (!get_proc_address) {
        LOG(ERROR) << "OSMesaGetProcAddress not found.";
        base::UnloadNativeLibrary(library);
        return false;
      }

      SetGLGetProcAddressProc(get_proc_address);
      AddGLNativeLibrary(library);
      SetGLImplementation(kGLImplementationOSMesaGL);

      InitializeStaticGLBindingsGL();
      break;
    }
    case kGLImplementationDesktopGL:
    case kGLImplementationAppleGL: {
      base::NativeLibrary library = base::LoadNativeLibrary(
          base::FilePath(kOpenGLFrameworkPath), NULL);
      if (!library) {
        LOG(ERROR) << "OpenGL framework not found";
        return false;
      }

      AddGLNativeLibrary(library);
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
    case kGLImplementationAppleGL:
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
