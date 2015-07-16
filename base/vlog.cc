// Copyright (c) 2010 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/vlog.h"

#include <cstddef>
#include <ostream>
#include <utility>

#include "base/basictypes.h"
#include "base/logging.h"
#include "base/strings/string_number_conversions.h"
#include "base/strings/string_split.h"

namespace logging {

const int VlogInfo::kDefaultVlogLevel = 0;

struct VlogInfo::VmodulePattern {
  enum MatchTarget { MATCH_MODULE, MATCH_FILE };

  explicit VmodulePattern(const std::string& pattern);

  VmodulePattern();

  std::string pattern;
  int vlog_level;
  MatchTarget match_target;
};

VlogInfo::VmodulePattern::VmodulePattern(const std::string& pattern)
    : pattern(pattern),
      vlog_level(VlogInfo::kDefaultVlogLevel),
      match_target(MATCH_MODULE) {
  // If the pattern contains a {forward,back} slash, we assume that
  // it's meant to be tested against the entire __FILE__ string.
  std::string::size_type first_slash = pattern.find_first_of("\\/");
  if (first_slash != std::string::npos)
    match_target = MATCH_FILE;
}

VlogInfo::VmodulePattern::VmodulePattern()
    : vlog_level(VlogInfo::kDefaultVlogLevel),
      match_target(MATCH_MODULE) {}

VlogInfo::VlogInfo(const std::string& v_switch,
                   const std::string& vmodule_switch,
                   int* min_log_level)
    : min_log_level_(min_log_level) {
  DCHECK(min_log_level != NULL);

  int vlog_level = 0;
  if (!v_switch.empty()) {
    if (base::StringToInt(v_switch, &vlog_level)) {
      SetMaxVlogLevel(vlog_level);
    } else {
      DLOG(WARNING) << "Could not parse v switch \"" << v_switch << "\"";
    }
  }

  base::StringPairs kv_pairs;
  if (!base::SplitStringIntoKeyValuePairs(
          vmodule_switch, '=', ',', &kv_pairs)) {
    DLOG(WARNING) << "Could not fully parse vmodule switch \""
                  << vmodule_switch << "\"";
  }
  for (base::StringPairs::const_iterator it = kv_pairs.begin();
       it != kv_pairs.end(); ++it) {
    VmodulePattern pattern(it->first);
    if (!base::StringToInt(it->second, &pattern.vlog_level)) {
      DLOG(WARNING) << "Parsed vlog level for \""
                    << it->first << "=" << it->second
                    << "\" as " << pattern.vlog_level;
    }
    vmodule_levels_.push_back(pattern);
  }
}

VlogInfo::~VlogInfo() {}

namespace {

// Given a path, returns the basename with the extension chopped off
// (and any -inl suffix).  We avoid using FilePath to minimize the
// number of dependencies the logging system has.
base::StringPiece GetModule(const base::StringPiece& file) {
  base::StringPiece module(file);
  base::StringPiece::size_type last_slash_pos =
      module.find_last_of("\\/");
  if (last_slash_pos != base::StringPiece::npos)
    module.remove_prefix(last_slash_pos + 1);
  base::StringPiece::size_type extension_start = module.rfind('.');
  module = module.substr(0, extension_start);
  static const char kInlSuffix[] = "-inl";
  static const int kInlSuffixLen = arraysize(kInlSuffix) - 1;
  if (module.ends_with(kInlSuffix))
    module.remove_suffix(kInlSuffixLen);
  return module;
}

}  // namespace

int VlogInfo::GetVlogLevel(const base::StringPiece& file) const {
  if (!vmodule_levels_.empty()) {
    base::StringPiece module(GetModule(file));
    for (std::vector<VmodulePattern>::const_iterator it =
             vmodule_levels_.begin(); it != vmodule_levels_.end(); ++it) {
      base::StringPiece target(
          (it->match_target == VmodulePattern::MATCH_FILE) ? file : module);
      if (MatchVlogPattern(target, it->pattern))
        return it->vlog_level;
    }
  }
  return GetMaxVlogLevel();
}

void VlogInfo::SetMaxVlogLevel(int level) {
  // Log severity is the negative verbosity.
  *min_log_level_ = -level;
}

int VlogInfo::GetMaxVlogLevel() const {
  return -*min_log_level_;
}

bool MatchVlogPattern(const base::StringPiece& string,
                      const base::StringPiece& vlog_pattern) {
  base::StringPiece p(vlog_pattern);
  base::StringPiece s(string);
  // Consume characters until the next star.
  while (!p.empty() && !s.empty() && (p[0] != '*')) {
    switch (p[0]) {
      // A slash (forward or back) must match a slash (forward or back).
      case '/':
      case '\\':
        if ((s[0] != '/') && (s[0] != '\\'))
          return false;
        break;

      // A '?' matches anything.
      case '?':
        break;

      // Anything else must match literally.
      default:
        if (p[0] != s[0])
          return false;
        break;
    }
    p.remove_prefix(1), s.remove_prefix(1);
  }

  // An empty pattern here matches only an empty string.
  if (p.empty())
    return s.empty();

  // Coalesce runs of consecutive stars.  There should be at least
  // one.
  while (!p.empty() && (p[0] == '*'))
    p.remove_prefix(1);

  // Since we moved past the stars, an empty pattern here matches
  // anything.
  if (p.empty())
    return true;

  // Since we moved past the stars and p is non-empty, if some
  // non-empty substring of s matches p, then we ourselves match.
  while (!s.empty()) {
    if (MatchVlogPattern(s, p))
      return true;
    s.remove_prefix(1);
  }

  // Otherwise, we couldn't find a match.
  return false;
}

}  // namespace logging
