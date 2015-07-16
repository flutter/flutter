// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/compiler_specific.h"
#include "base/memory/scoped_ptr.h"
#include "base/synchronization/lock.h"
#include "base/threading/platform_thread.h"
#include "base/threading/simple_thread.h"
#include "base/threading/thread_collision_warner.h"
#include "testing/gtest/include/gtest/gtest.h"

// '' : local class member function does not have a body
MSVC_PUSH_DISABLE_WARNING(4822)


#if defined(NDEBUG)

// Would cause a memory leak otherwise.
#undef DFAKE_MUTEX
#define DFAKE_MUTEX(obj) scoped_ptr<base::AsserterBase> obj

// In Release, we expect the AsserterBase::warn() to not happen.
#define EXPECT_NDEBUG_FALSE_DEBUG_TRUE EXPECT_FALSE

#else

// In Debug, we expect the AsserterBase::warn() to happen.
#define EXPECT_NDEBUG_FALSE_DEBUG_TRUE EXPECT_TRUE

#endif


namespace {

// This is the asserter used with ThreadCollisionWarner instead of the default
// DCheckAsserter. The method fail_state is used to know if a collision took
// place.
class AssertReporter : public base::AsserterBase {
 public:
  AssertReporter()
      : failed_(false) {}

  void warn() override { failed_ = true; }

  ~AssertReporter() override {}

  bool fail_state() const { return failed_; }
  void reset() { failed_ = false; }

 private:
  bool failed_;
};

}  // namespace

TEST(ThreadCollisionTest, BookCriticalSection) {
  AssertReporter* local_reporter = new AssertReporter();

  base::ThreadCollisionWarner warner(local_reporter);
  EXPECT_FALSE(local_reporter->fail_state());

  {  // Pin section.
    DFAKE_SCOPED_LOCK_THREAD_LOCKED(warner);
    EXPECT_FALSE(local_reporter->fail_state());
    {  // Pin section.
      DFAKE_SCOPED_LOCK_THREAD_LOCKED(warner);
      EXPECT_FALSE(local_reporter->fail_state());
    }
  }
}

TEST(ThreadCollisionTest, ScopedRecursiveBookCriticalSection) {
  AssertReporter* local_reporter = new AssertReporter();

  base::ThreadCollisionWarner warner(local_reporter);
  EXPECT_FALSE(local_reporter->fail_state());

  {  // Pin section.
    DFAKE_SCOPED_RECURSIVE_LOCK(warner);
    EXPECT_FALSE(local_reporter->fail_state());
    {  // Pin section again (allowed by DFAKE_SCOPED_RECURSIVE_LOCK)
      DFAKE_SCOPED_RECURSIVE_LOCK(warner);
      EXPECT_FALSE(local_reporter->fail_state());
    }  // Unpin section.
  }  // Unpin section.

  // Check that section is not pinned
  {  // Pin section.
    DFAKE_SCOPED_LOCK(warner);
    EXPECT_FALSE(local_reporter->fail_state());
  }  // Unpin section.
}

TEST(ThreadCollisionTest, ScopedBookCriticalSection) {
  AssertReporter* local_reporter = new AssertReporter();

  base::ThreadCollisionWarner warner(local_reporter);
  EXPECT_FALSE(local_reporter->fail_state());

  {  // Pin section.
    DFAKE_SCOPED_LOCK(warner);
    EXPECT_FALSE(local_reporter->fail_state());
  }  // Unpin section.

  {  // Pin section.
    DFAKE_SCOPED_LOCK(warner);
    EXPECT_FALSE(local_reporter->fail_state());
    {
      // Pin section again (not allowed by DFAKE_SCOPED_LOCK)
      DFAKE_SCOPED_LOCK(warner);
      EXPECT_NDEBUG_FALSE_DEBUG_TRUE(local_reporter->fail_state());
      // Reset the status of warner for further tests.
      local_reporter->reset();
    }  // Unpin section.
  }  // Unpin section.

  {
    // Pin section.
    DFAKE_SCOPED_LOCK(warner);
    EXPECT_FALSE(local_reporter->fail_state());
  }  // Unpin section.
}

