// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Time represents an absolute point in coordinated universal time (UTC),
// internally represented as microseconds (s/1,000,000) since the Windows epoch
// (1601-01-01 00:00:00 UTC). System-dependent clock interface routines are
// defined in time_PLATFORM.cc. Note that values for Time may skew and jump
// around as the operating system makes adjustments to synchronize (e.g., with
// NTP servers). Thus, client code that uses the Time class must account for
// this.
//
// TimeDelta represents a duration of time, internally represented in
// microseconds.
//
// TimeTicks, ThreadTicks, and TraceTicks represent an abstract time that is
// most of the time incrementing, for use in measuring time durations.
// Internally, they are represented in microseconds. They can not be converted
// to a human-readable time, but are guaranteed not to decrease (unlike the Time
// class). Note that TimeTicks may "stand still" (e.g., if the computer is
// suspended), and ThreadTicks will "stand still" whenever the thread has been
// de-scheduled by the operating system.
//
// All time classes are copyable, assignable, and occupy 64-bits per
// instance. Thus, they can be efficiently passed by-value (as opposed to
// by-reference).
//
// Definitions of operator<< are provided to make these types work with
// DCHECK_EQ() and other log macros. For human-readable formatting, see
// "base/i18n/time_formatting.h".
//
// So many choices!  Which time class should you use?  Examples:
//
//   Time:        Interpreting the wall-clock time provided by a remote
//                system. Detecting whether cached resources have
//                expired. Providing the user with a display of the current date
//                and time. Determining the amount of time between events across
//                re-boots of the machine.
//
//   TimeTicks:   Tracking the amount of time a task runs. Executing delayed
//                tasks at the right time. Computing presentation timestamps.
//                Synchronizing audio and video using TimeTicks as a common
//                reference clock (lip-sync). Measuring network round-trip
//                latency.
//
//   ThreadTicks: Benchmarking how long the current thread has been doing actual
//                work.
//
//   TraceTicks:  This is only meant to be used by the event tracing
//                infrastructure, and by outside code modules in special
//                circumstances.  Please be sure to consult a
//                base/trace_event/OWNER before committing any new code that
//                uses this.

#ifndef BASE_TIME_TIME_H_
#define BASE_TIME_TIME_H_

#include <time.h>

#include <iosfwd>

#include "base/base_export.h"
#include "base/basictypes.h"
#include "base/numerics/safe_math.h"
#include "build/build_config.h"

#if defined(OS_MACOSX)
#include <CoreFoundation/CoreFoundation.h>
// Avoid Mac system header macro leak.
#undef TYPE_BOOL
#endif

#if defined(OS_POSIX)
#include <unistd.h>
#include <sys/time.h>
#endif

#if defined(OS_WIN)
// For FILETIME in FromFileTime, until it moves to a new converter class.
// See TODO(iyengar) below.
#include <windows.h>
#endif

#include <limits>

namespace base {

class TimeDelta;

// The functions in the time_internal namespace are meant to be used only by the
// time classes and functions.  Please use the math operators defined in the
// time classes instead.
namespace time_internal {

// Add or subtract |value| from a TimeDelta. The int64 argument and return value
// are in terms of a microsecond timebase.
BASE_EXPORT int64 SaturatedAdd(TimeDelta delta, int64 value);
BASE_EXPORT int64 SaturatedSub(TimeDelta delta, int64 value);

// Clamp |value| on overflow and underflow conditions. The int64 argument and
// return value are in terms of a microsecond timebase.
BASE_EXPORT int64 FromCheckedNumeric(const CheckedNumeric<int64> value);

}  // namespace time_internal

// TimeDelta ------------------------------------------------------------------

class BASE_EXPORT TimeDelta {
 public:
  TimeDelta() : delta_(0) {
  }

  // Converts units of time to TimeDeltas.
  static TimeDelta FromDays(int days);
  static TimeDelta FromHours(int hours);
  static TimeDelta FromMinutes(int minutes);
  static TimeDelta FromSeconds(int64 secs);
  static TimeDelta FromMilliseconds(int64 ms);
  static TimeDelta FromSecondsD(double secs);
  static TimeDelta FromMillisecondsD(double ms);
  static TimeDelta FromMicroseconds(int64 us);
#if defined(OS_WIN)
  static TimeDelta FromQPCValue(LONGLONG qpc_value);
#endif

