// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/platform/posix/unix_domain_socket_posix.h"

#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>

#include <algorithm>
#include <array>

#include "flutter/fml/eintr_wrapper.h"

namespace fml {

UnixDomainSocket::UnixDomainSocket(fml::UniqueFD fd) : fd_(std::move(fd)) {}

std::optional<UnixDomainSocket> UnixDomainSocket::Connect(
    std::string_view path) {
  struct sockaddr_un addr = {};
  if (path.empty() || path.size() >= sizeof(addr.sun_path)) {
    return std::nullopt;
  }
  fml::UniqueFD sock(
      ::socket(AF_UNIX, SOCK_STREAM | SOCK_CLOEXEC, /*protocol=*/0));
  if (!sock.is_valid()) {
    return std::nullopt;
  }
  addr.sun_family = AF_UNIX;
  path.copy(addr.sun_path, path.size());

  if (FML_HANDLE_EINTR(
          ::connect(sock.get(), reinterpret_cast<const struct sockaddr*>(&addr),
                    sizeof(addr))) != 0) {
    return std::nullopt;
  }
  return UnixDomainSocket(std::move(sock));
}

std::optional<std::pair<UnixDomainSocket, UnixDomainSocket>>
UnixDomainSocket::CreatePair() {
  std::array<int, 2> fds = {-1, -1};
  if (::socketpair(AF_UNIX, SOCK_STREAM | SOCK_CLOEXEC, /*protocol=*/0,
                   fds.data()) != 0) {
    return std::nullopt;
  }
  return std::make_pair(UnixDomainSocket(fml::UniqueFD(fds[0])),
                        UnixDomainSocket(fml::UniqueFD(fds[1])));
}

bool UnixDomainSocket::Send(std::span<const uint8_t> data,
                            int fd_to_send) const {
  if (!fd_.is_valid()) {
    return false;
  }
  if (data.empty() && fd_to_send < 0) {
    return true;
  }

  size_t offset = 0;
  int pending_fd = fd_to_send;
  while (offset < data.size() || pending_fd >= 0) {
    struct iovec iov = {
        .iov_base = const_cast<uint8_t*>(data.data() + offset),
        .iov_len = data.size() - offset,
    };
    alignas(struct cmsghdr) std::array<char, CMSG_SPACE(sizeof(int))> cmsg_buf =
        {};
    struct msghdr msg = {};
    msg.msg_iov = &iov;
    msg.msg_iovlen = 1;

    if (pending_fd >= 0) {
      msg.msg_control = cmsg_buf.data();
      msg.msg_controllen = cmsg_buf.size();
      struct cmsghdr* cmsg = CMSG_FIRSTHDR(&msg);
      cmsg->cmsg_level = SOL_SOCKET;
      cmsg->cmsg_type = SCM_RIGHTS;
      cmsg->cmsg_len = CMSG_LEN(sizeof(int));
      const auto* fd_bytes = reinterpret_cast<const uint8_t*>(&pending_fd);
      std::copy_n(fd_bytes, sizeof(int), CMSG_DATA(cmsg));
    }

    const ssize_t sent =
        FML_HANDLE_EINTR(::sendmsg(fd_.get(), &msg, MSG_NOSIGNAL));
    if (sent < 0) {
      return false;
    }
    offset += static_cast<size_t>(sent);
    pending_fd = -1;
  }
  return true;
}

ssize_t UnixDomainSocket::Receive(std::span<uint8_t> buffer,
                                  fml::UniqueFD* out_fd) const {
  if (!fd_.is_valid() || buffer.empty()) {
    return -1;
  }

  struct iovec iov = {
      .iov_base = buffer.data(),
      .iov_len = buffer.size(),
  };
  alignas(struct cmsghdr) std::array<char, CMSG_SPACE(sizeof(int))> cmsg_buf =
      {};
  struct msghdr msg = {};
  msg.msg_iov = &iov;
  msg.msg_iovlen = 1;
  msg.msg_control = cmsg_buf.data();
  msg.msg_controllen = cmsg_buf.size();

  const ssize_t received =
      FML_HANDLE_EINTR(::recvmsg(fd_.get(), &msg, MSG_CMSG_CLOEXEC));
  if (received <= 0) {
    return received;
  }

  for (struct cmsghdr* cmsg = CMSG_FIRSTHDR(&msg); cmsg != nullptr;
       cmsg = CMSG_NXTHDR(&msg, cmsg)) {
    if (cmsg->cmsg_level == SOL_SOCKET && cmsg->cmsg_type == SCM_RIGHTS &&
        cmsg->cmsg_len >= CMSG_LEN(sizeof(int))) {
      const size_t num_fds = (cmsg->cmsg_len - CMSG_LEN(0)) / sizeof(int);
      for (size_t i = 0; i < num_fds; ++i) {
        int raw_fd = -1;
        std::copy_n(CMSG_DATA(cmsg) + i * sizeof(int), sizeof(int),
                    reinterpret_cast<uint8_t*>(&raw_fd));
        fml::UniqueFD received_fd(raw_fd);
        if (i == 0 && out_fd != nullptr) {
          *out_fd = std::move(received_fd);
        }
      }
    }
  }
  return received;
}

}  // namespace fml
