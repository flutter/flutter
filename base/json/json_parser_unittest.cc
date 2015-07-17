// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/json/json_parser.h"

#include "base/json/json_reader.h"
#include "base/memory/scoped_ptr.h"
#include "base/values.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {
namespace internal {

class JSONParserTest : public testing::Test {
 public:
  JSONParser* NewTestParser(const std::string& input) {
    JSONParser* parser = new JSONParser(JSON_PARSE_RFC);
    parser->start_pos_ = input.data();
    parser->pos_ = parser->start_pos_;
    parser->end_pos_ = parser->start_pos_ + input.length();
    return parser;
  }

  void TestLastThree(JSONParser* parser) {
    EXPECT_EQ(',', *parser->NextChar());
    EXPECT_EQ('|', *parser->NextChar());
    EXPECT_EQ('\0', *parser->NextChar());
    EXPECT_EQ(parser->end_pos_, parser->pos_);
  }
};

TEST_F(JSONParserTest, NextChar) {
  std::string input("Hello world");
  scoped_ptr<JSONParser> parser(NewTestParser(input));

  EXPECT_EQ('H', *parser->pos_);
  for (size_t i = 1; i < input.length(); ++i) {
    EXPECT_EQ(input[i], *parser->NextChar());
  }
  EXPECT_EQ(parser->end_pos_, parser->NextChar());
}

TEST_F(JSONParserTest, ConsumeString) {
  std::string input("\"test\",|");
  scoped_ptr<JSONParser> parser(NewTestParser(input));
  scoped_ptr<Value> value(parser->ConsumeString());
  EXPECT_EQ('"', *parser->pos_);

  TestLastThree(parser.get());

  ASSERT_TRUE(value.get());
  std::string str;
  EXPECT_TRUE(value->GetAsString(&str));
  EXPECT_EQ("test", str);
}

TEST_F(JSONParserTest, ConsumeList) {
  std::string input("[true, false],|");
  scoped_ptr<JSONParser> parser(NewTestParser(input));
  scoped_ptr<Value> value(parser->ConsumeList());
  EXPECT_EQ(']', *parser->pos_);

  TestLastThree(parser.get());

  ASSERT_TRUE(value.get());
  base::ListValue* list;
  EXPECT_TRUE(value->GetAsList(&list));
  EXPECT_EQ(2u, list->GetSize());
}

TEST_F(JSONParserTest, ConsumeDictionary) {
  std::string input("{\"abc\":\"def\"},|");
  scoped_ptr<JSONParser> parser(NewTestParser(input));
  scoped_ptr<Value> value(parser->ConsumeDictionary());
  EXPECT_EQ('}', *parser->pos_);

  TestLastThree(parser.get());

  ASSERT_TRUE(value.get());
  base::DictionaryValue* dict;
  EXPECT_TRUE(value->GetAsDictionary(&dict));
  std::string str;
  EXPECT_TRUE(dict->GetString("abc", &str));
  EXPECT_EQ("def", str);
}

TEST_F(JSONParserTest, ConsumeLiterals) {
  // Literal |true|.
  std::string input("true,|");
  scoped_ptr<JSONParser> parser(NewTestParser(input));
  scoped_ptr<Value> value(parser->ConsumeLiteral());
  EXPECT_EQ('e', *parser->pos_);

  TestLastThree(parser.get());

  ASSERT_TRUE(value.get());
  bool bool_value = false;
  EXPECT_TRUE(value->GetAsBoolean(&bool_value));
  EXPECT_TRUE(bool_value);

  // Literal |false|.
  input = "false,|";
  parser.reset(NewTestParser(input));
  value.reset(parser->ConsumeLiteral());
  EXPECT_EQ('e', *parser->pos_);

  TestLastThree(parser.get());

  ASSERT_TRUE(value.get());
  EXPECT_TRUE(value->GetAsBoolean(&bool_value));
  EXPECT_FALSE(bool_value);

  // Literal |null|.
  input = "null,|";
  parser.reset(NewTestParser(input));
  value.reset(parser->ConsumeLiteral());
  EXPECT_EQ('l', *parser->pos_);

  TestLastThree(parser.get());

  ASSERT_TRUE(value.get());
  EXPECT_TRUE(value->IsType(Value::TYPE_NULL));
}

TEST_F(JSONParserTest, ConsumeNumbers) {
  // Integer.
  std::string input("1234,|");
  scoped_ptr<JSONParser> parser(NewTestParser(input));
  scoped_ptr<Value> value(parser->ConsumeNumber());
  EXPECT_EQ('4', *parser->pos_);

  TestLastThree(parser.get());

  ASSERT_TRUE(value.get());
  int number_i;
  EXPECT_TRUE(value->GetAsInteger(&number_i));
  EXPECT_EQ(1234, number_i);

  // Negative integer.
  input = "-1234,|";
  parser.reset(NewTestParser(input));
  value.reset(parser->ConsumeNumber());
  EXPECT_EQ('4', *parser->pos_);

  TestLastThree(parser.get());

  ASSERT_TRUE(value.get());
  EXPECT_TRUE(value->GetAsInteger(&number_i));
  EXPECT_EQ(-1234, number_i);

  // Double.
  input = "12.34,|";
  parser.reset(NewTestParser(input));
  value.reset(parser->ConsumeNumber());
  EXPECT_EQ('4', *parser->pos_);

  TestLastThree(parser.get());

  ASSERT_TRUE(value.get());
  double number_d;
  EXPECT_TRUE(value->GetAsDouble(&number_d));
  EXPECT_EQ(12.34, number_d);

  // Scientific.
  input = "42e3,|";
  parser.reset(NewTestParser(input));
  value.reset(parser->ConsumeNumber());
  EXPECT_EQ('3', *parser->pos_);

  TestLastThree(parser.get());

  ASSERT_TRUE(value.get());
  EXPECT_TRUE(value->GetAsDouble(&number_d));
  EXPECT_EQ(42000, number_d);

  // Negative scientific.
  input = "314159e-5,|";
  parser.reset(NewTestParser(input));
  value.reset(parser->ConsumeNumber());
  EXPECT_EQ('5', *parser->pos_);

  TestLastThree(parser.get());

  ASSERT_TRUE(value.get());
  EXPECT_TRUE(value->GetAsDouble(&number_d));
  EXPECT_EQ(3.14159, number_d);

  // Positive scientific.
  input = "0.42e+3,|";
  parser.reset(NewTestParser(input));
  value.reset(parser->ConsumeNumber());
  EXPECT_EQ('3', *parser->pos_);

  TestLastThree(parser.get());

  ASSERT_TRUE(value.get());
  EXPECT_TRUE(value->GetAsDouble(&number_d));
  EXPECT_EQ(420, number_d);
}

TEST_F(JSONParserTest, ErrorMessages) {
  // Error strings should not be modified in case of success.
  std::string error_message;
  int error_code = 0;
  scoped_ptr<Value> root;
  root.reset(JSONReader::DeprecatedReadAndReturnError(
      "[42]", JSON_PARSE_RFC, &error_code, &error_message));
  EXPECT_TRUE(error_message.empty());
  EXPECT_EQ(0, error_code);

  // Test line and column counting
  const char big_json[] = "[\n0,\n1,\n2,\n3,4,5,6 7,\n8,\n9\n]";
  // error here ----------------------------------^
  root.reset(JSONReader::DeprecatedReadAndReturnError(
      big_json, JSON_PARSE_RFC, &error_code, &error_message));
  EXPECT_FALSE(root.get());
  EXPECT_EQ(JSONParser::FormatErrorMessage(5, 10, JSONReader::kSyntaxError),
            error_message);
  EXPECT_EQ(JSONReader::JSON_SYNTAX_ERROR, error_code);

  error_code = 0;
  error_message = "";
  // Test line and column counting with "\r\n" line ending
  const char big_json_crlf[] =
      "[\r\n0,\r\n1,\r\n2,\r\n3,4,5,6 7,\r\n8,\r\n9\r\n]";
  // error here ----------------------^
  root.reset(JSONReader::DeprecatedReadAndReturnError(
      big_json_crlf, JSON_PARSE_RFC, &error_code, &error_message));
  EXPECT_FALSE(root.get());
  EXPECT_EQ(JSONParser::FormatErrorMessage(5, 10, JSONReader::kSyntaxError),
            error_message);
  EXPECT_EQ(JSONReader::JSON_SYNTAX_ERROR, error_code);

  // Test each of the error conditions
  root.reset(JSONReader::DeprecatedReadAndReturnError(
      "{},{}", JSON_PARSE_RFC, &error_code, &error_message));
  EXPECT_FALSE(root.get());
  EXPECT_EQ(JSONParser::FormatErrorMessage(1, 3,
      JSONReader::kUnexpectedDataAfterRoot), error_message);
  EXPECT_EQ(JSONReader::JSON_UNEXPECTED_DATA_AFTER_ROOT, error_code);

  std::string nested_json;
  for (int i = 0; i < 101; ++i) {
    nested_json.insert(nested_json.begin(), '[');
    nested_json.append(1, ']');
  }
  root.reset(JSONReader::DeprecatedReadAndReturnError(
      nested_json, JSON_PARSE_RFC, &error_code, &error_message));
  EXPECT_FALSE(root.get());
  EXPECT_EQ(JSONParser::FormatErrorMessage(1, 100, JSONReader::kTooMuchNesting),
            error_message);
  EXPECT_EQ(JSONReader::JSON_TOO_MUCH_NESTING, error_code);

  root.reset(JSONReader::DeprecatedReadAndReturnError(
      "[1,]", JSON_PARSE_RFC, &error_code, &error_message));
  EXPECT_FALSE(root.get());
  EXPECT_EQ(JSONParser::FormatErrorMessage(1, 4, JSONReader::kTrailingComma),
            error_message);
  EXPECT_EQ(JSONReader::JSON_TRAILING_COMMA, error_code);

  root.reset(JSONReader::DeprecatedReadAndReturnError(
      "{foo:\"bar\"}", JSON_PARSE_RFC, &error_code, &error_message));
  EXPECT_FALSE(root.get());
  EXPECT_EQ(JSONParser::FormatErrorMessage(1, 2,
      JSONReader::kUnquotedDictionaryKey), error_message);
  EXPECT_EQ(JSONReader::JSON_UNQUOTED_DICTIONARY_KEY, error_code);

  root.reset(JSONReader::DeprecatedReadAndReturnError(
      "{\"foo\":\"bar\",}", JSON_PARSE_RFC, &error_code, &error_message));
  EXPECT_FALSE(root.get());
  EXPECT_EQ(JSONParser::FormatErrorMessage(1, 14, JSONReader::kTrailingComma),
            error_message);

  root.reset(JSONReader::DeprecatedReadAndReturnError(
      "[nu]", JSON_PARSE_RFC, &error_code, &error_message));
  EXPECT_FALSE(root.get());
  EXPECT_EQ(JSONParser::FormatErrorMessage(1, 2, JSONReader::kSyntaxError),
            error_message);
  EXPECT_EQ(JSONReader::JSON_SYNTAX_ERROR, error_code);

  root.reset(JSONReader::DeprecatedReadAndReturnError(
      "[\"xxx\\xq\"]", JSON_PARSE_RFC, &error_code, &error_message));
  EXPECT_FALSE(root.get());
  EXPECT_EQ(JSONParser::FormatErrorMessage(1, 7, JSONReader::kInvalidEscape),
            error_message);
  EXPECT_EQ(JSONReader::JSON_INVALID_ESCAPE, error_code);

  root.reset(JSONReader::DeprecatedReadAndReturnError(
      "[\"xxx\\uq\"]", JSON_PARSE_RFC, &error_code, &error_message));
  EXPECT_FALSE(root.get());
  EXPECT_EQ(JSONParser::FormatErrorMessage(1, 7, JSONReader::kInvalidEscape),
            error_message);
  EXPECT_EQ(JSONReader::JSON_INVALID_ESCAPE, error_code);

  root.reset(JSONReader::DeprecatedReadAndReturnError(
      "[\"xxx\\q\"]", JSON_PARSE_RFC, &error_code, &error_message));
  EXPECT_FALSE(root.get());
  EXPECT_EQ(JSONParser::FormatErrorMessage(1, 7, JSONReader::kInvalidEscape),
            error_message);
  EXPECT_EQ(JSONReader::JSON_INVALID_ESCAPE, error_code);
}

TEST_F(JSONParserTest, Decode4ByteUtf8Char) {
  // This test strings contains a 4 byte unicode character (a smiley!) that the
  // reader should be able to handle (the character is \xf0\x9f\x98\x87).
  const char kUtf8Data[] =
      "[\"😇\",[],[],[],{\"google:suggesttype\":[]}]";
  std::string error_message;
  int error_code = 0;
  scoped_ptr<Value> root(JSONReader::DeprecatedReadAndReturnError(
      kUtf8Data, JSON_PARSE_RFC, &error_code, &error_message));
  EXPECT_TRUE(root.get()) << error_message;
}

TEST_F(JSONParserTest, DecodeUnicodeNonCharacter) {
  // Tests Unicode code points (encoded as escaped UTF-16) that are not valid
  // characters.
  EXPECT_FALSE(JSONReader::Read("[\"\\ufdd0\"]"));
  EXPECT_FALSE(JSONReader::Read("[\"\\ufffe\"]"));
  EXPECT_FALSE(JSONReader::Read("[\"\\ud83f\\udffe\"]"));
}

}  // namespace internal
}  // namespace base
