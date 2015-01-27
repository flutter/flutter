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

#ifndef DartScriptWrappable_h
#define DartScriptWrappable_h

#include "bindings/common/ScriptWrappable.h"
#include <dart_api.h>

namespace blink {

class DartWrapperInfo {
public:
    void* domData;
    void* wrapper;
};

class DartMultiWrapperInfo {
public:
    Vector<void*> domDatas;
    Vector<void*> wrappers;
};

void ScriptWrappable::setDartWrapper(void* domData, void* wrapper)
{
    ASSERT(domData);
    if (LIKELY(m_dartWrapperInfo.isEmpty())) {
        DartWrapperInfo* wrapperInfo = new DartWrapperInfo;
        wrapperInfo->domData = domData;
        wrapperInfo->wrapper = wrapper;
        m_dartWrapperInfo = TaggedPointer(wrapperInfo);
    } else if (m_dartWrapperInfo.isDartWrapperInfo()) {
        DartWrapperInfo* wrapperInfo = m_dartWrapperInfo.dartWrapperInfo();
        if (wrapperInfo->domData == domData) {
            // Replace the current wrapper.
            wrapperInfo->wrapper = wrapper;
        } else {
            // Inflate to a multiwrapper.
            DartMultiWrapperInfo* multiWrapperInfo = new DartMultiWrapperInfo;
            multiWrapperInfo->domDatas.append(wrapperInfo->domData);
            multiWrapperInfo->wrappers.append(wrapperInfo->wrapper);
            multiWrapperInfo->domDatas.append(domData);
            multiWrapperInfo->wrappers.append(wrapper);
            m_dartWrapperInfo = TaggedPointer(multiWrapperInfo);
            delete wrapperInfo;
        }
    } else {
        ASSERT(m_dartWrapperInfo.isDartMultiWrapperInfo());
        DartMultiWrapperInfo* wrapperInfo = m_dartWrapperInfo.dartMultiWrapperInfo();
        size_t len = wrapperInfo->domDatas.size();
        for (size_t i = 0; i < len; i++) {
            if (wrapperInfo->domDatas.at(i) == domData) {
                // Replace the current wrapper.
                wrapperInfo->wrappers[i] = wrapper;
                return;
            }
        }
        // Append wrapper for new isolate.
        wrapperInfo->domDatas.append(domData);
        wrapperInfo->wrappers.append(wrapper);
    }
}

void* ScriptWrappable::getDartWrapper(void* domData) const
{
    ASSERT(domData);
    if (m_dartWrapperInfo.isDartWrapperInfo()) {
        DartWrapperInfo* wrapperInfo = m_dartWrapperInfo.dartWrapperInfo();
        if (wrapperInfo->domData == domData) {
            return wrapperInfo->wrapper;
        }
        return 0;
    }
    if (m_dartWrapperInfo.isDartMultiWrapperInfo()) {
        DartMultiWrapperInfo* wrapperInfo = m_dartWrapperInfo.dartMultiWrapperInfo();
        size_t len = wrapperInfo->domDatas.size();
        for (size_t i = 0; i < len; ++i) {
            if (wrapperInfo->domDatas[i] == domData) {
                return wrapperInfo->wrappers[i];
            }
        }
        return 0;
    }
    ASSERT(m_dartWrapperInfo.isWrapperTypeInfo() || m_dartWrapperInfo.isV8Wrapper());
    return 0;
}

void ScriptWrappable::clearDartWrapper(void* domData)
{
    if (LIKELY(m_dartWrapperInfo.isDartWrapperInfo())) {
        DartWrapperInfo* wrapperInfo = m_dartWrapperInfo.dartWrapperInfo();
        ASSERT(domData == wrapperInfo->domData);
        m_dartWrapperInfo = TaggedPointer();
        delete wrapperInfo;
    } else if (m_dartWrapperInfo.isDartMultiWrapperInfo()) {
        // Remove.
        DartMultiWrapperInfo* wrapperInfo = m_dartWrapperInfo.dartMultiWrapperInfo();
        size_t len = wrapperInfo->domDatas.size();
        for (size_t i = 0; i < len; i++) {
            if (wrapperInfo->domDatas[i] == domData) {
                wrapperInfo->domDatas.remove(i);
                wrapperInfo->wrappers.remove(i);
                if (len == 1) {
                    m_dartWrapperInfo = TaggedPointer();
                    delete wrapperInfo;
                }
                return;
            }
        }
        // Could not find wrapper.
        ASSERT_NOT_REACHED();
    } else {
        // No Dart wrappers.
        ASSERT_NOT_REACHED();
    }
}

} // namespace blink

#endif // DartScriptWrappable_h
