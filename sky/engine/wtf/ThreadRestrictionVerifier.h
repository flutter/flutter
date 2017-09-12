/*
 * Copyright (C) 2011 Google Inc. All rights reserved.
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

#ifndef SKY_ENGINE_WTF_THREADRESTRICTIONVERIFIER_H_
#define SKY_ENGINE_WTF_THREADRESTRICTIONVERIFIER_H_

#include "flutter/sky/engine/wtf/Assertions.h"

#if ENABLE(ASSERT)

#include "flutter/sky/engine/wtf/Threading.h"

namespace WTF {

// Verifies that a class is used in a way that respects its lack of
// thread-safety. The default mode is to verify that the object will only be
// used on a single thread. The thread gets captured when setShared(true) is
// called. The mode may be changed by calling useMutexMode (or
// turnOffVerification).
class ThreadRestrictionVerifier {
 public:
  ThreadRestrictionVerifier() : m_shared(false), m_owningThread(0) {}

  // Indicates that the object may (or may not) be owned by more than one place.
  void setShared(bool shared) {
    bool previouslyShared = m_shared;
    m_shared = shared;

    if (!m_shared)
      return;

    ASSERT(shared != previouslyShared);
    // Capture the current thread to verify that subsequent ref/deref happen on
    // this thread.
    m_owningThread = currentThread();
  }

  // Is it OK to use the object at this moment on the current thread?
  bool isSafeToUse() const {
    if (!m_shared)
      return true;

    return m_owningThread == currentThread();
  }

 private:
  bool m_shared;

  // Used by SingleThreadVerificationMode
  ThreadIdentifier m_owningThread;
};

}  // namespace WTF

#endif  // ENABLE(ASSERT)
#endif  // SKY_ENGINE_WTF_THREADRESTRICTIONVERIFIER_H_
