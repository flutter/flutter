// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/tools/licenses_cpp/src/deps_parser.h"

#include <re2/re2.h>

#include <string>
#include <string_view>
#include <vector>

#include "flutter/third_party/re2/re2/re2.h"

DepsParser::DepsParser() = default;

DepsParser::~DepsParser() = default;

// TODO(gaaclarke): Convert this to flex/bison, this is getting a bit
// complicated. It technically doesn't handle commas in trailing comments.
std::vector<std::string> DepsParser::Parse(std::string_view input) {
  std::vector<std::string> result;
  re2::StringPiece mutable_input(input);

  // 1. Find the start of the deps block
  if (!re2::RE2::FindAndConsume(&mutable_input, R"((?:^|\n)deps\s*=\s*\{)")) {
    return result;
  }

  // 2. Find the matching closing brace for the entire deps block
  size_t brace_close_pos = std::string_view::npos;
  int brace_count = 1;
  for (size_t i = 0; i < mutable_input.length(); ++i) {
    if (mutable_input[i] == '{') {
      brace_count++;
    } else if (mutable_input[i] == '}') {
      brace_count--;
      if (brace_count == 0) {
        brace_close_pos = i;
        break;
      }
    }
  }

  if (brace_close_pos == std::string_view::npos) {
    return result;
  }

  // 3. Extract the content of the deps block
  std::string_view deps_content = mutable_input.substr(0, brace_close_pos);

  // 4. Filter out comments and build a new string
  std::string cleaned_content;
  size_t current_pos_clean = 0;
  while (current_pos_clean < deps_content.length()) {
    size_t next_newline = deps_content.find('\n', current_pos_clean);
    if (next_newline == std::string_view::npos) {
      next_newline = deps_content.length();
    }

    std::string_view line = deps_content.substr(
        current_pos_clean, next_newline - current_pos_clean);

    size_t first_char = line.find_first_not_of(" \t");
    if (first_char != std::string_view::npos) {
      line = line.substr(first_char);
    } else {
      line = "";
    }

    if (line.empty() || line[0] != '#') {
      cleaned_content.append(line);
      cleaned_content.append("\n");
    }

    current_pos_clean = next_newline + 1;
  }

  // 5. Parse the cleaned content
  size_t current_pos = 0;
  while (current_pos < cleaned_content.length()) {
    // Find the start of the key
    size_t key_start = cleaned_content.find('\'', current_pos);
    if (key_start == std::string_view::npos) {
      break;
    }
    key_start++;

    // Find the end of the key
    size_t key_end = cleaned_content.find('\'', key_start);
    if (key_end == std::string_view::npos) {
      break;
    }

    std::string_view key =
        std::string_view(&cleaned_content[key_start], key_end - key_start);

    // Find the colon after the key
    size_t colon_pos = cleaned_content.find(':', key_end);
    if (colon_pos == std::string_view::npos) {
      break;
    }

    // Find the start of the value
    size_t value_start =
        cleaned_content.find_first_not_of(" \t\n", colon_pos + 1);
    if (value_start == std::string_view::npos) {
      break;
    }

    // Find the end of the value
    size_t value_end = std::string_view::npos;
    int brace_level = 0;
    int bracket_level = 0;
    for (size_t i = value_start; i < cleaned_content.length(); ++i) {
      char c = cleaned_content[i];
      if (c == '{') {
        brace_level++;
      } else if (c == '}') {
        brace_level--;
      } else if (c == '[') {
        bracket_level++;
      } else if (c == ']') {
        bracket_level--;
      } else if (c == ',' && brace_level == 0 && bracket_level == 0) {
        value_end = i;
        break;
      }
    }

    if (value_end == std::string_view::npos) {
      value_end = cleaned_content.length();
    }

    std::string_view value = std::string_view(&cleaned_content[value_start],
                                              value_end - value_start);

    // Check for 'dep_type': 'cipd'
    if (value.find("'dep_type': 'cipd'") != std::string_view::npos) {
      result.emplace_back(key);
    }

    current_pos = value_end + 1;
  }

  return result;
}
