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

#ifndef ScriptArguments_h
#define ScriptArguments_h

#include "bindings/core/v8/ScriptState.h"
#include "wtf/Forward.h"
#include "wtf/RefCounted.h"
#include "wtf/Vector.h"
#include "wtf/text/WTFString.h"

namespace blink {

class ScriptValue;

class ScriptArguments : public RefCountedWillBeGarbageCollectedFinalized<ScriptArguments> {
    DECLARE_EMPTY_DESTRUCTOR_WILL_BE_REMOVED(ScriptArguments);
public:
    static PassRefPtrWillBeRawPtr<ScriptArguments> create(ScriptState*, Vector<ScriptValue>& arguments);

    const ScriptValue& argumentAt(size_t) const;
    size_t argumentCount() const { return m_arguments.size(); }

    ScriptState* scriptState() const { return m_scriptState.get(); }

    bool getFirstArgumentAsString(WTF::String& result, bool checkForNullOrUndefined = false);

    void trace(Visitor*) { }

private:
    ScriptArguments(ScriptState*, Vector<ScriptValue>& arguments);

    ScriptStateProtectingContext m_scriptState;
    Vector<ScriptValue> m_arguments;
};

} // namespace blink

#endif // ScriptArguments_h
