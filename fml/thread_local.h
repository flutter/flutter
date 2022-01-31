// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_THREAD_LOCAL_H_
#define FLUTTER_FML_THREAD_LOCAL_H_

#include <memory>

#include "flutter/fml/build_config.h"
#include "flutter/fml/macros.h"

#define FML_THREAD_LOCAL_PTHREADS \
  FML_OS_MACOSX || FML_OS_LINUX || FML_OS_ANDROID

#if FML_THREAD_LOCAL_PTHREADS
#include <pthread.h>
#endif

namespace fml {

#if FML_THREAD_LOCAL_PTHREADS

#define FML_THREAD_LOCAL static

namespace internal {

class ThreadLocalPointer {
 public:
  explicit ThreadLocalPointer(void (*destroy)(void*));
  ~ThreadLocalPointer();

  void* get() const;
  void* swap(void* ptr);

 private:
  pthread_key_t key_;

  FML_DISALLOW_COPY_AND_ASSIGN(ThreadLocalPointer);
};

}  // namespace internal

template <typename T>
class ThreadLocalUniquePtr {
 public:
  ThreadLocalUniquePtr() : ptr_(destroy) {}

  T* get() const { return reinterpret_cast<T*>(ptr_.get()); }
  void reset(T* ptr) { destroy(ptr_.swap(ptr)); }

 private:
  static void destroy(void* ptr) { delete reinterpret_cast<T*>(ptr); }

  internal::ThreadLocalPointer ptr_;

  FML_DISALLOW_COPY_AND_ASSIGN(ThreadLocalUniquePtr);
};

#else  // FML_THREAD_LOCAL_PTHREADS

#define FML_THREAD_LOCAL static thread_local

template <typename T>
class ThreadLocalUniquePtr {
 public:
  ThreadLocalUniquePtr() = default;

  T* get() const { return ptr_.get(); }
  void reset(T* ptr) { ptr_.reset(ptr); }

 private:
  std::unique_ptr<T> ptr_;

  FML_DISALLOW_COPY_AND_ASSIGN(ThreadLocalUniquePtr);
};

#endif  // FML_THREAD_LOCAL_PTHREADS

#ifndef FML_THREAD_LOCAL

#error Thread local storage unavailable on the platform.

#endif  // FML_THREAD_LOCAL

}  // namespace fml

#endif  // FLUTTER_FML_THREAD_LOCAL_H_
