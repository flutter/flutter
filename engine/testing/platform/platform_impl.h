// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_TESTING_PLATFORM_PLATFORM_IMPL_H_
#define SKY_ENGINE_TESTING_PLATFORM_PLATFORM_IMPL_H_

#include "base/memory/scoped_ptr.h"
#include "base/message_loop/message_loop.h"
#include "base/threading/thread_local_storage.h"
#include "base/timer/timer.h"
#include "sky/engine/public/platform/Platform.h"
#include "sky/engine/public/platform/WebScrollbarBehavior.h"
#include "sky/engine/testing/platform/webmimeregistry_impl.h"
#include "sky/engine/testing/platform/webthemeengine_impl.h"
#include "sky/engine/testing/platform/webunittestsupport_impl.h"

namespace sky {

class PlatformImpl : public blink::Platform {
 public:
  explicit PlatformImpl();
  virtual ~PlatformImpl();

  // blink::Platform methods:
  virtual blink::WebUnitTestSupport* unitTestSupport();
  virtual blink::WebMimeRegistry* mimeRegistry();
  virtual blink::WebThemeEngine* themeEngine();
  virtual blink::WebString defaultLocale();
  virtual double currentTime();
  virtual double monotonicallyIncreasingTime();
  virtual void setSharedTimerFiredFunction(void (*func)());
  virtual void setSharedTimerFireInterval(double interval_seconds);
  virtual void stopSharedTimer();
  virtual blink::WebData parseDataURL(
      const blink::WebURL& url, blink::WebString& mime_type,
      blink::WebString& charset);
  virtual blink::WebScrollbarBehavior* scrollbarBehavior();
  virtual const unsigned char* getTraceCategoryEnabledFlag(
      const char* category_name);

 private:
  void SuspendSharedTimer();
  void ResumeSharedTimer();

  void DoTimeout() {
    if (shared_timer_func_ && !shared_timer_suspended_)
      shared_timer_func_();
  }

  base::MessageLoop* main_loop_;
  base::OneShotTimer<PlatformImpl> shared_timer_;
  void (*shared_timer_func_)();
  double shared_timer_fire_time_;
  bool shared_timer_fire_time_was_set_while_suspended_;
  int shared_timer_suspended_;  // counter
  WebThemeEngineImpl theme_engine_;
  WebMimeRegistryImpl mime_registry_;
  WebUnitTestSupportImpl unit_test_support_;
  blink::WebScrollbarBehavior scrollbar_behavior_;

  DISALLOW_COPY_AND_ASSIGN(PlatformImpl);
};

}  // namespace sky

#endif  // SKY_ENGINE_TESTING_PLATFORM_PLATFORM_IMPL_H_
