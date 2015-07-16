// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/sync_socket.h"

#include <errno.h>
#include <limits.h>
#include <stdio.h>
#include <sys/types.h>

#include "base/logging.h"

namespace base {

const SyncSocket::Handle SyncSocket::kInvalidHandle = -1;

SyncSocket::SyncSocket() : handle_(kInvalidHandle) {
}

SyncSocket::~SyncSocket() {
  Close();
}

// static
bool SyncSocket::CreatePair(SyncSocket* socket_a, SyncSocket* socket_b) {
  return false;
}

// static
SyncSocket::Handle SyncSocket::UnwrapHandle(
    const SyncSocket::TransitDescriptor& descriptor) {
  // TODO(xians): Still unclear how NaCl uses SyncSocket.
  // See http://crbug.com/409656
  NOTIMPLEMENTED();
  return SyncSocket::kInvalidHandle;
}

bool SyncSocket::PrepareTransitDescriptor(
    ProcessHandle peer_process_handle,
    SyncSocket::TransitDescriptor* descriptor) {
  // TODO(xians): Still unclear how NaCl uses SyncSocket.
  // See http://crbug.com/409656
  NOTIMPLEMENTED();
  return false;
}

bool SyncSocket::Close() {
  if (handle_ != kInvalidHandle) {
    if (close(handle_) < 0)
      DPLOG(ERROR) << "close";
    handle_ = kInvalidHandle;
  }
  return true;
}

size_t SyncSocket::Send(const void* buffer, size_t length) {
  const ssize_t bytes_written = write(handle_, buffer, length);
  return bytes_written > 0 ? bytes_written : 0;
}

size_t SyncSocket::Receive(void* buffer, size_t length) {
  const ssize_t bytes_read = read(handle_, buffer, length);
  return bytes_read > 0 ? bytes_read : 0;
}

size_t SyncSocket::ReceiveWithTimeout(void* buffer, size_t length, TimeDelta) {
  NOTIMPLEMENTED();
  return 0;
}

size_t SyncSocket::Peek() {
  NOTIMPLEMENTED();
  return 0;
}

CancelableSyncSocket::CancelableSyncSocket() {
}

CancelableSyncSocket::CancelableSyncSocket(Handle handle)
    : SyncSocket(handle) {
}

size_t CancelableSyncSocket::Send(const void* buffer, size_t length) {
  return SyncSocket::Send(buffer, length);
}

bool CancelableSyncSocket::Shutdown() {
  return SyncSocket::Close();
}

// static
bool CancelableSyncSocket::CreatePair(CancelableSyncSocket* socket_a,
                                      CancelableSyncSocket* socket_b) {
  return SyncSocket::CreatePair(socket_a, socket_b);
}

}  // namespace base
