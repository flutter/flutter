// Copyright (c) 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_TRACE_EVENT_TRACE_CONFIG_H_
#define BASE_TRACE_EVENT_TRACE_CONFIG_H_

#include <string>
#include <vector>

#include "base/base_export.h"
#include "base/gtest_prod_util.h"
#include "base/values.h"

namespace base {
namespace trace_event {

// Options determines how the trace buffer stores data.
enum TraceRecordMode {
  // Record until the trace buffer is full.
  RECORD_UNTIL_FULL,

  // Record until the user ends the trace. The trace buffer is a fixed size
  // and we use it as a ring buffer during recording.
  RECORD_CONTINUOUSLY,

  // Record until the trace buffer is full, but with a huge buffer size.
  RECORD_AS_MUCH_AS_POSSIBLE,

  // Echo to console. Events are discarded.
  ECHO_TO_CONSOLE,
};

class BASE_EXPORT TraceConfig {
 public:
  typedef std::vector<std::string> StringList;

  TraceConfig();

  // Create TraceConfig object from category filter and trace options strings.
  //
  // |category_filter_string| is a comma-delimited list of category wildcards.
  // A category can have an optional '-' prefix to make it an excluded category.
  // All the same rules apply above, so for example, having both included and
  // excluded categories in the same list would not be supported.
  //
  // Category filters can also be used to configure synthetic delays.
  //
  // |trace_options_string| is a comma-delimited list of trace options.
  // Possible options are: "record-until-full", "record-continuously",
  // "record-as-much-as-possible", "trace-to-console", "enable-sampling",
  // "enable-systrace" and "enable-argument-filter".
  // The first 4 options are trace recoding modes and hence
  // mutually exclusive. If more than one trace recording modes appear in the
  // options_string, the last one takes precedence. If none of the trace
  // recording mode is specified, recording mode is RECORD_UNTIL_FULL.
  //
  // The trace option will first be reset to the default option
  // (record_mode set to RECORD_UNTIL_FULL, enable_sampling, enable_systrace,
  // and enable_argument_filter set to false) before options parsed from
  // |trace_options_string| are applied on it. If |trace_options_string| is
  // invalid, the final state of trace options is undefined.
  //
  // Example: TraceConfig("test_MyTest*", "record-until-full");
  // Example: TraceConfig("test_MyTest*,test_OtherStuff",
  //                      "record-continuously, enable-sampling");
  // Example: TraceConfig("-excluded_category1,-excluded_category2",
  //                      "record-until-full, trace-to-console");
  //          would set ECHO_TO_CONSOLE as the recording mode.
  // Example: TraceConfig("-*,webkit", "");
  //          would disable everything but webkit; and use default options.
  // Example: TraceConfig("-webkit", "");
  //          would enable everything but webkit; and use default options.
  // Example: TraceConfig("DELAY(gpu.PresentingFrame;16)", "");
  //          would make swap buffers always take at least 16 ms; and use
  //          default options.
  // Example: TraceConfig("DELAY(gpu.PresentingFrame;16;oneshot)", "");
  //          would make swap buffers take at least 16 ms the first time it is
  //          called; and use default options.
  // Example: TraceConfig("DELAY(gpu.PresentingFrame;16;alternating)", "");
  //          would make swap buffers take at least 16 ms every other time it
  //          is called; and use default options.
  TraceConfig(const std::string& category_filter_string,
              const std::string& trace_options_string);

  TraceConfig(const std::string& category_filter_string,
              TraceRecordMode record_mode);

  // Create TraceConfig object from the trace config string.
  //
  // |config_string| is a dictionary formatted as a JSON string, containing both
  // category filters and trace options.
  //
  // Example:
  //   {
  //     "record_mode": "record-continuously",
  //     "enable_sampling": true,
  //     "enable_systrace": true,
  //     "enable_argument_filter": true,
  //     "included_categories": ["included",
  //                             "inc_pattern*",
  //                             "disabled-by-default-category1"],
  //     "excluded_categories": ["excluded", "exc_pattern*"],
  //     "synthetic_delays": ["test.Delay1;16", "test.Delay2;32"]
  //   }
  explicit TraceConfig(const std::string& config_string);

