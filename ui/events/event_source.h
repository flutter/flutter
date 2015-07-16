// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_EVENTS_EVENT_SOURCE_H_
#define UI_EVENTS_EVENT_SOURCE_H_

#include <vector>

#include "ui/events/event_dispatcher.h"
#include "ui/events/events_export.h"

namespace ui {

class Event;
class EventProcessor;
class EventRewriter;

// EventSource receives events from the native platform (e.g. X11, win32 etc.)
// and sends the events to an EventProcessor.
class EVENTS_EXPORT EventSource {
 public:
  EventSource();
  virtual ~EventSource();

  virtual EventProcessor* GetEventProcessor() = 0;

  // Adds a rewriter to modify events before they are sent to the
  // EventProcessor. The rewriter must be explicitly removed from the
  // EventSource before the rewriter is destroyed. The EventSource
  // does not take ownership of the rewriter.
  void AddEventRewriter(EventRewriter* rewriter);
  void RemoveEventRewriter(EventRewriter* rewriter);

 protected:
  EventDispatchDetails SendEventToProcessor(Event* event);

 private:
  friend class EventSourceTestApi;

  typedef std::vector<EventRewriter*> EventRewriterList;
  EventDispatchDetails DeliverEventToProcessor(Event* event);
  EventRewriterList rewriter_list_;
  DISALLOW_COPY_AND_ASSIGN(EventSource);
};

}  // namespace ui

#endif // UI_EVENTS_EVENT_SOURCE_H_
