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

#ifndef DartEventListener_h
#define DartEventListener_h

#include "core/events/EventListener.h"

#include <dart_api.h>

namespace blink {

class Event;

// Unfortunately we cannot add it to EventListener::Type enum, so keep
// it here.
enum {
    DartEventListenerType = -1
};

class DartEventListener : public EventListener {
public:
    virtual ~DartEventListener();

    // Implementation of EventListener interface.

    virtual bool operator==(const EventListener& other) { return this == &other; }

    virtual void handleEvent(ExecutionContext*, Event*);

    virtual bool isLazy() const { return false; }

    Dart_Isolate isolate() { return m_isolate; }
    Dart_WeakPersistentHandle listenerObject() { return m_listener; }

    static EventListener* toNative(Dart_Handle handle, Dart_Handle& exception);
    static EventListener* toNative(Dart_NativeArguments args, int idx, Dart_Handle& exception)
    {
        Dart_Handle object = Dart_GetNativeArgument(args, idx);
        return toNative(object, exception);
    }

    static EventListener* create(Dart_NativeArguments args, int idx, Dart_Handle& exception)
    {
        return toNative(args, idx, exception);
    }

    static EventListener* createWithNullCheck(Dart_NativeArguments args, int idx, Dart_Handle& exception)
    {
        Dart_Handle object = Dart_GetNativeArgument(args, idx);
        return Dart_IsNull(object) ? 0 : toNative(object, exception);
    }

private:
    DartEventListener();

    static DartEventListener* createOrFetch(Dart_Handle listener);
    Dart_Handle callListenerFunction(ExecutionContext*, Dart_Handle listener, Dart_Handle dartEvent);

    static void weakCallback(void* isolateCallbackData, Dart_WeakPersistentHandle, void* peer);

    Dart_Isolate m_isolate;
    Dart_WeakPersistentHandle m_listener;
    // FIXME: investigate why m_worldContext is needed in v8, extensions?
};

}

#endif // DartEventListener_h