  // Converts an integer value representing TimeDelta to a class. This is used
  // when deserializing a |TimeDelta| structure, using a value known to be
  // compatible. It is not provided as a constructor because the integer type
  // may be unclear from the perspective of a caller.
  static TimeDelta FromInternalValue(int64 delta) {
    return TimeDelta(delta);
  }

  // Returns the maximum time delta, which should be greater than any reasonable
  // time delta we might compare it to. Adding or subtracting the maximum time
  // delta to a time or another time delta has an undefined result.
  static TimeDelta Max();

  // Returns the internal numeric value of the TimeDelta object. Please don't
  // use this and do arithmetic on it, as it is more error prone than using the
  // provided operators.
  // For serializing, use FromInternalValue to reconstitute.
  int64 ToInternalValue() const {
    return delta_;
  }

  // Returns the magnitude (absolute value) of this TimeDelta.
  TimeDelta magnitude() const {
    // Some toolchains provide an incomplete C++11 implementation and lack an
    // int64 overload for std::abs().  The following is a simple branchless
    // implementation:
    const int64 mask = delta_ >> (sizeof(delta_) * 8 - 1);
    return TimeDelta((delta_ + mask) ^ mask);
  }

  // Returns true if the time delta is zero.
  bool is_zero() const {
    return delta_ == 0;
  }

  // Returns true if the time delta is the maximum time delta.
  bool is_max() const {
    return delta_ == std::numeric_limits<int64>::max();
  }

#if defined(OS_POSIX)
  struct timespec ToTimeSpec() const;
#endif

  // Returns the time delta in some unit. The F versions return a floating
  // point value, the "regular" versions return a rounded-down value.
  //
  // InMillisecondsRoundedUp() instead returns an integer that is rounded up
  // to the next full millisecond.
  int InDays() const;
  int InHours() const;
  int InMinutes() const;
  double InSecondsF() const;
  int64 InSeconds() const;
  double InMillisecondsF() const;
  int64 InMilliseconds() const;
  int64 InMillisecondsRoundedUp() const;
  int64 InMicroseconds() const;

  TimeDelta& operator=(TimeDelta other) {
    delta_ = other.delta_;
    return *this;
  }

  // Computations with other deltas.
  TimeDelta operator+(TimeDelta other) const {
    return TimeDelta(time_internal::SaturatedAdd(*this, other.delta_));
  }
  TimeDelta operator-(TimeDelta other) const {
    return TimeDelta(time_internal::SaturatedSub(*this, other.delta_));
  }

  TimeDelta& operator+=(TimeDelta other) {
    return *this = (*this + other);
  }
  TimeDelta& operator-=(TimeDelta other) {
    return *this = (*this - other);
  }
  TimeDelta operator-() const {
    return TimeDelta(-delta_);
  }

  // Computations with numeric types.
  template<typename T>
  TimeDelta operator*(T a) const {
    CheckedNumeric<int64> rv(delta_);
    rv *= a;
    return TimeDelta(time_internal::FromCheckedNumeric(rv));
  }
  template<typename T>
  TimeDelta operator/(T a) const {
    CheckedNumeric<int64> rv(delta_);
    rv /= a;
    return TimeDelta(time_internal::FromCheckedNumeric(rv));
  }
  template<typename T>
  TimeDelta& operator*=(T a) {
    return *this = (*this * a);
  }
  template<typename T>
  TimeDelta& operator/=(T a) {
    return *this = (*this / a);
  }

  int64 operator/(TimeDelta a) const {
    return delta_ / a.delta_;
  }
  TimeDelta operator%(TimeDelta a) const {
    return TimeDelta(delta_ % a.delta_);
  }

  // Comparison operators.
  bool operator==(TimeDelta other) const {
    return delta_ == other.delta_;
  }
  bool operator!=(TimeDelta other) const {
    return delta_ != other.delta_;
  }
  bool operator<(TimeDelta other) const {
    return delta_ < other.delta_;
  }
  bool operator<=(TimeDelta other) const {
    return delta_ <= other.delta_;
  }
  bool operator>(TimeDelta other) const {
    return delta_ > other.delta_;
  }
  bool operator>=(TimeDelta other) const {
    return delta_ >= other.delta_;
  }

