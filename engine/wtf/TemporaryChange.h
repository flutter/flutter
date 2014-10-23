/*
 * Copyright (C) 2011 Google Inc. All rights reserved.
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

#ifndef TemporaryChange_h
#define TemporaryChange_h

#include "wtf/Noncopyable.h"

namespace WTF {

// TemporaryChange<> is useful for setting a variable to a new value only within a
// particular scope. An TemporaryChange<> object changes a variable to its original
// value upon destruction, making it an alternative to writing "var = false;"
// or "var = oldVal;" at all of a block's exit points.
//
// This should be obvious, but note that an TemporaryChange<> instance should have a
// shorter lifetime than its scopedVariable, to prevent invalid memory writes
// when the TemporaryChange<> object is destroyed.

template<typename T>
class TemporaryChange {
    WTF_MAKE_NONCOPYABLE(TemporaryChange);
public:
    TemporaryChange(T& scopedVariable, T newValue)
        : m_scopedVariable(scopedVariable)
        , m_originalValue(scopedVariable)
    {
        m_scopedVariable = newValue;
    }

    ~TemporaryChange()
    {
        m_scopedVariable = m_originalValue;
    }


private:
    T& m_scopedVariable;
    T m_originalValue;
};

}

using WTF::TemporaryChange;

#endif
