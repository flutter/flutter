// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_MESSAGE_IN_TRANSIT_TEST_UTILS_H_
#define MOJO_EDK_SYSTEM_MESSAGE_IN_TRANSIT_TEST_UTILS_H_

#include "base/memory/scoped_ptr.h"
#include "mojo/edk/system/message_in_transit.h"

namespace mojo {
namespace system {
namespace test {

// Makes a test message. It will be of type
// |MessageInTransit::Type::ENDPOINT_CLIENT| and subtype
// |MessageInTransit::Subtype::ENDPOINT_CLIENT_DATA|, and contain data
// associated with |id| (so that test messages with different |id|s are
// distinguishable).
scoped_ptr<MessageInTransit> MakeTestMessage(unsigned id);

// Verifies a test message: ASSERTs that |message| is non-null, and EXPECTs that
// it looks like a message created using |MakeTestMessage(id)| (see above).
void VerifyTestMessage(const MessageInTransit* message, unsigned id);

// Checks if |message| looks like a test message created using
// |MakeTestMessage()|, in which case it returns true and sets |*id|. (Otherwise
// it returns false and leaves |*id| alone.)
bool IsTestMessage(MessageInTransit* message, unsigned* id);

}  // namespace test
}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_MESSAGE_IN_TRANSIT_TEST_UTILS_H_
