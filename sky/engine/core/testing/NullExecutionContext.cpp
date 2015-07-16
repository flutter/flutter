// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "core/testing/NullExecutionContext.h"

#include "sky/engine/core/events/Event.h"

namespace blink {

namespace {

class NullEventQueue final : public EventQueue {
public:
    NullEventQueue() { }
    virtual ~NullEventQueue() { }
    virtual bool enqueueEvent(PassRefPtr<Event>) override { return true; }
    virtual bool cancelEvent(Event*) override { return true; }
    virtual void close() override { }
};

} // namespace

NullExecutionContext::NullExecutionContext()
    : m_queue(adoptPtr(new NullEventQueue()))
{
}

} // namespace blink
