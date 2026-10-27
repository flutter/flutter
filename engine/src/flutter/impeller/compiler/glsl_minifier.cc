// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/compiler/glsl_minifier.h"

#include <charconv>
#include <cmath>
#include <sstream>
#include <string>
#include <string_view>
#include <system_error>

#include "flutter/third_party/re2/re2/re2.h"

namespace impeller {
namespace compiler {

namespace {

template <typename T>
std::string FormatFloatingPoint(T value) {
  if (!std::isfinite(value)) {
    return "0.0";
  }
  // `std::to_chars` with no format/precision argument emits the shortest
  // decimal representation that round-trips to the exact same IEEE-754 float.
  char buf[32];
  const auto [end_ptr, ec] = std::to_chars(buf, buf + sizeof(buf), value);
  if (ec != std::errc{}) {
    return "0.0";
  }
  std::string result(buf, end_ptr);
  // Ensure the formatted token contains a decimal point or exponent so GLSL
  // continues to lex it as a floating-point literal rather than an integer.
  if (result.find_first_of(".eE") == std::string_view::npos) {
    result += ".0";
  }
  return result;
}

}  // namespace

MinifyingCompilerGLSL::MinifyingCompilerGLSL(const spirv_cross::ParsedIR& ir)
    : spirv_cross::CompilerGLSL(ir) {
  set_float_formatter(&float_formatter_);
}

std::string MinifyingCompilerGLSL::FormatFloat(float value) {
  return FormatFloatingPoint(value);
}

std::string MinifyingCompilerGLSL::FormatDouble(double value) {
  return FormatFloatingPoint(value);
}

std::string MinifyingCompilerGLSL::ShortFloatFormatter::format_float(
    float value) {
  return FormatFloat(value);
}

std::string MinifyingCompilerGLSL::ShortFloatFormatter::format_double(
    double value) {
  return FormatDouble(value);
}

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

    // Preprocessor directives (`#version`, `#extension`, `#ifndef`, `#define`,
    // `#endif`, etc.) must remain on their own newline-delimited lines.
    if (raw_line.front() == '#') {
      if (!result.empty() && result.back() != '\n') {
        result.push_back('\n');
      }
      result += CollapseGLSLHorizontalWhitespace(raw_line);
      result.push_back('\n');
      continue;
    }

    // Non-preprocessor lines are joined onto a single line to save ~12 KiB of
    // newline bytes across the embedded GLES/GLES3 shader blobs, inserting a
    // separating space only when adjacent boundary tokens would otherwise
    // merge.
    const std::string minified_line = MinifyGLSLNonPreprocessorLine(raw_line);
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
