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

#include "config.h"
#include "bindings/core/dart/DartStringCache.h"

#include "bindings/core/dart/DartDOMData.h"
#include "bindings/core/dart/DartUtilities.h"

namespace blink {

DartStringCache::DartStringCache()
{
    m_lastStringImpl = nullptr;
    m_lastDartString = 0;
}

void DartStringCache::clearWeakHandles()
{
    Dart_Isolate isolate = Dart_CurrentIsolate();
    for (StringCache::iterator it = m_stringCache.begin(); it != m_stringCache.end(); ++it) {
        it->key->deref();
        Dart_DeleteWeakPersistentHandle(isolate, it->value);
    }
    m_stringCache.clear();
    m_lastStringImpl = nullptr;
    m_lastDartString = 0;
}

Dart_WeakPersistentHandle DartStringCache::getSlow(StringImpl* stringImpl, bool autoDartScope)
{
    ASSERT(stringImpl);

    Dart_WeakPersistentHandle cachedString = m_stringCache.get(stringImpl);
    if (cachedString) {
        m_lastStringImpl = stringImpl;
        m_lastDartString = cachedString;
        return cachedString;
    }

    if (!autoDartScope)
        Dart_EnterScope();

    ASSERT(stringImpl);
    Dart_Handle newString = DartUtilities::stringImplToDartString(stringImpl);
    ASSERT(!Dart_IsError(newString));

    intptr_t peerSize = stringImpl->sizeInBytes();
    Dart_WeakPersistentHandle wrapper = Dart_NewWeakPersistentHandle(newString, stringImpl, peerSize, handleFinalizer);

    stringImpl->ref();
    m_stringCache.set(stringImpl, wrapper);

    m_lastStringImpl = stringImpl;
    m_lastDartString = wrapper;

    if (!autoDartScope)
        Dart_ExitScope();

    return wrapper;
}

void DartStringCache::handleFinalizer(void* isolateCallbackData, Dart_WeakPersistentHandle handle, void* peer)
{
    StringImpl* stringImpl = reinterpret_cast<StringImpl*>(peer);
    DartDOMData* domData = reinterpret_cast<DartDOMData*>(isolateCallbackData);
    DartStringCache& stringCache = domData->stringCache();
    Dart_WeakPersistentHandle ALLOW_UNUSED cached = stringCache.m_stringCache.take(stringImpl);
    ASSERT(handle == cached);
    if (stringCache.m_lastDartString == handle) {
        stringCache.m_lastStringImpl = nullptr;
        stringCache.m_lastDartString = 0;
    }
    stringImpl->deref();
}

}
