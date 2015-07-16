// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/async_socket_io_handler.h"

#include <fcntl.h>

#include "base/posix/eintr_wrapper.h"

namespace base {

AsyncSocketIoHandler::AsyncSocketIoHandler()
    : socket_(base::SyncSocket::kInvalidHandle),
      pending_buffer_(NULL),
      pending_buffer_len_(0),
      is_watching_(false) {
}

AsyncSocketIoHandler::~AsyncSocketIoHandler() {
  DCHECK(CalledOnValidThread());
}

void AsyncSocketIoHandler::OnFileCanReadWithoutBlocking(int socket) {
  DCHECK(CalledOnValidThread());
  DCHECK_EQ(socket, socket_);
  DCHECK(!read_complete_.is_null());

  if (pending_buffer_) {
    int bytes_read = HANDLE_EINTR(read(socket_, pending_buffer_,
                                       pending_buffer_len_));
    DCHECK_GE(bytes_read, 0);
    pending_buffer_ = NULL;
    pending_buffer_len_ = 0;
    read_complete_.Run(bytes_read > 0 ? bytes_read : 0);
  } else {
    // We're getting notifications that we can read from the socket while
    // we're not waiting for data.  In order to not starve the message loop,
    // let's stop watching the fd and restart the watch when Read() is called.
    is_watching_ = false;
    socket_watcher_.StopWatchingFileDescriptor();
  }
}

bool AsyncSocketIoHandler::Read(char* buffer, int buffer_len) {
  DCHECK(CalledOnValidThread());
  DCHECK(!read_complete_.is_null());
  DCHECK(!pending_buffer_);

  EnsureWatchingSocket();

  int bytes_read = HANDLE_EINTR(read(socket_, buffer, buffer_len));
  if (bytes_read < 0) {
    if (errno == EAGAIN) {
      pending_buffer_ = buffer;
      pending_buffer_len_ = buffer_len;
    } else {
      NOTREACHED() << "read(): " << errno;
      return false;
    }
  } else {
    read_complete_.Run(bytes_read);
  }
  return true;
}

bool AsyncSocketIoHandler::Initialize(base::SyncSocket::Handle socket,
                                      const ReadCompleteCallback& callback) {
  DCHECK_EQ(socket_, base::SyncSocket::kInvalidHandle);

  DetachFromThread();

  socket_ = socket;
  read_complete_ = callback;

  // SyncSocket is blocking by default, so let's convert it to non-blocking.
  int value = fcntl(socket, F_GETFL);
  if (!(value & O_NONBLOCK)) {
    // Set the socket to be non-blocking so we can do async reads.
    if (fcntl(socket, F_SETFL, O_NONBLOCK) == -1) {
      NOTREACHED();
      return false;
    }
  }

  return true;
}

void AsyncSocketIoHandler::EnsureWatchingSocket() {
  DCHECK(CalledOnValidThread());
  if (!is_watching_ && socket_ != base::SyncSocket::kInvalidHandle) {
    is_watching_ = base::MessageLoopForIO::current()->WatchFileDescriptor(
        socket_, true, base::MessageLoopForIO::WATCH_READ,
        &socket_watcher_, this);
  }
}

}  // namespace base.
