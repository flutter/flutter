// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <vector>

#include "base/bind.h"
#include "base/bind_helpers.h"
#include "base/compiler_specific.h"
#include "base/logging.h"
#include "base/memory/ref_counted.h"
#include "base/message_loop/message_loop.h"
#include "base/message_loop/message_loop_proxy_impl.h"
#include "base/message_loop/message_loop_test.h"
#include "base/pending_task.h"
#include "base/posix/eintr_wrapper.h"
#include "base/run_loop.h"
#include "base/synchronization/waitable_event.h"
#include "base/thread_task_runner_handle.h"
#include "base/threading/platform_thread.h"
#include "base/threading/thread.h"
#include "testing/gtest/include/gtest/gtest.h"

#if defined(OS_WIN)
#include "base/message_loop/message_pump_dispatcher.h"
#include "base/message_loop/message_pump_win.h"
#include "base/process/memory.h"
#include "base/strings/string16.h"
#include "base/win/scoped_handle.h"
#endif

namespace base {

// TODO(darin): Platform-specific MessageLoop tests should be grouped together
// to avoid chopping this file up with so many #ifdefs.

namespace {

scoped_ptr<MessagePump> TypeDefaultMessagePumpFactory() {
  return MessageLoop::CreateMessagePumpForType(MessageLoop::TYPE_DEFAULT);
}

scoped_ptr<MessagePump> TypeIOMessagePumpFactory() {
  return MessageLoop::CreateMessagePumpForType(MessageLoop::TYPE_IO);
}

scoped_ptr<MessagePump> TypeUIMessagePumpFactory() {
  return MessageLoop::CreateMessagePumpForType(MessageLoop::TYPE_UI);
}

class Foo : public RefCounted<Foo> {
 public:
  Foo() : test_count_(0) {
  }

  void Test1ConstRef(const std::string& a) {
    ++test_count_;
    result_.append(a);
  }

  int test_count() const { return test_count_; }
  const std::string& result() const { return result_; }

 private:
  friend class RefCounted<Foo>;

  ~Foo() {}

