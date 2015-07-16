// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/events/gesture_detection/velocity_tracker.h"

#include <cmath>

#include "base/logging.h"
#include "ui/events/gesture_detection/motion_event.h"

using base::TimeDelta;
using base::TimeTicks;

namespace ui {

// Implements a particular velocity tracker algorithm.
class VelocityTrackerStrategy {
 public:
  virtual ~VelocityTrackerStrategy() {}

  virtual void Clear() = 0;
  virtual void ClearPointers(BitSet32 id_bits) = 0;
  virtual void AddMovement(const base::TimeTicks& event_time,
                           BitSet32 id_bits,
                           const Position* positions) = 0;
  virtual bool GetEstimator(uint32_t id, Estimator* out_estimator) const = 0;

 protected:
  VelocityTrackerStrategy() {}
};

namespace {

COMPILE_ASSERT(MotionEvent::MAX_POINTER_ID < 32, max_pointer_id_too_large);

// Threshold between ACTION_MOVE events for determining that a pointer has
// stopped moving. Some input devices do not send ACTION_MOVE events in the case
// where a pointer has stopped.  We need to detect this case so that we can
// accurately predict the velocity after the pointer starts moving again.
const int kAssumePointerMoveStoppedTimeMs = 40;

// Threshold between ACTION_MOVE and ACTION_{UP|POINTER_UP} events for
// determining that a pointer has stopped moving. This is a larger threshold
// than |kAssumePointerMoveStoppedTimeMs|, as some devices may delay synthesis
// of ACTION_{UP|POINTER_UP} to reduce risk of noisy release.
const int kAssumePointerUpStoppedTimeMs = 80;

struct Position {
  float x, y;
};

struct Estimator {
  static const uint8_t kMaxDegree = 4;

  // Estimator time base.
  TimeTicks time;

  // Polynomial coefficients describing motion in X and Y.
  float xcoeff[kMaxDegree + 1], ycoeff[kMaxDegree + 1];

  // Polynomial degree (number of coefficients), or zero if no information is
  // available.
  uint32_t degree;

  // Confidence (coefficient of determination), between 0 (no fit)
  // and 1 (perfect fit).
  float confidence;

  inline void Clear() {
    time = TimeTicks();
    degree = 0;
    confidence = 0;
    for (size_t i = 0; i <= kMaxDegree; i++) {
      xcoeff[i] = 0;
      ycoeff[i] = 0;
    }
  }
};

float VectorDot(const float* a, const float* b, uint32_t m) {
  float r = 0;
  while (m--) {
    r += *(a++) * *(b++);
  }
  return r;
}

float VectorNorm(const float* a, uint32_t m) {
  float r = 0;
  while (m--) {
    float t = *(a++);
    r += t * t;
  }
  return sqrtf(r);
}

// Velocity tracker algorithm based on least-squares linear regression.
class LeastSquaresVelocityTrackerStrategy : public VelocityTrackerStrategy {
 public:
  enum Weighting {
    // No weights applied.  All data points are equally reliable.
    WEIGHTING_NONE,

    // Weight by time delta.  Data points clustered together are weighted less.
    WEIGHTING_DELTA,

    // Weight such that points within a certain horizon are weighed more than
    // those outside of that horizon.
    WEIGHTING_CENTRAL,

    // Weight such that points older than a certain amount are weighed less.
    WEIGHTING_RECENT,
  };

  // Number of samples to keep.
  static const uint8_t kHistorySize = 20;

  // Degree must be no greater than Estimator::kMaxDegree.
  LeastSquaresVelocityTrackerStrategy(uint32_t degree,
                                      Weighting weighting = WEIGHTING_NONE);
  ~LeastSquaresVelocityTrackerStrategy() override;

  void Clear() override;
  void ClearPointers(BitSet32 id_bits) override;
  void AddMovement(const TimeTicks& event_time,
                   BitSet32 id_bits,
                   const Position* positions) override;
  bool GetEstimator(uint32_t id, Estimator* out_estimator) const override;

 private:
  // Sample horizon.
  // We don't use too much history by default since we want to react to quick
  // changes in direction.
  static const uint8_t kHorizonMS = 100;

