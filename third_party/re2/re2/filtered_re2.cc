// Copyright 2009 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#include <string>
#include "util/util.h"
#include "re2/filtered_re2.h"
#include "re2/prefilter.h"
#include "re2/prefilter_tree.h"

namespace re2 {

FilteredRE2::FilteredRE2()
    : compiled_(false),
      prefilter_tree_(new PrefilterTree()) {
}

FilteredRE2::~FilteredRE2() {
  for (int i = 0; i < re2_vec_.size(); i++)
    delete re2_vec_[i];
  delete prefilter_tree_;
}

RE2::ErrorCode FilteredRE2::Add(const StringPiece& pattern,
                                const RE2::Options& options, int* id) {
  RE2* re = new RE2(pattern, options);
  RE2::ErrorCode code = re->error_code();

  if (!re->ok()) {
    if (options.log_errors()) {
      LOG(ERROR) << "Couldn't compile regular expression, skipping: "
                 << re << " due to error " << re->error();
    }
    delete re;
  } else {
    *id = re2_vec_.size();
    re2_vec_.push_back(re);
  }

  return code;
}

void FilteredRE2::Compile(vector<string>* atoms) {
  if (compiled_ || re2_vec_.size() == 0) {
    LOG(INFO) << "C: " << compiled_ << " S:" << re2_vec_.size();
    return;
  }

  for (int i = 0; i < re2_vec_.size(); i++) {
    Prefilter* prefilter = Prefilter::FromRE2(re2_vec_[i]);
    prefilter_tree_->Add(prefilter);
  }
  atoms->clear();
  prefilter_tree_->Compile(atoms);
  compiled_ = true;
}

int FilteredRE2::SlowFirstMatch(const StringPiece& text) const {
  for (int i = 0; i < re2_vec_.size(); i++)
    if (RE2::PartialMatch(text, *re2_vec_[i]))
      return i;
  return -1;
}

int FilteredRE2::FirstMatch(const StringPiece& text,
                            const vector<int>& atoms) const {
  if (!compiled_) {
    LOG(DFATAL) << "FirstMatch called before Compile";
    return -1;
  }
  vector<int> regexps;
  prefilter_tree_->RegexpsGivenStrings(atoms, &regexps);
  for (int i = 0; i < regexps.size(); i++)
    if (RE2::PartialMatch(text, *re2_vec_[regexps[i]]))
      return regexps[i];
  return -1;
}

bool FilteredRE2::AllMatches(
    const StringPiece& text,
    const vector<int>& atoms,
    vector<int>* matching_regexps) const {
  matching_regexps->clear();
  vector<int> regexps;
  prefilter_tree_->RegexpsGivenStrings(atoms, &regexps);
  for (int i = 0; i < regexps.size(); i++)
    if (RE2::PartialMatch(text, *re2_vec_[regexps[i]]))
      matching_regexps->push_back(regexps[i]);
  return !matching_regexps->empty();
}

void FilteredRE2::RegexpsGivenStrings(const vector<int>& matched_atoms,
                                      vector<int>* passed_regexps) {
  prefilter_tree_->RegexpsGivenStrings(matched_atoms, passed_regexps);
}


void FilteredRE2::PrintPrefilter(int regexpid) {
  prefilter_tree_->PrintPrefilter(regexpid);
}

}  // namespace re2