 private:
  friend int64 time_internal::SaturatedAdd(TimeDelta delta, int64 value);
  friend int64 time_internal::SaturatedSub(TimeDelta delta, int64 value);

  // Constructs a delta given the duration in microseconds. This is private
  // to avoid confusion by callers with an integer constructor. Use
  // FromSeconds, FromMilliseconds, etc. instead.
  explicit TimeDelta(int64 delta_us) : delta_(delta_us) {
  }

  // Delta in microseconds.
  int64 delta_;
};

template<typename T>
inline TimeDelta operator*(T a, TimeDelta td) {
  return td * a;
}

// For logging use only.
BASE_EXPORT std::ostream& operator<<(std::ostream& os, TimeDelta time_delta);

// Do not reference the time_internal::TimeBase template class directly.  Please
// use one of the time subclasses instead, and only reference the public
// TimeBase members via those classes.
namespace time_internal {

// TimeBase--------------------------------------------------------------------

// Provides value storage and comparison/math operations common to all time
// classes. Each subclass provides for strong type-checking to ensure
// semantically meaningful comparison/math of time values from the same clock
// source or timeline.
template<class TimeClass>
class TimeBase {
 public:
  static const int64 kHoursPerDay = 24;
  static const int64 kMillisecondsPerSecond = 1000;
  static const int64 kMillisecondsPerDay = kMillisecondsPerSecond * 60 * 60 *
                                           kHoursPerDay;
  static const int64 kMicrosecondsPerMillisecond = 1000;
  static const int64 kMicrosecondsPerSecond = kMicrosecondsPerMillisecond *
                                              kMillisecondsPerSecond;
  static const int64 kMicrosecondsPerMinute = kMicrosecondsPerSecond * 60;
  static const int64 kMicrosecondsPerHour = kMicrosecondsPerMinute * 60;
  static const int64 kMicrosecondsPerDay = kMicrosecondsPerHour * kHoursPerDay;
  static const int64 kMicrosecondsPerWeek = kMicrosecondsPerDay * 7;
  static const int64 kNanosecondsPerMicrosecond = 1000;
  static const int64 kNanosecondsPerSecond = kNanosecondsPerMicrosecond *
                                             kMicrosecondsPerSecond;

  // Returns true if this object has not been initialized.
  //
  // Warning: Be careful when writing code that performs math on time values,
  // since it's possible to produce a valid "zero" result that should not be
  // interpreted as a "null" value.
  bool is_null() const {
    return us_ == 0;
  }

  // Returns true if this object represents the maximum time.
  bool is_max() const {
    return us_ == std::numeric_limits<int64>::max();
  }

  // For serializing only. Use FromInternalValue() to reconstitute. Please don't
  // use this and do arithmetic on it, as it is more error prone than using the
  // provided operators.
  int64 ToInternalValue() const {
    return us_;
  }

  TimeClass& operator=(TimeClass other) {
    us_ = other.us_;
    return *(static_cast<TimeClass*>(this));
  }

  // Compute the difference between two times.
  TimeDelta operator-(TimeClass other) const {
    return TimeDelta::FromMicroseconds(us_ - other.us_);
  }

  // Return a new time modified by some delta.
  TimeClass operator+(TimeDelta delta) const {
    return TimeClass(time_internal::SaturatedAdd(delta, us_));
  }
  TimeClass operator-(TimeDelta delta) const {
    return TimeClass(-time_internal::SaturatedSub(delta, us_));
  }

  // Modify by some time delta.
  TimeClass& operator+=(TimeDelta delta) {
    return static_cast<TimeClass&>(*this = (*this + delta));
  }
  TimeClass& operator-=(TimeDelta delta) {
    return static_cast<TimeClass&>(*this = (*this - delta));
  }

