// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/logging.h"
#include "base/threading/simple_thread.h"
#include "base/threading/thread_local.h"
#include "base/synchronization/waitable_event.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {

namespace {

class ThreadLocalTesterBase : public base::DelegateSimpleThreadPool::Delegate {
 public:
  typedef base::ThreadLocalPointer<char> TLPType;

  ThreadLocalTesterBase(TLPType* tlp, base::WaitableEvent* done)
      : tlp_(tlp),
        done_(done) {
  }
  ~ThreadLocalTesterBase() override {}

 protected:
  TLPType* tlp_;
  base::WaitableEvent* done_;
};

class SetThreadLocal : public ThreadLocalTesterBase {
 public:
  SetThreadLocal(TLPType* tlp, base::WaitableEvent* done)
      : ThreadLocalTesterBase(tlp, done),
        val_(NULL) {
  }
  ~SetThreadLocal() override {}

  void set_value(char* val) { val_ = val; }

  void Run() override {
    DCHECK(!done_->IsSignaled());
    tlp_->Set(val_);
    done_->Signal();
  }

 private:
  char* val_;
};

class GetThreadLocal : public ThreadLocalTesterBase {
 public:
  GetThreadLocal(TLPType* tlp, base::WaitableEvent* done)
      : ThreadLocalTesterBase(tlp, done),
        ptr_(NULL) {
  }
  ~GetThreadLocal() override {}

  void set_ptr(char** ptr) { ptr_ = ptr; }

  void Run() override {
    DCHECK(!done_->IsSignaled());
    *ptr_ = tlp_->Get();
    done_->Signal();
  }

 private:
  char** ptr_;
};

}  // namespace

// In this test, we start 2 threads which will access a ThreadLocalPointer.  We
// make sure the default is NULL, and the pointers are unique to the threads.
TEST(ThreadLocalTest, Pointer) {
  base::DelegateSimpleThreadPool tp1("ThreadLocalTest tp1", 1);
  base::DelegateSimpleThreadPool tp2("ThreadLocalTest tp1", 1);
  tp1.Start();
  tp2.Start();

  base::ThreadLocalPointer<char> tlp;

  static char* const kBogusPointer = reinterpret_cast<char*>(0x1234);

  char* tls_val;
  base::WaitableEvent done(true, false);

  GetThreadLocal getter(&tlp, &done);
  getter.set_ptr(&tls_val);

  // Check that both threads defaulted to NULL.
  tls_val = kBogusPointer;
  done.Reset();
  tp1.AddWork(&getter);
  done.Wait();
  EXPECT_EQ(static_cast<char*>(NULL), tls_val);

  tls_val = kBogusPointer;
  done.Reset();
  tp2.AddWork(&getter);
  done.Wait();
  EXPECT_EQ(static_cast<char*>(NULL), tls_val);


  SetThreadLocal setter(&tlp, &done);
  setter.set_value(kBogusPointer);

  // Have thread 1 set their pointer value to kBogusPointer.
  done.Reset();
  tp1.AddWork(&setter);
  done.Wait();

  tls_val = NULL;
  done.Reset();
  tp1.AddWork(&getter);
  done.Wait();
  EXPECT_EQ(kBogusPointer, tls_val);

  // Make sure thread 2 is still NULL
  tls_val = kBogusPointer;
  done.Reset();
  tp2.AddWork(&getter);
  done.Wait();
  EXPECT_EQ(static_cast<char*>(NULL), tls_val);

  // Set thread 2 to kBogusPointer + 1.
  setter.set_value(kBogusPointer + 1);

  done.Reset();
  tp2.AddWork(&setter);
  done.Wait();

  tls_val = NULL;
  done.Reset();
  tp2.AddWork(&getter);
  done.Wait();
  EXPECT_EQ(kBogusPointer + 1, tls_val);

  // Make sure thread 1 is still kBogusPointer.
  tls_val = NULL;
  done.Reset();
  tp1.AddWork(&getter);
  done.Wait();
  EXPECT_EQ(kBogusPointer, tls_val);

  tp1.JoinAll();
  tp2.JoinAll();
}

TEST(ThreadLocalTest, Boolean) {
  {
    base::ThreadLocalBoolean tlb;
    EXPECT_FALSE(tlb.Get());

    tlb.Set(false);
    EXPECT_FALSE(tlb.Get());

    tlb.Set(true);
    EXPECT_TRUE(tlb.Get());
  }

  // Our slot should have been freed, we're all reset.
  {
    base::ThreadLocalBoolean tlb;
    EXPECT_FALSE(tlb.Get());
  }
}

}  // namespace base
