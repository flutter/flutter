// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/posix/unix_domain_socket_linux.h"

#include <errno.h>
#include <sys/socket.h>
#include <unistd.h>

#include <vector>

#include "base/files/scoped_file.h"
#include "base/logging.h"
#include "base/memory/scoped_vector.h"
#include "base/pickle.h"
#include "base/posix/eintr_wrapper.h"
#include "base/stl_util.h"

#if !defined(OS_NACL_NONSFI)
#include <sys/uio.h>
#endif

namespace base {

const size_t UnixDomainSocket::kMaxFileDescriptors = 16;

#if !defined(OS_NACL_NONSFI)
// Creates a connected pair of UNIX-domain SOCK_SEQPACKET sockets, and passes
// ownership of the newly allocated file descriptors to |one| and |two|.
// Returns true on success.
static bool CreateSocketPair(ScopedFD* one, ScopedFD* two) {
  int raw_socks[2];
  if (socketpair(AF_UNIX, SOCK_SEQPACKET, 0, raw_socks) == -1)
    return false;
  one->reset(raw_socks[0]);
  two->reset(raw_socks[1]);
  return true;
}

// static
bool UnixDomainSocket::EnableReceiveProcessId(int fd) {
  const int enable = 1;
  return setsockopt(fd, SOL_SOCKET, SO_PASSCRED, &enable, sizeof(enable)) == 0;
}
#endif  // !defined(OS_NACL_NONSFI)

// static
bool UnixDomainSocket::SendMsg(int fd,
                               const void* buf,
                               size_t length,
                               const std::vector<int>& fds) {
  struct msghdr msg = {};
  struct iovec iov = { const_cast<void*>(buf), length };
  msg.msg_iov = &iov;
  msg.msg_iovlen = 1;

  char* control_buffer = NULL;
  if (fds.size()) {
    const unsigned control_len = CMSG_SPACE(sizeof(int) * fds.size());
    control_buffer = new char[control_len];

    struct cmsghdr* cmsg;
    msg.msg_control = control_buffer;
    msg.msg_controllen = control_len;
    cmsg = CMSG_FIRSTHDR(&msg);
    cmsg->cmsg_level = SOL_SOCKET;
    cmsg->cmsg_type = SCM_RIGHTS;
    cmsg->cmsg_len = CMSG_LEN(sizeof(int) * fds.size());
    memcpy(CMSG_DATA(cmsg), &fds[0], sizeof(int) * fds.size());
    msg.msg_controllen = cmsg->cmsg_len;
  }

  // Avoid a SIGPIPE if the other end breaks the connection.
  // Due to a bug in the Linux kernel (net/unix/af_unix.c) MSG_NOSIGNAL isn't
  // regarded for SOCK_SEQPACKET in the AF_UNIX domain, but it is mandated by
  // POSIX.
  const int flags = MSG_NOSIGNAL;
  const ssize_t r = HANDLE_EINTR(sendmsg(fd, &msg, flags));
  const bool ret = static_cast<ssize_t>(length) == r;
  delete[] control_buffer;
  return ret;
}

// static
ssize_t UnixDomainSocket::RecvMsg(int fd,
                                  void* buf,
                                  size_t length,
                                  ScopedVector<ScopedFD>* fds) {
  return UnixDomainSocket::RecvMsgWithPid(fd, buf, length, fds, NULL);
}

// static
ssize_t UnixDomainSocket::RecvMsgWithPid(int fd,
                                         void* buf,
                                         size_t length,
                                         ScopedVector<ScopedFD>* fds,
                                         ProcessId* pid) {
  return UnixDomainSocket::RecvMsgWithFlags(fd, buf, length, 0, fds, pid);
}

// static
ssize_t UnixDomainSocket::RecvMsgWithFlags(int fd,
                                           void* buf,
                                           size_t length,
                                           int flags,
                                           ScopedVector<ScopedFD>* fds,
                                           ProcessId* out_pid) {
  fds->clear();

  struct msghdr msg = {};
  struct iovec iov = { buf, length };
  msg.msg_iov = &iov;
  msg.msg_iovlen = 1;

  const size_t kControlBufferSize =
      CMSG_SPACE(sizeof(int) * kMaxFileDescriptors)
#if !defined(OS_NACL_NONSFI)
      // The PNaCl toolchain for Non-SFI binary build does not support ucred.
      + CMSG_SPACE(sizeof(struct ucred))
#endif
      ;
  char control_buffer[kControlBufferSize];
  msg.msg_control = control_buffer;
  msg.msg_controllen = sizeof(control_buffer);

  const ssize_t r = HANDLE_EINTR(recvmsg(fd, &msg, flags));
  if (r == -1)
    return -1;

  int* wire_fds = NULL;
  unsigned wire_fds_len = 0;
  ProcessId pid = -1;

  if (msg.msg_controllen > 0) {
    struct cmsghdr* cmsg;
    for (cmsg = CMSG_FIRSTHDR(&msg); cmsg; cmsg = CMSG_NXTHDR(&msg, cmsg)) {
      const unsigned payload_len = cmsg->cmsg_len - CMSG_LEN(0);
      if (cmsg->cmsg_level == SOL_SOCKET &&
          cmsg->cmsg_type == SCM_RIGHTS) {
        DCHECK_EQ(payload_len % sizeof(int), 0u);
        DCHECK_EQ(wire_fds, static_cast<void*>(nullptr));
        wire_fds = reinterpret_cast<int*>(CMSG_DATA(cmsg));
        wire_fds_len = payload_len / sizeof(int);
      }
#if !defined(OS_NACL_NONSFI)
      // The PNaCl toolchain for Non-SFI binary build does not support
      // SCM_CREDENTIALS.
      if (cmsg->cmsg_level == SOL_SOCKET &&
          cmsg->cmsg_type == SCM_CREDENTIALS) {
        DCHECK_EQ(payload_len, sizeof(struct ucred));
        DCHECK_EQ(pid, -1);
        pid = reinterpret_cast<struct ucred*>(CMSG_DATA(cmsg))->pid;
      }
#endif
    }
  }

  if (msg.msg_flags & MSG_TRUNC || msg.msg_flags & MSG_CTRUNC) {
    for (unsigned i = 0; i < wire_fds_len; ++i)
      close(wire_fds[i]);
    errno = EMSGSIZE;
    return -1;
  }

  if (wire_fds) {
    for (unsigned i = 0; i < wire_fds_len; ++i)
      fds->push_back(new ScopedFD(wire_fds[i]));
  }

  if (out_pid) {
    // |pid| will legitimately be -1 if we read EOF, so only DCHECK if we
    // actually received a message.  Unfortunately, Linux allows sending zero
    // length messages, which are indistinguishable from EOF, so this check
    // has false negatives.
    if (r > 0 || msg.msg_controllen > 0)
      DCHECK_GE(pid, 0);

    *out_pid = pid;
  }

  return r;
}

#if !defined(OS_NACL_NONSFI)
// static
ssize_t UnixDomainSocket::SendRecvMsg(int fd,
                                      uint8_t* reply,
                                      unsigned max_reply_len,
                                      int* result_fd,
                                      const Pickle& request) {
  return UnixDomainSocket::SendRecvMsgWithFlags(fd, reply, max_reply_len,
                                                0,  /* recvmsg_flags */
                                                result_fd, request);
}

// static
ssize_t UnixDomainSocket::SendRecvMsgWithFlags(int fd,
                                               uint8_t* reply,
                                               unsigned max_reply_len,
                                               int recvmsg_flags,
                                               int* result_fd,
                                               const Pickle& request) {
  // This socketpair is only used for the IPC and is cleaned up before
  // returning.
  ScopedFD recv_sock, send_sock;
  if (!CreateSocketPair(&recv_sock, &send_sock))
    return -1;

  {
    std::vector<int> send_fds;
    send_fds.push_back(send_sock.get());
    if (!SendMsg(fd, request.data(), request.size(), send_fds))
      return -1;
  }

  // Close the sending end of the socket right away so that if our peer closes
  // it before sending a response (e.g., from exiting), RecvMsgWithFlags() will
  // return EOF instead of hanging.
  send_sock.reset();

  ScopedVector<ScopedFD> recv_fds;
  // When porting to OSX keep in mind it doesn't support MSG_NOSIGNAL, so the
  // sender might get a SIGPIPE.
  const ssize_t reply_len = RecvMsgWithFlags(
      recv_sock.get(), reply, max_reply_len, recvmsg_flags, &recv_fds, NULL);
  recv_sock.reset();
  if (reply_len == -1)
    return -1;

  // If we received more file descriptors than caller expected, then we treat
  // that as an error.
  if (recv_fds.size() > (result_fd != NULL ? 1 : 0)) {
    NOTREACHED();
    return -1;
  }

  if (result_fd)
    *result_fd = recv_fds.empty() ? -1 : recv_fds[0]->release();

  return reply_len;
}
#endif  // !defined(OS_NACL_NONSFI)

}  // namespace base
