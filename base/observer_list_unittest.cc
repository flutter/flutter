// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/observer_list.h"
#include "base/observer_list_threadsafe.h"

#include <vector>

#include "base/compiler_specific.h"
#include "base/location.h"
#include "base/memory/weak_ptr.h"
#include "base/run_loop.h"
#include "base/single_thread_task_runner.h"
#include "base/threading/platform_thread.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {
namespace {

class Foo {
 public:
  virtual void Observe(int x) = 0;
  virtual ~Foo() {}
};

class Adder : public Foo {
 public:
  explicit Adder(int scaler) : total(0), scaler_(scaler) {}
  void Observe(int x) override { total += x * scaler_; }
  ~Adder() override {}
  int total;

 private:
  int scaler_;
};

class Disrupter : public Foo {
 public:
  Disrupter(ObserverList<Foo>* list, Foo* doomed)
      : list_(list),
        doomed_(doomed) {
  }
  ~Disrupter() override {}
  void Observe(int x) override { list_->RemoveObserver(doomed_); }

 private:
  ObserverList<Foo>* list_;
  Foo* doomed_;
};

class ThreadSafeDisrupter : public Foo {
 public:
  ThreadSafeDisrupter(ObserverListThreadSafe<Foo>* list, Foo* doomed)
      : list_(list),
        doomed_(doomed) {
  }
  ~ThreadSafeDisrupter() override {}
  void Observe(int x) override { list_->RemoveObserver(doomed_); }

 private:
  ObserverListThreadSafe<Foo>* list_;
  Foo* doomed_;
};

template <typename ObserverListType>
class AddInObserve : public Foo {
 public:
  explicit AddInObserve(ObserverListType* observer_list)
      : added(false),
        observer_list(observer_list),
        adder(1) {
  }

  void Observe(int x) override {
    if (!added) {
      added = true;
      observer_list->AddObserver(&adder);
    }
  }

