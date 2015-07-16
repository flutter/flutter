// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_PUBLIC_CPP_BINDINGS_LIB_MESSAGE_INTERNAL_H_
#define MOJO_PUBLIC_CPP_BINDINGS_LIB_MESSAGE_INTERNAL_H_

#include "mojo/public/cpp/bindings/lib/bindings_internal.h"

namespace mojo {
namespace internal {

#pragma pack(push, 1)

enum { kMessageExpectsResponse = 1 << 0, kMessageIsResponse = 1 << 1 };

struct MessageHeader : internal::StructHeader {
  uint32_t name;
  uint32_t flags;
};
static_assert(sizeof(MessageHeader) == 16, "Bad sizeof(MessageHeader)");

struct MessageHeaderWithRequestID : MessageHeader {
  uint64_t request_id;
};
static_assert(sizeof(MessageHeaderWithRequestID) == 24,
              "Bad sizeof(MessageHeaderWithRequestID)");

struct MessageData {
  MessageHeader header;
};

static_assert(sizeof(MessageData) == sizeof(MessageHeader),
              "Bad sizeof(MessageData)");

#pragma pack(pop)

}  // namespace internal
}  // namespace mojo

#endif  // MOJO_PUBLIC_CPP_BINDINGS_LIB_MESSAGE_INTERNAL_H_
