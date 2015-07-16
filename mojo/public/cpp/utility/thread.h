// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_PUBLIC_CPP_UTILITY_THREAD_H_
#define MOJO_PUBLIC_CPP_UTILITY_THREAD_H_

#ifdef _WIN32
#error "Not implemented: See crbug.com/342893."
#endif

#include <pthread.h>
#include <stddef.h>

#include "mojo/public/cpp/system/macros.h"

namespace mojo {

// This class is thread-friendly, not thread-safe (e.g., you mustn't call
// |Join()| from multiple threads and/or simultaneously try to destroy the
// object).
class Thread {
 public:
  // TODO(vtl): Support non-joinable? priority?
  class Options {
   public:
    Options() : stack_size_(0) {}

    // A stack size of 0 means the default.
    size_t stack_size() const { return stack_size_; }
    void set_stack_size(size_t stack_size) { stack_size_ = stack_size; }

   private:
    size_t stack_size_;

    // Copy and assign allowed.
  };

  // TODO(vtl): Add name or name prefix?
  Thread();
  explicit Thread(const Options& options);
  virtual ~Thread();

  void Start();
  void Join();

  virtual void Run() = 0;

 private:
  static void* ThreadRunTrampoline(void* arg);

  const Options options_;
  pthread_t thread_;
  bool started_;
  bool joined_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(Thread);
};

}  // namespace mojo

#endif  // MOJO_PUBLIC_CPP_UTILITY_THREAD_H_
