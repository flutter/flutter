// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_NATIVE_LIBRARY_H_
#define FLUTTER_FML_NATIVE_LIBRARY_H_

#include "flutter/fml/build_config.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/memory/ref_counted.h"
#include "flutter/fml/memory/ref_ptr.h"

#if OS_WIN

#include <windows.h>

#endif  // OS_WIN

namespace fml {
class NativeLibrary : public fml::RefCountedThreadSafe<NativeLibrary> {
 public:
#if OS_WIN
  using Handle = HMODULE;
#else   // OS_WIN
  using Handle = void*;
#endif  // OS_WIN

  static fml::RefPtr<NativeLibrary> Create(const char* path);

  static fml::RefPtr<NativeLibrary> CreateWithHandle(
      Handle handle,
      bool close_handle_when_done);

  static fml::RefPtr<NativeLibrary> CreateForCurrentProcess();

  const uint8_t* ResolveSymbol(const char* symbol);

 private:
  Handle handle_ = nullptr;
  bool close_handle_ = true;

  NativeLibrary(const char* path);

  NativeLibrary(Handle handle, bool close_handle);

  ~NativeLibrary();

  Handle GetHandle() const;

  FML_DISALLOW_COPY_AND_ASSIGN(NativeLibrary);
  FML_FRIEND_REF_COUNTED_THREAD_SAFE(NativeLibrary);
  FML_FRIEND_MAKE_REF_COUNTED(NativeLibrary);
};

}  // namespace fml

#endif  // FLUTTER_FML_NATIVE_LIBRARY_H_
