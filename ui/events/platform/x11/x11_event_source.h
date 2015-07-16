// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_EVENTS_PLATFORM_X11_X11_EVENT_SOURCE_H_
#define UI_EVENTS_PLATFORM_X11_X11_EVENT_SOURCE_H_

#include "base/memory/scoped_ptr.h"
#include "ui/events/events_export.h"
#include "ui/events/platform/platform_event_source.h"
#include "ui/gfx/x/x11_types.h"

typedef struct _GPollFD GPollFD;
typedef struct _GSource GSource;
typedef union _XEvent XEvent;
typedef unsigned long XID;

namespace ui {

class HotplugEventHandlerX11;

// A PlatformEventSource implementation for reading events from X11 server and
// dispatching the events to the appropriate dispatcher.
class EVENTS_EXPORT X11EventSource : public PlatformEventSource {
 public:
  explicit X11EventSource(XDisplay* display);
  ~X11EventSource() override;

  static X11EventSource* GetInstance();

  // Called by the glib source dispatch function. Processes all (if any)
  // available X events.
  void DispatchXEvents();

  // Blocks on the X11 event queue until we receive notification from the
  // xserver that |w| has been mapped; StructureNotifyMask events on |w| are
  // pulled out from the queue and dispatched out of order.
  //
  // For those that know X11, this is really a wrapper around XWindowEvent
  // which still makes sure the preempted event is dispatched instead of
  // dropped on the floor. This method exists because mapping a window is
  // asynchronous (and we receive an XEvent when mapped), while there are also
  // functions which require a mapped window.
  void BlockUntilWindowMapped(XID window);

 protected:
  XDisplay* display() { return display_; }

 private:
  // PlatformEventSource:
  uint32_t DispatchEvent(XEvent* xevent) override;
  void StopCurrentEventStream() override;

  // The connection to the X11 server used to receive the events.
  XDisplay* display_;

  // Keeps track of whether this source should continue to dispatch all the
  // available events.
  bool continue_stream_;

  scoped_ptr<HotplugEventHandlerX11> hotplug_event_handler_;

  DISALLOW_COPY_AND_ASSIGN(X11EventSource);
};

}  // namespace ui

#endif  // UI_EVENTS_PLATFORM_X11_X11_EVENT_SOURCE_H_
