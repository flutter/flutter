// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_DART_EMBEDDER_IO_INTERNET_ADDRESS_H_
#define MOJO_DART_EMBEDDER_IO_INTERNET_ADDRESS_H_

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "base/logging.h"
#include "base/macros.h"
#include "dart/runtime/include/dart_api.h"

namespace mojo {
namespace dart {

#define IPV4_RAW_ADDR_LENGTH 4
#define IPV6_RAW_ADDR_LENGTH 16

struct RawAddr {
  uint8_t bytes[IPV6_RAW_ADDR_LENGTH];
};

class InternetAddress {
 public:
  enum {
    TYPE_ANY = -1,
    TYPE_IPV4,
    TYPE_IPV6,
  };

  static bool Parse(int type, const char* address, RawAddr* addr);

  static bool Reverse(const RawAddr& addr, intptr_t addr_length,
                      char* host, intptr_t host_len,
                      intptr_t* error_code, const char** error_description);

 private:
  DISALLOW_IMPLICIT_CONSTRUCTORS(InternetAddress);
};

}  // namespace dart
}  // namespace mojo

#endif  // MOJO_DART_EMBEDDER_IO_INTERNET_ADDRESS_H_

