// Copyright 2018 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_NATIVE_LIBRARY_H_
#define FLUTTER_FML_NATIVE_LIBRARY_H_

#include "flutter/fml/macros.h"
#include "lib/fxl/memory/ref_counted.h"
#include "lib/fxl/memory/ref_ptr.h"

#if OS_WIN

#include <windows.h>

#endif  // OS_WIN

namespace fml {
class NativeLibrary : public fxl::RefCountedThreadSafe<NativeLibrary> {
 public:
#if OS_WIN
  using Handle = HMODULE;
#else   // OS_WIN
  using Handle = void*;
#endif  // OS_WIN

  static fxl::RefPtr<NativeLibrary> Create(const char* path);

  static fxl::RefPtr<NativeLibrary> CreateForCurrentProcess();

  const uint8_t* ResolveSymbol(const char* symbol);

 private:
  Handle handle_ = nullptr;
  bool close_handle_ = true;

  NativeLibrary(const char* path);

  NativeLibrary(Handle handle, bool close_handle);

  ~NativeLibrary();

  Handle GetHandle() const;

  FML_DISALLOW_COPY_AND_ASSIGN(NativeLibrary);
  FRIEND_REF_COUNTED_THREAD_SAFE(NativeLibrary);
  FRIEND_MAKE_REF_COUNTED(NativeLibrary);
};

}  // namespace fml

#endif  // FLUTTER_FML_NATIVE_LIBRARY_H_
