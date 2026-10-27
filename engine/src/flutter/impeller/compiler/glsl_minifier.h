// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_COMPILER_GLSL_MINIFIER_H_
#define FLUTTER_IMPELLER_COMPILER_GLSL_MINIFIER_H_

#include <string>
#include <string_view>

#include "spirv_glsl.hpp"

namespace impeller {
namespace compiler {

/// @brief A `spirv_cross::CompilerGLSL` subclass that uses SPIRV-Cross's code
///        generation hooks to emit compact GLSL.
///
/// Registers a custom `spirv_cross::FloatFormatter` backed by `std::to_chars`
/// so floating-point literals are emitted in their shortest round-tripping
/// decimal representation instead of SPIRV-Cross's default `"%.32g"` format.
class MinifyingCompilerGLSL final : public spirv_cross::CompilerGLSL {
 public:
  explicit MinifyingCompilerGLSL(const spirv_cross::ParsedIR& ir);

  ~MinifyingCompilerGLSL() override = default;

  /// @brief Formats `value` using `std::to_chars` as the shortest decimal
  ///        representation that round-trips to the exact same `float`,
  ///        appending `".0"` if needed so GLSL lexes it as a float literal.
  static std::string FormatFloat(float value);

  /// @brief Formats `value` using `std::to_chars` as the shortest decimal
  ///        representation that round-trips to the exact same `double`,
  ///        appending `".0"` if needed so GLSL lexes it as a float literal.
  static std::string FormatDouble(double value);

 private:
  class ShortFloatFormatter final : public spirv_cross::FloatFormatter {
   public:
    // |spirv_cross::FloatFormatter|
    std::string format_float(float value) override;

    // |spirv_cross::FloatFormatter|
    std::string format_double(double value) override;
  };

  ShortFloatFormatter float_formatter_;
};

/// @brief Strips C-style single-line (`//...`) and multi-line (`/*...*/`)
///        comments from GLSL shader source text.
///
/// Newlines following single-line comments are preserved so preprocessor
/// directives on subsequent lines remain line-delimited.
std::string StripGLSLComments(std::string_view source);

/// @brief Returns true if `c` can start a GLSL identifier (`[a-zA-Z_]`).
bool IsGLSLIdentStartChar(char c);

/// @brief Returns true if `c` can appear in a GLSL identifier (`[a-zA-Z0-9_]`).
bool IsGLSLIdentChar(char c);

/// @brief Returns true if `c` can appear in a GLSL identifier or numeric
///        literal (`[a-zA-Z0-9_.]`).
bool IsGLSLIdentOrNumChar(char c);

/// @brief Returns true if removing horizontal whitespace between `prev` and
///        `next` would merge two distinct GLSL tokens into one.
///
/// Specifically, a separating space must be preserved between:
/// - Two adjacent identifier/numeric characters (e.g. `highp float`).
/// - Two adjacent `+` characters (`+ +`), which would otherwise lex as `++`.
/// - Two adjacent `-` characters (`- -`), which would otherwise lex as `--`.
bool NeedsGLSLSpaceBetween(char prev, char next);

/// @brief Trims leading and trailing spaces (`' '`), tabs (`'\t'`), and
///        carriage returns (`'\r'`) from `line`.
std::string_view TrimGLSLLineWhitespace(std::string_view line);

/// @brief Collapses contiguous runs of horizontal whitespace (`' '` and
///        `'\t'`) in `line` into a single space `' '`.
std::string CollapseGLSLHorizontalWhitespace(std::string_view line);

/// @brief Minifies a single non-preprocessor line of GLSL by trimming outer
///        whitespace, collapsing internal horizontal whitespace, and removing
///        spaces that are not required by `NeedsGLSLSpaceBetween`.
std::string MinifyGLSLNonPreprocessorLine(std::string_view line);

/// @brief Minifies GLSL shader source text by stripping comments, redundant
///        whitespace, and unnecessary newlines.
///
/// Preprocessor directives (`#version`, `#extension`, `#ifndef`, `#define`,
/// `#endif`, etc.) are preserved on their own newline-delimited lines, while
/// non-preprocessor statements are joined onto a single line.
std::string MinifyGLSL(std::string_view source);

}  // namespace compiler
}  // namespace impeller

#endif  // FLUTTER_IMPELLER_COMPILER_GLSL_MINIFIER_H_
