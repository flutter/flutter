// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "handle.h"

#include <algorithm>

#include "third_party/tonic/dart_binding_macros.h"
#include "third_party/tonic/dart_class_library.h"

using tonic::ToDart;

namespace zircon {
namespace dart {

IMPLEMENT_WRAPPERTYPEINFO(zircon, Handle);

Handle::Handle(zx_handle_t handle) : handle_(handle) {
  tonic::DartState* state = tonic::DartState::Current();
  FML_DCHECK(state);
  Dart_Handle zircon_lib = Dart_LookupLibrary(ToDart("dart:zircon"));
  FML_DCHECK(!tonic::LogIfError(zircon_lib));

  Dart_Handle on_wait_completer_type =
      Dart_GetClass(zircon_lib, ToDart("_OnWaitCompleteClosure"));
  FML_DCHECK(!tonic::LogIfError(on_wait_completer_type));
  on_wait_completer_type_.Set(state, on_wait_completer_type);

  Dart_Handle async_lib = Dart_LookupLibrary(ToDart("dart:async"));
  FML_DCHECK(!tonic::LogIfError(async_lib));
  async_lib_.Set(state, async_lib);

  Dart_Handle closure_string = ToDart("_closure");
  FML_DCHECK(!tonic::LogIfError(closure_string));
  closure_string_.Set(state, closure_string);

  Dart_Handle schedule_microtask_string = ToDart("scheduleMicrotask");
  FML_DCHECK(!tonic::LogIfError(schedule_microtask_string));
  schedule_microtask_string_.Set(state, schedule_microtask_string);
}

Handle::~Handle() {
  if (is_valid()) {
    zx_status_t status = Close();
    FML_DCHECK(status == ZX_OK);
  }
}

fml::RefPtr<Handle> Handle::Create(zx_handle_t handle) {
  return fml::MakeRefCounted<Handle>(handle);
}

Dart_Handle Handle::CreateInvalid() {
  return ToDart(Create(ZX_HANDLE_INVALID));
}

zx_handle_t Handle::ReleaseHandle() {
  FML_DCHECK(is_valid());

  zx_handle_t handle = handle_;
  handle_ = ZX_HANDLE_INVALID;
  while (waiters_.size()) {
    // HandleWaiter::Cancel calls Handle::ReleaseWaiter which removes the
    // HandleWaiter from waiters_.
    FML_DCHECK(waiters_.back()->is_pending());
    waiters_.back()->Cancel();
  }

  FML_DCHECK(!is_valid());

  return handle;
}

zx_status_t Handle::Close() {
  if (is_valid()) {
    zx_handle_t handle = ReleaseHandle();
    return zx_handle_close(handle);
  }
  return ZX_ERR_BAD_HANDLE;
}

fml::RefPtr<HandleWaiter> Handle::AsyncWait(zx_signals_t signals,
                                            Dart_Handle callback) {
  if (!is_valid()) {
    FML_LOG(WARNING) << "Attempt to wait on an invalid handle.";
    return nullptr;
  }

  fml::RefPtr<HandleWaiter> waiter =
      HandleWaiter::Create(this, signals, callback);
  waiters_.push_back(waiter.get());

  return waiter;
}

void Handle::ReleaseWaiter(HandleWaiter* waiter) {
  FML_DCHECK(waiter);
  auto iter = std::find(waiters_.cbegin(), waiters_.cend(), waiter);
  FML_DCHECK(iter != waiters_.cend());
  FML_DCHECK(*iter == waiter);
  waiters_.erase(iter);
}

Dart_Handle Handle::Duplicate(uint32_t rights) {
  if (!is_valid()) {
    return ToDart(Create(ZX_HANDLE_INVALID));
  }

  zx_handle_t out_handle;
  zx_status_t status = zx_handle_duplicate(handle_, rights, &out_handle);
  if (status != ZX_OK) {
    return ToDart(Create(ZX_HANDLE_INVALID));
  }
  return ToDart(Create(out_handle));
}

void Handle::ScheduleCallback(tonic::DartPersistentValue callback,
                              zx_status_t status,
                              const zx_packet_signal_t* signal) {
  auto state = callback.dart_state().lock();
  FML_DCHECK(state);
  tonic::DartState::Scope scope(state);

  // Make a new _OnWaitCompleteClosure(callback, status, signal->observed).
  FML_DCHECK(!callback.is_empty());
  std::vector<Dart_Handle> constructor_args{callback.Release(), ToDart(status),
                                            ToDart(signal->observed)};
  Dart_Handle on_wait_complete_closure =
      Dart_New(on_wait_completer_type_.Get(), Dart_Null(),
               constructor_args.size(), constructor_args.data());
  FML_DCHECK(!tonic::LogIfError(on_wait_complete_closure));

  // The _callback field contains the thunk:
  // () => callback(status, signal->observed)
  Dart_Handle closure =
      Dart_GetField(on_wait_complete_closure, closure_string_.Get());
  FML_DCHECK(!tonic::LogIfError(closure));

  // Put the thunk on the microtask queue by calling scheduleMicrotask().
  std::vector<Dart_Handle> sm_args{closure};
  Dart_Handle sm_result =
      Dart_Invoke(async_lib_.Get(), schedule_microtask_string_.Get(),
                  sm_args.size(), sm_args.data());
  FML_DCHECK(!tonic::LogIfError(sm_result));
}

// clang-format: off

#define FOR_EACH_STATIC_BINDING(V) V(Handle, CreateInvalid)

#define FOR_EACH_BINDING(V) \
  V(Handle, handle)         \
  V(Handle, koid)           \
  V(Handle, is_valid)       \
  V(Handle, Close)          \
  V(Handle, AsyncWait)      \
  V(Handle, Duplicate)

// clang-format: on

// Tonic is missing a comma.
#define DART_REGISTER_NATIVE_STATIC_(CLASS, METHOD) \
  DART_REGISTER_NATIVE_STATIC(CLASS, METHOD),

FOR_EACH_STATIC_BINDING(DART_NATIVE_CALLBACK_STATIC)
FOR_EACH_BINDING(DART_NATIVE_NO_UI_CHECK_CALLBACK)

void Handle::RegisterNatives(tonic::DartLibraryNatives* natives) {
  natives->Register({FOR_EACH_STATIC_BINDING(DART_REGISTER_NATIVE_STATIC_)
                         FOR_EACH_BINDING(DART_REGISTER_NATIVE)});
}

}  // namespace dart
}  // namespace zircon