  // Comparison operators
  bool operator==(TimeClass other) const {
    return us_ == other.us_;
  }
  bool operator!=(TimeClass other) const {
    return us_ != other.us_;
  }
  bool operator<(TimeClass other) const {
    return us_ < other.us_;
  }
  bool operator<=(TimeClass other) const {
    return us_ <= other.us_;
  }
  bool operator>(TimeClass other) const {
    return us_ > other.us_;
  }
  bool operator>=(TimeClass other) const {
    return us_ >= other.us_;
  }

  // Converts an integer value representing TimeClass to a class. This is used
  // when deserializing a |TimeClass| structure, using a value known to be
  // compatible. It is not provided as a constructor because the integer type
  // may be unclear from the perspective of a caller.
  static TimeClass FromInternalValue(int64 us) {
    return TimeClass(us);
  }

 protected:
  explicit TimeBase(int64 us) : us_(us) {
  }

  // Time value in a microsecond timebase.
  int64 us_;
};

}  // namespace time_internal

template<class TimeClass>
inline TimeClass operator+(TimeDelta delta, TimeClass t) {
  return t + delta;
}

// Time -----------------------------------------------------------------------

// Represents a wall clock time in UTC. Values are not guaranteed to be
// monotonically non-decreasing and are subject to large amounts of skew.
class BASE_EXPORT Time : public time_internal::TimeBase<Time> {
 public:
  // The representation of Jan 1, 1970 UTC in microseconds since the
  // platform-dependent epoch.
  static const int64 kTimeTToMicrosecondsOffset;

#if !defined(OS_WIN)
  // On Mac & Linux, this value is the delta from the Windows epoch of 1601 to
  // the Posix delta of 1970. This is used for migrating between the old
  // 1970-based epochs to the new 1601-based ones. It should be removed from
  // this global header and put in the platform-specific ones when we remove the
  // migration code.
  static const int64 kWindowsEpochDeltaMicroseconds;
#else
  // To avoid overflow in QPC to Microseconds calculations, since we multiply
  // by kMicrosecondsPerSecond, then the QPC value should not exceed
  // (2^63 - 1) / 1E6. If it exceeds that threshold, we divide then multiply.
  static const int64 kQPCOverflowThreshold = 0x8637BD05AF7;
#endif

  // Represents an exploded time that can be formatted nicely. This is kind of
  // like the Win32 SYSTEMTIME structure or the Unix "struct tm" with a few
  // additions and changes to prevent errors.
  struct BASE_EXPORT Exploded {
    int year;          // Four digit year "2007"
    int month;         // 1-based month (values 1 = January, etc.)
    int day_of_week;   // 0-based day of week (0 = Sunday, etc.)
    int day_of_month;  // 1-based day of month (1-31)
    int hour;          // Hour within the current day (0-23)
    int minute;        // Minute within the current hour (0-59)
    int second;        // Second within the current minute (0-59 plus leap
                       //   seconds which may take it up to 60).
    int millisecond;   // Milliseconds within the current second (0-999)

    // A cursory test for whether the data members are within their
    // respective ranges. A 'true' return value does not guarantee the
    // Exploded value can be successfully converted to a Time value.
    bool HasValidValues() const;
  };

  // Contains the NULL time. Use Time::Now() to get the current time.
  Time() : TimeBase(0) {
  }

  // Returns the time for epoch in Unix-like system (Jan 1, 1970).
  static Time UnixEpoch();

  // Returns the current time. Watch out, the system might adjust its clock
  // in which case time will actually go backwards. We don't guarantee that
  // times are increasing, or that two calls to Now() won't be the same.
  static Time Now();

  // Returns the maximum time, which should be greater than any reasonable time
  // with which we might compare it.
  static Time Max();

  // Returns the current time. Same as Now() except that this function always
  // uses system time so that there are no discrepancies between the returned
  // time and system time even on virtual environments including our test bot.
  // For timing sensitive unittests, this function should be used.
  static Time NowFromSystemTime();

  // Converts to/from time_t in UTC and a Time class.
  // TODO(brettw) this should be removed once everybody starts using the |Time|
  // class.
  static Time FromTimeT(time_t tt);
  time_t ToTimeT() const;

