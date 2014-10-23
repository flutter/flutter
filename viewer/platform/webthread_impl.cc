// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// An implementation of WebThread in terms of base::MessageLoop and
// base::Thread

#include "sky/viewer/platform/webthread_impl.h"

#include "base/bind.h"
#include "base/bind_helpers.h"
#include "base/message_loop/message_loop.h"
#include "base/pending_task.h"
#include "base/threading/platform_thread.h"
#include "mojo/common/message_pump_mojo.h"

namespace sky {

using mojo::common::MessagePumpMojo;

WebThreadBase::WebThreadBase() {}
WebThreadBase::~WebThreadBase() {}

class WebThreadBase::TaskObserverAdapter
    : public base::MessageLoop::TaskObserver {
 public:
  TaskObserverAdapter(WebThread::TaskObserver* observer)
      : observer_(observer) {}

  virtual void WillProcessTask(const base::PendingTask& pending_task) override {
    observer_->willProcessTask();
  }

  virtual void DidProcessTask(const base::PendingTask& pending_task) override {
    observer_->didProcessTask();
  }

private:
  WebThread::TaskObserver* observer_;
};

class WebThreadBase::SignalObserverAdapter
    : public MessagePumpMojo::Observer {
 public:
  SignalObserverAdapter(WebThread::TaskObserver* observer)
      : observer_(observer) {}

  virtual void WillSignalHandler() override {
    observer_->willProcessTask();
  }

  virtual void DidSignalHandler() override {
    observer_->didProcessTask();
  }

private:
  WebThread::TaskObserver* observer_;
};

void WebThreadBase::addTaskObserver(TaskObserver* observer) {
  CHECK(isCurrentThread());
  std::pair<ObserverMap::iterator, bool> result = observer_map_.insert(
      std::make_pair(observer, Adaptors()));
  if (result.second) {
    result.first->second.task_adaptor = new TaskObserverAdapter(observer);
    result.first->second.signal_adaptor = new SignalObserverAdapter(observer);
  }
  base::MessageLoop::current()->AddTaskObserver(
      result.first->second.task_adaptor);
  MessagePumpMojo::current()->AddObserver(result.first->second.signal_adaptor);
}

void WebThreadBase::removeTaskObserver(TaskObserver* observer) {
  CHECK(isCurrentThread());
  ObserverMap::iterator iter = observer_map_.find(observer);
  if (iter == observer_map_.end())
    return;
  base::MessageLoop::current()->RemoveTaskObserver(iter->second.task_adaptor);
  MessagePumpMojo::current()->RemoveObserver(iter->second.signal_adaptor);
  delete iter->second.task_adaptor;
  delete iter->second.signal_adaptor;
  observer_map_.erase(iter);
}

WebThreadImpl::WebThreadImpl(const char* name)
    : thread_(new base::Thread(name)) {
  thread_->Start();
}

void WebThreadImpl::postTask(Task* task) {
  thread_->message_loop()->PostTask(
      FROM_HERE, base::Bind(&blink::WebThread::Task::run, base::Owned(task)));
}

void WebThreadImpl::postDelayedTask(Task* task, long long delay_ms) {
  thread_->message_loop()->PostDelayedTask(
      FROM_HERE,
      base::Bind(&blink::WebThread::Task::run, base::Owned(task)),
      base::TimeDelta::FromMilliseconds(delay_ms));
}

void WebThreadImpl::enterRunLoop() {
  CHECK(isCurrentThread());
  CHECK(!thread_->message_loop()->is_running());  // We don't support nesting.
  thread_->message_loop()->Run();
}

void WebThreadImpl::exitRunLoop() {
  CHECK(isCurrentThread());
  CHECK(thread_->message_loop()->is_running());
  thread_->message_loop()->Quit();
}

bool WebThreadImpl::isCurrentThread() const {
  return thread_->thread_id() == base::PlatformThread::CurrentId();
}

blink::PlatformThreadId WebThreadImpl::threadId() const {
  return thread_->thread_id();
}

WebThreadImpl::~WebThreadImpl() {
  thread_->Stop();
}

WebThreadImplForMessageLoop::WebThreadImplForMessageLoop(
    base::MessageLoopProxy* message_loop)
    : message_loop_(message_loop) {}

void WebThreadImplForMessageLoop::postTask(Task* task) {
  message_loop_->PostTask(
      FROM_HERE, base::Bind(&blink::WebThread::Task::run, base::Owned(task)));
}

void WebThreadImplForMessageLoop::postDelayedTask(Task* task,
                                                  long long delay_ms) {
  message_loop_->PostDelayedTask(
      FROM_HERE,
      base::Bind(&blink::WebThread::Task::run, base::Owned(task)),
      base::TimeDelta::FromMilliseconds(delay_ms));
}

void WebThreadImplForMessageLoop::enterRunLoop() {
  CHECK(isCurrentThread());
  // We don't support nesting.
  CHECK(!base::MessageLoop::current()->is_running());
  base::MessageLoop::current()->Run();
}

void WebThreadImplForMessageLoop::exitRunLoop() {
  CHECK(isCurrentThread());
  CHECK(base::MessageLoop::current()->is_running());
  base::MessageLoop::current()->Quit();
}

bool WebThreadImplForMessageLoop::isCurrentThread() const {
  return message_loop_->BelongsToCurrentThread();
}

blink::PlatformThreadId WebThreadImplForMessageLoop::threadId() const {
  return thread_id_;
}

WebThreadImplForMessageLoop::~WebThreadImplForMessageLoop() {}

}  // namespace sky
