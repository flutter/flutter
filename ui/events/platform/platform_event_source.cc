// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/events/platform/platform_event_source.h"

#include <algorithm>

#include "base/message_loop/message_loop.h"
#include "ui/events/platform/platform_event_dispatcher.h"
#include "ui/events/platform/platform_event_observer.h"
#include "ui/events/platform/scoped_event_dispatcher.h"

namespace ui {

// static
PlatformEventSource* PlatformEventSource::instance_ = NULL;

PlatformEventSource::PlatformEventSource()
    : overridden_dispatcher_(NULL),
      overridden_dispatcher_restored_(false) {
  CHECK(!instance_) << "Only one platform event source can be created.";
  instance_ = this;
}

PlatformEventSource::~PlatformEventSource() {
  CHECK_EQ(this, instance_);
  instance_ = NULL;
}

PlatformEventSource* PlatformEventSource::GetInstance() { return instance_; }

void PlatformEventSource::AddPlatformEventDispatcher(
    PlatformEventDispatcher* dispatcher) {
  CHECK(dispatcher);
  dispatchers_.AddObserver(dispatcher);
  OnDispatcherListChanged();
}

void PlatformEventSource::RemovePlatformEventDispatcher(
    PlatformEventDispatcher* dispatcher) {
  dispatchers_.RemoveObserver(dispatcher);
  OnDispatcherListChanged();
}

scoped_ptr<ScopedEventDispatcher> PlatformEventSource::OverrideDispatcher(
    PlatformEventDispatcher* dispatcher) {
  CHECK(dispatcher);
  overridden_dispatcher_restored_ = false;
  return make_scoped_ptr(
      new ScopedEventDispatcher(&overridden_dispatcher_, dispatcher));
}

void PlatformEventSource::StopCurrentEventStream() {
}

void PlatformEventSource::AddPlatformEventObserver(
    PlatformEventObserver* observer) {
  CHECK(observer);
  observers_.AddObserver(observer);
}

void PlatformEventSource::RemovePlatformEventObserver(
    PlatformEventObserver* observer) {
  observers_.RemoveObserver(observer);
}

uint32_t PlatformEventSource::DispatchEvent(PlatformEvent platform_event) {
  uint32_t action = POST_DISPATCH_PERFORM_DEFAULT;

  FOR_EACH_OBSERVER(PlatformEventObserver, observers_,
                    WillProcessEvent(platform_event));
  // Give the overridden dispatcher a chance to dispatch the event first.
  if (overridden_dispatcher_)
    action = overridden_dispatcher_->DispatchEvent(platform_event);

  if ((action & POST_DISPATCH_PERFORM_DEFAULT) &&
      dispatchers_.might_have_observers()) {
    base::ObserverList<PlatformEventDispatcher>::Iterator iter(&dispatchers_);
    while (PlatformEventDispatcher* dispatcher = iter.GetNext()) {
      if (dispatcher->CanDispatchEvent(platform_event))
        action = dispatcher->DispatchEvent(platform_event);
      if (action & POST_DISPATCH_STOP_PROPAGATION)
        break;
    }
  }
  FOR_EACH_OBSERVER(PlatformEventObserver, observers_,
                    DidProcessEvent(platform_event));

  // If an overridden dispatcher has been destroyed, then the platform
  // event-source should halt dispatching the current stream of events, and wait
  // until the next message-loop iteration for dispatching events. This lets any
  // nested message-loop to unwind correctly and any new dispatchers to receive
  // the correct sequence of events.
  if (overridden_dispatcher_restored_)
    StopCurrentEventStream();

  overridden_dispatcher_restored_ = false;

  return action;
}

void PlatformEventSource::OnDispatcherListChanged() {
}

void PlatformEventSource::OnOverriddenDispatcherRestored() {
  CHECK(overridden_dispatcher_);
  overridden_dispatcher_restored_ = true;
}

}  // namespace ui
