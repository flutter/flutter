// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/events/platform/scoped_event_dispatcher.h"

#include "ui/events/platform/platform_event_source.h"

namespace ui {

ScopedEventDispatcher::ScopedEventDispatcher(
    PlatformEventDispatcher** scoped_dispatcher,
    PlatformEventDispatcher* new_dispatcher)
    : original_(*scoped_dispatcher),
      restore_(scoped_dispatcher, new_dispatcher) {}

ScopedEventDispatcher::~ScopedEventDispatcher() {
  PlatformEventSource::GetInstance()->OnOverriddenDispatcherRestored();
}

}  // namespace ui
