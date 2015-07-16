// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_PUBLIC_CPP_BINDINGS_LIB_CONTROL_MESSAGE_HANDLER_H_
#define MOJO_PUBLIC_CPP_BINDINGS_LIB_CONTROL_MESSAGE_HANDLER_H_

#include <stdint.h>

#include "mojo/public/cpp/bindings/message.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace internal {

// Handlers for request messages defined in interface_control_messages.mojom.
class ControlMessageHandler : public MessageReceiverWithResponderStatus {
 public:
  static bool IsControlMessage(const Message* message);

  explicit ControlMessageHandler(uint32_t interface_version);
  ~ControlMessageHandler() override;

  // Call the following methods only if IsControlMessage() returned true.
  bool Accept(Message* message) override;
  // Takes ownership of |responder|.
  bool AcceptWithResponder(Message* message,
                           MessageReceiverWithStatus* responder) override;

 private:
  bool Run(Message* message, MessageReceiverWithStatus* responder);
  bool RunOrClosePipe(Message* message);

  uint32_t interface_version_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(ControlMessageHandler);
};

}  // namespace internal
}  // namespace mojo

#endif  // MOJO_PUBLIC_CPP_BINDINGS_LIB_CONTROL_MESSAGE_HANDLER_H_
