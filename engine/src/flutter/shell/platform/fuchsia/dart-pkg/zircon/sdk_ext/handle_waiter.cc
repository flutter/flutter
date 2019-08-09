// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "handle_waiter.h"

#include <lib/async/default.h>

#include "handle.h"
#include "third_party/tonic/converter/dart_converter.h"
#include "third_party/tonic/dart_args.h"
#include "third_party/tonic/dart_binding_macros.h"
#include "third_party/tonic/dart_library_natives.h"
#include "third_party/tonic/dart_message_handler.h"
#include "third_party/tonic/logging/dart_invoke.h"

using tonic::DartInvokeField;
using tonic::DartState;
using tonic::ToDart;

namespace zircon {
namespace dart {

IMPLEMENT_WRAPPERTYPEINFO(zircon, HandleWaiter);

#define FOR_EACH_BINDING(V) V(HandleWaiter, Cancel)

FOR_EACH_BINDING(DART_NATIVE_CALLBACK)

void HandleWaiter::RegisterNatives(tonic::DartLibraryNatives* natives) {
  natives->Register({FOR_EACH_BINDING(DART_REGISTER_NATIVE)});
}

fml::RefPtr<HandleWaiter> HandleWaiter::Create(Handle* handle,
                                               zx_signals_t signals,
                                               Dart_Handle callback) {
  return fml::MakeRefCounted<HandleWaiter>(handle, signals, callback);
}

HandleWaiter::HandleWaiter(Handle* handle,
                           zx_signals_t signals,
                           Dart_Handle callback)
    : wait_(this, handle->handle(), signals),
      handle_(handle),
      callback_(DartState::Current(), callback) {
  FML_CHECK(handle_ != nullptr);
  FML_CHECK(handle_->is_valid());

  zx_status_t status = wait_.Begin(async_get_default_dispatcher());
  FML_DCHECK(status == ZX_OK);
}

HandleWaiter::~HandleWaiter() {
  Cancel();
}

void HandleWaiter::Cancel() {
  FML_DCHECK(wait_.is_pending() == !!handle_);
  if (handle_) {
    // Cancel the wait.
    wait_.Cancel();

    // Release this object from the handle and clear handle_.
    handle_->ReleaseWaiter(this);
    handle_ = nullptr;
  }
  FML_DCHECK(!wait_.is_pending());
}

void HandleWaiter::OnWaitComplete(async_dispatcher_t* dispatcher,
                                  async::WaitBase* wait,
                                  zx_status_t status,
                                  const zx_packet_signal_t* signal) {
  FML_DCHECK(handle_);

  FML_DCHECK(!callback_.is_empty());

  // Hold a reference to this object.
  fml::RefPtr<HandleWaiter> ref(this);

  // Remove this waiter from the handle.
  handle_->ReleaseWaiter(this);

  // Schedule the callback on the microtask queue.
  handle_->ScheduleCallback(std::move(callback_), status, signal);

  // Clear handle_.
  handle_ = nullptr;
}

}  // namespace dart
}  // namespace zircon
