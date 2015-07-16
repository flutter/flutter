// Copyright 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_MESSAGE_LOOP_MESSAGE_PUMP_IO_IOS_H_
#define BASE_MESSAGE_LOOP_MESSAGE_PUMP_IO_IOS_H_

#include "base/base_export.h"
#include "base/mac/scoped_cffiledescriptorref.h"
#include "base/mac/scoped_cftyperef.h"
#include "base/memory/ref_counted.h"
#include "base/memory/weak_ptr.h"
#include "base/message_loop/message_pump_mac.h"
#include "base/observer_list.h"
#include "base/threading/thread_checker.h"

namespace base {

// This file introduces a class to monitor sockets and issue callbacks when
// sockets are ready for I/O on iOS.
class BASE_EXPORT MessagePumpIOSForIO : public MessagePumpNSRunLoop {
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
    friend class MessagePumpIOSForIO;
    friend class MessagePumpIOSForIOTest;

    // Called by MessagePumpIOSForIO, ownership of |fdref| and |fd_source|
    // is transferred to this object.
    void Init(CFFileDescriptorRef fdref,
              CFOptionFlags callback_types,
              CFRunLoopSourceRef fd_source,
              bool is_persistent);

    void set_pump(base::WeakPtr<MessagePumpIOSForIO> pump) { pump_ = pump; }
    const base::WeakPtr<MessagePumpIOSForIO>& pump() const { return pump_; }

    void set_watcher(Watcher* watcher) { watcher_ = watcher; }

    void OnFileCanReadWithoutBlocking(int fd, MessagePumpIOSForIO* pump);
    void OnFileCanWriteWithoutBlocking(int fd, MessagePumpIOSForIO* pump);

    bool is_persistent_;  // false if this event is one-shot.
    base::mac::ScopedCFFileDescriptorRef fdref_;
    CFOptionFlags callback_types_;
    base::ScopedCFTypeRef<CFRunLoopSourceRef> fd_source_;
    base::WeakPtr<MessagePumpIOSForIO> pump_;
    Watcher* watcher_;

    DISALLOW_COPY_AND_ASSIGN(FileDescriptorWatcher);
  };

  enum Mode {
    WATCH_READ = 1 << 0,
    WATCH_WRITE = 1 << 1,
    WATCH_READ_WRITE = WATCH_READ | WATCH_WRITE
  };

  MessagePumpIOSForIO();
  ~MessagePumpIOSForIO() override;

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
  bool WatchFileDescriptor(int fd,
                           bool persistent,
                           int mode,
                           FileDescriptorWatcher *controller,
                           Watcher *delegate);

  void RemoveRunLoopSource(CFRunLoopSourceRef source);

  void AddIOObserver(IOObserver* obs);
  void RemoveIOObserver(IOObserver* obs);

 private:
  friend class MessagePumpIOSForIOTest;

  void WillProcessIOEvent();
  void DidProcessIOEvent();

  static void HandleFdIOEvent(CFFileDescriptorRef fdref,
                              CFOptionFlags callback_types,
                              void* context);

  ObserverList<IOObserver> io_observers_;
  ThreadChecker watch_file_descriptor_caller_checker_;

  base::WeakPtrFactory<MessagePumpIOSForIO> weak_factory_;

  DISALLOW_COPY_AND_ASSIGN(MessagePumpIOSForIO);
};

}  // namespace base

#endif  // BASE_MESSAGE_LOOP_MESSAGE_PUMP_IO_IOS_H_