  TraceConfig(const TraceConfig& tc);

  ~TraceConfig();

  TraceConfig& operator=(const TraceConfig& rhs);

  // Return a list of the synthetic delays specified in this category filter.
  const StringList& GetSyntheticDelayValues() const;

  TraceRecordMode GetTraceRecordMode() const { return record_mode_; }
  bool IsSamplingEnabled() const { return enable_sampling_; }
  bool IsSystraceEnabled() const { return enable_systrace_; }
  bool IsArgumentFilterEnabled() const { return enable_argument_filter_; }

  void SetTraceRecordMode(TraceRecordMode mode) { record_mode_ = mode; }
  void EnableSampling() { enable_sampling_ = true; }
  void EnableSystrace() { enable_systrace_ = true; }
  void EnableArgumentFilter() { enable_argument_filter_ = true; }

  // Writes the string representation of the TraceConfig. The string is JSON
  // formatted.
  std::string ToString() const;

  // Write the string representation of the CategoryFilter part.
  std::string ToCategoryFilterString() const;

  // Returns true if at least one category in the list is enabled by this
  // trace config.
  bool IsCategoryGroupEnabled(const char* category_group) const;

  // Merges config with the current TraceConfig
  void Merge(const TraceConfig& config);

  void Clear();

 private:
  FRIEND_TEST_ALL_PREFIXES(TraceConfigTest, TraceConfigFromValidLegacyFormat);
  FRIEND_TEST_ALL_PREFIXES(TraceConfigTest,
                           TraceConfigFromInvalidLegacyStrings);
  FRIEND_TEST_ALL_PREFIXES(TraceConfigTest, ConstructDefaultTraceConfig);
  FRIEND_TEST_ALL_PREFIXES(TraceConfigTest, TraceConfigFromValidString);
  FRIEND_TEST_ALL_PREFIXES(TraceConfigTest, TraceConfigFromInvalidString);
  FRIEND_TEST_ALL_PREFIXES(TraceConfigTest,
                           IsEmptyOrContainsLeadingOrTrailingWhitespace);

  // The default trace config, used when none is provided.
  // Allows all non-disabled-by-default categories through, except if they end
  // in the suffix 'Debug' or 'Test'.
  void InitializeDefault();

  // Initialize from the config string
  void InitializeFromConfigString(const std::string& config_string);

  // Initialize from category filter and trace options strings
  void InitializeFromStrings(const std::string& category_filter_string,
                             const std::string& trace_options_string);

  void SetCategoriesFromIncludedList(const base::ListValue& included_list);
  void SetCategoriesFromExcludedList(const base::ListValue& excluded_list);
  void SetSyntheticDelaysFromList(const base::ListValue& list);
  void AddCategoryToDict(base::DictionaryValue& dict,
                         const char* param,
                         const StringList& categories) const;

  // Convert TraceConfig to the dict representation of the TraceConfig.
  void ToDict(base::DictionaryValue& dict) const;

  std::string ToTraceOptionsString() const;

  void WriteCategoryFilterString(const StringList& values,
                                 std::string* out,
                                 bool included) const;
  void WriteCategoryFilterString(const StringList& delays,
                                 std::string* out) const;

  // Returns true if category is enable according to this trace config.
  bool IsCategoryEnabled(const char* category_name) const;

  static bool IsEmptyOrContainsLeadingOrTrailingWhitespace(
      const std::string& str);

  bool HasIncludedPatterns() const;

  TraceRecordMode record_mode_;
  bool enable_sampling_ : 1;
  bool enable_systrace_ : 1;
  bool enable_argument_filter_ : 1;

  StringList included_categories_;
  StringList disabled_categories_;
  StringList excluded_categories_;
  StringList synthetic_delays_;
};

}  // namespace trace_event
}  // namespace base

#endif  // BASE_TRACE_EVENT_TRACE_CONFIG_H_
