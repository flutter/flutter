// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NullExecutionContext_h
#define NullExecutionContext_h

#include "core/dom/ExecutionContext.h"
#include "core/events/EventQueue.h"
#include "platform/heap/Handle.h"
#include "platform/weborigin/KURL.h"
#include "wtf/RefCounted.h"

namespace blink {

class NullExecutionContext final : public RefCounted<NullExecutionContext>, public ExecutionContext {
    WILL_BE_USING_GARBAGE_COLLECTED_MIXIN(NullExecutionContext);
public:
    NullExecutionContext();

    virtual EventQueue* eventQueue() const override { return m_queue.get(); }

    void trace(Visitor* visitor)
    {
        visitor->trace(m_queue);
        ExecutionContext::trace(visitor);
    }

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
