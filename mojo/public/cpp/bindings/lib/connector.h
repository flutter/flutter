// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_PUBLIC_CPP_BINDINGS_LIB_CONNECTOR_H_
#define MOJO_PUBLIC_CPP_BINDINGS_LIB_CONNECTOR_H_

#include "mojo/public/c/environment/async_waiter.h"
#include "mojo/public/cpp/bindings/callback.h"
#include "mojo/public/cpp/bindings/lib/message_queue.h"
#include "mojo/public/cpp/bindings/message.h"
#include "mojo/public/cpp/environment/environment.h"
#include "mojo/public/cpp/system/core.h"

namespace mojo {
class ErrorHandler;

namespace internal {

// The Connector class is responsible for performing read/write operations on a
// MessagePipe. It writes messages it receives through the MessageReceiver
// interface that it subclasses, and it forwards messages it reads through the
// MessageReceiver interface assigned as its incoming receiver.
//
// NOTE: MessagePipe I/O is non-blocking.
//
class Connector : public MessageReceiver {
 public:
  // The Connector takes ownership of |message_pipe|.
  explicit Connector(
      ScopedMessagePipeHandle message_pipe,
      const MojoAsyncWaiter* waiter = Environment::GetDefaultAsyncWaiter());
  ~Connector() override;

  // Sets the receiver to handle messages read from the message pipe.  The
  // Connector will read messages from the pipe regardless of whether or not an
  // incoming receiver has been set.
  void set_incoming_receiver(MessageReceiver* receiver) {
    incoming_receiver_ = receiver;
  }

  // Errors from incoming receivers will force the connector into an error
  // state, where no more messages will be processed. This method is used
  // during testing to prevent that from happening.
  void set_enforce_errors_from_incoming_receiver(bool enforce) {
    enforce_errors_from_incoming_receiver_ = enforce;
  }

  // Sets the error handler to receive notifications when an error is
  // encountered while reading from the pipe or waiting to read from the pipe.
  void set_connection_error_handler(const Closure& error_handler) {
    connection_error_handler_ = error_handler;
  }

  // Returns true if an error was encountered while reading from the pipe or
  // waiting to read from the pipe.
  bool encountered_error() const { return error_; }

  // Closes the pipe, triggering the error state. Connector is put into a
  // quiescent state.
  void CloseMessagePipe();

  // Releases the pipe, not triggering the error state. Connector is put into
  // a quiescent state.
  ScopedMessagePipeHandle PassMessagePipe();

  // Is the connector bound to a MessagePipe handle?
  bool is_valid() const { return message_pipe_.is_valid(); }

  // Waits for the next message on the pipe, blocking until one arrives,
  // |deadline| elapses, or an error happens. Returns |true| if a message has
  // been delivered, |false| otherwise.
  bool WaitForIncomingMessage(MojoDeadline deadline);

  // MessageReceiver implementation:
  bool Accept(Message* message) override;

  MessagePipeHandle handle() const { return message_pipe_.get(); }

 private:
  static void CallOnHandleReady(void* closure, MojoResult result);
  void OnHandleReady(MojoResult result);

  void WaitToReadMore();

  // Returns false if |this| was destroyed during message dispatch.
  MOJO_WARN_UNUSED_RESULT bool ReadSingleMessage(MojoResult* read_result);

  // |this| can be destroyed during message dispatch.
  void ReadAllAvailableMessages();

  void NotifyError();

  // Cancels any calls made to |waiter_|.
  void CancelWait();

  Closure connection_error_handler_;
  const MojoAsyncWaiter* waiter_;

  ScopedMessagePipeHandle message_pipe_;
  MessageReceiver* incoming_receiver_;

  MojoAsyncWaitID async_wait_id_;
  bool error_;
  bool drop_writes_;
  bool enforce_errors_from_incoming_receiver_;

  // If non-null, this will be set to true when the Connector is destroyed.  We
  // use this flag to allow for the Connector to be destroyed as a side-effect
  // of dispatching an incoming message.
  bool* destroyed_flag_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(Connector);
};

}  // namespace internal
}  // namespace mojo

#endif  // MOJO_PUBLIC_CPP_BINDINGS_LIB_CONNECTOR_H_