  struct Movement {
    TimeTicks event_time;
    BitSet32 id_bits;
    Position positions[VelocityTracker::MAX_POINTERS];

    inline const Position& GetPosition(uint32_t id) const {
      return positions[id_bits.get_index_of_bit(id)];
    }
  };

  float ChooseWeight(uint32_t index) const;

  const uint32_t degree_;
  const Weighting weighting_;
  uint32_t index_;
  Movement movements_[kHistorySize];
};

// Velocity tracker algorithm that uses an IIR filter.
class IntegratingVelocityTrackerStrategy : public VelocityTrackerStrategy {
 public:
  // Degree must be 1 or 2.
  explicit IntegratingVelocityTrackerStrategy(uint32_t degree);
  ~IntegratingVelocityTrackerStrategy() override;

  void Clear() override;
  void ClearPointers(BitSet32 id_bits) override;
  void AddMovement(const TimeTicks& event_time,
                   BitSet32 id_bits,
                   const Position* positions) override;
  bool GetEstimator(uint32_t id, Estimator* out_estimator) const override;

 private:
  // Current state estimate for a particular pointer.
  struct State {
    TimeTicks update_time;
    uint32_t degree;

    float xpos, xvel, xaccel;
    float ypos, yvel, yaccel;
  };

  const uint32_t degree_;
  BitSet32 pointer_id_bits_;
  State mPointerState[MotionEvent::MAX_POINTER_ID + 1];

