// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_EVENTS_PLATFORM_SCOPED_EVENT_DISPATCHER_H_
#define UI_EVENTS_PLATFORM_SCOPED_EVENT_DISPATCHER_H_

#include "base/auto_reset.h"
#include "base/basictypes.h"
#include "ui/events/events_export.h"

namespace ui {

class PlatformEventDispatcher;

// A temporary PlatformEventDispatcher can be installed on a
// PlatformEventSource that overrides all installed event dispatchers, and
// always gets a chance to dispatch the event first. The PlatformEventSource
// returns a ScopedEventDispatcher object in such cases. This
// ScopedEventDispatcher object can be used to dispatch the event to any
// previous overridden dispatcher. When this object is destroyed, it removes the
// override-dispatcher, and restores the previous override-dispatcher.
class EVENTS_EXPORT ScopedEventDispatcher {
 public:
  ScopedEventDispatcher(PlatformEventDispatcher** scoped_dispatcher,
                        PlatformEventDispatcher* new_dispatcher);
  ~ScopedEventDispatcher();

  operator PlatformEventDispatcher*() const { return original_; }

 private:
  PlatformEventDispatcher* original_;
  base::AutoReset<PlatformEventDispatcher*> restore_;

  DISALLOW_COPY_AND_ASSIGN(ScopedEventDispatcher);
};

}  // namespace ui

#endif  // UI_EVENTS_PLATFORM_SCOPED_EVENT_DISPATCHER_H_
