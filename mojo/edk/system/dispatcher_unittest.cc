// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/dispatcher.h"

#include <memory>
#include <vector>

#include "base/logging.h"
#include "mojo/edk/embedder/platform_shared_buffer.h"
#include "mojo/edk/system/memory.h"
#include "mojo/edk/system/test/simple_test_thread.h"
#include "mojo/edk/system/waiter.h"
#include "mojo/edk/util/make_unique.h"
#include "mojo/edk/util/ref_ptr.h"
#include "mojo/edk/util/waitable_event.h"
#include "mojo/public/cpp/system/macros.h"
#include "testing/gtest/include/gtest/gtest.h"

using mojo::util::MakeRefCounted;
using mojo::util::MakeUnique;
using mojo::util::ManualResetWaitableEvent;
using mojo::util::RefPtr;

namespace mojo {
namespace system {
namespace {

// Trivial subclass that makes the constructor public.
class TrivialDispatcher final : public Dispatcher {
 public:
  // Note: Use |MakeRefCounted<TrivialDispatcher>()|.

  Type GetType() const override { return Type::UNKNOWN; }

 private:
  FRIEND_MAKE_REF_COUNTED(TrivialDispatcher);

  TrivialDispatcher() {}
  ~TrivialDispatcher() override {}

  RefPtr<Dispatcher> CreateEquivalentDispatcherAndCloseImplNoLock() override {
    mutex().AssertHeld();
    return AdoptRef(new TrivialDispatcher());
  }

  MOJO_DISALLOW_COPY_AND_ASSIGN(TrivialDispatcher);
};

TEST(DispatcherTest, Basic) {
  auto d = MakeRefCounted<TrivialDispatcher>();

  EXPECT_EQ(Dispatcher::Type::UNKNOWN, d->GetType());

  EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT,
            d->WriteMessage(NullUserPointer(), 0, nullptr,
                            MOJO_WRITE_MESSAGE_FLAG_NONE));
  EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT,
            d->ReadMessage(NullUserPointer(), NullUserPointer(), nullptr,
                           nullptr, MOJO_WRITE_MESSAGE_FLAG_NONE));
  EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT,
            d->WriteData(NullUserPointer(), NullUserPointer(),
                         MOJO_WRITE_DATA_FLAG_NONE));
  EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT,
            d->BeginWriteData(NullUserPointer(), NullUserPointer(),
                              MOJO_WRITE_DATA_FLAG_NONE));
  EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT, d->EndWriteData(0));
  EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT,
            d->ReadData(NullUserPointer(), NullUserPointer(),
                        MOJO_READ_DATA_FLAG_NONE));
  EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT,
            d->BeginReadData(NullUserPointer(), NullUserPointer(),
                             MOJO_READ_DATA_FLAG_NONE));
  EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT, d->EndReadData(0));
  Waiter w;
  w.Init();
  HandleSignalsState hss;
  EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION,
            d->AddAwakable(&w, ~MOJO_HANDLE_SIGNAL_NONE, 0, &hss));
  EXPECT_EQ(0u, hss.satisfied_signals);
  EXPECT_EQ(0u, hss.satisfiable_signals);
  // Okay to remove even if it wasn't added (or was already removed).
  hss = HandleSignalsState();
  d->RemoveAwakable(&w, &hss);
  EXPECT_EQ(0u, hss.satisfied_signals);
  EXPECT_EQ(0u, hss.satisfiable_signals);
  hss = HandleSignalsState();
  d->RemoveAwakable(&w, &hss);
  EXPECT_EQ(0u, hss.satisfied_signals);
  EXPECT_EQ(0u, hss.satisfiable_signals);

  EXPECT_EQ(MOJO_RESULT_OK, d->Close());

  EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT,
            d->WriteMessage(NullUserPointer(), 0, nullptr,
                            MOJO_WRITE_MESSAGE_FLAG_NONE));
  EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT,
            d->ReadMessage(NullUserPointer(), NullUserPointer(), nullptr,
                           nullptr, MOJO_WRITE_MESSAGE_FLAG_NONE));
  EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT,
            d->WriteData(NullUserPointer(), NullUserPointer(),
                         MOJO_WRITE_DATA_FLAG_NONE));
  EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT,
            d->BeginWriteData(NullUserPointer(), NullUserPointer(),
                              MOJO_WRITE_DATA_FLAG_NONE));
  EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT, d->EndWriteData(0));
  EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT,
            d->ReadData(NullUserPointer(), NullUserPointer(),
                        MOJO_READ_DATA_FLAG_NONE));
  EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT,
            d->BeginReadData(NullUserPointer(), NullUserPointer(),
                             MOJO_READ_DATA_FLAG_NONE));
  EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT, d->EndReadData(0));
  hss = HandleSignalsState();
  EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT,
            d->AddAwakable(&w, ~MOJO_HANDLE_SIGNAL_NONE, 0, &hss));
  EXPECT_EQ(0u, hss.satisfied_signals);
  EXPECT_EQ(0u, hss.satisfiable_signals);
  hss = HandleSignalsState();
  d->RemoveAwakable(&w, &hss);
  EXPECT_EQ(0u, hss.satisfied_signals);
  EXPECT_EQ(0u, hss.satisfiable_signals);
}

