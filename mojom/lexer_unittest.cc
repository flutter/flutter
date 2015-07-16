// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/logging.h"
#include "mojom/lexer.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {
namespace mojom {
namespace {

TEST(LexerTest, AllNonErrorTokens) {
  const struct TestData {
    const char* name;
    const char* source;
    mojom::TokenType expected_token;
  } test_data[] = {
      {"LPAREN", "(", mojom::TokenType::LPAREN},
      {"RPAREN", ")", mojom::TokenType::RPAREN},
      {"LBRACKET", "[", mojom::TokenType::LBRACKET},
      {"RBRACKET", "]", mojom::TokenType::RBRACKET},
      {"LBRACE", "{", mojom::TokenType::LBRACE},
      {"RBRACE", "}", mojom::TokenType::RBRACE},
      {"LANGLE", "<", mojom::TokenType::LANGLE},
      {"RANGLE", ">", mojom::TokenType::RANGLE},
      {"SEMI", ";", mojom::TokenType::SEMI},
      {"COMMA", ",", mojom::TokenType::COMMA},
      {"DOT", ".", mojom::TokenType::DOT},
      {"MINUS", "-", mojom::TokenType::MINUS},
      {"PLUS", "+", mojom::TokenType::PLUS},
      {"AMP", "&", mojom::TokenType::AMP},
      {"QSTN", "?", mojom::TokenType::QSTN},
      {"EQUALS", "=", mojom::TokenType::EQUALS},
      {"RESPONSE", "=>", mojom::TokenType::RESPONSE},
      {"IDENTIFIER", "something", mojom::TokenType::IDENTIFIER},
      {"IMPORT", "import", mojom::TokenType::IMPORT},
      {"MODULE", "module", mojom::TokenType::MODULE},
      {"STRUCT", "struct", mojom::TokenType::STRUCT},
      {"UNION", "union", mojom::TokenType::UNION},
      {"INTERFACE", "interface", mojom::TokenType::INTERFACE},
      {"ENUM", "enum", mojom::TokenType::ENUM},
      {"CONST", "const", mojom::TokenType::CONST},
      {"TRUE", "true", mojom::TokenType::TRUE},
      {"FALSE", "false", mojom::TokenType::FALSE},
      {"DEFAULT", "default", mojom::TokenType::DEFAULT},
      {"INT_CONST_DEC", "10", mojom::TokenType::INT_CONST_DEC},
      {"INT_CONST_DEC_0", "0", mojom::TokenType::INT_CONST_DEC},
      {"FLOAT_CONST", "10.5", mojom::TokenType::FLOAT_CONST},
      {"FLOAT_CONST_E", "10e5", mojom::TokenType::FLOAT_CONST},
      {"FLOAT_CONST_ZERO", "0.5", mojom::TokenType::FLOAT_CONST},
      {"FLOAT_CONST_E_ZERO", "0e5", mojom::TokenType::FLOAT_CONST},
      {"FLOAT_CONST_E_PLUS", "10e+5", mojom::TokenType::FLOAT_CONST},
      {"FLOAT_CONST_E_MINUS", "10e-5", mojom::TokenType::FLOAT_CONST},
      {"INT_CONST_HEX", "0x10A", mojom::TokenType::INT_CONST_HEX},
      {"ORDINAL", "@10", mojom::TokenType::ORDINAL},
      {"STRING_LITERAL", "\"hello world\"", mojom::TokenType::STRING_LITERAL},
      {"STRING_LITERAL_ESCAPE",
       "\"hello \\\"world\\\"\"",
       mojom::TokenType::STRING_LITERAL},
      {"STRING_LITERAL_HEX_ESCAPE",
       "\"hello \\x23 world\"",
       mojom::TokenType::STRING_LITERAL},
  };
  for (size_t i = 0; i < arraysize(test_data); i++) {
    const char* test_name = test_data[i].name;
    const char* source = test_data[i].source;
    const mojom::TokenType expected_token = test_data[i].expected_token;
    std::vector<mojom::Token> tokens = mojom::Tokenize(source);
    DCHECK(tokens.size() >= 1) << "Failure to tokenize at all: " << test_name;
    const mojom::Token token = tokens[0];
    EXPECT_EQ(expected_token, token.token_type)
        << "Wrong token type: " << test_name;
    EXPECT_EQ(source, token.token) << "Wrong token value: " << test_name;
  }
}

TEST(LexerTest, TokenPosition) {
  std::string source("  \n  .");
  std::vector<mojom::Token> tokens = mojom::Tokenize(source);
  const mojom::Token token = tokens[0];
  EXPECT_EQ(mojom::TokenType::DOT, token.token_type);
  EXPECT_EQ(".", token.token);
  EXPECT_EQ(5U, token.char_pos);
  EXPECT_EQ(1U, token.line_no);
  EXPECT_EQ(2U, token.line_pos);
}

TEST(LexerTest, ExhaustedTokens) {
  std::string source("");
  std::vector<mojom::Token> tokens = mojom::Tokenize(source);
  EXPECT_EQ(0U, tokens.size());
}

TEST(LexerTest, SkipSkippable) {
  std::string source("  \t  \r \n .");
  std::vector<mojom::Token> tokens = mojom::Tokenize(source);
  const mojom::Token token = tokens[0];
  EXPECT_EQ(mojom::TokenType::DOT, token.token_type);
  EXPECT_EQ(".", token.token);
}

TEST(LexerTest, SkipToTheEnd) {
  std::string source("  \t  \r \n ");
  std::vector<mojom::Token> tokens = mojom::Tokenize(source);
  EXPECT_EQ(0U, tokens.size());
}

TEST(LexerTest, TokenizeMoreThanOne) {
  std::string source("()");
  std::vector<mojom::Token> tokens = mojom::Tokenize(source);

  EXPECT_EQ(mojom::TokenType::LPAREN, tokens[0].token_type);
  EXPECT_EQ(mojom::TokenType::RPAREN, tokens[1].token_type);
  EXPECT_EQ(2U, tokens.size());
}

TEST(LexerTest, ERROR_ILLEGAL_CHAR) {
  std::string source("#");
  std::vector<mojom::Token> tokens = mojom::Tokenize(source);
  const mojom::Token token = tokens[0];
  EXPECT_EQ(mojom::TokenType::ERROR_ILLEGAL_CHAR, token.token_type);
  EXPECT_EQ("#", token.token);
  EXPECT_TRUE(token.error());
}

TEST(LexerTest, ERROR_UNTERMINATED_STRING_LITERAL_EOL) {
  std::string source("\"Hello \n World\"");
  std::vector<mojom::Token> tokens = mojom::Tokenize(source);
  const mojom::Token token = tokens[0];
  EXPECT_EQ(mojom::TokenType::ERROR_UNTERMINATED_STRING_LITERAL,
            token.token_type);
  EXPECT_EQ("\"Hello ", token.token);
  EXPECT_EQ(0U, token.char_pos);
  EXPECT_TRUE(token.error());
}

TEST(LexerTest, ERROR_UNTERMINATED_STRING_LITERAL_EOF) {
  std::string source("\"Hello ");
  std::vector<mojom::Token> tokens = mojom::Tokenize(source);
  const mojom::Token token = tokens[0];
  EXPECT_EQ(mojom::TokenType::ERROR_UNTERMINATED_STRING_LITERAL,
            token.token_type);
  EXPECT_EQ("\"Hello ", token.token);
  EXPECT_EQ(0U, token.char_pos);
  EXPECT_TRUE(token.error());
}

TEST(LexerTest, ERROR_UNTERMINATED_STRING_LITERAL_ESC_EOF) {
  std::string source("\"Hello \\");
  std::vector<mojom::Token> tokens = mojom::Tokenize(source);
  const mojom::Token token = tokens[0];
  EXPECT_EQ(mojom::TokenType::ERROR_UNTERMINATED_STRING_LITERAL,
            token.token_type);
  EXPECT_EQ("\"Hello \\", token.token);
  EXPECT_EQ(0U, token.char_pos);
  EXPECT_TRUE(token.error());
}

}  // namespace
}  // namespace mojom
}  // namespace mojo
