// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/accessibility/ax_language_detection.h"
#include <algorithm>
#include <functional>

#include "base/command_line.h"
#include "base/i18n/unicodestring.h"
#include "base/metrics/histogram_functions.h"
#include "base/metrics/histogram_macros.h"
#include "base/strings/utf_string_conversions.h"
#include "base/trace_event/trace_event.h"
#include "ui/accessibility/accessibility_features.h"
#include "ui/accessibility/accessibility_switches.h"
#include "ui/accessibility/ax_enums.mojom.h"
#include "ui/accessibility/ax_tree.h"

namespace ui {

namespace {
// This is the maximum number of languages we assign per page, so only the top
// 3 languages on the top will be assigned to any node.
const int kMaxDetectedLanguagesPerPage = 3;

// This is the maximum number of languages that cld3 will detect for each
// input we give it, 3 was recommended to us by the ML team as a good
// starting point.
const int kMaxDetectedLanguagesPerSpan = 3;

const int kShortTextIdentifierMinByteLength = 1;
// TODO(https://crbug.com/971360): Determine appropriate value for
// |kShortTextIdentifierMaxByteLength|.
const int kShortTextIdentifierMaxByteLength = 1000;
}  // namespace

using Result = chrome_lang_id::NNetLanguageIdentifier::Result;
using SpanInfo = chrome_lang_id::NNetLanguageIdentifier::SpanInfo;

AXLanguageInfo::AXLanguageInfo() = default;
AXLanguageInfo::~AXLanguageInfo() = default;

AXLanguageInfoStats::AXLanguageInfoStats()
    : top_results_valid_(false),
      disable_metric_clearing_(false),
      count_detection_attempted_(0),
      count_detection_results_(0),
      count_labelled_(0),
      count_labelled_with_top_result_(0),
      count_overridden_(0) {}

AXLanguageInfoStats::~AXLanguageInfoStats() = default;

void AXLanguageInfoStats::Add(const std::vector<std::string>& languages) {
  // Count this as a successful detection with results.
  ++count_detection_results_;

  // Assign languages with higher probability a higher score.
  // TODO(chrishall): consider more complex scoring
  int score = kMaxDetectedLanguagesPerSpan;
  for (const auto& lang : languages) {
    lang_counts_[lang] += score;

    // Record the highest scoring detected languages for each node.
    if (score == kMaxDetectedLanguagesPerSpan)
      unique_top_lang_detected_.insert(lang);

    --score;
  }

  InvalidateTopResults();
}

int AXLanguageInfoStats::GetScore(const std::string& lang) const {
  const auto& lang_count_it = lang_counts_.find(lang);
  if (lang_count_it == lang_counts_.end()) {
    return 0;
  }
  return lang_count_it->second;
}

void AXLanguageInfoStats::InvalidateTopResults() {
  top_results_valid_ = false;
}

// Check if a given language is within the top results.
bool AXLanguageInfoStats::CheckLanguageWithinTop(const std::string& lang) {
  if (!top_results_valid_) {
    GenerateTopResults();
  }

  for (const auto& item : top_results_) {
    if (lang == item.second) {
      return true;
    }
  }

  return false;
}

void AXLanguageInfoStats::GenerateTopResults() {
  top_results_.clear();

  for (const auto& item : lang_counts_) {
    top_results_.emplace_back(item.second, item.first);
  }

  // Since we store the pair as (score, language) the default operator> on pairs
  // does our sort appropriately.
  // Sort in descending order.
  std::sort(top_results_.begin(), top_results_.end(), std::greater<>());

  // Resize down to remove all values greater than the N we are considering.
  // TODO(chrishall): In the event of a tie, we want to include more than N.
  top_results_.resize(kMaxDetectedLanguagesPerPage);

  top_results_valid_ = true;
}

void AXLanguageInfoStats::RecordLabelStatistics(
    const std::string& labelled_lang,
    const std::string& author_lang,
    bool labelled_with_first_result) {
  // Count the number of nodes we labelled, and the number we labelled with
  // our highest confidence result.
  ++count_labelled_;

  if (labelled_with_first_result)
    ++count_labelled_with_top_result_;

  // Record if we assigned a language that disagrees with the author
  // provided language for that node.
  if (author_lang != labelled_lang)
    ++count_overridden_;
}

void AXLanguageInfoStats::RecordDetectionAttempt() {
  ++count_detection_attempted_;
}

void AXLanguageInfoStats::ReportMetrics() {
  // Only report statistics for pages which had detected results.
  if (!count_detection_attempted_)
    return;

  // 50 buckets exponentially covering the range from 1 to 1000.
  base::UmaHistogramCustomCounts(
      "Accessibility.LanguageDetection.CountDetectionAttempted",
      count_detection_attempted_, 1, 1000, 50);

  int percentage_detected =
      count_detection_results_ * 100 / count_detection_attempted_;
  base::UmaHistogramPercentage(
      "Accessibility.LanguageDetection.PercentageLanguageDetected",
      percentage_detected);

  // 50 buckets exponentially covering the range from 1 to 1000.
  base::UmaHistogramCustomCounts(
      "Accessibility.LanguageDetection.CountLabelled", count_labelled_, 1, 1000,
      50);

  // If no nodes were labelled, then the percentage labelled with the top result
  // doesn't make sense to report.
  if (count_labelled_) {
    int percentage_top =
        count_labelled_with_top_result_ * 100 / count_labelled_;
    base::UmaHistogramPercentage(
        "Accessibility.LanguageDetection.PercentageLabelledWithTop",
        percentage_top);

    int percentage_overridden = count_overridden_ * 100 / count_labelled_;
    base::UmaHistogramPercentage(
        "Accessibility.LanguageDetection.PercentageOverridden",
        percentage_overridden);
  }

  // Exact count from 0 to 15, overflow is then truncated to 15.
  base::UmaHistogramExactLinear("Accessibility.LanguageDetection.LangsPerPage",
                                unique_top_lang_detected_.size(), 15);

  // TODO(chrishall): Consider adding timing metrics for performance, consider:
  //  - detect step.
  //  - label step.
  //  - total initial static detection & label timing.
  //  - total incremental dynamic detection & label timing.

  // Reset statistics for metrics.
  ClearMetrics();
}

void AXLanguageInfoStats::ClearMetrics() {
  // Do not clear metrics if we are specifically testing metrics.
  if (disable_metric_clearing_)
    return;

  unique_top_lang_detected_.clear();
  count_detection_attempted_ = 0;
  count_detection_results_ = 0;
  count_labelled_ = 0;
  count_labelled_with_top_result_ = 0;
  count_overridden_ = 0;
}

AXLanguageDetectionManager::AXLanguageDetectionManager(AXTree* tree)
    : short_text_language_identifier_(kShortTextIdentifierMinByteLength,
                                      kShortTextIdentifierMaxByteLength),
      tree_(tree) {}

AXLanguageDetectionManager::~AXLanguageDetectionManager() = default;

bool AXLanguageDetectionManager::IsStaticLanguageDetectionEnabled() {
  // Static language detection can be enabled by either:
  //  1) The general language detection feature flag which gates both static and
  //     dynamic language detection (feature flag for experiment), or
  //  2) The Static specific flag (user controlled switch).
  return features::IsAccessibilityLanguageDetectionEnabled() ||
         ::switches::IsExperimentalAccessibilityLanguageDetectionEnabled();
}

bool AXLanguageDetectionManager::IsDynamicLanguageDetectionEnabled() {
  // Dynamic language detection can be enabled by either:
  //  1) The general language detection feature flag which gates both static and
  //     dynamic language detection (feature flag for experiment), or
  //  2) The Dynamic specific flag (user controlled switch).
  return features::IsAccessibilityLanguageDetectionEnabled() ||
         ::switches::
             IsExperimentalAccessibilityLanguageDetectionDynamicEnabled();
}

void AXLanguageDetectionManager::RegisterLanguageDetectionObserver() {
  // Do not perform dynamic language detection unless explicitly enabled.
  if (!IsDynamicLanguageDetectionEnabled()) {
    return;
  }

  // Construct our new Observer as requested.
  // If there is already an Observer on this Manager then this will destroy it.
  language_detection_observer_.reset(new AXLanguageDetectionObserver(tree_));
}

// Detect languages for each node.
void AXLanguageDetectionManager::DetectLanguages() {
  TRACE_EVENT0("accessibility", "AXLanguageInfo::DetectLanguages");

  if (!IsStaticLanguageDetectionEnabled()) {
    return;
  }

  DetectLanguagesForSubtree(tree_->root());
}

// Detect languages for a subtree rooted at the given subtree_root.
// Will not check feature flag.
void AXLanguageDetectionManager::DetectLanguagesForSubtree(
    AXNode* subtree_root) {
  // Only perform detection for kStaticText nodes.
  //
  // Do not visit the children of kStaticText nodes as they don't have
  // interesting children for language detection.
  //
  // Since kInlineTextBox(es) contain text from their parent, any detection on
  // them is redundant. Instead they can inherit the detected language.
  if (subtree_root->data().role == ax::mojom::Role::kStaticText) {
    DetectLanguagesForNode(subtree_root);
  } else {
    // Otherwise, recurse into children for detection.
    for (AXNode* child : subtree_root->children()) {
      DetectLanguagesForSubtree(child);
    }
  }
}

// Detect languages for a single node.
// Will not descend into children.
// Will not check feature flag.
void AXLanguageDetectionManager::DetectLanguagesForNode(AXNode* node) {
  // Count this detection attempt.
  lang_info_stats_.RecordDetectionAttempt();

  // TODO(chrishall): implement strategy for nodes which are too small to get
  // reliable language detection results. Consider combination of
  // concatenation and bubbling up results.
  auto text = node->GetStringAttribute(ax::mojom::StringAttribute::kName);

  // FindTopNMostFreqLangs() will pad the results with
  // |NNetLanguageIdentifier::kUnknown| in order to reach the requested number
  // of languages, this means we cannot rely on the results' length and we
  // have to filter the results.
  const std::vector<Result> results =
      language_identifier_.FindTopNMostFreqLangs(text,
                                                 kMaxDetectedLanguagesPerSpan);

  std::vector<std::string> reliable_results;

  for (const auto& res : results) {
    // The output of FindTopNMostFreqLangs() is already sorted by byte count,
    // this seems good enough for now.
    // Only consider results which are 'reliable', this will also remove
    // 'unknown'.
    if (res.is_reliable) {
      reliable_results.push_back(res.language);
    }
  }

  // Only allocate a(n) LanguageInfo if we have results worth keeping.
  if (reliable_results.size()) {
    AXLanguageInfo* lang_info = node->GetLanguageInfo();
    if (lang_info) {
      // Clear previously detected and labelled languages.
      lang_info->detected_languages.clear();
      lang_info->language.clear();
    } else {
      node->SetLanguageInfo(std::make_unique<AXLanguageInfo>());
      lang_info = node->GetLanguageInfo();
    }

    // Keep these results.
    lang_info->detected_languages = std::move(reliable_results);

    // Update statistics to take these results into account.
    lang_info_stats_.Add(lang_info->detected_languages);
  }
}

// Label languages for each node. This relies on DetectLanguages having already
// been run.
void AXLanguageDetectionManager::LabelLanguages() {
  TRACE_EVENT0("accessibility", "AXLanguageInfo::LabelLanguages");

  if (!IsStaticLanguageDetectionEnabled()) {
    return;
  }

  LabelLanguagesForSubtree(tree_->root());

  // TODO(chrishall): consider refactoring to have a more clearly named entry
  // point for static language detection.
  //
  // LabelLanguages is only called for the initial run of language detection for
  // static content, this call to ReportMetrics therefore covers only the work
  // we performed in response to a page load complete event.
  lang_info_stats_.ReportMetrics();
}

// Label languages for each node in the subtree rooted at the given
// subtree_root. Will not check feature flag.
void AXLanguageDetectionManager::LabelLanguagesForSubtree(
    AXNode* subtree_root) {
  LabelLanguagesForNode(subtree_root);

  // Recurse into children to continue labelling.
  for (AXNode* child : subtree_root->children()) {
    LabelLanguagesForSubtree(child);
  }
}

// Label languages for a single node.
// Will not descend into children.
// Will not check feature flag.
void AXLanguageDetectionManager::LabelLanguagesForNode(AXNode* node) {
  AXLanguageInfo* lang_info = node->GetLanguageInfo();
  if (!lang_info)
    return;

  // There is no work to do if we already have an assigned (non-empty) language.
  if (lang_info->language.size())
    return;

  // Assign the highest probability language which is both:
  // 1) reliably detected for this node, and
  // 2) one of the top (kMaxDetectedLanguagesPerPage) languages on this page.
  //
  // This helps guard against false positives for nodes which have noisy
  // language detection results in isolation.
  //
  // Note that we assign a language even if it is the same as the author's
  // annotation. This may not be needed in practice. In theory this would help
  // if the author later on changed the language annotation to be incorrect, but
  // this seems unlikely to occur in practice.
  //
  // TODO(chrishall): consider optimisation: only assign language if it
  // disagrees with author's language annotation.
  bool labelled_with_first_result = true;
  for (const auto& lang : lang_info->detected_languages) {
    if (lang_info_stats_.CheckLanguageWithinTop(lang)) {
      lang_info->language = lang;

      const std::string& author_lang = node->GetInheritedStringAttribute(
          ax::mojom::StringAttribute::kLanguage);
      lang_info_stats_.RecordLabelStatistics(lang, author_lang,
                                             labelled_with_first_result);

      // After assigning a label we no longer need detected languages.
      // NB: clearing this invalidates the reference `lang`, so we must do this
      // last and then immediately return.
      lang_info->detected_languages.clear();

      return;
    }
    labelled_with_first_result = false;
  }

  // If we didn't label a language, then we can discard all language detection
  // information for this node.
  node->ClearLanguageInfo();
}

std::vector<AXLanguageSpan>
AXLanguageDetectionManager::GetLanguageAnnotationForStringAttribute(
    const AXNode& node,
    ax::mojom::StringAttribute attr) {
  std::vector<AXLanguageSpan> language_annotation;
  if (!node.HasStringAttribute(attr))
    return language_annotation;

  std::string attr_value = node.GetStringAttribute(attr);

  // Use author-provided language if present.
  if (node.HasStringAttribute(ax::mojom::StringAttribute::kLanguage)) {
    // Use author-provided language if present.
    language_annotation.push_back(AXLanguageSpan{
        0 /* start_index */, attr_value.length() /* end_index */,
        node.GetStringAttribute(
            ax::mojom::StringAttribute::kLanguage) /* language */,
        1 /* probability */});
    return language_annotation;
  }
  // Calculate top 3 languages.
  // TODO(akihiroota): What's a reasonable number of languages to have
  // cld_3 find? Should vary.
  std::vector<Result> top_languages =
      short_text_language_identifier_.FindTopNMostFreqLangs(
          attr_value, kMaxDetectedLanguagesPerPage);
  // Create vector of AXLanguageSpans.
  for (const auto& result : top_languages) {
    const std::vector<SpanInfo>& ranges = result.byte_ranges;
    for (const auto& span_info : ranges) {
      language_annotation.push_back(
          AXLanguageSpan{span_info.start_index, span_info.end_index,
                         result.language, span_info.probability});
    }
  }
  // Sort Language Annotations by increasing start index. LanguageAnnotations
  // with lower start index should appear earlier in the vector.
  std::sort(
      language_annotation.begin(), language_annotation.end(),
      [](const AXLanguageSpan& left, const AXLanguageSpan& right) -> bool {
        return left.start_index <= right.start_index;
      });
  // Ensure that AXLanguageSpans do not overlap.
  for (size_t i = 0; i < language_annotation.size(); ++i) {
    if (i > 0) {
      DCHECK(language_annotation[i].start_index <=
             language_annotation[i - 1].end_index);
    }
  }
  return language_annotation;
}

AXLanguageDetectionObserver::AXLanguageDetectionObserver(AXTree* tree)
    : tree_(tree) {
  // We expect the feature flag to have be checked before this Observer is
  // constructed, this should have been checked by
  // RegisterLanguageDetectionObserver.
  DCHECK(AXLanguageDetectionManager::IsDynamicLanguageDetectionEnabled());

  tree_->AddObserver(this);
}

AXLanguageDetectionObserver::~AXLanguageDetectionObserver() {
  tree_->RemoveObserver(this);
}

void AXLanguageDetectionObserver::OnAtomicUpdateFinished(
    ui::AXTree* tree,
    bool root_changed,
    const std::vector<Change>& changes) {
  // TODO(chrishall): We likely want to re-consider updating or resetting
  // AXLanguageInfoStats over time to better support detection on long running
  // pages.

  // TODO(chrishall): To support pruning deleted node data from stats we should
  // consider implementing OnNodeWillBeDeleted. Other options available include:
  // 1) move lang info from AXNode into a map on AXTree so that we can fetch
  //    based on id in here
  // 2) AXLanguageInfo destructor could remove itself

  // TODO(chrishall): Possible optimisation: only run detect/label for certain
  // change.type(s)), at least NODE_CREATED, NODE_CHANGED, and SUBTREE_CREATED.

  DCHECK(tree->language_detection_manager);

  // Perform Detect and Label for each node changed or created.
  // We currently only consider nodes with a role of kStaticText for detection.
  //
  // Note that language inheritance is now handled by AXNode::GetLanguage.
  //
  // Note that since Label no longer handles language inheritance, we only need
  // to call Label and Detect on the nodes that changed and don't need to
  // recurse.
  //
  // We do this in two passes because Detect updates page level statistics which
  // are later used by Label in order to make more accurate decisions.

  for (auto& change : changes) {
    if (change.node->data().role == ax::mojom::Role::kStaticText) {
      tree->language_detection_manager->DetectLanguagesForNode(change.node);
    }
  }

  for (auto& change : changes) {
    if (change.node->data().role == ax::mojom::Role::kStaticText) {
      tree->language_detection_manager->LabelLanguagesForNode(change.node);
    }
  }

  // OnAtomicUpdateFinished is used for dynamic language detection, this call to
  // ReportMetrics covers only the work we have performed in response to one
  // update to the AXTree.
  tree->language_detection_manager->lang_info_stats_.ReportMetrics();
}

}  // namespace ui
