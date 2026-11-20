// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_PLATFORM_POSIX_UNIX_DOMAIN_SOCKET_POSIX_H_
#define FLUTTER_FML_PLATFORM_POSIX_UNIX_DOMAIN_SOCKET_POSIX_H_

#include <sys/types.h>

#include <cstdint>
#include <optional>
#include <span>
#include <string_view>
#include <utility>

#include "flutter/fml/macros.h"
#include "flutter/fml/unique_fd.h"

namespace fml {

/// RAII wrapper around a connected POSIX `AF_UNIX` `SOCK_STREAM` socket with
/// support for `SCM_RIGHTS` file-descriptor passing.
class UnixDomainSocket {
 public:
  UnixDomainSocket() = default;
  explicit UnixDomainSocket(fml::UniqueFD fd);

  UnixDomainSocket(UnixDomainSocket&&) noexcept = default;
  UnixDomainSocket& operator=(UnixDomainSocket&&) noexcept = default;

  ~UnixDomainSocket() = default;

  /// Connects a stream socket to the filesystem path `path`.
  static std::optional<UnixDomainSocket> Connect(std::string_view path);

  /// Creates a connected pair of anonymous `AF_UNIX` stream sockets.
  static std::optional<std::pair<UnixDomainSocket, UnixDomainSocket>>
  CreatePair();

  /// Sends all bytes in `data` (optionally attaching `fd_to_send` via
  /// `SCM_RIGHTS` on the first send call).
  bool Send(std::span<const uint8_t> data, int fd_to_send = -1) const;

  /// Receives up to `buffer.size()` bytes into `buffer`. If the peer attached a
  /// file descriptor via `SCM_RIGHTS`, stores it in `*out_fd` (when non-null)
  /// or closes it immediately to prevent descriptor leaks.
  ssize_t Receive(std::span<uint8_t> buffer,
                  fml::UniqueFD* out_fd = nullptr) const;

  bool is_valid() const { return fd_.is_valid(); }
  const fml::UniqueFD& fd() const { return fd_; }
  void Reset() { fd_.reset(); }

 private:
  fml::UniqueFD fd_;

  FML_DISALLOW_COPY_AND_ASSIGN(UnixDomainSocket);
};

}  // namespace fml

#endif  // FLUTTER_FML_PLATFORM_POSIX_UNIX_DOMAIN_SOCKET_POSIX_H_
