// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/message_in_transit_test_utils.h"

#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {
namespace system {
namespace test {

scoped_ptr<MessageInTransit> MakeTestMessage(unsigned id) {
  return make_scoped_ptr(
      new MessageInTransit(MessageInTransit::Type::ENDPOINT_CLIENT,
                           MessageInTransit::Subtype::ENDPOINT_CLIENT_DATA,
                           static_cast<uint32_t>(sizeof(id)), &id));
}

void VerifyTestMessage(const MessageInTransit* message, unsigned id) {
  ASSERT_TRUE(message);
  EXPECT_EQ(MessageInTransit::Type::ENDPOINT_CLIENT, message->type());
  EXPECT_EQ(MessageInTransit::Subtype::ENDPOINT_CLIENT_DATA,
            message->subtype());
  EXPECT_EQ(sizeof(id), message->num_bytes());
  EXPECT_EQ(id, *static_cast<const unsigned*>(message->bytes()));
}

bool IsTestMessage(MessageInTransit* message, unsigned* id) {
  if (message->type() != MessageInTransit::Type::ENDPOINT_CLIENT ||
      message->subtype() != MessageInTransit::Subtype::ENDPOINT_CLIENT_DATA ||
      message->num_bytes() != sizeof(*id))
    return false;

  *id = *static_cast<const unsigned*>(message->bytes());
  return true;
}

}  // namespace test
}  // namespace system
}  // namespace mojo
