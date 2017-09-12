/*
 * Copyright (C) 2009 Google Inc. All rights reserved.
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

#ifndef SKY_ENGINE_WTF_THREADIDENTIFIERDATAPTHREADS_H_
#define SKY_ENGINE_WTF_THREADIDENTIFIERDATAPTHREADS_H_

#include <pthread.h>
#include "flutter/sky/engine/wtf/Noncopyable.h"
#include "flutter/sky/engine/wtf/Threading.h"

namespace WTF {

// Holds ThreadIdentifier in the thread-specific storage and employs
// pthreads-specific 2-pass destruction to reliably remove ThreadIdentifier from
// threadMap. It assumes regular ThreadSpecific types don't use multiple-pass
// destruction.
class ThreadIdentifierData {
  WTF_MAKE_NONCOPYABLE(ThreadIdentifierData);

 public:
  ~ThreadIdentifierData();

  // One time initialization for this class as a whole.
  // This method must be called before initialize() and it is not thread-safe.
  static void initializeOnce();

  // Creates and puts an instance of ThreadIdentifierData into thread-specific
  // storage.
  static void initialize(ThreadIdentifier identifier);

  // Returns 0 if thread-specific storage was not initialized.
  static ThreadIdentifier identifier();

 private:
  ThreadIdentifierData(ThreadIdentifier identifier)
      : m_identifier(identifier), m_isDestroyedOnce(false) {}

  // This thread-specific destructor is called 2 times when thread terminates:
  // - first, when all the other thread-specific destructors are called, it
  // simply remembers it was 'destroyed once' and re-sets itself into the
  // thread-specific slot to make Pthreads to call it again later.
  // - second, after all thread-specific destructors were invoked, it gets
  // called again - this time, we remove the ThreadIdentifier from the
  // threadMap, completing the cleanup.
  static void destruct(void* data);

  ThreadIdentifier m_identifier;
  bool m_isDestroyedOnce;
  static pthread_key_t m_key;
};

}  // namespace WTF

#endif  // SKY_ENGINE_WTF_THREADIDENTIFIERDATAPTHREADS_H_
