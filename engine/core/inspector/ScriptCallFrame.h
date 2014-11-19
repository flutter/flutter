/*
 * Copyright (c) 2010 Google Inc. All rights reserved.
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

#ifndef ScriptCallFrame_h
#define ScriptCallFrame_h

#include "gen/sky/core/InspectorTypeBuilder.h"
#include "wtf/Forward.h"
#include "wtf/text/WTFString.h"

namespace blink {

class ScriptCallFrame  {
public:
    ScriptCallFrame();
    ScriptCallFrame(const String& functionName, const String& scriptId, const String& scriptName, unsigned lineNumber, unsigned column = 0);
    ~ScriptCallFrame();

    const String& functionName() const { return m_functionName; }
    const String& scriptId() const { return m_scriptId; }
    const String& sourceURL() const { return m_scriptName; }
    unsigned lineNumber() const { return m_lineNumber; }
    unsigned columnNumber() const { return m_column; }

    PassRefPtr<TypeBuilder::Console::CallFrame> buildInspectorObject() const;

private:
    String m_functionName;
    String m_scriptId;
    String m_scriptName;
    unsigned m_lineNumber;
    unsigned m_column;
};

} // namespace blink

#endif // ScriptCallFrame_h
