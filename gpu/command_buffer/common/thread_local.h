// Copyright (c) 2010 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Functions for allocating and accessing thread local values via key.

#ifndef GPU_COMMAND_BUFFER_COMMON_THREAD_LOCAL_H_
#define GPU_COMMAND_BUFFER_COMMON_THREAD_LOCAL_H_

#if defined(_WIN32)
#include <windows.h>
#else
#include <pthread.h>
#endif

namespace gpu {

#if defined(_WIN32)
typedef DWORD ThreadLocalKey;
#else
typedef pthread_key_t ThreadLocalKey;
#endif

inline ThreadLocalKey ThreadLocalAlloc() {
#if defined(_WIN32)
  return TlsAlloc();
#else
  ThreadLocalKey key;
  pthread_key_create(&key, NULL);
  return key;
#endif
}

inline void ThreadLocalFree(ThreadLocalKey key) {
#if defined(_WIN32)
  TlsFree(key);
#else
  pthread_key_delete(key);
#endif
}

inline void ThreadLocalSetValue(ThreadLocalKey key, void* value) {
#if defined(_WIN32)
  TlsSetValue(key, value);
#else
  pthread_setspecific(key, value);
#endif
}

inline void* ThreadLocalGetValue(ThreadLocalKey key) {
#if defined(_WIN32)
  return TlsGetValue(key);
#else
  return pthread_getspecific(key);
#endif
}
}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_COMMON_THREAD_LOCAL_H_
