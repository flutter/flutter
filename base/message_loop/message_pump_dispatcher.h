// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_MESSAGE_LOOP_MESSAGE_PUMP_DISPATCHER_H_
#define BASE_MESSAGE_LOOP_MESSAGE_PUMP_DISPATCHER_H_

#include <stdint.h>

#include "base/base_export.h"
#include "base/event_types.h"

namespace base {

// Dispatcher is used during a nested invocation of Run to dispatch events when
// |RunLoop(dispatcher).Run()| is used.  If |RunLoop().Run()| is invoked,
// MessageLoop does not dispatch events (or invoke TranslateMessage), rather
// every message is passed to Dispatcher's Dispatch method for dispatch. It is
// up to the Dispatcher whether or not to dispatch the event.
//
// The nested loop is exited by either posting a quit, or setting the
// POST_DISPATCH_QUIT_LOOP flag on the return value from Dispatch.
class BASE_EXPORT MessagePumpDispatcher {
 public:
  enum PostDispatchAction {
    POST_DISPATCH_NONE = 0x0,
    POST_DISPATCH_QUIT_LOOP = 0x1,
    POST_DISPATCH_PERFORM_DEFAULT = 0x2,
  };

  virtual ~MessagePumpDispatcher() {}

  // Dispatches the event. The return value can have more than one
  // PostDispatchAction flags OR'ed together. If POST_DISPATCH_PERFORM_DEFAULT
  // is set in the returned value, then the message-pump performs the default
  // action. If POST_DISPATCH_QUIT_LOOP is set, in the return value, then the
  // nested loop exits immediately.
  virtual uint32_t Dispatch(const NativeEvent& event) = 0;
};

}  // namespace base

#endif  // BASE_MESSAGE_LOOP_MESSAGE_PUMP_DISPATCHER_H_
