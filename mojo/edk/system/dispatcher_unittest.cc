// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/dispatcher.h"

#include <memory>
#include <thread>
#include <vector>

#include "base/logging.h"
#include "mojo/edk/platform/platform_shared_buffer.h"
#include "mojo/edk/system/memory.h"
#include "mojo/edk/system/waiter.h"
#include "mojo/edk/util/make_unique.h"
#include "mojo/edk/util/ref_ptr.h"
#include "mojo/edk/util/waitable_event.h"
#include "mojo/public/cpp/system/macros.h"
#include "testing/gtest/include/gtest/gtest.h"

using mojo::platform::PlatformSharedBufferMapping;
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

enum class DispatcherOp {
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
  COUNT
};

void ThreadSafetyStressHelper(ManualResetWaitableEvent* event,
                              RefPtr<Dispatcher>&& dispatcher,
                              DispatcherOp op) {
  CHECK_LE(0, static_cast<int>(op));
  CHECK_LT(static_cast<int>(op), static_cast<int>(DispatcherOp::COUNT));

  event->Wait();

  Waiter waiter;
  waiter.Init();
  switch (op) {
    case DispatcherOp::CLOSE: {
      MojoResult r = dispatcher->Close();
      EXPECT_TRUE(r == MOJO_RESULT_OK || r == MOJO_RESULT_INVALID_ARGUMENT)
          << "Result: " << r;
      break;
    }
    case DispatcherOp::WRITE_MESSAGE:
      EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT,
                dispatcher->WriteMessage(NullUserPointer(), 0, nullptr,
                                         MOJO_WRITE_MESSAGE_FLAG_NONE));
      break;
    case DispatcherOp::READ_MESSAGE:
      EXPECT_EQ(
          MOJO_RESULT_INVALID_ARGUMENT,
          dispatcher->ReadMessage(NullUserPointer(), NullUserPointer(), nullptr,
                                  nullptr, MOJO_WRITE_MESSAGE_FLAG_NONE));
      break;
    case DispatcherOp::WRITE_DATA:
      EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT,
                dispatcher->WriteData(NullUserPointer(), NullUserPointer(),
                                      MOJO_WRITE_DATA_FLAG_NONE));
      break;
    case DispatcherOp::BEGIN_WRITE_DATA:
      EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT,
                dispatcher->BeginWriteData(NullUserPointer(), NullUserPointer(),
                                           MOJO_WRITE_DATA_FLAG_NONE));
      break;
    case DispatcherOp::END_WRITE_DATA:
      EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT, dispatcher->EndWriteData(0));
      break;
    case DispatcherOp::READ_DATA:
      EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT,
                dispatcher->ReadData(NullUserPointer(), NullUserPointer(),
                                     MOJO_READ_DATA_FLAG_NONE));
      break;
    case DispatcherOp::BEGIN_READ_DATA:
      EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT,
                dispatcher->BeginReadData(NullUserPointer(), NullUserPointer(),
                                          MOJO_READ_DATA_FLAG_NONE));
      break;
    case DispatcherOp::END_READ_DATA:
      EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT, dispatcher->EndReadData(0));
      break;
    case DispatcherOp::DUPLICATE_BUFFER_HANDLE: {
      RefPtr<Dispatcher> unused;
      EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT,
                dispatcher->DuplicateBufferHandle(NullUserPointer(), &unused));
      break;
    }
    case DispatcherOp::MAP_BUFFER: {
      std::unique_ptr<PlatformSharedBufferMapping> unused;
      EXPECT_EQ(
          MOJO_RESULT_INVALID_ARGUMENT,
          dispatcher->MapBuffer(0u, 0u, MOJO_MAP_BUFFER_FLAG_NONE, &unused));
      break;
    }
    case DispatcherOp::ADD_WAITER: {
      HandleSignalsState hss;
      MojoResult r =
          dispatcher->AddAwakable(&waiter, ~MOJO_HANDLE_SIGNAL_NONE, 0, &hss);
      EXPECT_TRUE(r == MOJO_RESULT_FAILED_PRECONDITION ||
                  r == MOJO_RESULT_INVALID_ARGUMENT);
      EXPECT_EQ(0u, hss.satisfied_signals);
      EXPECT_EQ(0u, hss.satisfiable_signals);
      break;
    }
    case DispatcherOp::REMOVE_WAITER: {
      HandleSignalsState hss;
      dispatcher->RemoveAwakable(&waiter, &hss);
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
  dispatcher->RemoveAwakable(&waiter, &hss);
  EXPECT_EQ(0u, hss.satisfied_signals);
  EXPECT_EQ(0u, hss.satisfiable_signals);
}

TEST(DispatcherTest, ThreadSafetyStress) {
  static const size_t kRepeatCount = 20;
  static const size_t kNumThreads = 100;

  for (size_t i = 0; i < kRepeatCount; i++) {
    // Manual reset, not initially signaled.
    ManualResetWaitableEvent event;
    auto d = MakeRefCounted<TrivialDispatcher>();

    std::vector<std::thread> threads;
    for (size_t j = 0; j < kNumThreads; j++) {
      DispatcherOp op = static_cast<DispatcherOp>(
          (i + j) % static_cast<size_t>(DispatcherOp::COUNT));
      threads.push_back(
          std::thread(&ThreadSafetyStressHelper, &event, d.Clone(), op));
    }
    // Kicks off real work on the threads:
    event.Signal();
    for (auto& thread : threads)
      thread.join();

    // One of the threads should already have closed the dispatcher.
    EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT, d->Close());
  }
}

TEST(DispatcherTest, ThreadSafetyStressNoClose) {
  static const size_t kRepeatCount = 20;
  static const size_t kNumThreads = 100;

  // We rely on "close" being the first |DispatcherOp|.
  static_assert(static_cast<int>(DispatcherOp::CLOSE) == 0,
                "DispatcherOp::CLOSE isn't 0!");

  for (size_t i = 0; i < kRepeatCount; i++) {
    // Manual reset, not initially signaled.
    ManualResetWaitableEvent event;
    auto d = MakeRefCounted<TrivialDispatcher>();

    std::vector<std::thread> threads;
    for (size_t j = 0; j < kNumThreads; j++) {
      DispatcherOp op = static_cast<DispatcherOp>(
          (i + j) % (static_cast<size_t>(DispatcherOp::COUNT) - 1) + 1);
      threads.push_back(
          std::thread(&ThreadSafetyStressHelper, &event, d.Clone(), op));
    }
    // Kicks off real work on the threads:
    event.Signal();
    for (auto& thread : threads)
      thread.join();

    EXPECT_EQ(MOJO_RESULT_OK, d->Close());
  }
}

}  // namespace
}  // namespace system
}  // namespace mojo
