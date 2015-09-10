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

// Port of BitSet32 from Android
// * platform/system/core/include/utils/BitSet.h
// * Change-Id: I9bbf41f9d2d4a2593b0e6d7d8be7e283f985bade
// * Please update the Change-Id as upstream Android changes are pulled.
struct BitSet32 {
  uint32_t value;

  inline BitSet32() : value(0) {}
  explicit inline BitSet32(uint32_t value) : value(value) {}

  // Gets the value associated with a particular bit index.
  static inline uint32_t value_for_bit(uint32_t n) {
    DCHECK_LE(n, 31U);
    return 0x80000000 >> n;
  }

  // Clears the bit set.
  inline void clear() { value = 0; }

  // Returns the number of marked bits in the set.
  inline uint32_t count() const { return popcnt(value); }

  // Returns true if the bit set does not contain any marked bits.
  inline bool is_empty() const { return !value; }

  // Returns true if the bit set does not contain any unmarked bits.
  inline bool is_full() const { return value == 0xffffffff; }

  // Returns true if the specified bit is marked.
  inline bool has_bit(uint32_t n) const {
    return (value & value_for_bit(n)) != 0;
  }

  // Marks the specified bit.
  inline void mark_bit(uint32_t n) { value |= value_for_bit(n); }

  // Clears the specified bit.
  inline void clear_bit(uint32_t n) { value &= ~value_for_bit(n); }

  // Finds the first marked bit in the set.
  // Result is undefined if all bits are unmarked.
  inline uint32_t first_marked_bit() const { return clz(value); }

  // Finds the first unmarked bit in the set.
  // Result is undefined if all bits are marked.
  inline uint32_t first_unmarked_bit() const { return clz(~value); }

  // Finds the last marked bit in the set.
  // Result is undefined if all bits are unmarked.
  inline uint32_t last_marked_bit() const { return 31 - ctz(value); }

  // Finds the first marked bit in the set and clears it.  Returns the bit
  // index.
  // Result is undefined if all bits are unmarked.
  inline uint32_t clear_first_marked_bit() {
    uint32_t n = first_marked_bit();
    clear_bit(n);
    return n;
  }

  // Finds the first unmarked bit in the set and marks it.  Returns the bit
  // index.
  // Result is undefined if all bits are marked.
  inline uint32_t mark_first_unmarked_bit() {
    uint32_t n = first_unmarked_bit();
    mark_bit(n);
    return n;
  }

  // Finds the last marked bit in the set and clears it.  Returns the bit index.
  // Result is undefined if all bits are unmarked.
  inline uint32_t clear_last_marked_bit() {
    uint32_t n = last_marked_bit();
    clear_bit(n);
    return n;
  }

  // Gets the inde of the specified bit in the set, which is the number of
  // marked bits that appear before the specified bit.
  inline uint32_t get_index_of_bit(uint32_t n) const {
    DCHECK_LE(n, 31U);
    return popcnt(value & ~(0xffffffffUL >> n));
  }

  inline bool operator==(const BitSet32& other) const {
    return value == other.value;
  }
  inline bool operator!=(const BitSet32& other) const {
    return value != other.value;
  }

 private:
#if defined(COMPILER_GCC) || defined(__clang__)
  static inline uint32_t popcnt(uint32_t v) { return __builtin_popcount(v); }
  static inline uint32_t clz(uint32_t v) { return __builtin_clz(v); }
  static inline uint32_t ctz(uint32_t v) { return __builtin_ctz(v); }
#else
  // http://graphics.stanford.edu/~seander/bithacks.html#CountBitsSetParallel
  static inline uint32_t popcnt(uint32_t v) {
    v = v - ((v >> 1) & 0x55555555);
    v = (v & 0x33333333) + ((v >> 2) & 0x33333333);
    return (((v + (v >> 4)) & 0x0F0F0F0F) * 0x01010101) >> 24;
  }
  // TODO(jdduke): Use intrinsics (BitScan{Forward,Reverse}) with MSVC.
  static inline uint32_t clz(uint32_t v) {
    v |= (v >> 1);
    v |= (v >> 2);
    v |= (v >> 4);
    v |= (v >> 8);
    v |= (v >> 16);
    return 32 - popcnt(v);
  }
  static inline uint32_t ctz(uint32_t v) {
    return popcnt((v & static_cast<uint32_t>(-static_cast<int>(v))) - 1);
  }
#endif
};

// Port of VelocityTracker from Android
// * platform/frameworks/native/include/input/VelocityTracker.h
// * Change-Id: I4983db61b53e28479fc90d9211fafff68f7f49a6
// * Please update the Change-Id as upstream Android changes are pulled.
class VelocityTracker : public RefCounted<VelocityTracker>, public DartWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
  enum {
    // The maximum number of pointers to use when computing the velocity.
    // Note that the supplied PointerEvent may expose more than 16 pointers, but
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

  // VelocityTracker IDL implementation
  static PassRefPtr<VelocityTracker> create() {
    return adoptRef(new VelocityTracker());
  }
  void reset();
  void addPosition(int timeStamp, int pointerId, float x, float y);
  PassRefPtr<GestureVelocity> getVelocity(int pointerId);


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
                   const PointerXY* positions);

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

}  // namespace blink

#endif  // SKY_ENGINE_CORE_EVENTS_VELOCITY_TRACKER_H_
