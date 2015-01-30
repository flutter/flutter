// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_VIEWER_PLATFORM_PLATFORM_IMPL_H_
#define SKY_VIEWER_PLATFORM_PLATFORM_IMPL_H_

#include "base/memory/scoped_ptr.h"
#include "base/message_loop/message_loop.h"
#include "base/threading/thread_local_storage.h"
#include "base/timer/timer.h"
#include "mojo/services/network/public/interfaces/network_service.mojom.h"
#include "sky/engine/public/platform/Platform.h"

namespace mojo {
class ApplicationImpl;
}

namespace sky {

class PlatformImpl : public blink::Platform {
 public:
  explicit PlatformImpl(mojo::ApplicationImpl* app);
  virtual ~PlatformImpl();

  // blink::Platform methods:
  virtual blink::WebString defaultLocale();
  virtual void setSharedTimerFiredFunction(void (*func)());
  virtual void setSharedTimerFireInterval(double interval_seconds);
  virtual void stopSharedTimer();
  virtual base::SingleThreadTaskRunner* mainThreadTaskRunner();
  virtual mojo::NetworkService* networkService();
  virtual blink::WebURLLoader* createURLLoader();
  virtual blink::WebURLError cancelledError(const blink::WebURL& url) const;
  virtual const unsigned char* getTraceCategoryEnabledFlag(
      const char* category_name);
  virtual TraceEventHandle addTraceEvent(
      char phase,
      const unsigned char* category_group_enabled,
      const char* name,
      unsigned long long id,
      int num_args,
      const char** arg_names,
      const unsigned char* arg_types,
      const unsigned long long* arg_values,
      unsigned char flags);
  virtual TraceEventHandle addTraceEvent(
      char phase,
      const unsigned char* category_group_enabled,
      const char* name,
      unsigned long long id,
      int num_args,
      const char** arg_names,
      const unsigned char* arg_types,
      const unsigned long long* arg_values,
      const blink::WebConvertableToTraceFormat* convertable_values,
      unsigned char flags);
  virtual void updateTraceEventDuration(
      const unsigned char* category_group_enabled,
      const char* name,
      TraceEventHandle);

 private:
  void SuspendSharedTimer();
  void ResumeSharedTimer();

  void DoTimeout() {
    if (shared_timer_func_ && !shared_timer_suspended_)
      shared_timer_func_();
  }

  mojo::NetworkServicePtr network_service_;
  base::MessageLoop* main_loop_;
  scoped_refptr<base::SingleThreadTaskRunner> main_thread_task_runner_;
  base::OneShotTimer<PlatformImpl> shared_timer_;
  void (*shared_timer_func_)();
  double shared_timer_fire_time_;
  bool shared_timer_fire_time_was_set_while_suspended_;
  int shared_timer_suspended_;  // counter

  DISALLOW_COPY_AND_ASSIGN(PlatformImpl);
};

}  // namespace sky

#endif  // SKY_VIEWER_PLATFORM_PLATFORM_IMPL_H_
