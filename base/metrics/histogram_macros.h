// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_METRICS_HISTOGRAM_MACROS_H_
#define BASE_METRICS_HISTOGRAM_MACROS_H_

#include "base/atomicops.h"
#include "base/basictypes.h"
#include "base/logging.h"
#include "base/metrics/histogram.h"
#include "base/time/time.h"

//------------------------------------------------------------------------------
// Histograms are often put in areas where they are called many many times, and
// performance is critical.  As a result, they are designed to have a very low
// recurring cost of executing (adding additional samples).  Toward that end,
// the macros declare a static pointer to the histogram in question, and only
// take a "slow path" to construct (or find) the histogram on the first run
// through the macro.  We leak the histograms at shutdown time so that we don't
// have to validate using the pointers at any time during the running of the
// process.

// The following code is generally what a thread-safe static pointer
// initialization looks like for a histogram (after a macro is expanded).  This
// sample is an expansion (with comments) of the code for
// LOCAL_HISTOGRAM_CUSTOM_COUNTS().

/*
  do {
    // The pointer's presence indicates the initialization is complete.
    // Initialization is idempotent, so it can safely be atomically repeated.
    static base::subtle::AtomicWord atomic_histogram_pointer = 0;

    // Acquire_Load() ensures that we acquire visibility to the pointed-to data
    // in the histogram.
    base::Histogram* histogram_pointer(reinterpret_cast<base::Histogram*>(
        base::subtle::Acquire_Load(&atomic_histogram_pointer)));

    if (!histogram_pointer) {
      // This is the slow path, which will construct OR find the matching
      // histogram.  FactoryGet includes locks on a global histogram name map
      // and is completely thread safe.
      histogram_pointer = base::Histogram::FactoryGet(
          name, min, max, bucket_count, base::HistogramBase::kNoFlags);

      // Use Release_Store to ensure that the histogram data is made available
      // globally before we make the pointer visible.
      // Several threads may perform this store, but the same value will be
      // stored in all cases (for a given named/spec'ed histogram).
      // We could do this without any barrier, since FactoryGet entered and
      // exited a lock after construction, but this barrier makes things clear.
      base::subtle::Release_Store(&atomic_histogram_pointer,
          reinterpret_cast<base::subtle::AtomicWord>(histogram_pointer));
    }

    // Ensure calling contract is upheld, and the name does NOT vary.
    DCHECK(histogram_pointer->histogram_name() == constant_histogram_name);

    histogram_pointer->Add(sample);
  } while (0);
*/

// The above pattern is repeated in several macros.  The only elements that
// vary are the invocation of the Add(sample) vs AddTime(sample), and the choice
// of which FactoryGet method to use.  The different FactoryGet methods have
// various argument lists, so the function with its argument list is provided as
// a macro argument here.  The name is only used in a DCHECK, to assure that
// callers don't try to vary the name of the histogram (which would tend to be
// ignored by the one-time initialization of the histogtram_pointer).
#define STATIC_HISTOGRAM_POINTER_BLOCK(constant_histogram_name,           \
                                       histogram_add_method_invocation,   \
                                       histogram_factory_get_invocation)  \
  do {                                                                    \
    static base::subtle::AtomicWord atomic_histogram_pointer = 0;         \
    base::HistogramBase* histogram_pointer(                               \
        reinterpret_cast<base::HistogramBase*>(                           \
            base::subtle::Acquire_Load(&atomic_histogram_pointer)));      \
    if (!histogram_pointer) {                                             \
      histogram_pointer = histogram_factory_get_invocation;               \
      base::subtle::Release_Store(                                        \
          &atomic_histogram_pointer,                                      \
          reinterpret_cast<base::subtle::AtomicWord>(histogram_pointer)); \
    }                                                                     \
    if (DCHECK_IS_ON())                                                   \
      histogram_pointer->CheckName(constant_histogram_name);              \
    histogram_pointer->histogram_add_method_invocation;                   \
  } while (0)

//------------------------------------------------------------------------------
// Provide easy general purpose histogram in a macro, just like stats counters.
// The first four macros use 50 buckets.

#define LOCAL_HISTOGRAM_TIMES(name, sample) LOCAL_HISTOGRAM_CUSTOM_TIMES( \
    name, sample, base::TimeDelta::FromMilliseconds(1), \
    base::TimeDelta::FromSeconds(10), 50)

// For folks that need real specific times, use this to select a precise range
// of times you want plotted, and the number of buckets you want used.
#define LOCAL_HISTOGRAM_CUSTOM_TIMES(name, sample, min, max, bucket_count) \
    STATIC_HISTOGRAM_POINTER_BLOCK(name, AddTime(sample), \
        base::Histogram::FactoryTimeGet(name, min, max, bucket_count, \
                                        base::HistogramBase::kNoFlags))

#define LOCAL_HISTOGRAM_COUNTS(name, sample) LOCAL_HISTOGRAM_CUSTOM_COUNTS( \
    name, sample, 1, 1000000, 50)

