// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_PUBLIC_CPP_BINDINGS_LIB_CONTROL_MESSAGE_PROXY_H_
#define MOJO_PUBLIC_CPP_BINDINGS_LIB_CONTROL_MESSAGE_PROXY_H_

#include <stdint.h>

#include "mojo/public/cpp/bindings/callback.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {

class MessageReceiverWithResponder;

namespace internal {

// Proxy for request messages defined in interface_control_messages.mojom.
class ControlMessageProxy {
 public:
  // Doesn't take ownership of |receiver|. It must outlive this object.
  explicit ControlMessageProxy(MessageReceiverWithResponder* receiver);

  void QueryVersion(const Callback<void(uint32_t)>& callback);
  void RequireVersion(uint32_t version);

 protected:
  // Not owned.
  MessageReceiverWithResponder* receiver_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(ControlMessageProxy);
};

}  // namespace internal
}  // namespace mojo

#endif  // MOJO_PUBLIC_CPP_BINDINGS_LIB_CONTROL_MESSAGE_PROXY_H_
