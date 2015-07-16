// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/message_loop/message_loop_test.h"

#include "base/bind.h"
#include "base/memory/ref_counted.h"
#include "base/run_loop.h"
#include "base/synchronization/waitable_event.h"
#include "base/threading/thread.h"

namespace base {
namespace test {

namespace {

class Foo : public RefCounted<Foo> {
 public:
  Foo() : test_count_(0) {
  }

  void Test0() {
    ++test_count_;
  }

  void Test1ConstRef(const std::string& a) {
    ++test_count_;
    result_.append(a);
  }

  void Test1Ptr(std::string* a) {
    ++test_count_;
    result_.append(*a);
  }

  void Test1Int(int a) {
    test_count_ += a;
  }

  void Test2Ptr(std::string* a, std::string* b) {
    ++test_count_;
    result_.append(*a);
    result_.append(*b);
  }

  void Test2Mixed(const std::string& a, std::string* b) {
    ++test_count_;
    result_.append(a);
    result_.append(*b);
  }

  int test_count() const { return test_count_; }
  const std::string& result() const { return result_; }

 private:
  friend class RefCounted<Foo>;

  ~Foo() {}

  int test_count_;
  std::string result_;

  DISALLOW_COPY_AND_ASSIGN(Foo);
};

// This function runs slowly to simulate a large amount of work being done.
void SlowFunc(TimeDelta pause, int* quit_counter) {
    PlatformThread::Sleep(pause);
    if (--(*quit_counter) == 0)
      MessageLoop::current()->QuitWhenIdle();
}

// This function records the time when Run was called in a Time object, which is
// useful for building a variety of MessageLoop tests.
// TODO(sky): remove?
void RecordRunTimeFunc(Time* run_time, int* quit_counter) {
  *run_time = Time::Now();

    // Cause our Run function to take some time to execute.  As a result we can
    // count on subsequent RecordRunTimeFunc()s running at a future time,
    // without worry about the resolution of our system clock being an issue.
  SlowFunc(TimeDelta::FromMilliseconds(10), quit_counter);
}

}  // namespace

void RunTest_PostTask(MessagePumpFactory factory) {
  scoped_ptr<MessagePump> pump(factory());
  MessageLoop loop(pump.Pass());
  // Add tests to message loop
  scoped_refptr<Foo> foo(new Foo());
  std::string a("a"), b("b"), c("c"), d("d");
  MessageLoop::current()->PostTask(FROM_HERE, Bind(
      &Foo::Test0, foo.get()));
  MessageLoop::current()->PostTask(FROM_HERE, Bind(
    &Foo::Test1ConstRef, foo.get(), a));
  MessageLoop::current()->PostTask(FROM_HERE, Bind(
      &Foo::Test1Ptr, foo.get(), &b));
  MessageLoop::current()->PostTask(FROM_HERE, Bind(
      &Foo::Test1Int, foo.get(), 100));
  MessageLoop::current()->PostTask(FROM_HERE, Bind(
      &Foo::Test2Ptr, foo.get(), &a, &c));
  MessageLoop::current()->PostTask(FROM_HERE, Bind(
      &Foo::Test2Mixed, foo.get(), a, &d));
  // After all tests, post a message that will shut down the message loop
  MessageLoop::current()->PostTask(FROM_HERE, Bind(
      &MessageLoop::Quit, Unretained(MessageLoop::current())));

  // Now kick things off
  MessageLoop::current()->Run();

  EXPECT_EQ(foo->test_count(), 105);
  EXPECT_EQ(foo->result(), "abacad");
}

void RunTest_PostDelayedTask_Basic(MessagePumpFactory factory) {
  scoped_ptr<MessagePump> pump(factory());
  MessageLoop loop(pump.Pass());

  // Test that PostDelayedTask results in a delayed task.

  const TimeDelta kDelay = TimeDelta::FromMilliseconds(100);

  int num_tasks = 1;
  Time run_time;

  loop.PostDelayedTask(
      FROM_HERE, Bind(&RecordRunTimeFunc, &run_time, &num_tasks),
      kDelay);

  Time time_before_run = Time::Now();
  loop.Run();
  Time time_after_run = Time::Now();

  EXPECT_EQ(0, num_tasks);
  EXPECT_LT(kDelay, time_after_run - time_before_run);
}

void RunTest_PostDelayedTask_InDelayOrder(MessagePumpFactory factory) {
  scoped_ptr<MessagePump> pump(factory());
  MessageLoop loop(pump.Pass());

  // Test that two tasks with different delays run in the right order.
  int num_tasks = 2;
  Time run_time1, run_time2;

  loop.PostDelayedTask(
      FROM_HERE,
      Bind(&RecordRunTimeFunc, &run_time1, &num_tasks),
      TimeDelta::FromMilliseconds(200));
  // If we get a large pause in execution (due to a context switch) here, this
  // test could fail.
  loop.PostDelayedTask(
      FROM_HERE,
      Bind(&RecordRunTimeFunc, &run_time2, &num_tasks),
      TimeDelta::FromMilliseconds(10));

  loop.Run();
  EXPECT_EQ(0, num_tasks);

  EXPECT_TRUE(run_time2 < run_time1);
}

void RunTest_PostDelayedTask_InPostOrder(MessagePumpFactory factory) {
  scoped_ptr<MessagePump> pump(factory());
  MessageLoop loop(pump.Pass());

  // Test that two tasks with the same delay run in the order in which they
  // were posted.
  //
  // NOTE: This is actually an approximate test since the API only takes a
  // "delay" parameter, so we are not exactly simulating two tasks that get
  // posted at the exact same time.  It would be nice if the API allowed us to
  // specify the desired run time.

  const TimeDelta kDelay = TimeDelta::FromMilliseconds(100);

  int num_tasks = 2;
  Time run_time1, run_time2;

  loop.PostDelayedTask(
      FROM_HERE,
      Bind(&RecordRunTimeFunc, &run_time1, &num_tasks), kDelay);
  loop.PostDelayedTask(
      FROM_HERE,
      Bind(&RecordRunTimeFunc, &run_time2, &num_tasks), kDelay);

  loop.Run();
  EXPECT_EQ(0, num_tasks);

  EXPECT_TRUE(run_time1 < run_time2);
}

void RunTest_PostDelayedTask_InPostOrder_2(MessagePumpFactory factory) {
  scoped_ptr<MessagePump> pump(factory());
  MessageLoop loop(pump.Pass());

  // Test that a delayed task still runs after a normal tasks even if the
  // normal tasks take a long time to run.

  const TimeDelta kPause = TimeDelta::FromMilliseconds(50);

  int num_tasks = 2;
  Time run_time;

  loop.PostTask(FROM_HERE, Bind(&SlowFunc, kPause, &num_tasks));
  loop.PostDelayedTask(
      FROM_HERE,
      Bind(&RecordRunTimeFunc, &run_time, &num_tasks),
      TimeDelta::FromMilliseconds(10));

  Time time_before_run = Time::Now();
  loop.Run();
  Time time_after_run = Time::Now();

  EXPECT_EQ(0, num_tasks);

  EXPECT_LT(kPause, time_after_run - time_before_run);
}

void RunTest_PostDelayedTask_InPostOrder_3(MessagePumpFactory factory) {
  scoped_ptr<MessagePump> pump(factory());
  MessageLoop loop(pump.Pass());

  // Test that a delayed task still runs after a pile of normal tasks.  The key
  // difference between this test and the previous one is that here we return
  // the MessageLoop a lot so we give the MessageLoop plenty of opportunities
  // to maybe run the delayed task.  It should know not to do so until the
  // delayed task's delay has passed.

  int num_tasks = 11;
  Time run_time1, run_time2;

  // Clutter the ML with tasks.
  for (int i = 1; i < num_tasks; ++i)
    loop.PostTask(FROM_HERE,
                  Bind(&RecordRunTimeFunc, &run_time1, &num_tasks));

  loop.PostDelayedTask(
      FROM_HERE, Bind(&RecordRunTimeFunc, &run_time2, &num_tasks),
      TimeDelta::FromMilliseconds(1));

  loop.Run();
  EXPECT_EQ(0, num_tasks);

  EXPECT_TRUE(run_time2 > run_time1);
}

void RunTest_PostDelayedTask_SharedTimer(MessagePumpFactory factory) {
  scoped_ptr<MessagePump> pump(factory());
  MessageLoop loop(pump.Pass());

  // Test that the interval of the timer, used to run the next delayed task, is
  // set to a value corresponding to when the next delayed task should run.

  // By setting num_tasks to 1, we ensure that the first task to run causes the
  // run loop to exit.
  int num_tasks = 1;
  Time run_time1, run_time2;

  loop.PostDelayedTask(
      FROM_HERE,
      Bind(&RecordRunTimeFunc, &run_time1, &num_tasks),
      TimeDelta::FromSeconds(1000));
  loop.PostDelayedTask(
      FROM_HERE,
      Bind(&RecordRunTimeFunc, &run_time2, &num_tasks),
      TimeDelta::FromMilliseconds(10));

  Time start_time = Time::Now();

  loop.Run();
  EXPECT_EQ(0, num_tasks);

  // Ensure that we ran in far less time than the slower timer.
  TimeDelta total_time = Time::Now() - start_time;
  EXPECT_GT(5000, total_time.InMilliseconds());

  // In case both timers somehow run at nearly the same time, sleep a little
  // and then run all pending to force them both to have run.  This is just
  // encouraging flakiness if there is any.
  PlatformThread::Sleep(TimeDelta::FromMilliseconds(100));
  RunLoop().RunUntilIdle();

  EXPECT_TRUE(run_time1.is_null());
  EXPECT_FALSE(run_time2.is_null());
}

// This is used to inject a test point for recording the destructor calls for
// Closure objects send to MessageLoop::PostTask(). It is awkward usage since we
// are trying to hook the actual destruction, which is not a common operation.
class RecordDeletionProbe : public RefCounted<RecordDeletionProbe> {
 public:
  RecordDeletionProbe(RecordDeletionProbe* post_on_delete, bool* was_deleted)
      : post_on_delete_(post_on_delete), was_deleted_(was_deleted) {
  }
  void Run() {}

