/*
 * Copyright (C) 2008 Apple Inc. All rights reserved.
 * Copyright (C) 2009 Jian Li <jianli@chromium.org>
 * Copyright (C) 2012 Patrick Gansterer <paroga@paroga.com>
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

/* Thread local storage is implemented by using either pthread API or Windows
 * native API. There is subtle semantic discrepancy for the cleanup function
 * implementation as noted below:
 *   @ In pthread implementation, the destructor function will be called
 *     repeatedly if there is still non-NULL value associated with the function.
 *   @ In Windows native implementation, the destructor function will be called
 *     only once.
 * This semantic discrepancy does not impose any problem because nowhere in
 * WebKit the repeated call bahavior is utilized.
 */

#ifndef SKY_ENGINE_WTF_THREADSPECIFIC_H_
#define SKY_ENGINE_WTF_THREADSPECIFIC_H_

#include "flutter/sky/engine/wtf/FastMalloc.h"
#include "flutter/sky/engine/wtf/Noncopyable.h"
#include "flutter/sky/engine/wtf/StdLibExtras.h"
#include "flutter/sky/engine/wtf/WTF.h"
#include "flutter/sky/engine/wtf/WTFExport.h"

#if USE(PTHREADS)
#include <pthread.h>
#elif OS(WIN)
#include <windows.h>
#endif

namespace WTF {

#if OS(WIN)
// ThreadSpecificThreadExit should be called each time when a thread is
// detached. This is done automatically for threads created with
// WTF::createThread.
WTF_EXPORT void ThreadSpecificThreadExit();
#endif

template <typename T>
class ThreadSpecific {
  WTF_MAKE_NONCOPYABLE(ThreadSpecific);

 public:
  ThreadSpecific();
  bool
  isSet();  // Useful as a fast check to see if this thread has set this value.
  T* operator->();
  operator T*();
  T& operator*();

 private:
#if OS(WIN)
  WTF_EXPORT friend void ThreadSpecificThreadExit();
#endif

  // Not implemented. It's technically possible to destroy a thread specific
  // key, but one would need to make sure that all values have been destroyed
  // already (usually, that all threads that used it have exited). It's unlikely
  // that any user of this call will be in that situation - and having a
  // destructor defined can be confusing, given that it has such strong
  // pre-requisites to work correctly.
  ~ThreadSpecific();

  T* get();
  void set(T*);
  void static destroy(void* ptr);

  struct Data {
    WTF_MAKE_NONCOPYABLE(Data);

   public:
    Data(T* value, ThreadSpecific<T>* owner) : value(value), owner(owner) {}

