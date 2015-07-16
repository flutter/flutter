// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/message_loop/message_pump_win.h"

#include <limits>
#include <math.h>

#include "base/message_loop/message_loop.h"
#include "base/metrics/histogram.h"
#include "base/process/memory.h"
#include "base/profiler/scoped_tracker.h"
#include "base/strings/stringprintf.h"
#include "base/trace_event/trace_event.h"
#include "base/win/wrapped_window_proc.h"

namespace base {

namespace {

enum MessageLoopProblems {
  MESSAGE_POST_ERROR,
  COMPLETION_POST_ERROR,
  SET_TIMER_ERROR,
  MESSAGE_LOOP_PROBLEM_MAX,
};

}  // namespace

static const wchar_t kWndClassFormat[] = L"Chrome_MessagePumpWindow_%p";

// Message sent to get an additional time slice for pumping (processing) another
// task (a series of such messages creates a continuous task pump).
static const int kMsgHaveWork = WM_USER + 1;

//-----------------------------------------------------------------------------
// MessagePumpWin public:

void MessagePumpWin::RunWithDispatcher(
    Delegate* delegate, MessagePumpDispatcher* dispatcher) {
  RunState s;
  s.delegate = delegate;
  s.dispatcher = dispatcher;
  s.should_quit = false;
  s.run_depth = state_ ? state_->run_depth + 1 : 1;

  RunState* previous_state = state_;
  state_ = &s;

  DoRunLoop();

  state_ = previous_state;
}

void MessagePumpWin::Run(Delegate* delegate) {
  RunWithDispatcher(delegate, NULL);
}

void MessagePumpWin::Quit() {
  DCHECK(state_);
  state_->should_quit = true;
}

//-----------------------------------------------------------------------------
// MessagePumpWin protected:

int MessagePumpWin::GetCurrentDelay() const {
  if (delayed_work_time_.is_null())
    return -1;

  // Be careful here.  TimeDelta has a precision of microseconds, but we want a
  // value in milliseconds.  If there are 5.5ms left, should the delay be 5 or
  // 6?  It should be 6 to avoid executing delayed work too early.
  double timeout =
      ceil((delayed_work_time_ - TimeTicks::Now()).InMillisecondsF());

  // Range check the |timeout| while converting to an integer.  If the |timeout|
  // is negative, then we need to run delayed work soon.  If the |timeout| is
  // "overflowingly" large, that means a delayed task was posted with a
  // super-long delay.
  return timeout < 0 ? 0 :
      (timeout > std::numeric_limits<int>::max() ?
       std::numeric_limits<int>::max() : static_cast<int>(timeout));
}

//-----------------------------------------------------------------------------
// MessagePumpForUI public:

MessagePumpForUI::MessagePumpForUI()
    : atom_(0) {
  InitMessageWnd();
}

MessagePumpForUI::~MessagePumpForUI() {
  DestroyWindow(message_hwnd_);
  UnregisterClass(MAKEINTATOM(atom_),
                  GetModuleFromAddress(&WndProcThunk));
}

void MessagePumpForUI::ScheduleWork() {
  if (InterlockedExchange(&have_work_, 1))
    return;  // Someone else continued the pumping.

  // Make sure the MessagePump does some work for us.
  BOOL ret = PostMessage(message_hwnd_, kMsgHaveWork,
                         reinterpret_cast<WPARAM>(this), 0);
  if (ret)
    return;  // There was room in the Window Message queue.

  // We have failed to insert a have-work message, so there is a chance that we
  // will starve tasks/timers while sitting in a nested message loop.  Nested
  // loops only look at Windows Message queues, and don't look at *our* task
  // queues, etc., so we might not get a time slice in such. :-(
  // We could abort here, but the fear is that this failure mode is plausibly
  // common (queue is full, of about 2000 messages), so we'll do a near-graceful
  // recovery.  Nested loops are pretty transient (we think), so this will
  // probably be recoverable.
  InterlockedExchange(&have_work_, 0);  // Clarify that we didn't really insert.
  UMA_HISTOGRAM_ENUMERATION("Chrome.MessageLoopProblem", MESSAGE_POST_ERROR,
                            MESSAGE_LOOP_PROBLEM_MAX);
}

void MessagePumpForUI::ScheduleDelayedWork(const TimeTicks& delayed_work_time) {
  delayed_work_time_ = delayed_work_time;
  RescheduleTimer();
}

//-----------------------------------------------------------------------------
// MessagePumpForUI private:

// static
LRESULT CALLBACK MessagePumpForUI::WndProcThunk(
    HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam) {
  // TODO(vadimt): Remove ScopedTracker below once crbug.com/440919 is fixed.
  tracked_objects::ScopedTracker tracking_profile1(
      FROM_HERE_WITH_EXPLICIT_FUNCTION(
          "440919 MessagePumpForUI::WndProcThunk1"));

  switch (message) {
    case kMsgHaveWork:
      reinterpret_cast<MessagePumpForUI*>(wparam)->HandleWorkMessage();
      break;
    case WM_TIMER:
      reinterpret_cast<MessagePumpForUI*>(wparam)->HandleTimerMessage();
      break;
  }

  // TODO(vadimt): Remove ScopedTracker below once crbug.com/440919 is fixed.
  tracked_objects::ScopedTracker tracking_profile2(
      FROM_HERE_WITH_EXPLICIT_FUNCTION(
          "440919 MessagePumpForUI::WndProcThunk2"));

  return DefWindowProc(hwnd, message, wparam, lparam);
}

void MessagePumpForUI::DoRunLoop() {
  // IF this was just a simple PeekMessage() loop (servicing all possible work
  // queues), then Windows would try to achieve the following order according
  // to MSDN documentation about PeekMessage with no filter):
  //    * Sent messages
  //    * Posted messages
  //    * Sent messages (again)
  //    * WM_PAINT messages
  //    * WM_TIMER messages
  //
  // Summary: none of the above classes is starved, and sent messages has twice
  // the chance of being processed (i.e., reduced service time).

  for (;;) {
    // If we do any work, we may create more messages etc., and more work may
    // possibly be waiting in another task group.  When we (for example)
    // ProcessNextWindowsMessage(), there is a good chance there are still more
    // messages waiting.  On the other hand, when any of these methods return
    // having done no work, then it is pretty unlikely that calling them again
    // quickly will find any work to do.  Finally, if they all say they had no
    // work, then it is a good time to consider sleeping (waiting) for more
    // work.

    bool more_work_is_plausible = ProcessNextWindowsMessage();
    if (state_->should_quit)
      break;

    more_work_is_plausible |= state_->delegate->DoWork();
    if (state_->should_quit)
      break;

    more_work_is_plausible |=
        state_->delegate->DoDelayedWork(&delayed_work_time_);
    // If we did not process any delayed work, then we can assume that our
    // existing WM_TIMER if any will fire when delayed work should run.  We
    // don't want to disturb that timer if it is already in flight.  However,
    // if we did do all remaining delayed work, then lets kill the WM_TIMER.
    if (more_work_is_plausible && delayed_work_time_.is_null())
      KillTimer(message_hwnd_, reinterpret_cast<UINT_PTR>(this));
    if (state_->should_quit)
      break;

    if (more_work_is_plausible)
      continue;

    more_work_is_plausible = state_->delegate->DoIdleWork();
    if (state_->should_quit)
      break;

    if (more_work_is_plausible)
      continue;

    WaitForWork();  // Wait (sleep) until we have work to do again.
  }
}

void MessagePumpForUI::InitMessageWnd() {
  // Generate a unique window class name.
  string16 class_name = StringPrintf(kWndClassFormat, this);

  HINSTANCE instance = GetModuleFromAddress(&WndProcThunk);
  WNDCLASSEX wc = {0};
  wc.cbSize = sizeof(wc);
  wc.lpfnWndProc = base::win::WrappedWindowProc<WndProcThunk>;
  wc.hInstance = instance;
  wc.lpszClassName = class_name.c_str();
  atom_ = RegisterClassEx(&wc);
  DCHECK(atom_);

  message_hwnd_ = CreateWindow(MAKEINTATOM(atom_), 0, 0, 0, 0, 0, 0,
                               HWND_MESSAGE, 0, instance, 0);
  DCHECK(message_hwnd_);
}

void MessagePumpForUI::WaitForWork() {
  // Wait until a message is available, up to the time needed by the timer
  // manager to fire the next set of timers.
  int delay = GetCurrentDelay();
  if (delay < 0)  // Negative value means no timers waiting.
    delay = INFINITE;

  DWORD result;
  result = MsgWaitForMultipleObjectsEx(0, NULL, delay, QS_ALLINPUT,
                                       MWMO_INPUTAVAILABLE);

  if (WAIT_OBJECT_0 == result) {
    // A WM_* message is available.
    // If a parent child relationship exists between windows across threads
    // then their thread inputs are implicitly attached.
    // This causes the MsgWaitForMultipleObjectsEx API to return indicating
    // that messages are ready for processing (Specifically, mouse messages
    // intended for the child window may appear if the child window has
    // capture).
    // The subsequent PeekMessages call may fail to return any messages thus
    // causing us to enter a tight loop at times.
    // The WaitMessage call below is a workaround to give the child window
    // some time to process its input messages.
    MSG msg = {0};
    DWORD queue_status = GetQueueStatus(QS_MOUSE);
    if (HIWORD(queue_status) & QS_MOUSE &&
        !PeekMessage(&msg, NULL, WM_MOUSEFIRST, WM_MOUSELAST, PM_NOREMOVE)) {
      WaitMessage();
    }
    return;
  }

  DCHECK_NE(WAIT_FAILED, result) << GetLastError();
}

void MessagePumpForUI::HandleWorkMessage() {
  // If we are being called outside of the context of Run, then don't try to do
  // any work.  This could correspond to a MessageBox call or something of that
  // sort.
  if (!state_) {
    // Since we handled a kMsgHaveWork message, we must still update this flag.
    InterlockedExchange(&have_work_, 0);
    return;
  }

  // Let whatever would have run had we not been putting messages in the queue
  // run now.  This is an attempt to make our dummy message not starve other
  // messages that may be in the Windows message queue.
  ProcessPumpReplacementMessage();

  // Now give the delegate a chance to do some work.  He'll let us know if he
  // needs to do more work.
  if (state_->delegate->DoWork())
    ScheduleWork();
  state_->delegate->DoDelayedWork(&delayed_work_time_);
  RescheduleTimer();
}

void MessagePumpForUI::HandleTimerMessage() {
  KillTimer(message_hwnd_, reinterpret_cast<UINT_PTR>(this));

  // If we are being called outside of the context of Run, then don't do
  // anything.  This could correspond to a MessageBox call or something of
  // that sort.
  if (!state_)
    return;

  state_->delegate->DoDelayedWork(&delayed_work_time_);
  RescheduleTimer();
}

void MessagePumpForUI::RescheduleTimer() {
  if (delayed_work_time_.is_null())
    return;
  //
  // We would *like* to provide high resolution timers.  Windows timers using
  // SetTimer() have a 10ms granularity.  We have to use WM_TIMER as a wakeup
  // mechanism because the application can enter modal windows loops where it
  // is not running our MessageLoop; the only way to have our timers fire in
  // these cases is to post messages there.
  //
  // To provide sub-10ms timers, we process timers directly from our run loop.
  // For the common case, timers will be processed there as the run loop does
  // its normal work.  However, we *also* set the system timer so that WM_TIMER
  // events fire.  This mops up the case of timers not being able to work in
  // modal message loops.  It is possible for the SetTimer to pop and have no
  // pending timers, because they could have already been processed by the
  // run loop itself.
  //
  // We use a single SetTimer corresponding to the timer that will expire
  // soonest.  As new timers are created and destroyed, we update SetTimer.
  // Getting a spurrious SetTimer event firing is benign, as we'll just be
  // processing an empty timer queue.
  //
  int delay_msec = GetCurrentDelay();
  DCHECK_GE(delay_msec, 0);
  if (delay_msec == 0) {
    ScheduleWork();
  } else {
    if (delay_msec < USER_TIMER_MINIMUM)
      delay_msec = USER_TIMER_MINIMUM;

    // Create a WM_TIMER event that will wake us up to check for any pending
    // timers (in case we are running within a nested, external sub-pump).
    BOOL ret = SetTimer(message_hwnd_, reinterpret_cast<UINT_PTR>(this),
                        delay_msec, NULL);
    if (ret)
      return;
    // If we can't set timers, we are in big trouble... but cross our fingers
    // for now.
    // TODO(jar): If we don't see this error, use a CHECK() here instead.
    UMA_HISTOGRAM_ENUMERATION("Chrome.MessageLoopProblem", SET_TIMER_ERROR,
                              MESSAGE_LOOP_PROBLEM_MAX);
  }
}

bool MessagePumpForUI::ProcessNextWindowsMessage() {
  // TODO(vadimt): Remove ScopedTracker below once crbug.com/440919 is fixed.
  tracked_objects::ScopedTracker tracking_profile1(
      FROM_HERE_WITH_EXPLICIT_FUNCTION(
          "440919 MessagePumpForUI::ProcessNextWindowsMessage1"));

  // If there are sent messages in the queue then PeekMessage internally
  // dispatches the message and returns false. We return true in this
  // case to ensure that the message loop peeks again instead of calling
  // MsgWaitForMultipleObjectsEx again.
  bool sent_messages_in_queue = false;
  DWORD queue_status = GetQueueStatus(QS_SENDMESSAGE);
  if (HIWORD(queue_status) & QS_SENDMESSAGE)
    sent_messages_in_queue = true;

  // TODO(vadimt): Remove ScopedTracker below once crbug.com/440919 is fixed.
  tracked_objects::ScopedTracker tracking_profile2(
      FROM_HERE_WITH_EXPLICIT_FUNCTION(
          "440919 MessagePumpForUI::ProcessNextWindowsMessage2"));

  MSG msg;
  if (PeekMessage(&msg, NULL, 0, 0, PM_REMOVE) != FALSE)
    return ProcessMessageHelper(msg);

  return sent_messages_in_queue;
}

bool MessagePumpForUI::ProcessMessageHelper(const MSG& msg) {
  TRACE_EVENT1("base", "MessagePumpForUI::ProcessMessageHelper",
               "message", msg.message);
  if (WM_QUIT == msg.message) {
    // Repost the QUIT message so that it will be retrieved by the primary
    // GetMessage() loop.
    state_->should_quit = true;
    PostQuitMessage(static_cast<int>(msg.wParam));
    return false;
  }

  // While running our main message pump, we discard kMsgHaveWork messages.
  if (msg.message == kMsgHaveWork && msg.hwnd == message_hwnd_)
    return ProcessPumpReplacementMessage();

  if (CallMsgFilter(const_cast<MSG*>(&msg), kMessageFilterCode))
    return true;

  uint32_t action = MessagePumpDispatcher::POST_DISPATCH_PERFORM_DEFAULT;
  if (state_->dispatcher) {
    // TODO(vadimt): Remove ScopedTracker below once crbug.com/440919 is fixed.
    tracked_objects::ScopedTracker tracking_profile4(
        FROM_HERE_WITH_EXPLICIT_FUNCTION(
            "440919 MessagePumpForUI::ProcessMessageHelper4"));

    action = state_->dispatcher->Dispatch(msg);
  }
  if (action & MessagePumpDispatcher::POST_DISPATCH_QUIT_LOOP)
    state_->should_quit = true;
  if (action & MessagePumpDispatcher::POST_DISPATCH_PERFORM_DEFAULT) {
    TranslateMessage(&msg);
    DispatchMessage(&msg);
  }

  return true;
}

bool MessagePumpForUI::ProcessPumpReplacementMessage() {
  // When we encounter a kMsgHaveWork message, this method is called to peek
  // and process a replacement message, such as a WM_PAINT or WM_TIMER.  The
  // goal is to make the kMsgHaveWork as non-intrusive as possible, even though
  // a continuous stream of such messages are posted.  This method carefully
  // peeks a message while there is no chance for a kMsgHaveWork to be pending,
  // then resets the have_work_ flag (allowing a replacement kMsgHaveWork to
  // possibly be posted), and finally dispatches that peeked replacement.  Note
  // that the re-post of kMsgHaveWork may be asynchronous to this thread!!

  bool have_message = false;
  MSG msg;
  // We should not process all window messages if we are in the context of an
  // OS modal loop, i.e. in the context of a windows API call like MessageBox.
  // This is to ensure that these messages are peeked out by the OS modal loop.
  if (MessageLoop::current()->os_modal_loop()) {
    // We only peek out WM_PAINT and WM_TIMER here for reasons mentioned above.
    have_message = PeekMessage(&msg, NULL, WM_PAINT, WM_PAINT, PM_REMOVE) ||
                   PeekMessage(&msg, NULL, WM_TIMER, WM_TIMER, PM_REMOVE);
  } else {
    have_message = PeekMessage(&msg, NULL, 0, 0, PM_REMOVE) != FALSE;
  }

  DCHECK(!have_message || kMsgHaveWork != msg.message ||
         msg.hwnd != message_hwnd_);

  // Since we discarded a kMsgHaveWork message, we must update the flag.
  int old_have_work = InterlockedExchange(&have_work_, 0);
  DCHECK(old_have_work);

  // We don't need a special time slice if we didn't have_message to process.
  if (!have_message)
    return false;

  // Guarantee we'll get another time slice in the case where we go into native
  // windows code.   This ScheduleWork() may hurt performance a tiny bit when
  // tasks appear very infrequently, but when the event queue is busy, the
  // kMsgHaveWork events get (percentage wise) rarer and rarer.
  ScheduleWork();
  return ProcessMessageHelper(msg);
}

//-----------------------------------------------------------------------------
// MessagePumpForIO public:

MessagePumpForIO::MessagePumpForIO() {
  port_.Set(CreateIoCompletionPort(INVALID_HANDLE_VALUE, NULL, NULL, 1));
  DCHECK(port_.IsValid());
}

MessagePumpForIO::~MessagePumpForIO() {
}

void MessagePumpForIO::ScheduleWork() {
  if (InterlockedExchange(&have_work_, 1))
    return;  // Someone else continued the pumping.

  // Make sure the MessagePump does some work for us.
  BOOL ret = PostQueuedCompletionStatus(port_.Get(), 0,
                                        reinterpret_cast<ULONG_PTR>(this),
                                        reinterpret_cast<OVERLAPPED*>(this));
  if (ret)
    return;  // Post worked perfectly.

  // See comment in MessagePumpForUI::ScheduleWork() for this error recovery.
  InterlockedExchange(&have_work_, 0);  // Clarify that we didn't succeed.
  UMA_HISTOGRAM_ENUMERATION("Chrome.MessageLoopProblem", COMPLETION_POST_ERROR,
                            MESSAGE_LOOP_PROBLEM_MAX);
}

void MessagePumpForIO::ScheduleDelayedWork(const TimeTicks& delayed_work_time) {
  // We know that we can't be blocked right now since this method can only be
  // called on the same thread as Run, so we only need to update our record of
  // how long to sleep when we do sleep.
  delayed_work_time_ = delayed_work_time;
}

void MessagePumpForIO::RegisterIOHandler(HANDLE file_handle,
                                         IOHandler* handler) {
  ULONG_PTR key = HandlerToKey(handler, true);
  HANDLE port = CreateIoCompletionPort(file_handle, port_.Get(), key, 1);
  DPCHECK(port);
}

bool MessagePumpForIO::RegisterJobObject(HANDLE job_handle,
                                         IOHandler* handler) {
  // Job object notifications use the OVERLAPPED pointer to carry the message
  // data. Mark the completion key correspondingly, so we will not try to
  // convert OVERLAPPED* to IOContext*.
  ULONG_PTR key = HandlerToKey(handler, false);
  JOBOBJECT_ASSOCIATE_COMPLETION_PORT info;
  info.CompletionKey = reinterpret_cast<void*>(key);
  info.CompletionPort = port_.Get();
  return SetInformationJobObject(job_handle,
                                 JobObjectAssociateCompletionPortInformation,
                                 &info,
                                 sizeof(info)) != FALSE;
}

//-----------------------------------------------------------------------------
// MessagePumpForIO private:

void MessagePumpForIO::DoRunLoop() {
  for (;;) {
    // If we do any work, we may create more messages etc., and more work may
    // possibly be waiting in another task group.  When we (for example)
    // WaitForIOCompletion(), there is a good chance there are still more
    // messages waiting.  On the other hand, when any of these methods return
    // having done no work, then it is pretty unlikely that calling them
    // again quickly will find any work to do.  Finally, if they all say they
    // had no work, then it is a good time to consider sleeping (waiting) for
    // more work.

    bool more_work_is_plausible = state_->delegate->DoWork();
    if (state_->should_quit)
      break;

    more_work_is_plausible |= WaitForIOCompletion(0, NULL);
    if (state_->should_quit)
      break;

    more_work_is_plausible |=
        state_->delegate->DoDelayedWork(&delayed_work_time_);
    if (state_->should_quit)
      break;

    if (more_work_is_plausible)
      continue;

    more_work_is_plausible = state_->delegate->DoIdleWork();
    if (state_->should_quit)
      break;

    if (more_work_is_plausible)
      continue;

    WaitForWork();  // Wait (sleep) until we have work to do again.
  }
}

// Wait until IO completes, up to the time needed by the timer manager to fire
// the next set of timers.
void MessagePumpForIO::WaitForWork() {
  // We do not support nested IO message loops. This is to avoid messy
  // recursion problems.
  DCHECK_EQ(1, state_->run_depth) << "Cannot nest an IO message loop!";

  int timeout = GetCurrentDelay();
  if (timeout < 0)  // Negative value means no timers waiting.
    timeout = INFINITE;

  WaitForIOCompletion(timeout, NULL);
}

bool MessagePumpForIO::WaitForIOCompletion(DWORD timeout, IOHandler* filter) {
  IOItem item;
  if (completed_io_.empty() || !MatchCompletedIOItem(filter, &item)) {
    // We have to ask the system for another IO completion.
    if (!GetIOItem(timeout, &item))
      return false;

    if (ProcessInternalIOItem(item))
      return true;
  }

  // If |item.has_valid_io_context| is false then |item.context| does not point
  // to a context structure, and so should not be dereferenced, although it may
  // still hold valid non-pointer data.
  if (!item.has_valid_io_context || item.context->handler) {
    if (filter && item.handler != filter) {
      // Save this item for later
      completed_io_.push_back(item);
    } else {
      DCHECK(!item.has_valid_io_context ||
             (item.context->handler == item.handler));
      WillProcessIOEvent();
      item.handler->OnIOCompleted(item.context, item.bytes_transfered,
                                  item.error);
      DidProcessIOEvent();
    }
  } else {
    // The handler must be gone by now, just cleanup the mess.
    delete item.context;
  }
  return true;
}

// Asks the OS for another IO completion result.
bool MessagePumpForIO::GetIOItem(DWORD timeout, IOItem* item) {
  memset(item, 0, sizeof(*item));
  ULONG_PTR key = NULL;
  OVERLAPPED* overlapped = NULL;
  if (!GetQueuedCompletionStatus(port_.Get(), &item->bytes_transfered, &key,
                                 &overlapped, timeout)) {
    if (!overlapped)
      return false;  // Nothing in the queue.
    item->error = GetLastError();
    item->bytes_transfered = 0;
  }

  item->handler = KeyToHandler(key, &item->has_valid_io_context);
  item->context = reinterpret_cast<IOContext*>(overlapped);
  return true;
}

bool MessagePumpForIO::ProcessInternalIOItem(const IOItem& item) {
  if (this == reinterpret_cast<MessagePumpForIO*>(item.context) &&
      this == reinterpret_cast<MessagePumpForIO*>(item.handler)) {
    // This is our internal completion.
    DCHECK(!item.bytes_transfered);
    InterlockedExchange(&have_work_, 0);
    return true;
  }
  return false;
}

// Returns a completion item that was previously received.
bool MessagePumpForIO::MatchCompletedIOItem(IOHandler* filter, IOItem* item) {
  DCHECK(!completed_io_.empty());
  for (std::list<IOItem>::iterator it = completed_io_.begin();
       it != completed_io_.end(); ++it) {
    if (!filter || it->handler == filter) {
      *item = *it;
      completed_io_.erase(it);
      return true;
    }
  }
  return false;
}

void MessagePumpForIO::AddIOObserver(IOObserver *obs) {
  io_observers_.AddObserver(obs);
}

void MessagePumpForIO::RemoveIOObserver(IOObserver *obs) {
  io_observers_.RemoveObserver(obs);
}

void MessagePumpForIO::WillProcessIOEvent() {
  FOR_EACH_OBSERVER(IOObserver, io_observers_, WillProcessIOEvent());
}

void MessagePumpForIO::DidProcessIOEvent() {
  FOR_EACH_OBSERVER(IOObserver, io_observers_, DidProcessIOEvent());
}

// static
ULONG_PTR MessagePumpForIO::HandlerToKey(IOHandler* handler,
                                         bool has_valid_io_context) {
  ULONG_PTR key = reinterpret_cast<ULONG_PTR>(handler);

  // |IOHandler| is at least pointer-size aligned, so the lowest two bits are
  // always cleared. We use the lowest bit to distinguish completion keys with
  // and without the associated |IOContext|.
  DCHECK_EQ(key & 1, 0u);

  // Mark the completion key as context-less.
  if (!has_valid_io_context)
    key = key | 1;
  return key;
}

// static
MessagePumpForIO::IOHandler* MessagePumpForIO::KeyToHandler(
    ULONG_PTR key,
    bool* has_valid_io_context) {
  *has_valid_io_context = ((key & 1) == 0);
  return reinterpret_cast<IOHandler*>(key & ~static_cast<ULONG_PTR>(1));
}

}  // namespace base
