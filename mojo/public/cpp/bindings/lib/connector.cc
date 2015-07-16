// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/public/cpp/bindings/lib/connector.h"

#include "mojo/public/cpp/environment/logging.h"

namespace mojo {
namespace internal {

// ----------------------------------------------------------------------------

Connector::Connector(ScopedMessagePipeHandle message_pipe,
                     const MojoAsyncWaiter* waiter)
    : waiter_(waiter),
      message_pipe_(message_pipe.Pass()),
      incoming_receiver_(nullptr),
      async_wait_id_(0),
      error_(false),
      drop_writes_(false),
      enforce_errors_from_incoming_receiver_(true),
      destroyed_flag_(nullptr) {
  // Even though we don't have an incoming receiver, we still want to monitor
  // the message pipe to know if is closed or encounters an error.
  WaitToReadMore();
}

Connector::~Connector() {
  if (destroyed_flag_)
    *destroyed_flag_ = true;

  CancelWait();
}

void Connector::CloseMessagePipe() {
  CancelWait();
  Close(message_pipe_.Pass());
}

ScopedMessagePipeHandle Connector::PassMessagePipe() {
  CancelWait();
  return message_pipe_.Pass();
}

bool Connector::WaitForIncomingMessage(MojoDeadline deadline) {
  if (error_)
    return false;

  MojoResult rv =
      Wait(message_pipe_.get(), MOJO_HANDLE_SIGNAL_READABLE, deadline, nullptr);
  if (rv == MOJO_RESULT_SHOULD_WAIT)
    return false;
  if (rv != MOJO_RESULT_OK) {
    NotifyError();
    return false;
  }
  mojo_ignore_result(ReadSingleMessage(&rv));
  return (rv == MOJO_RESULT_OK);
}

bool Connector::Accept(Message* message) {
  if (error_)
    return false;

  MOJO_CHECK(message_pipe_.is_valid());
  if (drop_writes_)
    return true;

  MojoResult rv =
      WriteMessageRaw(message_pipe_.get(),
                      message->data(),
                      message->data_num_bytes(),
                      message->mutable_handles()->empty()
                          ? nullptr
                          : reinterpret_cast<const MojoHandle*>(
                                &message->mutable_handles()->front()),
                      static_cast<uint32_t>(message->mutable_handles()->size()),
                      MOJO_WRITE_MESSAGE_FLAG_NONE);

  switch (rv) {
    case MOJO_RESULT_OK:
      // The handles were successfully transferred, so we don't need the message
      // to track their lifetime any longer.
      message->mutable_handles()->clear();
      break;
    case MOJO_RESULT_FAILED_PRECONDITION:
      // There's no point in continuing to write to this pipe since the other
      // end is gone. Avoid writing any future messages. Hide write failures
      // from the caller since we'd like them to continue consuming any backlog
      // of incoming messages before regarding the message pipe as closed.
      drop_writes_ = true;
      break;
    case MOJO_RESULT_BUSY:
      // We'd get a "busy" result if one of the message's handles is:
      //   - |message_pipe_|'s own handle;
      //   - simultaneously being used on another thread; or
      //   - in a "busy" state that prohibits it from being transferred (e.g.,
      //     a data pipe handle in the middle of a two-phase read/write,
      //     regardless of which thread that two-phase read/write is happening
      //     on).
      // TODO(vtl): I wonder if this should be a |MOJO_DCHECK()|. (But, until
      // crbug.com/389666, etc. are resolved, this will make tests fail quickly
      // rather than hanging.)
      MOJO_CHECK(false) << "Race condition or other bug detected";
      return false;
    default:
      // This particular write was rejected, presumably because of bad input.
      // The pipe is not necessarily in a bad state.
      return false;
  }
  return true;
}

// static
void Connector::CallOnHandleReady(void* closure, MojoResult result) {
  Connector* self = static_cast<Connector*>(closure);
  self->OnHandleReady(result);
}

void Connector::OnHandleReady(MojoResult result) {
  MOJO_CHECK(async_wait_id_ != 0);
  async_wait_id_ = 0;
  if (result != MOJO_RESULT_OK) {
    NotifyError();
    return;
  }
  ReadAllAvailableMessages();
  // At this point, this object might have been deleted. Return.
}

void Connector::WaitToReadMore() {
  MOJO_CHECK(!async_wait_id_);
  async_wait_id_ = waiter_->AsyncWait(message_pipe_.get().value(),
                                      MOJO_HANDLE_SIGNAL_READABLE,
                                      MOJO_DEADLINE_INDEFINITE,
                                      &Connector::CallOnHandleReady,
                                      this);
}

bool Connector::ReadSingleMessage(MojoResult* read_result) {
  bool receiver_result = false;

  // Detect if |this| was destroyed during message dispatch. Allow for the
  // possibility of re-entering ReadMore() through message dispatch.
  bool was_destroyed_during_dispatch = false;
  bool* previous_destroyed_flag = destroyed_flag_;
  destroyed_flag_ = &was_destroyed_during_dispatch;

  MojoResult rv = ReadAndDispatchMessage(
      message_pipe_.get(), incoming_receiver_, &receiver_result);
  if (read_result)
    *read_result = rv;

  if (was_destroyed_during_dispatch) {
    if (previous_destroyed_flag)
      *previous_destroyed_flag = true;  // Propagate flag.
    return false;
  }
  destroyed_flag_ = previous_destroyed_flag;

  if (rv == MOJO_RESULT_SHOULD_WAIT)
    return true;

  if (rv != MOJO_RESULT_OK ||
      (enforce_errors_from_incoming_receiver_ && !receiver_result)) {
    NotifyError();
    return false;
  }
  return true;
}

void Connector::ReadAllAvailableMessages() {
  while (!error_) {
    MojoResult rv;

    // Return immediately if |this| was destroyed. Do not touch any members!
    if (!ReadSingleMessage(&rv))
      return;

    if (rv == MOJO_RESULT_SHOULD_WAIT) {
      WaitToReadMore();
      break;
    }
  }
}

void Connector::CancelWait() {
  if (!async_wait_id_)
    return;

  waiter_->CancelWait(async_wait_id_);
  async_wait_id_ = 0;
}

void Connector::NotifyError() {
  error_ = true;
  CloseMessagePipe();
  connection_error_handler_.Run();
}

}  // namespace internal
}  // namespace mojo
