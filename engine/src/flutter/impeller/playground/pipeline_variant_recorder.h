// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_PLAYGROUND_PIPELINE_VARIANT_RECORDER_H_
#define FLUTTER_IMPELLER_PLAYGROUND_PIPELINE_VARIANT_RECORDER_H_

#include <cstdint>
#include <map>
#include <memory>
#include <optional>
#include <ostream>
#include <string>
#include <unordered_map>
#include <vector>

#include "impeller/base/thread.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/geometry/scalar.h"
#include "impeller/renderer/context.h"
#include "impeller/renderer/pipeline_descriptor.h"
#include "impeller/renderer/pipeline_library.h"

namespace impeller {

//------------------------------------------------------------------------------
/// @brief      Accumulates which pipeline variants were warmed and which were
///             actually drawn with, across every `ContentContext` created over
///             the life of a test process.
///
///             Each `ContentContext` reports the variants it created (see
///             `ContentContext::SetPipelineVariantObserver`) as it is
///             destroyed. Draw counts come from the `PipelineLibrary` of the
///             context it rendered with, which counts every pipeline bound to a
///             render pass.
///
///             The interesting output is the variants warmed during
///             `ContentContext` construction that nothing ever drew with, and
///             for each, how the same pipeline was drawn instead.
///
///             Recording is off unless `Enable` is called, and draw counts only
///             exist in debug and profile runtime modes.
///
class PipelineVariantRecorder {
 public:
  //----------------------------------------------------------------------------
  /// @brief      Details of the test run, recorded in the report so that a
  ///             reader can tell whether it is trustworthy.
  ///
  struct RunInfo {
    std::string gtest_filter;
    int tests_run = 0;
    int tests_skipped = 0;
    int tests_failed = 0;
  };

  //----------------------------------------------------------------------------
  /// @brief      The recorder used by the test process.
  ///
  ///             Instances can also be created directly, which is what tests of
  ///             the recorder itself do to avoid sharing state.
  ///
  static PipelineVariantRecorder& GetInstance();

  //----------------------------------------------------------------------------
  /// @brief      Enables the process-wide recorder and routes every
  ///             `ContentContext`'s variants to it. Must be called before the
  ///             `ContentContext`s of interest are created.
  ///
  static void InstallForProcess();

  PipelineVariantRecorder();

  ~PipelineVariantRecorder();

  //----------------------------------------------------------------------------
  /// @brief      Begins recording. Logs an error if the process was built in a
  ///             runtime mode where pipeline usage is not collected at all.
  ///
  void Enable();

  bool IsEnabled() const;

  //----------------------------------------------------------------------------
  /// @brief      Folds the variants created by one `ContentContext`, and the
  ///             draws recorded by the pipeline library of the `Context` it
  ///             rendered with, into the accumulated totals.
  ///
  ///             Several `ContentContext`s can share a `Context`, and the GLES
  ///             playground shares one `Context` across the whole suite, so a
  ///             library's draw counts are running totals that are seen many
  ///             times. Only the draws recorded since the library was last
  ///             harvested are added.
  ///
  ///             Draws of a pipeline that no `ContentContext` has reported yet
  ///             are held back, because the `ContentContext` that created it
  ///             may simply not have been destroyed yet. Whatever is still
  ///             unclaimed when its library is freed, or when the report is
  ///             printed, is not a `ContentContext` pipeline (runtime effects,
  ///             pipelines built directly by tests) and only counts towards the
  ///             total number of draws.
  ///
  ///             Records of libraries that have since been freed are dropped
  ///             here, so that they neither keep their pipelines alive nor get
  ///             mistaken for a new library allocated at the same address.
  ///
  void Harvest(const Context& context,
               const std::vector<ContentContext::RecordedVariant>& variants);

  //----------------------------------------------------------------------------
  /// @brief      Writes a human readable summary of what was warmed and what
  ///             was drawn.
  ///
  void PrintReport(std::ostream& out, const RunInfo& run_info) const;

 private:
  struct Entry {
    std::string label;
    /// Absent for pipelines that were not created by a `ContentContext`.
    std::optional<ContentContextOptions> options;
    std::vector<Scalar> specialization_constants;
    bool warmed = false;
    uint64_t draw_count = 0;
  };

  /// What a variant created by a `ContentContext` is known to be.
  struct KnownVariant {
    ContentContextOptions options;
    bool warmed = false;
  };

  using DescriptorCounts =
      std::unordered_map<PipelineDescriptor,
                         uint64_t,
                         ComparableHash<PipelineDescriptor>,
                         ComparableEqual<PipelineDescriptor>>;

  /// Everything known about a single pipeline library.
  ///
  /// The weak pointer distinguishes a library that is still alive from a freed
  /// one whose address has been reused by a different library.
  struct LibraryRecord {
    std::weak_ptr<PipelineLibrary> library;
    std::string backend;
    std::unordered_map<PipelineDescriptor,
                       KnownVariant,
                       ComparableHash<PipelineDescriptor>,
                       ComparableEqual<PipelineDescriptor>>
        known;
    /// The draw count of each descriptor already added to `backends_`.
    DescriptorCounts counted;
    /// The library's counts as of the most recent harvest, used to flush
    /// draws that no `ContentContext` ever claimed.
    DescriptorCounts latest;
  };

  /// Keyed by a stable identity string so that both the merge and the ordering
  /// of the report are deterministic.
  using BackendEntries = std::map<std::string, Entry>;

  /// Width of the horizontal rules in the printed report.
  static constexpr size_t kRuleWidth = 80u;

  static Entry& GetEntry(BackendEntries& entries,
                         const PipelineDescriptor& descriptor,
                         const std::optional<ContentContextOptions>& options);

  /// Formats the per-backend and cross-backend sections of the report. Defined
  /// in the implementation file, and nested so it can use `Entry`.
  class ReportPrinter;

  /// Adds the draws `record` holds back, because no `ContentContext` claimed
  /// them, to `entries` as entries without options.
  static void AddUnclaimedDraws(const LibraryRecord& record,
                                BackendEntries& entries);

  /// Folds the unclaimed draws of every freed library into `backends_` and
  /// forgets the library.
  void PruneExpiredLibraries() IPLR_REQUIRES(mutex_);

  /// `backends_` plus the draws that were never claimed by a `ContentContext`.
  std::map<std::string, BackendEntries> GetBackendsWithUnclaimedDraws() const
      IPLR_REQUIRES(mutex_);

  mutable Mutex mutex_;
  bool enabled_ IPLR_GUARDED_BY(mutex_) = false;
  std::map<std::string, BackendEntries> backends_ IPLR_GUARDED_BY(mutex_);
  std::map<const PipelineLibrary*, LibraryRecord> libraries_
      IPLR_GUARDED_BY(mutex_);

  PipelineVariantRecorder(const PipelineVariantRecorder&) = delete;

  PipelineVariantRecorder& operator=(const PipelineVariantRecorder&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_PLAYGROUND_PIPELINE_VARIANT_RECORDER_H_
