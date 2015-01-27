// Copyright 2012, Google Inc.
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//    * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//    * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#ifndef DartStringCache_h
#define DartStringCache_h

#include "wtf/HashMap.h"
#include "wtf/RefPtr.h"
#include "wtf/text/StringHash.h"
#include "wtf/text/StringImpl.h"

#include <dart_api.h>

namespace blink {

class DartStringCache {
public:
    DartStringCache();

    Dart_WeakPersistentHandle get(StringImpl* stringImpl, bool autoDartScope = true)
    {
        ASSERT(stringImpl);

        if (m_lastStringImpl.get() == stringImpl)
            return m_lastDartString;

        return getSlow(stringImpl, autoDartScope);
    }

    void clearWeakHandles();

    // FIXME: implement clearing on GC.

private:
    Dart_WeakPersistentHandle getSlow(StringImpl*, bool autoDartScope);
    static void handleFinalizer(void*, Dart_WeakPersistentHandle, void* peer);

    typedef HashMap<StringImpl*, Dart_WeakPersistentHandle> StringCache;
    StringCache m_stringCache;
    Dart_WeakPersistentHandle m_lastDartString;
    // Note: RefPtr is a must as we cache by StringImpl* equality, not identity
    // hence lastStringImpl might be not a key of the cache (in sense of identity)
    // and hence it's not refed on addition.
    RefPtr<StringImpl> m_lastStringImpl;
};

}

#endif
