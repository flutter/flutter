// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_MESSAGE_LOOP_MESSAGE_PUMP_LIBEVENT_H_
#define BASE_MESSAGE_LOOP_MESSAGE_PUMP_LIBEVENT_H_

#include "base/basictypes.h"
#include "base/compiler_specific.h"
#include "base/memory/weak_ptr.h"
#include "base/message_loop/message_pump.h"
#include "base/observer_list.h"
#include "base/threading/thread_checker.h"
#include "base/time/time.h"

// Declare structs we need from libevent.h rather than including it
struct event_base;
struct event;

namespace base {

// Class to monitor sockets and issue callbacks when sockets are ready for I/O
// TODO(dkegel): add support for background file IO somehow
class BASE_EXPORT MessagePumpLibevent : public MessagePump {
 public:
  class IOObserver {
   public:
    IOObserver() {}

    // An IOObserver is an object that receives IO notifications from the
    // MessagePump.
    //
    // NOTE: An IOObserver implementation should be extremely fast!
    virtual void WillProcessIOEvent() = 0;
    virtual void DidProcessIOEvent() = 0;

   protected:
    virtual ~IOObserver() {}
  };

  // Used with WatchFileDescriptor to asynchronously monitor the I/O readiness
  // of a file descriptor.
  class Watcher {
   public:
    // Called from MessageLoop::Run when an FD can be read from/written to
    // without blocking
    virtual void OnFileCanReadWithoutBlocking(int fd) = 0;
    virtual void OnFileCanWriteWithoutBlocking(int fd) = 0;

   protected:
    virtual ~Watcher() {}
  };

  // Object returned by WatchFileDescriptor to manage further watching.
  class FileDescriptorWatcher {
   public:
    FileDescriptorWatcher();
    ~FileDescriptorWatcher();  // Implicitly calls StopWatchingFileDescriptor.

    // NOTE: These methods aren't called StartWatching()/StopWatching() to
    // avoid confusion with the win32 ObjectWatcher class.

    // Stop watching the FD, always safe to call.  No-op if there's nothing
    // to do.
    bool StopWatchingFileDescriptor();

   private:
    friend class MessagePumpLibevent;
    friend class MessagePumpLibeventTest;

    // Called by MessagePumpLibevent, ownership of |e| is transferred to this
    // object.
    void Init(event* e);

    // Used by MessagePumpLibevent to take ownership of event_.
    event* ReleaseEvent();

    void set_pump(MessagePumpLibevent* pump) { pump_ = pump; }
    MessagePumpLibevent* pump() const { return pump_; }

    void set_watcher(Watcher* watcher) { watcher_ = watcher; }

    void OnFileCanReadWithoutBlocking(int fd, MessagePumpLibevent* pump);
    void OnFileCanWriteWithoutBlocking(int fd, MessagePumpLibevent* pump);

    event* event_;
    MessagePumpLibevent* pump_;
    Watcher* watcher_;
    WeakPtrFactory<FileDescriptorWatcher> weak_factory_;

    DISALLOW_COPY_AND_ASSIGN(FileDescriptorWatcher);
  };

  enum Mode {
    WATCH_READ = 1 << 0,
    WATCH_WRITE = 1 << 1,
    WATCH_READ_WRITE = WATCH_READ | WATCH_WRITE
  };

  MessagePumpLibevent();
  ~MessagePumpLibevent() override;

  // Have the current thread's message loop watch for a a situation in which
  // reading/writing to the FD can be performed without blocking.
  // Callers must provide a preallocated FileDescriptorWatcher object which
  // can later be used to manage the lifetime of this event.
  // If a FileDescriptorWatcher is passed in which is already attached to
  // an event, then the effect is cumulative i.e. after the call |controller|
  // will watch both the previous event and the new one.
  // If an error occurs while calling this method in a cumulative fashion, the
  // event previously attached to |controller| is aborted.
  // Returns true on success.
  // Must be called on the same thread the message_pump is running on.
  // TODO(dkegel): switch to edge-triggered readiness notification
  bool WatchFileDescriptor(int fd,
                           bool persistent,
                           int mode,
                           FileDescriptorWatcher *controller,
                           Watcher *delegate);

  void AddIOObserver(IOObserver* obs);
  void RemoveIOObserver(IOObserver* obs);

  // MessagePump methods:
  void Run(Delegate* delegate) override;
  void Quit() override;
  void ScheduleWork() override;
  void ScheduleDelayedWork(const TimeTicks& delayed_work_time) override;

 private:
  friend class MessagePumpLibeventTest;

  void WillProcessIOEvent();
  void DidProcessIOEvent();

  // Risky part of constructor.  Returns true on success.
  bool Init();

  // Called by libevent to tell us a registered FD can be read/written to.
  static void OnLibeventNotification(int fd, short flags,
                                     void* context);

  // Unix pipe used to implement ScheduleWork()
  // ... callback; called by libevent inside Run() when pipe is ready to read
  static void OnWakeup(int socket, short flags, void* context);

  // This flag is set to false when Run should return.
  bool keep_running_;

  // This flag is set when inside Run.
  bool in_run_;

  // This flag is set if libevent has processed I/O events.
  bool processed_io_events_;

  // The time at which we should call DoDelayedWork.
  TimeTicks delayed_work_time_;

  // Libevent dispatcher.  Watches all sockets registered with it, and sends
  // readiness callbacks when a socket is ready for I/O.
  event_base* event_base_;

  // ... write end; ScheduleWork() writes a single byte to it
  int wakeup_pipe_in_;
  // ... read end; OnWakeup reads it and then breaks Run() out of its sleep
  int wakeup_pipe_out_;
  // ... libevent wrapper for read end
  event* wakeup_event_;

  ObserverList<IOObserver> io_observers_;
  ThreadChecker watch_file_descriptor_caller_checker_;
  DISALLOW_COPY_AND_ASSIGN(MessagePumpLibevent);
};

}  // namespace base

#endif  // BASE_MESSAGE_LOOP_MESSAGE_PUMP_LIBEVENT_H_
