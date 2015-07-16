// Copyright (c) 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/native_library.h"

#include "base/logging.h"

namespace base {

std::string NativeLibraryLoadError::ToString() const {
  return message;
}

// static
NativeLibrary LoadNativeLibrary(const base::FilePath& library_path,
                                NativeLibraryLoadError* error) {
  NOTIMPLEMENTED();
  return nullptr;
}

// static
void UnloadNativeLibrary(NativeLibrary library) {
  NOTIMPLEMENTED();
  DCHECK(!library);
}

// static
void* GetFunctionPointerFromNativeLibrary(NativeLibrary library,
                                          const char* name) {
  NOTIMPLEMENTED();
  return nullptr;
}

// static
string16 GetNativeLibraryName(const string16& name) {
  return name;
}

}  // namespace base
