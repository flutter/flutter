// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/message_loop/message_pump_libevent.h"

#include <errno.h>
#include <fcntl.h>
#include <unistd.h>

#include "base/auto_reset.h"
#include "base/compiler_specific.h"
#include "base/logging.h"
#include "base/memory/scoped_ptr.h"
#include "base/observer_list.h"
#include "base/posix/eintr_wrapper.h"
#include "base/time/time.h"
#include "base/trace_event/trace_event.h"
#include "third_party/libevent/event.h"

#if defined(OS_MACOSX)
#include "base/mac/scoped_nsautorelease_pool.h"
#endif

// Lifecycle of struct event
// Libevent uses two main data structures:
// struct event_base (of which there is one per message pump), and
// struct event (of which there is roughly one per socket).
// The socket's struct event is created in
// MessagePumpLibevent::WatchFileDescriptor(),
// is owned by the FileDescriptorWatcher, and is destroyed in
// StopWatchingFileDescriptor().
// It is moved into and out of lists in struct event_base by
// the libevent functions event_add() and event_del().
//
// TODO(dkegel):
// At the moment bad things happen if a FileDescriptorWatcher
// is active after its MessagePumpLibevent has been destroyed.
// See MessageLoopTest.FileDescriptorWatcherOutlivesMessageLoop
// Not clear yet whether that situation occurs in practice,
// but if it does, we need to fix it.

