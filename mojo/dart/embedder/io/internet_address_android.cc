// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <arpa/inet.h>
#include <netdb.h>
#include <sys/socket.h>

#include "mojo/dart/embedder/io/internet_address.h"

namespace mojo {
namespace dart {

static void SetupSockAddr(sockaddr_storage* dest,
                          socklen_t* salen,
                          const RawAddr& addr, intptr_t addr_length) {
  CHECK((addr_length == 4) || (addr_length == 16));
  if (addr_length == 4) {
    dest->ss_family = AF_INET;
    sockaddr_in* dest4 = reinterpret_cast<sockaddr_in*>(dest);
    *salen = sizeof(*dest4);
    memmove(&(dest4->sin_addr), &addr.bytes[0], addr_length);
  } else {
    dest->ss_family = AF_INET6;
    sockaddr_in6* dest6 = reinterpret_cast<sockaddr_in6*>(dest);
    *salen = sizeof(*dest6);
    memmove(&(dest6->sin6_addr), &addr.bytes[0], addr_length);
  }
}

bool InternetAddress::Parse(int type, const char* address, RawAddr* addr) {
  memset(addr, 0, IPV6_RAW_ADDR_LENGTH);
  int result;
  if (type == InternetAddress::TYPE_IPV4) {
    struct sockaddr_in in;
    result = inet_pton(AF_INET, address, &in.sin_addr);
    memmove(addr, &in.sin_addr, IPV4_RAW_ADDR_LENGTH);
  } else {
    CHECK(type == InternetAddress::TYPE_IPV6);
    sockaddr_in6 in6;
    result = inet_pton(AF_INET6, address, &in6.sin6_addr);
    memmove(addr, &in6.sin6_addr, IPV6_RAW_ADDR_LENGTH);
  }
  return result == 1;
}

bool InternetAddress::Reverse(const RawAddr& addr, intptr_t addr_length,
                              char* host, intptr_t host_len,
                              intptr_t* error_code,
                              const char** error_description) {
  CHECK(host_len >= NI_MAXHOST);
  sockaddr_storage sock_addr;
  socklen_t salen;
  SetupSockAddr(&sock_addr, &salen, addr, addr_length);
  int status = getnameinfo(reinterpret_cast<sockaddr*>(&sock_addr),
                           salen,
                           host,
                           host_len,
                           NULL,
                           0,
                           NI_NAMEREQD);
  *error_code = status;
  if (status != 0) {
    CHECK(*error_description == NULL);
    *error_description = gai_strerror(status);
    return false;
  }
  return true;
}

}  // namespace dart
}  // namespace mojo