 private:
  friend class RefCounted<RecordDeletionProbe>;

  ~RecordDeletionProbe() {
    *was_deleted_ = true;
    if (post_on_delete_.get())
      MessageLoop::current()->PostTask(
          FROM_HERE, Bind(&RecordDeletionProbe::Run, post_on_delete_.get()));
  }

  scoped_refptr<RecordDeletionProbe> post_on_delete_;
  bool* was_deleted_;
};

void RunTest_EnsureDeletion(MessagePumpFactory factory) {
  bool a_was_deleted = false;
  bool b_was_deleted = false;
  {
    scoped_ptr<MessagePump> pump(factory());
    MessageLoop loop(pump.Pass());
    loop.PostTask(
        FROM_HERE, Bind(&RecordDeletionProbe::Run,
                              new RecordDeletionProbe(NULL, &a_was_deleted)));
    // TODO(ajwong): Do we really need 1000ms here?
    loop.PostDelayedTask(
        FROM_HERE, Bind(&RecordDeletionProbe::Run,
                              new RecordDeletionProbe(NULL, &b_was_deleted)),
        TimeDelta::FromMilliseconds(1000));
  }
  EXPECT_TRUE(a_was_deleted);
  EXPECT_TRUE(b_was_deleted);
}

void RunTest_EnsureDeletion_Chain(MessagePumpFactory factory) {
  bool a_was_deleted = false;
  bool b_was_deleted = false;
  bool c_was_deleted = false;
  {
    scoped_ptr<MessagePump> pump(factory());
    MessageLoop loop(pump.Pass());
    // The scoped_refptr for each of the below is held either by the chained
    // RecordDeletionProbe, or the bound RecordDeletionProbe::Run() callback.
    RecordDeletionProbe* a = new RecordDeletionProbe(NULL, &a_was_deleted);
    RecordDeletionProbe* b = new RecordDeletionProbe(a, &b_was_deleted);
    RecordDeletionProbe* c = new RecordDeletionProbe(b, &c_was_deleted);
    loop.PostTask(FROM_HERE, Bind(&RecordDeletionProbe::Run, c));
  }
  EXPECT_TRUE(a_was_deleted);
  EXPECT_TRUE(b_was_deleted);
  EXPECT_TRUE(c_was_deleted);
}

void NestingFunc(int* depth) {
  if (*depth > 0) {
    *depth -= 1;
    MessageLoop::current()->PostTask(FROM_HERE,
                                     Bind(&NestingFunc, depth));

    MessageLoop::current()->SetNestableTasksAllowed(true);
    MessageLoop::current()->Run();
  }
  MessageLoop::current()->QuitWhenIdle();
}

void RunTest_Nesting(MessagePumpFactory factory) {
  scoped_ptr<MessagePump> pump(factory());
  MessageLoop loop(pump.Pass());

  int depth = 100;
  MessageLoop::current()->PostTask(FROM_HERE,
                                   Bind(&NestingFunc, &depth));
  MessageLoop::current()->Run();
  EXPECT_EQ(depth, 0);
}

enum TaskType {
  MESSAGEBOX,
  ENDDIALOG,
  RECURSIVE,
  TIMEDMESSAGELOOP,
  QUITMESSAGELOOP,
  ORDERED,
  PUMPS,
  SLEEP,
  RUNS,
};

struct TaskItem {
  TaskItem(TaskType t, int c, bool s)
      : type(t),
        cookie(c),
        start(s) {
  }

