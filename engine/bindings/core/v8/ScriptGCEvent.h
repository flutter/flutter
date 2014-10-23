/*
* Copyright (C) 2010 Google Inc. All rights reserved.
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

#ifndef ScriptGCEvent_h
#define ScriptGCEvent_h

#include "wtf/Vector.h"
#include <v8.h>

namespace blink {

struct HeapInfo {
    HeapInfo()
        : usedJSHeapSize(0)
        , totalJSHeapSize(0)
        , jsHeapSizeLimit(0)
    {
    }

    size_t usedJSHeapSize;
    size_t totalJSHeapSize;
    size_t jsHeapSizeLimit;
};

class ScriptGCEventListener;

class GCEventData {
public:
    typedef Vector<ScriptGCEventListener*> GCEventListeners;

    GCEventData()
        : m_startTime(0.0)
        , m_usedHeapSize(0)
    { }

    void clear()
    {
        m_startTime = 0.0;
        m_usedHeapSize = 0;
    }

    GCEventListeners& listeners() { return m_listeners; }

    double startTime() { return m_startTime; }
    void setStartTime(double startTime) { m_startTime = startTime; }
    size_t usedHeapSize() { return m_usedHeapSize; }
    void setUsedHeapSize(size_t usedHeapSize) { m_usedHeapSize = usedHeapSize; }

private:
    double m_startTime;
    size_t m_usedHeapSize;
    GCEventListeners m_listeners;
};


// FIXME(361045): remove ScriptGCEvent once DevTools Timeline migrates to tracing.
class ScriptGCEvent {
public:
    static void addEventListener(ScriptGCEventListener*);
    static void removeEventListener(ScriptGCEventListener*);
    static void getHeapSize(HeapInfo&);

private:
    static void gcEpilogueCallback(v8::GCType type, v8::GCCallbackFlags flags);
    static void gcPrologueCallback(v8::GCType type, v8::GCCallbackFlags flags);
    static size_t getUsedHeapSize();
};


} // namespace blink

#endif // !defined(ScriptGCEvent_h)
