// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NullExecutionContext_h
#define NullExecutionContext_h

#include "sky/engine/core/dom/ExecutionContext.h"
#include "sky/engine/core/events/EventQueue.h"
#include "sky/engine/platform/heap/Handle.h"
#include "sky/engine/platform/weborigin/KURL.h"
#include "sky/engine/wtf/RefCounted.h"

namespace blink {

class NullExecutionContext final : public RefCounted<NullExecutionContext>, public ExecutionContext {
public:
    NullExecutionContext();

    virtual EventQueue* eventQueue() const override { return m_queue.get(); }

    virtual void reportBlockedScriptExecutionToInspector(const String& directiveText) override { }

#if !ENABLE(OILPAN)
    using RefCounted<NullExecutionContext>::ref;
    using RefCounted<NullExecutionContext>::deref;

    virtual void refExecutionContext() override { ref(); }
    virtual void derefExecutionContext() override { deref(); }
#endif

protected:
    virtual const KURL& virtualURL() const override { return m_dummyURL; }
    virtual KURL virtualCompleteURL(const String&) const override { return m_dummyURL; }

private:
    OwnPtr<EventQueue> m_queue;

    KURL m_dummyURL;
};

} // namespace blink

#endif // NullExecutionContext_h
