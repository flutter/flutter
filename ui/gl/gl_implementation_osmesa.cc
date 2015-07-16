// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gl/gl_implementation_osmesa.h"

#include "base/files/file_path.h"
#include "base/logging.h"
#include "base/native_library.h"
#include "base/path_service.h"
#include "ui/gl/gl_bindings.h"
#include "ui/gl/gl_gl_api_implementation.h"
#include "ui/gl/gl_implementation.h"
#include "ui/gl/gl_osmesa_api_implementation.h"

namespace gfx {

base::NativeLibrary LoadLibraryAndPrintError(const base::FilePath& filename) {
  base::NativeLibraryLoadError error;
  base::NativeLibrary library = base::LoadNativeLibrary(filename, &error);
  if (!library) {
    LOG(ERROR) << "Failed to load " << filename.MaybeAsASCII() << ": "
               << error.ToString();
    return NULL;
  }
  return library;
}

base::NativeLibrary LoadLibraryAndPrintError(const char* filename) {
  return LoadLibraryAndPrintError(base::FilePath(filename));
}

bool InitializeStaticGLBindingsOSMesaGL() {
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
  return true;
}

}  // namespace gfx
