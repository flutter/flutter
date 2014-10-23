/*
 * Copyright (C) 2007 Apple Inc. All rights reserved.
 * Copyright (C) 2013 Google Inc. All rights reserved.
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

#ifndef ConsoleBase_h
#define ConsoleBase_h

#include "bindings/core/v8/ScriptState.h"
#include "bindings/core/v8/ScriptWrappable.h"
#include "core/inspector/ConsoleAPITypes.h"
#include "core/inspector/ScriptCallStack.h"
#include "core/frame/ConsoleTypes.h"
#include "core/frame/DOMWindowProperty.h"
#include "platform/heap/Handle.h"
#include "wtf/Forward.h"
#include "wtf/PassRefPtr.h"
#include "wtf/RefCounted.h"

namespace blink {

class ConsoleMessage;
class ScriptArguments;

class ConsoleBase : public RefCountedWillBeGarbageCollectedFinalized<ConsoleBase>, public ScriptWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    void debug(ScriptState*, PassRefPtrWillBeRawPtr<ScriptArguments>);
    void error(ScriptState*, PassRefPtrWillBeRawPtr<ScriptArguments>);
    void info(ScriptState*, PassRefPtrWillBeRawPtr<ScriptArguments>);
    void log(ScriptState*, PassRefPtrWillBeRawPtr<ScriptArguments>);
    void clear(ScriptState*, PassRefPtrWillBeRawPtr<ScriptArguments>);
    void warn(ScriptState*, PassRefPtrWillBeRawPtr<ScriptArguments>);
    void dir(ScriptState*, PassRefPtrWillBeRawPtr<ScriptArguments>);
    void dirxml(ScriptState*, PassRefPtrWillBeRawPtr<ScriptArguments>);
    void table(ScriptState*, PassRefPtrWillBeRawPtr<ScriptArguments>);
    void trace(ScriptState*, PassRefPtrWillBeRawPtr<ScriptArguments>);
    void assertCondition(ScriptState*, PassRefPtrWillBeRawPtr<ScriptArguments>, bool condition);
    void count(ScriptState*, PassRefPtrWillBeRawPtr<ScriptArguments>);
    void markTimeline(const String&);
    void profile(const String&);
    void profileEnd(const String&);
    void time(const String&);
    void timeEnd(ScriptState*, const String&);
    void timeStamp(const String&);
    void timeline(ScriptState*, const String&);
    void timelineEnd(ScriptState*, const String&);
    void group(ScriptState*, PassRefPtrWillBeRawPtr<ScriptArguments>);
    void groupCollapsed(ScriptState*, PassRefPtrWillBeRawPtr<ScriptArguments>);
    void groupEnd();

    virtual void trace(Visitor*) { }

    virtual ~ConsoleBase();

protected:
    virtual ExecutionContext* context() = 0;
    virtual void reportMessageToConsole(PassRefPtrWillBeRawPtr<ConsoleMessage>) = 0;

private:
    void internalAddMessage(MessageType, MessageLevel, ScriptState*, PassRefPtrWillBeRawPtr<ScriptArguments>, bool acceptNoArguments = false, bool printTrace = false);

    HashCountedSet<String> m_counts;
    HashMap<String, double> m_times;
};

} // namespace blink

#endif // ConsoleBase_h
