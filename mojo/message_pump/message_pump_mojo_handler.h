// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_MESSAGE_PUMP_MESSAGE_PUMP_MOJO_HANDLER_H_
#define MOJO_MESSAGE_PUMP_MESSAGE_PUMP_MOJO_HANDLER_H_

#include "mojo/public/cpp/system/core.h"

namespace mojo {
namespace common {

// Used by MessagePumpMojo to notify when a handle is either ready or has become
// invalid. In case of error, the handler will be removed.
class MessagePumpMojoHandler {
 public:
  virtual void OnHandleReady(const Handle& handle) = 0;

  virtual void OnHandleError(const Handle& handle, MojoResult result) = 0;

 protected:
  virtual ~MessagePumpMojoHandler() {}
};

}  // namespace common
}  // namespace mojo

#endif  // MOJO_MESSAGE_PUMP_MESSAGE_PUMP_MOJO_HANDLER_H_