TEST(ThreadCollisionTest, MTBookCriticalSectionTest) {
  class NonThreadSafeQueue {
   public:
    explicit NonThreadSafeQueue(base::AsserterBase* asserter)
        : push_pop_(asserter) {
    }

    void push(int value) {
      DFAKE_SCOPED_LOCK_THREAD_LOCKED(push_pop_);
    }

    int pop() {
      DFAKE_SCOPED_LOCK_THREAD_LOCKED(push_pop_);
      return 0;
    }

   private:
    DFAKE_MUTEX(push_pop_);

    DISALLOW_COPY_AND_ASSIGN(NonThreadSafeQueue);
  };

  class QueueUser : public base::DelegateSimpleThread::Delegate {
   public:
    explicit QueueUser(NonThreadSafeQueue* queue) : queue_(queue) {}

    void Run() override {
      queue_->push(0);
      queue_->pop();
    }

   private:
    NonThreadSafeQueue* queue_;
  };

  AssertReporter* local_reporter = new AssertReporter();

  NonThreadSafeQueue queue(local_reporter);

  QueueUser queue_user_a(&queue);
  QueueUser queue_user_b(&queue);

  base::DelegateSimpleThread thread_a(&queue_user_a, "queue_user_thread_a");
  base::DelegateSimpleThread thread_b(&queue_user_b, "queue_user_thread_b");

  thread_a.Start();
  thread_b.Start();

  thread_a.Join();
  thread_b.Join();

  EXPECT_NDEBUG_FALSE_DEBUG_TRUE(local_reporter->fail_state());
}

TEST(ThreadCollisionTest, MTScopedBookCriticalSectionTest) {
  // Queue with a 5 seconds push execution time, hopefuly the two used threads
  // in the test will enter the push at same time.
  class NonThreadSafeQueue {
   public:
    explicit NonThreadSafeQueue(base::AsserterBase* asserter)
        : push_pop_(asserter) {
    }

    void push(int value) {
      DFAKE_SCOPED_LOCK(push_pop_);
      base::PlatformThread::Sleep(base::TimeDelta::FromSeconds(5));
    }

    int pop() {
      DFAKE_SCOPED_LOCK(push_pop_);
      return 0;
    }

   private:
    DFAKE_MUTEX(push_pop_);

    DISALLOW_COPY_AND_ASSIGN(NonThreadSafeQueue);
  };

  class QueueUser : public base::DelegateSimpleThread::Delegate {
   public:
    explicit QueueUser(NonThreadSafeQueue* queue) : queue_(queue) {}

    void Run() override {
      queue_->push(0);
      queue_->pop();
    }

   private:
    NonThreadSafeQueue* queue_;
  };

  AssertReporter* local_reporter = new AssertReporter();

  NonThreadSafeQueue queue(local_reporter);

  QueueUser queue_user_a(&queue);
  QueueUser queue_user_b(&queue);

  base::DelegateSimpleThread thread_a(&queue_user_a, "queue_user_thread_a");
  base::DelegateSimpleThread thread_b(&queue_user_b, "queue_user_thread_b");

  thread_a.Start();
  thread_b.Start();

  thread_a.Join();
  thread_b.Join();

  EXPECT_NDEBUG_FALSE_DEBUG_TRUE(local_reporter->fail_state());
}