    T* value;
    ThreadSpecific<T>* owner;
#if OS(WIN)
    void (*destructor)(void*);
#endif
  };

#if USE(PTHREADS)
  pthread_key_t m_key;
#elif OS(WIN)
  int m_index;
#endif
};

#if USE(PTHREADS)

typedef pthread_key_t ThreadSpecificKey;

inline void threadSpecificKeyCreate(ThreadSpecificKey* key,
                                    void (*destructor)(void*)) {
  int error = pthread_key_create(key, destructor);
  if (error)
    CRASH();
}

inline void threadSpecificKeyDelete(ThreadSpecificKey key) {
  int error = pthread_key_delete(key);
  if (error)
    CRASH();
}

inline void threadSpecificSet(ThreadSpecificKey key, void* value) {
  pthread_setspecific(key, value);
}

inline void* threadSpecificGet(ThreadSpecificKey key) {
  return pthread_getspecific(key);
}

template <typename T>
inline ThreadSpecific<T>::ThreadSpecific() {
  int error = pthread_key_create(&m_key, destroy);
  if (error)
    CRASH();
}

template <typename T>
inline T* ThreadSpecific<T>::get() {
  Data* data = static_cast<Data*>(pthread_getspecific(m_key));
  return data ? data->value : 0;
}

template <typename T>
inline void ThreadSpecific<T>::set(T* ptr) {
  ASSERT(!get());
  pthread_setspecific(m_key, new Data(ptr, this));
}

#elif OS(WIN)

// TLS_OUT_OF_INDEXES is not defined on WinCE.
#ifndef TLS_OUT_OF_INDEXES
#define TLS_OUT_OF_INDEXES 0xffffffff
#endif

// The maximum number of TLS keys that can be created. For simplification, we
// assume that: 1) Once the instance of ThreadSpecific<> is created, it will not
// be destructed until the program dies. 2) We do not need to hold many
// instances of ThreadSpecific<> data. This fixed number should be far enough.
const int kMaxTlsKeySize = 256;

WTF_EXPORT long& tlsKeyCount();
WTF_EXPORT DWORD* tlsKeys();

class PlatformThreadSpecificKey;
typedef PlatformThreadSpecificKey* ThreadSpecificKey;

WTF_EXPORT void threadSpecificKeyCreate(ThreadSpecificKey*, void (*)(void*));
WTF_EXPORT void threadSpecificKeyDelete(ThreadSpecificKey);
WTF_EXPORT void threadSpecificSet(ThreadSpecificKey, void*);
WTF_EXPORT void* threadSpecificGet(ThreadSpecificKey);

template <typename T>
inline ThreadSpecific<T>::ThreadSpecific() : m_index(-1) {
  DWORD tlsKey = TlsAlloc();
  if (tlsKey == TLS_OUT_OF_INDEXES)
    CRASH();

  m_index = InterlockedIncrement(&tlsKeyCount()) - 1;
  if (m_index >= kMaxTlsKeySize)
    CRASH();
  tlsKeys()[m_index] = tlsKey;
}

template <typename T>
inline ThreadSpecific<T>::~ThreadSpecific() {
  // Does not invoke destructor functions. They will be called from
  // ThreadSpecificThreadExit when the thread is detached.
  TlsFree(tlsKeys()[m_index]);
}

template <typename T>
inline T* ThreadSpecific<T>::get() {
  Data* data = static_cast<Data*>(TlsGetValue(tlsKeys()[m_index]));
  return data ? data->value : 0;
}

template <typename T>
inline void ThreadSpecific<T>::set(T* ptr) {
  ASSERT(!get());
  Data* data = new Data(ptr, this);
  data->destructor = &ThreadSpecific<T>::destroy;
  TlsSetValue(tlsKeys()[m_index], data);
}

#else
#error ThreadSpecific is not implemented for this platform.
#endif

template <typename T>
inline void ThreadSpecific<T>::destroy(void* ptr) {
  if (isShutdown())
    return;

  Data* data = static_cast<Data*>(ptr);

#if USE(PTHREADS)
  // We want get() to keep working while data destructor works, because it can
  // be called indirectly by the destructor. Some pthreads implementations zero
  // out the pointer before calling destroy(), so we temporarily reset it.
  pthread_setspecific(data->owner->m_key, ptr);
#endif

  data->value->~T();
  fastFree(data->value);

#if USE(PTHREADS)
  pthread_setspecific(data->owner->m_key, 0);
#elif OS(WIN)
  TlsSetValue(tlsKeys()[data->owner->m_index], 0);
#else
#error ThreadSpecific is not implemented for this platform.
#endif

  delete data;
}

template <typename T>
inline bool ThreadSpecific<T>::isSet() {
  return !!get();
}

template <typename T>
inline ThreadSpecific<T>::operator T*() {
  T* ptr = static_cast<T*>(get());
  if (!ptr) {
    // Set up thread-specific value's memory pointer before invoking
    // constructor, in case any function it calls needs to access the value, to
    // avoid recursion.
    ptr = static_cast<T*>(fastZeroedMalloc(sizeof(T)));
    set(ptr);
    new (NotNull, ptr) T;
  }
  return ptr;
}

template <typename T>
inline T* ThreadSpecific<T>::operator->() {
  return operator T*();
}

template <typename T>
inline T& ThreadSpecific<T>::operator*() {
  return *operator T*();
}

}  // namespace WTF

using WTF::ThreadSpecific;

#endif  // SKY_ENGINE_WTF_THREADSPECIFIC_H_
