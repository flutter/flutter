// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// A JSON parser.  Converts strings of JSON into a Value object (see
// base/values.h).
// http://www.ietf.org/rfc/rfc4627.txt?number=4627
//
// Known limitations/deviations from the RFC:
// - Only knows how to parse ints within the range of a signed 32 bit int and
//   decimal numbers within a double.
// - Assumes input is encoded as UTF8.  The spec says we should allow UTF-16
//   (BE or LE) and UTF-32 (BE or LE) as well.
// - We limit nesting to 100 levels to prevent stack overflow (this is allowed
//   by the RFC).
// - A Unicode FAQ ("http://unicode.org/faq/utf_bom.html") writes a data
//   stream may start with a Unicode Byte-Order-Mark (U+FEFF), i.e. the input
//   UTF-8 string for the JSONReader::JsonToValue() function may start with a
//   UTF-8 BOM (0xEF, 0xBB, 0xBF).
//   To avoid the function from mis-treating a UTF-8 BOM as an invalid
//   character, the function skips a Unicode BOM at the beginning of the
//   Unicode string (converted from the input UTF-8 string) before parsing it.
//
// TODO(tc): Add a parsing option to to relax object keys being wrapped in
//   double quotes
// TODO(tc): Add an option to disable comment stripping

#ifndef BASE_JSON_JSON_READER_H_
#define BASE_JSON_JSON_READER_H_

#include <string>

#include "base/base_export.h"
#include "base/basictypes.h"
#include "base/memory/scoped_ptr.h"
#include "base/strings/string_piece.h"

namespace base {

class Value;

namespace internal {
class JSONParser;
}

enum JSONParserOptions {
  // Parses the input strictly according to RFC 4627, except for where noted
  // above.
  JSON_PARSE_RFC = 0,

  // Allows commas to exist after the last element in structures.
  JSON_ALLOW_TRAILING_COMMAS = 1 << 0,

  // The parser can perform optimizations by placing hidden data in the root of
  // the JSON object, which speeds up certain operations on children. However,
  // if the child is Remove()d from root, it would result in use-after-free
  // unless it is DeepCopy()ed or this option is used.
  JSON_DETACHABLE_CHILDREN = 1 << 1,
};

class BASE_EXPORT JSONReader {
 public:
  // Error codes during parsing.
  enum JsonParseError {
    JSON_NO_ERROR = 0,
    JSON_INVALID_ESCAPE,
    JSON_SYNTAX_ERROR,
    JSON_UNEXPECTED_TOKEN,
    JSON_TRAILING_COMMA,
    JSON_TOO_MUCH_NESTING,
    JSON_UNEXPECTED_DATA_AFTER_ROOT,
    JSON_UNSUPPORTED_ENCODING,
    JSON_UNQUOTED_DICTIONARY_KEY,
    JSON_PARSE_ERROR_COUNT
  };

  // String versions of parse error codes.
  static const char kInvalidEscape[];
  static const char kSyntaxError[];
  static const char kUnexpectedToken[];
  static const char kTrailingComma[];
  static const char kTooMuchNesting[];
  static const char kUnexpectedDataAfterRoot[];
  static const char kUnsupportedEncoding[];
  static const char kUnquotedDictionaryKey[];

  // Constructs a reader with the default options, JSON_PARSE_RFC.
  JSONReader();

  // Constructs a reader with custom options.
  explicit JSONReader(int options);

  ~JSONReader();

  // Reads and parses |json|, returning a Value. The caller owns the returned
  // instance. If |json| is not a properly formed JSON string, returns NULL.
  static scoped_ptr<Value> Read(const StringPiece& json);
  // TODO(estade): remove this bare pointer version.
  static Value* DeprecatedRead(const StringPiece& json);

  // Reads and parses |json|, returning a Value owned by the caller. The
  // parser respects the given |options|. If the input is not properly formed,
  // returns NULL.
  static scoped_ptr<Value> Read(const StringPiece& json, int options);
  // TODO(estade): remove this bare pointer version.
  static Value* DeprecatedRead(const StringPiece& json, int options);

  // Reads and parses |json| like Read(). |error_code_out| and |error_msg_out|
  // are optional. If specified and NULL is returned, they will be populated
  // an error code and a formatted error message (including error location if
  // appropriate). Otherwise, they will be unmodified.
  static scoped_ptr<Value> ReadAndReturnError(const StringPiece& json,
                                              int options,  // JSONParserOptions
                                              int* error_code_out,
                                              std::string* error_msg_out);
  // TODO(estade): remove this bare pointer version.
  static Value* DeprecatedReadAndReturnError(const StringPiece& json,
                                             int options,  // JSONParserOptions
                                             int* error_code_out,
                                             std::string* error_msg_out);

  // Converts a JSON parse error code into a human readable message.
  // Returns an empty string if error_code is JSON_NO_ERROR.
  static std::string ErrorCodeToString(JsonParseError error_code);

  // Parses an input string into a Value that is owned by the caller.
  scoped_ptr<Value> ReadToValue(const std::string& json);

  // Returns the error code if the last call to ReadToValue() failed.
  // Returns JSON_NO_ERROR otherwise.
  JsonParseError error_code() const;

  // Converts error_code_ to a human-readable string, including line and column
  // numbers if appropriate.
  std::string GetErrorMessage() const;

 private:
  scoped_ptr<internal::JSONParser> parser_;
};

}  // namespace base

#endif  // BASE_JSON_JSON_READER_H_