  int test_count_;
  std::string result_;
};

#if defined(OS_WIN)

// This function runs slowly to simulate a large amount of work being done.
static void SlowFunc(TimeDelta pause, int* quit_counter) {
    PlatformThread::Sleep(pause);
    if (--(*quit_counter) == 0)
      MessageLoop::current()->QuitWhenIdle();
}

// This function records the time when Run was called in a Time object, which is
// useful for building a variety of MessageLoop tests.
static void RecordRunTimeFunc(Time* run_time, int* quit_counter) {
  *run_time = Time::Now();

    // Cause our Run function to take some time to execute.  As a result we can
    // count on subsequent RecordRunTimeFunc()s running at a future time,
    // without worry about the resolution of our system clock being an issue.
  SlowFunc(TimeDelta::FromMilliseconds(10), quit_counter);
}

void SubPumpFunc() {
  MessageLoop::current()->SetNestableTasksAllowed(true);
  MSG msg;
  while (GetMessage(&msg, NULL, 0, 0)) {
    TranslateMessage(&msg);
    DispatchMessage(&msg);
  }
  MessageLoop::current()->QuitWhenIdle();
}

void RunTest_PostDelayedTask_SharedTimer_SubPump() {
  MessageLoop loop(MessageLoop::TYPE_UI);

  // Test that the interval of the timer, used to run the next delayed task, is
  // set to a value corresponding to when the next delayed task should run.

  // By setting num_tasks to 1, we ensure that the first task to run causes the
  // run loop to exit.
  int num_tasks = 1;
  Time run_time;

  loop.PostTask(FROM_HERE, Bind(&SubPumpFunc));

  // This very delayed task should never run.
  loop.PostDelayedTask(
      FROM_HERE,
      Bind(&RecordRunTimeFunc, &run_time, &num_tasks),
      TimeDelta::FromSeconds(1000));

  // This slightly delayed task should run from within SubPumpFunc).
  loop.PostDelayedTask(
      FROM_HERE,
      Bind(&PostQuitMessage, 0),
      TimeDelta::FromMilliseconds(10));

  Time start_time = Time::Now();

  loop.Run();
  EXPECT_EQ(1, num_tasks);

  // Ensure that we ran in far less time than the slower timer.
  TimeDelta total_time = Time::Now() - start_time;
  EXPECT_GT(5000, total_time.InMilliseconds());

  // In case both timers somehow run at nearly the same time, sleep a little
  // and then run all pending to force them both to have run.  This is just
  // encouraging flakiness if there is any.
  PlatformThread::Sleep(TimeDelta::FromMilliseconds(100));
  RunLoop().RunUntilIdle();

  EXPECT_TRUE(run_time.is_null());
}

const wchar_t kMessageBoxTitle[] = L"MessageLoop Unit Test";

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

// Saves the order in which the tasks executed.
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

// MessageLoop implicitly start a "modal message loop". Modal dialog boxes,
// common controls (like OpenFile) and StartDoc printing function can cause
// implicit message loops.
void MessageBoxFunc(TaskList* order, int cookie, bool is_reentrant) {
  order->RecordStart(MESSAGEBOX, cookie);
  if (is_reentrant)
    MessageLoop::current()->SetNestableTasksAllowed(true);
  MessageBox(NULL, L"Please wait...", kMessageBoxTitle, MB_OK);
  order->RecordEnd(MESSAGEBOX, cookie);
}

// Will end the MessageBox.
void EndDialogFunc(TaskList* order, int cookie) {
  order->RecordStart(ENDDIALOG, cookie);
  HWND window = GetActiveWindow();
  if (window != NULL) {
    EXPECT_NE(EndDialog(window, IDCONTINUE), 0);
    // Cheap way to signal that the window wasn't found if RunEnd() isn't
    // called.
    order->RecordEnd(ENDDIALOG, cookie);
  }
}

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

void RecursiveFuncWin(MessageLoop* target,
                      HANDLE event,
                      bool expect_window,
                      TaskList* order,
                      bool is_reentrant) {
  target->PostTask(FROM_HERE,
                   Bind(&RecursiveFunc, order, 1, 2, is_reentrant));
  target->PostTask(FROM_HERE,
                   Bind(&MessageBoxFunc, order, 2, is_reentrant));
  target->PostTask(FROM_HERE,
                   Bind(&RecursiveFunc, order, 3, 2, is_reentrant));
  // The trick here is that for recursive task processing, this task will be
  // ran _inside_ the MessageBox message loop, dismissing the MessageBox
  // without a chance.
  // For non-recursive task processing, this will be executed _after_ the
  // MessageBox will have been dismissed by the code below, where
  // expect_window_ is true.
  target->PostTask(FROM_HERE,
                   Bind(&EndDialogFunc, order, 4));
  target->PostTask(FROM_HERE,
                   Bind(&QuitFunc, order, 5));

  // Enforce that every tasks are sent before starting to run the main thread
  // message loop.
  ASSERT_TRUE(SetEvent(event));

  // Poll for the MessageBox. Don't do this at home! At the speed we do it,
  // you will never realize one MessageBox was shown.
  for (; expect_window;) {
    HWND window = FindWindow(L"#32770", kMessageBoxTitle);
    if (window) {
      // Dismiss it.
      for (;;) {
        HWND button = FindWindowEx(window, NULL, L"Button", NULL);
        if (button != NULL) {
          EXPECT_EQ(0, SendMessage(button, WM_LBUTTONDOWN, 0, 0));
          EXPECT_EQ(0, SendMessage(button, WM_LBUTTONUP, 0, 0));
          break;
        }
      }
      break;
    }
  }
}

// TODO(darin): These tests need to be ported since they test critical
// message loop functionality.

// A side effect of this test is the generation a beep. Sorry.
void RunTest_RecursiveDenial2(MessageLoop::Type message_loop_type) {
  MessageLoop loop(message_loop_type);

  Thread worker("RecursiveDenial2_worker");
  Thread::Options options;
  options.message_loop_type = message_loop_type;
  ASSERT_EQ(true, worker.StartWithOptions(options));
  TaskList order;
  win::ScopedHandle event(CreateEvent(NULL, FALSE, FALSE, NULL));
  worker.message_loop()->PostTask(FROM_HERE,
                                  Bind(&RecursiveFuncWin,
                                             MessageLoop::current(),
                                             event.Get(),
                                             true,
                                             &order,
                                             false));
  // Let the other thread execute.
  WaitForSingleObject(event.Get(), INFINITE);
  MessageLoop::current()->Run();

  ASSERT_EQ(order.Size(), 17);
  EXPECT_EQ(order.Get(0), TaskItem(RECURSIVE, 1, true));
  EXPECT_EQ(order.Get(1), TaskItem(RECURSIVE, 1, false));
  EXPECT_EQ(order.Get(2), TaskItem(MESSAGEBOX, 2, true));
  EXPECT_EQ(order.Get(3), TaskItem(MESSAGEBOX, 2, false));
  EXPECT_EQ(order.Get(4), TaskItem(RECURSIVE, 3, true));
  EXPECT_EQ(order.Get(5), TaskItem(RECURSIVE, 3, false));
  // When EndDialogFunc is processed, the window is already dismissed, hence no
  // "end" entry.
  EXPECT_EQ(order.Get(6), TaskItem(ENDDIALOG, 4, true));
  EXPECT_EQ(order.Get(7), TaskItem(QUITMESSAGELOOP, 5, true));
  EXPECT_EQ(order.Get(8), TaskItem(QUITMESSAGELOOP, 5, false));
  EXPECT_EQ(order.Get(9), TaskItem(RECURSIVE, 1, true));
  EXPECT_EQ(order.Get(10), TaskItem(RECURSIVE, 1, false));
  EXPECT_EQ(order.Get(11), TaskItem(RECURSIVE, 3, true));
  EXPECT_EQ(order.Get(12), TaskItem(RECURSIVE, 3, false));
  EXPECT_EQ(order.Get(13), TaskItem(RECURSIVE, 1, true));
  EXPECT_EQ(order.Get(14), TaskItem(RECURSIVE, 1, false));
  EXPECT_EQ(order.Get(15), TaskItem(RECURSIVE, 3, true));
  EXPECT_EQ(order.Get(16), TaskItem(RECURSIVE, 3, false));
}

// A side effect of this test is the generation a beep. Sorry.  This test also
// needs to process windows messages on the current thread.
void RunTest_RecursiveSupport2(MessageLoop::Type message_loop_type) {
  MessageLoop loop(message_loop_type);

  Thread worker("RecursiveSupport2_worker");
  Thread::Options options;
  options.message_loop_type = message_loop_type;
  ASSERT_EQ(true, worker.StartWithOptions(options));
  TaskList order;
  win::ScopedHandle event(CreateEvent(NULL, FALSE, FALSE, NULL));
  worker.message_loop()->PostTask(FROM_HERE,
                                  Bind(&RecursiveFuncWin,
                                             MessageLoop::current(),
                                             event.Get(),
                                             false,
                                             &order,
                                             true));
  // Let the other thread execute.
  WaitForSingleObject(event.Get(), INFINITE);
  MessageLoop::current()->Run();

  ASSERT_EQ(order.Size(), 18);
  EXPECT_EQ(order.Get(0), TaskItem(RECURSIVE, 1, true));
  EXPECT_EQ(order.Get(1), TaskItem(RECURSIVE, 1, false));
  EXPECT_EQ(order.Get(2), TaskItem(MESSAGEBOX, 2, true));
  // Note that this executes in the MessageBox modal loop.
  EXPECT_EQ(order.Get(3), TaskItem(RECURSIVE, 3, true));
  EXPECT_EQ(order.Get(4), TaskItem(RECURSIVE, 3, false));
  EXPECT_EQ(order.Get(5), TaskItem(ENDDIALOG, 4, true));
  EXPECT_EQ(order.Get(6), TaskItem(ENDDIALOG, 4, false));
  EXPECT_EQ(order.Get(7), TaskItem(MESSAGEBOX, 2, false));
  /* The order can subtly change here. The reason is that when RecursiveFunc(1)
     is called in the main thread, if it is faster than getting to the
     PostTask(FROM_HERE, Bind(&QuitFunc) execution, the order of task
     execution can change. We don't care anyway that the order isn't correct.
  EXPECT_EQ(order.Get(8), TaskItem(QUITMESSAGELOOP, 5, true));
  EXPECT_EQ(order.Get(9), TaskItem(QUITMESSAGELOOP, 5, false));
  EXPECT_EQ(order.Get(10), TaskItem(RECURSIVE, 1, true));
  EXPECT_EQ(order.Get(11), TaskItem(RECURSIVE, 1, false));
  */
  EXPECT_EQ(order.Get(12), TaskItem(RECURSIVE, 3, true));
  EXPECT_EQ(order.Get(13), TaskItem(RECURSIVE, 3, false));
  EXPECT_EQ(order.Get(14), TaskItem(RECURSIVE, 1, true));
  EXPECT_EQ(order.Get(15), TaskItem(RECURSIVE, 1, false));
  EXPECT_EQ(order.Get(16), TaskItem(RECURSIVE, 3, true));
  EXPECT_EQ(order.Get(17), TaskItem(RECURSIVE, 3, false));
}

#endif  // defined(OS_WIN)

void PostNTasksThenQuit(int posts_remaining) {
  if (posts_remaining > 1) {
    MessageLoop::current()->PostTask(
        FROM_HERE,
        Bind(&PostNTasksThenQuit, posts_remaining - 1));
  } else {
    MessageLoop::current()->QuitWhenIdle();
  }
}

#if defined(OS_WIN)

class DispatcherImpl : public MessagePumpDispatcher {
 public:
  DispatcherImpl() : dispatch_count_(0) {}