namespace base {

// Return 0 on success
// Too small a function to bother putting in a library?
static int SetNonBlocking(int fd) {
  int flags = fcntl(fd, F_GETFL, 0);
  if (flags == -1)
    flags = 0;
  return fcntl(fd, F_SETFL, flags | O_NONBLOCK);
}

MessagePumpLibevent::FileDescriptorWatcher::FileDescriptorWatcher()
    : event_(NULL),
      pump_(NULL),
      watcher_(NULL),
      weak_factory_(this) {
}

MessagePumpLibevent::FileDescriptorWatcher::~FileDescriptorWatcher() {
  if (event_) {
    StopWatchingFileDescriptor();
  }
}

bool MessagePumpLibevent::FileDescriptorWatcher::StopWatchingFileDescriptor() {
  event* e = ReleaseEvent();
  if (e == NULL)
    return true;

  // event_del() is a no-op if the event isn't active.
  int rv = event_del(e);
  delete e;
  pump_ = NULL;
  watcher_ = NULL;
  return (rv == 0);
}

void MessagePumpLibevent::FileDescriptorWatcher::Init(event *e) {
  DCHECK(e);
  DCHECK(!event_);

  event_ = e;
}

event *MessagePumpLibevent::FileDescriptorWatcher::ReleaseEvent() {
  struct event *e = event_;
  event_ = NULL;
  return e;
}

void MessagePumpLibevent::FileDescriptorWatcher::OnFileCanReadWithoutBlocking(
    int fd, MessagePumpLibevent* pump) {
  // Since OnFileCanWriteWithoutBlocking() gets called first, it can stop
  // watching the file descriptor.
  if (!watcher_)
    return;
  pump->WillProcessIOEvent();
  watcher_->OnFileCanReadWithoutBlocking(fd);
  pump->DidProcessIOEvent();
}

void MessagePumpLibevent::FileDescriptorWatcher::OnFileCanWriteWithoutBlocking(
    int fd, MessagePumpLibevent* pump) {
  DCHECK(watcher_);
  pump->WillProcessIOEvent();
  watcher_->OnFileCanWriteWithoutBlocking(fd);
  pump->DidProcessIOEvent();
}

MessagePumpLibevent::MessagePumpLibevent()
    : keep_running_(true),
      in_run_(false),
      processed_io_events_(false),
      event_base_(event_base_new()),
      wakeup_pipe_in_(-1),
      wakeup_pipe_out_(-1) {
  if (!Init())
     NOTREACHED();
}

MessagePumpLibevent::~MessagePumpLibevent() {
  DCHECK(wakeup_event_);
  DCHECK(event_base_);
  event_del(wakeup_event_);
  delete wakeup_event_;
  if (wakeup_pipe_in_ >= 0) {
    if (IGNORE_EINTR(close(wakeup_pipe_in_)) < 0)
      DPLOG(ERROR) << "close";
  }
  if (wakeup_pipe_out_ >= 0) {
    if (IGNORE_EINTR(close(wakeup_pipe_out_)) < 0)
      DPLOG(ERROR) << "close";
  }
  event_base_free(event_base_);
}

bool MessagePumpLibevent::WatchFileDescriptor(int fd,
                                              bool persistent,
                                              int mode,
                                              FileDescriptorWatcher *controller,
                                              Watcher *delegate) {
  DCHECK_GE(fd, 0);
  DCHECK(controller);
  DCHECK(delegate);
  DCHECK(mode == WATCH_READ || mode == WATCH_WRITE || mode == WATCH_READ_WRITE);
  // WatchFileDescriptor should be called on the pump thread. It is not
  // threadsafe, and your watcher may never be registered.
  DCHECK(watch_file_descriptor_caller_checker_.CalledOnValidThread());

  int event_mask = persistent ? EV_PERSIST : 0;
  if (mode & WATCH_READ) {
    event_mask |= EV_READ;
  }
  if (mode & WATCH_WRITE) {
    event_mask |= EV_WRITE;
  }

  scoped_ptr<event> evt(controller->ReleaseEvent());
  if (evt.get() == NULL) {
    // Ownership is transferred to the controller.
    evt.reset(new event);
  } else {
    // Make sure we don't pick up any funky internal libevent masks.
    int old_interest_mask = evt.get()->ev_events &
        (EV_READ | EV_WRITE | EV_PERSIST);

    // Combine old/new event masks.
    event_mask |= old_interest_mask;

    // Must disarm the event before we can reuse it.
    event_del(evt.get());

    // It's illegal to use this function to listen on 2 separate fds with the
    // same |controller|.
    if (EVENT_FD(evt.get()) != fd) {
      NOTREACHED() << "FDs don't match" << EVENT_FD(evt.get()) << "!=" << fd;
      return false;
    }
  }

  // Set current interest mask and message pump for this event.
  event_set(evt.get(), fd, event_mask, OnLibeventNotification, controller);

  // Tell libevent which message pump this socket will belong to when we add it.
  if (event_base_set(event_base_, evt.get())) {
    return false;
  }

  // Add this socket to the list of monitored sockets.
  if (event_add(evt.get(), NULL)) {
    return false;
  }

  // Transfer ownership of evt to controller.
  controller->Init(evt.release());

  controller->set_watcher(delegate);
  controller->set_pump(this);

  return true;
}

void MessagePumpLibevent::AddIOObserver(IOObserver *obs) {
  io_observers_.AddObserver(obs);
}

void MessagePumpLibevent::RemoveIOObserver(IOObserver *obs) {
  io_observers_.RemoveObserver(obs);
}

// Tell libevent to break out of inner loop.
static void timer_callback(int fd, short events, void *context)
{
  event_base_loopbreak((struct event_base *)context);
}

// Reentrant!
void MessagePumpLibevent::Run(Delegate* delegate) {
  AutoReset<bool> auto_reset_keep_running(&keep_running_, true);
  AutoReset<bool> auto_reset_in_run(&in_run_, true);

  // event_base_loopexit() + EVLOOP_ONCE is leaky, see http://crbug.com/25641.
  // Instead, make our own timer and reuse it on each call to event_base_loop().
  scoped_ptr<event> timer_event(new event);

  for (;;) {
#if defined(OS_MACOSX)
    mac::ScopedNSAutoreleasePool autorelease_pool;
#endif

    bool did_work = delegate->DoWork();
    if (!keep_running_)
      break;

    event_base_loop(event_base_, EVLOOP_NONBLOCK);
    did_work |= processed_io_events_;
    processed_io_events_ = false;
    if (!keep_running_)
      break;

    did_work |= delegate->DoDelayedWork(&delayed_work_time_);
    if (!keep_running_)
      break;

    if (did_work)
      continue;

    did_work = delegate->DoIdleWork();
    if (!keep_running_)
      break;

    if (did_work)
      continue;

    // EVLOOP_ONCE tells libevent to only block once,
    // but to service all pending events when it wakes up.
    if (delayed_work_time_.is_null()) {
      event_base_loop(event_base_, EVLOOP_ONCE);
    } else {
      TimeDelta delay = delayed_work_time_ - TimeTicks::Now();
      if (delay > TimeDelta()) {
        struct timeval poll_tv;
        poll_tv.tv_sec = delay.InSeconds();
        poll_tv.tv_usec = delay.InMicroseconds() % Time::kMicrosecondsPerSecond;
        event_set(timer_event.get(), -1, 0, timer_callback, event_base_);
        event_base_set(event_base_, timer_event.get());
        event_add(timer_event.get(), &poll_tv);
        event_base_loop(event_base_, EVLOOP_ONCE);
        event_del(timer_event.get());
      } else {
        // It looks like delayed_work_time_ indicates a time in the past, so we
        // need to call DoDelayedWork now.
        delayed_work_time_ = TimeTicks();
      }
    }

    if (!keep_running_)
      break;
  }
}

void MessagePumpLibevent::Quit() {
  DCHECK(in_run_) << "Quit was called outside of Run!";
  // Tell both libevent and Run that they should break out of their loops.
  keep_running_ = false;
  ScheduleWork();
}

void MessagePumpLibevent::ScheduleWork() {
  // Tell libevent (in a threadsafe way) that it should break out of its loop.
  char buf = 0;
  int nwrite = HANDLE_EINTR(write(wakeup_pipe_in_, &buf, 1));
  DCHECK(nwrite == 1 || errno == EAGAIN)
      << "[nwrite:" << nwrite << "] [errno:" << errno << "]";
}

void MessagePumpLibevent::ScheduleDelayedWork(
    const TimeTicks& delayed_work_time) {
  // We know that we can't be blocked on Wait right now since this method can
  // only be called on the same thread as Run, so we only need to update our
  // record of how long to sleep when we do sleep.
  delayed_work_time_ = delayed_work_time;
}

void MessagePumpLibevent::WillProcessIOEvent() {
  FOR_EACH_OBSERVER(IOObserver, io_observers_, WillProcessIOEvent());
}

void MessagePumpLibevent::DidProcessIOEvent() {
  FOR_EACH_OBSERVER(IOObserver, io_observers_, DidProcessIOEvent());
}

bool MessagePumpLibevent::Init() {
  int fds[2];
  if (pipe(fds)) {
    DLOG(ERROR) << "pipe() failed, errno: " << errno;
    return false;
  }
  if (SetNonBlocking(fds[0])) {
    DLOG(ERROR) << "SetNonBlocking for pipe fd[0] failed, errno: " << errno;
    return false;
  }
  if (SetNonBlocking(fds[1])) {
    DLOG(ERROR) << "SetNonBlocking for pipe fd[1] failed, errno: " << errno;
    return false;
  }
  wakeup_pipe_out_ = fds[0];
  wakeup_pipe_in_ = fds[1];

  wakeup_event_ = new event;
  event_set(wakeup_event_, wakeup_pipe_out_, EV_READ | EV_PERSIST,
            OnWakeup, this);
  event_base_set(event_base_, wakeup_event_);

  if (event_add(wakeup_event_, 0))
    return false;
  return true;
}

// static
void MessagePumpLibevent::OnLibeventNotification(int fd, short flags,
                                                 void* context) {
  WeakPtr<FileDescriptorWatcher> controller =
      static_cast<FileDescriptorWatcher*>(context)->weak_factory_.GetWeakPtr();
  DCHECK(controller.get());
  TRACE_EVENT1("toplevel", "MessagePumpLibevent::OnLibeventNotification",
               "fd", fd);

  MessagePumpLibevent* pump = controller->pump();
  pump->processed_io_events_ = true;

  if (flags & EV_WRITE) {
    controller->OnFileCanWriteWithoutBlocking(fd, pump);
  }
  // Check |controller| in case it's been deleted in
  // controller->OnFileCanWriteWithoutBlocking().
  if (controller.get() && flags & EV_READ) {
    controller->OnFileCanReadWithoutBlocking(fd, pump);
  }
}

// Called if a byte is received on the wakeup pipe.
// static
void MessagePumpLibevent::OnWakeup(int socket, short flags, void* context) {
  MessagePumpLibevent* that = static_cast<MessagePumpLibevent*>(context);
  DCHECK(that->wakeup_pipe_out_ == socket);

  // Remove and discard the wakeup byte.
  char buf;
  int nread = HANDLE_EINTR(read(socket, &buf, 1));
  DCHECK_EQ(nread, 1);
  that->processed_io_events_ = true;
  // Tell libevent to break out of inner loop.
  event_base_loopbreak(that->event_base_);
}

}  // namespace base