  // Converts time to/from a double which is the number of seconds since epoch
  // (Jan 1, 1970).  Webkit uses this format to represent time.
  // Because WebKit initializes double time value to 0 to indicate "not
  // initialized", we map it to empty Time object that also means "not
  // initialized".
  static Time FromDoubleT(double dt);
  double ToDoubleT() const;

#if defined(OS_POSIX)
  // Converts the timespec structure to time. MacOS X 10.8.3 (and tentatively,
  // earlier versions) will have the |ts|'s tv_nsec component zeroed out,
  // having a 1 second resolution, which agrees with
  // https://developer.apple.com/legacy/library/#technotes/tn/tn1150.html#HFSPlusDates.
  static Time FromTimeSpec(const timespec& ts);
#endif

  // Converts to/from the Javascript convention for times, a number of
  // milliseconds since the epoch:
  // https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Date/getTime.
  static Time FromJsTime(double ms_since_epoch);
  double ToJsTime() const;

  // Converts to Java convention for times, a number of
  // milliseconds since the epoch.
  int64 ToJavaTime() const;

#if defined(OS_POSIX)
  static Time FromTimeVal(struct timeval t);
  struct timeval ToTimeVal() const;
#endif

#if defined(OS_MACOSX)
  static Time FromCFAbsoluteTime(CFAbsoluteTime t);
  CFAbsoluteTime ToCFAbsoluteTime() const;
#endif

#if defined(OS_WIN)
  static Time FromFileTime(FILETIME ft);
  FILETIME ToFileTime() const;

  // The minimum time of a low resolution timer.  This is basically a windows
  // constant of ~15.6ms.  While it does vary on some older OS versions, we'll
  // treat it as static across all windows versions.
  static const int kMinLowResolutionThresholdMs = 16;

  // Enable or disable Windows high resolution timer.
  static void EnableHighResolutionTimer(bool enable);

  // Activates or deactivates the high resolution timer based on the |activate|
  // flag.  If the HighResolutionTimer is not Enabled (see
  // EnableHighResolutionTimer), this function will return false.  Otherwise
  // returns true.  Each successful activate call must be paired with a
  // subsequent deactivate call.
  // All callers to activate the high resolution timer must eventually call
  // this function to deactivate the high resolution timer.
  static bool ActivateHighResolutionTimer(bool activate);

  // Returns true if the high resolution timer is both enabled and activated.
  // This is provided for testing only, and is not tracked in a thread-safe
  // way.
  static bool IsHighResolutionTimerInUse();
#endif

  // Converts an exploded structure representing either the local time or UTC
  // into a Time class.
  static Time FromUTCExploded(const Exploded& exploded) {
    return FromExploded(false, exploded);
  }
  static Time FromLocalExploded(const Exploded& exploded) {
    return FromExploded(true, exploded);
  }

  // Converts a string representation of time to a Time object.
  // An example of a time string which is converted is as below:-
  // "Tue, 15 Nov 1994 12:45:26 GMT". If the timezone is not specified
  // in the input string, FromString assumes local time and FromUTCString
  // assumes UTC. A timezone that cannot be parsed (e.g. "UTC" which is not
  // specified in RFC822) is treated as if the timezone is not specified.
  // TODO(iyengar) Move the FromString/FromTimeT/ToTimeT/FromFileTime to
  // a new time converter class.
  static bool FromString(const char* time_string, Time* parsed_time) {
    return FromStringInternal(time_string, true, parsed_time);
  }
  static bool FromUTCString(const char* time_string, Time* parsed_time) {
    return FromStringInternal(time_string, false, parsed_time);
  }

  // Fills the given exploded structure with either the local time or UTC from
  // this time structure (containing UTC).
  void UTCExplode(Exploded* exploded) const {
    return Explode(false, exploded);
  }
  void LocalExplode(Exploded* exploded) const {
    return Explode(true, exploded);
  }

  // Rounds this time down to the nearest day in local time. It will represent
  // midnight on that day.
  Time LocalMidnight() const;

 private:
  friend class time_internal::TimeBase<Time>;

  explicit Time(int64 us) : TimeBase(us) {
  }

  // Explodes the given time to either local time |is_local = true| or UTC
  // |is_local = false|.
  void Explode(bool is_local, Exploded* exploded) const;

