// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/frame_timings.h"

#include <memory>
#include <sstream>

#include "flutter/common/settings.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/time/time_point.h"

namespace flutter {

std::atomic<uint64_t> FrameTimingsRecorder::frame_number_gen_ = {1};

static std::string ToString(uint64_t val) {
  std::stringstream stream;
  stream << val;
  return stream.str();
}

FrameTimingsRecorder::FrameTimingsRecorder()
    : frame_number_(frame_number_gen_++),
      frame_number_trace_arg_val_(ToString(frame_number_)) {}

FrameTimingsRecorder::FrameTimingsRecorder(uint64_t frame_number)
    : frame_number_(frame_number),
      frame_number_trace_arg_val_(ToString(frame_number_)) {}

FrameTimingsRecorder::~FrameTimingsRecorder() = default;

fml::TimePoint FrameTimingsRecorder::GetVsyncStartTime() const {
  std::scoped_lock state_lock(state_mutex_);
  FML_DCHECK(state_ >= State::kVsync);
  return vsync_start_;
}

fml::TimePoint FrameTimingsRecorder::GetVsyncTargetTime() const {
  std::scoped_lock state_lock(state_mutex_);
  FML_DCHECK(state_ >= State::kVsync);
  return vsync_target_;
}

fml::TimePoint FrameTimingsRecorder::GetBuildStartTime() const {
  std::scoped_lock state_lock(state_mutex_);
  FML_DCHECK(state_ >= State::kBuildStart);
  return build_start_;
}

fml::TimePoint FrameTimingsRecorder::GetBuildEndTime() const {
  std::scoped_lock state_lock(state_mutex_);
  FML_DCHECK(state_ >= State::kBuildEnd);
  return build_end_;
}

fml::TimePoint FrameTimingsRecorder::GetRasterStartTime() const {
  std::scoped_lock state_lock(state_mutex_);
  FML_DCHECK(state_ >= State::kRasterStart);
  return raster_start_;
}

fml::TimePoint FrameTimingsRecorder::GetRasterEndTime() const {
  std::scoped_lock state_lock(state_mutex_);
  FML_DCHECK(state_ >= State::kRasterEnd);
  return raster_end_;
}

fml::TimePoint FrameTimingsRecorder::GetRasterEndWallTime() const {
  std::scoped_lock state_lock(state_mutex_);
  FML_DCHECK(state_ >= State::kRasterEnd);
  return raster_end_wall_time_;
}

fml::TimeDelta FrameTimingsRecorder::GetBuildDuration() const {
  std::scoped_lock state_lock(state_mutex_);
  FML_DCHECK(state_ >= State::kBuildEnd);
  return build_end_ - build_start_;
}

void FrameTimingsRecorder::RecordVsync(fml::TimePoint vsync_start,
                                       fml::TimePoint vsync_target) {
  std::scoped_lock state_lock(state_mutex_);
  FML_DCHECK(state_ == State::kUninitialized);
  state_ = State::kVsync;
  vsync_start_ = vsync_start;
  vsync_target_ = vsync_target;
}

void FrameTimingsRecorder::RecordBuildStart(fml::TimePoint build_start) {
  std::scoped_lock state_lock(state_mutex_);
  FML_DCHECK(state_ == State::kVsync);
  state_ = State::kBuildStart;
  build_start_ = build_start;
}

void FrameTimingsRecorder::RecordBuildEnd(fml::TimePoint build_end) {
  std::scoped_lock state_lock(state_mutex_);
  FML_DCHECK(state_ == State::kBuildStart);
  state_ = State::kBuildEnd;
  build_end_ = build_end;
}

void FrameTimingsRecorder::RecordRasterStart(fml::TimePoint raster_start) {
  std::scoped_lock state_lock(state_mutex_);
  FML_DCHECK(state_ == State::kBuildEnd);
  state_ = State::kRasterStart;
  raster_start_ = raster_start;
}

FrameTiming FrameTimingsRecorder::RecordRasterEnd() {
  std::scoped_lock state_lock(state_mutex_);
  FML_DCHECK(state_ == State::kRasterStart);
  state_ = State::kRasterEnd;
  raster_end_ = fml::TimePoint::Now();
  raster_end_wall_time_ = fml::TimePoint::CurrentWallTime();
  timing_.Set(FrameTiming::kVsyncStart, vsync_start_);
  timing_.Set(FrameTiming::kBuildStart, build_start_);
  timing_.Set(FrameTiming::kBuildFinish, build_end_);
  timing_.Set(FrameTiming::kRasterStart, raster_start_);
  timing_.Set(FrameTiming::kRasterFinish, raster_end_);
  timing_.Set(FrameTiming::kRasterFinishWallTime, raster_end_wall_time_);
  timing_.SetFrameNumber(GetFrameNumber());
  return timing_;
}

FrameTiming FrameTimingsRecorder::GetRecordedTime() const {
  std::scoped_lock state_lock(state_mutex_);
  FML_DCHECK(state_ == State::kRasterEnd);
  return timing_;
}

std::unique_ptr<FrameTimingsRecorder> FrameTimingsRecorder::CloneUntil(
    State state) {
  std::scoped_lock state_lock(state_mutex_);
  std::unique_ptr<FrameTimingsRecorder> recorder =
      std::make_unique<FrameTimingsRecorder>(frame_number_);
  recorder->state_ = state;

  if (state >= State::kVsync) {
    recorder->vsync_start_ = vsync_start_;
    recorder->vsync_target_ = vsync_target_;
  }

  if (state >= State::kBuildStart) {
    recorder->build_start_ = build_start_;
  }

  if (state >= State::kRasterEnd) {
    recorder->build_end_ = build_end_;
  }

  if (state >= State::kRasterStart) {
    recorder->raster_start_ = raster_start_;
  }

  if (state >= State::kRasterEnd) {
    recorder->raster_end_ = raster_end_;
  }

  return recorder;
}

uint64_t FrameTimingsRecorder::GetFrameNumber() const {
  return frame_number_;
}

const char* FrameTimingsRecorder::GetFrameNumberTraceArg() const {
  return frame_number_trace_arg_val_.c_str();
}

}  // namespace flutter
