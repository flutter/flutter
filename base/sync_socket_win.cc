// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/sync_socket.h"

#include "base/logging.h"
#include "base/threading/thread_restrictions.h"
#include "base/win/scoped_handle.h"

namespace base {

using win::ScopedHandle;

namespace {
// IMPORTANT: do not change how this name is generated because it will break
// in sandboxed scenarios as we might have by-name policies that allow pipe
// creation. Also keep the secure random number generation.
const wchar_t kPipeNameFormat[] = L"\\\\.\\pipe\\chrome.sync.%u.%u.%lu";
const size_t kPipePathMax =  arraysize(kPipeNameFormat) + (3 * 10) + 1;

// To avoid users sending negative message lengths to Send/Receive
// we clamp message lengths, which are size_t, to no more than INT_MAX.
const size_t kMaxMessageLength = static_cast<size_t>(INT_MAX);

const int kOutBufferSize = 4096;
const int kInBufferSize = 4096;
const int kDefaultTimeoutMilliSeconds = 1000;

bool CreatePairImpl(HANDLE* socket_a, HANDLE* socket_b, bool overlapped) {
  DCHECK_NE(socket_a, socket_b);
  DCHECK_EQ(*socket_a, SyncSocket::kInvalidHandle);
  DCHECK_EQ(*socket_b, SyncSocket::kInvalidHandle);

  wchar_t name[kPipePathMax];
  ScopedHandle handle_a;
  DWORD flags = PIPE_ACCESS_DUPLEX | FILE_FLAG_FIRST_PIPE_INSTANCE;
  if (overlapped)
    flags |= FILE_FLAG_OVERLAPPED;

  do {
    unsigned int rnd_name;
    if (rand_s(&rnd_name) != 0)
      return false;

    swprintf(name, kPipePathMax,
             kPipeNameFormat,
             GetCurrentProcessId(),
             GetCurrentThreadId(),
             rnd_name);

    handle_a.Set(CreateNamedPipeW(
        name,
        flags,
        PIPE_TYPE_BYTE | PIPE_READMODE_BYTE,
        1,
        kOutBufferSize,
        kInBufferSize,
        kDefaultTimeoutMilliSeconds,
        NULL));
  } while (!handle_a.IsValid() &&
           (GetLastError() == ERROR_PIPE_BUSY));

  if (!handle_a.IsValid()) {
    NOTREACHED();
    return false;
  }

  // The SECURITY_ANONYMOUS flag means that the server side (handle_a) cannot
  // impersonate the client (handle_b). This allows us not to care which side
  // ends up in which side of a privilege boundary.
  flags = SECURITY_SQOS_PRESENT | SECURITY_ANONYMOUS;
  if (overlapped)
    flags |= FILE_FLAG_OVERLAPPED;

  ScopedHandle handle_b(CreateFileW(name,
                                    GENERIC_READ | GENERIC_WRITE,
                                    0,          // no sharing.
                                    NULL,       // default security attributes.
                                    OPEN_EXISTING,  // opens existing pipe.
                                    flags,
                                    NULL));     // no template file.
  if (!handle_b.IsValid()) {
    DPLOG(ERROR) << "CreateFileW failed";
    return false;
  }

  if (!ConnectNamedPipe(handle_a.Get(), NULL)) {
    DWORD error = GetLastError();
    if (error != ERROR_PIPE_CONNECTED) {
      DPLOG(ERROR) << "ConnectNamedPipe failed";
      return false;
    }
  }

  *socket_a = handle_a.Take();
  *socket_b = handle_b.Take();

  return true;
}

// Inline helper to avoid having the cast everywhere.
DWORD GetNextChunkSize(size_t current_pos, size_t max_size) {
  // The following statement is for 64 bit portability.
  return static_cast<DWORD>(((max_size - current_pos) <= UINT_MAX) ?
      (max_size - current_pos) : UINT_MAX);
}

// Template function that supports calling ReadFile or WriteFile in an
// overlapped fashion and waits for IO completion.  The function also waits
// on an event that can be used to cancel the operation.  If the operation
// is cancelled, the function returns and closes the relevant socket object.
template <typename BufferType, typename Function>
size_t CancelableFileOperation(Function operation,
                               HANDLE file,
                               BufferType* buffer,
                               size_t length,
                               WaitableEvent* io_event,
                               WaitableEvent* cancel_event,
                               CancelableSyncSocket* socket,
                               DWORD timeout_in_ms) {
  ThreadRestrictions::AssertIOAllowed();
  // The buffer must be byte size or the length check won't make much sense.
  COMPILE_ASSERT(sizeof(buffer[0]) == sizeof(char), incorrect_buffer_type);
  DCHECK_GT(length, 0u);
  DCHECK_LE(length, kMaxMessageLength);
  DCHECK_NE(file, SyncSocket::kInvalidHandle);

  // Track the finish time so we can calculate the timeout as data is read.
  TimeTicks current_time, finish_time;
  if (timeout_in_ms != INFINITE) {
    current_time = TimeTicks::Now();
    finish_time =
        current_time + base::TimeDelta::FromMilliseconds(timeout_in_ms);
  }

  size_t count = 0;
  do {
    // The OVERLAPPED structure will be modified by ReadFile or WriteFile.
    OVERLAPPED ol = { 0 };
    ol.hEvent = io_event->handle();

    const DWORD chunk = GetNextChunkSize(count, length);
    // This is either the ReadFile or WriteFile call depending on whether
    // we're receiving or sending data.
    DWORD len = 0;
    const BOOL operation_ok = operation(
        file, static_cast<BufferType*>(buffer) + count, chunk, &len, &ol);
    if (!operation_ok) {
      if (::GetLastError() == ERROR_IO_PENDING) {
        HANDLE events[] = { io_event->handle(), cancel_event->handle() };
        const int wait_result = WaitForMultipleObjects(
            arraysize(events), events, FALSE,
            timeout_in_ms == INFINITE ?
                timeout_in_ms :
                static_cast<DWORD>(
                    (finish_time - current_time).InMilliseconds()));
        if (wait_result != WAIT_OBJECT_0 + 0) {
          // CancelIo() doesn't synchronously cancel outstanding IO, only marks
          // outstanding IO for cancellation. We must call GetOverlappedResult()
          // below to ensure in flight writes complete before returning.
          CancelIo(file);
        }

        // We set the |bWait| parameter to TRUE for GetOverlappedResult() to
        // ensure writes are complete before returning.
        if (!GetOverlappedResult(file, &ol, &len, TRUE))
          len = 0;

        if (wait_result == WAIT_OBJECT_0 + 1) {
          DVLOG(1) << "Shutdown was signaled. Closing socket.";
          socket->Close();
          return count;
        }

        // Timeouts will be handled by the while() condition below since
        // GetOverlappedResult() may complete successfully after CancelIo().
        DCHECK(wait_result == WAIT_OBJECT_0 + 0 || wait_result == WAIT_TIMEOUT);
      } else {
        break;
      }
    }

    count += len;

    // Quit the operation if we can't write/read anymore.
    if (len != chunk)
      break;

    // Since TimeTicks::Now() is expensive, only bother updating the time if we
    // have more work to do.
    if (timeout_in_ms != INFINITE && count < length)
      current_time = base::TimeTicks::Now();
  } while (count < length &&
           (timeout_in_ms == INFINITE || current_time < finish_time));

  return count;
}

}  // namespace

#if defined(COMPONENT_BUILD)
const SyncSocket::Handle SyncSocket::kInvalidHandle = INVALID_HANDLE_VALUE;
#endif

SyncSocket::SyncSocket() : handle_(kInvalidHandle) {}

SyncSocket::~SyncSocket() {
  Close();
}

// static
bool SyncSocket::CreatePair(SyncSocket* socket_a, SyncSocket* socket_b) {
  return CreatePairImpl(&socket_a->handle_, &socket_b->handle_, false);
}

// static
SyncSocket::Handle SyncSocket::UnwrapHandle(
    const TransitDescriptor& descriptor) {
  return descriptor;
}

bool SyncSocket::PrepareTransitDescriptor(ProcessHandle peer_process_handle,
                                          TransitDescriptor* descriptor) {
  DCHECK(descriptor);
  if (!::DuplicateHandle(GetCurrentProcess(), handle(), peer_process_handle,
                         descriptor, 0, FALSE, DUPLICATE_SAME_ACCESS)) {
    DPLOG(ERROR) << "Cannot duplicate socket handle for peer process.";
    return false;
  }
  return true;
}

bool SyncSocket::Close() {
  if (handle_ == kInvalidHandle)
    return true;

  const BOOL result = CloseHandle(handle_);
  handle_ = kInvalidHandle;
  return result == TRUE;
}

size_t SyncSocket::Send(const void* buffer, size_t length) {
  ThreadRestrictions::AssertIOAllowed();
  DCHECK_GT(length, 0u);
  DCHECK_LE(length, kMaxMessageLength);
  DCHECK_NE(handle_, kInvalidHandle);
  size_t count = 0;
  while (count < length) {
    DWORD len;
    DWORD chunk = GetNextChunkSize(count, length);
    if (WriteFile(handle_, static_cast<const char*>(buffer) + count,
                  chunk, &len, NULL) == FALSE) {
      return count;
    }
    count += len;
  }
  return count;
}

size_t SyncSocket::ReceiveWithTimeout(void* buffer,
                                      size_t length,
                                      TimeDelta timeout) {
  NOTIMPLEMENTED();
  return 0;
}

size_t SyncSocket::Receive(void* buffer, size_t length) {
  ThreadRestrictions::AssertIOAllowed();
  DCHECK_GT(length, 0u);
  DCHECK_LE(length, kMaxMessageLength);
  DCHECK_NE(handle_, kInvalidHandle);
  size_t count = 0;
  while (count < length) {
    DWORD len;
    DWORD chunk = GetNextChunkSize(count, length);
    if (ReadFile(handle_, static_cast<char*>(buffer) + count,
                 chunk, &len, NULL) == FALSE) {
      return count;
    }
    count += len;
  }
  return count;
}

size_t SyncSocket::Peek() {
  DWORD available = 0;
  PeekNamedPipe(handle_, NULL, 0, NULL, &available, NULL);
  return available;
}

CancelableSyncSocket::CancelableSyncSocket()
    : shutdown_event_(true, false), file_operation_(true, false) {
}

CancelableSyncSocket::CancelableSyncSocket(Handle handle)
    : SyncSocket(handle), shutdown_event_(true, false),
      file_operation_(true, false) {
}

bool CancelableSyncSocket::Shutdown() {
  // This doesn't shut down the pipe immediately, but subsequent Receive or Send
  // methods will fail straight away.
  shutdown_event_.Signal();
  return true;
}

bool CancelableSyncSocket::Close() {
  const bool result = SyncSocket::Close();
  shutdown_event_.Reset();
  return result;
}

size_t CancelableSyncSocket::Send(const void* buffer, size_t length) {
  static const DWORD kWaitTimeOutInMs = 500;
  return CancelableFileOperation(
      &WriteFile, handle_, reinterpret_cast<const char*>(buffer),
      length, &file_operation_, &shutdown_event_, this, kWaitTimeOutInMs);
}

size_t CancelableSyncSocket::Receive(void* buffer, size_t length) {
  return CancelableFileOperation(
      &ReadFile, handle_, reinterpret_cast<char*>(buffer), length,
      &file_operation_, &shutdown_event_, this, INFINITE);
}

size_t CancelableSyncSocket::ReceiveWithTimeout(void* buffer,
                                                size_t length,
                                                TimeDelta timeout) {
  return CancelableFileOperation(
      &ReadFile, handle_, reinterpret_cast<char*>(buffer), length,
      &file_operation_, &shutdown_event_, this,
      static_cast<DWORD>(timeout.InMilliseconds()));
}

// static
bool CancelableSyncSocket::CreatePair(CancelableSyncSocket* socket_a,
                                      CancelableSyncSocket* socket_b) {
  return CreatePairImpl(&socket_a->handle_, &socket_b->handle_, true);
}

}  // namespace base
