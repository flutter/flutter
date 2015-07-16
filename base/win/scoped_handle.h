// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_WIN_SCOPED_HANDLE_H_
#define BASE_WIN_SCOPED_HANDLE_H_

#include <windows.h>

#include "base/base_export.h"
#include "base/basictypes.h"
#include "base/location.h"
#include "base/logging.h"
#include "base/move.h"

// TODO(rvargas): remove this with the rest of the verifier.
#if defined(COMPILER_MSVC)
#include <intrin.h>
#define BASE_WIN_GET_CALLER _ReturnAddress()
#elif defined(COMPILER_GCC)
#define BASE_WIN_GET_CALLER __builtin_extract_return_addr(\\
    __builtin_return_address(0))
#endif

namespace base {
namespace win {

// Generic wrapper for raw handles that takes care of closing handles
// automatically. The class interface follows the style of
// the ScopedFILE class with one addition:
//   - IsValid() method can tolerate multiple invalid handle values such as NULL
//     and INVALID_HANDLE_VALUE (-1) for Win32 handles.
template <class Traits, class Verifier>
class GenericScopedHandle {
  MOVE_ONLY_TYPE_FOR_CPP_03(GenericScopedHandle, RValue)

 public:
  typedef typename Traits::Handle Handle;

  GenericScopedHandle() : handle_(Traits::NullHandle()) {}

  explicit GenericScopedHandle(Handle handle) : handle_(Traits::NullHandle()) {
    Set(handle);
  }

  // Move constructor for C++03 move emulation of this type.
  GenericScopedHandle(RValue other) : handle_(Traits::NullHandle()) {
    Set(other.object->Take());
  }

  ~GenericScopedHandle() {
    Close();
  }

  bool IsValid() const {
    return Traits::IsHandleValid(handle_);
  }

  // Move operator= for C++03 move emulation of this type.
  GenericScopedHandle& operator=(RValue other) {
    if (this != other.object) {
      Set(other.object->Take());
    }
    return *this;
  }

  void Set(Handle handle) {
    if (handle_ != handle) {
      Close();

      if (Traits::IsHandleValid(handle)) {
        handle_ = handle;
        Verifier::StartTracking(handle, this, BASE_WIN_GET_CALLER,
                                tracked_objects::GetProgramCounter());
      }
    }
  }

  Handle Get() const {
    return handle_;
  }

  // Transfers ownership away from this object.
  Handle Take() {
    Handle temp = handle_;
    handle_ = Traits::NullHandle();
    if (Traits::IsHandleValid(temp)) {
      Verifier::StopTracking(temp, this, BASE_WIN_GET_CALLER,
                             tracked_objects::GetProgramCounter());
    }
    return temp;
  }

  // Explicitly closes the owned handle.
  void Close() {
    if (Traits::IsHandleValid(handle_)) {
      Verifier::StopTracking(handle_, this, BASE_WIN_GET_CALLER,
                             tracked_objects::GetProgramCounter());

      Traits::CloseHandle(handle_);
      handle_ = Traits::NullHandle();
    }
  }

 private:
  Handle handle_;
};

#undef BASE_WIN_GET_CALLER

// The traits class for Win32 handles that can be closed via CloseHandle() API.
class HandleTraits {
 public:
  typedef HANDLE Handle;

  // Closes the handle.
  static bool BASE_EXPORT CloseHandle(HANDLE handle);

  // Returns true if the handle value is valid.
  static bool IsHandleValid(HANDLE handle) {
    return handle != NULL && handle != INVALID_HANDLE_VALUE;
  }

  // Returns NULL handle value.
  static HANDLE NullHandle() {
    return NULL;
  }

 private:
  DISALLOW_IMPLICIT_CONSTRUCTORS(HandleTraits);
};

// Do-nothing verifier.
class DummyVerifierTraits {
 public:
  typedef HANDLE Handle;

  static void StartTracking(HANDLE handle, const void* owner,
                            const void* pc1, const void* pc2) {}
  static void StopTracking(HANDLE handle, const void* owner,
                           const void* pc1, const void* pc2) {}

 private:
  DISALLOW_IMPLICIT_CONSTRUCTORS(DummyVerifierTraits);
};

// Performs actual run-time tracking.
class BASE_EXPORT VerifierTraits {
 public:
  typedef HANDLE Handle;

  static void StartTracking(HANDLE handle, const void* owner,
                            const void* pc1, const void* pc2);
  static void StopTracking(HANDLE handle, const void* owner,
                           const void* pc1, const void* pc2);

 private:
  DISALLOW_IMPLICIT_CONSTRUCTORS(VerifierTraits);
};

typedef GenericScopedHandle<HandleTraits, VerifierTraits> ScopedHandle;

// This function may be called by the embedder to disable the use of
// VerifierTraits at runtime. It has no effect if DummyVerifierTraits is used
// for ScopedHandle.
void BASE_EXPORT DisableHandleVerifier();

// This should be called whenever the OS is closing a handle, if extended
// verification of improper handle closing is desired. If |handle| is being
// tracked by the handle verifier and ScopedHandle is not the one closing it,
// a CHECK is generated.
void BASE_EXPORT OnHandleBeingClosed(HANDLE handle);

}  // namespace win
}  // namespace base

#endif  // BASE_WIN_SCOPED_HANDLE_H_
