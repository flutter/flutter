/*
 * Copyright (C) 2007, 2009 Apple Inc. All rights reserved.
 * Copyright (C) 2007 Justin Haygood (jhaygood@reaktix.com)
 * Copyright (C) 2011 Research In Motion Limited. All rights reserved.
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

#include "flutter/sky/engine/wtf/Threading.h"

#if USE(PTHREADS)

#include <errno.h>
#include "flutter/sky/engine/wtf/HashMap.h"
#include "flutter/sky/engine/wtf/OwnPtr.h"
#include "flutter/sky/engine/wtf/PassOwnPtr.h"
#include "flutter/sky/engine/wtf/StdLibExtras.h"
#include "flutter/sky/engine/wtf/ThreadIdentifierDataPthreads.h"
#include "flutter/sky/engine/wtf/ThreadSpecific.h"
#include "flutter/sky/engine/wtf/ThreadingPrimitives.h"
#include "flutter/sky/engine/wtf/WTFThreadData.h"
#include "flutter/sky/engine/wtf/dtoa.h"
#include "wtf/dtoa/cached-powers.h"

#include <limits.h>
#include <sched.h>
#include <sys/time.h>

namespace WTF {

class PthreadState {
  WTF_MAKE_FAST_ALLOCATED;

 public:
  enum JoinableState {
    Joinable,  // The default thread state. The thread can be joined on.

    Joined,  // Somebody waited on this thread to exit and this thread finally
             // exited. This state is here because there can be a period of time
             // between when the thread exits (which causes pthread_join to
             // return and the remainder of waitOnThreadCompletion to run) and
             // when threadDidExit is called. We need threadDidExit to take
             // charge and delete the thread data since there's nobody else to
             // pick up the slack in this case (since waitOnThreadCompletion has
             // already returned).

    Detached  // The thread has been detached and can no longer be joined on. At
              // this point, the thread must take care of cleaning up after
              // itself.
  };

  // Currently all threads created by WTF start out as joinable.
  PthreadState(pthread_t handle)
      : m_joinableState(Joinable), m_didExit(false), m_pthreadHandle(handle) {}

  JoinableState joinableState() { return m_joinableState; }
  pthread_t pthreadHandle() { return m_pthreadHandle; }
  void didBecomeDetached() { m_joinableState = Detached; }
  void didExit() { m_didExit = true; }
  void didJoin() { m_joinableState = Joined; }
  bool hasExited() { return m_didExit; }

 private:
  JoinableState m_joinableState;
  bool m_didExit;
  pthread_t m_pthreadHandle;
};

typedef HashMap<ThreadIdentifier, OwnPtr<PthreadState>> ThreadMap;

static Mutex* atomicallyInitializedStaticMutex;

void unsafeThreadWasDetached(ThreadIdentifier);
void threadDidExit(ThreadIdentifier);
void threadWasJoined(ThreadIdentifier);

static Mutex& threadMapMutex() {
  DEFINE_STATIC_LOCAL(Mutex, mutex, ());
  return mutex;
}

void initializeThreading() {
  // This should only be called once.
  ASSERT(!atomicallyInitializedStaticMutex);

  // StringImpl::empty() does not construct its static string in a threadsafe
  // fashion, so ensure it has been initialized from here.
  StringImpl::empty();
  atomicallyInitializedStaticMutex = new Mutex;
  threadMapMutex();
  ThreadIdentifierData::initializeOnce();
  wtfThreadData();
  s_dtoaP5Mutex = new Mutex;
}

void lockAtomicallyInitializedStaticMutex() {
  ASSERT(atomicallyInitializedStaticMutex);
  atomicallyInitializedStaticMutex->lock();
}

void unlockAtomicallyInitializedStaticMutex() {
  atomicallyInitializedStaticMutex->unlock();
}

static ThreadMap& threadMap() {
  DEFINE_STATIC_LOCAL(ThreadMap, map, ());
  return map;
}

static ThreadIdentifier identifierByPthreadHandle(
    const pthread_t& pthreadHandle) {
  MutexLocker locker(threadMapMutex());

  ThreadMap::iterator i = threadMap().begin();
  for (; i != threadMap().end(); ++i) {
    if (pthread_equal(i->value->pthreadHandle(), pthreadHandle) &&
        !i->value->hasExited())
      return i->key;
  }

  return 0;
}

static ThreadIdentifier establishIdentifierForPthreadHandle(
    const pthread_t& pthreadHandle) {
  ASSERT(!identifierByPthreadHandle(pthreadHandle));
  MutexLocker locker(threadMapMutex());
  static ThreadIdentifier identifierCount = 1;
  threadMap().add(identifierCount, adoptPtr(new PthreadState(pthreadHandle)));
  return identifierCount++;
}

void initializeCurrentThreadInternal(const char* threadName) {
  ThreadIdentifier id = identifierByPthreadHandle(pthread_self());
  ASSERT(id);
  ThreadIdentifierData::initialize(id);
}

void threadDidExit(ThreadIdentifier threadID) {
  MutexLocker locker(threadMapMutex());
  PthreadState* state = threadMap().get(threadID);
  ASSERT(state);

  state->didExit();

  if (state->joinableState() != PthreadState::Joinable)
    threadMap().remove(threadID);
}

ThreadIdentifier currentThread() {
  ThreadIdentifier id = ThreadIdentifierData::identifier();
  if (id)
    return id;

  // Not a WTF-created thread, ThreadIdentifier is not established yet.
  id = establishIdentifierForPthreadHandle(pthread_self());
  ThreadIdentifierData::initialize(id);
  return id;
}

MutexBase::MutexBase(bool recursive) {
  pthread_mutexattr_t attr;
  pthread_mutexattr_init(&attr);
  pthread_mutexattr_settype(
      &attr, recursive ? PTHREAD_MUTEX_RECURSIVE : PTHREAD_MUTEX_NORMAL);

  int result = pthread_mutex_init(&m_mutex.m_internalMutex, &attr);
  ASSERT_UNUSED(result, !result);
#if ENABLE(ASSERT)
  m_mutex.m_recursionCount = 0;
#endif

  pthread_mutexattr_destroy(&attr);
}

MutexBase::~MutexBase() {
  int result = pthread_mutex_destroy(&m_mutex.m_internalMutex);
  ASSERT_UNUSED(result, !result);
}

void MutexBase::lock() {
  int result = pthread_mutex_lock(&m_mutex.m_internalMutex);
  ASSERT_UNUSED(result, !result);
#if ENABLE(ASSERT)
  ++m_mutex.m_recursionCount;
#endif
}

void MutexBase::unlock() {
#if ENABLE(ASSERT)
  ASSERT(m_mutex.m_recursionCount);
  --m_mutex.m_recursionCount;
#endif
  int result = pthread_mutex_unlock(&m_mutex.m_internalMutex);
  ASSERT_UNUSED(result, !result);
}

// There is a separate tryLock implementation for the Mutex and the
// RecursiveMutex since on Windows we need to manually check if tryLock should
// succeed or not for the non-recursive mutex. On Linux the two implementations
// are equal except we can assert the recursion count is always zero for the
// non-recursive mutex.
bool Mutex::tryLock() {
  int result = pthread_mutex_trylock(&m_mutex.m_internalMutex);
  if (result == 0) {
#if ENABLE(ASSERT)
    // The Mutex class is not recursive, so the recursionCount should be
    // zero after getting the lock.
    ASSERT(!m_mutex.m_recursionCount);
    ++m_mutex.m_recursionCount;
#endif
    return true;
  }
  if (result == EBUSY)
    return false;

  ASSERT_NOT_REACHED();
  return false;
}

bool RecursiveMutex::tryLock() {
  int result = pthread_mutex_trylock(&m_mutex.m_internalMutex);
  if (result == 0) {
#if ENABLE(ASSERT)
    ++m_mutex.m_recursionCount;
#endif
    return true;
  }
  if (result == EBUSY)
    return false;

  ASSERT_NOT_REACHED();
  return false;
}

}  // namespace WTF

#endif  // USE(PTHREADS)
