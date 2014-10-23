/*
 * Copyright (C) 2011 Google Inc. All rights reserved.
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

#ifndef EventTracer_h
#define EventTracer_h

#include "platform/PlatformExport.h"
#include "wtf/RefCounted.h"
#include "wtf/RefPtr.h"
#include "wtf/text/WTFString.h"

#include <stdint.h>

// This will mark the trace event as disabled by default. The user will need
// to explicitly enable the event.
#define TRACE_DISABLED_BY_DEFAULT(name) "disabled-by-default-" name

namespace blink {

namespace TraceEvent {
typedef uint64_t TraceEventHandle;

class PLATFORM_EXPORT ConvertableToTraceFormat : public RefCounted<ConvertableToTraceFormat> {
public:
    virtual String asTraceFormat() const = 0;
    virtual ~ConvertableToTraceFormat() { }
};

}

// FIXME: Make these global variables thread-safe. Make a value update atomic.
PLATFORM_EXPORT extern long* traceSamplingState[3];

class PLATFORM_EXPORT EventTracer {
public:
    static void initialize();
    static const unsigned char* getTraceCategoryEnabledFlag(const char*);
    static TraceEvent::TraceEventHandle addTraceEvent(char phase,
        const unsigned char* categoryEnabledFlag,
        const char* name,
        unsigned long long id,
        int numArgs,
        const char* argNames[],
        const unsigned char argTypes[],
        const unsigned long long argValues[],
        TraceEvent::ConvertableToTraceFormat*[],
        unsigned char flags);
    static TraceEvent::TraceEventHandle addTraceEvent(char phase,
        const unsigned char* categoryEnabledFlag,
        const char* name,
        unsigned long long id,
        int numArgs,
        const char* argNames[],
        const unsigned char argTypes[],
        const unsigned long long argValues[],
        unsigned char flags);
    static void updateTraceEventDuration(const unsigned char* categoryEnabledFlag, const char* name, TraceEvent::TraceEventHandle);
};

} // namespace blink

#endif // EventTracer_h
