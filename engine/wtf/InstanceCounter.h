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

#ifndef InstanceCounter_h
#define InstanceCounter_h

#include "wtf/Compiler.h"
#include "wtf/WTFExport.h"

namespace WTF {

class String;
WTF_EXPORT String dumpRefCountedInstanceCounts();

#if ENABLE(INSTANCE_COUNTER) || ENABLE(GC_PROFILING)
WTF_EXPORT void incrementInstanceCount(const char* extractNameFunctionName, void* ptr);
WTF_EXPORT void decrementInstanceCount(const char* extractNameFunctionName, void* ptr);

WTF_EXPORT String extractTypeNameFromFunctionName(const char* funcName);

template<typename T>
inline const char* extractNameFunction()
{
    return WTF_PRETTY_FUNCTION;
}

template<typename T>
inline void incrementInstanceCount(T* p)
{
    incrementInstanceCount(extractNameFunction<T>(), p);
}

template<typename T>
inline void decrementInstanceCount(T* p)
{
    decrementInstanceCount(extractNameFunction<T>(), p);
}

#endif // ENABLE(INSTANCE_COUNTER) || ENABLE(GC_PROFILING)

} // namespace WTF

#endif
