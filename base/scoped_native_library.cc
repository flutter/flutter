// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/scoped_native_library.h"

namespace base {

ScopedNativeLibrary::ScopedNativeLibrary() : library_(NULL) {
}

ScopedNativeLibrary::ScopedNativeLibrary(NativeLibrary library)
    : library_(library) {
}

ScopedNativeLibrary::ScopedNativeLibrary(const FilePath& library_path) {
  library_ = base::LoadNativeLibrary(library_path, NULL);
}

ScopedNativeLibrary::~ScopedNativeLibrary() {
  if (library_)
    base::UnloadNativeLibrary(library_);
}

void* ScopedNativeLibrary::GetFunctionPointer(
    const char* function_name) const {
  if (!library_)
    return NULL;
  return base::GetFunctionPointerFromNativeLibrary(library_, function_name);
}

void ScopedNativeLibrary::Reset(NativeLibrary library) {
  if (library_)
    base::UnloadNativeLibrary(library_);
  library_ = library;
}

NativeLibrary ScopedNativeLibrary::Release() {
  NativeLibrary result = library_;
  library_ = NULL;
  return result;
}

}  // namespace base
