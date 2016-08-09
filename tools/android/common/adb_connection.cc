// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "tools/android/common/adb_connection.h"

#include <arpa/inet.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <unistd.h>

#include "base/logging.h"
#include "base/posix/eintr_wrapper.h"
#include "tools/android/common/net.h"

namespace tools {
namespace {

void CloseSocket(int fd) {
  if (fd >= 0) {
    int old_errno = errno;
    close(fd);
    errno = old_errno;
  }
}

}  // namespace

int ConnectAdbHostSocket(const char* forward_to) {
  // ADB port forward request format: HHHHtcp:port:address.
  // HHHH is the hexidecimal length of the "tcp:port:address" part.
  const size_t kBufferMaxLength = 30;
  const size_t kLengthOfLength = 4;

  const char kAddressPrefix[] = { 't', 'c', 'p', ':' };
  size_t address_length = arraysize(kAddressPrefix) + strlen(forward_to);
  if (address_length > kBufferMaxLength - kLengthOfLength) {
    LOG(ERROR) << "Forward to address is too long: " << forward_to;
    return -1;
  }

  char request[kBufferMaxLength];
  memcpy(request + kLengthOfLength, kAddressPrefix, arraysize(kAddressPrefix));
  memcpy(request + kLengthOfLength + arraysize(kAddressPrefix),
         forward_to, strlen(forward_to));

  char length_buffer[kLengthOfLength + 1];
  snprintf(length_buffer, arraysize(length_buffer), "%04X",
           static_cast<int>(address_length));
  memcpy(request, length_buffer, kLengthOfLength);

  int host_socket = socket(AF_INET, SOCK_STREAM, 0);
  if (host_socket < 0) {
    LOG(ERROR) << "Failed to create adb socket: " << strerror(errno);
    return -1;
  }

  DisableNagle(host_socket);

  const int kAdbPort = 5037;
  sockaddr_in addr;
  memset(&addr, 0, sizeof(addr));
  addr.sin_family = AF_INET;
  addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
  addr.sin_port = htons(kAdbPort);
  if (HANDLE_EINTR(connect(host_socket, reinterpret_cast<sockaddr*>(&addr),
                           sizeof(addr))) < 0) {
    LOG(ERROR) << "Failed to connect adb socket: " << strerror(errno);
    CloseSocket(host_socket);
    return -1;
  }

  size_t bytes_remaining = address_length + kLengthOfLength;
  size_t bytes_sent = 0;
  while (bytes_remaining > 0) {
    int ret = HANDLE_EINTR(send(host_socket, request + bytes_sent,
                                bytes_remaining, 0));
    if (ret < 0) {
      LOG(ERROR) << "Failed to send request: " << strerror(errno);
      CloseSocket(host_socket);
      return -1;
    }

    bytes_sent += ret;
    bytes_remaining -= ret;
  }

  const int kAdbStatusLength = 4;
  char response[kBufferMaxLength];
  int response_length = HANDLE_EINTR(recv(host_socket, response,
                                          kBufferMaxLength, 0));
  if (response_length < kAdbStatusLength ||
      strncmp("OKAY", response, kAdbStatusLength) != 0) {
    LOG(ERROR) << "Bad response from ADB: length: " << response_length
               << " data: " << DumpBinary(response, response_length);
    CloseSocket(host_socket);
    return -1;
  }

  return host_socket;
}

}  // namespace tools
