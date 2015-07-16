// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/json/json_reader.h"

#include "base/json/json_parser.h"
#include "base/logging.h"
#include "base/values.h"

namespace base {

// Values 1000 and above are used by JSONFileValueSerializer::JsonFileError.
COMPILE_ASSERT(JSONReader::JSON_PARSE_ERROR_COUNT < 1000,
               json_reader_error_out_of_bounds);

const char JSONReader::kInvalidEscape[] =
    "Invalid escape sequence.";
const char JSONReader::kSyntaxError[] =
    "Syntax error.";
const char JSONReader::kUnexpectedToken[] =
    "Unexpected token.";
const char JSONReader::kTrailingComma[] =
    "Trailing comma not allowed.";
const char JSONReader::kTooMuchNesting[] =
    "Too much nesting.";
const char JSONReader::kUnexpectedDataAfterRoot[] =
    "Unexpected data after root element.";
const char JSONReader::kUnsupportedEncoding[] =
    "Unsupported encoding. JSON must be UTF-8.";
const char JSONReader::kUnquotedDictionaryKey[] =
    "Dictionary keys must be quoted.";

JSONReader::JSONReader()
    : JSONReader(JSON_PARSE_RFC) {
}

JSONReader::JSONReader(int options)
    : parser_(new internal::JSONParser(options)) {
}

JSONReader::~JSONReader() {
}

// static
Value* JSONReader::DeprecatedRead(const StringPiece& json) {
  return Read(json).release();
}

// static
scoped_ptr<Value> JSONReader::Read(const StringPiece& json) {
  internal::JSONParser parser(JSON_PARSE_RFC);
  return make_scoped_ptr(parser.Parse(json));
}

// static
Value* JSONReader::DeprecatedRead(const StringPiece& json, int options) {
  return Read(json, options).release();
}

// static
scoped_ptr<Value> JSONReader::Read(const StringPiece& json, int options) {
  internal::JSONParser parser(options);
  return make_scoped_ptr(parser.Parse(json));
}

// static
Value* JSONReader::DeprecatedReadAndReturnError(const StringPiece& json,
                                                int options,
                                                int* error_code_out,
                                                std::string* error_msg_out) {
  return ReadAndReturnError(json, options, error_code_out, error_msg_out)
      .release();
}

// static
scoped_ptr<Value> JSONReader::ReadAndReturnError(const StringPiece& json,
                                                 int options,
                                                 int* error_code_out,
                                                 std::string* error_msg_out) {
  internal::JSONParser parser(options);
  scoped_ptr<Value> root(parser.Parse(json));
  if (!root) {
    if (error_code_out)
      *error_code_out = parser.error_code();
    if (error_msg_out)
      *error_msg_out = parser.GetErrorMessage();
  }

  return root;
}

// static
std::string JSONReader::ErrorCodeToString(JsonParseError error_code) {
  switch (error_code) {
    case JSON_NO_ERROR:
      return std::string();
    case JSON_INVALID_ESCAPE:
      return kInvalidEscape;
    case JSON_SYNTAX_ERROR:
      return kSyntaxError;
    case JSON_UNEXPECTED_TOKEN:
      return kUnexpectedToken;
    case JSON_TRAILING_COMMA:
      return kTrailingComma;
    case JSON_TOO_MUCH_NESTING:
      return kTooMuchNesting;
    case JSON_UNEXPECTED_DATA_AFTER_ROOT:
      return kUnexpectedDataAfterRoot;
    case JSON_UNSUPPORTED_ENCODING:
      return kUnsupportedEncoding;
    case JSON_UNQUOTED_DICTIONARY_KEY:
      return kUnquotedDictionaryKey;
    default:
      NOTREACHED();
      return std::string();
  }
}

scoped_ptr<Value> JSONReader::ReadToValue(const std::string& json) {
  return make_scoped_ptr(parser_->Parse(json));
}

JSONReader::JsonParseError JSONReader::error_code() const {
  return parser_->error_code();
}

std::string JSONReader::GetErrorMessage() const {
  return parser_->GetErrorMessage();
}

}  // namespace base
