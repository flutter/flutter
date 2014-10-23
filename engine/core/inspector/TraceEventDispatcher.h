/*
* Copyright (C) 2013 Google Inc. All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions are
* met:
*
*     * Redistributions of source code must retain the above copyright
* notice, this list of conditions and the following disclaimer.
*     * Redistributions in binary form must reproduce the above
* copyright notice, this list of conditions and the following disclaimer
* in the documentation and/or other materials provided with the
* distribution.
*     * Neither the name of Google Inc. nor the names of its
* contributors may be used to endorse or promote products derived from
* this software without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
* "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
* A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
* OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
* SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
* LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
* DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
* THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
* (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
* OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#ifndef TraceEventDispatcher_h
#define TraceEventDispatcher_h

#include "platform/TraceEvent.h"
#include "platform/heap/Handle.h"
#include "wtf/HashMap.h"
#include "wtf/Threading.h"
#include "wtf/ThreadingPrimitives.h"
#include "wtf/Vector.h"
#include "wtf/text/StringHash.h"
#include "wtf/text/WTFString.h"

namespace blink {

class InspectorClient;

class TraceEventDispatcher {
    WTF_MAKE_NONCOPYABLE(TraceEventDispatcher);
public:
    class TraceEvent {
    public:
        TraceEvent()
            : m_name(0)
            , m_argumentCount(0)
        {
        }

        TraceEvent(double timestamp, char phase, const char* name, unsigned long long id, ThreadIdentifier threadIdentifier,
            int argumentCount, const char* const* argumentNames, const unsigned char* argumentTypes, const unsigned long long* argumentValues)
            : m_timestamp(timestamp)
            , m_phase(phase)
            , m_name(name)
            , m_id(id)
            , m_threadIdentifier(threadIdentifier)
            , m_argumentCount(argumentCount)
        {
            if (m_argumentCount > MaxArguments) {
                ASSERT_NOT_REACHED();
                m_argumentCount = MaxArguments;
            }
            for (int i = 0; i < m_argumentCount; ++i) {
                m_argumentNames[i] = argumentNames[i];
                if (argumentTypes[i] == TRACE_VALUE_TYPE_COPY_STRING) {
                    m_stringArguments[i] = reinterpret_cast<const char*>(argumentValues[i]);
                    m_argumentValues[i].m_string = reinterpret_cast<const char*>(m_stringArguments[i].characters8());
                    m_argumentTypes[i] = TRACE_VALUE_TYPE_STRING;
                } else {
                    m_argumentValues[i].m_int = argumentValues[i];
                    m_argumentTypes[i] = argumentTypes[i];
                }
            }
        }

        double timestamp() const { return m_timestamp; }
        char phase() const { return m_phase; }
        const char* name() const { return m_name; }
        unsigned long long id() const { return m_id; }
        ThreadIdentifier threadIdentifier() const { return m_threadIdentifier; }
        int argumentCount() const { return m_argumentCount; }
        bool isNull() const { return !m_name; }

        bool asBool(const char* name) const
        {
            return parameter(name, TRACE_VALUE_TYPE_BOOL).m_bool;
        }
        long long asInt(const char* name) const
        {
            size_t index = findParameter(name);
            if (index == kNotFound || (m_argumentTypes[index] != TRACE_VALUE_TYPE_INT && m_argumentTypes[index] != TRACE_VALUE_TYPE_UINT)) {
                ASSERT_NOT_REACHED();
                return 0;
            }
            return reinterpret_cast<const blink::TraceEvent::TraceValueUnion*>(m_argumentValues + index)->m_int;
        }
        unsigned long long asUInt(const char* name) const
        {
            return asInt(name);
        }
        double asDouble(const char* name) const
        {
            return parameter(name, TRACE_VALUE_TYPE_DOUBLE).m_double;
        }
        const char* asString(const char* name) const
        {
            return parameter(name, TRACE_VALUE_TYPE_STRING).m_string;
        }

    private:
        enum { MaxArguments = 2 };

        size_t findParameter(const char*) const;
        const blink::TraceEvent::TraceValueUnion& parameter(const char* name, unsigned char expectedType) const;

        double m_timestamp;
        char m_phase;
        const char* m_name;
        unsigned long long m_id;
        ThreadIdentifier m_threadIdentifier;
        int m_argumentCount;
        const char* m_argumentNames[MaxArguments];
        unsigned char m_argumentTypes[MaxArguments];
        blink::TraceEvent::TraceValueUnion m_argumentValues[MaxArguments];
        // These are only used as buffers for TRACE_VALUE_TYPE_COPY_STRING.
        // Consider allocating the entire vector of buffered trace events and their copied arguments out of a special arena
        // to make things more compact.
        String m_stringArguments[MaxArguments];
    };

    class TraceEventListener : public NoBaseWillBeGarbageCollected<TraceEventListener> {
    public:
#if !ENABLE(OILPAN)
        virtual ~TraceEventListener() { }
#endif
        virtual void call(const TraceEventDispatcher::TraceEvent&) = 0;
        virtual void* target() = 0;
        virtual void trace(Visitor*) { }
    };

    static TraceEventDispatcher* instance()
    {
        DEFINE_STATIC_LOCAL(TraceEventDispatcher, instance, ());
        return &instance;
    }

    void addListener(const char* name, char phase, PassOwnPtrWillBeRawPtr<TraceEventListener>, InspectorClient*);

    void removeAllListeners(void*, InspectorClient*);
    void processBackgroundEvents();

private:
    typedef std::pair<String, int> EventSelector;
    typedef WillBeHeapHashMap<EventSelector, OwnPtrWillBeMember<WillBeHeapVector<OwnPtrWillBeMember<TraceEventListener> > > > ListenersMap;

    TraceEventDispatcher()
        : m_listeners(adoptPtrWillBeNoop(new ListenersMap()))
        , m_processEventsTaskInFlight(false)
        , m_lastEventProcessingTime(0)
    {
    }

    static void dispatchEventOnAnyThread(char phase, const unsigned char*, const char* name, unsigned long long id,
        int numArgs, const char* const* argNames, const unsigned char* argTypes, const unsigned long long* argValues,
        unsigned char flags, double timestamp);

    void enqueueEvent(const TraceEvent&);
    void processBackgroundEventsTask();

    Mutex m_mutex;
    OwnPtrWillBePersistent<ListenersMap> m_listeners;
    Vector<TraceEvent> m_backgroundEvents;
    bool m_processEventsTaskInFlight;
    double m_lastEventProcessingTime;
};

} // namespace blink

#endif // TraceEventDispatcher_h
