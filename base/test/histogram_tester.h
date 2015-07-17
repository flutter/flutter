// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_TEST_HISTOGRAM_TESTER_H_
#define BASE_TEST_HISTOGRAM_TESTER_H_

#include <map>
#include <ostream>
#include <string>
#include <utility>
#include <vector>

#include "base/basictypes.h"
#include "base/memory/scoped_ptr.h"
#include "base/metrics/histogram.h"
#include "base/metrics/histogram_base.h"

namespace base {

struct Bucket;
class HistogramSamples;

// HistogramTester provides a simple interface for examining histograms, UMA
// or otherwise. Tests can use this interface to verify that histogram data is
// getting logged as intended.
class HistogramTester {
 public:
  // The constructor will call StatisticsRecorder::Initialize() for you. Also,
  // this takes a snapshot of all current histograms counts.
  HistogramTester();
  ~HistogramTester();

  // We know the exact number of samples in a bucket, and that no other bucket
  // should have samples. Measures the diff from the snapshot taken when this
  // object was constructed.
  void ExpectUniqueSample(const std::string& name,
                          base::HistogramBase::Sample sample,
                          base::HistogramBase::Count expected_count) const;

  // We know the exact number of samples in a bucket, but other buckets may
  // have samples as well. Measures the diff from the snapshot taken when this
  // object was constructed.
  void ExpectBucketCount(const std::string& name,
                         base::HistogramBase::Sample sample,
                         base::HistogramBase::Count expected_count) const;

  // We don't know the values of the samples, but we know how many there are.
  // This measures the diff from the snapshot taken when this object was
  // constructed.
  void ExpectTotalCount(const std::string& name,
                        base::HistogramBase::Count count) const;

  // Returns a list of all of the buckets recorded since creation of this
  // object, as vector<Bucket>, where the Bucket represents the min boundary of
  // the bucket and the count of samples recorded to that bucket since creation.
  //
  // Example usage, using gMock:
  //   EXPECT_THAT(histogram_tester.GetAllSamples("HistogramName"),
  //               ElementsAre(Bucket(1, 5), Bucket(2, 10), Bucket(3, 5)));
  //
  // If you build the expected list programmatically, you can use ContainerEq:
  //   EXPECT_THAT(histogram_tester.GetAllSamples("HistogramName"),
  //               ContainerEq(expected_buckets));
  //
  // or EXPECT_EQ if you prefer not to depend on gMock, at the expense of a
  // slightly less helpful failure message:
  //   EXPECT_EQ(expected_buckets,
  //             histogram_tester.GetAllSamples("HistogramName"));
  std::vector<Bucket> GetAllSamples(const std::string& name);

  // Access a modified HistogramSamples containing only what has been logged
  // to the histogram since the creation of this object.
  scoped_ptr<HistogramSamples> GetHistogramSamplesSinceCreation(
      const std::string& histogram_name);

 private:
  // Verifies and asserts that value in the |sample| bucket matches the
  // |expected_count|. The bucket's current value is determined from |samples|
  // and is modified based on the snapshot stored for histogram |name|.
  void CheckBucketCount(const std::string& name,
                        base::HistogramBase::Sample sample,
                        base::Histogram::Count expected_count,
                        const base::HistogramSamples& samples) const;

  // Verifies that the total number of values recorded for the histogram |name|
  // is |expected_count|. This is checked against |samples| minus the snapshot
  // that was taken for |name|.
  void CheckTotalCount(const std::string& name,
                       base::Histogram::Count expected_count,
                       const base::HistogramSamples& samples) const;

  // Used to determine the histogram changes made during this instance's
  // lifecycle. This instance takes ownership of the samples, which are deleted
  // when the instance is destroyed.
  std::map<std::string, HistogramSamples*> histograms_snapshot_;

  DISALLOW_COPY_AND_ASSIGN(HistogramTester);
};

struct Bucket {
  Bucket(base::HistogramBase::Sample min, base::HistogramBase::Count count)
      : min(min), count(count) {}

  bool operator==(const Bucket& other) const;

  base::HistogramBase::Sample min;
  base::HistogramBase::Count count;
};

void PrintTo(const Bucket& value, std::ostream* os);

}  // namespace base

#endif  // BASE_TEST_HISTOGRAM_TESTER_H_