  void InitState(State& state,
                 const TimeTicks& event_time,
                 float xpos,
                 float ypos) const;
  void UpdateState(State& state,
                   const TimeTicks& event_time,
                   float xpos,
                   float ypos) const;
  void PopulateEstimator(const State& state, Estimator* out_estimator) const;
};

VelocityTrackerStrategy* CreateStrategy(VelocityTracker::Strategy strategy) {
  switch (strategy) {
    case VelocityTracker::LSQ1:
      return new LeastSquaresVelocityTrackerStrategy(1);
    case VelocityTracker::LSQ2:
      return new LeastSquaresVelocityTrackerStrategy(2);
    case VelocityTracker::LSQ3:
      return new LeastSquaresVelocityTrackerStrategy(3);
    case VelocityTracker::WLSQ2_DELTA:
      return new LeastSquaresVelocityTrackerStrategy(
          2, LeastSquaresVelocityTrackerStrategy::WEIGHTING_DELTA);
    case VelocityTracker::WLSQ2_CENTRAL:
      return new LeastSquaresVelocityTrackerStrategy(
          2, LeastSquaresVelocityTrackerStrategy::WEIGHTING_CENTRAL);
    case VelocityTracker::WLSQ2_RECENT:
      return new LeastSquaresVelocityTrackerStrategy(
          2, LeastSquaresVelocityTrackerStrategy::WEIGHTING_RECENT);
    case VelocityTracker::INT1:
      return new IntegratingVelocityTrackerStrategy(1);
    case VelocityTracker::INT2:
      return new IntegratingVelocityTrackerStrategy(2);
  }
  NOTREACHED() << "Unrecognized velocity tracker strategy: " << strategy;
  return CreateStrategy(VelocityTracker::STRATEGY_DEFAULT);
}

}  // namespace

// --- VelocityTracker ---

VelocityTracker::VelocityTracker()
    : current_pointer_id_bits_(0),
      active_pointer_id_(-1),
      strategy_(CreateStrategy(STRATEGY_DEFAULT)) {}

VelocityTracker::VelocityTracker(Strategy strategy)
    : current_pointer_id_bits_(0),
      active_pointer_id_(-1),
      strategy_(CreateStrategy(strategy)) {}

VelocityTracker::~VelocityTracker() {}

void VelocityTracker::Clear() {
  current_pointer_id_bits_.clear();
  active_pointer_id_ = -1;
  strategy_->Clear();
}

void VelocityTracker::ClearPointers(BitSet32 id_bits) {
  BitSet32 remaining_id_bits(current_pointer_id_bits_.value & ~id_bits.value);
  current_pointer_id_bits_ = remaining_id_bits;

  if (active_pointer_id_ >= 0 && id_bits.has_bit(active_pointer_id_)) {
    active_pointer_id_ = !remaining_id_bits.is_empty()
                             ? remaining_id_bits.first_marked_bit()
                             : -1;
  }

  strategy_->ClearPointers(id_bits);
}

void VelocityTracker::AddMovement(const TimeTicks& event_time,
                                  BitSet32 id_bits,
                                  const Position* positions) {
  while (id_bits.count() > MAX_POINTERS)
    id_bits.clear_last_marked_bit();

  if ((current_pointer_id_bits_.value & id_bits.value) &&
      (event_time - last_event_time_) >=
          base::TimeDelta::FromMilliseconds(kAssumePointerMoveStoppedTimeMs)) {
    // We have not received any movements for too long. Assume that all pointers
    // have stopped.
    strategy_->Clear();
  }
  last_event_time_ = event_time;

  current_pointer_id_bits_ = id_bits;
  if (active_pointer_id_ < 0 || !id_bits.has_bit(active_pointer_id_))
    active_pointer_id_ = id_bits.is_empty() ? -1 : id_bits.first_marked_bit();

  strategy_->AddMovement(event_time, id_bits, positions);
}

void VelocityTracker::AddMovement(const MotionEvent& event) {
  int32_t actionMasked = event.GetAction();

  switch (actionMasked) {
    case MotionEvent::ACTION_DOWN:
      // case MotionEvent::HOVER_ENTER:
      // Clear all pointers on down before adding the new movement.
      Clear();
      break;
    case MotionEvent::ACTION_POINTER_DOWN: {
      // Start a new movement trace for a pointer that just went down.
      // We do this on down instead of on up because the client may want to
      // query the final velocity for a pointer that just went up.
      BitSet32 downIdBits;
      downIdBits.mark_bit(event.GetPointerId(event.GetActionIndex()));
      ClearPointers(downIdBits);
      break;
    }
    case MotionEvent::ACTION_MOVE:
      // case MotionEvent::ACTION_HOVER_MOVE:
      break;
    case MotionEvent::ACTION_UP:
    case MotionEvent::ACTION_POINTER_UP:
      // Note that ACTION_UP and ACTION_POINTER_UP always report the last known
      // position of the pointers that went up.  ACTION_POINTER_UP does include
      // the new position of pointers that remained down but we will also
      // receive an ACTION_MOVE with this information if any of them actually
      // moved.  Since we don't know how many pointers will be going up at once
      // it makes sense to just wait for the following ACTION_MOVE before adding
      // the movement. However, if the up event itself is delayed because of
      // (difficult albeit possible) prolonged stationary screen contact, assume
      // that motion has stopped.
      if ((event.GetEventTime() - last_event_time_) >=
          base::TimeDelta::FromMilliseconds(kAssumePointerUpStoppedTimeMs))
        strategy_->Clear();
      return;
    default:
      // Ignore all other actions because they do not convey any new information
      // about pointer movement.  We also want to preserve the last known
      // velocity of the pointers.
      return;
  }

  size_t pointer_count = event.GetPointerCount();
  if (pointer_count > MAX_POINTERS) {
    pointer_count = MAX_POINTERS;
  }

  BitSet32 id_bits;
  for (size_t i = 0; i < pointer_count; i++) {
    id_bits.mark_bit(event.GetPointerId(i));
  }

  uint32_t pointer_index[MAX_POINTERS];
  for (size_t i = 0; i < pointer_count; i++) {
    pointer_index[i] = id_bits.get_index_of_bit(event.GetPointerId(i));
  }

  Position positions[MAX_POINTERS];
  size_t historySize = event.GetHistorySize();
  for (size_t h = 0; h < historySize; h++) {
    for (size_t i = 0; i < pointer_count; i++) {
      uint32_t index = pointer_index[i];
      positions[index].x = event.GetHistoricalX(i, h);
      positions[index].y = event.GetHistoricalY(i, h);
    }
    AddMovement(event.GetHistoricalEventTime(h), id_bits, positions);
  }

  for (size_t i = 0; i < pointer_count; i++) {
    uint32_t index = pointer_index[i];
    positions[index].x = event.GetX(i);
    positions[index].y = event.GetY(i);
  }
  AddMovement(event.GetEventTime(), id_bits, positions);
}

bool VelocityTracker::GetVelocity(uint32_t id,
                                  float* out_vx,
                                  float* out_vy) const {
  Estimator estimator;
  if (GetEstimator(id, &estimator) && estimator.degree >= 1) {
    *out_vx = estimator.xcoeff[1];
    *out_vy = estimator.ycoeff[1];
    return true;
  }
  *out_vx = 0;
  *out_vy = 0;
  return false;
}

void LeastSquaresVelocityTrackerStrategy::AddMovement(
    const TimeTicks& event_time,
    BitSet32 id_bits,
    const Position* positions) {
  if (++index_ == kHistorySize) {
    index_ = 0;
  }

  Movement& movement = movements_[index_];
  movement.event_time = event_time;
  movement.id_bits = id_bits;
  uint32_t count = id_bits.count();
  for (uint32_t i = 0; i < count; i++) {
    movement.positions[i] = positions[i];
  }
}

bool VelocityTracker::GetEstimator(uint32_t id,
                                   Estimator* out_estimator) const {
  return strategy_->GetEstimator(id, out_estimator);
}

// --- LeastSquaresVelocityTrackerStrategy ---

LeastSquaresVelocityTrackerStrategy::LeastSquaresVelocityTrackerStrategy(
    uint32_t degree,
    Weighting weighting)
    : degree_(degree), weighting_(weighting) {
  DCHECK_LT(degree_, static_cast<uint32_t>(Estimator::kMaxDegree));
  Clear();
}

LeastSquaresVelocityTrackerStrategy::~LeastSquaresVelocityTrackerStrategy() {}

void LeastSquaresVelocityTrackerStrategy::Clear() {
  index_ = 0;
  movements_[0].id_bits.clear();
}

/**
 * Solves a linear least squares problem to obtain a N degree polynomial that
 * fits the specified input data as nearly as possible.
 *
 * Returns true if a solution is found, false otherwise.
 *
 * The input consists of two vectors of data points X and Y with indices 0..m-1
 * along with a weight vector W of the same size.
 *
 * The output is a vector B with indices 0..n that describes a polynomial
 * that fits the data, such the sum of W[i] * W[i] * abs(Y[i] - (B[0] + B[1]
 * X[i] * + B[2] X[i]^2 ... B[n] X[i]^n)) for all i between 0 and m-1 is
 * minimized.
 *
 * Accordingly, the weight vector W should be initialized by the caller with the
 * reciprocal square root of the variance of the error in each input data point.
 * In other words, an ideal choice for W would be W[i] = 1 / var(Y[i]) = 1 /
 * stddev(Y[i]).
 * The weights express the relative importance of each data point.  If the
 * weights are* all 1, then the data points are considered to be of equal
 * importance when fitting the polynomial.  It is a good idea to choose weights
 * that diminish the importance of data points that may have higher than usual
 * error margins.
 *
 * Errors among data points are assumed to be independent.  W is represented
 * here as a vector although in the literature it is typically taken to be a
 * diagonal matrix.
 *
 * That is to say, the function that generated the input data can be
 * approximated by y(x) ~= B[0] + B[1] x + B[2] x^2 + ... + B[n] x^n.
 *
 * The coefficient of determination (R^2) is also returned to describe the
 * goodness of fit of the model for the given data.  It is a value between 0
 * and 1, where 1 indicates perfect correspondence.
 *
 * This function first expands the X vector to a m by n matrix A such that
 * A[i][0] = 1, A[i][1] = X[i], A[i][2] = X[i]^2, ..., A[i][n] = X[i]^n, then
 * multiplies it by w[i]./
 *
 * Then it calculates the QR decomposition of A yielding an m by m orthonormal
 * matrix Q and an m by n upper triangular matrix R.  Because R is upper
 * triangular (lower part is all zeroes), we can simplify the decomposition into
 * an m by n matrix Q1 and a n by n matrix R1 such that A = Q1 R1.
 *
 * Finally we solve the system of linear equations given by
 * R1 B = (Qtranspose W Y) to find B.
 *
 * For efficiency, we lay out A and Q column-wise in memory because we
 * frequently operate on the column vectors.  Conversely, we lay out R row-wise.
 *
 * http://en.wikipedia.org/wiki/Numerical_methods_for_linear_least_squares
 * http://en.wikipedia.org/wiki/Gram-Schmidt
 */
static bool SolveLeastSquares(const float* x,
                              const float* y,
                              const float* w,
                              uint32_t m,
                              uint32_t n,
                              float* out_b,
                              float* out_det) {
  // MSVC does not support variable-length arrays (used by the original Android
  // implementation of this function).
#if defined(COMPILER_MSVC)
  const uint32_t M_ARRAY_LENGTH =
      LeastSquaresVelocityTrackerStrategy::kHistorySize;
  const uint32_t N_ARRAY_LENGTH = Estimator::kMaxDegree;
  DCHECK_LE(m, M_ARRAY_LENGTH);
  DCHECK_LE(n, N_ARRAY_LENGTH);
#else
  const uint32_t M_ARRAY_LENGTH = m;
  const uint32_t N_ARRAY_LENGTH = n;
#endif

  // Expand the X vector to a matrix A, pre-multiplied by the weights.
  float a[N_ARRAY_LENGTH][M_ARRAY_LENGTH];  // column-major order
  for (uint32_t h = 0; h < m; h++) {
    a[0][h] = w[h];
    for (uint32_t i = 1; i < n; i++) {
      a[i][h] = a[i - 1][h] * x[h];
    }
  }

  // Apply the Gram-Schmidt process to A to obtain its QR decomposition.

  // Orthonormal basis, column-major order.
  float q[N_ARRAY_LENGTH][M_ARRAY_LENGTH];
  // Upper triangular matrix, row-major order.
  float r[N_ARRAY_LENGTH][N_ARRAY_LENGTH];
  for (uint32_t j = 0; j < n; j++) {
    for (uint32_t h = 0; h < m; h++) {
      q[j][h] = a[j][h];
    }
    for (uint32_t i = 0; i < j; i++) {
      float dot = VectorDot(&q[j][0], &q[i][0], m);
      for (uint32_t h = 0; h < m; h++) {
        q[j][h] -= dot * q[i][h];
      }
    }

    float norm = VectorNorm(&q[j][0], m);
    if (norm < 0.000001f) {
      // vectors are linearly dependent or zero so no solution
      return false;
    }

    float invNorm = 1.0f / norm;
    for (uint32_t h = 0; h < m; h++) {
      q[j][h] *= invNorm;
    }
    for (uint32_t i = 0; i < n; i++) {
      r[j][i] = i < j ? 0 : VectorDot(&q[j][0], &a[i][0], m);
    }
  }

  // Solve R B = Qt W Y to find B.  This is easy because R is upper triangular.
  // We just work from bottom-right to top-left calculating B's coefficients.
  float wy[M_ARRAY_LENGTH];
  for (uint32_t h = 0; h < m; h++) {
    wy[h] = y[h] * w[h];
  }
  for (uint32_t i = n; i-- != 0;) {
    out_b[i] = VectorDot(&q[i][0], wy, m);
    for (uint32_t j = n - 1; j > i; j--) {
      out_b[i] -= r[i][j] * out_b[j];
    }
    out_b[i] /= r[i][i];
  }

  // Calculate the coefficient of determination as 1 - (SSerr / SStot) where
  // SSerr is the residual sum of squares (variance of the error),
  // and SStot is the total sum of squares (variance of the data) where each
  // has been weighted.
  float ymean = 0;
  for (uint32_t h = 0; h < m; h++) {
    ymean += y[h];
  }
  ymean /= m;

  float sserr = 0;
  float sstot = 0;
  for (uint32_t h = 0; h < m; h++) {
    float err = y[h] - out_b[0];
    float term = 1;
    for (uint32_t i = 1; i < n; i++) {
      term *= x[h];
      err -= term * out_b[i];
    }
    sserr += w[h] * w[h] * err * err;
    float var = y[h] - ymean;
    sstot += w[h] * w[h] * var * var;
  }
  *out_det = sstot > 0.000001f ? 1.0f - (sserr / sstot) : 1;
  return true;
}

void LeastSquaresVelocityTrackerStrategy::ClearPointers(BitSet32 id_bits) {
  BitSet32 remaining_id_bits(movements_[index_].id_bits.value & ~id_bits.value);
  movements_[index_].id_bits = remaining_id_bits;
}

bool LeastSquaresVelocityTrackerStrategy::GetEstimator(
    uint32_t id,
    Estimator* out_estimator) const {
  out_estimator->Clear();

  // Iterate over movement samples in reverse time order and collect samples.
  float x[kHistorySize];
  float y[kHistorySize];
  float w[kHistorySize];
  float time[kHistorySize];
  uint32_t m = 0;
  uint32_t index = index_;
  const base::TimeDelta horizon = base::TimeDelta::FromMilliseconds(kHorizonMS);
  const Movement& newest_movement = movements_[index_];
  do {
    const Movement& movement = movements_[index];
    if (!movement.id_bits.has_bit(id))
      break;

    TimeDelta age = newest_movement.event_time - movement.event_time;
    if (age > horizon)
      break;

    const Position& position = movement.GetPosition(id);
    x[m] = position.x;
    y[m] = position.y;
    w[m] = ChooseWeight(index);
    time[m] = -static_cast<float>(age.InSecondsF());
    index = (index == 0 ? kHistorySize : index) - 1;
  } while (++m < kHistorySize);

  if (m == 0)
    return false;  // no data

  // Calculate a least squares polynomial fit.
  uint32_t degree = degree_;
  if (degree > m - 1)
    degree = m - 1;

  if (degree >= 1) {
    float xdet, ydet;
    uint32_t n = degree + 1;
    if (SolveLeastSquares(time, x, w, m, n, out_estimator->xcoeff, &xdet) &&
        SolveLeastSquares(time, y, w, m, n, out_estimator->ycoeff, &ydet)) {
      out_estimator->time = newest_movement.event_time;
      out_estimator->degree = degree;
      out_estimator->confidence = xdet * ydet;
      return true;
    }
  }

  // No velocity data available for this pointer, but we do have its current
  // position.
  out_estimator->xcoeff[0] = x[0];
  out_estimator->ycoeff[0] = y[0];
  out_estimator->time = newest_movement.event_time;
  out_estimator->degree = 0;
  out_estimator->confidence = 1;
  return true;
}

float LeastSquaresVelocityTrackerStrategy::ChooseWeight(uint32_t index) const {
  switch (weighting_) {
    case WEIGHTING_DELTA: {
      // Weight points based on how much time elapsed between them and the next
      // point so that points that "cover" a shorter time span are weighed less.
      //   delta  0ms: 0.5
      //   delta 10ms: 1.0
      if (index == index_) {
        return 1.0f;
      }
      uint32_t next_index = (index + 1) % kHistorySize;
      float delta_millis =
          static_cast<float>((movements_[next_index].event_time -
                              movements_[index].event_time).InMillisecondsF());
      if (delta_millis < 0)
        return 0.5f;
      if (delta_millis < 10)
        return 0.5f + delta_millis * 0.05f;

      return 1.0f;
    }

    case WEIGHTING_CENTRAL: {
      // Weight points based on their age, weighing very recent and very old
      // points less.
      //   age  0ms: 0.5
      //   age 10ms: 1.0
      //   age 50ms: 1.0
      //   age 60ms: 0.5
      float age_millis =
          static_cast<float>((movements_[index_].event_time -
                              movements_[index].event_time).InMillisecondsF());
      if (age_millis < 0)
        return 0.5f;
      if (age_millis < 10)
        return 0.5f + age_millis * 0.05f;
      if (age_millis < 50)
        return 1.0f;
      if (age_millis < 60)
        return 0.5f + (60 - age_millis) * 0.05f;

      return 0.5f;
    }

    case WEIGHTING_RECENT: {
      // Weight points based on their age, weighing older points less.
      //   age   0ms: 1.0
      //   age  50ms: 1.0
      //   age 100ms: 0.5
      float age_millis =
          static_cast<float>((movements_[index_].event_time -
                              movements_[index].event_time).InMillisecondsF());
      if (age_millis < 50) {
        return 1.0f;
      }
      if (age_millis < 100) {
        return 0.5f + (100 - age_millis) * 0.01f;
      }
      return 0.5f;
    }

    case WEIGHTING_NONE:
    default:
      return 1.0f;
  }
}

// --- IntegratingVelocityTrackerStrategy ---

IntegratingVelocityTrackerStrategy::IntegratingVelocityTrackerStrategy(
    uint32_t degree)
    : degree_(degree) {
  DCHECK_LT(degree_, static_cast<uint32_t>(Estimator::kMaxDegree));
}

IntegratingVelocityTrackerStrategy::~IntegratingVelocityTrackerStrategy() {}

void IntegratingVelocityTrackerStrategy::Clear() { pointer_id_bits_.clear(); }

void IntegratingVelocityTrackerStrategy::ClearPointers(BitSet32 id_bits) {
  pointer_id_bits_.value &= ~id_bits.value;
}

void IntegratingVelocityTrackerStrategy::AddMovement(
    const TimeTicks& event_time,
    BitSet32 id_bits,
    const Position* positions) {
  uint32_t index = 0;
  for (BitSet32 iter_id_bits(id_bits); !iter_id_bits.is_empty();) {
    uint32_t id = iter_id_bits.clear_first_marked_bit();
    State& state = mPointerState[id];
    const Position& position = positions[index++];
    if (pointer_id_bits_.has_bit(id))
      UpdateState(state, event_time, position.x, position.y);
    else
      InitState(state, event_time, position.x, position.y);
  }

  pointer_id_bits_ = id_bits;
}

bool IntegratingVelocityTrackerStrategy::GetEstimator(
    uint32_t id,
    Estimator* out_estimator) const {
  out_estimator->Clear();

  if (pointer_id_bits_.has_bit(id)) {
    const State& state = mPointerState[id];
    PopulateEstimator(state, out_estimator);
    return true;
  }

  return false;
}

void IntegratingVelocityTrackerStrategy::InitState(State& state,
                                                   const TimeTicks& event_time,
                                                   float xpos,
                                                   float ypos) const {
  state.update_time = event_time;
  state.degree = 0;
  state.xpos = xpos;
  state.xvel = 0;
  state.xaccel = 0;
  state.ypos = ypos;
  state.yvel = 0;
  state.yaccel = 0;
}

void IntegratingVelocityTrackerStrategy::UpdateState(
    State& state,
    const TimeTicks& event_time,
    float xpos,
    float ypos) const {
  const base::TimeDelta MIN_TIME_DELTA = TimeDelta::FromMicroseconds(2);
  const float FILTER_TIME_CONSTANT = 0.010f;  // 10 milliseconds

  if (event_time <= state.update_time + MIN_TIME_DELTA)
    return;

  float dt = static_cast<float>((event_time - state.update_time).InSecondsF());
  state.update_time = event_time;

  float xvel = (xpos - state.xpos) / dt;
  float yvel = (ypos - state.ypos) / dt;
  if (state.degree == 0) {
    state.xvel = xvel;
    state.yvel = yvel;
    state.degree = 1;
  } else {
    float alpha = dt / (FILTER_TIME_CONSTANT + dt);
    if (degree_ == 1) {
      state.xvel += (xvel - state.xvel) * alpha;
      state.yvel += (yvel - state.yvel) * alpha;
    } else {
      float xaccel = (xvel - state.xvel) / dt;
      float yaccel = (yvel - state.yvel) / dt;
      if (state.degree == 1) {
        state.xaccel = xaccel;
        state.yaccel = yaccel;
        state.degree = 2;
      } else {
        state.xaccel += (xaccel - state.xaccel) * alpha;
        state.yaccel += (yaccel - state.yaccel) * alpha;
      }
      state.xvel += (state.xaccel * dt) * alpha;
      state.yvel += (state.yaccel * dt) * alpha;
    }
  }
  state.xpos = xpos;
  state.ypos = ypos;
}

void IntegratingVelocityTrackerStrategy::PopulateEstimator(
    const State& state,
    Estimator* out_estimator) const {
  out_estimator->time = state.update_time;
  out_estimator->confidence = 1.0f;
  out_estimator->degree = state.degree;
  out_estimator->xcoeff[0] = state.xpos;
  out_estimator->xcoeff[1] = state.xvel;
  out_estimator->xcoeff[2] = state.xaccel / 2;
  out_estimator->ycoeff[0] = state.ypos;
  out_estimator->ycoeff[1] = state.yvel;
  out_estimator->ycoeff[2] = state.yaccel / 2;
}

}  // namespace ui
