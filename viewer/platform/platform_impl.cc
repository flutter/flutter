// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/viewer/platform/platform_impl.h"

#include <cmath>

#include "base/debug/trace_event.h"
#include "base/rand_util.h"
#include "base/stl_util.h"
#include "base/synchronization/waitable_event.h"
#include "base/time/time.h"
#include "mojo/public/cpp/application/application_impl.h"
#include "net/base/data_url.h"
#include "net/base/mime_util.h"
#include "net/base/net_errors.h"
#include "sky/viewer/platform/weburlloader_impl.h"

namespace sky {

PlatformImpl::PlatformImpl(mojo::ApplicationImpl* app)
    : main_loop_(base::MessageLoop::current()),
      main_thread_task_runner_(base::MessageLoop::current()->task_runner()),
      shared_timer_func_(NULL),
      shared_timer_fire_time_(0.0),
      shared_timer_fire_time_was_set_while_suspended_(false),
      shared_timer_suspended_(0) {
  app->ConnectToService("mojo:network_service", &network_service_);

  mojo::CookieStorePtr cookie_store;
  network_service_->GetCookieStore(GetProxy(&cookie_store));
}

PlatformImpl::~PlatformImpl() {
}

blink::WebString PlatformImpl::defaultLocale() {
  return blink::WebString::fromUTF8("en-US");
}

void PlatformImpl::setSharedTimerFiredFunction(void (*func)()) {
  shared_timer_func_ = func;
}

void PlatformImpl::setSharedTimerFireInterval(
    double interval_seconds) {
  double now = base::TimeTicks::Now().ToInternalValue() /
      static_cast<double>(base::Time::kMicrosecondsPerSecond);

  shared_timer_fire_time_ = interval_seconds + now;
  if (shared_timer_suspended_) {
    shared_timer_fire_time_was_set_while_suspended_ = true;
    return;
  }

  // By converting between double and int64 representation, we run the risk
  // of losing precision due to rounding errors. Performing computations in
  // microseconds reduces this risk somewhat. But there still is the potential
  // of us computing a fire time for the timer that is shorter than what we
  // need.
  // As the event loop will check event deadlines prior to actually firing
  // them, there is a risk of needlessly rescheduling events and of
  // needlessly looping if sleep times are too short even by small amounts.
  // This results in measurable performance degradation unless we use ceil() to
  // always round up the sleep times.
  int64 interval = static_cast<int64>(
      ceil(interval_seconds * base::Time::kMillisecondsPerSecond)
      * base::Time::kMicrosecondsPerMillisecond);

  if (interval < 0)
    interval = 0;

  shared_timer_.Stop();
  shared_timer_.Start(FROM_HERE, base::TimeDelta::FromMicroseconds(interval),
                      this, &PlatformImpl::DoTimeout);
}

void PlatformImpl::stopSharedTimer() {
  shared_timer_.Stop();
}

base::SingleThreadTaskRunner* PlatformImpl::mainThreadTaskRunner() {
  return main_thread_task_runner_.get();
}

mojo::NetworkService* PlatformImpl::networkService() {
  return network_service_.get();
}

blink::WebURLLoader* PlatformImpl::createURLLoader() {
  return new WebURLLoaderImpl(network_service_.get());
}

blink::WebURLError PlatformImpl::cancelledError(const blink::WebURL& url)
    const {
  blink::WebURLError error;
  error.domain = blink::WebString::fromUTF8(net::kErrorDomain);
  error.reason = net::ERR_ABORTED;
  error.unreachableURL = url;
  error.staleCopyInCache = false;
  error.isCancellation = true;
  return error;
}

}  // namespace sky
