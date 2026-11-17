// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <algorithm>
#include <memory>
#include <mutex>
#include <set>
#include <thread>
#include <vector>
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/testing/testing.h"  // IWYU pragma: keep
#include "gmock/gmock.h"
#include "gtest/gtest.h"
#include "impeller/renderer/backend/gles/handle_gles.h"
#include "impeller/renderer/backend/gles/proc_table_gles.h"
#include "impeller/renderer/backend/gles/reactor_gles.h"
#include "impeller/renderer/backend/gles/test/mock_gles.h"

namespace impeller {
namespace testing {

using ::testing::_;
using ::testing::NiceMock;
using ::testing::Pointee;

class TestWorker : public ReactorGLES::Worker {
 public:
  bool CanReactorReactOnCurrentThreadNow(
      const ReactorGLES& reactor) const override {
    return true;
  }
};

// Reacts only on threads that were allowed to.
class AllowListWorker : public ReactorGLES::Worker {
 public:
  void AllowCurrentThread() {
    std::scoped_lock lock(mutex_);
    threads_.insert(std::this_thread::get_id());
  }

  bool CanReactorReactOnCurrentThreadNow(
      const ReactorGLES& reactor) const override {
    std::scoped_lock lock(mutex_);
    return threads_.count(std::this_thread::get_id()) > 0;
  }

