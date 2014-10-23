// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_TESTING_PLATFORM__WEBTHREAD_IMPL_H_
#define SKY_ENGINE_TESTING_PLATFORM__WEBTHREAD_IMPL_H_

#include <map>

#include "base/memory/scoped_ptr.h"
#include "base/threading/thread.h"
#include "sky/engine/public/platform/WebThread.h"

namespace sky {

class WebThreadBase : public blink::WebThread {
 public:
  virtual ~WebThreadBase();

  virtual void addTaskObserver(TaskObserver* observer);
  virtual void removeTaskObserver(TaskObserver* observer);

  virtual bool isCurrentThread() const = 0;
  virtual blink::PlatformThreadId threadId() const = 0;

 protected:
  WebThreadBase();

 private:
  class TaskObserverAdapter;

  typedef std::map<TaskObserver*, TaskObserverAdapter*> TaskObserverMap;
  TaskObserverMap task_observer_map_;
};

class WebThreadImpl : public WebThreadBase {
 public:
  explicit WebThreadImpl(const char* name);
  virtual ~WebThreadImpl();

  virtual void postTask(Task* task);
  virtual void postDelayedTask(Task* task, long long delay_ms);

  virtual void enterRunLoop();
  virtual void exitRunLoop();

  base::MessageLoop* message_loop() const { return thread_->message_loop(); }

  virtual bool isCurrentThread() const;
  virtual blink::PlatformThreadId threadId() const;

 private:
  scoped_ptr<base::Thread> thread_;
};

class WebThreadImplForMessageLoop : public WebThreadBase {
 public:
  explicit WebThreadImplForMessageLoop(
      base::MessageLoopProxy* message_loop);
  virtual ~WebThreadImplForMessageLoop();

  virtual void postTask(Task* task);
  virtual void postDelayedTask(Task* task, long long delay_ms);

  virtual void enterRunLoop();
  virtual void exitRunLoop();

 private:
  virtual bool isCurrentThread() const;
  virtual blink::PlatformThreadId threadId() const;

  scoped_refptr<base::MessageLoopProxy> message_loop_;
  blink::PlatformThreadId thread_id_;
};

}  // namespace sky

#endif  // SKY_ENGINE_TESTING_PLATFORM__WEBTHREAD_IMPL_H_
