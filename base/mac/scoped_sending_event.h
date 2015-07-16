// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_MAC_SCOPED_SENDING_EVENT_H_
#define BASE_MAC_SCOPED_SENDING_EVENT_H_

#include "base/base_export.h"
#include "base/basictypes.h"
#include "base/message_loop/message_pump_mac.h"

// Nested event loops can pump IPC messages, including
// script-initiated tab closes, which could release objects that the
// nested event loop might message.  CrAppProtocol defines how to ask
// the embedding NSApplication subclass if an event is currently being
// handled, in which case such closes are deferred to the top-level
// event loop.
//
// ScopedSendingEvent allows script-initiated event loops to work like
// a nested event loop, as such events do not arrive via -sendEvent:.
// CrAppControlProtocol lets ScopedSendingEvent tell the embedding
// NSApplication what to return from -handlingSendEvent.

@protocol CrAppControlProtocol<CrAppProtocol>
- (void)setHandlingSendEvent:(BOOL)handlingSendEvent;
@end

namespace base {
namespace mac {

class BASE_EXPORT ScopedSendingEvent {
 public:
  ScopedSendingEvent();
  ~ScopedSendingEvent();

 private:
  // The NSApp in control at the time the constructor was run, to be
  // sure the |handling_| setting is restored appropriately.
  NSObject<CrAppControlProtocol>* app_;
  BOOL handling_;  // Value of -[app_ handlingSendEvent] at construction.

  DISALLOW_COPY_AND_ASSIGN(ScopedSendingEvent);
};

}  // namespace mac
}  // namespace base

#endif  // BASE_MAC_SCOPED_SENDING_EVENT_H_
