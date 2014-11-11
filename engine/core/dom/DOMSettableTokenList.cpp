/*
 * Copyright (C) 2010 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "core/dom/DOMSettableTokenList.h"

#include "bindings/core/v8/ExceptionState.h"

namespace blink {

DOMSettableTokenList::DOMSettableTokenList()
    : m_value()
    , m_tokens()
{
}

DOMSettableTokenList::~DOMSettableTokenList()
{
}

const AtomicString DOMSettableTokenList::item(unsigned index) const
{
    if (index >= length())
        return AtomicString();
    return m_tokens[index];
}

bool DOMSettableTokenList::containsInternal(const AtomicString& token) const
{
    return m_tokens.contains(token);
}

void DOMSettableTokenList::add(const Vector<String>& tokens, ExceptionState& exceptionState)
{
    DOMTokenList::add(tokens, exceptionState);

    for (size_t i = 0; i < tokens.size(); ++i) {
        if (m_tokens.isNull())
            m_tokens.set(AtomicString(tokens[i]), false);
        else
            m_tokens.add(AtomicString(tokens[i]));
    }
}

void DOMSettableTokenList::addInternal(const AtomicString& token)
{
    DOMTokenList::addInternal(token);
    if (m_tokens.isNull())
        m_tokens.set(token, false);
    else
        m_tokens.add(token);
}

void DOMSettableTokenList::remove(const Vector<String>& tokens, ExceptionState& exceptionState)
{
    DOMTokenList::remove(tokens, exceptionState);
    for (size_t i = 0; i < tokens.size(); ++i)
        m_tokens.remove(AtomicString(tokens[i]));
}

void DOMSettableTokenList::removeInternal(const AtomicString& token)
{
    DOMTokenList::removeInternal(token);
    m_tokens.remove(token);
}

void DOMSettableTokenList::setValue(const AtomicString& value)
{
    m_value = value;
    m_tokens.set(value, false);
}

} // namespace blink
