// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_PUBLIC_CPP_BINDINGS_LIB_VALIDATION_UTIL_H_
#define MOJO_PUBLIC_CPP_BINDINGS_LIB_VALIDATION_UTIL_H_

#include <stdint.h>

#include "mojo/public/cpp/bindings/lib/bounds_checker.h"
#include "mojo/public/cpp/bindings/message.h"

namespace mojo {
namespace internal {

// Checks whether decoding the pointer will overflow and produce a pointer
// smaller than |offset|.
bool ValidateEncodedPointer(const uint64_t* offset);

// Validates that |data| contains a valid struct header, in terms of alignment
// and size (i.e., the |num_bytes| field of the header is sufficient for storing
// the header itself). Besides, it checks that the memory range
// [data, data + num_bytes) is not marked as occupied by other objects in
// |bounds_checker|. On success, the memory range is marked as occupied.
// Note: Does not verify |version| or that |num_bytes| is correct for the
// claimed version.
bool ValidateStructHeaderAndClaimMemory(const void* data,
                                        BoundsChecker* bounds_checker);

// Validates that the message is a request which doesn't expect a response.
bool ValidateMessageIsRequestWithoutResponse(const Message* message);
// Validates that the message is a request expecting a response.
bool ValidateMessageIsRequestExpectingResponse(const Message* message);
// Validates that the message is a response.
bool ValidateMessageIsResponse(const Message* message);

// Validates that the message payload is a valid struct of type ParamsType.
template <typename ParamsType>
bool ValidateMessagePayload(const Message* message) {
  BoundsChecker bounds_checker(message->payload(), message->payload_num_bytes(),
                               message->handles()->size());
  return ParamsType::Validate(message->payload(), &bounds_checker);
}

// The following methods validate control messages defined in
// interface_control_messages.mojom.
bool ValidateControlRequest(const Message* message);
bool ValidateControlResponse(const Message* message);

}  // namespace internal
}  // namespace mojo

#endif  // MOJO_PUBLIC_CPP_BINDINGS_LIB_VALIDATION_UTIL_H_
