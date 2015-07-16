// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <sys/socket.h>
#include <sys/types.h>
#include <unistd.h>

#include "base/bind.h"
#include "base/bind_helpers.h"
#include "base/files/file_util.h"
#include "base/files/scoped_file.h"
#include "base/location.h"
#include "base/memory/scoped_vector.h"
#include "base/pickle.h"
#include "base/posix/unix_domain_socket_linux.h"
#include "base/single_thread_task_runner.h"
#include "base/synchronization/waitable_event.h"
#include "base/threading/thread.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {

namespace {

TEST(UnixDomainSocketTest, SendRecvMsgAbortOnReplyFDClose) {
  Thread message_thread("UnixDomainSocketTest");
  ASSERT_TRUE(message_thread.Start());

  int fds[2];
  ASSERT_EQ(0, socketpair(AF_UNIX, SOCK_SEQPACKET, 0, fds));
  ScopedFD scoped_fd0(fds[0]);
  ScopedFD scoped_fd1(fds[1]);

  // Have the thread send a synchronous message via the socket.
  Pickle request;
  message_thread.task_runner()->PostTask(
      FROM_HERE,
      Bind(IgnoreResult(&UnixDomainSocket::SendRecvMsg), fds[1],
           static_cast<uint8_t*>(NULL), 0U, static_cast<int*>(NULL), request));

  // Receive the message.
  ScopedVector<ScopedFD> message_fds;
  uint8_t buffer[16];
  ASSERT_EQ(static_cast<int>(request.size()),
            UnixDomainSocket::RecvMsg(fds[0], buffer, sizeof(buffer),
                                      &message_fds));
  ASSERT_EQ(1U, message_fds.size());

  // Close the reply FD.
  message_fds.clear();

  // Check that the thread didn't get blocked.
  WaitableEvent event(false, false);
  message_thread.task_runner()->PostTask(
      FROM_HERE, Bind(&WaitableEvent::Signal, Unretained(&event)));
  ASSERT_TRUE(event.TimedWait(TimeDelta::FromMilliseconds(5000)));
}

TEST(UnixDomainSocketTest, SendRecvMsgAvoidsSIGPIPE) {
  // Make sure SIGPIPE isn't being ignored.
  struct sigaction act = {}, oldact;
  act.sa_handler = SIG_DFL;
  ASSERT_EQ(0, sigaction(SIGPIPE, &act, &oldact));
  int fds[2];
  ASSERT_EQ(0, socketpair(AF_UNIX, SOCK_SEQPACKET, 0, fds));
  ScopedFD scoped_fd1(fds[1]);
  ASSERT_EQ(0, IGNORE_EINTR(close(fds[0])));

  // Have the thread send a synchronous message via the socket. Unless the
  // message is sent with MSG_NOSIGNAL, this shall result in SIGPIPE.
  Pickle request;
  ASSERT_EQ(-1,
      UnixDomainSocket::SendRecvMsg(fds[1], static_cast<uint8_t*>(NULL),
                                    0U, static_cast<int*>(NULL), request));
  ASSERT_EQ(EPIPE, errno);
  // Restore the SIGPIPE handler.
  ASSERT_EQ(0, sigaction(SIGPIPE, &oldact, NULL));
}

// Simple sanity check within a single process that receiving PIDs works.
TEST(UnixDomainSocketTest, RecvPid) {
  int fds[2];
  ASSERT_EQ(0, socketpair(AF_UNIX, SOCK_SEQPACKET, 0, fds));
  ScopedFD recv_sock(fds[0]);
  ScopedFD send_sock(fds[1]);

  ASSERT_TRUE(UnixDomainSocket::EnableReceiveProcessId(recv_sock.get()));

  static const char kHello[] = "hello";
  ASSERT_TRUE(UnixDomainSocket::SendMsg(
      send_sock.get(), kHello, sizeof(kHello), std::vector<int>()));

  // Extra receiving buffer space to make sure we really received only
  // sizeof(kHello) bytes and it wasn't just truncated to fit the buffer.
  char buf[sizeof(kHello) + 1];
  ProcessId sender_pid;
  ScopedVector<ScopedFD> fd_vec;
  const ssize_t nread = UnixDomainSocket::RecvMsgWithPid(
      recv_sock.get(), buf, sizeof(buf), &fd_vec, &sender_pid);
  ASSERT_EQ(sizeof(kHello), static_cast<size_t>(nread));
  ASSERT_EQ(0, memcmp(buf, kHello, sizeof(kHello)));
  ASSERT_EQ(0U, fd_vec.size());

  ASSERT_EQ(getpid(), sender_pid);
}

// Same as above, but send the max number of file descriptors too.
TEST(UnixDomainSocketTest, RecvPidWithMaxDescriptors) {
  int fds[2];
  ASSERT_EQ(0, socketpair(AF_UNIX, SOCK_SEQPACKET, 0, fds));
  ScopedFD recv_sock(fds[0]);
  ScopedFD send_sock(fds[1]);

  ASSERT_TRUE(UnixDomainSocket::EnableReceiveProcessId(recv_sock.get()));

  static const char kHello[] = "hello";
  std::vector<int> send_fds(UnixDomainSocket::kMaxFileDescriptors,
                            send_sock.get());
  ASSERT_TRUE(UnixDomainSocket::SendMsg(
      send_sock.get(), kHello, sizeof(kHello), send_fds));

  // Extra receiving buffer space to make sure we really received only
  // sizeof(kHello) bytes and it wasn't just truncated to fit the buffer.
  char buf[sizeof(kHello) + 1];
  ProcessId sender_pid;
  ScopedVector<ScopedFD> recv_fds;
  const ssize_t nread = UnixDomainSocket::RecvMsgWithPid(
      recv_sock.get(), buf, sizeof(buf), &recv_fds, &sender_pid);
  ASSERT_EQ(sizeof(kHello), static_cast<size_t>(nread));
  ASSERT_EQ(0, memcmp(buf, kHello, sizeof(kHello)));
  ASSERT_EQ(UnixDomainSocket::kMaxFileDescriptors, recv_fds.size());

  ASSERT_EQ(getpid(), sender_pid);
}

// Check that RecvMsgWithPid doesn't DCHECK fail when reading EOF from a
// disconnected socket.
TEST(UnixDomianSocketTest, RecvPidDisconnectedSocket) {
  int fds[2];
  ASSERT_EQ(0, socketpair(AF_UNIX, SOCK_SEQPACKET, 0, fds));
  ScopedFD recv_sock(fds[0]);
  ScopedFD send_sock(fds[1]);

  ASSERT_TRUE(UnixDomainSocket::EnableReceiveProcessId(recv_sock.get()));

  send_sock.reset();

  char ch;
  ProcessId sender_pid;
  ScopedVector<ScopedFD> recv_fds;
  const ssize_t nread = UnixDomainSocket::RecvMsgWithPid(
      recv_sock.get(), &ch, sizeof(ch), &recv_fds, &sender_pid);
  ASSERT_EQ(0, nread);
  ASSERT_EQ(-1, sender_pid);
  ASSERT_EQ(0U, recv_fds.size());
}

}  // namespace

}  // namespace base
