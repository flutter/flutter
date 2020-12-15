// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_ACCESSIBILITY_AX_LANGUAGE_DETECTION_H_
#define UI_ACCESSIBILITY_AX_LANGUAGE_DETECTION_H_

#include <memory>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <utility>
#include <vector>

#include "base/macros.h"
#include "third_party/cld_3/src/src/nnet_language_identifier.h"
#include "ui/accessibility/ax_enums.mojom-forward.h"
#include "ui/accessibility/ax_export.h"
#include "ui/accessibility/ax_tree_observer.h"

namespace ui {

class AXNode;
class AXTree;

// This module implements language detection enabling Chrome to automatically
// detect the language for runs of text within the page.
//
// Node-level language detection runs once per page after the load complete
// event. This involves two passes:
//   *Detect* walks the tree from the given root using cld3 to detect up to 3
//            potential languages per node. A ranked list is created enumerating
//            all potential languages on a page.
//   *Label* re-walks the tree, assigning a language to each node considering
//           the potential languages from the detect phase, page level
//           statistics, and the assigned languages of ancestor nodes.
//
// Optionally an embedder may run *sub-node* language detection which attempts
// to assign languages for runs of text within a node, potentially down to the
// individual character level. This is useful in cases where a single paragraph
// involves switching between multiple languages, and where the speech engine
// doesn't automatically switch voices to handle different character sets.
// Due to the potentially small lengths of text runs involved this tends to be
// lower in accuracy, and works best when a node is composed of multiple
// languages with easily distinguishable scripts.

// AXLanguageInfo represents the local language detection data for all text
// within an AXNode. Stored on AXNode.
struct AX_EXPORT AXLanguageInfo {
  AXLanguageInfo();
  ~AXLanguageInfo();

  // This is the final language we have assigned for this node during the
  // 'label' step, it is the result of merging:
  //  a) The detected language for this node
  //  b) The declared lang attribute on this node
  //  c) the (recursive) language of the parent (detected or declared).
  //
  // This will be the empty string if no language was assigned during label
  // phase.
  //
  // IETF BCP 47 Language code (rfc5646).
  // examples:
  //  'de'
  //  'de-DE'
  //  'en'
  //  'en-US'
  //  'es-ES'
  //
  // This should not be read directly by clients of AXNode, instead clients
  // should call AXNode::GetLanguage().
  // TODO(chrishall): consider renaming this to `assigned_language`.
  std::string language;

  // Detected languages for this node sorted as returned by
  // FindTopNMostFreqLangs, which sorts in decreasing order of probability,
  // filtered to remove any unreliable results.
  std::vector<std::string> detected_languages;
};

// Each AXLanguageSpan contains a language, a probability, and start and end
// indices. The indices are used to specify the substring that contains the
// associated language. The string which the indices are relative to is not
// included in this structure.
// Also, the indices are relative to a Utf8 string.
// See documentation on GetLanguageAnnotationForStringAttribute for details
// on how to associate this object with a string.
struct AX_EXPORT AXLanguageSpan {
  int start_index;
  int end_index;
  std::string language;
  float probability;
};

// A single AXLanguageInfoStats instance is stored on each AXTree and contains
// statistics on detected languages for all the AXNodes in that tree.
//
// We rely on these tree-level statistics when labelling individual nodes, to
// provide extra signals to increase our confidence in assigning a detected
// language.
//
// These tree level statistics are also used to send reports on the language
// detection feature to enable tuning.
//
// The Label step will only assign a detected language to a node if that
// language is one of the most frequent languages on the page.
//
// For example, if a single node has detected_languages (in order of probability
// assigned by cld_3): da-DK, en-AU, fr-FR, but the page statistics overall
// indicate that the page is generally in en-AU and ja-JP, it is more likely to
// be a mis-recognition of Danish than an accurate assignment, so we assign
// en-AU instead of da-DK.
class AX_EXPORT AXLanguageInfoStats {
 public:
  AXLanguageInfoStats();
  ~AXLanguageInfoStats();

