// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/events/test/platform_event_waiter.h"

#include "base/message_loop/message_loop.h"
#include "ui/events/platform/platform_event_source.h"

namespace ui {

PlatformEventWaiter::PlatformEventWaiter(
    const base::Closure& success_callback,
    const PlatformEventMatcher& event_matcher)
    : success_callback_(success_callback),
      event_matcher_(event_matcher) {
  PlatformEventSource::GetInstance()->AddPlatformEventObserver(this);
}

PlatformEventWaiter::~PlatformEventWaiter() {
  PlatformEventSource::GetInstance()->RemovePlatformEventObserver(this);
}

void PlatformEventWaiter::WillProcessEvent(const PlatformEvent& event) {
  if (event_matcher_.Run(event)) {
    base::MessageLoop::current()->PostTask(FROM_HERE, success_callback_);
    delete this;
  }
}

void PlatformEventWaiter::DidProcessEvent(const PlatformEvent& event) {
}

// static
PlatformEventWaiter* PlatformEventWaiter::Create(
    const base::Closure& success_callback,
    const PlatformEventMatcher& event_matcher) {
  return new PlatformEventWaiter(success_callback, event_matcher);
}

}  // namespace ui
