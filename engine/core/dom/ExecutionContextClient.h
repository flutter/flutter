/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
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

#ifndef ExecutionContextClient_h
#define ExecutionContextClient_h

#include "sky/engine/core/frame/ConsoleTypes.h"
#include "sky/engine/core/inspector/ConsoleMessage.h"
#include "sky/engine/platform/LifecycleNotifier.h"
#include "sky/engine/platform/heap/Handle.h"
#include "sky/engine/platform/weborigin/KURL.h"
#include "sky/engine/wtf/Forward.h"

namespace blink {

class EventTarget;
class KURL;
class LocalDOMWindow;
class ScriptCallStack;
class ScriptState;

class ExecutionContextClient {
public:
    virtual bool isDocument() const { return false; }
    virtual LocalDOMWindow* executingWindow() { return 0; }
    virtual void addMessage(PassRefPtr<ConsoleMessage>) = 0;
    virtual EventTarget* errorEventTarget() = 0;
    virtual void logExceptionToConsole(const String& errorMessage, int scriptId, const String& sourceURL, int lineNumber, int columnNumber, PassRefPtr<ScriptCallStack>) = 0;
    virtual double timerAlignmentInterval() const = 0;

    virtual void tasksWereSuspended() { }
    virtual void tasksWereResumed() { }

    void addConsoleMessage(PassRefPtr<ConsoleMessage> consoleMessage) { addMessage(consoleMessage); }

protected:
    virtual ~ExecutionContextClient() { }

};


} // namespace blink

#endif
