// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gl/angle_platform_impl.h"

#include "base/metrics/histogram.h"
#include "base/metrics/sparse_histogram.h"

namespace gfx {

ANGLEPlatformImpl::ANGLEPlatformImpl() {
}

ANGLEPlatformImpl::~ANGLEPlatformImpl() {
}

void ANGLEPlatformImpl::histogramCustomCounts(const char* name,
                                              int sample,
                                              int min,
                                              int max,
                                              int bucket_count) {
  // Copied from histogram macro, but without the static variable caching
  // the histogram because name is dynamic.
  base::HistogramBase* counter = base::Histogram::FactoryGet(
      name, min, max, bucket_count,
      base::HistogramBase::kUmaTargetedHistogramFlag);
  DCHECK_EQ(name, counter->histogram_name());
  counter->Add(sample);
}

void ANGLEPlatformImpl::histogramEnumeration(const char* name,
                                             int sample,
                                             int boundary_value) {
  // Copied from histogram macro, but without the static variable caching
  // the histogram because name is dynamic.
  base::HistogramBase* counter = base::LinearHistogram::FactoryGet(
      name, 1, boundary_value, boundary_value + 1,
      base::HistogramBase::kUmaTargetedHistogramFlag);
  DCHECK_EQ(name, counter->histogram_name());
  counter->Add(sample);
}

void ANGLEPlatformImpl::histogramSparse(const char* name, int sample) {
  // For sparse histograms, we can use the macro, as it does not incorporate a
  // static.
  UMA_HISTOGRAM_SPARSE_SLOWLY(name, sample);
}

}  // namespace gfx