  bool added;
  ObserverListType* observer_list;
  Adder adder;
};


static const int kThreadRunTime = 2000;  // ms to run the multi-threaded test.

// A thread for use in the ThreadSafeObserver test
// which will add and remove itself from the notification
// list repeatedly.
class AddRemoveThread : public PlatformThread::Delegate,
                        public Foo {
 public:
  AddRemoveThread(ObserverListThreadSafe<Foo>* list, bool notify)
      : list_(list),
        loop_(nullptr),
        in_list_(false),
        start_(Time::Now()),
        count_observes_(0),
        count_addtask_(0),
        do_notifies_(notify),
        weak_factory_(this) {
  }

  ~AddRemoveThread() override {}

  void ThreadMain() override {
    loop_ = new MessageLoop();  // Fire up a message loop.
    loop_->task_runner()->PostTask(
        FROM_HERE,
        base::Bind(&AddRemoveThread::AddTask, weak_factory_.GetWeakPtr()));
    loop_->Run();
    //LOG(ERROR) << "Loop 0x" << std::hex << loop_ << " done. " <<
    //    count_observes_ << ", " << count_addtask_;
    delete loop_;
    loop_ = reinterpret_cast<MessageLoop*>(0xdeadbeef);
    delete this;
  }

  // This task just keeps posting to itself in an attempt
  // to race with the notifier.
  void AddTask() {
    count_addtask_++;

    if ((Time::Now() - start_).InMilliseconds() > kThreadRunTime) {
      VLOG(1) << "DONE!";
      return;
    }

    if (!in_list_) {
      list_->AddObserver(this);
      in_list_ = true;
    }

    if (do_notifies_) {
      list_->Notify(FROM_HERE, &Foo::Observe, 10);
    }

    loop_->task_runner()->PostTask(
        FROM_HERE,
        base::Bind(&AddRemoveThread::AddTask, weak_factory_.GetWeakPtr()));
  }

  void Quit() {
    loop_->task_runner()->PostTask(FROM_HERE,
                                   MessageLoop::QuitWhenIdleClosure());
  }

  void Observe(int x) override {
    count_observes_++;

    // If we're getting called after we removed ourselves from
    // the list, that is very bad!
    DCHECK(in_list_);

    // This callback should fire on the appropriate thread
    EXPECT_EQ(loop_, MessageLoop::current());

    list_->RemoveObserver(this);
    in_list_ = false;
  }

 private:
  ObserverListThreadSafe<Foo>* list_;
  MessageLoop* loop_;
  bool in_list_;        // Are we currently registered for notifications.
                        // in_list_ is only used on |this| thread.
  Time start_;          // The time we started the test.

  int count_observes_;  // Number of times we observed.
  int count_addtask_;   // Number of times thread AddTask was called
  bool do_notifies_;    // Whether these threads should do notifications.

  base::WeakPtrFactory<AddRemoveThread> weak_factory_;
};

TEST(ObserverListTest, BasicTest) {
  ObserverList<Foo> observer_list;
  Adder a(1), b(-1), c(1), d(-1), e(-1);
  Disrupter evil(&observer_list, &c);

  observer_list.AddObserver(&a);
  observer_list.AddObserver(&b);

  EXPECT_TRUE(observer_list.HasObserver(&a));
  EXPECT_FALSE(observer_list.HasObserver(&c));

  FOR_EACH_OBSERVER(Foo, observer_list, Observe(10));

  observer_list.AddObserver(&evil);
  observer_list.AddObserver(&c);
  observer_list.AddObserver(&d);

  // Removing an observer not in the list should do nothing.
  observer_list.RemoveObserver(&e);

  FOR_EACH_OBSERVER(Foo, observer_list, Observe(10));

  EXPECT_EQ(20, a.total);
  EXPECT_EQ(-20, b.total);
  EXPECT_EQ(0, c.total);
  EXPECT_EQ(-10, d.total);
  EXPECT_EQ(0, e.total);
}

TEST(ObserverListThreadSafeTest, BasicTest) {
  MessageLoop loop;

  scoped_refptr<ObserverListThreadSafe<Foo> > observer_list(
      new ObserverListThreadSafe<Foo>);
  Adder a(1);
  Adder b(-1);
  Adder c(1);
  Adder d(-1);
  ThreadSafeDisrupter evil(observer_list.get(), &c);

  observer_list->AddObserver(&a);
  observer_list->AddObserver(&b);

  observer_list->Notify(FROM_HERE, &Foo::Observe, 10);
  RunLoop().RunUntilIdle();

  observer_list->AddObserver(&evil);
  observer_list->AddObserver(&c);
  observer_list->AddObserver(&d);

  observer_list->Notify(FROM_HERE, &Foo::Observe, 10);
  RunLoop().RunUntilIdle();

  EXPECT_EQ(20, a.total);
  EXPECT_EQ(-20, b.total);
  EXPECT_EQ(0, c.total);
  EXPECT_EQ(-10, d.total);
}

TEST(ObserverListThreadSafeTest, RemoveObserver) {
  MessageLoop loop;

  scoped_refptr<ObserverListThreadSafe<Foo> > observer_list(
      new ObserverListThreadSafe<Foo>);
  Adder a(1), b(1);

  // A workaround for the compiler bug. See http://crbug.com/121960.
  EXPECT_NE(&a, &b);

  // Should do nothing.
  observer_list->RemoveObserver(&a);
  observer_list->RemoveObserver(&b);

  observer_list->Notify(FROM_HERE, &Foo::Observe, 10);
  RunLoop().RunUntilIdle();

  EXPECT_EQ(0, a.total);
  EXPECT_EQ(0, b.total);

  observer_list->AddObserver(&a);

  // Should also do nothing.
  observer_list->RemoveObserver(&b);

  observer_list->Notify(FROM_HERE, &Foo::Observe, 10);
  RunLoop().RunUntilIdle();

  EXPECT_EQ(10, a.total);
  EXPECT_EQ(0, b.total);
}

TEST(ObserverListThreadSafeTest, WithoutMessageLoop) {
  scoped_refptr<ObserverListThreadSafe<Foo> > observer_list(
      new ObserverListThreadSafe<Foo>);

  Adder a(1), b(1), c(1);

  // No MessageLoop, so these should not be added.
  observer_list->AddObserver(&a);
  observer_list->AddObserver(&b);

  {
    // Add c when there's a loop.
    MessageLoop loop;
    observer_list->AddObserver(&c);

    observer_list->Notify(FROM_HERE, &Foo::Observe, 10);
    RunLoop().RunUntilIdle();

    EXPECT_EQ(0, a.total);
    EXPECT_EQ(0, b.total);
    EXPECT_EQ(10, c.total);

    // Now add a when there's a loop.
    observer_list->AddObserver(&a);

    // Remove c when there's a loop.
    observer_list->RemoveObserver(&c);

    // Notify again.
    observer_list->Notify(FROM_HERE, &Foo::Observe, 20);
    RunLoop().RunUntilIdle();

    EXPECT_EQ(20, a.total);
    EXPECT_EQ(0, b.total);
    EXPECT_EQ(10, c.total);
  }

  // Removing should always succeed with or without a loop.
  observer_list->RemoveObserver(&a);

  // Notifying should not fail but should also be a no-op.
  MessageLoop loop;
  observer_list->AddObserver(&b);
  observer_list->Notify(FROM_HERE, &Foo::Observe, 30);
  RunLoop().RunUntilIdle();

  EXPECT_EQ(20, a.total);
  EXPECT_EQ(30, b.total);
  EXPECT_EQ(10, c.total);
}

class FooRemover : public Foo {
 public:
  explicit FooRemover(ObserverListThreadSafe<Foo>* list) : list_(list) {}
  ~FooRemover() override {}

