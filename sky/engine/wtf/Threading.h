/*
 * Copyright (C) 2007, 2008, 2010 Apple Inc. All rights reserved.
 * Copyright (C) 2007 Justin Haygood (jhaygood@reaktix.com)
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
 * 3.  Neither the name of Apple Computer, Inc. ("Apple") nor the names of
 *     its contributors may be used to endorse or promote products derived
 *     from this software without specific prior written permission.
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

#ifndef SKY_ENGINE_WTF_THREADING_H_
#define SKY_ENGINE_WTF_THREADING_H_

#include <stdint.h>
#include "flutter/sky/engine/wtf/WTFExport.h"

// For portability, we do not use thread-safe statics natively supported by some
// compilers (e.g. gcc).
#define AtomicallyInitializedStatic(T, name)   \
  WTF::lockAtomicallyInitializedStaticMutex(); \
  static T name;                               \
  WTF::unlockAtomicallyInitializedStaticMutex();

namespace WTF {

typedef uint32_t ThreadIdentifier;

// Called in the thread during initialization.
// Helpful for platforms where the thread name must be set from within the
// thread.
WTF_EXPORT void initializeCurrentThreadInternal(const char* threadName);

WTF_EXPORT ThreadIdentifier currentThread();

WTF_EXPORT void lockAtomicallyInitializedStaticMutex();
WTF_EXPORT void unlockAtomicallyInitializedStaticMutex();

}  // namespace WTF

using WTF::currentThread;
using WTF::ThreadIdentifier;

#endif  // SKY_ENGINE_WTF_THREADING_H_