  // Unexplodes a given time assuming the source is either local time
  // |is_local = true| or UTC |is_local = false|.
  static Time FromExploded(bool is_local, const Exploded& exploded);

  // Converts a string representation of time to a Time object.
  // An example of a time string which is converted is as below:-
  // "Tue, 15 Nov 1994 12:45:26 GMT". If the timezone is not specified
  // in the input string, local time |is_local = true| or
  // UTC |is_local = false| is assumed. A timezone that cannot be parsed
  // (e.g. "UTC" which is not specified in RFC822) is treated as if the
  // timezone is not specified.
  static bool FromStringInternal(const char* time_string,
                                 bool is_local,
                                 Time* parsed_time);
};

// Inline the TimeDelta factory methods, for fast TimeDelta construction.

// static
inline TimeDelta TimeDelta::FromDays(int days) {
  // Preserve max to prevent overflow.
  if (days == std::numeric_limits<int>::max())
    return Max();
  return TimeDelta(days * Time::kMicrosecondsPerDay);
}

// static
inline TimeDelta TimeDelta::FromHours(int hours) {
  // Preserve max to prevent overflow.
  if (hours == std::numeric_limits<int>::max())
    return Max();
  return TimeDelta(hours * Time::kMicrosecondsPerHour);
}

// static
inline TimeDelta TimeDelta::FromMinutes(int minutes) {
  // Preserve max to prevent overflow.
  if (minutes == std::numeric_limits<int>::max())
    return Max();
  return TimeDelta(minutes * Time::kMicrosecondsPerMinute);
}

// static
inline TimeDelta TimeDelta::FromSeconds(int64 secs) {
  // Preserve max to prevent overflow.
  if (secs == std::numeric_limits<int64>::max())
    return Max();
  return TimeDelta(secs * Time::kMicrosecondsPerSecond);
}

// static
inline TimeDelta TimeDelta::FromMilliseconds(int64 ms) {
  // Preserve max to prevent overflow.
  if (ms == std::numeric_limits<int64>::max())
    return Max();
  return TimeDelta(ms * Time::kMicrosecondsPerMillisecond);
}

// static
inline TimeDelta TimeDelta::FromSecondsD(double secs) {
  // Preserve max to prevent overflow.
  if (secs == std::numeric_limits<double>::infinity())
    return Max();
  return TimeDelta(static_cast<int64>(secs * Time::kMicrosecondsPerSecond));
}

// static
inline TimeDelta TimeDelta::FromMillisecondsD(double ms) {
  // Preserve max to prevent overflow.
  if (ms == std::numeric_limits<double>::infinity())
    return Max();
  return TimeDelta(static_cast<int64>(ms * Time::kMicrosecondsPerMillisecond));
}

// static
inline TimeDelta TimeDelta::FromMicroseconds(int64 us) {
  // Preserve max to prevent overflow.
  if (us == std::numeric_limits<int64>::max())
    return Max();
  return TimeDelta(us);
}

// For logging use only.
BASE_EXPORT std::ostream& operator<<(std::ostream& os, Time time);

// TimeTicks ------------------------------------------------------------------

// Represents monotonically non-decreasing clock time.
class BASE_EXPORT TimeTicks : public time_internal::TimeBase<TimeTicks> {
 public:
  TimeTicks() : TimeBase(0) {
  }

  // Platform-dependent tick count representing "right now." When
  // IsHighResolution() returns false, the resolution of the clock could be
  // as coarse as ~15.6ms. Otherwise, the resolution should be no worse than one
  // microsecond.
  static TimeTicks Now();

  // Returns true if the high resolution clock is working on this system and
  // Now() will return high resolution values. Note that, on systems where the
  // high resolution clock works but is deemed inefficient, the low resolution
  // clock will be used instead.
  static bool IsHighResolution();

#if defined(OS_WIN)
  // Translates an absolute QPC timestamp into a TimeTicks value. The returned
  // value has the same origin as Now(). Do NOT attempt to use this if
  // IsHighResolution() returns false.
  static TimeTicks FromQPCValue(LONGLONG qpc_value);
#endif

