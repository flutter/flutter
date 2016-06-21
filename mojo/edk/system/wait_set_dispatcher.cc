// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/wait_set_dispatcher.h"

#include "base/logging.h"
#include "mojo/edk/system/options_validation.h"

using mojo::util::MutexLocker;
using mojo::util::RefPtr;

namespace mojo {
namespace system {

// static
constexpr MojoHandleRights WaitSetDispatcher::kDefaultHandleRights;

// static
const MojoCreateWaitSetOptions WaitSetDispatcher::kDefaultCreateOptions = {
    static_cast<uint32_t>(sizeof(MojoCreateWaitSetOptions)),
    MOJO_CREATE_WAIT_SET_OPTIONS_FLAG_NONE};

// static
MojoResult WaitSetDispatcher::ValidateCreateOptions(
    UserPointer<const MojoCreateWaitSetOptions> in_options,
    MojoCreateWaitSetOptions* out_options) {
  const MojoCreateWaitSetOptionsFlags kKnownFlags =
      MOJO_CREATE_WAIT_SET_OPTIONS_FLAG_NONE;

  *out_options = kDefaultCreateOptions;
  if (in_options.IsNull())
    return MOJO_RESULT_OK;

  UserOptionsReader<MojoCreateWaitSetOptions> reader(in_options);
  if (!reader.is_valid())
    return MOJO_RESULT_INVALID_ARGUMENT;

  if (!OPTIONS_STRUCT_HAS_MEMBER(MojoCreateWaitSetOptions, flags, reader))
    return MOJO_RESULT_OK;
  if ((reader.options().flags & ~kKnownFlags))
    return MOJO_RESULT_UNIMPLEMENTED;
  out_options->flags = reader.options().flags;

  // Checks for fields beyond |flags|:

  // (Nothing here yet.)

  return MOJO_RESULT_OK;
}

Dispatcher::Type WaitSetDispatcher::GetType() const {
  return Type::WAIT_SET;
}

bool WaitSetDispatcher::SupportsEntrypointClass(
    EntrypointClass entrypoint_class) const {
  return (entrypoint_class == EntrypointClass::NONE ||
          entrypoint_class == EntrypointClass::WAIT_SET);
}

WaitSetDispatcher::WaitSetDispatcher() {}

WaitSetDispatcher::~WaitSetDispatcher() {}

RefPtr<Dispatcher>
WaitSetDispatcher::CreateEquivalentDispatcherAndCloseImplNoLock(
    MessagePipe* /*message_pipe*/,
    unsigned /*port*/) {
  mutex().AssertHeld();
  NOTREACHED();
  return nullptr;
}

MojoResult WaitSetDispatcher::WaitSetAddImpl(
    UserPointer<const MojoWaitSetAddOptions> options,
    Handle&& handle,
    MojoHandleSignals signals,
    uint64_t cookie) {
  MutexLocker locker(&mutex());
  if (is_closed_no_lock())
    return MOJO_RESULT_INVALID_ARGUMENT;

  // TODO(vtl)
  NOTIMPLEMENTED();
  return MOJO_RESULT_UNIMPLEMENTED;
}

MojoResult WaitSetDispatcher::WaitSetRemoveImpl(uint64_t cookie) {
  MutexLocker locker(&mutex());
  if (is_closed_no_lock())
    return MOJO_RESULT_INVALID_ARGUMENT;

  // TODO(vtl)
  NOTIMPLEMENTED();
  return MOJO_RESULT_UNIMPLEMENTED;
}

MojoResult WaitSetDispatcher::WaitSetWaitImpl(
    MojoDeadline deadline,
    UserPointer<uint32_t> num_results,
    UserPointer<MojoWaitSetResult> results,
    UserPointer<uint32_t> max_results) {
  MutexLocker locker(&mutex());
  if (is_closed_no_lock())
    return MOJO_RESULT_INVALID_ARGUMENT;

  // TODO(vtl)
  NOTIMPLEMENTED();
  return MOJO_RESULT_UNIMPLEMENTED;
}

}  // namespace system
}  // namespace mojo
