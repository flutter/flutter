// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/test/expectations/parser.h"

#include "base/strings/string_util.h"

namespace test_expectations {

Parser::Parser(Delegate* delegate, const std::string& input)
    : delegate_(delegate),
      input_(input),
      pos_(NULL),
      end_(NULL),
      line_number_(0),
      data_error_(false) {
}

Parser::~Parser() {
}

void Parser::Parse() {
  pos_ = &input_[0];
  end_ = pos_ + input_.length();

  line_number_ = 1;

  StateFuncPtr state = &Parser::Start;
  while (state) {
    state = (this->*state)();
  }
}

inline bool Parser::HasNext() {
  return pos_ < end_;
}

Parser::StateFunc Parser::Start() {
  // If at the start of a line is whitespace, skip it and arrange to come back
  // here.
  if (IsAsciiWhitespace(*pos_))
    return SkipWhitespaceAndNewLines(&Parser::Start);

  // Handle comments at the start of lines.
  if (*pos_ == '#')
    return &Parser::ParseComment;

  // After arranging to come back here from skipping whitespace and comments,
  // the parser may be at the end of the input.
  if (pos_ >= end_)
    return NULL;

  current_ = Expectation();
  data_error_ = false;

  return &Parser::ParseBugURL;
}

Parser::StateFunc Parser::ParseComment() {
  if (*pos_ != '#')
    return SyntaxError("Invalid start of comment");

  do {
    ++pos_;
  } while (HasNext() && *pos_ != '\n');

  return &Parser::Start;
}

Parser::StateFunc Parser::ParseBugURL() {
  return SkipWhitespace(ExtractString(
      &Parser::BeginModifiers));
}

Parser::StateFunc Parser::BeginModifiers() {
  if (*pos_ != '[' || !HasNext())
    return SyntaxError("Expected '[' for start of modifiers");

  ++pos_;
  return SkipWhitespace(&Parser::InModifiers);
}

Parser::StateFunc Parser::InModifiers() {
  if (*pos_ == ']')
    return &Parser::EndModifiers;

  return ExtractString(SkipWhitespace(
      &Parser::SaveModifier));
}

Parser::StateFunc Parser::SaveModifier() {
  if (extracted_string_.empty())
    return SyntaxError("Invalid modifier list");

  Configuration config;
  if (ConfigurationFromString(extracted_string_, &config)) {
    if (current_.configuration != CONFIGURATION_UNSPECIFIED)
      DataError("Cannot use more than one configuration modifier");
    else
      current_.configuration = config;
  } else {
    Platform platform;
    if (PlatformFromString(extracted_string_, &platform))
      current_.platforms.push_back(platform);
    else
      DataError("Invalid modifier string");
  }

  return SkipWhitespace(&Parser::InModifiers);
}

Parser::StateFunc Parser::EndModifiers() {
 if (*pos_ != ']' || !HasNext())
    return SyntaxError("Expected ']' for end of modifiers list");

  ++pos_;
  return SkipWhitespace(&Parser::ParseTestName);
}

Parser::StateFunc Parser::ParseTestName() {
  return ExtractString(&Parser::SaveTestName);
}

Parser::StateFunc Parser::SaveTestName() {
  if (extracted_string_.empty())
    return SyntaxError("Invalid test name");

  current_.test_name = extracted_string_.as_string();
  return SkipWhitespace(&Parser::ParseExpectation);
}

Parser::StateFunc Parser::ParseExpectation() {
  if (*pos_ != '=' || !HasNext())
    return SyntaxError("Expected '=' for expectation result");

  ++pos_;
  return SkipWhitespace(&Parser::ParseExpectationType);
}

Parser::StateFunc Parser::ParseExpectationType() {
  return ExtractString(&Parser::SaveExpectationType);
}

Parser::StateFunc Parser::SaveExpectationType() {
  if (!ResultFromString(extracted_string_, &current_.result))
    DataError("Unknown expectation type");

  return SkipWhitespace(&Parser::End);
}

Parser::StateFunc Parser::End() {
  if (!data_error_)
    delegate_->EmitExpectation(current_);

  if (HasNext())
    return SkipWhitespaceAndNewLines(&Parser::Start);

  return NULL;
}

Parser::StateFunc Parser::ExtractString(StateFunc success) {
  const char* start = pos_;
  while (!IsAsciiWhitespace(*pos_) && *pos_ != ']' && HasNext()) {
    ++pos_;
    if (*pos_ == '#') {
      return SyntaxError("Unexpected start of comment");
    }
  }
  extracted_string_ = base::StringPiece(start, pos_ - start);
  return success;
}

Parser::StateFunc Parser::SkipWhitespace(Parser::StateFunc next) {
  while ((*pos_ == ' ' || *pos_ == '\t') && HasNext()) {
    ++pos_;
  }
  return next;
}

Parser::StateFunc Parser::SkipWhitespaceAndNewLines(Parser::StateFunc next) {
  while (IsAsciiWhitespace(*pos_) && HasNext()) {
    if (*pos_ == '\n') {
      ++line_number_;
    }
    ++pos_;
  }
  return next;
}

Parser::StateFunc Parser::SyntaxError(const std::string& message) {
  delegate_->OnSyntaxError(message);
  return NULL;
}

void Parser::DataError(const std::string& error) {
  data_error_ = true;
  delegate_->OnDataError(error);
}

}  // namespace test_expectations