  TaskType type;
  int cookie;
  bool start;

  bool operator == (const TaskItem& other) const {
    return type == other.type && cookie == other.cookie && start == other.start;
  }
};

std::ostream& operator <<(std::ostream& os, TaskType type) {
  switch (type) {
  case MESSAGEBOX:        os << "MESSAGEBOX"; break;
  case ENDDIALOG:         os << "ENDDIALOG"; break;
  case RECURSIVE:         os << "RECURSIVE"; break;
  case TIMEDMESSAGELOOP:  os << "TIMEDMESSAGELOOP"; break;
  case QUITMESSAGELOOP:   os << "QUITMESSAGELOOP"; break;
  case ORDERED:          os << "ORDERED"; break;
  case PUMPS:             os << "PUMPS"; break;
  case SLEEP:             os << "SLEEP"; break;
  default:
    NOTREACHED();
    os << "Unknown TaskType";
    break;
  }
  return os;
}

std::ostream& operator <<(std::ostream& os, const TaskItem& item) {
  if (item.start)
    return os << item.type << " " << item.cookie << " starts";
  else
    return os << item.type << " " << item.cookie << " ends";
}

class TaskList {
 public:
  void RecordStart(TaskType type, int cookie) {
    TaskItem item(type, cookie, true);
    DVLOG(1) << item;
    task_list_.push_back(item);
  }

  void RecordEnd(TaskType type, int cookie) {
    TaskItem item(type, cookie, false);
    DVLOG(1) << item;
    task_list_.push_back(item);
  }

  size_t Size() {
    return task_list_.size();
  }

  TaskItem Get(int n)  {
    return task_list_[n];
  }

