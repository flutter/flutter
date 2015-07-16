// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojom/lexer.h"

#include <map>
#include <string>

#include "base/lazy_instance.h"

namespace mojo {
namespace mojom {

namespace {

class KeywordsDict {
 public:
  KeywordsDict();

 private:
  std::map<std::string, mojom::TokenType> keywords_;
  friend std::map<std::string, mojom::TokenType>& Keywords();

  DISALLOW_COPY_AND_ASSIGN(KeywordsDict);
};
static base::LazyInstance<KeywordsDict> g_keywords = LAZY_INSTANCE_INITIALIZER;

std::map<std::string, mojom::TokenType>& Keywords() {
  return g_keywords.Get().keywords_;
}

KeywordsDict::KeywordsDict() {
  keywords_["import"] = TokenType::IMPORT;
  keywords_["module"] = TokenType::MODULE;
  keywords_["struct"] = TokenType::STRUCT;
  keywords_["union"] = TokenType::UNION;
  keywords_["interface"] = TokenType::INTERFACE;
  keywords_["enum"] = TokenType::ENUM;
  keywords_["const"] = TokenType::CONST;
  keywords_["true"] = TokenType::TRUE;
  keywords_["false"] = TokenType::FALSE;
  keywords_["default"] = TokenType::DEFAULT;
}

// Non-localized versions of isalpha.
bool IsAlpha(char c) {
  return (('a' <= c && c <= 'z') || ('A' <= c && c <= 'Z'));
}

// Non-localized versions of isnum.
bool IsDigit(char c) {
  return ('0' <= c && c <= '9');
}

bool IsHexDigit(char c) {
  return (IsDigit(c) || ('a' <= c && c <= 'f') || ('A' <= c && c <= 'F'));
}

// Non-localized versions of isalnum.
bool IsAlnum(char c) {
  return IsAlpha(c) || IsDigit(c);
}

// MojomLexer tokenizes a mojom source file. It is NOT thread-safe.
class MojomLexer {
 public:
  explicit MojomLexer(const std::string& source);
  ~MojomLexer();

  // Returns the list of tokens in the source file.
  std::vector<Token> Tokenize();

 private:
  // The GetNextToken.* functions all return true if they could find a token
  // (even an error token) and false otherwise.
  bool GetNextToken(Token* result);
  bool GetNextTokenSingleChar(Token* result);
  bool GetNextTokenEqualsOrResponse(Token* result);
  bool GetNextTokenIdentifier(Token* result);
  bool GetNextTokenDecConst(Token* result);
  bool GetNextTokenHexConst(Token* result);
  bool GetNextTokenOrdinal(Token* result);
  bool GetNextTokenStringLiteral(Token* result);

  void ConsumeSkippable();
  void ConsumeDigits();
  void ConsumeEol();
  void Consume(size_t num);

  bool eos(size_t offset_plus) {
    return offset_ + offset_plus >= source_.size();
  }

  const std::string source_;
  size_t offset_;
  size_t line_no_;
  size_t offset_in_line_;

