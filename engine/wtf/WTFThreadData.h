/*
 * Copyright (C) 2008 Apple Inc. All Rights Reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

#ifndef WTFThreadData_h
#define WTFThreadData_h

#include "wtf/HashMap.h"
#include "wtf/HashSet.h"
#include "wtf/Noncopyable.h"
#include "wtf/ThreadSpecific.h"
#include "wtf/Threading.h"
#include "wtf/WTFExport.h"
#include "wtf/text/StringHash.h"

namespace WTF {

class AtomicStringTable;
struct ICUConverterWrapper;

typedef void (*AtomicStringTableDestructor)(AtomicStringTable*);

class WTF_EXPORT WTFThreadData {
    WTF_MAKE_NONCOPYABLE(WTFThreadData);
public:
    WTFThreadData();
    ~WTFThreadData();

    AtomicStringTable* atomicStringTable()
    {
        return m_atomicStringTable;
    }

    ICUConverterWrapper& cachedConverterICU() { return *m_cachedConverterICU; }

private:
    AtomicStringTable* m_atomicStringTable;
    AtomicStringTableDestructor m_atomicStringTableDestructor;
    OwnPtr<ICUConverterWrapper> m_cachedConverterICU;

    static ThreadSpecific<WTFThreadData>* staticData;
    friend WTFThreadData& wtfThreadData();
    friend class AtomicStringTable;
};

inline WTFThreadData& wtfThreadData()
{
    // WRT WebCore:
    //    WTFThreadData is used on main thread before it could possibly be used
    //    on secondary ones, so there is no need for synchronization here.
    // WRT JavaScriptCore:
    //    wtfThreadData() is initially called from initializeThreading(), ensuring
    //    this is initially called in a pthread_once locked context.
    if (!WTFThreadData::staticData)
        WTFThreadData::staticData = new ThreadSpecific<WTFThreadData>;
    return **WTFThreadData::staticData;
}

} // namespace WTF

using WTF::WTFThreadData;
using WTF::wtfThreadData;

#endif // WTFThreadData_h
