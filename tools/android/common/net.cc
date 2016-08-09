// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "tools/android/common/net.h"

#include <netinet/in.h>
#include <netinet/tcp.h>
#include <sys/socket.h>
#include <sys/types.h>

#include "base/strings/stringprintf.h"

namespace tools {

int DisableNagle(int socket) {
  int on = 1;
  return setsockopt(socket, IPPROTO_TCP, TCP_NODELAY, &on, sizeof(on));
}

int DeferAccept(int socket) {
  int on = 1;
  return setsockopt(socket, IPPROTO_TCP, TCP_DEFER_ACCEPT, &on, sizeof(on));
}

std::string DumpBinary(const char* buffer, size_t length) {
  std::string result = "[";
  for (size_t i = 0; i < length; ++i) {
    base::StringAppendF(&result, "%02x,",
                        static_cast<unsigned char>(buffer[i]));
  }

  if (length)
    result.erase(result.length() - 1);

  return result + "]";
}

}  // namespace tools