  uint32_t Dispatch(const NativeEvent& msg) override {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
    // Do not count WM_TIMER since it is not what we post and it will cause
    // flakiness.
    if (msg.message != WM_TIMER)
      ++dispatch_count_;
    // We treat WM_LBUTTONUP as the last message.
    return msg.message == WM_LBUTTONUP ? POST_DISPATCH_QUIT_LOOP
                                       : POST_DISPATCH_NONE;
  }

  int dispatch_count_;
};

void MouseDownUp() {
  PostMessage(NULL, WM_LBUTTONDOWN, 0, 0);
  PostMessage(NULL, WM_LBUTTONUP, 'A', 0);
}

void RunTest_Dispatcher(MessageLoop::Type message_loop_type) {
  MessageLoop loop(message_loop_type);

  MessageLoop::current()->PostDelayedTask(
      FROM_HERE,
      Bind(&MouseDownUp),
      TimeDelta::FromMilliseconds(100));
  DispatcherImpl dispatcher;
  RunLoop run_loop(&dispatcher);
  run_loop.Run();
  ASSERT_EQ(2, dispatcher.dispatch_count_);
}

LRESULT CALLBACK MsgFilterProc(int code, WPARAM wparam, LPARAM lparam) {
  if (code == MessagePumpForUI::kMessageFilterCode) {
    MSG* msg = reinterpret_cast<MSG*>(lparam);
    if (msg->message == WM_LBUTTONDOWN)
      return TRUE;
  }
  return FALSE;
}

void RunTest_DispatcherWithMessageHook(MessageLoop::Type message_loop_type) {
  MessageLoop loop(message_loop_type);

  MessageLoop::current()->PostDelayedTask(
      FROM_HERE,
      Bind(&MouseDownUp),
      TimeDelta::FromMilliseconds(100));
  HHOOK msg_hook = SetWindowsHookEx(WH_MSGFILTER,
                                    MsgFilterProc,
                                    NULL,
                                    GetCurrentThreadId());
  DispatcherImpl dispatcher;
  RunLoop run_loop(&dispatcher);
  run_loop.Run();
  ASSERT_EQ(1, dispatcher.dispatch_count_);
  UnhookWindowsHookEx(msg_hook);
}

class TestIOHandler : public MessageLoopForIO::IOHandler {
 public:
  TestIOHandler(const wchar_t* name, HANDLE signal, bool wait);

