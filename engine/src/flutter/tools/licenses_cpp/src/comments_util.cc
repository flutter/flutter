// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/tools/licenses_cpp/src/comments_util.h"
#include "flutter/third_party/re2/re2/re2.h"

static RE2 kAddTrimLineRegex(R"regex(^(?:\s*(?://|#)\s?))regex");
static RE2 kAddCTrimLineRegex(
    R"regex(^(?:\s*\**\s)?(.*?)(?:\s*\**\s*)?$)regex");
static RE2 kAddCEndTrimLineRegex(R"regex(^\s*(.*?)\*/)regex");

void CommentsUtil::AddTrimLine(std::string* buffer,
                               const char* text,
                               size_t length) {
  std::string chopped(text, length);
  RE2::Replace(&chopped, kAddTrimLineRegex, "");
  buffer->append(chopped);
}

void CommentsUtil::AddCTrimLine(std::string* buffer,
                                const char* text,
                                size_t length) {
  re2::StringPiece captured_content;
  RE2::PartialMatch(re2::StringPiece(text), kAddCTrimLineRegex,
                    &captured_content);
  buffer->append(captured_content);
  buffer->push_back('\n');
}

void CommentsUtil::AddCEndTrimLine(std::string* buffer,
                                   const char* text,
                                   size_t length) {
  re2::StringPiece captured_content;
  RE2::PartialMatch(re2::StringPiece(text), kAddCEndTrimLineRegex,
                    &captured_content);
  buffer->append(captured_content);
}
