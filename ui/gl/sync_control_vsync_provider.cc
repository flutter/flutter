// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gl/sync_control_vsync_provider.h"

#include <math.h>

#include "base/logging.h"
#include "base/time/time.h"

#if defined(OS_LINUX)
// These constants define a reasonable range for a calculated refresh interval.
// Calculating refreshes out of this range will be considered a fatal error.
const int64 kMinVsyncIntervalUs = base::Time::kMicrosecondsPerSecond / 400;
const int64 kMaxVsyncIntervalUs = base::Time::kMicrosecondsPerSecond / 10;

// How much noise we'll tolerate between successive computed intervals before
// we think the latest computed interval is invalid (noisey due to
// monitor configuration change, moving a window between monitors, etc.).
const double kRelativeIntervalDifferenceThreshold = 0.05;
#endif

namespace gfx {

SyncControlVSyncProvider::SyncControlVSyncProvider()
    : VSyncProvider(), last_media_stream_counter_(0), invalid_msc_(false) {
  // On platforms where we can't get an accurate reading on the refresh
  // rate we fall back to the assumption that we're displaying 60 frames
  // per second.
  last_good_interval_ = base::TimeDelta::FromSeconds(1) / 60;
}

SyncControlVSyncProvider::~SyncControlVSyncProvider() {}

void SyncControlVSyncProvider::GetVSyncParameters(
    const UpdateVSyncCallback& callback) {
#if defined(OS_LINUX)
  base::TimeTicks timebase;

  // The actual clock used for the system time returned by glXGetSyncValuesOML
  // is unspecified. In practice, the clock used is likely to be either
  // CLOCK_REALTIME or CLOCK_MONOTONIC, so we compare the returned time to the
  // current time according to both clocks, and assume that the returned time
  // was produced by the clock whose current time is closest to it, subject
  // to the restriction that the returned time must not be in the future
  // (since it is the time of a vblank that has already occurred).
  int64 system_time;
  int64 media_stream_counter;
  int64 swap_buffer_counter;
  if (!GetSyncValues(&system_time, &media_stream_counter, &swap_buffer_counter))
    return;

  // Both Intel and Mali drivers will return TRUE for GetSyncValues
  // but a value of 0 for MSC if they cannot access the CRTC data structure
  // associated with the surface. crbug.com/231945
  bool prev_invalid_msc = invalid_msc_;
  invalid_msc_ = (media_stream_counter == 0);
  if (invalid_msc_) {
    LOG_IF(ERROR, !prev_invalid_msc) << "glXGetSyncValuesOML "
        "should not return TRUE with a media stream counter of 0.";
    return;
  }

  struct timespec real_time;
  struct timespec monotonic_time;
  clock_gettime(CLOCK_REALTIME, &real_time);
  clock_gettime(CLOCK_MONOTONIC, &monotonic_time);

  int64 real_time_in_microseconds =
      real_time.tv_sec * base::Time::kMicrosecondsPerSecond +
      real_time.tv_nsec / base::Time::kNanosecondsPerMicrosecond;
  int64 monotonic_time_in_microseconds =
      monotonic_time.tv_sec * base::Time::kMicrosecondsPerSecond +
      monotonic_time.tv_nsec / base::Time::kNanosecondsPerMicrosecond;

  // We need the time according to CLOCK_MONOTONIC, so if we've been given
  // a time from CLOCK_REALTIME, we need to convert.
  bool time_conversion_needed =
      llabs(system_time - real_time_in_microseconds) <
      llabs(system_time - monotonic_time_in_microseconds);

  if (time_conversion_needed)
    system_time += monotonic_time_in_microseconds - real_time_in_microseconds;

  // Return if |system_time| is more than 1 frames in the future.
  int64 interval_in_microseconds = last_good_interval_.InMicroseconds();
  if (system_time > monotonic_time_in_microseconds + interval_in_microseconds)
    return;

  // If |system_time| is slightly in the future, adjust it to the previous
  // frame and use the last frame counter to prevent issues in the callback.
  if (system_time > monotonic_time_in_microseconds) {
    system_time -= interval_in_microseconds;
    media_stream_counter--;
  }
  if (monotonic_time_in_microseconds - system_time >
      base::Time::kMicrosecondsPerSecond)
    return;

  timebase = base::TimeTicks::FromInternalValue(system_time);

  // Only need the previous calculated interval for our filtering.
  while (last_computed_intervals_.size() > 1)
    last_computed_intervals_.pop();

  int32 numerator, denominator;
  if (GetMscRate(&numerator, &denominator)) {
    last_computed_intervals_.push(base::TimeDelta::FromSeconds(denominator) /
                                  numerator);
  } else if (!last_timebase_.is_null()) {
    base::TimeDelta timebase_diff = timebase - last_timebase_;
    int64 counter_diff = media_stream_counter - last_media_stream_counter_;
    if (counter_diff > 0 && timebase > last_timebase_)
      last_computed_intervals_.push(timebase_diff / counter_diff);
  }

  if (last_computed_intervals_.size() == 2) {
    const base::TimeDelta& old_interval = last_computed_intervals_.front();
    const base::TimeDelta& new_interval = last_computed_intervals_.back();

    double relative_change =
        fabs(old_interval.InMillisecondsF() - new_interval.InMillisecondsF()) /
        new_interval.InMillisecondsF();
    if (relative_change < kRelativeIntervalDifferenceThreshold) {
      if (new_interval.InMicroseconds() < kMinVsyncIntervalUs ||
          new_interval.InMicroseconds() > kMaxVsyncIntervalUs) {
#if defined(USE_ASH)
        // On ash platforms (ChromeOS essentially), the real refresh interval is
        // queried from XRandR, regardless of the value calculated here, and
        // this value is overriden by ui::CompositorVSyncManager.  The log
        // should not be fatal in this case. Reconsider all this when XRandR
        // support is added to non-ash platforms.
        // http://crbug.com/340851
        LOG(ERROR)
#else
        LOG(FATAL)
#endif  // USE_ASH
            << "Calculated bogus refresh interval="
            << new_interval.InMicroseconds()
            << " us., last_timebase_=" << last_timebase_.ToInternalValue()
            << " us., timebase=" << timebase.ToInternalValue()
            << " us., last_media_stream_counter_=" << last_media_stream_counter_
            << ", media_stream_counter=" << media_stream_counter;
      } else {
        last_good_interval_ = new_interval;
      }
    }
  }

  last_timebase_ = timebase;
  last_media_stream_counter_ = media_stream_counter;
  callback.Run(timebase, last_good_interval_);
#endif  // defined(OS_LINUX)
}

}  // namespace gfx