class ThreadSafetyStressThread : public test::SimpleTestThread {
 public:
  enum DispatcherOp {
    CLOSE = 0,
    WRITE_MESSAGE,
    READ_MESSAGE,
    WRITE_DATA,
    BEGIN_WRITE_DATA,
    END_WRITE_DATA,
    READ_DATA,
    BEGIN_READ_DATA,
    END_READ_DATA,
    DUPLICATE_BUFFER_HANDLE,
    MAP_BUFFER,
    ADD_WAITER,
    REMOVE_WAITER,
    DISPATCHER_OP_COUNT
  };

  ThreadSafetyStressThread(ManualResetWaitableEvent* event,
                           RefPtr<Dispatcher> dispatcher,
                           DispatcherOp op)
      : event_(event), dispatcher_(dispatcher), op_(op) {
    CHECK_LE(0, op_);
    CHECK_LT(op_, DISPATCHER_OP_COUNT);
  }

  ~ThreadSafetyStressThread() override { Join(); }

 private:
  void Run() override {
    event_->Wait();

    waiter_.Init();
    switch (op_) {
      case CLOSE: {
        MojoResult r = dispatcher_->Close();
        EXPECT_TRUE(r == MOJO_RESULT_OK || r == MOJO_RESULT_INVALID_ARGUMENT)
            << "Result: " << r;
        break;
      }
      case WRITE_MESSAGE:
        EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT,
                  dispatcher_->WriteMessage(NullUserPointer(), 0, nullptr,
                                            MOJO_WRITE_MESSAGE_FLAG_NONE));
        break;
      case READ_MESSAGE:
        EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT,
                  dispatcher_->ReadMessage(NullUserPointer(), NullUserPointer(),
                                           nullptr, nullptr,
                                           MOJO_WRITE_MESSAGE_FLAG_NONE));
        break;
      case WRITE_DATA:
        EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT,
                  dispatcher_->WriteData(NullUserPointer(), NullUserPointer(),
                                         MOJO_WRITE_DATA_FLAG_NONE));
        break;
      case BEGIN_WRITE_DATA:
        EXPECT_EQ(
            MOJO_RESULT_INVALID_ARGUMENT,
            dispatcher_->BeginWriteData(NullUserPointer(), NullUserPointer(),
                                        MOJO_WRITE_DATA_FLAG_NONE));
        break;
      case END_WRITE_DATA:
        EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT, dispatcher_->EndWriteData(0));
        break;
      case READ_DATA:
        EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT,
                  dispatcher_->ReadData(NullUserPointer(), NullUserPointer(),
                                        MOJO_READ_DATA_FLAG_NONE));
        break;
      case BEGIN_READ_DATA:
        EXPECT_EQ(
            MOJO_RESULT_INVALID_ARGUMENT,
            dispatcher_->BeginReadData(NullUserPointer(), NullUserPointer(),
                                       MOJO_READ_DATA_FLAG_NONE));
        break;
      case END_READ_DATA:
        EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT, dispatcher_->EndReadData(0));
        break;
      case DUPLICATE_BUFFER_HANDLE: {
        RefPtr<Dispatcher> unused;
        EXPECT_EQ(
            MOJO_RESULT_INVALID_ARGUMENT,
            dispatcher_->DuplicateBufferHandle(NullUserPointer(), &unused));
        break;
      }
      case MAP_BUFFER: {
        std::unique_ptr<embedder::PlatformSharedBufferMapping> unused;
        EXPECT_EQ(
            MOJO_RESULT_INVALID_ARGUMENT,
            dispatcher_->MapBuffer(0u, 0u, MOJO_MAP_BUFFER_FLAG_NONE, &unused));
        break;
      }
      case ADD_WAITER: {
        HandleSignalsState hss;
        MojoResult r = dispatcher_->AddAwakable(
            &waiter_, ~MOJO_HANDLE_SIGNAL_NONE, 0, &hss);
        EXPECT_TRUE(r == MOJO_RESULT_FAILED_PRECONDITION ||
                    r == MOJO_RESULT_INVALID_ARGUMENT);
        EXPECT_EQ(0u, hss.satisfied_signals);
        EXPECT_EQ(0u, hss.satisfiable_signals);
        break;
      }
      case REMOVE_WAITER: {
        HandleSignalsState hss;
        dispatcher_->RemoveAwakable(&waiter_, &hss);
        EXPECT_EQ(0u, hss.satisfied_signals);
        EXPECT_EQ(0u, hss.satisfiable_signals);
        break;
      }
      default:
        NOTREACHED();
        break;
    }

    // Always try to remove the waiter, in case we added it.
    HandleSignalsState hss;
    dispatcher_->RemoveAwakable(&waiter_, &hss);
    EXPECT_EQ(0u, hss.satisfied_signals);
    EXPECT_EQ(0u, hss.satisfiable_signals);
  }

  ManualResetWaitableEvent* const event_;
  const RefPtr<Dispatcher> dispatcher_;
  const DispatcherOp op_;

  Waiter waiter_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(ThreadSafetyStressThread);
};

