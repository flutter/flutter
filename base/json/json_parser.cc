// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/json/json_parser.h"

#include <cmath>

#include "base/logging.h"
#include "base/memory/scoped_ptr.h"
#include "base/strings/string_number_conversions.h"
#include "base/strings/string_piece.h"
#include "base/strings/string_util.h"
#include "base/strings/stringprintf.h"
#include "base/strings/utf_string_conversion_utils.h"
#include "base/strings/utf_string_conversions.h"
#include "base/third_party/icu/icu_utf.h"
#include "base/values.h"

namespace base {
namespace internal {

namespace {

const int kStackMaxDepth = 100;

const int32 kExtendedASCIIStart = 0x80;

// This and the class below are used to own the JSON input string for when
// string tokens are stored as StringPiece instead of std::string. This
// optimization avoids about 2/3rds of string memory copies. The constructor
// takes ownership of the input string. The real root value is Swap()ed into
// the new instance.
class DictionaryHiddenRootValue : public DictionaryValue {
 public:
  DictionaryHiddenRootValue(std::string* json, Value* root) : json_(json) {
    DCHECK(root->IsType(Value::TYPE_DICTIONARY));
    DictionaryValue::Swap(static_cast<DictionaryValue*>(root));
  }

  void Swap(DictionaryValue* other) override {
    DVLOG(1) << "Swap()ing a DictionaryValue inefficiently.";

    // First deep copy to convert JSONStringValue to std::string and swap that
    // copy with |other|, which contains the new contents of |this|.
    scoped_ptr<DictionaryValue> copy(DeepCopy());
    copy->Swap(other);

    // Then erase the contents of the current dictionary and swap in the
    // new contents, originally from |other|.
    Clear();
    json_.reset();
    DictionaryValue::Swap(copy.get());
  }

  // Not overriding DictionaryValue::Remove because it just calls through to
  // the method below.

  bool RemoveWithoutPathExpansion(const std::string& key,
                                  scoped_ptr<Value>* out) override {
    // If the caller won't take ownership of the removed value, just call up.
    if (!out)
      return DictionaryValue::RemoveWithoutPathExpansion(key, out);

    DVLOG(1) << "Remove()ing from a DictionaryValue inefficiently.";

    // Otherwise, remove the value while its still "owned" by this and copy it
    // to convert any JSONStringValues to std::string.
    scoped_ptr<Value> out_owned;
    if (!DictionaryValue::RemoveWithoutPathExpansion(key, &out_owned))
      return false;

    out->reset(out_owned->DeepCopy());

    return true;
  }

 private:
  scoped_ptr<std::string> json_;

  DISALLOW_COPY_AND_ASSIGN(DictionaryHiddenRootValue);
};

class ListHiddenRootValue : public ListValue {
 public:
  ListHiddenRootValue(std::string* json, Value* root) : json_(json) {
    DCHECK(root->IsType(Value::TYPE_LIST));
    ListValue::Swap(static_cast<ListValue*>(root));
  }

  void Swap(ListValue* other) override {
    DVLOG(1) << "Swap()ing a ListValue inefficiently.";

    // First deep copy to convert JSONStringValue to std::string and swap that
    // copy with |other|, which contains the new contents of |this|.
    scoped_ptr<ListValue> copy(DeepCopy());
    copy->Swap(other);

    // Then erase the contents of the current list and swap in the new contents,
    // originally from |other|.
    Clear();
    json_.reset();
    ListValue::Swap(copy.get());
  }

  bool Remove(size_t index, scoped_ptr<Value>* out) override {
    // If the caller won't take ownership of the removed value, just call up.
    if (!out)
      return ListValue::Remove(index, out);

    DVLOG(1) << "Remove()ing from a ListValue inefficiently.";

    // Otherwise, remove the value while its still "owned" by this and copy it
    // to convert any JSONStringValues to std::string.
    scoped_ptr<Value> out_owned;
    if (!ListValue::Remove(index, &out_owned))
      return false;

    out->reset(out_owned->DeepCopy());

    return true;
  }

 private:
  scoped_ptr<std::string> json_;

