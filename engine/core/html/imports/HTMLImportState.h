/*
 * Copyright (C) 2014 Google Inc. All rights reserved.
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

#ifndef HTMLImportState_h
#define HTMLImportState_h

#include "wtf/Assertions.h"

namespace blink {

class HTMLImportState {
public:
    enum Value {
        BlockingScriptExecution = 0,
        Active,
        Ready,
        Invalid
    };

    explicit HTMLImportState(Value value = BlockingScriptExecution)
        : m_value(value)
    { }

    bool shouldBlockScriptExecution() const { return checkedValue() <= BlockingScriptExecution; }
    bool isReady() const { return checkedValue() == Ready; }
    bool isValid() const { return m_value != Invalid; }
    bool operator==(const HTMLImportState& other) const { return m_value == other.m_value; }
    bool operator!=(const HTMLImportState& other) const { return !(*this == other); }
    bool operator<=(const HTMLImportState& other) const { return m_value <= other.m_value; }

#if !defined(NDEBUG)
    Value peekValueForDebug() const { return m_value; }
#endif

    static HTMLImportState invalidState() { return HTMLImportState(Invalid); }
    static HTMLImportState blockedState() { return HTMLImportState(BlockingScriptExecution); }
private:
    Value checkedValue() const;
    Value m_value;
};

inline HTMLImportState::Value HTMLImportState::checkedValue() const
{
    ASSERT(isValid());
    return m_value;
}

}

#endif