#define LOCAL_HISTOGRAM_COUNTS_100(name, sample) \
    LOCAL_HISTOGRAM_CUSTOM_COUNTS(name, sample, 1, 100, 50)

#define LOCAL_HISTOGRAM_COUNTS_10000(name, sample) \
    LOCAL_HISTOGRAM_CUSTOM_COUNTS(name, sample, 1, 10000, 50)

#define LOCAL_HISTOGRAM_CUSTOM_COUNTS(name, sample, min, max, bucket_count) \
    STATIC_HISTOGRAM_POINTER_BLOCK(name, Add(sample), \
        base::Histogram::FactoryGet(name, min, max, bucket_count, \
                                    base::HistogramBase::kNoFlags))

// This is a helper macro used by other macros and shouldn't be used directly.
#define HISTOGRAM_ENUMERATION_WITH_FLAG(name, sample, boundary, flag) \
    STATIC_HISTOGRAM_POINTER_BLOCK(name, Add(sample), \
        base::LinearHistogram::FactoryGet(name, 1, boundary, boundary + 1, \
            flag))

#define LOCAL_HISTOGRAM_PERCENTAGE(name, under_one_hundred) \
    LOCAL_HISTOGRAM_ENUMERATION(name, under_one_hundred, 101)

#define LOCAL_HISTOGRAM_BOOLEAN(name, sample) \
    STATIC_HISTOGRAM_POINTER_BLOCK(name, AddBoolean(sample), \
        base::BooleanHistogram::FactoryGet(name, base::Histogram::kNoFlags))

// Support histograming of an enumerated value.  The samples should always be
// strictly less than |boundary_value| -- this prevents you from running into
// problems down the line if you add additional buckets to the histogram.  Note
// also that, despite explicitly setting the minimum bucket value to |1| below,
// it is fine for enumerated histograms to be 0-indexed -- this is because
// enumerated histograms should never have underflow.
#define LOCAL_HISTOGRAM_ENUMERATION(name, sample, boundary_value) \
    STATIC_HISTOGRAM_POINTER_BLOCK(name, Add(sample), \
        base::LinearHistogram::FactoryGet(name, 1, boundary_value, \
            boundary_value + 1, base::HistogramBase::kNoFlags))

// Support histograming of an enumerated value. Samples should be one of the
// std::vector<int> list provided via |custom_ranges|. See comments above
// CustomRanges::FactoryGet about the requirement of |custom_ranges|.
// You can use the helper function CustomHistogram::ArrayToCustomRanges to
// transform a C-style array of valid sample values to a std::vector<int>.
#define LOCAL_HISTOGRAM_CUSTOM_ENUMERATION(name, sample, custom_ranges) \
    STATIC_HISTOGRAM_POINTER_BLOCK(name, Add(sample), \
        base::CustomHistogram::FactoryGet(name, custom_ranges, \
                                          base::HistogramBase::kNoFlags))

#define LOCAL_HISTOGRAM_MEMORY_KB(name, sample) LOCAL_HISTOGRAM_CUSTOM_COUNTS( \
    name, sample, 1000, 500000, 50)

//------------------------------------------------------------------------------
// The following macros provide typical usage scenarios for callers that wish
// to record histogram data, and have the data submitted/uploaded via UMA.
// Not all systems support such UMA, but if they do, the following macros
// should work with the service.

#define UMA_HISTOGRAM_TIMES(name, sample) UMA_HISTOGRAM_CUSTOM_TIMES( \
    name, sample, base::TimeDelta::FromMilliseconds(1), \
    base::TimeDelta::FromSeconds(10), 50)

#define UMA_HISTOGRAM_MEDIUM_TIMES(name, sample) UMA_HISTOGRAM_CUSTOM_TIMES( \
    name, sample, base::TimeDelta::FromMilliseconds(10), \
    base::TimeDelta::FromMinutes(3), 50)

// Use this macro when times can routinely be much longer than 10 seconds.
#define UMA_HISTOGRAM_LONG_TIMES(name, sample) UMA_HISTOGRAM_CUSTOM_TIMES( \
    name, sample, base::TimeDelta::FromMilliseconds(1), \
    base::TimeDelta::FromHours(1), 50)

// Use this macro when times can routinely be much longer than 10 seconds and
// you want 100 buckets.
#define UMA_HISTOGRAM_LONG_TIMES_100(name, sample) UMA_HISTOGRAM_CUSTOM_TIMES( \
    name, sample, base::TimeDelta::FromMilliseconds(1), \
    base::TimeDelta::FromHours(1), 100)

#define UMA_HISTOGRAM_CUSTOM_TIMES(name, sample, min, max, bucket_count) \
    STATIC_HISTOGRAM_POINTER_BLOCK(name, AddTime(sample), \
        base::Histogram::FactoryTimeGet(name, min, max, bucket_count, \
            base::HistogramBase::kUmaTargetedHistogramFlag))

