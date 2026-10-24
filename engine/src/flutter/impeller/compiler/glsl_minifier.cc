// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/compiler/glsl_minifier.h"

#include <algorithm>
#include <charconv>
#include <cmath>
#include <sstream>
#include <string>
#include <string_view>
#include <system_error>
#include <unordered_map>
#include <unordered_set>
#include <utility>
#include <vector>

#include "flutter/third_party/re2/re2/re2.h"

namespace impeller {
namespace compiler {

std::string StripGLSLComments(std::string_view source) {
  std::string result(source);
  // Matches `//` through the end of the line (preserving `\n`) or non-greedy
  // `/* ... */` blocks across lines.
  static const re2::LazyRE2 kCommentPattern = {R"(//[^\n]*|/\*[\s\S]*?\*/)"};
  re2::RE2::GlobalReplace(&result, *kCommentPattern, "");
  return result;
}

bool IsGLSLIdentStartChar(char c) {
  // Use explicit ASCII range checks rather than `<cctype>` classification
  // functions, which depend on the active global C locale.
  return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_';
}

bool IsGLSLIdentChar(char c) {
  return IsGLSLIdentStartChar(c) || (c >= '0' && c <= '9');
}

bool IsGLSLIdentOrNumChar(char c) {
  return IsGLSLIdentChar(c) || c == '.';
}

bool NeedsGLSLSpaceBetween(char prev, char next) {
  return (IsGLSLIdentOrNumChar(prev) && IsGLSLIdentOrNumChar(next)) ||
         (prev == '+' && next == '+') || (prev == '-' && next == '-');
}

std::string ShortenGLSLFloatLiteral(std::string_view token, float value) {
  // Single-precision floats have up to 9 significant decimal digits, so tokens
  // of length <= 9 are already compact. Integer tokens (without '.', 'e', or
  // 'E') and non-finite values must not be rewritten as float literals.
  if (token.size() <= 9 ||
      token.find_first_of(".eE") == std::string_view::npos ||
      !std::isfinite(value)) {
    return std::string(token);
  }
  // `std::to_chars` with no format/precision argument emits the shortest
  // decimal representation that round-trips to the exact same `float`.
  char buf[32];
  const auto [end_ptr, ec] = std::to_chars(buf, buf + sizeof(buf), value);
  // Fall back to the original token if `std::to_chars` reports a conversion
  // error.
  if (ec != std::errc{}) {
    return std::string(token);
  }
  std::string candidate(buf, end_ptr);
  // Ensure the shortened token still contains a decimal point or exponent so
  // GLSL continues to lex it as a floating-point literal rather than an int.
  if (candidate.find_first_of(".eE") == std::string::npos) {
    candidate += ".0";
  }
  return candidate.size() < token.size() ? candidate : std::string(token);
}

std::string ShortenGLSLFloatLiteralsInLine(std::string_view line) {
  std::string out;
  out.reserve(line.size());
  size_t i = 0;
  while (i < line.size()) {
    // Only attempt to parse a numeric literal at the start of a token so digits
    // embedded in identifiers (such as `vec4` or `_123`) are ignored. Use an
    // explicit ASCII digit check rather than `std::isdigit` to avoid any locale
    // dependency.
    const bool at_token_start = (i == 0 || !IsGLSLIdentOrNumChar(line[i - 1]));
    if (at_token_start && line[i] >= '0' && line[i] <= '9') {
      float value = 0.0f;
      const char* first = line.data() + i;
      const char* last = line.data() + line.size();
      const auto [ptr, ec] = std::from_chars(first, last, value);
      // SPIRV-Cross may emit float literals with a trailing `f` or `F` suffix
      // (e.g. `0.300000011920928955078125f`) when targeting GLSL ES 3.00 or
      // desktop GLSL. Because `std::from_chars` stops before the suffix and
      // `f`/`F` is an identifier character, explicitly consume a trailing
      // `f`/`F` if the parsed slice contains a decimal point or exponent and
      // is not followed by another identifier/number character (such as
      // `1.0foo`).
      const std::string_view parsed(first, static_cast<size_t>(ptr - first));
      const bool has_float_suffix =
          ptr < last && (*ptr == 'f' || *ptr == 'F') &&
          parsed.find_first_of(".eE") != std::string_view::npos &&
          (ptr + 1 == last || !IsGLSLIdentOrNumChar(*(ptr + 1)));
      // Accept the parsed token only if `std::from_chars` succeeded and the
      // match ends at a token boundary (not followed by an identifier/dot
      // character such as `123abc` or `1.0.2`).
      if (ec == std::errc{} &&
          (ptr == last || !IsGLSLIdentOrNumChar(*ptr) || has_float_suffix)) {
        const char* token_end = has_float_suffix ? ptr + 1 : ptr;
        const std::string_view token(first,
                                     static_cast<size_t>(token_end - first));
        out += ShortenGLSLFloatLiteral(token, value);
        i += token.size();
        continue;
      }
    }
    out.push_back(line[i]);
    ++i;
  }
  return out;
}

std::string_view TrimGLSLLineWhitespace(std::string_view line) {
  const size_t first = line.find_first_not_of(" \t\r");
  if (first == std::string_view::npos) {
    return {};
  }
  return line.substr(first, line.find_last_not_of(" \t\r") - first + 1);
}

std::string CollapseGLSLHorizontalWhitespace(std::string_view line) {
  std::string collapsed(line);
  static const re2::LazyRE2 kHorizontalSpace = {R"([ \t]+)"};
  re2::RE2::GlobalReplace(&collapsed, *kHorizontalSpace, " ");
  return collapsed;
}

std::string MinifyGLSLNonPreprocessorLine(std::string_view line) {
  const std::string_view trimmed = TrimGLSLLineWhitespace(line);
  if (trimmed.empty()) {
    return {};
  }
  const std::string collapsed = CollapseGLSLHorizontalWhitespace(trimmed);
  std::string minified;
  minified.reserve(collapsed.size());
  for (size_t i = 0; i < collapsed.size(); ++i) {
    const char ch = collapsed[i];
    if (ch == ' ') {
      // Because `trimmed` has no leading or trailing whitespace, any space in
      // `collapsed` is guaranteed to have a preceding character in `minified`
      // and a following character in `collapsed`.
      if (NeedsGLSLSpaceBetween(minified.back(), collapsed[i + 1])) {
        minified.push_back(' ');
      }
    } else {
      minified.push_back(ch);
    }
  }
  return minified;
}

bool IsSynthesizedGLSLIdentifier(std::string_view token) {
  // Matches SPIRV-Cross synthesized SSA/local temporaries (`_<digits>`),
  // RelaxedPrecision copy temporaries (`mp_copy_*`, `hp_copy_*`), and
  // single-iteration dummy loop counters (`spvDummy<digits>`).
  static const re2::LazyRE2 kSynthPattern = {
      R"(^(_[0-9]+|(?:mp|hp)_copy_[a-zA-Z0-9_]+|spvDummy[0-9]+)$)"};
  return re2::RE2::FullMatch(
      re2::StringPiece(token.data(), static_cast<int>(token.size())),
      *kSynthPattern);
}

std::string NextShortGLSLIdentifier(
    size_t& cursor,
    const std::unordered_set<std::string_view>& reserved) {
  // Leading character cannot be a digit or underscore (leading underscores such
  // as `_0` are either longer than 1 character or could collide with `__`
  // reserved prefixes).
  static constexpr std::string_view kFirstChars =
      "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
  static constexpr std::string_view kRestChars =
      "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_";

  while (true) {
    std::string candidate;
    size_t value = cursor++;
    candidate.push_back(kFirstChars[value % kFirstChars.size()]);
    value /= kFirstChars.size();
    while (value > 0) {
      --value;
      candidate.push_back(kRestChars[value % kRestChars.size()]);
      value /= kRestChars.size();
    }
    if (reserved.find(candidate) == reserved.end()) {
      return candidate;
    }
  }
}

std::unordered_map<std::string_view, std::string> BuildGLSLIdentifierRenameMap(
    std::string_view source) {
  // Short 2- and 3-letter GLSL keywords, types, and built-ins that must never
  // be generated as replacement names even if they do not appear in `source`.
  std::unordered_set<std::string_view> reserved = {
      "do",  "if",  "in",  "no",  "or",  "to",  "abs", "all", "any", "asm",
      "cos", "dot", "exp", "for", "int", "log", "mat", "max", "min", "mix",
      "mod", "new", "not", "out", "pow", "sin", "tan", "vec", "xor",
  };

  // Scan all word tokens in `source`, adding every identifier to `reserved` and
  // counting occurrences of synthesized internal identifiers.
  std::unordered_map<std::string_view, size_t> candidate_counts;
  static const re2::LazyRE2 kWordPattern = {R"(([a-zA-Z0-9_]+))"};
  re2::StringPiece input(source.data(), static_cast<int>(source.size()));
  re2::StringPiece word;
  while (re2::RE2::FindAndConsume(&input, *kWordPattern, &word)) {
    const std::string_view tok(word.data(), word.size());
    if (!IsGLSLIdentStartChar(tok.front())) {
      continue;
    }
    reserved.insert(tok);
    if (IsSynthesizedGLSLIdentifier(tok)) {
      ++candidate_counts[tok];
    }
  }

  if (candidate_counts.empty()) {
    return {};
  }

  // Sort candidates by descending frequency (breaking ties lexicographically)
  // so the most frequently used temporaries receive 1-character names.
  std::vector<std::pair<std::string_view, size_t>> sorted_candidates(
      candidate_counts.begin(), candidate_counts.end());
  std::sort(sorted_candidates.begin(), sorted_candidates.end(),
            [](const auto& a, const auto& b) {
              if (a.second != b.second) {
                return a.second > b.second;
              }
              return a.first < b.first;
            });

  std::unordered_map<std::string_view, std::string> rename_map;
  size_t name_cursor = 0;
  for (const auto& [tok, count] : sorted_candidates) {
    std::string short_name = NextShortGLSLIdentifier(name_cursor, reserved);
    if (short_name.size() < tok.size()) {
      rename_map.emplace(tok, std::move(short_name));
    }
  }
  return rename_map;
}

std::string ShortenGLSLInternalIdentifiers(std::string_view source) {
  const auto rename_map = BuildGLSLIdentifierRenameMap(source);
  if (rename_map.empty()) {
    return std::string(source);
  }

  std::string out;
  out.reserve(source.size());
  size_t i = 0;
  while (i < source.size()) {
    if (IsGLSLIdentChar(source[i])) {
      const size_t start = i;
      while (i < source.size() && IsGLSLIdentChar(source[i])) {
        ++i;
      }
      const std::string_view tok = source.substr(start, i - start);
      if (const auto it = rename_map.find(tok); it != rename_map.end()) {
        out.append(it->second);
      } else {
        out.append(tok);
      }
    } else {
      out.push_back(source[i]);
      ++i;
    }
  }
  return out;
}

std::string MinifyGLSL(std::string_view source) {
  const std::string uncommented = StripGLSLComments(source);
  std::string result;
  result.reserve(uncommented.size());

  std::istringstream stream(uncommented);
  std::string line;
  while (std::getline(stream, line)) {
    const std::string_view raw_line = TrimGLSLLineWhitespace(line);
    if (raw_line.empty()) {
      continue;
    }

    const std::string shortened_line = ShortenGLSLFloatLiteralsInLine(raw_line);
    // Preprocessor directives (`#version`, `#extension`, `#ifndef`, `#define`,
    // `#endif`, etc.) must remain on their own newline-delimited lines.
    if (shortened_line.front() == '#') {
      if (!result.empty() && result.back() != '\n') {
        result.push_back('\n');
      }
      result += CollapseGLSLHorizontalWhitespace(shortened_line);
      result.push_back('\n');
      continue;
    }

    // Non-preprocessor lines are joined onto a single line to save ~12 KiB of
    // newline bytes across the embedded GLES/GLES3 shader blobs, inserting a
    // separating space only when adjacent boundary tokens would otherwise
    // merge.
    const std::string minified_line =
        MinifyGLSLNonPreprocessorLine(shortened_line);
    if (!result.empty() && result.back() != '\n' &&
        NeedsGLSLSpaceBetween(result.back(), minified_line.front())) {
      result.push_back(' ');
    }
    result += minified_line;
  }

  if (!result.empty() && result.back() != '\n') {
    result.push_back('\n');
  }
  return ShortenGLSLInternalIdentifiers(result);
}

}  // namespace compiler
}  // namespace impeller
