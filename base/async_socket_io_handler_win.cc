// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/async_socket_io_handler.h"

namespace base {

AsyncSocketIoHandler::AsyncSocketIoHandler()
    : socket_(base::SyncSocket::kInvalidHandle),
      context_(NULL),
      is_pending_(false) {}

AsyncSocketIoHandler::~AsyncSocketIoHandler() {
  // We need to be deleted on the correct thread to avoid racing with the
  // message loop thread.
  DCHECK(CalledOnValidThread());

  if (context_) {
    if (is_pending_) {
      // Make the context be deleted by the message pump when done.
      context_->handler = NULL;
    } else {
      delete context_;
    }
  }
}

// Implementation of IOHandler on Windows.
void AsyncSocketIoHandler::OnIOCompleted(
    base::MessageLoopForIO::IOContext* context,
    DWORD bytes_transfered,
    DWORD error) {
  DCHECK(CalledOnValidThread());
  DCHECK_EQ(context_, context);
  DCHECK(!read_complete_.is_null());
  is_pending_ = false;
  read_complete_.Run(error == ERROR_SUCCESS ? bytes_transfered : 0);
}

bool AsyncSocketIoHandler::Read(char* buffer, int buffer_len) {
  DCHECK(CalledOnValidThread());
  DCHECK(!read_complete_.is_null());
  DCHECK(!is_pending_);
  DCHECK_NE(socket_, base::SyncSocket::kInvalidHandle);

  DWORD bytes_read = 0;
  BOOL ok = ::ReadFile(socket_, buffer, buffer_len, &bytes_read,
                       &context_->overlapped);
  // The completion port will be signaled regardless of completing the read
  // straight away or asynchronously (ERROR_IO_PENDING). OnIOCompleted() will
  // be called regardless and we don't need to explicitly run the callback
  // in the case where ok is FALSE and GLE==ERROR_IO_PENDING.
  is_pending_ = !ok && (GetLastError() == ERROR_IO_PENDING);
  return ok || is_pending_;
}

bool AsyncSocketIoHandler::Initialize(base::SyncSocket::Handle socket,
                                      const ReadCompleteCallback& callback) {
  DCHECK(!context_);
  DCHECK_EQ(socket_, base::SyncSocket::kInvalidHandle);

  DetachFromThread();

  socket_ = socket;
  read_complete_ = callback;

  base::MessageLoopForIO::current()->RegisterIOHandler(socket, this);

  context_ = new base::MessageLoopForIO::IOContext();
  context_->handler = this;
  memset(&context_->overlapped, 0, sizeof(context_->overlapped));

  return true;
}

}  // namespace base.
