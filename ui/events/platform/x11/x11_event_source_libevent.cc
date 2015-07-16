// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/events/platform/x11/x11_event_source.h"

#include <X11/Xlib.h>

#include "base/message_loop/message_loop.h"
#include "base/message_loop/message_pump_libevent.h"

namespace ui {

namespace {

class X11EventSourceLibevent : public X11EventSource,
                               public base::MessagePumpLibevent::Watcher {
 public:
  explicit X11EventSourceLibevent(XDisplay* display)
      : X11EventSource(display),
        initialized_(false) {
    AddEventWatcher();
  }

  ~X11EventSourceLibevent() override {
  }

 private:
  void AddEventWatcher() {
    if (initialized_)
      return;
    if (!base::MessageLoop::current())
      return;

    int fd = ConnectionNumber(display());
    base::MessageLoopForUI::current()->WatchFileDescriptor(fd, true,
        base::MessagePumpLibevent::WATCH_READ, &watcher_controller_, this);
    initialized_ = true;
  }

  // PlatformEventSource:
  void OnDispatcherListChanged() override {
    AddEventWatcher();
  }

  // base::MessagePumpLibevent::Watcher:
  void OnFileCanReadWithoutBlocking(int fd) override {
    DispatchXEvents();
  }

  void OnFileCanWriteWithoutBlocking(int fd) override {
    NOTREACHED();
  }

  base::MessagePumpLibevent::FileDescriptorWatcher watcher_controller_;
  bool initialized_;

  DISALLOW_COPY_AND_ASSIGN(X11EventSourceLibevent);
};

}  // namespace

scoped_ptr<PlatformEventSource> PlatformEventSource::CreateDefault() {
  return scoped_ptr<PlatformEventSource>(
      new X11EventSourceLibevent(gfx::GetXDisplay()));
}

}  // namespace ui
