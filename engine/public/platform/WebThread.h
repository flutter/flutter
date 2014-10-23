/*
 * Copyright (C) 2011 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
#ifndef WebThread_h
#define WebThread_h

#include "WebCommon.h"
#include <stdint.h>

namespace blink {

// Always an integer value.
typedef uintptr_t PlatformThreadId;

// Provides an interface to an embedder-defined thread implementation.
//
// Deleting the thread blocks until all pending, non-delayed tasks have been
// run.
class BLINK_PLATFORM_EXPORT WebThread {
public:
    class Task {
    public:
        virtual ~Task() { }
        virtual void run() = 0;
    };

    class BLINK_PLATFORM_EXPORT TaskObserver {
    public:
        virtual ~TaskObserver() { }
        virtual void willProcessTask() = 0;
        virtual void didProcessTask() = 0;
    };

    // postTask() and postDelayedTask() take ownership of the passed Task
    // object. It is safe to invoke postTask() and postDelayedTask() from any
    // thread.
    virtual void postTask(Task*) = 0;
    virtual void postDelayedTask(Task*, long long delayMs) = 0;

    virtual bool isCurrentThread() const = 0;
    virtual PlatformThreadId threadId() const { return 0; }

    virtual void addTaskObserver(TaskObserver*) { }
    virtual void removeTaskObserver(TaskObserver*) { }

    // enterRunLoop() processes tasks posted to this WebThread. This call does not return until some task calls exitRunLoop().
    // WebThread does not support nesting, meaning that once the run loop is entered for a given WebThread it is not valid to
    // call enterRunLoop() again.
    virtual void enterRunLoop() = 0;

    // exitRunLoop() runs tasks until there are no tasks available to run, then returns control to the caller of enterRunLoop().
    // Must be called when the WebThread is running.
    virtual void exitRunLoop() = 0;

    virtual ~WebThread() { }
};

} // namespace blink

#endif
