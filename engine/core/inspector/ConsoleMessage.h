// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_INSPECTOR_CONSOLEMESSAGE_H_
#define SKY_ENGINE_CORE_INSPECTOR_CONSOLEMESSAGE_H_

#include "sky/engine/bindings/core/v8/ScriptState.h"
#include "sky/engine/core/frame/ConsoleTypes.h"
#include "sky/engine/core/inspector/ConsoleAPITypes.h"
#include "sky/engine/core/inspector/ScriptCallStack.h"
#include "sky/engine/platform/heap/Handle.h"
#include "sky/engine/wtf/Forward.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/RefCounted.h"
#include "sky/engine/wtf/text/WTFString.h"

namespace blink {

class ScriptArguments;
class ScriptCallStack;
class ScriptState;

class ConsoleMessage final: public RefCounted<ConsoleMessage> {
public:
    static PassRefPtr<ConsoleMessage> create(MessageSource source, MessageLevel level, const String& message, const String& url = String(), unsigned lineNumber = 0, unsigned columnNumber = 0)
    {
        return adoptRef(new ConsoleMessage(source, level, message, url, lineNumber, columnNumber));
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
    PassRefPtr<ScriptCallStack> callStack() const;
    void setCallStack(PassRefPtr<ScriptCallStack>);
    ScriptState* scriptState() const;
    void setScriptState(ScriptState*);
    PassRefPtr<ScriptArguments> scriptArguments() const;
    void setScriptArguments(PassRefPtr<ScriptArguments>);
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
    RefPtr<ScriptCallStack> m_callStack;
    OwnPtr<ScriptStateProtectingContext> m_scriptState;
    RefPtr<ScriptArguments> m_scriptArguments;
    unsigned long m_requestIdentifier;
    double m_timestamp;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_INSPECTOR_CONSOLEMESSAGE_H_
