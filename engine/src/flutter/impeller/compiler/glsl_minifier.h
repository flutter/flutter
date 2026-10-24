// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_COMPILER_GLSL_MINIFIER_H_
#define FLUTTER_IMPELLER_COMPILER_GLSL_MINIFIER_H_

#include <cstddef>
#include <string>
#include <string_view>
#include <unordered_map>
#include <unordered_set>

namespace impeller {
namespace compiler {

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

/// @brief Shortens a verbose 32-bit float literal token emitted by SPIRV-Cross
///        (such as `0.300000011920928955078125`) to the shortest decimal
///        representation that round-trips to the exact same IEEE-754 binary32
///        float (`0.3`).
///
/// Tokens with 9 or fewer characters, integer tokens (no `.`, `e`, or `E`),
/// non-finite values, or values whose shortest float representation is not
/// shorter than `token` are returned unchanged. If `std::to_chars` produces an
/// integer-looking string (e.g. `"1"` for `1.0f`), `".0"` is appended so the
/// result remains a valid GLSL float literal.
std::string ShortenGLSLFloatLiteral(std::string_view token, float value);

/// @brief Scans a single line of GLSL for standalone floating-point literals
///        and replaces verbose literals with their shortened equivalents via
///        `ShortenGLSLFloatLiteral`.
std::string ShortenGLSLFloatLiteralsInLine(std::string_view line);

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

/// @brief Returns true if `token` is a synthesized SPIRV-Cross internal
///        identifier:
///        - Unnamed SPIR-V SSA/local temporaries (`_<digits>`, e.g. `_2461`).
///        - RelaxedPrecision copy temporaries (`mp_copy_*` or `hp_copy_*`).
///        - Dummy single-iteration loop counters (`spvDummy<digits>`).
bool IsSynthesizedGLSLIdentifier(std::string_view token);

/// @brief Generates the next short valid GLSL identifier starting from `cursor`
///        (`a`..`z`, `A`..`Z`, `aa`.., etc.) that is not present in `reserved`,
///        advancing `cursor` past the returned identifier.
std::string NextShortGLSLIdentifier(
    size_t& cursor,
    const std::unordered_set<std::string_view>& reserved);

/// @brief Builds a mapping from synthesized internal identifiers in `source`
///        (matched by `IsSynthesizedGLSLIdentifier`) to shorter replacement
///        identifiers.
///
/// Candidates are ordered by descending occurrence count so the most frequently
/// used temporaries receive 1-character names, and replacement names never
/// collide with GLSL keywords or existing identifiers in `source`.
std::unordered_map<std::string_view, std::string> BuildGLSLIdentifierRenameMap(
    std::string_view source);

/// @brief Shortens synthesized SPIRV-Cross internal identifiers in `source`
///        (`_<digits>`, `mp_copy_*`, `hp_copy_*`, `spvDummy<digits>`) using the
///        mapping produced by `BuildGLSLIdentifierRenameMap`.
///
/// External interface identifiers (uniforms, attributes, varyings, struct types
/// and members, preprocessor macros, and GLSL keywords/built-ins) are never
/// renamed.
std::string ShortenGLSLInternalIdentifiers(std::string_view source);

/// @brief Minifies SPIRV-Cross GLSL output by stripping comments, redundant
///        whitespace, and non-preprocessor newlines, shortening verbose 32-bit
///        float literals, and shrinking shader-internal identifiers.
///
/// Preprocessor directives (lines beginning with `#`, such as `#version`,
/// `#extension`, `#ifndef`, `#define`, and `#endif`) are preserved on their own
/// newline-delimited lines.
std::string MinifyGLSL(std::string_view source);

}  // namespace compiler
}  // namespace impeller

#endif  // FLUTTER_IMPELLER_COMPILER_GLSL_MINIFIER_H_
