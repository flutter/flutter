// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_EVENTS_GESTURE_DETECTION_VELOCITY_TRACKER_H_
#define UI_EVENTS_GESTURE_DETECTION_VELOCITY_TRACKER_H_

#include "base/basictypes.h"
#include "base/memory/scoped_ptr.h"
#include "base/time/time.h"
#include "ui/events/gesture_detection/bitset_32.h"

namespace ui {

class MotionEvent;
class VelocityTrackerStrategy;

namespace {
struct Estimator;
struct Position;
}

// Port of VelocityTracker from Android
// * platform/frameworks/native/include/input/VelocityTracker.h
// * Change-Id: I4983db61b53e28479fc90d9211fafff68f7f49a6
// * Please update the Change-Id as upstream Android changes are pulled.
class VelocityTracker {
 public:
  enum {
    // The maximum number of pointers to use when computing the velocity.
    // Note that the supplied MotionEvent may expose more than 16 pointers, but
    // at most |MAX_POINTERS| will be used.
    MAX_POINTERS = 16,
  };

  enum Strategy {
    // 1st order least squares.  Quality: POOR.
    // Frequently underfits the touch data especially when the finger
    // accelerates or changes direction.  Often underestimates velocity.  The
    // direction is overly influenced by historical touch points.
    LSQ1,

    // 2nd order least squares.  Quality: VERY GOOD.
    // Pretty much ideal, but can be confused by certain kinds of touch data,
    // particularly if the panel has a tendency to generate delayed,
    // duplicate or jittery touch coordinates when the finger is released.
    LSQ2,

    // 3rd order least squares.  Quality: UNUSABLE.
    // Frequently overfits the touch data yielding wildly divergent estimates
    // of the velocity when the finger is released.
    LSQ3,

    // 2nd order weighted least squares, delta weighting.
    // Quality: EXPERIMENTAL
    WLSQ2_DELTA,

    // 2nd order weighted least squares, central weighting.
    // Quality: EXPERIMENTAL
    WLSQ2_CENTRAL,

    // 2nd order weighted least squares, recent weighting.
    // Quality: EXPERIMENTAL
    WLSQ2_RECENT,

    // 1st order integrating filter.  Quality: GOOD.
    // Not as good as 'lsq2' because it cannot estimate acceleration but it is
    // more tolerant of errors.  Like 'lsq1', this strategy tends to
    // underestimate
    // the velocity of a fling but this strategy tends to respond to changes in
    // direction more quickly and accurately.
    INT1,

    // 2nd order integrating filter.  Quality: EXPERIMENTAL.
    // For comparison purposes only.  Unlike 'int1' this strategy can compensate
    // for acceleration but it typically overestimates the effect.
    INT2,
    STRATEGY_MAX = INT2,

    // The default velocity tracker strategy.
    // Although other strategies are available for testing and comparison
    // purposes, this is the strategy that applications will actually use.  Be
    // very careful when adjusting the default strategy because it can
    // dramatically affect (often in a bad way) the user experience.
    STRATEGY_DEFAULT = LSQ2,
  };

  // Creates a velocity tracker using the default strategy for the platform.
  VelocityTracker();

  // Creates a velocity tracker using the specified strategy.
  // If strategy is NULL, uses the default strategy for the platform.
  explicit VelocityTracker(Strategy strategy);

  ~VelocityTracker();

  // Resets the velocity tracker state.
  void Clear();

  // Adds movement information for all pointers in a MotionEvent, including
  // historical samples.
  void AddMovement(const MotionEvent& event);

  // Gets the velocity of the specified pointer id in position units per second.
  // Returns false and sets the velocity components to zero if there is
  // insufficient movement information for the pointer.
  bool GetVelocity(uint32_t id, float* outVx, float* outVy) const;

  // Gets the active pointer id, or -1 if none.
  inline int32_t GetActivePointerId() const { return active_pointer_id_; }

  // Gets a bitset containing all pointer ids from the most recent movement.
  inline BitSet32 GetCurrentPointerIdBits() const {
    return current_pointer_id_bits_;
  }

 private:
  // Resets the velocity tracker state for specific pointers.
  // Call this method when some pointers have changed and may be reusing
  // an id that was assigned to a different pointer earlier.
  void ClearPointers(BitSet32 id_bits);

  // Adds movement information for a set of pointers.
  // The id_bits bitfield specifies the pointer ids of the pointers whose
  // positions
  // are included in the movement.
  // The positions array contains position information for each pointer in order
  // by
  // increasing id.  Its size should be equal to the number of one bits in
  // id_bits.
  void AddMovement(const base::TimeTicks& event_time,
                   BitSet32 id_bits,
                   const Position* positions);

  // Gets an estimator for the recent movements of the specified pointer id.
  // Returns false and clears the estimator if there is no information available
  // about the pointer.
  bool GetEstimator(uint32_t id, Estimator* out_estimator) const;

  base::TimeTicks last_event_time_;
  BitSet32 current_pointer_id_bits_;
  int32_t active_pointer_id_;
  scoped_ptr<VelocityTrackerStrategy> strategy_;

  DISALLOW_COPY_AND_ASSIGN(VelocityTracker);
};

}  // namespace ui

#endif  // UI_EVENTS_GESTURE_DETECTION_VELOCITY_TRACKER_H_
