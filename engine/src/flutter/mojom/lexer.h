// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_PUBLIC_TOOLS_BINDINGS_MOJOM_CPP_LEXER_H_
#define MOJO_PUBLIC_TOOLS_BINDINGS_MOJOM_CPP_LEXER_H_

#include <cstddef>
#include <string>
#include <vector>

#include "base/macros.h"

namespace mojo {
namespace mojom {

enum class TokenType {
  // Errors
  ERROR_UNKNOWN,
  ERROR_ILLEGAL_CHAR,
  ERROR_UNTERMINATED_STRING_LITERAL,

  // Punctuators and Separators
  LPAREN,
  RPAREN,
  LBRACKET,
  RBRACKET,
  LBRACE,
  RBRACE,
  LANGLE,
  RANGLE,
  SEMI,
  COMMA,
  DOT,
  MINUS,
  PLUS,
  AMP,
  QSTN,
  EQUALS,
  RESPONSE,

  // Identifiers
  IDENTIFIER,

  // Keywords
  IMPORT,
  MODULE,
  STRUCT,
  UNION,
  INTERFACE,
  ENUM,
  CONST,
  TRUE,
  FALSE,
  DEFAULT,

  // Constants
  INT_CONST_DEC,
  INT_CONST_HEX,
  FLOAT_CONST,
  ORDINAL,
  STRING_LITERAL,

  // TODO(azani): Check that all tokens were implemented.
  // TODO(azani): Error out on octal.
};

struct Token {
  Token();
  ~Token();

  bool error() const {
    return (token_type == TokenType::ERROR_ILLEGAL_CHAR ||
            token_type == TokenType::ERROR_UNTERMINATED_STRING_LITERAL ||
            token_type == TokenType::ERROR_UNKNOWN);
  }

  TokenType token_type;
  std::string token;
  size_t char_pos;
  size_t line_no;
  size_t line_pos;
};

// Accepts the text of a mojom file and returns the ordered list of tokens
// found in the file.
std::vector<Token> Tokenize(const std::string& source);

}  // namespace mojom
}  // namespace mojo

#endif  // MOJO_PUBLIC_TOOLS_BINDINGS_MOJOM_CPP_LEXER_H_