  // Each AXLanguageInfoStats is tied to a specific AXTree, copying is safe but
  // logically doesn't make sense.
  AXLanguageInfoStats(const AXLanguageInfoStats&) = delete;
  AXLanguageInfoStats& operator=(const AXLanguageInfoStats&) = delete;

  // Adjust our statistics to add provided detected languages.
  void Add(const std::vector<std::string>& languages);

  // Fetch the score for a given language.
  int GetScore(const std::string& lang) const;

  // Check if a given language is within the top results.
  bool CheckLanguageWithinTop(const std::string& lang);

  // Record statistics based on how we labelled a node.
  // We consider the language we labelled the node with, the language the author
  // assigned, and whether or not we assigned our highest confidence detection
  // result.
  void RecordLabelStatistics(const std::string& labelled_lang,
                             const std::string& author_lang,
                             bool labelled_with_first_result);

  // Update metrics to reflect we attempted to detect language for a node.
  void RecordDetectionAttempt();

  // Report metrics to UMA.
  // Reports statistics since last run, run once detect & label iteration.
  // If successful, will reset statistics.
  void ReportMetrics();

 private:
  // Allow access from a fixture only used in testing.
  friend class AXLanguageDetectionTestFixture;

  // Store a count of the occurrences of a given language.
  std::unordered_map<std::string, int> lang_counts_;

  // Cache of last calculated top language results.
  // A vector of pairs of (score, language) sorted by descending score.
  std::vector<std::pair<int, std::string>> top_results_;

  // Boolean recording that we have not mutated the statistics since last
  // calculating top results, setting this to false will cause recalculation
  // when the results are next fetched.
  bool top_results_valid_;

  // Invalidate the top results cache.
  void InvalidateTopResults();

  // Compute the top results and store them in cache.
  void GenerateTopResults();

  // TODO(chrishall): Do we want this for testing? or is it better to only test
  //  the generated metrics by inspecting the histogram?
  // Boolean used for testing metrics only, disables clearing of metrics.
  bool disable_metric_clearing_;
  void ClearMetrics();

  // *** Statistics recorded for metric reporting. ***
  // All statistics represent a single iteration of language detection and are
  // reset after each successful call of ReportMetrics.

  // The number of nodes we attempted detection on.
  int count_detection_attempted_;

  // The number of nodes we got detection results for.
  int count_detection_results_;

  // The number of nodes we assigned a label to.
  int count_labelled_;

  // The number of nodes we assigned a label to which was the highest confident
  // detected language.
  int count_labelled_with_top_result_;

  // The number of times we labelled a language which disagreed with the node's
  // author provided language annotation.
  //
  // If we have
  //  <div lang='en'><span>...</span><span>...</span></div>
  // and we detect and label both spans as having language 'fr', then we count
  // this as `2` overrides.
  int count_overridden_;

  // Set of top language detected for every node, used to generate the unique
  // number of detected languages metric (LangsPerPage).
  std::unordered_set<std::string> unique_top_lang_detected_;
};

// AXLanguageDetectionObserver is registered as a change observer on an AXTree
// and will run language detection after each update to the tree.
//
// We have kept this observer separate from the AXLanguageDetectionManager as we
// are aiming to launch language detection in two phases and wanted to try keep
// the code paths somewhat separate.
//
// TODO(chrishall): After both features have launched we could consider merging
// AXLanguageDetectionObserver into AXLanguageDetectionManager.
//
// TODO(chrishall): Investigate the cost of using AXTreeObserver, given that it
// has many empty virtual methods which are called for every AXTree change and
// we are only currently interested in OnAtomicUpdateFinished.
class AX_EXPORT AXLanguageDetectionObserver : public ui::AXTreeObserver {
 public:
  // Observer constructor will register itself with the provided AXTree.
  AXLanguageDetectionObserver(AXTree* tree);

