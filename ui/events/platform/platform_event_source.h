// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_EVENTS_PLATFORM_PLATFORM_EVENT_SOURCE_H_
#define UI_EVENTS_PLATFORM_PLATFORM_EVENT_SOURCE_H_

#include <map>
#include <vector>

#include "base/auto_reset.h"
#include "base/macros.h"
#include "base/memory/scoped_ptr.h"
#include "base/observer_list.h"
#include "ui/events/events_export.h"
#include "ui/events/platform/platform_event_types.h"

namespace ui {

class Event;
class PlatformEventDispatcher;
class PlatformEventObserver;
class ScopedEventDispatcher;

// PlatformEventSource receives events from a source and dispatches the events
// to the appropriate dispatchers.
class EVENTS_EXPORT PlatformEventSource {
 public:
  virtual ~PlatformEventSource();

  static PlatformEventSource* GetInstance();

  // Adds a dispatcher to the dispatcher list. If a dispatcher is added during
  // dispatching an event, then the newly added dispatcher also receives that
  // event.
  void AddPlatformEventDispatcher(PlatformEventDispatcher* dispatcher);

  // Removes a dispatcher from the dispatcher list. Dispatchers can safely be
  // removed from the dispatcher list during an event is being dispatched,
  // without affecting the dispatch of the event to other existing dispatchers.
  void RemovePlatformEventDispatcher(PlatformEventDispatcher* dispatcher);

  // Installs a PlatformEventDispatcher that receives all the events. The
  // dispatcher can process the event, or request that the default dispatchers
  // be invoked by setting |POST_DISPATCH_PERFORM_DEFAULT| flag from the
  // |DispatchEvent()| override.
  // The returned |ScopedEventDispatcher| object is a handler for the overridden
  // dispatcher. When this handler is destroyed, it removes the overridden
  // dispatcher, and restores the previous override-dispatcher (or NULL if there
  // wasn't any).
  scoped_ptr<ScopedEventDispatcher> OverrideDispatcher(
      PlatformEventDispatcher* dispatcher);

  void AddPlatformEventObserver(PlatformEventObserver* observer);
  void RemovePlatformEventObserver(PlatformEventObserver* observer);

  static scoped_ptr<PlatformEventSource> CreateDefault();

 protected:
  PlatformEventSource();

  // Dispatches |platform_event| to the dispatchers. If there is an override
  // dispatcher installed using |OverrideDispatcher()|, then that dispatcher
  // receives the event first. |POST_DISPATCH_QUIT_LOOP| flag is set in the
  // returned value if the event-source should stop dispatching events at the
  // current message-loop iteration.
  virtual uint32_t DispatchEvent(PlatformEvent platform_event);

 private:
  friend class ScopedEventDispatcher;
  static PlatformEventSource* instance_;

  // Called to indicate that the source should stop dispatching the current
  // stream of events and wait until the next iteration of the message-loop to
  // dispatch the rest of the events.
  virtual void StopCurrentEventStream();

  // This is invoked when the list of dispatchers changes (i.e. a new dispatcher
  // is added, or a dispatcher is removed).
  virtual void OnDispatcherListChanged();

  void OnOverriddenDispatcherRestored();

  // Use a base::ObserverList<> instead of an std::vector<> to store the list of
  // dispatchers, so that adding/removing dispatchers during an event dispatch
  // is well-defined.
  typedef base::ObserverList<PlatformEventDispatcher>
      PlatformEventDispatcherList;
  PlatformEventDispatcherList dispatchers_;
  PlatformEventDispatcher* overridden_dispatcher_;

  // Used to keep track of whether the current override-dispatcher has been
  // reset and a previous override-dispatcher has been restored.
  bool overridden_dispatcher_restored_;

  base::ObserverList<PlatformEventObserver> observers_;

  DISALLOW_COPY_AND_ASSIGN(PlatformEventSource);
};

}  // namespace ui

#endif  // UI_EVENTS_PLATFORM_PLATFORM_EVENT_SOURCE_H_
