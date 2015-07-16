// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_JSON_JSON_PARSER_H_
#define BASE_JSON_JSON_PARSER_H_

#include <string>

#include "base/base_export.h"
#include "base/basictypes.h"
#include "base/compiler_specific.h"
#include "base/json/json_reader.h"
#include "base/strings/string_piece.h"

#if !defined(OS_CHROMEOS)
#include "base/gtest_prod_util.h"
#endif

namespace base {
class Value;
}

#if defined(OS_CHROMEOS)
// Chromium and Chromium OS check out gtest to different places, so this is
// unable to compile on both if gtest_prod.h is included here. Instead, include
// its only contents -- this will need to be updated if the macro ever changes.
#define FRIEND_TEST(test_case_name, test_name)\
friend class test_case_name##_##test_name##_Test

#define FRIEND_TEST_ALL_PREFIXES(test_case_name, test_name) \
  FRIEND_TEST(test_case_name, test_name); \
  FRIEND_TEST(test_case_name, DISABLED_##test_name); \
  FRIEND_TEST(test_case_name, FLAKY_##test_name)
#endif  // OS_CHROMEOS

namespace base {
namespace internal {

class JSONParserTest;

// The implementation behind the JSONReader interface. This class is not meant
// to be used directly; it encapsulates logic that need not be exposed publicly.
//
// This parser guarantees O(n) time through the input string. It also optimizes
// base::StringValue by using StringPiece where possible when returning Value
// objects by using "hidden roots," discussed in the implementation.
//
// Iteration happens on the byte level, with the functions CanConsume and
// NextChar. The conversion from byte to JSON token happens without advancing
// the parser in GetNextToken/ParseToken, that is tokenization operates on
// the current parser position without advancing.
//
// Built on top of these are a family of Consume functions that iterate
// internally. Invariant: on entry of a Consume function, the parser is wound
// to the first byte of a valid JSON token. On exit, it is on the last byte
// of a token, such that the next iteration of the parser will be at the byte
// immediately following the token, which would likely be the first byte of the
// next token.
class BASE_EXPORT_PRIVATE JSONParser {
 public:
  explicit JSONParser(int options);
  ~JSONParser();

  // Parses the input string according to the set options and returns the
  // result as a Value owned by the caller.
  Value* Parse(const StringPiece& input);

  // Returns the error code.
  JSONReader::JsonParseError error_code() const;

  // Returns the human-friendly error message.
  std::string GetErrorMessage() const;

 private:
  enum Token {
    T_OBJECT_BEGIN,           // {
    T_OBJECT_END,             // }
    T_ARRAY_BEGIN,            // [
    T_ARRAY_END,              // ]
    T_STRING,
    T_NUMBER,
    T_BOOL_TRUE,              // true
    T_BOOL_FALSE,             // false
    T_NULL,                   // null
    T_LIST_SEPARATOR,         // ,
    T_OBJECT_PAIR_SEPARATOR,  // :
    T_END_OF_INPUT,
    T_INVALID_TOKEN,
  };

  // A helper class used for parsing strings. One optimization performed is to
  // create base::Value with a StringPiece to avoid unnecessary std::string
  // copies. This is not possible if the input string needs to be decoded from
  // UTF-16 to UTF-8, or if an escape sequence causes characters to be skipped.
  // This class centralizes that logic.
  class StringBuilder {
   public:
    // Empty constructor. Used for creating a builder with which to Swap().
    StringBuilder();

    // |pos| is the beginning of an input string, excluding the |"|.
    explicit StringBuilder(const char* pos);

    ~StringBuilder();

    // Swaps the contents of |other| with this.
    void Swap(StringBuilder* other);

    // Either increases the |length_| of the string or copies the character if
    // the StringBuilder has been converted. |c| must be in the basic ASCII
    // plane; all other characters need to be in UTF-8 units, appended with
    // AppendString below.
    void Append(const char& c);

    // Appends a string to the std::string. Must be Convert()ed to use.
    void AppendString(const std::string& str);

    // Converts the builder from its default StringPiece to a full std::string,
    // performing a copy. Once a builder is converted, it cannot be made a
    // StringPiece again.
    void Convert();

    // Returns whether the builder can be converted to a StringPiece.
    bool CanBeStringPiece() const;

    // Returns the StringPiece representation. Returns an empty piece if it
    // cannot be converted.
    StringPiece AsStringPiece();

    // Returns the builder as a std::string.
    const std::string& AsString();

   private:
    // The beginning of the input string.
    const char* pos_;

    // Number of bytes in |pos_| that make up the string being built.
    size_t length_;

    // The copied string representation. NULL until Convert() is called.
    // Strong. scoped_ptr<T> has too much of an overhead here.
    std::string* string_;
  };

  // Quick check that the stream has capacity to consume |length| more bytes.
  bool CanConsume(int length);

  // The basic way to consume a single character in the stream. Consumes one
  // byte of the input stream and returns a pointer to the rest of it.
  const char* NextChar();

  // Performs the equivalent of NextChar N times.
  void NextNChars(int n);

  // Skips over whitespace and comments to find the next token in the stream.
  // This does not advance the parser for non-whitespace or comment chars.
  Token GetNextToken();

  // Consumes whitespace characters and comments until the next non-that is
  // encountered.
  void EatWhitespaceAndComments();
  // Helper function that consumes a comment, assuming that the parser is
  // currently wound to a '/'.
  bool EatComment();

  // Calls GetNextToken() and then ParseToken(). Caller owns the result.
  Value* ParseNextToken();

  // Takes a token that represents the start of a Value ("a structural token"
  // in RFC terms) and consumes it, returning the result as an object the
  // caller owns.
  Value* ParseToken(Token token);

  // Assuming that the parser is currently wound to '{', this parses a JSON
  // object into a DictionaryValue.
  Value* ConsumeDictionary();

  // Assuming that the parser is wound to '[', this parses a JSON list into a
  // ListValue.
  Value* ConsumeList();

  // Calls through ConsumeStringRaw and wraps it in a value.
  Value* ConsumeString();

  // Assuming that the parser is wound to a double quote, this parses a string,
  // decoding any escape sequences and converts UTF-16 to UTF-8. Returns true on
  // success and Swap()s the result into |out|. Returns false on failure with
  // error information set.
  bool ConsumeStringRaw(StringBuilder* out);
  // Helper function for ConsumeStringRaw() that consumes the next four or 10
  // bytes (parser is wound to the first character of a HEX sequence, with the
  // potential for consuming another \uXXXX for a surrogate). Returns true on
  // success and places the UTF8 code units in |dest_string|, and false on
  // failure.
  bool DecodeUTF16(std::string* dest_string);
  // Helper function for ConsumeStringRaw() that takes a single code point,
  // decodes it into UTF-8 units, and appends it to the given builder. The
  // point must be valid.
  void DecodeUTF8(const int32& point, StringBuilder* dest);

  // Assuming that the parser is wound to the start of a valid JSON number,
  // this parses and converts it to either an int or double value.
  Value* ConsumeNumber();
  // Helper that reads characters that are ints. Returns true if a number was
  // read and false on error.
  bool ReadInt(bool allow_leading_zeros);

  // Consumes the literal values of |true|, |false|, and |null|, assuming the
  // parser is wound to the first character of any of those.
  Value* ConsumeLiteral();

  // Compares two string buffers of a given length.
  static bool StringsAreEqual(const char* left, const char* right, size_t len);

  // Sets the error information to |code| at the current column, based on
  // |index_| and |index_last_line_|, with an optional positive/negative
  // adjustment by |column_adjust|.
  void ReportError(JSONReader::JsonParseError code, int column_adjust);

  // Given the line and column number of an error, formats one of the error
  // message contants from json_reader.h for human display.
  static std::string FormatErrorMessage(int line, int column,
                                        const std::string& description);

  // base::JSONParserOptions that control parsing.
  int options_;

  // Pointer to the start of the input data.
  const char* start_pos_;

  // Pointer to the current position in the input data. Equivalent to
  // |start_pos_ + index_|.
  const char* pos_;

  // Pointer to the last character of the input data.
  const char* end_pos_;

  // The index in the input stream to which the parser is wound.
  int index_;

  // The number of times the parser has recursed (current stack depth).
  int stack_depth_;

  // The line number that the parser is at currently.
  int line_number_;

  // The last value of |index_| on the previous line.
  int index_last_line_;

  // Error information.
  JSONReader::JsonParseError error_code_;
  int error_line_;
  int error_column_;

  friend class JSONParserTest;
  FRIEND_TEST_ALL_PREFIXES(JSONParserTest, NextChar);
  FRIEND_TEST_ALL_PREFIXES(JSONParserTest, ConsumeDictionary);
  FRIEND_TEST_ALL_PREFIXES(JSONParserTest, ConsumeList);
  FRIEND_TEST_ALL_PREFIXES(JSONParserTest, ConsumeString);
  FRIEND_TEST_ALL_PREFIXES(JSONParserTest, ConsumeLiterals);
  FRIEND_TEST_ALL_PREFIXES(JSONParserTest, ConsumeNumbers);
  FRIEND_TEST_ALL_PREFIXES(JSONParserTest, ErrorMessages);

  DISALLOW_COPY_AND_ASSIGN(JSONParser);
};

}  // namespace internal
}  // namespace base

#endif  // BASE_JSON_JSON_PARSER_H_