  void AddFooToRemove(Foo* foo) {
    foos_.push_back(foo);
  }

  void Observe(int x) override {
    std::vector<Foo*> tmp;
    tmp.swap(foos_);
    for (std::vector<Foo*>::iterator it = tmp.begin();
         it != tmp.end(); ++it) {
      list_->RemoveObserver(*it);
    }
  }

 private:
  const scoped_refptr<ObserverListThreadSafe<Foo> > list_;
  std::vector<Foo*> foos_;
};

TEST(ObserverListThreadSafeTest, RemoveMultipleObservers) {
  MessageLoop loop;
  scoped_refptr<ObserverListThreadSafe<Foo> > observer_list(
      new ObserverListThreadSafe<Foo>);

  FooRemover a(observer_list.get());
  Adder b(1);

  observer_list->AddObserver(&a);
  observer_list->AddObserver(&b);

  a.AddFooToRemove(&a);
  a.AddFooToRemove(&b);

  observer_list->Notify(FROM_HERE, &Foo::Observe, 1);
  RunLoop().RunUntilIdle();
}

// A test driver for a multi-threaded notification loop.  Runs a number
// of observer threads, each of which constantly adds/removes itself
// from the observer list.  Optionally, if cross_thread_notifies is set
// to true, the observer threads will also trigger notifications to
// all observers.
static void ThreadSafeObserverHarness(int num_threads,
                                      bool cross_thread_notifies) {
  MessageLoop loop;

  const int kMaxThreads = 15;
  num_threads = num_threads > kMaxThreads ? kMaxThreads : num_threads;

  scoped_refptr<ObserverListThreadSafe<Foo> > observer_list(
      new ObserverListThreadSafe<Foo>);
  Adder a(1);
  Adder b(-1);
  Adder c(1);
  Adder d(-1);

  observer_list->AddObserver(&a);
  observer_list->AddObserver(&b);

  AddRemoveThread* threaded_observer[kMaxThreads];
  base::PlatformThreadHandle threads[kMaxThreads];
  for (int index = 0; index < num_threads; index++) {
    threaded_observer[index] = new AddRemoveThread(observer_list.get(), false);
    EXPECT_TRUE(PlatformThread::Create(0,
                threaded_observer[index], &threads[index]));
  }

  Time start = Time::Now();
  while (true) {
    if ((Time::Now() - start).InMilliseconds() > kThreadRunTime)
      break;

    observer_list->Notify(FROM_HERE, &Foo::Observe, 10);

    RunLoop().RunUntilIdle();
  }

  for (int index = 0; index < num_threads; index++) {
    threaded_observer[index]->Quit();
    PlatformThread::Join(threads[index]);
  }
}

TEST(ObserverListThreadSafeTest, CrossThreadObserver) {
  // Use 7 observer threads.  Notifications only come from
  // the main thread.
  ThreadSafeObserverHarness(7, false);
}

TEST(ObserverListThreadSafeTest, CrossThreadNotifications) {
  // Use 3 observer threads.  Notifications will fire from
  // the main thread and all 3 observer threads.
  ThreadSafeObserverHarness(3, true);
}

TEST(ObserverListThreadSafeTest, OutlivesMessageLoop) {
  MessageLoop* loop = new MessageLoop;
  scoped_refptr<ObserverListThreadSafe<Foo> > observer_list(
      new ObserverListThreadSafe<Foo>);

  Adder a(1);
  observer_list->AddObserver(&a);
  delete loop;
  // Test passes if we don't crash here.
  observer_list->Notify(FROM_HERE, &Foo::Observe, 1);
}

TEST(ObserverListTest, Existing) {
  ObserverList<Foo> observer_list(ObserverList<Foo>::NOTIFY_EXISTING_ONLY);
  Adder a(1);
  AddInObserve<ObserverList<Foo> > b(&observer_list);

  observer_list.AddObserver(&a);
  observer_list.AddObserver(&b);

  FOR_EACH_OBSERVER(Foo, observer_list, Observe(1));

  EXPECT_TRUE(b.added);
  // B's adder should not have been notified because it was added during
  // notification.
  EXPECT_EQ(0, b.adder.total);

  // Notify again to make sure b's adder is notified.
  FOR_EACH_OBSERVER(Foo, observer_list, Observe(1));
  EXPECT_EQ(1, b.adder.total);
}

// Same as above, but for ObserverListThreadSafe
TEST(ObserverListThreadSafeTest, Existing) {
  MessageLoop loop;
  scoped_refptr<ObserverListThreadSafe<Foo> > observer_list(
      new ObserverListThreadSafe<Foo>(ObserverList<Foo>::NOTIFY_EXISTING_ONLY));
  Adder a(1);
  AddInObserve<ObserverListThreadSafe<Foo> > b(observer_list.get());

  observer_list->AddObserver(&a);
  observer_list->AddObserver(&b);

  observer_list->Notify(FROM_HERE, &Foo::Observe, 1);
  RunLoop().RunUntilIdle();

  EXPECT_TRUE(b.added);
  // B's adder should not have been notified because it was added during
  // notification.
  EXPECT_EQ(0, b.adder.total);

  // Notify again to make sure b's adder is notified.
  observer_list->Notify(FROM_HERE, &Foo::Observe, 1);
  RunLoop().RunUntilIdle();
  EXPECT_EQ(1, b.adder.total);
}

class AddInClearObserve : public Foo {
 public:
  explicit AddInClearObserve(ObserverList<Foo>* list)
      : list_(list), added_(false), adder_(1) {}