  DISALLOW_COPY_AND_ASSIGN(MojomLexer);
};

std::vector<Token> MojomLexer::Tokenize() {
  offset_ = 0;
  line_no_ = 0;
  offset_in_line_ = 0;

  std::vector<Token> result;
  Token cur;
  while (GetNextToken(&cur)) {
    result.push_back(cur);

    // As soon as an error token is found, stop tokenizing.
    if (cur.error()) {
      break;
    }
  }

  return result;
}

bool MojomLexer::GetNextToken(Token* result) {
  // Skip all spaces which may be in front of the next token.
  ConsumeSkippable();

  // If we found the end of the source signal that is so.
  if (eos(0))
    return false;

  // Save the current position in the source code.
  result->char_pos = offset_;
  result->line_no = line_no_;
  result->line_pos = offset_in_line_;

  if (GetNextTokenSingleChar(result) || GetNextTokenEqualsOrResponse(result) ||
      GetNextTokenIdentifier(result) || GetNextTokenHexConst(result) ||
      GetNextTokenDecConst(result) || GetNextTokenDecConst(result) ||
      GetNextTokenOrdinal(result) || GetNextTokenStringLiteral(result))
    return true;

  result->token = source_.substr(offset_, 1);
  result->token_type = TokenType::ERROR_ILLEGAL_CHAR;
  return true;
}

void MojomLexer::ConsumeSkippable() {
  if (eos(0))
    return;

  bool found_non_space = false;
  while (!found_non_space && !eos(0)) {
    switch (source_[offset_]) {
      case ' ':
      case '\t':
      case '\r':
        Consume(1);
        break;
      case '\n':
        ConsumeEol();
        break;
      default:
        found_non_space = true;
        break;
    }
  }
}

// Finds all single-character tokens except for '='.
bool MojomLexer::GetNextTokenSingleChar(Token* result) {
  switch (source_[offset_]) {
    case '(':
      result->token_type = TokenType::LPAREN;
      break;
    case ')':
      result->token_type = TokenType::RPAREN;
      break;
    case '[':
      result->token_type = TokenType::LBRACKET;
      break;
    case ']':
      result->token_type = TokenType::RBRACKET;
      break;
    case '{':
      result->token_type = TokenType::LBRACE;
      break;
    case '}':
      result->token_type = TokenType::RBRACE;
      break;
    case '<':
      result->token_type = TokenType::LANGLE;
      break;
    case '>':
      result->token_type = TokenType::RANGLE;
      break;
    case ';':
      result->token_type = TokenType::SEMI;
      break;
    case ',':
      result->token_type = TokenType::COMMA;
      break;
    case '.':
      result->token_type = TokenType::DOT;
      break;
    case '-':
      result->token_type = TokenType::MINUS;
      break;
    case '+':
      result->token_type = TokenType::PLUS;
      break;
    case '&':
      result->token_type = TokenType::AMP;
      break;
    case '?':
      result->token_type = TokenType::QSTN;
      break;
    default:
      return false;
      break;
  }

  result->token = source_.substr(offset_, 1);
  Consume(1);
  return true;
}

// Finds '=' or '=>'.
bool MojomLexer::GetNextTokenEqualsOrResponse(Token* result) {
  if (source_[offset_] != '=')
    return false;
  Consume(1);

  if (eos(0) || source_[offset_] != '>') {
    result->token_type = TokenType::EQUALS;
    result->token = "=";
  } else {
    result->token_type = TokenType::RESPONSE;
    result->token = "=>";
    Consume(1);
  }
  return true;
}

// valid C identifiers (K&R2: A.2.3)
bool MojomLexer::GetNextTokenIdentifier(Token* result) {
  char c = source_[offset_];

  // Identifiers start with a letter or underscore.
  if (!(IsAlpha(c) || c == '_'))
    return false;
  size_t start_offset = offset_;

  // Identifiers contain letters numbers and underscores.
  while (!eos(0) && (IsAlnum(source_[offset_]) || c == '_'))
    Consume(1);

  result->token = source_.substr(start_offset, offset_ - start_offset);
  result->token_type = TokenType::IDENTIFIER;

  if (Keywords().count(result->token))
    result->token_type = Keywords()[result->token];

  return true;
}

// integer constants (K&R2: A.2.5.1) dec
// floating constants (K&R2: A.2.5.3)
bool MojomLexer::GetNextTokenDecConst(Token* result) {
  if (!IsDigit(source_[offset_]))
    return false;

  result->token_type = TokenType::INT_CONST_DEC;
  // If the number starts with a zero and is not a floating point number.
  if (source_[offset_] == '0' &&
      (eos(1) || (source_[offset_] == 'e' && source_[offset_] == 'E' &&
                  source_[offset_] == '.'))) {
    // TODO(azani): Catch and error on octal.
    result->token = "0";
    Consume(1);
    return true;
  }

  size_t start_offset = offset_;

  // First, we consume all the digits.
  ConsumeDigits();

  // If there is a fractional part, we consume the . and the following digits.
  if (!eos(0) && source_[offset_] == '.') {
    result->token_type = TokenType::FLOAT_CONST;
    Consume(1);
    ConsumeDigits();
  }

  // If there is an exponential part, we consume the e and the following digits.
  if (!eos(0) && (source_[offset_] == 'e' || source_[offset_] == 'E')) {
    if (!eos(2) && (source_[offset_ + 1] == '-' || source_[offset_ + 1]) &&
        IsDigit(source_[offset_ + 2])) {
      result->token_type = TokenType::FLOAT_CONST;
      Consume(2);  // Consume e/E and +/-
      ConsumeDigits();
    } else if (!eos(1) && IsDigit(source_[offset_ + 1])) {
      result->token_type = TokenType::FLOAT_CONST;
      Consume(1);  // Consume e/E
      ConsumeDigits();
    }
  }

  result->token = source_.substr(start_offset, offset_ - start_offset);
  return true;
}

// integer constants (K&R2: A.2.5.1) hex
bool MojomLexer::GetNextTokenHexConst(Token* result) {
  // Hex numbers start with a 0, x and then some hex numeral.
  if (eos(2) || source_[offset_] != '0' ||
      (source_[offset_ + 1] != 'x' && source_[offset_ + 1] != 'X') ||
      !IsHexDigit(source_[offset_ + 2]))
    return false;

  result->token_type = TokenType::INT_CONST_HEX;
  size_t start_offset = offset_;
  Consume(2);

  while (IsHexDigit(source_[offset_]))
    Consume(1);

  result->token = source_.substr(start_offset, offset_ - start_offset);
  return true;
}

bool MojomLexer::GetNextTokenOrdinal(Token* result) {
  // Ordinals start with '@' and then some digit.
  if (eos(1) || source_[offset_] != '@' || !IsDigit(source_[offset_ + 1]))
    return false;
  size_t start_offset = offset_;
  // Consumes '@'.
  Consume(1);

  result->token_type = TokenType::ORDINAL;
  ConsumeDigits();

  result->token = source_.substr(start_offset, offset_ - start_offset);
  return true;
}

bool MojomLexer::GetNextTokenStringLiteral(Token* result) {
  // Ordinals start with '@' and then some digit.
  if (source_[offset_] != '"')
    return false;

  size_t start_offset = offset_;
  // Consumes '"'.
  Consume(1);

  while (source_[offset_] != '"') {
    if (source_[offset_] == '\n' || eos(0)) {
      result->token_type = TokenType::ERROR_UNTERMINATED_STRING_LITERAL;
      result->token = source_.substr(start_offset, offset_ - start_offset);
      return true;
    }

    // This block will be skipped if the backslash is at the end of the source.
    if (source_[offset_] == '\\' && !eos(1)) {
      // Consume the backslash. This will ensure \" is consumed.
      Consume(1);
    }
    Consume(1);
  }
  // Consume the closing doublequotes.
  Consume(1);

  result->token_type = TokenType::STRING_LITERAL;

  result->token = source_.substr(start_offset, offset_ - start_offset);
  return true;
}

void MojomLexer::ConsumeDigits() {
  while (!eos(0) && IsDigit(source_[offset_]))
    Consume(1);
}

void MojomLexer::ConsumeEol() {
  ++offset_;
  ++line_no_;
  offset_in_line_ = 0;
}

void MojomLexer::Consume(size_t num) {
  offset_ += num;
  offset_in_line_ += num;
}

MojomLexer::MojomLexer(const std::string& source)
    : source_(source), offset_(0), line_no_(0), offset_in_line_(0) {
}

MojomLexer::~MojomLexer() {
}

}  // namespace

Token::Token()
    : token_type(TokenType::ERROR_UNKNOWN),
      char_pos(0),
      line_no(0),
      line_pos(0) {
}

Token::~Token() {
}

// Accepts the text of a mojom file and returns the ordered list of tokens
// found in the file.
std::vector<Token> Tokenize(const std::string& source) {
  return MojomLexer(source).Tokenize();
}

}  // namespace mojom
}  // namespace mojo
