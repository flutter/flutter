// Copyright (c) 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gl/gpu_timing.h"

#include "base/time/time.h"
#include "ui/gl/gl_bindings.h"
#include "ui/gl/gl_context.h"
#include "ui/gl/gl_version_info.h"

namespace gfx {

GPUTiming::GPUTiming(GLContextReal* context) {
  DCHECK(context);
  const GLVersionInfo* version_info = context->GetVersionInfo();
  DCHECK(version_info);
  if (version_info->is_es3 &&  // glGetInteger64v is supported under ES3.
    context->HasExtension("GL_EXT_disjoint_timer_query")) {
    timer_type_ = kTimerTypeDisjoint;
  } else if (context->HasExtension("GL_ARB_timer_query")) {
    timer_type_ = kTimerTypeARB;
  } else if (context->HasExtension("GL_EXT_timer_query")) {
    timer_type_ = kTimerTypeEXT;
  }
}

GPUTiming::~GPUTiming() {
}

scoped_refptr<GPUTimingClient> GPUTiming::CreateGPUTimingClient() {
  return new GPUTimingClient(this);
}

uint32_t GPUTiming::GetDisjointCount() {
  if (timer_type_ == kTimerTypeDisjoint) {
    GLint disjoint_value = 0;
    glGetIntegerv(GL_GPU_DISJOINT_EXT, &disjoint_value);
    if (disjoint_value) {
      disjoint_counter_++;
    }
  }
  return disjoint_counter_;
}

GPUTimer::~GPUTimer() {
  // Destroy() must be called before the destructor.
  DCHECK(queries_[0] == 0);
  DCHECK(queries_[1] == 0);
}

void GPUTimer::Destroy(bool have_context) {
  if (have_context) {
    glDeleteQueries(2, queries_);
  }
  memset(queries_, 0, sizeof(queries_));
}

void GPUTimer::Start() {
  switch (gpu_timing_client_->gpu_timing_->timer_type_) {
    case GPUTiming::kTimerTypeARB:
    case GPUTiming::kTimerTypeDisjoint:
      // GL_TIMESTAMP and GL_TIMESTAMP_EXT both have the same value.
      glQueryCounter(queries_[0], GL_TIMESTAMP);
      break;
    case GPUTiming::kTimerTypeEXT:
      glBeginQuery(GL_TIME_ELAPSED_EXT, queries_[0]);
      break;
    default:
      NOTREACHED();
  }
}

void GPUTimer::End() {
  end_requested_ = true;
  DCHECK(gpu_timing_client_->gpu_timing_);
  switch (gpu_timing_client_->gpu_timing_->timer_type_) {
    case GPUTiming::kTimerTypeARB:
    case GPUTiming::kTimerTypeDisjoint:
      offset_ = gpu_timing_client_->CalculateTimerOffset();
      glQueryCounter(queries_[1], GL_TIMESTAMP);
      break;
    case GPUTiming::kTimerTypeEXT:
      glEndQuery(GL_TIME_ELAPSED_EXT);
      break;
    default:
      NOTREACHED();
  }
}

bool GPUTimer::IsAvailable() {
  if (!gpu_timing_client_->IsAvailable() || !end_requested_) {
    return false;
  }
  GLint done = 0;
  glGetQueryObjectiv(queries_[1] ? queries_[1] : queries_[0],
                     GL_QUERY_RESULT_AVAILABLE, &done);
  return done != 0;
}

void GPUTimer::GetStartEndTimestamps(int64* start, int64* end) {
  DCHECK(start && end);
  DCHECK(IsAvailable());
  DCHECK(gpu_timing_client_->gpu_timing_);
  DCHECK(gpu_timing_client_->gpu_timing_->timer_type_ !=
         GPUTiming::kTimerTypeEXT);
  GLuint64 begin_stamp = 0;
  GLuint64 end_stamp = 0;
  // TODO(dsinclair): It's possible for the timer to wrap during the start/end.
  // We need to detect if the end is less then the start and correct for the
  // wrapping.
  glGetQueryObjectui64v(queries_[0], GL_QUERY_RESULT, &begin_stamp);
  glGetQueryObjectui64v(queries_[1], GL_QUERY_RESULT, &end_stamp);

  *start = (begin_stamp / base::Time::kNanosecondsPerMicrosecond) + offset_;
  *end = (end_stamp / base::Time::kNanosecondsPerMicrosecond) + offset_;
}

int64 GPUTimer::GetDeltaElapsed() {
  DCHECK(gpu_timing_client_->gpu_timing_);
  switch (gpu_timing_client_->gpu_timing_->timer_type_) {
    case GPUTiming::kTimerTypeARB:
    case GPUTiming::kTimerTypeDisjoint: {
      int64 start = 0;
      int64 end = 0;
      GetStartEndTimestamps(&start, &end);
      return end - start;
    } break;
    case GPUTiming::kTimerTypeEXT: {
      GLuint64 delta = 0;
      glGetQueryObjectui64v(queries_[0], GL_QUERY_RESULT, &delta);
      return static_cast<int64>(delta / base::Time::kNanosecondsPerMicrosecond);
    } break;
    default:
      NOTREACHED();
  }
  return 0;
}

GPUTimer::GPUTimer(scoped_refptr<GPUTimingClient> gpu_timing_client)
    : gpu_timing_client_(gpu_timing_client) {
  DCHECK(gpu_timing_client_);
  memset(queries_, 0, sizeof(queries_));
  int queries = 0;
  DCHECK(gpu_timing_client_->gpu_timing_);
  switch (gpu_timing_client_->gpu_timing_->timer_type_) {
    case GPUTiming::kTimerTypeARB:
    case GPUTiming::kTimerTypeDisjoint:
      queries = 2;
      break;
    case GPUTiming::kTimerTypeEXT:
      queries = 1;
      break;
    default:
      NOTREACHED();
  }
  glGenQueries(queries, queries_);
}

GPUTimingClient::GPUTimingClient(GPUTiming* gpu_timing)
    : gpu_timing_(gpu_timing) {
  if (gpu_timing) {
    timer_type_ = gpu_timing->GetTimerType();
    disjoint_counter_ = gpu_timing_->GetDisjointCount();
  }
}

scoped_ptr<GPUTimer> GPUTimingClient::CreateGPUTimer() {
  return make_scoped_ptr(new GPUTimer(this));
}

bool GPUTimingClient::IsAvailable() {
  return timer_type_ != GPUTiming::kTimerTypeInvalid;
}

bool GPUTimingClient::IsTimerOffsetAvailable() {
  return timer_type_ == GPUTiming::kTimerTypeARB ||
         timer_type_ == GPUTiming::kTimerTypeDisjoint;
}

const char* GPUTimingClient::GetTimerTypeName() const {
  switch (timer_type_) {
    case GPUTiming::kTimerTypeDisjoint:
      return "GL_EXT_disjoint_timer_query";
    case GPUTiming::kTimerTypeARB:
      return "GL_ARB_timer_query";
    case GPUTiming::kTimerTypeEXT:
      return "GL_EXT_timer_query";
    default:
      return "Unknown";
  }
}

bool GPUTimingClient::CheckAndResetTimerErrors() {
  if (timer_type_ == GPUTiming::kTimerTypeDisjoint) {
    DCHECK(gpu_timing_ != nullptr);
    const uint32_t total_disjoint_count = gpu_timing_->GetDisjointCount();
    const bool disjoint_triggered = total_disjoint_count != disjoint_counter_;
    disjoint_counter_ = total_disjoint_count;
    return disjoint_triggered;
  }
  return false;
}

int64 GPUTimingClient::CalculateTimerOffset() {
  DCHECK(IsTimerOffsetAvailable());
  if (!offset_valid_) {
    GLint64 gl_now = 0;
    glGetInteger64v(GL_TIMESTAMP, &gl_now);
    int64 now =
        cpu_time_for_testing_.is_null()
            ? (base::TraceTicks::Now() - base::TraceTicks()).InMicroseconds()
            : cpu_time_for_testing_.Run();
    offset_ = now - gl_now / base::Time::kNanosecondsPerMicrosecond;
    offset_valid_ = timer_type_ == GPUTiming::kTimerTypeARB;
  }
  return offset_;
}

void GPUTimingClient::InvalidateTimerOffset() {
  offset_valid_ = false;
}

void GPUTimingClient::SetCpuTimeForTesting(
    const base::Callback<int64(void)>& cpu_time) {
  cpu_time_for_testing_ = cpu_time;
}

GPUTimingClient::~GPUTimingClient() {
}

}  // namespace gfx