  DISALLOW_COPY_AND_ASSIGN(ListHiddenRootValue);
};

// A variant on StringValue that uses StringPiece instead of copying the string
// into the Value. This can only be stored in a child of hidden root (above),
// otherwise the referenced string will not be guaranteed to outlive it.
class JSONStringValue : public Value {
 public:
  explicit JSONStringValue(const StringPiece& piece)
      : Value(TYPE_STRING),
        string_piece_(piece) {
  }

  // Overridden from Value:
  bool GetAsString(std::string* out_value) const override {
    string_piece_.CopyToString(out_value);
    return true;
  }
  bool GetAsString(string16* out_value) const override {
    *out_value = UTF8ToUTF16(string_piece_);
    return true;
  }
  Value* DeepCopy() const override {
    return new StringValue(string_piece_.as_string());
  }
  bool Equals(const Value* other) const override {
    std::string other_string;
    return other->IsType(TYPE_STRING) && other->GetAsString(&other_string) &&
        StringPiece(other_string) == string_piece_;
  }

 private:
  // The location in the original input stream.
  StringPiece string_piece_;

  DISALLOW_COPY_AND_ASSIGN(JSONStringValue);
};

// Simple class that checks for maximum recursion/"stack overflow."
class StackMarker {
 public:
  explicit StackMarker(int* depth) : depth_(depth) {
    ++(*depth_);
    DCHECK_LE(*depth_, kStackMaxDepth);
  }
  ~StackMarker() {
    --(*depth_);
  }

  bool IsTooDeep() const {
    return *depth_ >= kStackMaxDepth;
  }

 private:
  int* const depth_;

