// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/strings/string_split.h"

#include "base/logging.h"
#include "base/strings/string_util.h"
#include "base/third_party/icu/icu_utf.h"

namespace base {

namespace {

template <typename STR>
void SplitStringT(const STR& str,
                  const typename STR::value_type s,
                  bool trim_whitespace,
                  std::vector<STR>* r) {
  r->clear();
  size_t last = 0;
  size_t c = str.size();
  for (size_t i = 0; i <= c; ++i) {
    if (i == c || str[i] == s) {
      STR tmp(str, last, i - last);
      if (trim_whitespace)
        TrimWhitespace(tmp, TRIM_ALL, &tmp);
      // Avoid converting an empty or all-whitespace source string into a vector
      // of one empty string.
      if (i != c || !r->empty() || !tmp.empty())
        r->push_back(tmp);
      last = i + 1;
    }
  }
}

bool SplitStringIntoKeyValue(const std::string& line,
                             char key_value_delimiter,
                             std::string* key,
                             std::string* value) {
  key->clear();
  value->clear();

  // Find the delimiter.
  size_t end_key_pos = line.find_first_of(key_value_delimiter);
  if (end_key_pos == std::string::npos) {
    DVLOG(1) << "cannot find delimiter in: " << line;
    return false;    // no delimiter
  }
  key->assign(line, 0, end_key_pos);

  // Find the value string.
  std::string remains(line, end_key_pos, line.size() - end_key_pos);
  size_t begin_value_pos = remains.find_first_not_of(key_value_delimiter);
  if (begin_value_pos == std::string::npos) {
    DVLOG(1) << "cannot parse value from line: " << line;
    return false;   // no value
  }
  value->assign(remains, begin_value_pos, remains.size() - begin_value_pos);
  return true;
}

template <typename STR>
void SplitStringUsingSubstrT(const STR& str,
                                    const STR& s,
                                    std::vector<STR>* r) {
  r->clear();
  typename STR::size_type begin_index = 0;
  while (true) {
    const typename STR::size_type end_index = str.find(s, begin_index);
    if (end_index == STR::npos) {
      const STR term = str.substr(begin_index);
      STR tmp;
      TrimWhitespace(term, TRIM_ALL, &tmp);
      r->push_back(tmp);
      return;
    }
    const STR term = str.substr(begin_index, end_index - begin_index);
    STR tmp;
    TrimWhitespace(term, TRIM_ALL, &tmp);
    r->push_back(tmp);
    begin_index = end_index + s.size();
  }
}

template<typename STR>
void SplitStringAlongWhitespaceT(const STR& str, std::vector<STR>* result) {
  result->clear();
  const size_t length = str.length();
  if (!length)
    return;

  bool last_was_ws = false;
  size_t last_non_ws_start = 0;
  for (size_t i = 0; i < length; ++i) {
    switch (str[i]) {
      // HTML 5 defines whitespace as: space, tab, LF, line tab, FF, or CR.
      case L' ':
      case L'\t':
      case L'\xA':
      case L'\xB':
      case L'\xC':
      case L'\xD':
        if (!last_was_ws) {
          if (i > 0) {
            result->push_back(
                str.substr(last_non_ws_start, i - last_non_ws_start));
          }
          last_was_ws = true;
        }
        break;

      default:  // Not a space character.
        if (last_was_ws) {
          last_was_ws = false;
          last_non_ws_start = i;
        }
        break;
    }
  }
  if (!last_was_ws) {
    result->push_back(
        str.substr(last_non_ws_start, length - last_non_ws_start));
  }
}

}  // namespace

void SplitString(const string16& str,
                 char16 c,
                 std::vector<string16>* r) {
  DCHECK(CBU16_IS_SINGLE(c));
  SplitStringT(str, c, true, r);
}

void SplitString(const std::string& str,
                 char c,
                 std::vector<std::string>* r) {
#if CHAR_MIN < 0
  DCHECK_GE(c, 0);
#endif
  DCHECK_LT(c, 0x7F);
  SplitStringT(str, c, true, r);
}

bool SplitStringIntoKeyValuePairs(const std::string& line,
                                  char key_value_delimiter,
                                  char key_value_pair_delimiter,
                                  StringPairs* key_value_pairs) {
  key_value_pairs->clear();

  std::vector<std::string> pairs;
  SplitString(line, key_value_pair_delimiter, &pairs);

  bool success = true;
  for (size_t i = 0; i < pairs.size(); ++i) {
    // Don't add empty pairs into the result.
    if (pairs[i].empty())
      continue;

    std::string key;
    std::string value;
    if (!SplitStringIntoKeyValue(pairs[i], key_value_delimiter, &key, &value)) {
      // Don't return here, to allow for pairs without associated
      // value or key; just record that the split failed.
      success = false;
    }
    key_value_pairs->push_back(make_pair(key, value));
  }
  return success;
}

void SplitStringUsingSubstr(const string16& str,
                            const string16& s,
                            std::vector<string16>* r) {
  SplitStringUsingSubstrT(str, s, r);
}

void SplitStringUsingSubstr(const std::string& str,
                            const std::string& s,
                            std::vector<std::string>* r) {
  SplitStringUsingSubstrT(str, s, r);
}

void SplitStringDontTrim(const string16& str,
                         char16 c,
                         std::vector<string16>* r) {
  DCHECK(CBU16_IS_SINGLE(c));
  SplitStringT(str, c, false, r);
}

void SplitStringDontTrim(const std::string& str,
                         char c,
                         std::vector<std::string>* r) {
#if CHAR_MIN < 0
  DCHECK_GE(c, 0);
#endif
  DCHECK_LT(c, 0x7F);
  SplitStringT(str, c, false, r);
}

void SplitStringAlongWhitespace(const string16& str,
                                std::vector<string16>* result) {
  SplitStringAlongWhitespaceT(str, result);
}

void SplitStringAlongWhitespace(const std::string& str,
                                std::vector<std::string>* result) {
  SplitStringAlongWhitespaceT(str, result);
}

}  // namespace base
