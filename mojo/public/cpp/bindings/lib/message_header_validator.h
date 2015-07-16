// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_PUBLIC_CPP_BINDINGS_LIB_MESSAGE_HEADER_VALIDATOR_H_
#define MOJO_PUBLIC_CPP_BINDINGS_LIB_MESSAGE_HEADER_VALIDATOR_H_

#include "mojo/public/cpp/bindings/message.h"
#include "mojo/public/cpp/bindings/message_filter.h"

namespace mojo {
namespace internal {

class MessageHeaderValidator : public MessageFilter {
 public:
  explicit MessageHeaderValidator(MessageReceiver* sink = nullptr);

  bool Accept(Message* message) override;
};

}  // namespace internal
}  // namespace mojo

#endif  // MOJO_PUBLIC_CPP_BINDINGS_LIB_MESSAGE_HEADER_VALIDATOR_H_
