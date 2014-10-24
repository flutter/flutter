// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef ConsoleMessageStorage_h
#define ConsoleMessageStorage_h

#include "core/inspector/ConsoleMessage.h"
#include "platform/heap/Handle.h"
#include "wtf/Forward.h"

namespace blink {

class LocalDOMWindow;

class ConsoleMessageStorage final : public NoBaseWillBeGarbageCollected<ConsoleMessageStorage> {
    WTF_MAKE_NONCOPYABLE(ConsoleMessageStorage);
    WTF_MAKE_FAST_ALLOCATED_WILL_BE_REMOVED;
public:
    static PassOwnPtrWillBeRawPtr<ConsoleMessageStorage> createForFrame(LocalFrame* frame)
    {
        return adoptPtrWillBeNoop(new ConsoleMessageStorage(frame));
    }

    void reportMessage(PassRefPtrWillBeRawPtr<ConsoleMessage>);
    void clear();

    Vector<unsigned> argumentCounts() const;

    void frameWindowDiscarded(LocalDOMWindow*);

    size_t size() const;
    ConsoleMessage* at(size_t index) const;

    int expiredCount() const;

    void trace(Visitor*);

private:
    explicit ConsoleMessageStorage(ExecutionContext*);
    explicit ConsoleMessageStorage(LocalFrame*);

    ExecutionContext* executionContext() const;

    int m_expiredCount;
    WillBeHeapDeque<RefPtrWillBeMember<ConsoleMessage> > m_messages;
    RawPtrWillBeMember<ExecutionContext> m_context;
    LocalFrame* m_frame;
};

} // namespace blink

#endif // ConsoleMessageStorage_h
