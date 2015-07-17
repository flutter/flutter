// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// StatisticsRecorder holds all Histograms and BucketRanges that are used by
// Histograms in the system. It provides a general place for
// Histograms/BucketRanges to register, and supports a global API for accessing
// (i.e., dumping, or graphing) the data.

#ifndef BASE_METRICS_STATISTICS_RECORDER_H_
#define BASE_METRICS_STATISTICS_RECORDER_H_

#include <list>
#include <map>
#include <string>
#include <vector>

#include "base/base_export.h"
#include "base/basictypes.h"
#include "base/callback.h"
#include "base/gtest_prod_util.h"
#include "base/lazy_instance.h"
#include "base/metrics/histogram_base.h"

namespace base {

class BucketRanges;
class Lock;

class BASE_EXPORT StatisticsRecorder {
 public:
  typedef std::vector<HistogramBase*> Histograms;

  // Initializes the StatisticsRecorder system. Safe to call multiple times.
  static void Initialize();

  // Find out if histograms can now be registered into our list.
  static bool IsActive();

  // Register, or add a new histogram to the collection of statistics. If an
  // identically named histogram is already registered, then the argument
  // |histogram| will deleted.  The returned value is always the registered
  // histogram (either the argument, or the pre-existing registered histogram).
  static HistogramBase* RegisterOrDeleteDuplicate(HistogramBase* histogram);

  // Register, or add a new BucketRanges. If an identically BucketRanges is
  // already registered, then the argument |ranges| will deleted. The returned
  // value is always the registered BucketRanges (either the argument, or the
  // pre-existing one).
  static const BucketRanges* RegisterOrDeleteDuplicateRanges(
      const BucketRanges* ranges);

  // Methods for appending histogram data to a string.  Only histograms which
  // have |query| as a substring are written to |output| (an empty string will
  // process all registered histograms).
  static void WriteHTMLGraph(const std::string& query, std::string* output);
  static void WriteGraph(const std::string& query, std::string* output);

  // Returns the histograms with |query| as a substring as JSON text (an empty
  // |query| will process all registered histograms).
  static std::string ToJSON(const std::string& query);

  // Method for extracting histograms which were marked for use by UMA.
  static void GetHistograms(Histograms* output);

  // Method for extracting BucketRanges used by all histograms registered.
  static void GetBucketRanges(std::vector<const BucketRanges*>* output);

  // Find a histogram by name. It matches the exact name. This method is thread
  // safe.  It returns NULL if a matching histogram is not found.
  static HistogramBase* FindHistogram(const std::string& name);

  // GetSnapshot copies some of the pointers to registered histograms into the
  // caller supplied vector (Histograms). Only histograms which have |query| as
  // a substring are copied (an empty string will process all registered
  // histograms).
  static void GetSnapshot(const std::string& query, Histograms* snapshot);

  typedef base::Callback<void(HistogramBase::Sample)> OnSampleCallback;

  // SetCallback sets the callback to notify when a new sample is recorded on
  // the histogram referred to by |histogram_name|. The call to this method can
  // be be done before or after the histogram is created. This method is thread
  // safe. The return value is whether or not the callback was successfully set.
  static bool SetCallback(const std::string& histogram_name,
                          const OnSampleCallback& callback);

  // ClearCallback clears any callback set on the histogram referred to by
  // |histogram_name|. This method is thread safe.
  static void ClearCallback(const std::string& histogram_name);

  // FindCallback retrieves the callback for the histogram referred to by
  // |histogram_name|, or a null callback if no callback exists for this
  // histogram. This method is thread safe.
  static OnSampleCallback FindCallback(const std::string& histogram_name);

 private:
  // HistogramNameRef holds a weak const ref to the name field of the associated
  // Histogram object, allowing re-use of the underlying string storage for the
  // map keys. The wrapper is required as using "const std::string&" as the key
  // results in compile errors.
  struct HistogramNameRef {
    explicit HistogramNameRef(const std::string& name) : name_(name) {};

    // Operator < is necessary to use this type as a std::map key.
    bool operator<(const HistogramNameRef& other) const {
      return name_ < other.name_;
    }

    // Weak, owned by the associated Histogram object.
    const std::string& name_;
  };

  // We keep all registered histograms in a map, from name to histogram.
  typedef std::map<HistogramNameRef, HistogramBase*> HistogramMap;

  // We keep a map of callbacks to histograms, so that as histograms are
  // created, we can set the callback properly.
  typedef std::map<std::string, OnSampleCallback> CallbackMap;

  // We keep all |bucket_ranges_| in a map, from checksum to a list of
  // |bucket_ranges_|.  Checksum is calculated from the |ranges_| in
  // |bucket_ranges_|.
  typedef std::map<uint32, std::list<const BucketRanges*>*> RangesMap;

  friend struct DefaultLazyInstanceTraits<StatisticsRecorder>;
  friend class HistogramBaseTest;
  friend class HistogramSnapshotManagerTest;
  friend class HistogramTest;
  friend class JsonPrefStoreTest;
  friend class SparseHistogramTest;
  friend class StatisticsRecorderTest;
  FRIEND_TEST_ALL_PREFIXES(HistogramDeltaSerializationTest,
                           DeserializeHistogramAndAddSamples);

  // The constructor just initializes static members. Usually client code should
  // use Initialize to do this. But in test code, you can friend this class and
  // call destructor/constructor to get a clean StatisticsRecorder.
  StatisticsRecorder();
  ~StatisticsRecorder();

  static void DumpHistogramsToVlog(void* instance);

  static HistogramMap* histograms_;
  static CallbackMap* callbacks_;
  static RangesMap* ranges_;

  // Lock protects access to above maps.
  static base::Lock* lock_;

  DISALLOW_COPY_AND_ASSIGN(StatisticsRecorder);
};

}  // namespace base

#endif  // BASE_METRICS_STATISTICS_RECORDER_H_