  // Observer destructor will remove itself as an observer from the AXTree.
  ~AXLanguageDetectionObserver() override;

  // AXLanguageDetectionObserver contains a pointer so copying is non-trivial.
  AXLanguageDetectionObserver(const AXLanguageDetectionObserver&) = delete;
  AXLanguageDetectionObserver& operator=(const AXLanguageDetectionObserver&) =
      delete;

 private:
  void OnAtomicUpdateFinished(ui::AXTree* tree,
                              bool root_changed,
                              const std::vector<Change>& changes) override;

  // Non-owning pointer to AXTree, used to de-register observer on destruction.
  AXTree* const tree_;
};

// AXLanguageDetectionManager manages all of the context needed for language
// detection within an AXTree.
class AX_EXPORT AXLanguageDetectionManager {
 public:
  // Construct an AXLanguageDetectionManager for the specified tree.
  explicit AXLanguageDetectionManager(AXTree* tree);
  ~AXLanguageDetectionManager();

  // AXLanguageDetectionManager contains pointers so copying is non-trivial.
  AXLanguageDetectionManager(const AXLanguageDetectionManager&) = delete;
  AXLanguageDetectionManager& operator=(const AXLanguageDetectionManager&) =
      delete;

  // Detect languages for each node in the tree managed by this manager.
  // This is the first pass in detection and labelling.
  // This only detects the language, it does not label it, for that see
  //  LabelLanguageForSubtree.
  void DetectLanguages();

  // Label languages for each node in the tree manager by this manager.
  // This is the second pass in detection and labelling.
  // This will label the language, but relies on the earlier detection phase
  // having already completed.
  void LabelLanguages();

  // Sub-node language detection for a given string attribute.
  // For example, if a node has name: "My name is Fred", then calling
  // GetLanguageAnnotationForStringAttribute(*node, ax::mojom::StringAttribute::
  // kName) would return language detection information about "My name is Fred".
  std::vector<AXLanguageSpan> GetLanguageAnnotationForStringAttribute(
      const AXNode& node,
      ax::mojom::StringAttribute attr);

  // Construct and register a dynamic content change observer for this manager.
  void RegisterLanguageDetectionObserver();

 private:
  friend class AXLanguageDetectionObserver;

  // Allow access from a fixture only used in testing.
  friend class AXLanguageDetectionTestFixture;

  // Helper methods to test if language detection features are enabled.
  static bool IsStaticLanguageDetectionEnabled();
  static bool IsDynamicLanguageDetectionEnabled();

  // Perform detection for subtree rooted at subtree_root.
  void DetectLanguagesForSubtree(AXNode* subtree_root);
  // Perform detection for node. Will not descend into children.
  void DetectLanguagesForNode(AXNode* node);
  // Perform labelling for subtree rooted at subtree_root.
  void LabelLanguagesForSubtree(AXNode* subtree_root);
  // Perform labelling for node. Will not descend into children.
  void LabelLanguagesForNode(AXNode* node);

  // This language identifier is constructed with a default minimum byte length
  // of chrome_lang_id::NNetLanguageIdentifier::kMinNumBytesToConsider and is
  // used for detecting page-level languages.
  chrome_lang_id::NNetLanguageIdentifier language_identifier_;

  // This language identifier is constructed with a minimum byte length of
  // kShortTextIdentifierMinByteLength so it can be used for detecting languages
  // of shorter text (e.g. one character).
  chrome_lang_id::NNetLanguageIdentifier short_text_language_identifier_;

  // The observer to support dynamic content language detection.
  std::unique_ptr<AXLanguageDetectionObserver> language_detection_observer_;

  // Non-owning back pointer to the tree which owns this manager.
  AXTree* tree_;

  AXLanguageInfoStats lang_info_stats_;
};

}  // namespace ui

#endif  // UI_ACCESSIBILITY_AX_LANGUAGE_DETECTION_H_
