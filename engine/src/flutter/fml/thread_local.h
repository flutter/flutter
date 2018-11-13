// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_THREAD_LOCAL_H_
#define FLUTTER_FML_THREAD_LOCAL_H_

#include <functional>

#include "flutter/fml/build_config.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/macros.h"

#define FML_THREAD_LOCAL_PTHREADS OS_MACOSX || OS_LINUX || OS_ANDROID

#if FML_THREAD_LOCAL_PTHREADS
#include <pthread.h>
#endif

namespace fml {

using ThreadLocalDestroyCallback = std::function<void(intptr_t)>;

#if FML_THREAD_LOCAL_PTHREADS

// thread_local is unavailable and we have to resort to pthreads.

#define FML_THREAD_LOCAL static

class ThreadLocal {
 private:
  class Box {
   public:
    Box(ThreadLocalDestroyCallback destroy, intptr_t value);

    ~Box();

    intptr_t Value() const { return value_; }

    void SetValue(intptr_t value) {
      if (value == value_) {
        return;
      }

      DestroyValue();
      value_ = value;
    }

    void DestroyValue() {
      if (destroy_) {
        destroy_(value_);
      }
    }

   private:
    ThreadLocalDestroyCallback destroy_;
    intptr_t value_;

    FML_DISALLOW_COPY_AND_ASSIGN(Box);
  };

  static inline void ThreadLocalDestroy(void* value) {
    FML_CHECK(value != nullptr);
    auto* box = reinterpret_cast<Box*>(value);
    box->DestroyValue();
    delete box;
  }

 public:
  ThreadLocal();

  ThreadLocal(ThreadLocalDestroyCallback destroy);

  void Set(intptr_t value) {
    auto* box = reinterpret_cast<Box*>(pthread_getspecific(_key));
    if (box == nullptr) {
      box = new Box(destroy_, value);
      FML_CHECK(pthread_setspecific(_key, box) == 0);
    } else {
      box->SetValue(value);
    }
  }

  intptr_t Get() {
    auto* box = reinterpret_cast<Box*>(pthread_getspecific(_key));
    return box != nullptr ? box->Value() : 0;
  }

  ~ThreadLocal();

 private:
  pthread_key_t _key;
  ThreadLocalDestroyCallback destroy_;

  FML_DISALLOW_COPY_AND_ASSIGN(ThreadLocal);
};

#else  // FML_THREAD_LOCAL_PTHREADS

#define FML_THREAD_LOCAL thread_local

class ThreadLocal {
 public:
  ThreadLocal() : ThreadLocal(nullptr) {}

  ThreadLocal(ThreadLocalDestroyCallback destroy)
      : destroy_(destroy), value_(0) {}

  void Set(intptr_t value) {
    if (value_ == value) {
      return;
    }

    if (value_ != 0 && destroy_) {
      destroy_(value_);
    }

    value_ = value;
  }

  intptr_t Get() { return value_; }

  ~ThreadLocal() {
    if (value_ != 0 && destroy_) {
      destroy_(value_);
    }
  }

 private:
  ThreadLocalDestroyCallback destroy_;
  intptr_t value_;

  FML_DISALLOW_COPY_AND_ASSIGN(ThreadLocal);
};

#endif  // FML_THREAD_LOCAL_PTHREADS

#ifndef FML_THREAD_LOCAL

#error Thread local storage unavailable on the platform.

#endif  // FML_THREAD_LOCAL

}  // namespace fml

#endif  // FLUTTER_FML_THREAD_LOCAL_H_
