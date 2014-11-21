// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_INSPECTOR_CONSOLEMESSAGESTORAGE_H_
#define SKY_ENGINE_CORE_INSPECTOR_CONSOLEMESSAGESTORAGE_H_

#include "sky/engine/core/inspector/ConsoleMessage.h"
#include "sky/engine/platform/heap/Handle.h"
#include "sky/engine/wtf/Deque.h"
#include "sky/engine/wtf/Forward.h"

namespace blink {

class LocalDOMWindow;

class ConsoleMessageStorage final {
    WTF_MAKE_NONCOPYABLE(ConsoleMessageStorage);
    WTF_MAKE_FAST_ALLOCATED;
public:
    static PassOwnPtr<ConsoleMessageStorage> createForFrame(LocalFrame* frame)
    {
        return adoptPtr(new ConsoleMessageStorage(frame));
    }

    void reportMessage(PassRefPtr<ConsoleMessage>);
    void clear();

    Vector<unsigned> argumentCounts() const;

    void frameWindowDiscarded(LocalDOMWindow*);

    size_t size() const;
    ConsoleMessage* at(size_t index) const;

    int expiredCount() const;

private:
    explicit ConsoleMessageStorage(ExecutionContext*);
    explicit ConsoleMessageStorage(LocalFrame*);

    ExecutionContext* executionContext() const;

    int m_expiredCount;
    Deque<RefPtr<ConsoleMessage> > m_messages;
    RawPtr<ExecutionContext> m_context;
    LocalFrame* m_frame;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_INSPECTOR_CONSOLEMESSAGESTORAGE_H_
