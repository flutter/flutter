// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef ConsoleMessage_h
#define ConsoleMessage_h

#include "bindings/core/v8/ScriptState.h"
#include "core/frame/ConsoleTypes.h"
#include "core/inspector/ConsoleAPITypes.h"
#include "core/inspector/ScriptCallStack.h"
#include "platform/heap/Handle.h"
#include "wtf/Forward.h"
#include "wtf/PassRefPtr.h"
#include "wtf/RefCounted.h"
#include "wtf/text/WTFString.h"

namespace blink {

class ScriptArguments;
class ScriptCallStack;
class ScriptState;

class ConsoleMessage final: public RefCountedWillBeGarbageCollectedFinalized<ConsoleMessage> {
public:
    static PassRefPtrWillBeRawPtr<ConsoleMessage> create(MessageSource source, MessageLevel level, const String& message, const String& url = String(), unsigned lineNumber = 0, unsigned columnNumber = 0)
    {
        return adoptRefWillBeNoop(new ConsoleMessage(source, level, message, url, lineNumber, columnNumber));
    }
    ~ConsoleMessage();

    MessageType type() const;
    void setType(MessageType);
    int scriptId() const;
    void setScriptId(int);
    const String& url() const;
    void setURL(const String&);
    unsigned lineNumber() const;
    void setLineNumber(unsigned);
    PassRefPtrWillBeRawPtr<ScriptCallStack> callStack() const;
    void setCallStack(PassRefPtrWillBeRawPtr<ScriptCallStack>);
    ScriptState* scriptState() const;
    void setScriptState(ScriptState*);
    PassRefPtrWillBeRawPtr<ScriptArguments> scriptArguments() const;
    void setScriptArguments(PassRefPtrWillBeRawPtr<ScriptArguments>);
    unsigned long requestIdentifier() const;
    void setRequestIdentifier(unsigned long);
    double timestamp() const;
    void setTimestamp(double);

    MessageSource source() const;
    MessageLevel level() const;
    const String& message() const;
    unsigned columnNumber() const;

    void frameWindowDiscarded(LocalDOMWindow*);
    unsigned argumentCount();

    void collectCallStack();

    void trace(Visitor*);

private:
    ConsoleMessage(MessageSource, MessageLevel, const String& message, const String& url = String(), unsigned lineNumber = 0, unsigned columnNumber = 0);

    MessageSource m_source;
    MessageLevel m_level;
    MessageType m_type;
    String m_message;
    int m_scriptId;
    String m_url;
    unsigned m_lineNumber;
    unsigned m_columnNumber;
    RefPtrWillBeMember<ScriptCallStack> m_callStack;
    OwnPtr<ScriptStateProtectingContext> m_scriptState;
    RefPtrWillBeMember<ScriptArguments> m_scriptArguments;
    unsigned long m_requestIdentifier;
    double m_timestamp;
};

} // namespace blink

#endif // ConsoleMessage_h
