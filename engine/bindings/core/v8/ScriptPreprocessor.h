/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
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
#ifndef ScriptPreprocessor_h
#define ScriptPreprocessor_h

#include "bindings/core/v8/V8Binding.h"
#include "wtf/RefCounted.h"
#include "wtf/text/WTFString.h"
#include <v8.h>

namespace blink {

class ScriptController;
class ScriptSourceCode;
class ScriptDebugServer;

class ScriptPreprocessor {
    WTF_MAKE_NONCOPYABLE(ScriptPreprocessor);
public:
    ScriptPreprocessor(const ScriptSourceCode&, LocalFrame*);
    String preprocessSourceCode(const String& sourceCode, const String& sourceName);
    String preprocessSourceCode(const String& sourceCode, const String& sourceName, const String& functionName);
    bool isPreprocessing() { return m_isPreprocessing; }
    bool isValid() { return !m_preprocessorFunction.isEmpty(); }

private:
    String preprocessSourceCode(const String& sourceCode, const String& sourceName, v8::Handle<v8::Value> functionName);
    RefPtr<ScriptState> m_scriptState;
    ScopedPersistent<v8::Function> m_preprocessorFunction;
    bool m_isPreprocessing;
};

} // namespace blink

#endif // ScriptPreprocessor_h
