// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/testing/NullExecutionContext.h"

#include "core/events/Event.h"

namespace blink {

namespace {

class NullEventQueue FINAL : public EventQueue {
public:
    NullEventQueue() { }
    virtual ~NullEventQueue() { }
    virtual bool enqueueEvent(PassRefPtrWillBeRawPtr<Event>) OVERRIDE { return true; }
    virtual bool cancelEvent(Event*) OVERRIDE { return true; }
    virtual void close() OVERRIDE { }
};

} // namespace

NullExecutionContext::NullExecutionContext()
    : m_queue(adoptPtrWillBeNoop(new NullEventQueue()))
{
}

} // namespace blink
