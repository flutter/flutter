// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/native_library.h"

#include <dlfcn.h>

#include "base/files/file_path.h"
#include "base/logging.h"
#include "base/strings/utf_string_conversions.h"
#include "base/threading/thread_restrictions.h"

namespace base {

std::string NativeLibraryLoadError::ToString() const {
  return message;
}

// static
NativeLibrary LoadNativeLibrary(const FilePath& library_path,
                                NativeLibraryLoadError* error) {
  // dlopen() opens the file off disk.
  base::ThreadRestrictions::AssertIOAllowed();

  // We deliberately do not use RTLD_DEEPBIND.  For the history why, please
  // refer to the bug tracker.  Some useful bug reports to read include:
  // http://crbug.com/17943, http://crbug.com/17557, http://crbug.com/36892,
  // and http://crbug.com/40794.
  void* dl = dlopen(library_path.value().c_str(), RTLD_LAZY);
  if (!dl && error)
    error->message = dlerror();

  return dl;
}

// static
void UnloadNativeLibrary(NativeLibrary library) {
  int ret = dlclose(library);
  if (ret < 0) {
    DLOG(ERROR) << "dlclose failed: " << dlerror();
    NOTREACHED();
  }
}

// static
void* GetFunctionPointerFromNativeLibrary(NativeLibrary library,
                                          const char* name) {
  return dlsym(library, name);
}

// static
string16 GetNativeLibraryName(const string16& name) {
  return ASCIIToUTF16("lib") + name + ASCIIToUTF16(".so");
}

}  // namespace base