  // Get the TimeTick value at the time of the UnixEpoch. This is useful when
  // you need to relate the value of TimeTicks to a real time and date.
  // Note: Upon first invocation, this function takes a snapshot of the realtime
  // clock to establish a reference point.  This function will return the same
  // value for the duration of the application, but will be different in future
  // application runs.
  static TimeTicks UnixEpoch();

  // Returns |this| snapped to the next tick, given a |tick_phase| and
  // repeating |tick_interval| in both directions. |this| may be before,
  // after, or equal to the |tick_phase|.
  TimeTicks SnappedToNextTick(TimeTicks tick_phase,
                              TimeDelta tick_interval) const;

#if defined(OS_WIN)
 protected:
  typedef DWORD (*TickFunctionType)(void);
  static TickFunctionType SetMockTickFunction(TickFunctionType ticker);
#endif

 private:
  friend class time_internal::TimeBase<TimeTicks>;

  // Please use Now() to create a new object. This is for internal use
  // and testing.
  explicit TimeTicks(int64 us) : TimeBase(us) {
  }
};

// For logging use only.
BASE_EXPORT std::ostream& operator<<(std::ostream& os, TimeTicks time_ticks);

// ThreadTicks ----------------------------------------------------------------

// Represents a clock, specific to a particular thread, than runs only while the
// thread is running.
class BASE_EXPORT ThreadTicks : public time_internal::TimeBase<ThreadTicks> {
 public:
  ThreadTicks() : TimeBase(0) {
  }

  // Returns true if ThreadTicks::Now() is supported on this system.
  static bool IsSupported() {
#if (defined(_POSIX_THREAD_CPUTIME) && (_POSIX_THREAD_CPUTIME >= 0)) || \
    (defined(OS_MACOSX) && !defined(OS_IOS)) || defined(OS_ANDROID)
    return true;
#else
    return false;
#endif
  }

  // Returns thread-specific CPU-time on systems that support this feature.
  // Needs to be guarded with a call to IsSupported(). Use this timer
  // to (approximately) measure how much time the calling thread spent doing
  // actual work vs. being de-scheduled. May return bogus results if the thread
  // migrates to another CPU between two calls.
  static ThreadTicks Now();

 private:
  friend class time_internal::TimeBase<ThreadTicks>;

  // Please use Now() to create a new object. This is for internal use
  // and testing.
  explicit ThreadTicks(int64 us) : TimeBase(us) {
  }
};

// For logging use only.
BASE_EXPORT std::ostream& operator<<(std::ostream& os, ThreadTicks time_ticks);

// TraceTicks ----------------------------------------------------------------

// Represents high-resolution system trace clock time.
class BASE_EXPORT TraceTicks : public time_internal::TimeBase<TraceTicks> {
 public:
  // We define this even without OS_CHROMEOS for seccomp sandbox testing.
#if defined(OS_LINUX)
  // Force definition of the system trace clock; it is a chromeos-only api
  // at the moment and surfacing it in the right place requires mucking
  // with glibc et al.
  static const clockid_t kClockSystemTrace = 11;
#endif

  TraceTicks() : TimeBase(0) {
  }

  // Returns the current system trace time or, if not available on this
  // platform, a high-resolution time value; or a low-resolution time value if
  // neither are avalable. On systems where a global trace clock is defined,
  // timestamping TraceEvents's with this value guarantees synchronization
  // between events collected inside chrome and events collected outside
  // (e.g. kernel, X server).
  //
  // On some platforms, the clock source used for tracing can vary depending on
  // hardware and/or kernel support.  Do not make any assumptions without
  // consulting the documentation for this functionality in the time_win.cc,
  // time_posix.cc, etc. files.
  //
  // NOTE: This is only meant to be used by the event tracing infrastructure,
  // and by outside code modules in special circumstances.  Please be sure to
  // consult a base/trace_event/OWNER before committing any new code that uses
  // this.
  static TraceTicks Now();

 private:
  friend class time_internal::TimeBase<TraceTicks>;

  // Please use Now() to create a new object. This is for internal use
  // and testing.
  explicit TraceTicks(int64 us) : TimeBase(us) {
  }
};

// For logging use only.
BASE_EXPORT std::ostream& operator<<(std::ostream& os, TraceTicks time_ticks);

}  // namespace base

#endif  // BASE_TIME_TIME_H_
