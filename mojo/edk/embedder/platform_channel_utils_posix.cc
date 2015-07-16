// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/embedder/platform_channel_utils_posix.h"

#include <sys/socket.h>
#include <sys/uio.h>
#include <unistd.h>

#include "base/logging.h"
#include "base/posix/eintr_wrapper.h"
#include "build/build_config.h"

namespace mojo {
namespace embedder {

// On Linux, |SIGPIPE| is suppressed by passing |MSG_NOSIGNAL| to
// |send()|/|sendmsg()|. (There is no way of suppressing |SIGPIPE| on
// |write()|/|writev().) On Mac, |SIGPIPE| is suppressed by setting the
// |SO_NOSIGPIPE| option on the socket.
//
// Performance notes:
//  - On Linux, we have to use |send()|/|sendmsg()| rather than
//    |write()|/|writev()| in order to suppress |SIGPIPE|. This is okay, since
//    |send()| is (slightly) faster than |write()| (!), while |sendmsg()| is
//    quite comparable to |writev()|.
//  - On Mac, we may use |write()|/|writev()|. Here, |write()| is considerably
//    faster than |send()|, whereas |sendmsg()| is quite comparable to
//    |writev()|.
//  - On both platforms, an appropriate |sendmsg()|/|writev()| is considerably
//    faster than two |send()|s/|write()|s.
//  - Relative numbers (minimum real times from 10 runs) for one |write()| of
//    1032 bytes, one |send()| of 1032 bytes, one |writev()| of 32+1000 bytes,
//    one |sendmsg()| of 32+1000 bytes, two |write()|s of 32 and 1000 bytes, two
//    |send()|s of 32 and 1000 bytes:
//    - Linux: 0.81 s, 0.77 s, 0.87 s, 0.89 s, 1.31 s, 1.22 s
//    - Mac: 2.21 s, 2.91 s, 2.98 s, 3.08 s, 3.59 s, 4.74 s

// Flags to use with calling |send()| or |sendmsg()| (see above).
#if defined(OS_MACOSX)
const int kSendFlags = 0;
#else
const int kSendFlags = MSG_NOSIGNAL;
#endif

ssize_t PlatformChannelWrite(PlatformHandle h,
                             const void* bytes,
                             size_t num_bytes) {
  DCHECK(h.is_valid());
  DCHECK(bytes);
  DCHECK_GT(num_bytes, 0u);

#if defined(OS_MACOSX)
  return HANDLE_EINTR(write(h.fd, bytes, num_bytes));
#else
  return send(h.fd, bytes, num_bytes, kSendFlags);
#endif
}

ssize_t PlatformChannelWritev(PlatformHandle h,
                              struct iovec* iov,
                              size_t num_iov) {
  DCHECK(h.is_valid());
  DCHECK(iov);
  DCHECK_GT(num_iov, 0u);

#if defined(OS_MACOSX)
  return HANDLE_EINTR(writev(h.fd, iov, static_cast<int>(num_iov)));
#else
  struct msghdr msg = {};
  msg.msg_iov = iov;
  msg.msg_iovlen = num_iov;
  return HANDLE_EINTR(sendmsg(h.fd, &msg, kSendFlags));
#endif
}

ssize_t PlatformChannelSendmsgWithHandles(PlatformHandle h,
                                          struct iovec* iov,
                                          size_t num_iov,
                                          PlatformHandle* platform_handles,
                                          size_t num_platform_handles) {
  DCHECK(iov);
  DCHECK_GT(num_iov, 0u);
  DCHECK(platform_handles);
  DCHECK_GT(num_platform_handles, 0u);
  DCHECK_LE(num_platform_handles, kPlatformChannelMaxNumHandles);

  char cmsg_buf[CMSG_SPACE(kPlatformChannelMaxNumHandles * sizeof(int))];
  struct msghdr msg = {};
  msg.msg_iov = iov;
  msg.msg_iovlen = num_iov;
  msg.msg_control = cmsg_buf;
  msg.msg_controllen = CMSG_LEN(num_platform_handles * sizeof(int));
  struct cmsghdr* cmsg = CMSG_FIRSTHDR(&msg);
  cmsg->cmsg_level = SOL_SOCKET;
  cmsg->cmsg_type = SCM_RIGHTS;
  cmsg->cmsg_len = CMSG_LEN(num_platform_handles * sizeof(int));
  for (size_t i = 0; i < num_platform_handles; i++) {
    DCHECK(platform_handles[i].is_valid());
    reinterpret_cast<int*>(CMSG_DATA(cmsg))[i] = platform_handles[i].fd;
  }

  return HANDLE_EINTR(sendmsg(h.fd, &msg, kSendFlags));
}

bool PlatformChannelSendHandles(PlatformHandle h,
                                PlatformHandle* handles,
                                size_t num_handles) {
  DCHECK(handles);
  DCHECK_GT(num_handles, 0u);
  DCHECK_LE(num_handles, kPlatformChannelMaxNumHandles);

  // Note: |sendmsg()| fails on Mac if we don't write at least one character.
  struct iovec iov = {const_cast<char*>(""), 1};
  char cmsg_buf[CMSG_SPACE(kPlatformChannelMaxNumHandles * sizeof(int))];
  struct msghdr msg = {};
  msg.msg_iov = &iov;
  msg.msg_iovlen = 1;
  msg.msg_control = cmsg_buf;
  msg.msg_controllen = CMSG_LEN(num_handles * sizeof(int));
  struct cmsghdr* cmsg = CMSG_FIRSTHDR(&msg);
  cmsg->cmsg_level = SOL_SOCKET;
  cmsg->cmsg_type = SCM_RIGHTS;
  cmsg->cmsg_len = CMSG_LEN(num_handles * sizeof(int));
  for (size_t i = 0; i < num_handles; i++) {
    DCHECK(handles[i].is_valid());
    reinterpret_cast<int*>(CMSG_DATA(cmsg))[i] = handles[i].fd;
  }

  ssize_t result = HANDLE_EINTR(sendmsg(h.fd, &msg, kSendFlags));
  if (result < 1) {
    DCHECK_EQ(result, -1);
    return false;
  }

  for (size_t i = 0; i < num_handles; i++)
    handles[i].CloseIfNecessary();
  return true;
}

ssize_t PlatformChannelRecvmsg(PlatformHandle h,
                               void* buf,
                               size_t num_bytes,
                               std::deque<PlatformHandle>* platform_handles) {
  DCHECK(buf);
  DCHECK_GT(num_bytes, 0u);
  DCHECK(platform_handles);

  struct iovec iov = {buf, num_bytes};
  char cmsg_buf[CMSG_SPACE(kPlatformChannelMaxNumHandles * sizeof(int))];
  struct msghdr msg = {};
  msg.msg_iov = &iov;
  msg.msg_iovlen = 1;
  msg.msg_control = cmsg_buf;
  msg.msg_controllen = sizeof(cmsg_buf);

  ssize_t result = HANDLE_EINTR(recvmsg(h.fd, &msg, MSG_DONTWAIT));
  if (result < 0)
    return result;

  // Success; no control messages.
  if (msg.msg_controllen == 0)
    return result;

  DCHECK(!(msg.msg_flags & MSG_CTRUNC));

  for (cmsghdr* cmsg = CMSG_FIRSTHDR(&msg); cmsg;
       cmsg = CMSG_NXTHDR(&msg, cmsg)) {
    if (cmsg->cmsg_level == SOL_SOCKET && cmsg->cmsg_type == SCM_RIGHTS) {
      size_t payload_length = cmsg->cmsg_len - CMSG_LEN(0);
      DCHECK_EQ(payload_length % sizeof(int), 0u);
      size_t num_fds = payload_length / sizeof(int);
      const int* fds = reinterpret_cast<int*>(CMSG_DATA(cmsg));
      for (size_t i = 0; i < num_fds; i++) {
        platform_handles->push_back(PlatformHandle(fds[i]));
        DCHECK(platform_handles->back().is_valid());
      }
    }
  }

  return result;
}

}  // namespace embedder
}  // namespace mojo
