// Copyright (c) 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GL_GPU_TIMING_H_
#define UI_GL_GPU_TIMING_H_

#include "base/callback.h"
#include "base/memory/scoped_ptr.h"
#include "ui/gl/gl_export.h"

// The gpu_timing classes handles the abstraction of GL GPU Timing extensions
// into a common set of functions. Currently the different timer extensions that
// are supported are EXT_timer_query, ARB_timer_query and
// EXT_disjoint_timer_query.
//
// Explanation of Classes:
//   GPUTiming - GPU Timing is a private class which is only owned by the
//     underlying GLContextReal class. This class handles any GL Context level
//     states which may need to be redistributed to users of GPUTiming. For
//     example, there exists only a single disjoint flag for each real GL
//     Context. Once the disjoint flag is checked, internally it is reset to
//     false. In order to support multiple virtual contexts each checking the
//     disjoint flag seperately, GPUTiming is in charge of checking the
//     disjoint flag and broadcasting out the disjoint state to all the
//     various users of GPUTiming (GPUTimingClient below).
//   GPUTimingClient - The GLContextReal holds the GPUTiming class and is the
//     factory that creates GPUTimingClient objects. If a user would like to
//     obtain various GPU times they would access CreateGPUTimingClient() from
//     their GLContext and use the returned object for their timing calls.
//     Each virtual context as well as any other classes which need GPU times
//     will hold one of these. When they want to time a set of GL commands they
//     will create GPUTimer objects.
//   GPUTimer - Once a user decides to time something, the user creates a new
//     GPUTimer object from a GPUTimingClient and issue Start() and Stop() calls
//     around various GL calls. Once IsAvailable() returns true, the GPU times
//     will be available through the various time stamp related functions.
//     The constructor and destructor of this object handles the actual
//     creation and deletion of the GL Queries within GL.

namespace gfx {

class GLContextReal;
class GPUTimingClient;

class GPUTiming {
 public:
  enum TimerType {
    kTimerTypeInvalid = -1,

    kTimerTypeEXT,      // EXT_timer_query
    kTimerTypeARB,      // ARB_timer_query
    kTimerTypeDisjoint  // EXT_disjoint_timer_query
  };

  TimerType GetTimerType() const { return timer_type_; }
  uint32_t GetDisjointCount();

 private:
  friend struct base::DefaultDeleter<GPUTiming>;
  friend class GLContextReal;
  friend class GPUTimer;
  explicit GPUTiming(GLContextReal* context);
  ~GPUTiming();

  scoped_refptr<GPUTimingClient> CreateGPUTimingClient();

  TimerType timer_type_ = kTimerTypeInvalid;
  uint32_t disjoint_counter_ = 0;
  DISALLOW_COPY_AND_ASSIGN(GPUTiming);
};

// Class to compute the amount of time it takes to fully
// complete a set of GL commands
class GL_EXPORT GPUTimer {
 public:
  ~GPUTimer();

  // Destroy the timer object. This must be explicitly called before destroying
  // this object.
  void Destroy(bool have_context);

  void Start();
  void End();
  bool IsAvailable();

  void GetStartEndTimestamps(int64* start, int64* end);
  int64 GetDeltaElapsed();

 private:
  friend class GPUTimingClient;

  explicit GPUTimer(scoped_refptr<GPUTimingClient> gpu_timing_client);

  unsigned int queries_[2];
  int64 offset_ = 0;
  bool end_requested_ = false;
  scoped_refptr<GPUTimingClient> gpu_timing_client_;

  DISALLOW_COPY_AND_ASSIGN(GPUTimer);
};

// GPUTimingClient contains all the gl timing logic that is not specific
// to a single GPUTimer.
class GL_EXPORT GPUTimingClient
    : public base::RefCounted<GPUTimingClient> {
 public:
  explicit GPUTimingClient(GPUTiming* gpu_timing = nullptr);

  scoped_ptr<GPUTimer> CreateGPUTimer();
  bool IsAvailable();
  bool IsTimerOffsetAvailable();

  const char* GetTimerTypeName() const;

  // CheckAndResetTimerErrors has to be called before reading timestamps
  // from GPUTimers instances and after making sure all the timers
  // were available.
  // If the returned value is false, all the previous timers should be
  // discarded.
  bool CheckAndResetTimerErrors();

  // Returns the offset between the current gpu time and the cpu time.
  int64 CalculateTimerOffset();
  void InvalidateTimerOffset();

  void SetCpuTimeForTesting(const base::Callback<int64(void)>& cpu_time);

 private:
  friend class base::RefCounted<GPUTimingClient>;
  friend class GPUTimer;
  friend class GPUTiming;

  virtual ~GPUTimingClient();

  GPUTiming* gpu_timing_;
  GPUTiming::TimerType timer_type_ = GPUTiming::kTimerTypeInvalid;
  int64 offset_ = 0;  // offset cache when timer_type_ == kTimerTypeARB
  uint32_t disjoint_counter_ = 0;
  bool offset_valid_ = false;
  base::Callback<int64(void)> cpu_time_for_testing_;

  DISALLOW_COPY_AND_ASSIGN(GPUTimingClient);
};

}  // namespace gfx

#endif  // UI_GL_GPU_TIMING_H_