#define UMA_HISTOGRAM_COUNTS(name, sample) UMA_HISTOGRAM_CUSTOM_COUNTS( \
    name, sample, 1, 1000000, 50)

#define UMA_HISTOGRAM_COUNTS_100(name, sample) UMA_HISTOGRAM_CUSTOM_COUNTS( \
    name, sample, 1, 100, 50)

#define UMA_HISTOGRAM_COUNTS_10000(name, sample) UMA_HISTOGRAM_CUSTOM_COUNTS( \
    name, sample, 1, 10000, 50)

#define UMA_HISTOGRAM_CUSTOM_COUNTS(name, sample, min, max, bucket_count) \
    STATIC_HISTOGRAM_POINTER_BLOCK(name, Add(sample), \
        base::Histogram::FactoryGet(name, min, max, bucket_count, \
            base::HistogramBase::kUmaTargetedHistogramFlag))

#define UMA_HISTOGRAM_MEMORY_KB(name, sample) UMA_HISTOGRAM_CUSTOM_COUNTS( \
    name, sample, 1000, 500000, 50)

#define UMA_HISTOGRAM_MEMORY_MB(name, sample) UMA_HISTOGRAM_CUSTOM_COUNTS( \
    name, sample, 1, 1000, 50)

#define UMA_HISTOGRAM_PERCENTAGE(name, under_one_hundred) \
    UMA_HISTOGRAM_ENUMERATION(name, under_one_hundred, 101)

#define UMA_HISTOGRAM_BOOLEAN(name, sample) \
    STATIC_HISTOGRAM_POINTER_BLOCK(name, AddBoolean(sample), \
        base::BooleanHistogram::FactoryGet(name, \
            base::HistogramBase::kUmaTargetedHistogramFlag))

// The samples should always be strictly less than |boundary_value|.  For more
// details, see the comment for the |LOCAL_HISTOGRAM_ENUMERATION| macro, above.
#define UMA_HISTOGRAM_ENUMERATION(name, sample, boundary_value) \
    HISTOGRAM_ENUMERATION_WITH_FLAG(name, sample, boundary_value, \
        base::HistogramBase::kUmaTargetedHistogramFlag)

// Similar to UMA_HISTOGRAM_ENUMERATION, but used for recording stability
// histograms.  Use this if recording a histogram that should be part of the
// initial stability log.
#define UMA_STABILITY_HISTOGRAM_ENUMERATION(name, sample, boundary_value) \
    HISTOGRAM_ENUMERATION_WITH_FLAG(name, sample, boundary_value, \
        base::HistogramBase::kUmaStabilityHistogramFlag)

#define UMA_HISTOGRAM_CUSTOM_ENUMERATION(name, sample, custom_ranges) \
    STATIC_HISTOGRAM_POINTER_BLOCK(name, Add(sample), \
        base::CustomHistogram::FactoryGet(name, custom_ranges, \
            base::HistogramBase::kUmaTargetedHistogramFlag))

// Scoped class which logs its time on this earth as a UMA statistic. This is
// recommended for when you want a histogram which measures the time it takes
// for a method to execute. This measures up to 10 seconds.
#define SCOPED_UMA_HISTOGRAM_TIMER(name) \
  SCOPED_UMA_HISTOGRAM_TIMER_EXPANDER(name, false, __COUNTER__)

// Similar scoped histogram timer, but this uses UMA_HISTOGRAM_LONG_TIMES_100,
// which measures up to an hour, and uses 100 buckets. This is more expensive
// to store, so only use if this often takes >10 seconds.
#define SCOPED_UMA_HISTOGRAM_LONG_TIMER(name) \
  SCOPED_UMA_HISTOGRAM_TIMER_EXPANDER(name, true, __COUNTER__)

// This nested macro is necessary to expand __COUNTER__ to an actual value.
#define SCOPED_UMA_HISTOGRAM_TIMER_EXPANDER(name, is_long, key) \
  SCOPED_UMA_HISTOGRAM_TIMER_UNIQUE(name, is_long, key)

#define SCOPED_UMA_HISTOGRAM_TIMER_UNIQUE(name, is_long, key) \
  class ScopedHistogramTimer##key { \
   public: \
    ScopedHistogramTimer##key() : constructed_(base::TimeTicks::Now()) {} \
    ~ScopedHistogramTimer##key() { \
      base::TimeDelta elapsed = base::TimeTicks::Now() - constructed_; \
      if (is_long) { \
        UMA_HISTOGRAM_LONG_TIMES_100(name, elapsed); \
      } else { \
        UMA_HISTOGRAM_TIMES(name, elapsed); \
      } \
    } \
   private: \
    base::TimeTicks constructed_; \
  } scoped_histogram_timer_##key

#endif  // BASE_METRICS_HISTOGRAM_MACROS_H_
