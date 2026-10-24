// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/compiler/glsl_minifier.h"

#include <cctype>
#include <charconv>
#include <cmath>
#include <sstream>
#include <string>
#include <string_view>
#include <system_error>

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

bool IsGLSLIdentOrNumChar(char c) {
  return std::isalnum(static_cast<unsigned char>(c)) || c == '_' || c == '.';
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
    // embedded in identifiers (such as `vec4` or `_123`) are ignored.
    const bool at_token_start = (i == 0 || !IsGLSLIdentOrNumChar(line[i - 1]));
    if (at_token_start && std::isdigit(static_cast<unsigned char>(line[i]))) {
      float value = 0.0f;
      const char* first = line.data() + i;
      const char* last = line.data() + line.size();
      const auto [ptr, ec] = std::from_chars(first, last, value);
      // Accept the parsed token only if `std::from_chars` succeeded and the
      // match ends at a token boundary (not followed by an identifier/dot
      // character such as `123abc` or `1.0.2`).
      if (ec == std::errc{} && (ptr == last || !IsGLSLIdentOrNumChar(*ptr))) {
        const std::string_view token(first, static_cast<size_t>(ptr - first));
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

    // Non-preprocessor lines can be joined onto a single line as long as a
    // separating space is inserted when adjacent boundary tokens would merge.
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
  return result;
}

}  // namespace compiler
}  // namespace impeller
