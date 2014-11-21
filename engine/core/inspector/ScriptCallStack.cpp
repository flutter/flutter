/*
 * Copyright (c) 2008, Google Inc. All rights reserved.
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

#include "sky/engine/config.h"
#include "sky/engine/core/inspector/ScriptCallStack.h"

#include "sky/engine/core/inspector/ScriptAsyncCallStack.h"

namespace blink {

DEFINE_EMPTY_DESTRUCTOR_WILL_BE_REMOVED(ScriptCallStack);

PassRefPtr<ScriptCallStack> ScriptCallStack::create(Vector<ScriptCallFrame>& frames)
{
    return adoptRef(new ScriptCallStack(frames));
}

ScriptCallStack::ScriptCallStack(Vector<ScriptCallFrame>& frames)
{
    m_frames.swap(frames);
}

const ScriptCallFrame &ScriptCallStack::at(size_t index) const
{
    ASSERT(m_frames.size() > index);
    return m_frames[index];
}

size_t ScriptCallStack::size() const
{
    return m_frames.size();
}

PassRefPtr<ScriptAsyncCallStack> ScriptCallStack::asyncCallStack() const
{
    return m_asyncCallStack;
}

void ScriptCallStack::setAsyncCallStack(PassRefPtr<ScriptAsyncCallStack> asyncCallStack)
{
    m_asyncCallStack = asyncCallStack;
}

PassRefPtr<TypeBuilder::Array<TypeBuilder::Console::CallFrame> > ScriptCallStack::buildInspectorArray() const
{
    RefPtr<TypeBuilder::Array<TypeBuilder::Console::CallFrame> > frames = TypeBuilder::Array<TypeBuilder::Console::CallFrame>::create();
    for (size_t i = 0; i < m_frames.size(); i++)
        frames->addItem(m_frames.at(i).buildInspectorObject());
    return frames;
}

} // namespace blink
