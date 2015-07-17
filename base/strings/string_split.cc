// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/strings/string_split.h"

#include "base/logging.h"
#include "base/strings/string_util.h"
#include "base/third_party/icu/icu_utf.h"

namespace base {

namespace {

// PieceToOutputType converts a StringPiece as needed to a given output type,
// which is either the same type of StringPiece (a NOP) or the corresponding
// non-piece string type.
//
// The default converter is a NOP, it works when the OutputType is the
// correct StringPiece.
template<typename Str, typename OutputType>
OutputType PieceToOutputType(BasicStringPiece<Str> piece) {
  return piece;
}
template<>  // Convert StringPiece to std::string
std::string PieceToOutputType<std::string, std::string>(StringPiece piece) {
  return piece.as_string();
}
template<>  // Convert StringPiece16 to string16.
string16 PieceToOutputType<string16, string16>(StringPiece16 piece) {
  return piece.as_string();
}

// Returns either the ASCII or UTF-16 whitespace.
template<typename Str> BasicStringPiece<Str> WhitespaceForType();
template<> StringPiece16 WhitespaceForType<string16>() {
  return kWhitespaceUTF16;
}
template<> StringPiece WhitespaceForType<std::string>() {
  return kWhitespaceASCII;
}

// Optimize the single-character case to call find() on the string instead,
// since this is the common case and can be made faster. This could have been
// done with template specialization too, but would have been less clear.
//
// There is no corresponding FindFirstNotOf because StringPiece already
// implements these different versions that do the optimized searching.
size_t FindFirstOf(StringPiece piece, char c, size_t pos) {
  return piece.find(c, pos);
}
size_t FindFirstOf(StringPiece16 piece, char16 c, size_t pos) {
  return piece.find(c, pos);
}
size_t FindFirstOf(StringPiece piece, StringPiece one_of, size_t pos) {
  return piece.find_first_of(one_of, pos);
}
size_t FindFirstOf(StringPiece16 piece, StringPiece16 one_of, size_t pos) {
  return piece.find_first_of(one_of, pos);
}

// General string splitter template. Can take 8- or 16-bit input, can produce
// the corresponding string or StringPiece output, and can take single- or
// multiple-character delimiters.
//
// DelimiterType is either a character (Str::value_type) or a string piece of
// multiple characters (BasicStringPiece<Str>). StringPiece has a version of
// find for both of these cases, and the single-character version is the most
// common and can be implemented faster, which is why this is a template.
template<typename Str, typename OutputStringType, typename DelimiterType>
static std::vector<OutputStringType> SplitStringT(
    BasicStringPiece<Str> str,
    DelimiterType delimiter,
    WhitespaceHandling whitespace,
    SplitResult result_type) {
  std::vector<OutputStringType> result;
  if (str.empty())
    return result;

  size_t start = 0;
  while (start != Str::npos) {
    size_t end = FindFirstOf(str, delimiter, start);

    BasicStringPiece<Str> piece;
    if (end == Str::npos) {
      piece = str.substr(start);
      start = Str::npos;
    } else {
      piece = str.substr(start, end - start);
      start = end + 1;
    }

    if (whitespace == TRIM_WHITESPACE)
      piece = TrimString(piece, WhitespaceForType<Str>(), TRIM_ALL);

    if (result_type == SPLIT_WANT_ALL || !piece.empty())
      result.push_back(PieceToOutputType<Str, OutputStringType>(piece));
  }
  return result;
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

}  // namespace

std::vector<std::string> SplitString(StringPiece input,
                                     StringPiece separators,
                                     WhitespaceHandling whitespace,
                                     SplitResult result_type) {
  if (separators.size() == 1) {
    return SplitStringT<std::string, std::string, char>(
        input, separators[0], whitespace, result_type);
  }
  return SplitStringT<std::string, std::string, StringPiece>(
      input, separators, whitespace, result_type);
}

std::vector<string16> SplitString(StringPiece16 input,
                                  StringPiece16 separators,
                                  WhitespaceHandling whitespace,
                                  SplitResult result_type) {
  if (separators.size() == 1) {
    return SplitStringT<string16, string16, char16>(
        input, separators[0], whitespace, result_type);
  }
  return SplitStringT<string16, string16, StringPiece16>(
      input, separators, whitespace, result_type);
}

std::vector<StringPiece> SplitStringPiece(StringPiece input,
                                          StringPiece separators,
                                          WhitespaceHandling whitespace,
                                          SplitResult result_type) {
  if (separators.size() == 1) {
    return SplitStringT<std::string, StringPiece, char>(
        input, separators[0], whitespace, result_type);
  }
  return SplitStringT<std::string, StringPiece, StringPiece>(
      input, separators, whitespace, result_type);
}

std::vector<StringPiece16> SplitStringPiece(StringPiece16 input,
                                            StringPiece16 separators,
                                            WhitespaceHandling whitespace,
                                            SplitResult result_type) {
  if (separators.size() == 1) {
    return SplitStringT<string16, StringPiece16, char16>(
        input, separators[0], whitespace, result_type);
  }
  return SplitStringT<string16, StringPiece16, StringPiece16>(
      input, separators, whitespace, result_type);
}

void SplitString(const string16& str,
                 char16 c,
                 std::vector<string16>* result) {
  DCHECK(CBU16_IS_SINGLE(c));
  *result = SplitStringT<string16, string16, char16>(
      str, c, TRIM_WHITESPACE, SPLIT_WANT_ALL);

  // Backward-compat hack: The old SplitString implementation would keep
  // empty substrings, for example:
  //    "a,,b" -> ["a", "", "b"]
  //    "a, ,b" -> ["a", "", "b"]
  // which the current code also does. But the old one would discard them when
  // the only result was that empty string:
  //    "  " -> []
  // In the latter case, our new code will give [""]
  if (result->size() == 1 && (*result)[0].empty())
    result->clear();
}

void SplitString(const std::string& str,
                 char c,
                 std::vector<std::string>* result) {
#if CHAR_MIN < 0
  DCHECK_GE(c, 0);
#endif
  DCHECK_LT(c, 0x7F);
  *result = SplitStringT<std::string, std::string, char>(
      str, c, TRIM_WHITESPACE, SPLIT_WANT_ALL);

  // Backward-compat hack, see above.
  if (result->size() == 1 && (*result)[0].empty())
    result->clear();
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

void SplitStringDontTrim(StringPiece16 str,
                         char16 c,
                         std::vector<string16>* result) {
  DCHECK(CBU16_IS_SINGLE(c));
  *result = SplitStringT<string16, string16, char16>(
      str, c, KEEP_WHITESPACE, SPLIT_WANT_ALL);
}

void SplitStringDontTrim(StringPiece str,
                         char c,
                         std::vector<std::string>* result) {
#if CHAR_MIN < 0
  DCHECK_GE(c, 0);
#endif
  DCHECK_LT(c, 0x7F);
  *result = SplitStringT<std::string, std::string, char>(
      str, c, KEEP_WHITESPACE, SPLIT_WANT_ALL);
}

void SplitStringAlongWhitespace(const string16& str,
                                std::vector<string16>* result) {
  *result = SplitStringT<string16, string16, StringPiece16>(
      str, StringPiece16(kWhitespaceASCIIAs16),
      TRIM_WHITESPACE, SPLIT_WANT_NONEMPTY);
}

void SplitStringAlongWhitespace(const std::string& str,
                                std::vector<std::string>* result) {
  *result = SplitStringT<std::string, std::string, StringPiece>(
      str, StringPiece(kWhitespaceASCII),
      TRIM_WHITESPACE, SPLIT_WANT_NONEMPTY);
}

}  // namespace base