  DISALLOW_COPY_AND_ASSIGN(StackMarker);
};

}  // namespace

JSONParser::JSONParser(int options)
    : options_(options),
      start_pos_(NULL),
      pos_(NULL),
      end_pos_(NULL),
      index_(0),
      stack_depth_(0),
      line_number_(0),
      index_last_line_(0),
      error_code_(JSONReader::JSON_NO_ERROR),
      error_line_(0),
      error_column_(0) {
}

JSONParser::~JSONParser() {
}

Value* JSONParser::Parse(const StringPiece& input) {
  scoped_ptr<std::string> input_copy;
  // If the children of a JSON root can be detached, then hidden roots cannot
  // be used, so do not bother copying the input because StringPiece will not
  // be used anywhere.
  if (!(options_ & JSON_DETACHABLE_CHILDREN)) {
    input_copy.reset(new std::string(input.as_string()));
    start_pos_ = input_copy->data();
  } else {
    start_pos_ = input.data();
  }
  pos_ = start_pos_;
  end_pos_ = start_pos_ + input.length();
  index_ = 0;
  line_number_ = 1;
  index_last_line_ = 0;

  error_code_ = JSONReader::JSON_NO_ERROR;
  error_line_ = 0;
  error_column_ = 0;

  // When the input JSON string starts with a UTF-8 Byte-Order-Mark
  // <0xEF 0xBB 0xBF>, advance the start position to avoid the
  // ParseNextToken function mis-treating a Unicode BOM as an invalid
  // character and returning NULL.
  if (CanConsume(3) && static_cast<uint8>(*pos_) == 0xEF &&
      static_cast<uint8>(*(pos_ + 1)) == 0xBB &&
      static_cast<uint8>(*(pos_ + 2)) == 0xBF) {
    NextNChars(3);
  }

  // Parse the first and any nested tokens.
  scoped_ptr<Value> root(ParseNextToken());
  if (!root.get())
    return NULL;

  // Make sure the input stream is at an end.
  if (GetNextToken() != T_END_OF_INPUT) {
    if (!CanConsume(1) || (NextChar() && GetNextToken() != T_END_OF_INPUT)) {
      ReportError(JSONReader::JSON_UNEXPECTED_DATA_AFTER_ROOT, 1);
      return NULL;
    }
  }

  // Dictionaries and lists can contain JSONStringValues, so wrap them in a
  // hidden root.
  if (!(options_ & JSON_DETACHABLE_CHILDREN)) {
    if (root->IsType(Value::TYPE_DICTIONARY)) {
      return new DictionaryHiddenRootValue(input_copy.release(), root.get());
    } else if (root->IsType(Value::TYPE_LIST)) {
      return new ListHiddenRootValue(input_copy.release(), root.get());
    } else if (root->IsType(Value::TYPE_STRING)) {
      // A string type could be a JSONStringValue, but because there's no
      // corresponding HiddenRootValue, the memory will be lost. Deep copy to
      // preserve it.
      return root->DeepCopy();
    }
  }

  // All other values can be returned directly.
  return root.release();
}

JSONReader::JsonParseError JSONParser::error_code() const {
  return error_code_;
}

std::string JSONParser::GetErrorMessage() const {
  return FormatErrorMessage(error_line_, error_column_,
      JSONReader::ErrorCodeToString(error_code_));
}

// StringBuilder ///////////////////////////////////////////////////////////////

JSONParser::StringBuilder::StringBuilder()
    : pos_(NULL),
      length_(0),
      string_(NULL) {
}

JSONParser::StringBuilder::StringBuilder(const char* pos)
    : pos_(pos),
      length_(0),
      string_(NULL) {
}

void JSONParser::StringBuilder::Swap(StringBuilder* other) {
  std::swap(other->string_, string_);
  std::swap(other->pos_, pos_);
  std::swap(other->length_, length_);
}

JSONParser::StringBuilder::~StringBuilder() {
  delete string_;
}

void JSONParser::StringBuilder::Append(const char& c) {
  DCHECK_GE(c, 0);
  DCHECK_LT(c, 128);

  if (string_)
    string_->push_back(c);
  else
    ++length_;
}

void JSONParser::StringBuilder::AppendString(const std::string& str) {
  DCHECK(string_);
  string_->append(str);
}

void JSONParser::StringBuilder::Convert() {
  if (string_)
    return;
  string_  = new std::string(pos_, length_);
}

bool JSONParser::StringBuilder::CanBeStringPiece() const {
  return !string_;
}

StringPiece JSONParser::StringBuilder::AsStringPiece() {
  if (string_)
    return StringPiece();
  return StringPiece(pos_, length_);
}

const std::string& JSONParser::StringBuilder::AsString() {
  if (!string_)
    Convert();
  return *string_;
}

// JSONParser private //////////////////////////////////////////////////////////

inline bool JSONParser::CanConsume(int length) {
  return pos_ + length <= end_pos_;
}

const char* JSONParser::NextChar() {
  DCHECK(CanConsume(1));
  ++index_;
  ++pos_;
  return pos_;
}

void JSONParser::NextNChars(int n) {
  DCHECK(CanConsume(n));
  index_ += n;
  pos_ += n;
}

JSONParser::Token JSONParser::GetNextToken() {
  EatWhitespaceAndComments();
  if (!CanConsume(1))
    return T_END_OF_INPUT;

  switch (*pos_) {
    case '{':
      return T_OBJECT_BEGIN;
    case '}':
      return T_OBJECT_END;
    case '[':
      return T_ARRAY_BEGIN;
    case ']':
      return T_ARRAY_END;
    case '"':
      return T_STRING;
    case '0':
    case '1':
    case '2':
    case '3':
    case '4':
    case '5':
    case '6':
    case '7':
    case '8':
    case '9':
    case '-':
      return T_NUMBER;
    case 't':
      return T_BOOL_TRUE;
    case 'f':
      return T_BOOL_FALSE;
    case 'n':
      return T_NULL;
    case ',':
      return T_LIST_SEPARATOR;
    case ':':
      return T_OBJECT_PAIR_SEPARATOR;
    default:
      return T_INVALID_TOKEN;
  }
}

void JSONParser::EatWhitespaceAndComments() {
  while (pos_ < end_pos_) {
    switch (*pos_) {
      case '\r':
      case '\n':
        index_last_line_ = index_;
        // Don't increment line_number_ twice for "\r\n".
        if (!(*pos_ == '\n' && pos_ > start_pos_ && *(pos_ - 1) == '\r'))
          ++line_number_;
        // Fall through.
      case ' ':
      case '\t':
        NextChar();
        break;
      case '/':
        if (!EatComment())
          return;
        break;
      default:
        return;
    }
  }
}

bool JSONParser::EatComment() {
  if (*pos_ != '/' || !CanConsume(1))
    return false;

  char next_char = *NextChar();
  if (next_char == '/') {
    // Single line comment, read to newline.
    while (CanConsume(1)) {
      next_char = *NextChar();
      if (next_char == '\n' || next_char == '\r')
        return true;
    }
  } else if (next_char == '*') {
    char previous_char = '\0';
    // Block comment, read until end marker.
    while (CanConsume(1)) {
      next_char = *NextChar();
      if (previous_char == '*' && next_char == '/') {
        // EatWhitespaceAndComments will inspect pos_, which will still be on
        // the last / of the comment, so advance once more (which may also be
        // end of input).
        NextChar();
        return true;
      }
      previous_char = next_char;
    }

    // If the comment is unterminated, GetNextToken will report T_END_OF_INPUT.
  }

  return false;
}

Value* JSONParser::ParseNextToken() {
  return ParseToken(GetNextToken());
}

Value* JSONParser::ParseToken(Token token) {
  switch (token) {
    case T_OBJECT_BEGIN:
      return ConsumeDictionary();
    case T_ARRAY_BEGIN:
      return ConsumeList();
    case T_STRING:
      return ConsumeString();
    case T_NUMBER:
      return ConsumeNumber();
    case T_BOOL_TRUE:
    case T_BOOL_FALSE:
    case T_NULL:
      return ConsumeLiteral();
    default:
      ReportError(JSONReader::JSON_UNEXPECTED_TOKEN, 1);
      return NULL;
  }
}

Value* JSONParser::ConsumeDictionary() {
  if (*pos_ != '{') {
    ReportError(JSONReader::JSON_UNEXPECTED_TOKEN, 1);
    return NULL;
  }

  StackMarker depth_check(&stack_depth_);
  if (depth_check.IsTooDeep()) {
    ReportError(JSONReader::JSON_TOO_MUCH_NESTING, 1);
    return NULL;
  }

  scoped_ptr<DictionaryValue> dict(new DictionaryValue);

  NextChar();
  Token token = GetNextToken();
  while (token != T_OBJECT_END) {
    if (token != T_STRING) {
      ReportError(JSONReader::JSON_UNQUOTED_DICTIONARY_KEY, 1);
      return NULL;
    }

    // First consume the key.
    StringBuilder key;
    if (!ConsumeStringRaw(&key)) {
      return NULL;
    }

    // Read the separator.
    NextChar();
    token = GetNextToken();
    if (token != T_OBJECT_PAIR_SEPARATOR) {
      ReportError(JSONReader::JSON_SYNTAX_ERROR, 1);
      return NULL;
    }

    // The next token is the value. Ownership transfers to |dict|.
    NextChar();
    Value* value = ParseNextToken();
    if (!value) {
      // ReportError from deeper level.
      return NULL;
    }

    dict->SetWithoutPathExpansion(key.AsString(), value);

    NextChar();
    token = GetNextToken();
    if (token == T_LIST_SEPARATOR) {
      NextChar();
      token = GetNextToken();
      if (token == T_OBJECT_END && !(options_ & JSON_ALLOW_TRAILING_COMMAS)) {
        ReportError(JSONReader::JSON_TRAILING_COMMA, 1);
        return NULL;
      }
    } else if (token != T_OBJECT_END) {
      ReportError(JSONReader::JSON_SYNTAX_ERROR, 0);
      return NULL;
    }
  }

  return dict.release();
}

Value* JSONParser::ConsumeList() {
  if (*pos_ != '[') {
    ReportError(JSONReader::JSON_UNEXPECTED_TOKEN, 1);
    return NULL;
  }

  StackMarker depth_check(&stack_depth_);
  if (depth_check.IsTooDeep()) {
    ReportError(JSONReader::JSON_TOO_MUCH_NESTING, 1);
    return NULL;
  }

  scoped_ptr<ListValue> list(new ListValue);

  NextChar();
  Token token = GetNextToken();
  while (token != T_ARRAY_END) {
    Value* item = ParseToken(token);
    if (!item) {
      // ReportError from deeper level.
      return NULL;
    }

    list->Append(item);

    NextChar();
    token = GetNextToken();
    if (token == T_LIST_SEPARATOR) {
      NextChar();
      token = GetNextToken();
      if (token == T_ARRAY_END && !(options_ & JSON_ALLOW_TRAILING_COMMAS)) {
        ReportError(JSONReader::JSON_TRAILING_COMMA, 1);
        return NULL;
      }
    } else if (token != T_ARRAY_END) {
      ReportError(JSONReader::JSON_SYNTAX_ERROR, 1);
      return NULL;
    }
  }

  return list.release();
}

Value* JSONParser::ConsumeString() {
  StringBuilder string;
  if (!ConsumeStringRaw(&string))
    return NULL;

  // Create the Value representation, using a hidden root, if configured
  // to do so, and if the string can be represented by StringPiece.
  if (string.CanBeStringPiece() && !(options_ & JSON_DETACHABLE_CHILDREN)) {
    return new JSONStringValue(string.AsStringPiece());
  } else {
    if (string.CanBeStringPiece())
      string.Convert();
    return new StringValue(string.AsString());
  }
}

bool JSONParser::ConsumeStringRaw(StringBuilder* out) {
  if (*pos_ != '"') {
    ReportError(JSONReader::JSON_UNEXPECTED_TOKEN, 1);
    return false;
  }

  // StringBuilder will internally build a StringPiece unless a UTF-16
  // conversion occurs, at which point it will perform a copy into a
  // std::string.
  StringBuilder string(NextChar());

  int length = end_pos_ - start_pos_;
  int32 next_char = 0;

  while (CanConsume(1)) {
    pos_ = start_pos_ + index_;  // CBU8_NEXT is postcrement.
    CBU8_NEXT(start_pos_, index_, length, next_char);
    if (next_char < 0 || !IsValidCharacter(next_char)) {
      ReportError(JSONReader::JSON_UNSUPPORTED_ENCODING, 1);
      return false;
    }

    // If this character is an escape sequence...
    if (next_char == '\\') {
      // The input string will be adjusted (either by combining the two
      // characters of an encoded escape sequence, or with a UTF conversion),
      // so using StringPiece isn't possible -- force a conversion.
      string.Convert();

      if (!CanConsume(1)) {
        ReportError(JSONReader::JSON_INVALID_ESCAPE, 0);
        return false;
      }

      switch (*NextChar()) {
        // Allowed esape sequences:
        case 'x': {  // UTF-8 sequence.
          // UTF-8 \x escape sequences are not allowed in the spec, but they
          // are supported here for backwards-compatiblity with the old parser.
          if (!CanConsume(2)) {
            ReportError(JSONReader::JSON_INVALID_ESCAPE, 1);
            return false;
          }

          int hex_digit = 0;
          if (!HexStringToInt(StringPiece(NextChar(), 2), &hex_digit)) {
            ReportError(JSONReader::JSON_INVALID_ESCAPE, -1);
            return false;
          }
          NextChar();

          if (hex_digit < kExtendedASCIIStart)
            string.Append(static_cast<char>(hex_digit));
          else
            DecodeUTF8(hex_digit, &string);
          break;
        }
        case 'u': {  // UTF-16 sequence.
          // UTF units are of the form \uXXXX.
          if (!CanConsume(5)) {  // 5 being 'u' and four HEX digits.
            ReportError(JSONReader::JSON_INVALID_ESCAPE, 0);
            return false;
          }

          // Skip the 'u'.
          NextChar();

          std::string utf8_units;
          if (!DecodeUTF16(&utf8_units)) {
            ReportError(JSONReader::JSON_INVALID_ESCAPE, -1);
            return false;
          }

          string.AppendString(utf8_units);
          break;
        }
        case '"':
          string.Append('"');
          break;
        case '\\':
          string.Append('\\');
          break;
        case '/':
          string.Append('/');
          break;
        case 'b':
          string.Append('\b');
          break;
        case 'f':
          string.Append('\f');
          break;
        case 'n':
          string.Append('\n');
          break;
        case 'r':
          string.Append('\r');
          break;
        case 't':
          string.Append('\t');
          break;
        case 'v':  // Not listed as valid escape sequence in the RFC.
          string.Append('\v');
          break;
        // All other escape squences are illegal.
        default:
          ReportError(JSONReader::JSON_INVALID_ESCAPE, 0);
          return false;
      }
    } else if (next_char == '"') {
      --index_;  // Rewind by one because of CBU8_NEXT.
      out->Swap(&string);
      return true;
    } else {
      if (next_char < kExtendedASCIIStart)
        string.Append(static_cast<char>(next_char));
      else
        DecodeUTF8(next_char, &string);
    }
  }

  ReportError(JSONReader::JSON_SYNTAX_ERROR, 0);
  return false;
}

// Entry is at the first X in \uXXXX.
bool JSONParser::DecodeUTF16(std::string* dest_string) {
  if (!CanConsume(4))
    return false;

  // This is a 32-bit field because the shift operations in the
  // conversion process below cause MSVC to error about "data loss."
  // This only stores UTF-16 code units, though.
  // Consume the UTF-16 code unit, which may be a high surrogate.
  int code_unit16_high = 0;
  if (!HexStringToInt(StringPiece(pos_, 4), &code_unit16_high))
    return false;

  // Only add 3, not 4, because at the end of this iteration, the parser has
  // finished working with the last digit of the UTF sequence, meaning that
  // the next iteration will advance to the next byte.
  NextNChars(3);

  // Used to convert the UTF-16 code units to a code point and then to a UTF-8
  // code unit sequence.
  char code_unit8[8] = { 0 };
  size_t offset = 0;

  // If this is a high surrogate, consume the next code unit to get the
  // low surrogate.
  if (CBU16_IS_SURROGATE(code_unit16_high)) {
    // Make sure this is the high surrogate. If not, it's an encoding
    // error.
    if (!CBU16_IS_SURROGATE_LEAD(code_unit16_high))
      return false;

    // Make sure that the token has more characters to consume the
    // lower surrogate.
    if (!CanConsume(6))  // 6 being '\' 'u' and four HEX digits.
      return false;
    if (*NextChar() != '\\' || *NextChar() != 'u')
      return false;

    NextChar();  // Read past 'u'.
    int code_unit16_low = 0;
    if (!HexStringToInt(StringPiece(pos_, 4), &code_unit16_low))
      return false;

    NextNChars(3);

    if (!CBU16_IS_TRAIL(code_unit16_low)) {
      return false;
    }

    uint32 code_point = CBU16_GET_SUPPLEMENTARY(code_unit16_high,
                                                code_unit16_low);
    if (!IsValidCharacter(code_point))
      return false;

    offset = 0;
    CBU8_APPEND_UNSAFE(code_unit8, offset, code_point);
  } else {
    // Not a surrogate.
    DCHECK(CBU16_IS_SINGLE(code_unit16_high));
    if (!IsValidCharacter(code_unit16_high))
      return false;

    CBU8_APPEND_UNSAFE(code_unit8, offset, code_unit16_high);
  }

  dest_string->append(code_unit8);
  return true;
}

void JSONParser::DecodeUTF8(const int32& point, StringBuilder* dest) {
  DCHECK(IsValidCharacter(point));

  // Anything outside of the basic ASCII plane will need to be decoded from
  // int32 to a multi-byte sequence.
  if (point < kExtendedASCIIStart) {
    dest->Append(static_cast<char>(point));
  } else {
    char utf8_units[4] = { 0 };
    int offset = 0;
    CBU8_APPEND_UNSAFE(utf8_units, offset, point);
    dest->Convert();
    // CBU8_APPEND_UNSAFE can overwrite up to 4 bytes, so utf8_units may not be
    // zero terminated at this point.  |offset| contains the correct length.
    dest->AppendString(std::string(utf8_units, offset));
  }
}

Value* JSONParser::ConsumeNumber() {
  const char* num_start = pos_;
  const int start_index = index_;
  int end_index = start_index;

  if (*pos_ == '-')
    NextChar();

  if (!ReadInt(false)) {
    ReportError(JSONReader::JSON_SYNTAX_ERROR, 1);
    return NULL;
  }
  end_index = index_;

  // The optional fraction part.
  if (*pos_ == '.') {
    if (!CanConsume(1)) {
      ReportError(JSONReader::JSON_SYNTAX_ERROR, 1);
      return NULL;
    }
    NextChar();
    if (!ReadInt(true)) {
      ReportError(JSONReader::JSON_SYNTAX_ERROR, 1);
      return NULL;
    }
    end_index = index_;
  }

  // Optional exponent part.
  if (*pos_ == 'e' || *pos_ == 'E') {
    NextChar();
    if (*pos_ == '-' || *pos_ == '+')
      NextChar();
    if (!ReadInt(true)) {
      ReportError(JSONReader::JSON_SYNTAX_ERROR, 1);
      return NULL;
    }
    end_index = index_;
  }

  // ReadInt is greedy because numbers have no easily detectable sentinel,
  // so save off where the parser should be on exit (see Consume invariant at
  // the top of the header), then make sure the next token is one which is
  // valid.
  const char* exit_pos = pos_ - 1;
  int exit_index = index_ - 1;

  switch (GetNextToken()) {
    case T_OBJECT_END:
    case T_ARRAY_END:
    case T_LIST_SEPARATOR:
    case T_END_OF_INPUT:
      break;
    default:
      ReportError(JSONReader::JSON_SYNTAX_ERROR, 1);
      return NULL;
  }

  pos_ = exit_pos;
  index_ = exit_index;

  StringPiece num_string(num_start, end_index - start_index);

  int num_int;
  if (StringToInt(num_string, &num_int))
    return new FundamentalValue(num_int);

  double num_double;
  if (StringToDouble(num_string.as_string(), &num_double) &&
      std::isfinite(num_double)) {
    return new FundamentalValue(num_double);
  }

  return NULL;
}

bool JSONParser::ReadInt(bool allow_leading_zeros) {
  char first = *pos_;
  int len = 0;

  char c = first;
  while (CanConsume(1) && IsAsciiDigit(c)) {
    c = *NextChar();
    ++len;
  }

  if (len == 0)
    return false;

  if (!allow_leading_zeros && len > 1 && first == '0')
    return false;

  return true;
}

Value* JSONParser::ConsumeLiteral() {
  switch (*pos_) {
    case 't': {
      const char kTrueLiteral[] = "true";
      const int kTrueLen = static_cast<int>(strlen(kTrueLiteral));
      if (!CanConsume(kTrueLen - 1) ||
          !StringsAreEqual(pos_, kTrueLiteral, kTrueLen)) {
        ReportError(JSONReader::JSON_SYNTAX_ERROR, 1);
        return NULL;
      }
      NextNChars(kTrueLen - 1);
      return new FundamentalValue(true);
    }
    case 'f': {
      const char kFalseLiteral[] = "false";
      const int kFalseLen = static_cast<int>(strlen(kFalseLiteral));
      if (!CanConsume(kFalseLen - 1) ||
          !StringsAreEqual(pos_, kFalseLiteral, kFalseLen)) {
        ReportError(JSONReader::JSON_SYNTAX_ERROR, 1);
        return NULL;
      }
      NextNChars(kFalseLen - 1);
      return new FundamentalValue(false);
    }
    case 'n': {
      const char kNullLiteral[] = "null";
      const int kNullLen = static_cast<int>(strlen(kNullLiteral));
      if (!CanConsume(kNullLen - 1) ||
          !StringsAreEqual(pos_, kNullLiteral, kNullLen)) {
        ReportError(JSONReader::JSON_SYNTAX_ERROR, 1);
        return NULL;
      }
      NextNChars(kNullLen - 1);
      return Value::CreateNullValue().release();
    }
    default:
      ReportError(JSONReader::JSON_UNEXPECTED_TOKEN, 1);
      return NULL;
  }
}

// static
bool JSONParser::StringsAreEqual(const char* one, const char* two, size_t len) {
  return strncmp(one, two, len) == 0;
}

void JSONParser::ReportError(JSONReader::JsonParseError code,
                             int column_adjust) {
  error_code_ = code;
  error_line_ = line_number_;
  error_column_ = index_ - index_last_line_ + column_adjust;
}

// static
std::string JSONParser::FormatErrorMessage(int line, int column,
                                           const std::string& description) {
  if (line || column) {
    return StringPrintf("Line: %i, column: %i, %s",
        line, column, description.c_str());
  }
  return description;
}

}  // namespace internal
}  // namespace base