TEST(DispatcherTest, ThreadSafetyStress) {
  static const size_t kRepeatCount = 20;
  static const size_t kNumThreads = 100;

  for (size_t i = 0; i < kRepeatCount; i++) {
    // Manual reset, not initially signaled.
    ManualResetWaitableEvent event;
    auto d = MakeRefCounted<TrivialDispatcher>();

    {
      std::vector<std::unique_ptr<ThreadSafetyStressThread>> threads;
      for (size_t j = 0; j < kNumThreads; j++) {
        ThreadSafetyStressThread::DispatcherOp op =
            static_cast<ThreadSafetyStressThread::DispatcherOp>(
                (i + j) % ThreadSafetyStressThread::DISPATCHER_OP_COUNT);
        threads.push_back(MakeUnique<ThreadSafetyStressThread>(&event, d, op));
        threads.back()->Start();
      }
      // Kicks off real work on the threads:
      event.Signal();
    }  // Joins all the threads.

    // One of the threads should already have closed the dispatcher.
    EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT, d->Close());
  }
}

TEST(DispatcherTest, ThreadSafetyStressNoClose) {
  static const size_t kRepeatCount = 20;
  static const size_t kNumThreads = 100;

  for (size_t i = 0; i < kRepeatCount; i++) {
    // Manual reset, not initially signaled.
    ManualResetWaitableEvent event;
    auto d = MakeRefCounted<TrivialDispatcher>();

    {
      std::vector<std::unique_ptr<ThreadSafetyStressThread>> threads;
      for (size_t j = 0; j < kNumThreads; j++) {
        ThreadSafetyStressThread::DispatcherOp op =
            static_cast<ThreadSafetyStressThread::DispatcherOp>(
                (i + j) % (ThreadSafetyStressThread::DISPATCHER_OP_COUNT - 1) +
                1);
        threads.push_back(MakeUnique<ThreadSafetyStressThread>(&event, d, op));
        threads.back()->Start();
      }
      // Kicks off real work on the threads:
      event.Signal();
    }  // Joins all the threads.

    EXPECT_EQ(MOJO_RESULT_OK, d->Close());
  }
}

}  // namespace
}  // namespace system
}  // namespace mojo