  void OnIOCompleted(MessageLoopForIO::IOContext* context,
                     DWORD bytes_transfered,
                     DWORD error) override;

  void Init();
  void WaitForIO();
  OVERLAPPED* context() { return &context_.overlapped; }
  DWORD size() { return sizeof(buffer_); }

 private:
  char buffer_[48];
  MessageLoopForIO::IOContext context_;
  HANDLE signal_;
  win::ScopedHandle file_;
  bool wait_;
};

TestIOHandler::TestIOHandler(const wchar_t* name, HANDLE signal, bool wait)
    : signal_(signal), wait_(wait) {
  memset(buffer_, 0, sizeof(buffer_));
  memset(&context_, 0, sizeof(context_));
  context_.handler = this;

  file_.Set(CreateFile(name, GENERIC_READ, 0, NULL, OPEN_EXISTING,
                       FILE_FLAG_OVERLAPPED, NULL));
  EXPECT_TRUE(file_.IsValid());
}

void TestIOHandler::Init() {
  MessageLoopForIO::current()->RegisterIOHandler(file_.Get(), this);

  DWORD read;
  EXPECT_FALSE(ReadFile(file_.Get(), buffer_, size(), &read, context()));
  EXPECT_EQ(ERROR_IO_PENDING, GetLastError());
  if (wait_)
    WaitForIO();
}

void TestIOHandler::OnIOCompleted(MessageLoopForIO::IOContext* context,
                                  DWORD bytes_transfered, DWORD error) {
  ASSERT_TRUE(context == &context_);
  ASSERT_TRUE(SetEvent(signal_));
}

void TestIOHandler::WaitForIO() {
  EXPECT_TRUE(MessageLoopForIO::current()->WaitForIOCompletion(300, this));
  EXPECT_TRUE(MessageLoopForIO::current()->WaitForIOCompletion(400, this));
}

void RunTest_IOHandler() {
  win::ScopedHandle callback_called(CreateEvent(NULL, TRUE, FALSE, NULL));
  ASSERT_TRUE(callback_called.IsValid());

  const wchar_t* kPipeName = L"\\\\.\\pipe\\iohandler_pipe";
  win::ScopedHandle server(
      CreateNamedPipe(kPipeName, PIPE_ACCESS_OUTBOUND, 0, 1, 0, 0, 0, NULL));
  ASSERT_TRUE(server.IsValid());

  Thread thread("IOHandler test");
  Thread::Options options;
  options.message_loop_type = MessageLoop::TYPE_IO;
  ASSERT_TRUE(thread.StartWithOptions(options));

  MessageLoop* thread_loop = thread.message_loop();
  ASSERT_TRUE(NULL != thread_loop);

  TestIOHandler handler(kPipeName, callback_called.Get(), false);
  thread_loop->PostTask(FROM_HERE, Bind(&TestIOHandler::Init,
                                              Unretained(&handler)));
  // Make sure the thread runs and sleeps for lack of work.
  PlatformThread::Sleep(TimeDelta::FromMilliseconds(100));

  const char buffer[] = "Hello there!";
  DWORD written;
  EXPECT_TRUE(WriteFile(server.Get(), buffer, sizeof(buffer), &written, NULL));

  DWORD result = WaitForSingleObject(callback_called.Get(), 1000);
  EXPECT_EQ(WAIT_OBJECT_0, result);

  thread.Stop();
}

void RunTest_WaitForIO() {
  win::ScopedHandle callback1_called(
      CreateEvent(NULL, TRUE, FALSE, NULL));
  win::ScopedHandle callback2_called(
      CreateEvent(NULL, TRUE, FALSE, NULL));
  ASSERT_TRUE(callback1_called.IsValid());
  ASSERT_TRUE(callback2_called.IsValid());

  const wchar_t* kPipeName1 = L"\\\\.\\pipe\\iohandler_pipe1";
  const wchar_t* kPipeName2 = L"\\\\.\\pipe\\iohandler_pipe2";
  win::ScopedHandle server1(
      CreateNamedPipe(kPipeName1, PIPE_ACCESS_OUTBOUND, 0, 1, 0, 0, 0, NULL));
  win::ScopedHandle server2(
      CreateNamedPipe(kPipeName2, PIPE_ACCESS_OUTBOUND, 0, 1, 0, 0, 0, NULL));
  ASSERT_TRUE(server1.IsValid());
  ASSERT_TRUE(server2.IsValid());

  Thread thread("IOHandler test");
  Thread::Options options;
  options.message_loop_type = MessageLoop::TYPE_IO;
  ASSERT_TRUE(thread.StartWithOptions(options));

  MessageLoop* thread_loop = thread.message_loop();
  ASSERT_TRUE(NULL != thread_loop);

  TestIOHandler handler1(kPipeName1, callback1_called.Get(), false);
  TestIOHandler handler2(kPipeName2, callback2_called.Get(), true);
  thread_loop->PostTask(FROM_HERE, Bind(&TestIOHandler::Init,
                                              Unretained(&handler1)));
  // TODO(ajwong): Do we really need such long Sleeps in ths function?
  // Make sure the thread runs and sleeps for lack of work.
  TimeDelta delay = TimeDelta::FromMilliseconds(100);
  PlatformThread::Sleep(delay);
  thread_loop->PostTask(FROM_HERE, Bind(&TestIOHandler::Init,
                                              Unretained(&handler2)));
  PlatformThread::Sleep(delay);

  // At this time handler1 is waiting to be called, and the thread is waiting
  // on the Init method of handler2, filtering only handler2 callbacks.

  const char buffer[] = "Hello there!";
  DWORD written;
  EXPECT_TRUE(WriteFile(server1.Get(), buffer, sizeof(buffer), &written, NULL));
  PlatformThread::Sleep(2 * delay);
  EXPECT_EQ(WAIT_TIMEOUT, WaitForSingleObject(callback1_called.Get(), 0)) <<
      "handler1 has not been called";

  EXPECT_TRUE(WriteFile(server2.Get(), buffer, sizeof(buffer), &written, NULL));

  HANDLE objects[2] = { callback1_called.Get(), callback2_called.Get() };
  DWORD result = WaitForMultipleObjects(2, objects, TRUE, 1000);
  EXPECT_EQ(WAIT_OBJECT_0, result);

  thread.Stop();
}

#endif  // defined(OS_WIN)

}  // namespace

//-----------------------------------------------------------------------------
// Each test is run against each type of MessageLoop.  That way we are sure
// that message loops work properly in all configurations.  Of course, in some
// cases, a unit test may only be for a particular type of loop.

RUN_MESSAGE_LOOP_TESTS(Default, &TypeDefaultMessagePumpFactory);
RUN_MESSAGE_LOOP_TESTS(UI, &TypeUIMessagePumpFactory);
RUN_MESSAGE_LOOP_TESTS(IO, &TypeIOMessagePumpFactory);

#if defined(OS_WIN)
TEST(MessageLoopTest, PostDelayedTask_SharedTimer_SubPump) {
  RunTest_PostDelayedTask_SharedTimer_SubPump();
}

// This test occasionally hangs http://crbug.com/44567
TEST(MessageLoopTest, DISABLED_RecursiveDenial2) {
  RunTest_RecursiveDenial2(MessageLoop::TYPE_DEFAULT);
  RunTest_RecursiveDenial2(MessageLoop::TYPE_UI);
  RunTest_RecursiveDenial2(MessageLoop::TYPE_IO);
}

TEST(MessageLoopTest, RecursiveSupport2) {
  // This test requires a UI loop
  RunTest_RecursiveSupport2(MessageLoop::TYPE_UI);
}
#endif  // defined(OS_WIN)

class DummyTaskObserver : public MessageLoop::TaskObserver {
 public:
  explicit DummyTaskObserver(int num_tasks)
      : num_tasks_started_(0),
        num_tasks_processed_(0),
        num_tasks_(num_tasks) {}

