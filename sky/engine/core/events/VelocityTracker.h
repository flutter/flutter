// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is a largely a copy of ui/events/gesture_detection/velocity_tracker.h
// and ui/events/gesture_detection/bitset_32.h from https://chromium.googlesource.com.
// The VelocityTracker::AddMovement(const MotionEvent& event) method and a
// few of its supporting definitions have been removed.

#ifndef SKY_ENGINE_CORE_EVENTS_VELOCITY_TRACKER_H_
#define SKY_ENGINE_CORE_EVENTS_VELOCITY_TRACKER_H_

#include <stdint.h>

#include "base/memory/scoped_ptr.h"
#include "base/time/time.h"
#include "sky/engine/core/events/GestureVelocity.h"
#include "sky/engine/tonic/dart_wrappable.h"
#include "sky/engine/wtf/OwnPtr.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/RefCounted.h"

namespace blink {

class PointerEvent;
class VelocityTrackerStrategy;

namespace {
struct Estimator;
struct PointerXY;
}

// Port of VelocityTracker from Android
// * platform/frameworks/native/include/input/VelocityTracker.h
// * Change-Id: I4983db61b53e28479fc90d9211fafff68f7f49a6
// * Please update the Change-Id as upstream Android changes are pulled.
class VelocityTracker : public RefCounted<VelocityTracker>, public DartWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
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

  // VelocityTracker IDL implementation
  static PassRefPtr<VelocityTracker> create() {
    return adoptRef(new VelocityTracker());
  }
  void reset();
  void addPosition(int timeStamp, float x, float y);
  PassRefPtr<GestureVelocity> getVelocity();


  // Creates a velocity tracker using the default strategy for the platform.
  VelocityTracker();

  // Creates a velocity tracker using the specified strategy.
  // If strategy is NULL, uses the default strategy for the platform.
  explicit VelocityTracker(Strategy strategy);

  ~VelocityTracker();

  // Resets the velocity tracker state.
  void Clear();

  // Adds movement information for all pointers in a PointerEvent, including
  // historical samples.
  // void AddMovement(const PointerEvent& event);

  // Gets the velocity of the specified pointer id in position units per second.
  // Returns false and sets the velocity components to zero if there is
  // insufficient movement information for the pointer.
  bool GetVelocity(float* outVx, float* outVy) const;

 private:
  // Adds movement information for a pointer.
  // The id specifies the pointer id of the pointer whose position is included
  // in the movement.
  // position specifies the position information for the pointer.
  void AddMovement(const base::TimeTicks& event_time,
                   const PointerXY &position);

  // Gets an estimator for the recent movements of the specified pointer id.
  // Returns false and clears the estimator if there is no information available
  // about the pointer.
  bool GetEstimator(Estimator* out_estimator) const;

  base::TimeTicks last_event_time_;
  scoped_ptr<VelocityTrackerStrategy> strategy_;

  DISALLOW_COPY_AND_ASSIGN(VelocityTracker);
};

}  // namespace blink

#endif  // SKY_ENGINE_CORE_EVENTS_VELOCITY_TRACKER_H_