TEST(ThreadCollisionTest, MTSynchedScopedBookCriticalSectionTest) {
  // Queue with a 2 seconds push execution time, hopefuly the two used threads
  // in the test will enter the push at same time.
  class NonThreadSafeQueue {
   public:
    explicit NonThreadSafeQueue(base::AsserterBase* asserter)
        : push_pop_(asserter) {
    }

    void push(int value) {
      DFAKE_SCOPED_LOCK(push_pop_);
      base::PlatformThread::Sleep(base::TimeDelta::FromSeconds(2));
    }

    int pop() {
      DFAKE_SCOPED_LOCK(push_pop_);
      return 0;
    }

   private:
    DFAKE_MUTEX(push_pop_);

    DISALLOW_COPY_AND_ASSIGN(NonThreadSafeQueue);
  };

  // This time the QueueUser class protects the non thread safe queue with
  // a lock.
  class QueueUser : public base::DelegateSimpleThread::Delegate {
   public:
    QueueUser(NonThreadSafeQueue* queue, base::Lock* lock)
        : queue_(queue), lock_(lock) {}

    void Run() override {
      {
        base::AutoLock auto_lock(*lock_);
        queue_->push(0);
      }
      {
        base::AutoLock auto_lock(*lock_);
        queue_->pop();
      }
    }
   private:
    NonThreadSafeQueue* queue_;
    base::Lock* lock_;
  };

  AssertReporter* local_reporter = new AssertReporter();

  NonThreadSafeQueue queue(local_reporter);

  base::Lock lock;

  QueueUser queue_user_a(&queue, &lock);
  QueueUser queue_user_b(&queue, &lock);

  base::DelegateSimpleThread thread_a(&queue_user_a, "queue_user_thread_a");
  base::DelegateSimpleThread thread_b(&queue_user_b, "queue_user_thread_b");

  thread_a.Start();
  thread_b.Start();

  thread_a.Join();
  thread_b.Join();

  EXPECT_FALSE(local_reporter->fail_state());
}

TEST(ThreadCollisionTest, MTSynchedScopedRecursiveBookCriticalSectionTest) {
  // Queue with a 2 seconds push execution time, hopefuly the two used threads
  // in the test will enter the push at same time.
  class NonThreadSafeQueue {
   public:
    explicit NonThreadSafeQueue(base::AsserterBase* asserter)
        : push_pop_(asserter) {
    }

    void push(int) {
      DFAKE_SCOPED_RECURSIVE_LOCK(push_pop_);
      bar();
      base::PlatformThread::Sleep(base::TimeDelta::FromSeconds(2));
    }

    int pop() {
      DFAKE_SCOPED_RECURSIVE_LOCK(push_pop_);
      return 0;
    }

    void bar() {
      DFAKE_SCOPED_RECURSIVE_LOCK(push_pop_);
    }

   private:
    DFAKE_MUTEX(push_pop_);

    DISALLOW_COPY_AND_ASSIGN(NonThreadSafeQueue);
  };

  // This time the QueueUser class protects the non thread safe queue with
  // a lock.
  class QueueUser : public base::DelegateSimpleThread::Delegate {
   public:
    QueueUser(NonThreadSafeQueue* queue, base::Lock* lock)
        : queue_(queue), lock_(lock) {}

    void Run() override {
      {
        base::AutoLock auto_lock(*lock_);
        queue_->push(0);
      }
      {
        base::AutoLock auto_lock(*lock_);
        queue_->bar();
      }
      {
        base::AutoLock auto_lock(*lock_);
        queue_->pop();
      }
    }
   private:
    NonThreadSafeQueue* queue_;
    base::Lock* lock_;
  };

  AssertReporter* local_reporter = new AssertReporter();

  NonThreadSafeQueue queue(local_reporter);

  base::Lock lock;

  QueueUser queue_user_a(&queue, &lock);
  QueueUser queue_user_b(&queue, &lock);

  base::DelegateSimpleThread thread_a(&queue_user_a, "queue_user_thread_a");
  base::DelegateSimpleThread thread_b(&queue_user_b, "queue_user_thread_b");

  thread_a.Start();
  thread_b.Start();

  thread_a.Join();
  thread_b.Join();

  EXPECT_FALSE(local_reporter->fail_state());
}
