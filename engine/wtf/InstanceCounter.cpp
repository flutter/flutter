/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
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

#include "config.h"
#include "InstanceCounter.h"

#include "wtf/HashMap.h"
#include "wtf/StdLibExtras.h"
#include "wtf/ThreadingPrimitives.h"
#include "wtf/text/StringBuilder.h"
#include "wtf/text/StringHash.h"
#include "wtf/text/WTFString.h"

namespace WTF {

#if ENABLE(INSTANCE_COUNTER) || ENABLE(GC_PROFILING)

#if COMPILER(CLANG)
const size_t extractNameFunctionPrefixLength = sizeof("const char *WTF::extractNameFunction() [T = ") - 1;
const size_t extractNameFunctionPostfixLength = sizeof("]") - 1;
#elif COMPILER(GCC)
const size_t extractNameFunctionPrefixLength = sizeof("const char* WTF::extractNameFunction() [with T = ") - 1;
const size_t extractNameFunctionPostfixLength = sizeof("]") - 1;
#elif COMPILER(MSVC)
const size_t extractNameFunctionPrefixLength = sizeof("const char *__cdecl WTF::extractNameFunction<class ") - 1;
const size_t extractNameFunctionPostfixLength = sizeof(">(void)") - 1;
#else
#warning "Extracting typename is supported only in compiler GCC, CLANG and MSVC at this moment"
#endif

// This function is used to stringify a typename T without using RTTI.
// The result of extractNameFunction<T>() is given as |funcName|. |extractTypeNameFromFunctionName| then extracts a typename string from |funcName|.
String extractTypeNameFromFunctionName(const char* funcName)
{
#if COMPILER(CLANG) || COMPILER(GCC) || COMPILER(MSVC)
    size_t funcNameLength = strlen(funcName);
    ASSERT(funcNameLength > extractNameFunctionPrefixLength + extractNameFunctionPostfixLength);

    const char* funcNameWithoutPrefix = funcName + extractNameFunctionPrefixLength;
    return String(funcNameWithoutPrefix, funcNameLength - extractNameFunctionPrefixLength - extractNameFunctionPostfixLength);
#else
    return String("unknown");
#endif
}

class InstanceCounter {
public:
    void incrementInstanceCount(const String& instanceName, void* ptr);
    void decrementInstanceCount(const String& instanceName, void* ptr);
    String dump();

    static InstanceCounter* instance()
    {
        DEFINE_STATIC_LOCAL(InstanceCounter, self, ());
        return &self;
    }

private:
    InstanceCounter() { }

    Mutex m_mutex;
    HashMap<String, int> m_counterMap;
};

void incrementInstanceCount(const char* extractNameFunctionName, void* ptr)
{
    String instanceName = extractTypeNameFromFunctionName(extractNameFunctionName);
    InstanceCounter::instance()->incrementInstanceCount(instanceName, ptr);
}

void decrementInstanceCount(const char* extractNameFunctionName, void* ptr)
{
    String instanceName = extractTypeNameFromFunctionName(extractNameFunctionName);
    InstanceCounter::instance()->decrementInstanceCount(instanceName, ptr);
}

String dumpRefCountedInstanceCounts()
{
    return InstanceCounter::instance()->dump();
}

void InstanceCounter::incrementInstanceCount(const String& instanceName, void* ptr)
{
    MutexLocker locker(m_mutex);
    HashMap<String, int>::AddResult result = m_counterMap.add(instanceName, 1);
    if (!result.isNewEntry)
        ++(result.storedValue->value);
}

void InstanceCounter::decrementInstanceCount(const String& instanceName, void* ptr)
{
    MutexLocker locker(m_mutex);
    HashMap<String, int>::iterator it = m_counterMap.find(instanceName);
    ASSERT(it != m_counterMap.end());

    --(it->value);
    if (!it->value)
        m_counterMap.remove(it);
}

String InstanceCounter::dump()
{
    MutexLocker locker(m_mutex);

    StringBuilder builder;

    builder.append("{");
    HashMap<String, int>::iterator it = m_counterMap.begin();
    HashMap<String, int>::iterator itEnd = m_counterMap.end();
    for (; it != itEnd; ++it) {
        if (it != m_counterMap.begin())
            builder.append(",");
        builder.append("\"");
        builder.append(it->key);
        builder.append("\": ");
        builder.append(String::number(it->value));
    }
    builder.append("}");

    return builder.toString();
}

#else

String dumpRefCountedInstanceCounts()
{
    return String("{}");
}

#endif // ENABLE(INSTANCE_COUNTER) || ENABLE(GC_PROFILING)

} // namespace WTF