 private:
  mutable std::mutex mutex_;
  std::set<std::thread::id> threads_;
};

TEST(ReactorGLES, CanAttachCleanupCallbacksToHandles) {
  auto mock_gles = MockGLES::Init();
  ProcTableGLES::Resolver resolver = kMockResolverGLES;
  auto proc_table = std::make_unique<ProcTableGLES>(resolver);
  auto worker = std::make_shared<TestWorker>();
  auto reactor = std::make_shared<ReactorGLES>(std::move(proc_table));
  reactor->AddWorker(worker);

  int value = 0;
  auto handle = reactor->CreateHandle(HandleType::kTexture, 1123);
  auto added =
      reactor->RegisterCleanupCallback(handle, [&value]() { value++; });

  EXPECT_TRUE(added);
  EXPECT_TRUE(reactor->React());

  reactor->CollectHandle(handle);
  EXPECT_TRUE(reactor->AddOperation([](const ReactorGLES& reactor) {}));
  EXPECT_TRUE(reactor->React());
  EXPECT_EQ(value, 1);
}

TEST(ReactorGLES, DeletesHandlesDuringShutdown) {
  auto mock_gles_impl = std::make_unique<MockGLESImpl>();

  EXPECT_CALL(*mock_gles_impl, GenTextures(1, _))
      .WillOnce([](GLsizei size, GLuint* queries) { queries[0] = 1234; });
  EXPECT_CALL(*mock_gles_impl, DeleteTextures(1, ::testing::Pointee(1234)))
      .Times(1);

  std::shared_ptr<MockGLES> mock_gles =
      MockGLES::Init(std::move(mock_gles_impl));
  ProcTableGLES::Resolver resolver = kMockResolverGLES;
  auto proc_table = std::make_unique<ProcTableGLES>(resolver);
  auto worker = std::make_shared<TestWorker>();
  auto reactor = std::make_shared<ReactorGLES>(std::move(proc_table));
  reactor->AddWorker(worker);
  reactor->CreateHandle(HandleType::kTexture);
  reactor.reset();
}

TEST(ReactorGLES, UntrackedHandle) {
  auto mock_gles_impl = std::make_unique<MockGLESImpl>();

  EXPECT_CALL(*mock_gles_impl, GenTextures(1, _))
      .WillOnce([](GLsizei size, GLuint* queries) { queries[0] = 1234; });
  EXPECT_CALL(*mock_gles_impl, DeleteTextures(1, ::testing::Pointee(1234)))
      .Times(1);

  std::shared_ptr<MockGLES> mock_gles =
      MockGLES::Init(std::move(mock_gles_impl));
  ProcTableGLES::Resolver resolver = kMockResolverGLES;
  auto proc_table = std::make_unique<ProcTableGLES>(resolver);
  auto worker = std::make_shared<TestWorker>();
  auto reactor = std::make_shared<ReactorGLES>(std::move(proc_table));
  reactor->AddWorker(worker);

  HandleGLES handle = reactor->CreateUntrackedHandle(HandleType::kTexture);
  EXPECT_FALSE(handle.IsDead());
  std::optional<GLuint> glint = reactor->GetGLHandle(handle);
  EXPECT_TRUE(glint.has_value());
  if (glint.has_value()) {
    EXPECT_EQ(1234u, *glint);
  }
  reactor->CollectHandle(handle);
  EXPECT_TRUE(reactor->AddOperation([&](const ReactorGLES&) {}));
  EXPECT_TRUE(reactor->React());
}

TEST(ReactorGLES, NameUntrackedHandle) {
  auto mock_gles_impl = std::make_unique<NiceMock<MockGLESImpl>>();
  NiceMock<MockGLESImpl>* raw_mock_gles = mock_gles_impl.get();

  std::shared_ptr<MockGLES> mock_gles =
      MockGLES::Init(std::move(mock_gles_impl));
  ProcTableGLES::Resolver resolver = kMockResolverGLES;
  auto proc_table = std::make_unique<ProcTableGLES>(resolver);

  if (!proc_table->SupportsDebugLabels()) {
    GTEST_SKIP() << "This device doesn't support labelling.";
  }

  EXPECT_CALL(*raw_mock_gles, GenTextures(1, _))
      .WillOnce([](GLsizei size, GLuint* queries) { queries[0] = 1234; });
  EXPECT_CALL(*raw_mock_gles,
              ObjectLabelKHR(_, 1234, _, ::testing::StrEq("hello, joe!")))
      .Times(1);
  ON_CALL(*raw_mock_gles, IsTexture).WillByDefault(::testing::Return(GL_TRUE));

  auto worker = std::make_shared<TestWorker>();
  auto reactor = std::make_shared<ReactorGLES>(std::move(proc_table));
  reactor->AddWorker(worker);

  HandleGLES handle = reactor->CreateUntrackedHandle(HandleType::kTexture);
  reactor->SetDebugLabel(handle, "hello, joe!");
}

TEST(ReactorGLES, PerThreadOperationQueues) {
  auto mock_gles = MockGLES::Init();
  ProcTableGLES::Resolver resolver = kMockResolverGLES;
  auto proc_table = std::make_unique<ProcTableGLES>(resolver);
  auto worker = std::make_shared<TestWorker>();
  auto reactor = std::make_shared<ReactorGLES>(std::move(proc_table));
  reactor->AddWorker(worker);

  bool op1_called = false;
  EXPECT_TRUE(
      reactor->AddOperation([&](const ReactorGLES&) { op1_called = true; }));

  fml::AutoResetWaitableEvent event;
  bool op2_called = false;
  std::thread thread([&] {
    EXPECT_TRUE(reactor->AddOperation(
        [&](const ReactorGLES&) { op2_called = true; }, true));
    event.Wait();
    EXPECT_TRUE(reactor->React());
  });

  // Reacting on the main thread should only run the main thread's operation.
  EXPECT_TRUE(reactor->React());
  EXPECT_TRUE(op1_called);
  EXPECT_FALSE(op2_called);

  // Reacting on the second thread will run the second thread's operation.
  event.Signal();
  thread.join();
  EXPECT_TRUE(op2_called);
}

TEST(ReactorGLES, CanDeferOperations) {
  auto mock_gles = MockGLES::Init();
  ProcTableGLES::Resolver resolver = kMockResolverGLES;
  auto proc_table = std::make_unique<ProcTableGLES>(resolver);
  auto worker = std::make_shared<TestWorker>();
  auto reactor = std::make_shared<ReactorGLES>(std::move(proc_table));
  reactor->AddWorker(worker);

  // Add operation executes tasks as long as the reactor can run tasks on
  // the current thread.
  bool did_run = false;
  EXPECT_TRUE(
      reactor->AddOperation([&](const ReactorGLES&) { did_run = true; }));
  EXPECT_TRUE(did_run);

  //...unless defer=true is specified, which only enqueues in the reactor.
  did_run = false;
  EXPECT_TRUE(reactor->AddOperation([&](const ReactorGLES&) { did_run = true; },
                                    /*defer=*/true));
  EXPECT_FALSE(did_run);
  EXPECT_TRUE(reactor->React());
  EXPECT_TRUE(did_run);
}

TEST(ReactorGLES, FramebufferDeletedOnOwnerThread) {
  auto mock_gles_impl = std::make_unique<MockGLESImpl>();

  EXPECT_CALL(*mock_gles_impl, GenFramebuffers(1, _))
      .WillOnce([](GLsizei size, GLuint* queries) { queries[0] = 1234; });

  std::shared_ptr<MockGLES> mock_gles =
      MockGLES::Init(std::move(mock_gles_impl));
  ProcTableGLES::Resolver resolver = kMockResolverGLES;
  auto proc_table = std::make_unique<ProcTableGLES>(resolver);
  auto worker = std::make_shared<TestWorker>();
  auto reactor = std::make_shared<ReactorGLES>(std::move(proc_table));
  reactor->AddWorker(worker);

  HandleGLES handle = reactor->CreateHandle(HandleType::kFrameBuffer);

  std::thread::id cleanup_thread;
  reactor->RegisterCleanupCallback(
      handle, [&]() { cleanup_thread = std::this_thread::get_id(); });

  reactor->CollectHandle(handle);

  std::thread thread([&] {
    EXPECT_TRUE(reactor->AddOperation([](const ReactorGLES& reactor) {}));
    EXPECT_TRUE(reactor->React());
  });
  thread.join();

  EXPECT_EQ(cleanup_thread, std::thread::id());

  EXPECT_TRUE(reactor->AddOperation([](const ReactorGLES& reactor) {}));
  EXPECT_TRUE(reactor->React());
  EXPECT_EQ(cleanup_thread, std::this_thread::get_id());
}

// A texture collected by a thread that can react is deleted by that thread's
// next reaction, never by another thread that reacts first.
TEST(ReactorGLES, SharedHandleDeletedOnCollectingThread) {
  auto mock_gles_impl = std::make_unique<MockGLESImpl>();

  std::thread::id deleting_thread;
  EXPECT_CALL(*mock_gles_impl, GenTextures(1, _))
      .WillOnce([](GLsizei size, GLuint* textures) { textures[0] = 1234; });
  EXPECT_CALL(*mock_gles_impl, DeleteTextures(1, Pointee(1234)))
      .WillOnce([&](GLsizei size, const GLuint* textures) {
        deleting_thread = std::this_thread::get_id();
      });

  std::shared_ptr<MockGLES> mock_gles =
      MockGLES::Init(std::move(mock_gles_impl));
  ProcTableGLES::Resolver resolver = kMockResolverGLES;
  auto proc_table = std::make_unique<ProcTableGLES>(resolver);
  auto worker = std::make_shared<TestWorker>();
  auto reactor = std::make_shared<ReactorGLES>(std::move(proc_table));
  reactor->AddWorker(worker);

  HandleGLES handle = reactor->CreateHandle(HandleType::kTexture);

  // This thread can react, so its context may still have unflushed commands
  // that use the texture. Another thread's reaction must not delete it.
  reactor->CollectHandle(handle);

  std::thread thread([&] {
    EXPECT_TRUE(reactor->AddOperation([](const ReactorGLES& reactor) {}));
    EXPECT_TRUE(reactor->React());
  });
  thread.join();

  EXPECT_EQ(deleting_thread, std::thread::id());

  EXPECT_TRUE(reactor->AddOperation([](const ReactorGLES& reactor) {}));
  EXPECT_TRUE(reactor->React());
  EXPECT_EQ(deleting_thread, std::this_thread::get_id());
}

// A texture collected by a thread that cannot react has no context whose
// commands the deletion must follow, so the first thread to react deletes it.
TEST(ReactorGLES, HandleCollectedWithoutContextDeletedOnAnyReactingThread) {
  auto mock_gles_impl = std::make_unique<MockGLESImpl>();

  std::thread::id deleting_thread;
  EXPECT_CALL(*mock_gles_impl, GenTextures(1, _))
      .WillOnce([](GLsizei size, GLuint* textures) { textures[0] = 1234; });
  EXPECT_CALL(*mock_gles_impl, DeleteTextures(1, Pointee(1234)))
      .WillOnce([&](GLsizei size, const GLuint* textures) {
        deleting_thread = std::this_thread::get_id();
      });

  std::shared_ptr<MockGLES> mock_gles =
      MockGLES::Init(std::move(mock_gles_impl));
  ProcTableGLES::Resolver resolver = kMockResolverGLES;
  auto proc_table = std::make_unique<ProcTableGLES>(resolver);
  auto worker = std::make_shared<AllowListWorker>();
  worker->AllowCurrentThread();
  auto reactor = std::make_shared<ReactorGLES>(std::move(proc_table));
  reactor->AddWorker(worker);

  HandleGLES handle = reactor->CreateHandle(HandleType::kTexture);

  std::thread collector([&] { reactor->CollectHandle(handle); });
  collector.join();

  std::thread::id reacting_thread;
  std::thread thread([&] {
    worker->AllowCurrentThread();
    reacting_thread = std::this_thread::get_id();
    EXPECT_TRUE(reactor->AddOperation([](const ReactorGLES& reactor) {}));
    EXPECT_TRUE(reactor->React());
  });
  thread.join();

  EXPECT_EQ(deleting_thread, reacting_thread);
}

// A framebuffer exists only in the context of the thread that created it, so
// that thread deletes it even when another thread that can react collects it.
// Covers a handle the reactor tracks and an untracked one.
TEST(ReactorGLES, FramebufferCollectedOnAnotherThreadDeletedOnOwnerThread) {
  auto mock_gles_impl = std::make_unique<MockGLESImpl>();

  std::vector<std::thread::id> deleting_threads;
  EXPECT_CALL(*mock_gles_impl, GenFramebuffers(1, _))
      .WillOnce([](GLsizei n, GLuint* framebuffers) { framebuffers[0] = 1234; })
      .WillOnce(
          [](GLsizei n, GLuint* framebuffers) { framebuffers[0] = 5678; });
  EXPECT_CALL(*mock_gles_impl, DeleteFramebuffers(1, _))
      .Times(2)
      .WillRepeatedly([&](GLsizei n, const GLuint* framebuffers) {
        deleting_threads.push_back(std::this_thread::get_id());
      });

  std::shared_ptr<MockGLES> mock_gles =
      MockGLES::Init(std::move(mock_gles_impl));
  ProcTableGLES::Resolver resolver = kMockResolverGLES;
  auto proc_table = std::make_unique<ProcTableGLES>(resolver);
  auto worker = std::make_shared<TestWorker>();
  auto reactor = std::make_shared<ReactorGLES>(std::move(proc_table));
  reactor->AddWorker(worker);

  HandleGLES tracked = reactor->CreateHandle(HandleType::kFrameBuffer);
  HandleGLES untracked =
      reactor->CreateUntrackedHandle(HandleType::kFrameBuffer);

  // The collecting thread can react, but its context does not hold the
  // framebuffers, so its reaction must leave them alone.
  std::thread thread([&] {
    reactor->CollectHandle(tracked);
    reactor->CollectHandle(untracked);
    EXPECT_TRUE(reactor->AddOperation([](const ReactorGLES& reactor) {}));
    EXPECT_TRUE(reactor->React());
  });
  thread.join();

  EXPECT_TRUE(deleting_threads.empty());

  EXPECT_TRUE(reactor->AddOperation([](const ReactorGLES& reactor) {}));
  EXPECT_TRUE(reactor->React());
  EXPECT_EQ(deleting_threads,
            std::vector<std::thread::id>(2, std::this_thread::get_id()));
}

}  // namespace testing
}  // namespace impeller
