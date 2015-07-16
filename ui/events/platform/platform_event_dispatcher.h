// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_EVENTS_PLATFORM_PLATFORM_EVENT_DISPATCHER_H_
#define UI_EVENTS_PLATFORM_PLATFORM_EVENT_DISPATCHER_H_

#include "base/basictypes.h"
#include "ui/events/events_export.h"
#include "ui/events/platform/platform_event_types.h"

namespace ui {

// See documentation for |PlatformEventDispatcher::DispatchEvent()| for
// explanation of the meaning of the flags.
enum PostDispatchAction {
  POST_DISPATCH_NONE = 0x0,
  POST_DISPATCH_PERFORM_DEFAULT = 0x1,
  POST_DISPATCH_STOP_PROPAGATION = 0x2,
};

// PlatformEventDispatcher receives events from a PlatformEventSource and
// dispatches them.
class EVENTS_EXPORT PlatformEventDispatcher {
 public:
  // Returns whether this dispatcher wants to dispatch |event|.
  virtual bool CanDispatchEvent(const PlatformEvent& event) = 0;

  // Dispatches |event|. If this is not the default dispatcher, then the
  // dispatcher can request that the default dispatcher gets a chance to
  // dispatch the event by setting POST_DISPATCH_PERFORM_DEFAULT to the return
  // value. If the dispatcher has processed the event, and no other dispatcher
  // should be allowed to dispatch the event, then the dispatcher should set
  // POST_DISPATCH_STOP_PROPAGATION flag on the return value.
  virtual uint32_t DispatchEvent(const PlatformEvent& event) = 0;

 protected:
  virtual ~PlatformEventDispatcher() {}
};

}  // namespace ui

#endif  // UI_EVENTS_PLATFORM_PLATFORM_EVENT_DISPATCHER_H_