  void Observe(int /* x */) override {
    list_->Clear();
    list_->AddObserver(&adder_);
    added_ = true;
  }

  bool added() const { return added_; }
  const Adder& adder() const { return adder_; }

 private:
  ObserverList<Foo>* const list_;

  bool added_;
  Adder adder_;
};

TEST(ObserverListTest, ClearNotifyAll) {
  ObserverList<Foo> observer_list;
  AddInClearObserve a(&observer_list);

  observer_list.AddObserver(&a);

  FOR_EACH_OBSERVER(Foo, observer_list, Observe(1));
  EXPECT_TRUE(a.added());
  EXPECT_EQ(1, a.adder().total)
      << "Adder should observe once and have sum of 1.";
}

TEST(ObserverListTest, ClearNotifyExistingOnly) {
  ObserverList<Foo> observer_list(ObserverList<Foo>::NOTIFY_EXISTING_ONLY);
  AddInClearObserve a(&observer_list);

  observer_list.AddObserver(&a);

  FOR_EACH_OBSERVER(Foo, observer_list, Observe(1));
  EXPECT_TRUE(a.added());
  EXPECT_EQ(0, a.adder().total)
      << "Adder should not observe, so sum should still be 0.";
}

class ListDestructor : public Foo {
 public:
  explicit ListDestructor(ObserverList<Foo>* list) : list_(list) {}
  ~ListDestructor() override {}

  void Observe(int x) override { delete list_; }

 private:
  ObserverList<Foo>* list_;
};


TEST(ObserverListTest, IteratorOutlivesList) {
  ObserverList<Foo>* observer_list = new ObserverList<Foo>;
  ListDestructor a(observer_list);
  observer_list->AddObserver(&a);

  FOR_EACH_OBSERVER(Foo, *observer_list, Observe(0));
  // If this test fails, there'll be Valgrind errors when this function goes out
  // of scope.
}

}  // namespace
}  // namespace base
