/*
 * Copyright (C) 2007, 2008, 2013 Apple Inc. All rights reserved.
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
 * 3.  Neither the name of Apple Computer, Inc. ("Apple") nor the names of
 *     its contributors may be used to endorse or promote products derived
 *     from this software without specific prior written permission.
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

#ifndef TaskSynchronizer_h
#define TaskSynchronizer_h

#include "platform/PlatformExport.h"
#include "wtf/Noncopyable.h"
#include "wtf/Threading.h"
#include "wtf/ThreadingPrimitives.h"

namespace blink {

// TaskSynchronizer can be used to wait for task completion.
class PLATFORM_EXPORT TaskSynchronizer {
    WTF_MAKE_NONCOPYABLE(TaskSynchronizer);
public:
    TaskSynchronizer();

    // Called from a thread that waits for the task completion.
    void waitForTaskCompletion();

    // Called from a thread that executes the task.
    void taskCompleted();

#if ENABLE(ASSERT)
    bool hasCheckedForTermination() const { return m_hasCheckedForTermination; }
    void setHasCheckedForTermination() { m_hasCheckedForTermination = true; }
#endif

private:
    void waitForTaskCompletionInternal();

    bool m_taskCompleted;
    Mutex m_synchronousMutex;
    ThreadCondition m_synchronousCondition;
#if ENABLE(ASSERT)
    bool m_hasCheckedForTermination;
#endif
};

} // namespace blink

#endif // TaskSynchronizer_h
