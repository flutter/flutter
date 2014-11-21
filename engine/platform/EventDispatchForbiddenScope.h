// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_PLATFORM_EVENTDISPATCHFORBIDDENSCOPE_H_
#define SKY_ENGINE_PLATFORM_EVENTDISPATCHFORBIDDENSCOPE_H_

#include "sky/engine/wtf/MainThread.h"
#include "sky/engine/wtf/TemporaryChange.h"

namespace blink {

#if ENABLE(ASSERT)

class EventDispatchForbiddenScope {
public:
    EventDispatchForbiddenScope()
    {
        if (!isMainThread())
            return;
        ++s_count;
    }

    ~EventDispatchForbiddenScope()
    {
        if (!isMainThread())
            return;
        ASSERT(s_count);
        --s_count;
    }

    static bool isEventDispatchForbidden()
    {
        if (!isMainThread())
            return false;
        return s_count;
    }

    class AllowUserAgentEvents {
    public:
        AllowUserAgentEvents()
            : m_change(s_count, 0)
        {
        }

        ~AllowUserAgentEvents()
        {
            ASSERT(!s_count);
        }

        TemporaryChange<unsigned> m_change;
    };

private:
    static unsigned s_count;
};

#else

class EventDispatchForbiddenScope {
public:
    EventDispatchForbiddenScope() { }

    class AllowUserAgentEvents {
    public:
        AllowUserAgentEvents() { }
    };
};

#endif // ENABLE(ASSERT)

} // namespace blink

#endif  // SKY_ENGINE_PLATFORM_EVENTDISPATCHFORBIDDENSCOPE_H_
