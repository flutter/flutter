// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_POSIX_UNIX_DOMAIN_SOCKET_LINUX_H_
#define BASE_POSIX_UNIX_DOMAIN_SOCKET_LINUX_H_

#include <stdint.h>
#include <sys/types.h>
#include <vector>

#include "base/base_export.h"
#include "base/files/scoped_file.h"
#include "base/memory/scoped_vector.h"
#include "base/process/process_handle.h"

namespace base {

class Pickle;

class BASE_EXPORT UnixDomainSocket {
 public:
  // Maximum number of file descriptors that can be read by RecvMsg().
  static const size_t kMaxFileDescriptors;

#if !defined(OS_NACL_NONSFI)
  // Use to enable receiving process IDs in RecvMsgWithPid.  Should be called on
  // the receiving socket (i.e., the socket passed to RecvMsgWithPid). Returns
  // true if successful.
  static bool EnableReceiveProcessId(int fd);
#endif  // !defined(OS_NACL_NONSFI)

  // Use sendmsg to write the given msg and include a vector of file
  // descriptors. Returns true if successful.
  static bool SendMsg(int fd,
                      const void* msg,
                      size_t length,
                      const std::vector<int>& fds);

  // Use recvmsg to read a message and an array of file descriptors. Returns
  // -1 on failure. Note: will read, at most, |kMaxFileDescriptors| descriptors.
  static ssize_t RecvMsg(int fd,
                         void* msg,
                         size_t length,
                         ScopedVector<ScopedFD>* fds);

  // Same as RecvMsg above, but also returns the sender's process ID (as seen
  // from the caller's namespace).  However, before using this function to
  // receive process IDs, EnableReceiveProcessId() should be called on the
  // receiving socket.
  static ssize_t RecvMsgWithPid(int fd,
                                void* msg,
                                size_t length,
                                ScopedVector<ScopedFD>* fds,
                                ProcessId* pid);

#if !defined(OS_NACL_NONSFI)
  // Perform a sendmsg/recvmsg pair.
  //   1. This process creates a UNIX SEQPACKET socketpair. Using
  //      connection-oriented sockets (SEQPACKET or STREAM) is critical here,
  //      because if one of the ends closes the other one must be notified.
  //   2. This process writes a request to |fd| with an SCM_RIGHTS control
  //      message containing on end of the fresh socket pair.
  //   3. This process blocks reading from the other end of the fresh
  //      socketpair.
  //   4. The target process receives the request, processes it and writes the
  //      reply to the end of the socketpair contained in the request.
  //   5. This process wakes up and continues.
  //
  //   fd: descriptor to send the request on
  //   reply: buffer for the reply
  //   reply_len: size of |reply|
  //   result_fd: (may be NULL) the file descriptor returned in the reply
  //              (if any)
  //   request: the bytes to send in the request
  static ssize_t SendRecvMsg(int fd,
                             uint8_t* reply,
                             unsigned reply_len,
                             int* result_fd,
                             const Pickle& request);

  // Similar to SendRecvMsg(), but |recvmsg_flags| allows to control the flags
  // of the recvmsg(2) call.
  static ssize_t SendRecvMsgWithFlags(int fd,
                                      uint8_t* reply,
                                      unsigned reply_len,
                                      int recvmsg_flags,
                                      int* result_fd,
                                      const Pickle& request);
#endif  // !defined(OS_NACL_NONSFI)
 private:
  // Similar to RecvMsg, but allows to specify |flags| for recvmsg(2).
  static ssize_t RecvMsgWithFlags(int fd,
                                  void* msg,
                                  size_t length,
                                  int flags,
                                  ScopedVector<ScopedFD>* fds,
                                  ProcessId* pid);
};

}  // namespace base

#endif  // BASE_POSIX_UNIX_DOMAIN_SOCKET_LINUX_H_