  ~DummyTaskObserver() override {}

  void WillProcessTask(const PendingTask& pending_task) override {
    num_tasks_started_++;
    EXPECT_LE(num_tasks_started_, num_tasks_);
    EXPECT_EQ(num_tasks_started_, num_tasks_processed_ + 1);
  }

  void DidProcessTask(const PendingTask& pending_task) override {
    num_tasks_processed_++;
    EXPECT_LE(num_tasks_started_, num_tasks_);
    EXPECT_EQ(num_tasks_started_, num_tasks_processed_);
  }

  int num_tasks_started() const { return num_tasks_started_; }
  int num_tasks_processed() const { return num_tasks_processed_; }

 private:
  int num_tasks_started_;
  int num_tasks_processed_;
  const int num_tasks_;

  DISALLOW_COPY_AND_ASSIGN(DummyTaskObserver);
};

TEST(MessageLoopTest, TaskObserver) {
  const int kNumPosts = 6;
  DummyTaskObserver observer(kNumPosts);

  MessageLoop loop;
  loop.AddTaskObserver(&observer);
  loop.PostTask(FROM_HERE, Bind(&PostNTasksThenQuit, kNumPosts));
  loop.Run();
  loop.RemoveTaskObserver(&observer);

  EXPECT_EQ(kNumPosts, observer.num_tasks_started());
  EXPECT_EQ(kNumPosts, observer.num_tasks_processed());
}

#if defined(OS_WIN)
TEST(MessageLoopTest, Dispatcher) {
  // This test requires a UI loop
  RunTest_Dispatcher(MessageLoop::TYPE_UI);
}

TEST(MessageLoopTest, DispatcherWithMessageHook) {
  // This test requires a UI loop
  RunTest_DispatcherWithMessageHook(MessageLoop::TYPE_UI);
}

TEST(MessageLoopTest, IOHandler) {
  RunTest_IOHandler();
}

TEST(MessageLoopTest, WaitForIO) {
  RunTest_WaitForIO();
}

TEST(MessageLoopTest, HighResolutionTimer) {
  MessageLoop loop;
  Time::EnableHighResolutionTimer(true);

  const TimeDelta kFastTimer = TimeDelta::FromMilliseconds(5);
  const TimeDelta kSlowTimer = TimeDelta::FromMilliseconds(100);

  EXPECT_FALSE(loop.HasHighResolutionTasks());
  // Post a fast task to enable the high resolution timers.
  loop.PostDelayedTask(FROM_HERE, Bind(&PostNTasksThenQuit, 1),
                       kFastTimer);
  EXPECT_TRUE(loop.HasHighResolutionTasks());
  loop.Run();
  EXPECT_FALSE(loop.HasHighResolutionTasks());
  EXPECT_FALSE(Time::IsHighResolutionTimerInUse());
  // Check that a slow task does not trigger the high resolution logic.
  loop.PostDelayedTask(FROM_HERE, Bind(&PostNTasksThenQuit, 1),
                       kSlowTimer);
  EXPECT_FALSE(loop.HasHighResolutionTasks());
  loop.Run();
  EXPECT_FALSE(loop.HasHighResolutionTasks());
  Time::EnableHighResolutionTimer(false);
}

#endif  // defined(OS_WIN)

#if defined(OS_POSIX) && !defined(OS_NACL)

namespace {

class QuitDelegate : public MessageLoopForIO::Watcher {
 public:
  void OnFileCanWriteWithoutBlocking(int fd) override {
    MessageLoop::current()->QuitWhenIdle();
  }
  void OnFileCanReadWithoutBlocking(int fd) override {
    MessageLoop::current()->QuitWhenIdle();
  }
};

TEST(MessageLoopTest, FileDescriptorWatcherOutlivesMessageLoop) {
  // Simulate a MessageLoop that dies before an FileDescriptorWatcher.
  // This could happen when people use the Singleton pattern or atexit.

  // Create a file descriptor.  Doesn't need to be readable or writable,
  // as we don't need to actually get any notifications.
  // pipe() is just the easiest way to do it.
  int pipefds[2];
  int err = pipe(pipefds);
  ASSERT_EQ(0, err);
  int fd = pipefds[1];
  {
    // Arrange for controller to live longer than message loop.
    MessageLoopForIO::FileDescriptorWatcher controller;
    {
      MessageLoopForIO message_loop;

      QuitDelegate delegate;
      message_loop.WatchFileDescriptor(fd,
          true, MessageLoopForIO::WATCH_WRITE, &controller, &delegate);
      // and don't run the message loop, just destroy it.
    }
  }
  if (IGNORE_EINTR(close(pipefds[0])) < 0)
    PLOG(ERROR) << "close";
  if (IGNORE_EINTR(close(pipefds[1])) < 0)
    PLOG(ERROR) << "close";
}

TEST(MessageLoopTest, FileDescriptorWatcherDoubleStop) {
  // Verify that it's ok to call StopWatchingFileDescriptor().
  // (Errors only showed up in valgrind.)
  int pipefds[2];
  int err = pipe(pipefds);
  ASSERT_EQ(0, err);
  int fd = pipefds[1];
  {
    // Arrange for message loop to live longer than controller.
    MessageLoopForIO message_loop;
    {
      MessageLoopForIO::FileDescriptorWatcher controller;

      QuitDelegate delegate;
      message_loop.WatchFileDescriptor(fd,
          true, MessageLoopForIO::WATCH_WRITE, &controller, &delegate);
      controller.StopWatchingFileDescriptor();
    }
  }
  if (IGNORE_EINTR(close(pipefds[0])) < 0)
    PLOG(ERROR) << "close";
  if (IGNORE_EINTR(close(pipefds[1])) < 0)
    PLOG(ERROR) << "close";
}

}  // namespace

#endif  // defined(OS_POSIX) && !defined(OS_NACL)

namespace {
// Inject a test point for recording the destructor calls for Closure objects
// send to MessageLoop::PostTask(). It is awkward usage since we are trying to
// hook the actual destruction, which is not a common operation.
class DestructionObserverProbe :
  public RefCounted<DestructionObserverProbe> {
 public:
  DestructionObserverProbe(bool* task_destroyed,
                           bool* destruction_observer_called)
      : task_destroyed_(task_destroyed),
        destruction_observer_called_(destruction_observer_called) {
  }
  virtual void Run() {
    // This task should never run.
    ADD_FAILURE();
  }
 private:
  friend class RefCounted<DestructionObserverProbe>;

  virtual ~DestructionObserverProbe() {
    EXPECT_FALSE(*destruction_observer_called_);
    *task_destroyed_ = true;
  }

  bool* task_destroyed_;
  bool* destruction_observer_called_;
};

class MLDestructionObserver : public MessageLoop::DestructionObserver {
 public:
  MLDestructionObserver(bool* task_destroyed, bool* destruction_observer_called)
      : task_destroyed_(task_destroyed),
        destruction_observer_called_(destruction_observer_called),
        task_destroyed_before_message_loop_(false) {
  }
  void WillDestroyCurrentMessageLoop() override {
    task_destroyed_before_message_loop_ = *task_destroyed_;
    *destruction_observer_called_ = true;
  }
  bool task_destroyed_before_message_loop() const {
    return task_destroyed_before_message_loop_;
  }
 private:
  bool* task_destroyed_;
  bool* destruction_observer_called_;
  bool task_destroyed_before_message_loop_;
};

}  // namespace

TEST(MessageLoopTest, DestructionObserverTest) {
  // Verify that the destruction observer gets called at the very end (after
  // all the pending tasks have been destroyed).
  MessageLoop* loop = new MessageLoop;
  const TimeDelta kDelay = TimeDelta::FromMilliseconds(100);

  bool task_destroyed = false;
  bool destruction_observer_called = false;

  MLDestructionObserver observer(&task_destroyed, &destruction_observer_called);
  loop->AddDestructionObserver(&observer);
  loop->PostDelayedTask(
      FROM_HERE,
      Bind(&DestructionObserverProbe::Run,
                 new DestructionObserverProbe(&task_destroyed,
                                              &destruction_observer_called)),
      kDelay);
  delete loop;
  EXPECT_TRUE(observer.task_destroyed_before_message_loop());
  // The task should have been destroyed when we deleted the loop.
  EXPECT_TRUE(task_destroyed);
  EXPECT_TRUE(destruction_observer_called);
}


// Verify that MessageLoop sets ThreadMainTaskRunner::current() and it
// posts tasks on that message loop.
TEST(MessageLoopTest, ThreadMainTaskRunner) {
  MessageLoop loop;

  scoped_refptr<Foo> foo(new Foo());
  std::string a("a");
  ThreadTaskRunnerHandle::Get()->PostTask(FROM_HERE, Bind(
      &Foo::Test1ConstRef, foo.get(), a));

  // Post quit task;
  MessageLoop::current()->PostTask(FROM_HERE, Bind(
      &MessageLoop::Quit, Unretained(MessageLoop::current())));

  // Now kick things off
  MessageLoop::current()->Run();

  EXPECT_EQ(foo->test_count(), 1);
  EXPECT_EQ(foo->result(), "a");
}

TEST(MessageLoopTest, IsType) {
  MessageLoop loop(MessageLoop::TYPE_UI);
  EXPECT_TRUE(loop.IsType(MessageLoop::TYPE_UI));
  EXPECT_FALSE(loop.IsType(MessageLoop::TYPE_IO));
  EXPECT_FALSE(loop.IsType(MessageLoop::TYPE_DEFAULT));
}

#if defined(OS_WIN)
void EmptyFunction() {}

void PostMultipleTasks() {
  MessageLoop::current()->PostTask(FROM_HERE, base::Bind(&EmptyFunction));
  MessageLoop::current()->PostTask(FROM_HERE, base::Bind(&EmptyFunction));
}

static const int kSignalMsg = WM_USER + 2;

void PostWindowsMessage(HWND message_hwnd) {
  PostMessage(message_hwnd, kSignalMsg, 0, 2);
}

void EndTest(bool* did_run, HWND hwnd) {
  *did_run = true;
  PostMessage(hwnd, WM_CLOSE, 0, 0);
}

int kMyMessageFilterCode = 0x5002;

LRESULT CALLBACK TestWndProcThunk(HWND hwnd, UINT message,
                                  WPARAM wparam, LPARAM lparam) {
  if (message == WM_CLOSE)
    EXPECT_TRUE(DestroyWindow(hwnd));
  if (message != kSignalMsg)
    return DefWindowProc(hwnd, message, wparam, lparam);

  switch (lparam) {
  case 1:
    // First, we post a task that will post multiple no-op tasks to make sure
    // that the pump's incoming task queue does not become empty during the
    // test.
    MessageLoop::current()->PostTask(FROM_HERE, base::Bind(&PostMultipleTasks));
    // Next, we post a task that posts a windows message to trigger the second
    // stage of the test.
    MessageLoop::current()->PostTask(FROM_HERE,
                                     base::Bind(&PostWindowsMessage, hwnd));
    break;
  case 2:
    // Since we're about to enter a modal loop, tell the message loop that we
    // intend to nest tasks.
    MessageLoop::current()->SetNestableTasksAllowed(true);
    bool did_run = false;
    MessageLoop::current()->PostTask(FROM_HERE,
                                     base::Bind(&EndTest, &did_run, hwnd));
    // Run a nested windows-style message loop and verify that our task runs. If
    // it doesn't, then we'll loop here until the test times out.
    MSG msg;
    while (GetMessage(&msg, 0, 0, 0)) {
      if (!CallMsgFilter(&msg, kMyMessageFilterCode))
        DispatchMessage(&msg);
      // If this message is a WM_CLOSE, explicitly exit the modal loop. Posting
      // a WM_QUIT should handle this, but unfortunately MessagePumpWin eats
      // WM_QUIT messages even when running inside a modal loop.
      if (msg.message == WM_CLOSE)
        break;
    }
    EXPECT_TRUE(did_run);
    MessageLoop::current()->Quit();
    break;
  }
  return 0;
}

TEST(MessageLoopTest, AlwaysHaveUserMessageWhenNesting) {
  MessageLoop loop(MessageLoop::TYPE_UI);
  HINSTANCE instance = GetModuleFromAddress(&TestWndProcThunk);
  WNDCLASSEX wc = {0};
  wc.cbSize = sizeof(wc);
  wc.lpfnWndProc = TestWndProcThunk;
  wc.hInstance = instance;
  wc.lpszClassName = L"MessageLoopTest_HWND";
  ATOM atom = RegisterClassEx(&wc);
  ASSERT_TRUE(atom);

  HWND message_hwnd = CreateWindow(MAKEINTATOM(atom), 0, 0, 0, 0, 0, 0,
                                   HWND_MESSAGE, 0, instance, 0);
  ASSERT_TRUE(message_hwnd) << GetLastError();

  ASSERT_TRUE(PostMessage(message_hwnd, kSignalMsg, 0, 1));

  loop.Run();

  ASSERT_TRUE(UnregisterClass(MAKEINTATOM(atom), instance));
}
#endif  // defined(OS_WIN)

}  // namespace base
