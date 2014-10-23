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
#include "sky/engine/public/platform/WebConvertableToTraceFormat.h"
#include "sky/engine/public/platform/WebWaitableEvent.h"
#include "sky/viewer/platform/weburlloader_impl.h"

namespace sky {
namespace {

class WebWaitableEventImpl : public blink::WebWaitableEvent {
 public:
  WebWaitableEventImpl() : impl_(new base::WaitableEvent(false, false)) {}
  virtual ~WebWaitableEventImpl() {}

  virtual void wait() { impl_->Wait(); }
  virtual void signal() { impl_->Signal(); }

  base::WaitableEvent* impl() {
    return impl_.get();
  }

 private:
  scoped_ptr<base::WaitableEvent> impl_;
  DISALLOW_COPY_AND_ASSIGN(WebWaitableEventImpl);
};

class ConvertableToTraceFormatWrapper
    : public base::debug::ConvertableToTraceFormat {
 public:
  explicit ConvertableToTraceFormatWrapper(
      const blink::WebConvertableToTraceFormat& convertable)
      : convertable_(convertable) {}
  virtual void AppendAsTraceFormat(std::string* out) const override {
    *out += convertable_.asTraceFormat().utf8();
  }

 private:
  virtual ~ConvertableToTraceFormatWrapper() {}

  blink::WebConvertableToTraceFormat convertable_;
};

}  // namespace

PlatformImpl::PlatformImpl(mojo::ApplicationImpl* app)
    : main_loop_(base::MessageLoop::current()),
      shared_timer_func_(NULL),
      shared_timer_fire_time_(0.0),
      shared_timer_fire_time_was_set_while_suspended_(false),
      shared_timer_suspended_(0) {
  app->ConnectToService("mojo://network_service/", &network_service_);

  mojo::CookieStorePtr cookie_store;
  network_service_->GetCookieStore(GetProxy(&cookie_store));
}

PlatformImpl::~PlatformImpl() {
}

blink::WebMimeRegistry* PlatformImpl::mimeRegistry() {
  return &mime_registry_;
}

blink::WebThemeEngine* PlatformImpl::themeEngine() {
  return &theme_engine_;
}

blink::WebString PlatformImpl::defaultLocale() {
  return blink::WebString::fromUTF8("en-US");
}

double PlatformImpl::currentTime() {
  return base::Time::Now().ToDoubleT();
}

double PlatformImpl::monotonicallyIncreasingTime() {
  return base::TimeTicks::Now().ToInternalValue() /
      static_cast<double>(base::Time::kMicrosecondsPerSecond);
}

void PlatformImpl::cryptographicallyRandomValues(unsigned char* buffer,
                                                      size_t length) {
  base::RandBytes(buffer, length);
}

void PlatformImpl::setSharedTimerFiredFunction(void (*func)()) {
  shared_timer_func_ = func;
}

void PlatformImpl::setSharedTimerFireInterval(
    double interval_seconds) {
  shared_timer_fire_time_ = interval_seconds + monotonicallyIncreasingTime();
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

void PlatformImpl::callOnMainThread(
    void (*func)(void*), void* context) {
  main_loop_->PostTask(FROM_HERE, base::Bind(func, context));
}

bool PlatformImpl::isThreadedCompositingEnabled() {
  return true;
}

blink::WebCompositorSupport* PlatformImpl::compositorSupport() {
  return &compositor_support_;
}

blink::WebScrollbarBehavior* PlatformImpl::scrollbarBehavior() {
  return &scrollbar_behavior_;
}

blink::WebURLLoader* PlatformImpl::createURLLoader() {
  return new WebURLLoaderImpl(network_service_.get());
}

blink::WebData PlatformImpl::parseDataURL(
    const blink::WebURL& url,
    blink::WebString& mimetype_out,
    blink::WebString& charset_out) {
  std::string mimetype, charset, data;
  if (net::DataURL::Parse(url, &mimetype, &charset, &data)
      && net::IsSupportedMimeType(mimetype)) {
    mimetype_out = blink::WebString::fromUTF8(mimetype);
    charset_out = blink::WebString::fromUTF8(charset);
    return data;
  }
  return blink::WebData();
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

blink::WebWaitableEvent* PlatformImpl::createWaitableEvent() {
  return new WebWaitableEventImpl();
}

blink::WebWaitableEvent* PlatformImpl::waitMultipleEvents(
    const blink::WebVector<blink::WebWaitableEvent*>& web_events) {
  std::vector<base::WaitableEvent*> events;
  for (size_t i = 0; i < web_events.size(); ++i)
    events.push_back(static_cast<WebWaitableEventImpl*>(web_events[i])->impl());
  size_t idx = base::WaitableEvent::WaitMany(
      vector_as_array(&events), events.size());
  DCHECK_LT(idx, web_events.size());
  return web_events[idx];
}

const unsigned char* PlatformImpl::getTraceCategoryEnabledFlag(
    const char* category_group) {
  return TRACE_EVENT_API_GET_CATEGORY_GROUP_ENABLED(category_group);
}

long* PlatformImpl::getTraceSamplingState(const unsigned thread_bucket) {
  switch (thread_bucket) {
    case 0:
      return reinterpret_cast<long*>(&TRACE_EVENT_API_THREAD_BUCKET(0));
    case 1:
      return reinterpret_cast<long*>(&TRACE_EVENT_API_THREAD_BUCKET(1));
    case 2:
      return reinterpret_cast<long*>(&TRACE_EVENT_API_THREAD_BUCKET(2));
    default:
      NOTREACHED() << "Unknown thread bucket type.";
  }
  return NULL;
}

COMPILE_ASSERT(
    sizeof(blink::Platform::TraceEventHandle) ==
        sizeof(base::debug::TraceEventHandle),
    TraceEventHandle_types_must_be_same_size);

blink::Platform::TraceEventHandle PlatformImpl::addTraceEvent(
    char phase,
    const unsigned char* category_group_enabled,
    const char* name,
    unsigned long long id,
    int num_args,
    const char** arg_names,
    const unsigned char* arg_types,
    const unsigned long long* arg_values,
    unsigned char flags) {
  base::debug::TraceEventHandle handle = TRACE_EVENT_API_ADD_TRACE_EVENT(
      phase, category_group_enabled, name, id,
      num_args, arg_names, arg_types, arg_values, NULL, flags);
  blink::Platform::TraceEventHandle result;
  memcpy(&result, &handle, sizeof(result));
  return result;
}

blink::Platform::TraceEventHandle PlatformImpl::addTraceEvent(
    char phase,
    const unsigned char* category_group_enabled,
    const char* name,
    unsigned long long id,
    int num_args,
    const char** arg_names,
    const unsigned char* arg_types,
    const unsigned long long* arg_values,
    const blink::WebConvertableToTraceFormat* convertable_values,
    unsigned char flags) {
  scoped_refptr<base::debug::ConvertableToTraceFormat> convertable_wrappers[2];
  if (convertable_values) {
    size_t size = std::min(static_cast<size_t>(num_args),
                           arraysize(convertable_wrappers));
    for (size_t i = 0; i < size; ++i) {
      if (arg_types[i] == TRACE_VALUE_TYPE_CONVERTABLE) {
        convertable_wrappers[i] =
            new ConvertableToTraceFormatWrapper(convertable_values[i]);
      }
    }
  }
  base::debug::TraceEventHandle handle =
      TRACE_EVENT_API_ADD_TRACE_EVENT(phase,
                                      category_group_enabled,
                                      name,
                                      id,
                                      num_args,
                                      arg_names,
                                      arg_types,
                                      arg_values,
                                      convertable_wrappers,
                                      flags);
  blink::Platform::TraceEventHandle result;
  memcpy(&result, &handle, sizeof(result));
  return result;
}

void PlatformImpl::updateTraceEventDuration(
    const unsigned char* category_group_enabled,
    const char* name,
    TraceEventHandle handle) {
  base::debug::TraceEventHandle traceEventHandle;
  memcpy(&traceEventHandle, &handle, sizeof(handle));
  TRACE_EVENT_API_UPDATE_TRACE_EVENT_DURATION(
      category_group_enabled, name, traceEventHandle);
}

}  // namespace sky
