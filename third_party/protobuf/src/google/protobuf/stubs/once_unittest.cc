// Protocol Buffers - Google's data interchange format
// Copyright 2008 Google Inc.  All rights reserved.
// http://code.google.com/p/protobuf/
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//     * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//     * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// Author: kenton@google.com (Kenton Varda)

#ifdef _WIN32
#include <windows.h>
#else
#include <unistd.h>
#include <pthread.h>
#endif

#include <google/protobuf/stubs/once.h>
#include <google/protobuf/testing/googletest.h>
#include <gtest/gtest.h>

namespace google {
namespace protobuf {
namespace {

class OnceInitTest : public testing::Test {
 protected:
  void SetUp() {
    state_ = INIT_NOT_STARTED;
    current_test_ = this;
  }

  // Since ProtobufOnceType is only allowed to be allocated in static storage,
  // each test must use a different pair of ProtobufOnceType objects which it
  // must declare itself.
  void SetOnces(ProtobufOnceType* once, ProtobufOnceType* recursive_once) {
    once_ = once;
    recursive_once_ = recursive_once;
  }

  void InitOnce() {
    GoogleOnceInit(once_, &InitStatic);
  }
  void InitRecursiveOnce() {
    GoogleOnceInit(recursive_once_, &InitRecursiveStatic);
  }

  void BlockInit() { init_blocker_.Lock(); }
  void UnblockInit() { init_blocker_.Unlock(); }

  class TestThread {
   public:
    TestThread(Closure* callback)
        : done_(false), joined_(false), callback_(callback) {
#ifdef _WIN32
      thread_ = CreateThread(NULL, 0, &Start, this, 0, NULL);
#else
      pthread_create(&thread_, NULL, &Start, this);
#endif
    }
    ~TestThread() {
      if (!joined_) Join();
    }

    bool IsDone() {
      MutexLock lock(&done_mutex_);
      return done_;
    }
    void Join() {
      joined_ = true;
#ifdef _WIN32
      WaitForSingleObject(thread_, INFINITE);
      CloseHandle(thread_);
#else
      pthread_join(thread_, NULL);
#endif
    }

   private:
#ifdef _WIN32
    HANDLE thread_;
#else
    pthread_t thread_;
#endif

    Mutex done_mutex_;
    bool done_;
    bool joined_;
    Closure* callback_;

#ifdef _WIN32
    static DWORD WINAPI Start(LPVOID arg) {
#else
    static void* Start(void* arg) {
#endif
      reinterpret_cast<TestThread*>(arg)->Run();
      return 0;
    }

    void Run() {
      callback_->Run();
      MutexLock lock(&done_mutex_);
      done_ = true;
    }
  };

  TestThread* RunInitOnceInNewThread() {
    return new TestThread(NewCallback(this, &OnceInitTest::InitOnce));
  }
  TestThread* RunInitRecursiveOnceInNewThread() {
    return new TestThread(NewCallback(this, &OnceInitTest::InitRecursiveOnce));
  }

  enum State {
    INIT_NOT_STARTED,
    INIT_STARTED,
    INIT_DONE
  };
  State CurrentState() {
    MutexLock lock(&mutex_);
    return state_;
  }

  void WaitABit() {
#ifdef _WIN32
    Sleep(1000);
#else
    sleep(1);
#endif
  }

 private:
  Mutex mutex_;
  Mutex init_blocker_;
  State state_;
  ProtobufOnceType* once_;
  ProtobufOnceType* recursive_once_;

  void Init() {
    MutexLock lock(&mutex_);
    EXPECT_EQ(INIT_NOT_STARTED, state_);
    state_ = INIT_STARTED;
    mutex_.Unlock();
    init_blocker_.Lock();
    init_blocker_.Unlock();
    mutex_.Lock();
    state_ = INIT_DONE;
  }

  static OnceInitTest* current_test_;
  static void InitStatic() { current_test_->Init(); }
  static void InitRecursiveStatic() { current_test_->InitOnce(); }
};

OnceInitTest* OnceInitTest::current_test_ = NULL;

GOOGLE_PROTOBUF_DECLARE_ONCE(simple_once);

TEST_F(OnceInitTest, Simple) {
  SetOnces(&simple_once, NULL);

  EXPECT_EQ(INIT_NOT_STARTED, CurrentState());
  InitOnce();
  EXPECT_EQ(INIT_DONE, CurrentState());

  // Calling again has no effect.
  InitOnce();
  EXPECT_EQ(INIT_DONE, CurrentState());
}

GOOGLE_PROTOBUF_DECLARE_ONCE(recursive_once1);
GOOGLE_PROTOBUF_DECLARE_ONCE(recursive_once2);

TEST_F(OnceInitTest, Recursive) {
  SetOnces(&recursive_once1, &recursive_once2);

  EXPECT_EQ(INIT_NOT_STARTED, CurrentState());
  InitRecursiveOnce();
  EXPECT_EQ(INIT_DONE, CurrentState());
}

GOOGLE_PROTOBUF_DECLARE_ONCE(multiple_threads_once);

TEST_F(OnceInitTest, MultipleThreads) {
  SetOnces(&multiple_threads_once, NULL);

  scoped_ptr<TestThread> threads[4];
  EXPECT_EQ(INIT_NOT_STARTED, CurrentState());
  for (int i = 0; i < 4; i++) {
    threads[i].reset(RunInitOnceInNewThread());
  }
  for (int i = 0; i < 4; i++) {
    threads[i]->Join();
  }
  EXPECT_EQ(INIT_DONE, CurrentState());
}

GOOGLE_PROTOBUF_DECLARE_ONCE(multiple_threads_blocked_once1);
GOOGLE_PROTOBUF_DECLARE_ONCE(multiple_threads_blocked_once2);

TEST_F(OnceInitTest, MultipleThreadsBlocked) {
  SetOnces(&multiple_threads_blocked_once1, &multiple_threads_blocked_once2);

  scoped_ptr<TestThread> threads[8];
  EXPECT_EQ(INIT_NOT_STARTED, CurrentState());

  BlockInit();
  for (int i = 0; i < 4; i++) {
    threads[i].reset(RunInitOnceInNewThread());
  }
  for (int i = 4; i < 8; i++) {
    threads[i].reset(RunInitRecursiveOnceInNewThread());
  }

  WaitABit();

  // We should now have one thread blocked inside Init(), four blocked waiting
  // for Init() to complete, and three blocked waiting for InitRecursive() to
  // complete.
  EXPECT_EQ(INIT_STARTED, CurrentState());
  UnblockInit();

  for (int i = 0; i < 8; i++) {
    threads[i]->Join();
  }
  EXPECT_EQ(INIT_DONE, CurrentState());
}

}  // anonymous namespace
}  // namespace protobuf
}  // namespace google
