// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "tools/android/forwarder2/socket.h"

#include <arpa/inet.h>
#include <fcntl.h>
#include <netdb.h>
#include <netinet/in.h>
#include <stdio.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <unistd.h>

#include "base/logging.h"
#include "base/posix/eintr_wrapper.h"
#include "base/posix/safe_strerror.h"
#include "tools/android/common/net.h"
#include "tools/android/forwarder2/common.h"

namespace {
const int kNoTimeout = -1;
const int kConnectTimeOut = 10;  // Seconds.

bool FamilyIsTCP(int family) {
  return family == AF_INET || family == AF_INET6;
}
}  // namespace

namespace forwarder2 {

bool Socket::BindUnix(const std::string& path) {
  errno = 0;
  if (!InitUnixSocket(path) || !BindAndListen()) {
    Close();
    return false;
  }
  return true;
}

bool Socket::BindTcp(const std::string& host, int port) {
  errno = 0;
  if (!InitTcpSocket(host, port) || !BindAndListen()) {
    Close();
    return false;
  }
  return true;
}

bool Socket::ConnectUnix(const std::string& path) {
  errno = 0;
  if (!InitUnixSocket(path) || !Connect()) {
    Close();
    return false;
  }
  return true;
}

bool Socket::ConnectTcp(const std::string& host, int port) {
  errno = 0;
  if (!InitTcpSocket(host, port) || !Connect()) {
    Close();
    return false;
  }
  return true;
}

Socket::Socket()
    : socket_(-1),
      port_(0),
      socket_error_(false),
      family_(AF_INET),
      addr_ptr_(reinterpret_cast<sockaddr*>(&addr_.addr4)),
      addr_len_(sizeof(sockaddr)) {
  memset(&addr_, 0, sizeof(addr_));
}

Socket::~Socket() {
  Close();
}

void Socket::Shutdown() {
  if (!IsClosed()) {
    PRESERVE_ERRNO_HANDLE_EINTR(shutdown(socket_, SHUT_RDWR));
  }
}

void Socket::Close() {
  if (!IsClosed()) {
    CloseFD(socket_);
    socket_ = -1;
  }
}

bool Socket::InitSocketInternal() {
  socket_ = socket(family_, SOCK_STREAM, 0);
  if (socket_ < 0) {
    PLOG(ERROR) << "socket";
    return false;
  }
  tools::DisableNagle(socket_);
  int reuse_addr = 1;
  setsockopt(socket_, SOL_SOCKET, SO_REUSEADDR, &reuse_addr,
             sizeof(reuse_addr));
  if (!SetNonBlocking())
    return false;
  return true;
}

bool Socket::SetNonBlocking() {
  const int flags = fcntl(socket_, F_GETFL);
  if (flags < 0) {
    PLOG(ERROR) << "fcntl";
    return false;
  }
  if (flags & O_NONBLOCK)
    return true;
  if (fcntl(socket_, F_SETFL, flags | O_NONBLOCK) < 0) {
    PLOG(ERROR) << "fcntl";
    return false;
  }
  return true;
}

bool Socket::InitUnixSocket(const std::string& path) {
  static const size_t kPathMax = sizeof(addr_.addr_un.sun_path);
  // For abstract sockets we need one extra byte for the leading zero.
  if (path.size() + 2 /* '\0' */ > kPathMax) {
    LOG(ERROR) << "The provided path is too big to create a unix "
               << "domain socket: " << path;
    return false;
  }
  family_ = PF_UNIX;
  addr_.addr_un.sun_family = family_;
  // Copied from net/socket/unix_domain_socket_posix.cc
  // Convert the path given into abstract socket name. It must start with
  // the '\0' character, so we are adding it. |addr_len| must specify the
  // length of the structure exactly, as potentially the socket name may
  // have '\0' characters embedded (although we don't support this).
  // Note that addr_.addr_un.sun_path is already zero initialized.
  memcpy(addr_.addr_un.sun_path + 1, path.c_str(), path.size());
  addr_len_ = path.size() + offsetof(struct sockaddr_un, sun_path) + 1;
  addr_ptr_ = reinterpret_cast<sockaddr*>(&addr_.addr_un);
  return InitSocketInternal();
}

bool Socket::InitTcpSocket(const std::string& host, int port) {
  port_ = port;
  if (host.empty()) {
    // Use localhost: INADDR_LOOPBACK
    family_ = AF_INET;
    addr_.addr4.sin_family = family_;
    addr_.addr4.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
  } else if (!Resolve(host)) {
    return false;
  }
  CHECK(FamilyIsTCP(family_)) << "Invalid socket family.";
  if (family_ == AF_INET) {
    addr_.addr4.sin_port = htons(port_);
    addr_ptr_ = reinterpret_cast<sockaddr*>(&addr_.addr4);
    addr_len_ = sizeof(addr_.addr4);
  } else if (family_ == AF_INET6) {
    addr_.addr6.sin6_port = htons(port_);
    addr_ptr_ = reinterpret_cast<sockaddr*>(&addr_.addr6);
    addr_len_ = sizeof(addr_.addr6);
  }
  return InitSocketInternal();
}

bool Socket::BindAndListen() {
  errno = 0;
  if (HANDLE_EINTR(bind(socket_, addr_ptr_, addr_len_)) < 0 ||
      HANDLE_EINTR(listen(socket_, SOMAXCONN)) < 0) {
    PLOG(ERROR) << "bind/listen";
    SetSocketError();
    return false;
  }
  if (port_ == 0 && FamilyIsTCP(family_)) {
    SockAddr addr;
    memset(&addr, 0, sizeof(addr));
    socklen_t addrlen = 0;
    sockaddr* addr_ptr = NULL;
    uint16* port_ptr = NULL;
    if (family_ == AF_INET) {
      addr_ptr = reinterpret_cast<sockaddr*>(&addr.addr4);
      port_ptr = &addr.addr4.sin_port;
      addrlen = sizeof(addr.addr4);
    } else if (family_ == AF_INET6) {
      addr_ptr = reinterpret_cast<sockaddr*>(&addr.addr6);
      port_ptr = &addr.addr6.sin6_port;
      addrlen = sizeof(addr.addr6);
    }
    errno = 0;
    if (getsockname(socket_, addr_ptr, &addrlen) != 0) {
      PLOG(ERROR) << "getsockname";
      SetSocketError();
      return false;
    }
    port_ = ntohs(*port_ptr);
  }
  return true;
}

bool Socket::Accept(Socket* new_socket) {
  DCHECK(new_socket != NULL);
  if (!WaitForEvent(READ, kNoTimeout)) {
    SetSocketError();
    return false;
  }
  errno = 0;
  int new_socket_fd = HANDLE_EINTR(accept(socket_, NULL, NULL));
  if (new_socket_fd < 0) {
    SetSocketError();
    return false;
  }
  tools::DisableNagle(new_socket_fd);
  new_socket->socket_ = new_socket_fd;
  if (!new_socket->SetNonBlocking())
    return false;
  return true;
}

bool Socket::Connect() {
  DCHECK(fcntl(socket_, F_GETFL) & O_NONBLOCK);
  errno = 0;
  if (HANDLE_EINTR(connect(socket_, addr_ptr_, addr_len_)) < 0 &&
      errno != EINPROGRESS) {
    SetSocketError();
    return false;
  }
  // Wait for connection to complete, or receive a notification.
  if (!WaitForEvent(WRITE, kConnectTimeOut)) {
    SetSocketError();
    return false;
  }
  int socket_errno;
  socklen_t opt_len = sizeof(socket_errno);
  if (getsockopt(socket_, SOL_SOCKET, SO_ERROR, &socket_errno, &opt_len) < 0) {
    PLOG(ERROR) << "getsockopt()";
    SetSocketError();
    return false;
  }
  if (socket_errno != 0) {
    LOG(ERROR) << "Could not connect to host: "
               << base::safe_strerror(socket_errno);
    SetSocketError();
    return false;
  }
  return true;
}

bool Socket::Resolve(const std::string& host) {
  struct addrinfo hints;
  struct addrinfo* res;
  memset(&hints, 0, sizeof(hints));
  hints.ai_family = AF_UNSPEC;
  hints.ai_socktype = SOCK_STREAM;
  hints.ai_flags |= AI_CANONNAME;

  int errcode = getaddrinfo(host.c_str(), NULL, &hints, &res);
  if (errcode != 0) {
    errno = 0;
    SetSocketError();
    freeaddrinfo(res);
    return false;
  }
  family_ = res->ai_family;
  switch (res->ai_family) {
    case AF_INET:
      memcpy(&addr_.addr4,
             reinterpret_cast<sockaddr_in*>(res->ai_addr),
             sizeof(sockaddr_in));
      break;
    case AF_INET6:
      memcpy(&addr_.addr6,
             reinterpret_cast<sockaddr_in6*>(res->ai_addr),
             sizeof(sockaddr_in6));
      break;
  }
  freeaddrinfo(res);
  return true;
}

int Socket::GetPort() {
  if (!FamilyIsTCP(family_)) {
    LOG(ERROR) << "Can't call GetPort() on an unix domain socket.";
    return 0;
  }
  return port_;
}

int Socket::ReadNumBytes(void* buffer, size_t num_bytes) {
  size_t bytes_read = 0;
  int ret = 1;
  while (bytes_read < num_bytes && ret > 0) {
    ret = Read(static_cast<char*>(buffer) + bytes_read, num_bytes - bytes_read);
    if (ret >= 0)
      bytes_read += ret;
  }
  return bytes_read;
}

void Socket::SetSocketError() {
  socket_error_ = true;
  DCHECK_NE(EAGAIN, errno);
  DCHECK_NE(EWOULDBLOCK, errno);
  Close();
}

int Socket::Read(void* buffer, size_t buffer_size) {
  if (!WaitForEvent(READ, kNoTimeout)) {
    SetSocketError();
    return 0;
  }
  int ret = HANDLE_EINTR(read(socket_, buffer, buffer_size));
  if (ret < 0) {
    PLOG(ERROR) << "read";
    SetSocketError();
  }
  return ret;
}

int Socket::NonBlockingRead(void* buffer, size_t buffer_size) {
  DCHECK(fcntl(socket_, F_GETFL) & O_NONBLOCK);
  int ret = HANDLE_EINTR(read(socket_, buffer, buffer_size));
  if (ret < 0) {
    PLOG(ERROR) << "read";
    SetSocketError();
  }
  return ret;
}

int Socket::Write(const void* buffer, size_t count) {
  if (!WaitForEvent(WRITE, kNoTimeout)) {
    SetSocketError();
    return 0;
  }
  int ret = HANDLE_EINTR(send(socket_, buffer, count, MSG_NOSIGNAL));
  if (ret < 0) {
    PLOG(ERROR) << "send";
    SetSocketError();
  }
  return ret;
}

int Socket::NonBlockingWrite(const void* buffer, size_t count) {
  DCHECK(fcntl(socket_, F_GETFL) & O_NONBLOCK);
  int ret = HANDLE_EINTR(send(socket_, buffer, count, MSG_NOSIGNAL));
  if (ret < 0) {
    PLOG(ERROR) << "send";
    SetSocketError();
  }
  return ret;
}

int Socket::WriteString(const std::string& buffer) {
  return WriteNumBytes(buffer.c_str(), buffer.size());
}

void Socket::AddEventFd(int event_fd) {
  Event event;
  event.fd = event_fd;
  event.was_fired = false;
  events_.push_back(event);
}

bool Socket::DidReceiveEventOnFd(int fd) const {
  for (size_t i = 0; i < events_.size(); ++i)
    if (events_[i].fd == fd)
      return events_[i].was_fired;
  return false;
}

bool Socket::DidReceiveEvent() const {
  for (size_t i = 0; i < events_.size(); ++i)
    if (events_[i].was_fired)
      return true;
  return false;
}

int Socket::WriteNumBytes(const void* buffer, size_t num_bytes) {
  size_t bytes_written = 0;
  int ret = 1;
  while (bytes_written < num_bytes && ret > 0) {
    ret = Write(static_cast<const char*>(buffer) + bytes_written,
                num_bytes - bytes_written);
    if (ret >= 0)
      bytes_written += ret;
  }
  return bytes_written;
}

bool Socket::WaitForEvent(EventType type, int timeout_secs) {
  if (socket_ == -1)
    return true;
  DCHECK(fcntl(socket_, F_GETFL) & O_NONBLOCK);
  fd_set read_fds;
  fd_set write_fds;
  FD_ZERO(&read_fds);
  FD_ZERO(&write_fds);
  if (type == READ)
    FD_SET(socket_, &read_fds);
  else
    FD_SET(socket_, &write_fds);
  for (size_t i = 0; i < events_.size(); ++i)
    FD_SET(events_[i].fd, &read_fds);
  timeval tv = {};
  timeval* tv_ptr = NULL;
  if (timeout_secs > 0) {
    tv.tv_sec = timeout_secs;
    tv.tv_usec = 0;
    tv_ptr = &tv;
  }
  int max_fd = socket_;
  for (size_t i = 0; i < events_.size(); ++i)
    if (events_[i].fd > max_fd)
      max_fd = events_[i].fd;
  if (HANDLE_EINTR(
          select(max_fd + 1, &read_fds, &write_fds, NULL, tv_ptr)) <= 0) {
    PLOG(ERROR) << "select";
    return false;
  }
  bool event_was_fired = false;
  for (size_t i = 0; i < events_.size(); ++i) {
    if (FD_ISSET(events_[i].fd, &read_fds)) {
      events_[i].was_fired = true;
      event_was_fired = true;
    }
  }
  return !event_was_fired;
}

// static
pid_t Socket::GetUnixDomainSocketProcessOwner(const std::string& path) {
  Socket socket;
  if (!socket.ConnectUnix(path))
    return -1;
  ucred ucred;
  socklen_t len = sizeof(ucred);
  if (getsockopt(socket.socket_, SOL_SOCKET, SO_PEERCRED, &ucred, &len) == -1) {
    CHECK_NE(ENOPROTOOPT, errno);
    return -1;
  }
  return ucred.pid;
}

}  // namespace forwarder2