 private:
  std::vector<TaskItem> task_list_;
};

void RecursiveFunc(TaskList* order, int cookie, int depth,
                   bool is_reentrant) {
  order->RecordStart(RECURSIVE, cookie);
  if (depth > 0) {
    if (is_reentrant)
      MessageLoop::current()->SetNestableTasksAllowed(true);
    MessageLoop::current()->PostTask(
        FROM_HERE,
        Bind(&RecursiveFunc, order, cookie, depth - 1, is_reentrant));
  }
  order->RecordEnd(RECURSIVE, cookie);
}

void QuitFunc(TaskList* order, int cookie) {
  order->RecordStart(QUITMESSAGELOOP, cookie);
  MessageLoop::current()->QuitWhenIdle();
  order->RecordEnd(QUITMESSAGELOOP, cookie);
}
void RunTest_RecursiveDenial1(MessagePumpFactory factory) {
  scoped_ptr<MessagePump> pump(factory());
  MessageLoop loop(pump.Pass());

  EXPECT_TRUE(MessageLoop::current()->NestableTasksAllowed());
  TaskList order;
  MessageLoop::current()->PostTask(
      FROM_HERE,
      Bind(&RecursiveFunc, &order, 1, 2, false));
  MessageLoop::current()->PostTask(
      FROM_HERE,
      Bind(&RecursiveFunc, &order, 2, 2, false));
  MessageLoop::current()->PostTask(
      FROM_HERE,
      Bind(&QuitFunc, &order, 3));

  MessageLoop::current()->Run();

  // FIFO order.
  ASSERT_EQ(14U, order.Size());
  EXPECT_EQ(order.Get(0), TaskItem(RECURSIVE, 1, true));
  EXPECT_EQ(order.Get(1), TaskItem(RECURSIVE, 1, false));
  EXPECT_EQ(order.Get(2), TaskItem(RECURSIVE, 2, true));
  EXPECT_EQ(order.Get(3), TaskItem(RECURSIVE, 2, false));
  EXPECT_EQ(order.Get(4), TaskItem(QUITMESSAGELOOP, 3, true));
  EXPECT_EQ(order.Get(5), TaskItem(QUITMESSAGELOOP, 3, false));
  EXPECT_EQ(order.Get(6), TaskItem(RECURSIVE, 1, true));
  EXPECT_EQ(order.Get(7), TaskItem(RECURSIVE, 1, false));
  EXPECT_EQ(order.Get(8), TaskItem(RECURSIVE, 2, true));
  EXPECT_EQ(order.Get(9), TaskItem(RECURSIVE, 2, false));
  EXPECT_EQ(order.Get(10), TaskItem(RECURSIVE, 1, true));
  EXPECT_EQ(order.Get(11), TaskItem(RECURSIVE, 1, false));
  EXPECT_EQ(order.Get(12), TaskItem(RECURSIVE, 2, true));
  EXPECT_EQ(order.Get(13), TaskItem(RECURSIVE, 2, false));
}

void RecursiveSlowFunc(TaskList* order, int cookie, int depth,
                       bool is_reentrant) {
  RecursiveFunc(order, cookie, depth, is_reentrant);
  PlatformThread::Sleep(TimeDelta::FromMilliseconds(10));
}

void OrderedFunc(TaskList* order, int cookie) {
  order->RecordStart(ORDERED, cookie);
  order->RecordEnd(ORDERED, cookie);
}

void RunTest_RecursiveDenial3(MessagePumpFactory factory) {
  scoped_ptr<MessagePump> pump(factory());
  MessageLoop loop(pump.Pass());

  EXPECT_TRUE(MessageLoop::current()->NestableTasksAllowed());
  TaskList order;
  MessageLoop::current()->PostTask(
      FROM_HERE, Bind(&RecursiveSlowFunc, &order, 1, 2, false));
  MessageLoop::current()->PostTask(
      FROM_HERE, Bind(&RecursiveSlowFunc, &order, 2, 2, false));
  MessageLoop::current()->PostDelayedTask(
      FROM_HERE,
      Bind(&OrderedFunc, &order, 3),
      TimeDelta::FromMilliseconds(5));
  MessageLoop::current()->PostDelayedTask(
      FROM_HERE,
      Bind(&QuitFunc, &order, 4),
      TimeDelta::FromMilliseconds(5));

  MessageLoop::current()->Run();

  // FIFO order.
  ASSERT_EQ(16U, order.Size());
  EXPECT_EQ(order.Get(0), TaskItem(RECURSIVE, 1, true));
  EXPECT_EQ(order.Get(1), TaskItem(RECURSIVE, 1, false));
  EXPECT_EQ(order.Get(2), TaskItem(RECURSIVE, 2, true));
  EXPECT_EQ(order.Get(3), TaskItem(RECURSIVE, 2, false));
  EXPECT_EQ(order.Get(4), TaskItem(RECURSIVE, 1, true));
  EXPECT_EQ(order.Get(5), TaskItem(RECURSIVE, 1, false));
  EXPECT_EQ(order.Get(6), TaskItem(ORDERED, 3, true));
  EXPECT_EQ(order.Get(7), TaskItem(ORDERED, 3, false));
  EXPECT_EQ(order.Get(8), TaskItem(RECURSIVE, 2, true));
  EXPECT_EQ(order.Get(9), TaskItem(RECURSIVE, 2, false));
  EXPECT_EQ(order.Get(10), TaskItem(QUITMESSAGELOOP, 4, true));
  EXPECT_EQ(order.Get(11), TaskItem(QUITMESSAGELOOP, 4, false));
  EXPECT_EQ(order.Get(12), TaskItem(RECURSIVE, 1, true));
  EXPECT_EQ(order.Get(13), TaskItem(RECURSIVE, 1, false));
  EXPECT_EQ(order.Get(14), TaskItem(RECURSIVE, 2, true));
  EXPECT_EQ(order.Get(15), TaskItem(RECURSIVE, 2, false));
}

void RunTest_RecursiveSupport1(MessagePumpFactory factory) {
  scoped_ptr<MessagePump> pump(factory());
  MessageLoop loop(pump.Pass());

  TaskList order;
  MessageLoop::current()->PostTask(
      FROM_HERE, Bind(&RecursiveFunc, &order, 1, 2, true));
  MessageLoop::current()->PostTask(
      FROM_HERE, Bind(&RecursiveFunc, &order, 2, 2, true));
  MessageLoop::current()->PostTask(
      FROM_HERE, Bind(&QuitFunc, &order, 3));

  MessageLoop::current()->Run();

  // FIFO order.
  ASSERT_EQ(14U, order.Size());
  EXPECT_EQ(order.Get(0), TaskItem(RECURSIVE, 1, true));
  EXPECT_EQ(order.Get(1), TaskItem(RECURSIVE, 1, false));
  EXPECT_EQ(order.Get(2), TaskItem(RECURSIVE, 2, true));
  EXPECT_EQ(order.Get(3), TaskItem(RECURSIVE, 2, false));
  EXPECT_EQ(order.Get(4), TaskItem(QUITMESSAGELOOP, 3, true));
  EXPECT_EQ(order.Get(5), TaskItem(QUITMESSAGELOOP, 3, false));
  EXPECT_EQ(order.Get(6), TaskItem(RECURSIVE, 1, true));
  EXPECT_EQ(order.Get(7), TaskItem(RECURSIVE, 1, false));
  EXPECT_EQ(order.Get(8), TaskItem(RECURSIVE, 2, true));
  EXPECT_EQ(order.Get(9), TaskItem(RECURSIVE, 2, false));
  EXPECT_EQ(order.Get(10), TaskItem(RECURSIVE, 1, true));
  EXPECT_EQ(order.Get(11), TaskItem(RECURSIVE, 1, false));
  EXPECT_EQ(order.Get(12), TaskItem(RECURSIVE, 2, true));
  EXPECT_EQ(order.Get(13), TaskItem(RECURSIVE, 2, false));
}

// Tests that non nestable tasks run in FIFO if there are no nested loops.
void RunTest_NonNestableWithNoNesting(MessagePumpFactory factory) {
  scoped_ptr<MessagePump> pump(factory());
  MessageLoop loop(pump.Pass());

  TaskList order;

  MessageLoop::current()->PostNonNestableTask(
      FROM_HERE,
      Bind(&OrderedFunc, &order, 1));
  MessageLoop::current()->PostTask(FROM_HERE,
                                   Bind(&OrderedFunc, &order, 2));
  MessageLoop::current()->PostTask(FROM_HERE,
                                   Bind(&QuitFunc, &order, 3));
  MessageLoop::current()->Run();

  // FIFO order.
  ASSERT_EQ(6U, order.Size());
  EXPECT_EQ(order.Get(0), TaskItem(ORDERED, 1, true));
  EXPECT_EQ(order.Get(1), TaskItem(ORDERED, 1, false));
  EXPECT_EQ(order.Get(2), TaskItem(ORDERED, 2, true));
  EXPECT_EQ(order.Get(3), TaskItem(ORDERED, 2, false));
  EXPECT_EQ(order.Get(4), TaskItem(QUITMESSAGELOOP, 3, true));
  EXPECT_EQ(order.Get(5), TaskItem(QUITMESSAGELOOP, 3, false));
}

void FuncThatPumps(TaskList* order, int cookie) {
  order->RecordStart(PUMPS, cookie);
  {
    MessageLoop::ScopedNestableTaskAllower allow(MessageLoop::current());
    RunLoop().RunUntilIdle();
  }
  order->RecordEnd(PUMPS, cookie);
}

void SleepFunc(TaskList* order, int cookie, TimeDelta delay) {
  order->RecordStart(SLEEP, cookie);
  PlatformThread::Sleep(delay);
  order->RecordEnd(SLEEP, cookie);
}

// Tests that non nestable tasks don't run when there's code in the call stack.
void RunTest_NonNestableInNestedLoop(MessagePumpFactory factory,
                                     bool use_delayed) {
  scoped_ptr<MessagePump> pump(factory());
  MessageLoop loop(pump.Pass());

  TaskList order;

  MessageLoop::current()->PostTask(
      FROM_HERE,
      Bind(&FuncThatPumps, &order, 1));
  if (use_delayed) {
    MessageLoop::current()->PostNonNestableDelayedTask(
        FROM_HERE,
        Bind(&OrderedFunc, &order, 2),
        TimeDelta::FromMilliseconds(1));
  } else {
    MessageLoop::current()->PostNonNestableTask(
        FROM_HERE,
        Bind(&OrderedFunc, &order, 2));
  }
  MessageLoop::current()->PostTask(FROM_HERE,
                                   Bind(&OrderedFunc, &order, 3));
  MessageLoop::current()->PostTask(
      FROM_HERE,
      Bind(&SleepFunc, &order, 4, TimeDelta::FromMilliseconds(50)));
  MessageLoop::current()->PostTask(FROM_HERE,
                                   Bind(&OrderedFunc, &order, 5));
  if (use_delayed) {
    MessageLoop::current()->PostNonNestableDelayedTask(
        FROM_HERE,
        Bind(&QuitFunc, &order, 6),
        TimeDelta::FromMilliseconds(2));
  } else {
    MessageLoop::current()->PostNonNestableTask(
        FROM_HERE,
        Bind(&QuitFunc, &order, 6));
  }

  MessageLoop::current()->Run();

  // FIFO order.
  ASSERT_EQ(12U, order.Size());
  EXPECT_EQ(order.Get(0), TaskItem(PUMPS, 1, true));
  EXPECT_EQ(order.Get(1), TaskItem(ORDERED, 3, true));
  EXPECT_EQ(order.Get(2), TaskItem(ORDERED, 3, false));
  EXPECT_EQ(order.Get(3), TaskItem(SLEEP, 4, true));
  EXPECT_EQ(order.Get(4), TaskItem(SLEEP, 4, false));
  EXPECT_EQ(order.Get(5), TaskItem(ORDERED, 5, true));
  EXPECT_EQ(order.Get(6), TaskItem(ORDERED, 5, false));
  EXPECT_EQ(order.Get(7), TaskItem(PUMPS, 1, false));
  EXPECT_EQ(order.Get(8), TaskItem(ORDERED, 2, true));
  EXPECT_EQ(order.Get(9), TaskItem(ORDERED, 2, false));
  EXPECT_EQ(order.Get(10), TaskItem(QUITMESSAGELOOP, 6, true));
  EXPECT_EQ(order.Get(11), TaskItem(QUITMESSAGELOOP, 6, false));
}

void FuncThatRuns(TaskList* order, int cookie, RunLoop* run_loop) {
  order->RecordStart(RUNS, cookie);
  {
    MessageLoop::ScopedNestableTaskAllower allow(MessageLoop::current());
    run_loop->Run();
  }
  order->RecordEnd(RUNS, cookie);
}

void FuncThatQuitsNow() {
  MessageLoop::current()->QuitNow();
}
// Tests RunLoopQuit only quits the corresponding MessageLoop::Run.
void RunTest_QuitNow(MessagePumpFactory factory) {
  scoped_ptr<MessagePump> pump(factory());
  MessageLoop loop(pump.Pass());

  TaskList order;

  RunLoop run_loop;

  MessageLoop::current()->PostTask(FROM_HERE,
      Bind(&FuncThatRuns, &order, 1, Unretained(&run_loop)));
  MessageLoop::current()->PostTask(
      FROM_HERE, Bind(&OrderedFunc, &order, 2));
  MessageLoop::current()->PostTask(
      FROM_HERE, Bind(&FuncThatQuitsNow));
  MessageLoop::current()->PostTask(
      FROM_HERE, Bind(&OrderedFunc, &order, 3));
  MessageLoop::current()->PostTask(
      FROM_HERE, Bind(&FuncThatQuitsNow));
  MessageLoop::current()->PostTask(
      FROM_HERE, Bind(&OrderedFunc, &order, 4)); // never runs

  MessageLoop::current()->Run();

  ASSERT_EQ(6U, order.Size());
  int task_index = 0;
  EXPECT_EQ(order.Get(task_index++), TaskItem(RUNS, 1, true));
  EXPECT_EQ(order.Get(task_index++), TaskItem(ORDERED, 2, true));
  EXPECT_EQ(order.Get(task_index++), TaskItem(ORDERED, 2, false));
  EXPECT_EQ(order.Get(task_index++), TaskItem(RUNS, 1, false));
  EXPECT_EQ(order.Get(task_index++), TaskItem(ORDERED, 3, true));
  EXPECT_EQ(order.Get(task_index++), TaskItem(ORDERED, 3, false));
  EXPECT_EQ(static_cast<size_t>(task_index), order.Size());
}

// Tests RunLoopQuit only quits the corresponding MessageLoop::Run.
void RunTest_RunLoopQuitTop(MessagePumpFactory factory) {
  scoped_ptr<MessagePump> pump(factory());
  MessageLoop loop(pump.Pass());

  TaskList order;

  RunLoop outer_run_loop;
  RunLoop nested_run_loop;

  MessageLoop::current()->PostTask(FROM_HERE,
      Bind(&FuncThatRuns, &order, 1, Unretained(&nested_run_loop)));
  MessageLoop::current()->PostTask(
      FROM_HERE, outer_run_loop.QuitClosure());
  MessageLoop::current()->PostTask(
      FROM_HERE, Bind(&OrderedFunc, &order, 2));
  MessageLoop::current()->PostTask(
      FROM_HERE, nested_run_loop.QuitClosure());

  outer_run_loop.Run();

  ASSERT_EQ(4U, order.Size());
  int task_index = 0;
  EXPECT_EQ(order.Get(task_index++), TaskItem(RUNS, 1, true));
  EXPECT_EQ(order.Get(task_index++), TaskItem(ORDERED, 2, true));
  EXPECT_EQ(order.Get(task_index++), TaskItem(ORDERED, 2, false));
  EXPECT_EQ(order.Get(task_index++), TaskItem(RUNS, 1, false));
  EXPECT_EQ(static_cast<size_t>(task_index), order.Size());
}

// Tests RunLoopQuit only quits the corresponding MessageLoop::Run.
void RunTest_RunLoopQuitNested(MessagePumpFactory factory) {
  scoped_ptr<MessagePump> pump(factory());
  MessageLoop loop(pump.Pass());

  TaskList order;

  RunLoop outer_run_loop;
  RunLoop nested_run_loop;

  MessageLoop::current()->PostTask(FROM_HERE,
      Bind(&FuncThatRuns, &order, 1, Unretained(&nested_run_loop)));
  MessageLoop::current()->PostTask(
      FROM_HERE, nested_run_loop.QuitClosure());
  MessageLoop::current()->PostTask(
      FROM_HERE, Bind(&OrderedFunc, &order, 2));
  MessageLoop::current()->PostTask(
      FROM_HERE, outer_run_loop.QuitClosure());

  outer_run_loop.Run();

  ASSERT_EQ(4U, order.Size());
  int task_index = 0;
  EXPECT_EQ(order.Get(task_index++), TaskItem(RUNS, 1, true));
  EXPECT_EQ(order.Get(task_index++), TaskItem(RUNS, 1, false));
  EXPECT_EQ(order.Get(task_index++), TaskItem(ORDERED, 2, true));
  EXPECT_EQ(order.Get(task_index++), TaskItem(ORDERED, 2, false));
  EXPECT_EQ(static_cast<size_t>(task_index), order.Size());
}

// Tests RunLoopQuit only quits the corresponding MessageLoop::Run.
void RunTest_RunLoopQuitBogus(MessagePumpFactory factory) {
  scoped_ptr<MessagePump> pump(factory());
  MessageLoop loop(pump.Pass());

  TaskList order;

  RunLoop outer_run_loop;
  RunLoop nested_run_loop;
  RunLoop bogus_run_loop;

  MessageLoop::current()->PostTask(FROM_HERE,
      Bind(&FuncThatRuns, &order, 1, Unretained(&nested_run_loop)));
  MessageLoop::current()->PostTask(
      FROM_HERE, bogus_run_loop.QuitClosure());
  MessageLoop::current()->PostTask(
      FROM_HERE, Bind(&OrderedFunc, &order, 2));
  MessageLoop::current()->PostTask(
      FROM_HERE, outer_run_loop.QuitClosure());
  MessageLoop::current()->PostTask(
      FROM_HERE, nested_run_loop.QuitClosure());

  outer_run_loop.Run();

  ASSERT_EQ(4U, order.Size());
  int task_index = 0;
  EXPECT_EQ(order.Get(task_index++), TaskItem(RUNS, 1, true));
  EXPECT_EQ(order.Get(task_index++), TaskItem(ORDERED, 2, true));
  EXPECT_EQ(order.Get(task_index++), TaskItem(ORDERED, 2, false));
  EXPECT_EQ(order.Get(task_index++), TaskItem(RUNS, 1, false));
  EXPECT_EQ(static_cast<size_t>(task_index), order.Size());
}

// Tests RunLoopQuit only quits the corresponding MessageLoop::Run.
void RunTest_RunLoopQuitDeep(MessagePumpFactory factory) {
  scoped_ptr<MessagePump> pump(factory());
  MessageLoop loop(pump.Pass());

  TaskList order;

  RunLoop outer_run_loop;
  RunLoop nested_loop1;
  RunLoop nested_loop2;
  RunLoop nested_loop3;
  RunLoop nested_loop4;

  MessageLoop::current()->PostTask(FROM_HERE,
      Bind(&FuncThatRuns, &order, 1, Unretained(&nested_loop1)));
  MessageLoop::current()->PostTask(FROM_HERE,
      Bind(&FuncThatRuns, &order, 2, Unretained(&nested_loop2)));
  MessageLoop::current()->PostTask(FROM_HERE,
      Bind(&FuncThatRuns, &order, 3, Unretained(&nested_loop3)));
  MessageLoop::current()->PostTask(FROM_HERE,
      Bind(&FuncThatRuns, &order, 4, Unretained(&nested_loop4)));
  MessageLoop::current()->PostTask(
      FROM_HERE, Bind(&OrderedFunc, &order, 5));
  MessageLoop::current()->PostTask(
      FROM_HERE, outer_run_loop.QuitClosure());
  MessageLoop::current()->PostTask(
      FROM_HERE, Bind(&OrderedFunc, &order, 6));
  MessageLoop::current()->PostTask(
      FROM_HERE, nested_loop1.QuitClosure());
  MessageLoop::current()->PostTask(
      FROM_HERE, Bind(&OrderedFunc, &order, 7));
  MessageLoop::current()->PostTask(
      FROM_HERE, nested_loop2.QuitClosure());
  MessageLoop::current()->PostTask(
      FROM_HERE, Bind(&OrderedFunc, &order, 8));
  MessageLoop::current()->PostTask(
      FROM_HERE, nested_loop3.QuitClosure());
  MessageLoop::current()->PostTask(
      FROM_HERE, Bind(&OrderedFunc, &order, 9));
  MessageLoop::current()->PostTask(
      FROM_HERE, nested_loop4.QuitClosure());
  MessageLoop::current()->PostTask(
      FROM_HERE, Bind(&OrderedFunc, &order, 10));

  outer_run_loop.Run();

  ASSERT_EQ(18U, order.Size());
  int task_index = 0;
  EXPECT_EQ(order.Get(task_index++), TaskItem(RUNS, 1, true));
  EXPECT_EQ(order.Get(task_index++), TaskItem(RUNS, 2, true));
  EXPECT_EQ(order.Get(task_index++), TaskItem(RUNS, 3, true));
  EXPECT_EQ(order.Get(task_index++), TaskItem(RUNS, 4, true));
  EXPECT_EQ(order.Get(task_index++), TaskItem(ORDERED, 5, true));
  EXPECT_EQ(order.Get(task_index++), TaskItem(ORDERED, 5, false));
  EXPECT_EQ(order.Get(task_index++), TaskItem(ORDERED, 6, true));
  EXPECT_EQ(order.Get(task_index++), TaskItem(ORDERED, 6, false));
  EXPECT_EQ(order.Get(task_index++), TaskItem(ORDERED, 7, true));
  EXPECT_EQ(order.Get(task_index++), TaskItem(ORDERED, 7, false));
  EXPECT_EQ(order.Get(task_index++), TaskItem(ORDERED, 8, true));
  EXPECT_EQ(order.Get(task_index++), TaskItem(ORDERED, 8, false));
  EXPECT_EQ(order.Get(task_index++), TaskItem(ORDERED, 9, true));
  EXPECT_EQ(order.Get(task_index++), TaskItem(ORDERED, 9, false));
  EXPECT_EQ(order.Get(task_index++), TaskItem(RUNS, 4, false));
  EXPECT_EQ(order.Get(task_index++), TaskItem(RUNS, 3, false));
  EXPECT_EQ(order.Get(task_index++), TaskItem(RUNS, 2, false));
  EXPECT_EQ(order.Get(task_index++), TaskItem(RUNS, 1, false));
  EXPECT_EQ(static_cast<size_t>(task_index), order.Size());
}

// Tests RunLoopQuit works before RunWithID.
void RunTest_RunLoopQuitOrderBefore(MessagePumpFactory factory) {
  scoped_ptr<MessagePump> pump(factory());
  MessageLoop loop(pump.Pass());

  TaskList order;

  RunLoop run_loop;

  run_loop.Quit();

  MessageLoop::current()->PostTask(
      FROM_HERE, Bind(&OrderedFunc, &order, 1)); // never runs
  MessageLoop::current()->PostTask(
      FROM_HERE, Bind(&FuncThatQuitsNow)); // never runs

  run_loop.Run();

  ASSERT_EQ(0U, order.Size());
}

// Tests RunLoopQuit works during RunWithID.
void RunTest_RunLoopQuitOrderDuring(MessagePumpFactory factory) {
  scoped_ptr<MessagePump> pump(factory());
  MessageLoop loop(pump.Pass());

  TaskList order;

  RunLoop run_loop;

  MessageLoop::current()->PostTask(
      FROM_HERE, Bind(&OrderedFunc, &order, 1));
  MessageLoop::current()->PostTask(
      FROM_HERE, run_loop.QuitClosure());
  MessageLoop::current()->PostTask(
      FROM_HERE, Bind(&OrderedFunc, &order, 2)); // never runs
  MessageLoop::current()->PostTask(
      FROM_HERE, Bind(&FuncThatQuitsNow)); // never runs

  run_loop.Run();

  ASSERT_EQ(2U, order.Size());
  int task_index = 0;
  EXPECT_EQ(order.Get(task_index++), TaskItem(ORDERED, 1, true));
  EXPECT_EQ(order.Get(task_index++), TaskItem(ORDERED, 1, false));
  EXPECT_EQ(static_cast<size_t>(task_index), order.Size());
}

// Tests RunLoopQuit works after RunWithID.
void RunTest_RunLoopQuitOrderAfter(MessagePumpFactory factory) {
  scoped_ptr<MessagePump> pump(factory());
  MessageLoop loop(pump.Pass());

  TaskList order;

  RunLoop run_loop;

  MessageLoop::current()->PostTask(FROM_HERE,
      Bind(&FuncThatRuns, &order, 1, Unretained(&run_loop)));
  MessageLoop::current()->PostTask(
      FROM_HERE, Bind(&OrderedFunc, &order, 2));
  MessageLoop::current()->PostTask(
      FROM_HERE, Bind(&FuncThatQuitsNow));
  MessageLoop::current()->PostTask(
      FROM_HERE, Bind(&OrderedFunc, &order, 3));
  MessageLoop::current()->PostTask(
      FROM_HERE, run_loop.QuitClosure()); // has no affect
  MessageLoop::current()->PostTask(
      FROM_HERE, Bind(&OrderedFunc, &order, 4));
  MessageLoop::current()->PostTask(
      FROM_HERE, Bind(&FuncThatQuitsNow));

  RunLoop outer_run_loop;
  outer_run_loop.Run();

  ASSERT_EQ(8U, order.Size());
  int task_index = 0;
  EXPECT_EQ(order.Get(task_index++), TaskItem(RUNS, 1, true));
  EXPECT_EQ(order.Get(task_index++), TaskItem(ORDERED, 2, true));
  EXPECT_EQ(order.Get(task_index++), TaskItem(ORDERED, 2, false));
  EXPECT_EQ(order.Get(task_index++), TaskItem(RUNS, 1, false));
  EXPECT_EQ(order.Get(task_index++), TaskItem(ORDERED, 3, true));
  EXPECT_EQ(order.Get(task_index++), TaskItem(ORDERED, 3, false));
  EXPECT_EQ(order.Get(task_index++), TaskItem(ORDERED, 4, true));
  EXPECT_EQ(order.Get(task_index++), TaskItem(ORDERED, 4, false));
  EXPECT_EQ(static_cast<size_t>(task_index), order.Size());
}

void PostNTasksThenQuit(int posts_remaining) {
  if (posts_remaining > 1) {
    MessageLoop::current()->PostTask(
        FROM_HERE,
        Bind(&PostNTasksThenQuit, posts_remaining - 1));
  } else {
    MessageLoop::current()->QuitWhenIdle();
  }
}

// There was a bug in the MessagePumpGLib where posting tasks recursively
// caused the message loop to hang, due to the buffer of the internal pipe
// becoming full. Test all MessageLoop types to ensure this issue does not
// exist in other MessagePumps.
//
// On Linux, the pipe buffer size is 64KiB by default. The bug caused one
// byte accumulated in the pipe per two posts, so we should repeat 128K
// times to reproduce the bug.
void RunTest_RecursivePosts(MessagePumpFactory factory) {
  const int kNumTimes = 1 << 17;
  scoped_ptr<MessagePump> pump(factory());
  MessageLoop loop(pump.Pass());
  loop.PostTask(FROM_HERE, Bind(&PostNTasksThenQuit, kNumTimes));
  loop.Run();
}

}  // namespace test
}  // namespace base
