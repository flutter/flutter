// Protocol Buffers - Google's data interchange format
// Copyright 2008 Google Inc.  All rights reserved.
// http://code.google.com/p/protobuf/
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//     * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//     * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// Author: kenton@google.com (Kenton Varda)
//  Based on original Protocol Buffers design by
//  Sanjay Ghemawat, Jeff Dean, and others.
//
// Here we have a hand-written lexer.  At first you might ask yourself,
// "Hand-written text processing?  Is Kenton crazy?!"  Well, first of all,
// yes I am crazy, but that's beside the point.  There are actually reasons
// why I ended up writing this this way.
//
// The traditional approach to lexing is to use lex to generate a lexer for
// you.  Unfortunately, lex's output is ridiculously ugly and difficult to
// integrate cleanly with C++ code, especially abstract code or code meant
// as a library.  Better parser-generators exist but would add dependencies
// which most users won't already have, which we'd like to avoid.  (GNU flex
// has a C++ output option, but it's still ridiculously ugly, non-abstract,
// and not library-friendly.)
//
// The next approach that any good software engineer should look at is to
// use regular expressions.  And, indeed, I did.  I have code which
// implements this same class using regular expressions.  It's about 200
// lines shorter.  However:
// - Rather than error messages telling you "This string has an invalid
//   escape sequence at line 5, column 45", you get error messages like
//   "Parse error on line 5".  Giving more precise errors requires adding
//   a lot of code that ends up basically as complex as the hand-coded
//   version anyway.
// - The regular expression to match a string literal looks like this:
//     kString  = new RE("(\"([^\"\\\\]|"              // non-escaped
//                       "\\\\[abfnrtv?\"'\\\\0-7]|"   // normal escape
//                       "\\\\x[0-9a-fA-F])*\"|"       // hex escape
//                       "\'([^\'\\\\]|"        // Also support single-quotes.
//                       "\\\\[abfnrtv?\"'\\\\0-7]|"
//                       "\\\\x[0-9a-fA-F])*\')");
//   Verifying the correctness of this line noise is actually harder than
//   verifying the correctness of ConsumeString(), defined below.  I'm not
//   even confident that the above is correct, after staring at it for some
//   time.
// - PCRE is fast, but there's still more overhead involved than the code
//   below.
// - Sadly, regular expressions are not part of the C standard library, so
//   using them would require depending on some other library.  For the
//   open source release, this could be really annoying.  Nobody likes
//   downloading one piece of software just to find that they need to
//   download something else to make it work, and in all likelihood
//   people downloading Protocol Buffers will already be doing so just
//   to make something else work.  We could include a copy of PCRE with
//   our code, but that obligates us to keep it up-to-date and just seems
//   like a big waste just to save 200 lines of code.
//
// On a similar but unrelated note, I'm even scared to use ctype.h.
// Apparently functions like isalpha() are locale-dependent.  So, if we used
// that, then if this code is being called from some program that doesn't
// have its locale set to "C", it would behave strangely.  We can't just set
// the locale to "C" ourselves since we might break the calling program that
// way, particularly if it is multi-threaded.  WTF?  Someone please let me
// (Kenton) know if I'm missing something here...
//
// I'd love to hear about other alternatives, though, as this code isn't
// exactly pretty.

#include <google/protobuf/io/tokenizer.h>
#include <google/protobuf/stubs/common.h>
#include <google/protobuf/stubs/stringprintf.h>
#include <google/protobuf/io/zero_copy_stream.h>
#include <google/protobuf/stubs/strutil.h>
#include <google/protobuf/stubs/stl_util.h>

namespace google {
namespace protobuf {
namespace io {
namespace {

// As mentioned above, I don't trust ctype.h due to the presence of "locales".
// So, I have written replacement functions here.  Someone please smack me if
// this is a bad idea or if there is some way around this.
//
// These "character classes" are designed to be used in template methods.
// For instance, Tokenizer::ConsumeZeroOrMore<Whitespace>() will eat
// whitespace.

// Note:  No class is allowed to contain '\0', since this is used to mark end-
//   of-input and is handled specially.

#define CHARACTER_CLASS(NAME, EXPRESSION)      \
  class NAME {                                 \
   public:                                     \
    static inline bool InClass(char c) {       \
      return EXPRESSION;                       \
    }                                          \
  }

CHARACTER_CLASS(Whitespace, c == ' ' || c == '\n' || c == '\t' ||
                            c == '\r' || c == '\v' || c == '\f');
CHARACTER_CLASS(WhitespaceNoNewline, c == ' ' || c == '\t' ||
                                     c == '\r' || c == '\v' || c == '\f');

CHARACTER_CLASS(Unprintable, c < ' ' && c > '\0');

CHARACTER_CLASS(Digit, '0' <= c && c <= '9');
CHARACTER_CLASS(OctalDigit, '0' <= c && c <= '7');
CHARACTER_CLASS(HexDigit, ('0' <= c && c <= '9') ||
                          ('a' <= c && c <= 'f') ||
                          ('A' <= c && c <= 'F'));

CHARACTER_CLASS(Letter, ('a' <= c && c <= 'z') ||
                        ('A' <= c && c <= 'Z') ||
                        (c == '_'));

CHARACTER_CLASS(Alphanumeric, ('a' <= c && c <= 'z') ||
                              ('A' <= c && c <= 'Z') ||
                              ('0' <= c && c <= '9') ||
                              (c == '_'));

CHARACTER_CLASS(Escape, c == 'a' || c == 'b' || c == 'f' || c == 'n' ||
                        c == 'r' || c == 't' || c == 'v' || c == '\\' ||
                        c == '?' || c == '\'' || c == '\"');

#undef CHARACTER_CLASS

// Given a char, interpret it as a numeric digit and return its value.
// This supports any number base up to 36.
inline int DigitValue(char digit) {
  if ('0' <= digit && digit <= '9') return digit - '0';
  if ('a' <= digit && digit <= 'z') return digit - 'a' + 10;
  if ('A' <= digit && digit <= 'Z') return digit - 'A' + 10;
  return -1;
}

// Inline because it's only used in one place.
inline char TranslateEscape(char c) {
  switch (c) {
    case 'a':  return '\a';
    case 'b':  return '\b';
    case 'f':  return '\f';
    case 'n':  return '\n';
    case 'r':  return '\r';
    case 't':  return '\t';
    case 'v':  return '\v';
    case '\\': return '\\';
    case '?':  return '\?';    // Trigraphs = :(
    case '\'': return '\'';
    case '"':  return '\"';

    // We expect escape sequences to have been validated separately.
    default:   return '?';
  }
}

}  // anonymous namespace

ErrorCollector::~ErrorCollector() {}

// ===================================================================

Tokenizer::Tokenizer(ZeroCopyInputStream* input,
                     ErrorCollector* error_collector)
  : input_(input),
    error_collector_(error_collector),
    buffer_(NULL),
    buffer_size_(0),
    buffer_pos_(0),
    read_error_(false),
    line_(0),
    column_(0),
    record_target_(NULL),
    record_start_(-1),
    allow_f_after_float_(false),
    comment_style_(CPP_COMMENT_STYLE) {

  current_.line = 0;
  current_.column = 0;
  current_.end_column = 0;
  current_.type = TYPE_START;

  Refresh();
}

Tokenizer::~Tokenizer() {
  // If we had any buffer left unread, return it to the underlying stream
  // so that someone else can read it.
  if (buffer_size_ > buffer_pos_) {
    input_->BackUp(buffer_size_ - buffer_pos_);
  }
}

// -------------------------------------------------------------------
// Internal helpers.

void Tokenizer::NextChar() {
  // Update our line and column counters based on the character being
  // consumed.
  if (current_char_ == '\n') {
    ++line_;
    column_ = 0;
  } else if (current_char_ == '\t') {
    column_ += kTabWidth - column_ % kTabWidth;
  } else {
    ++column_;
  }

  // Advance to the next character.
  ++buffer_pos_;
  if (buffer_pos_ < buffer_size_) {
    current_char_ = buffer_[buffer_pos_];
  } else {
    Refresh();
  }
}

void Tokenizer::Refresh() {
  if (read_error_) {
    current_char_ = '\0';
    return;
  }

  // If we're in a token, append the rest of the buffer to it.
  if (record_target_ != NULL && record_start_ < buffer_size_) {
    record_target_->append(buffer_ + record_start_, buffer_size_ - record_start_);
    record_start_ = 0;
  }

  const void* data = NULL;
  buffer_ = NULL;
  buffer_pos_ = 0;
  do {
    if (!input_->Next(&data, &buffer_size_)) {
      // end of stream (or read error)
      buffer_size_ = 0;
      read_error_ = true;
      current_char_ = '\0';
      return;
    }
  } while (buffer_size_ == 0);

  buffer_ = static_cast<const char*>(data);

  current_char_ = buffer_[0];
}

inline void Tokenizer::RecordTo(string* target) {
  record_target_ = target;
  record_start_ = buffer_pos_;
}

inline void Tokenizer::StopRecording() {
  // Note:  The if() is necessary because some STL implementations crash when
  //   you call string::append(NULL, 0), presumably because they are trying to
  //   be helpful by detecting the NULL pointer, even though there's nothing
  //   wrong with reading zero bytes from NULL.
  if (buffer_pos_ != record_start_) {
    record_target_->append(buffer_ + record_start_, buffer_pos_ - record_start_);
  }
  record_target_ = NULL;
  record_start_ = -1;
}

inline void Tokenizer::StartToken() {
  current_.type = TYPE_START;    // Just for the sake of initializing it.
  current_.text.clear();
  current_.line = line_;
  current_.column = column_;
  RecordTo(&current_.text);
}

inline void Tokenizer::EndToken() {
  StopRecording();
  current_.end_column = column_;
}

// -------------------------------------------------------------------
// Helper methods that consume characters.

template<typename CharacterClass>
inline bool Tokenizer::LookingAt() {
  return CharacterClass::InClass(current_char_);
}

template<typename CharacterClass>
inline bool Tokenizer::TryConsumeOne() {
  if (CharacterClass::InClass(current_char_)) {
    NextChar();
    return true;
  } else {
    return false;
  }
}

inline bool Tokenizer::TryConsume(char c) {
  if (current_char_ == c) {
    NextChar();
    return true;
  } else {
    return false;
  }
}

template<typename CharacterClass>
inline void Tokenizer::ConsumeZeroOrMore() {
  while (CharacterClass::InClass(current_char_)) {
    NextChar();
  }
}

template<typename CharacterClass>
inline void Tokenizer::ConsumeOneOrMore(const char* error) {
  if (!CharacterClass::InClass(current_char_)) {
    AddError(error);
  } else {
    do {
      NextChar();
    } while (CharacterClass::InClass(current_char_));
  }
}

// -------------------------------------------------------------------
// Methods that read whole patterns matching certain kinds of tokens
// or comments.

void Tokenizer::ConsumeString(char delimiter) {
  while (true) {
    switch (current_char_) {
      case '\0':
      case '\n': {
        AddError("String literals cannot cross line boundaries.");
        return;
      }

      case '\\': {
        // An escape sequence.
        NextChar();
        if (TryConsumeOne<Escape>()) {
          // Valid escape sequence.
        } else if (TryConsumeOne<OctalDigit>()) {
          // Possibly followed by two more octal digits, but these will
          // just be consumed by the main loop anyway so we don't need
          // to do so explicitly here.
        } else if (TryConsume('x') || TryConsume('X')) {
          if (!TryConsumeOne<HexDigit>()) {
            AddError("Expected hex digits for escape sequence.");
          }
          // Possibly followed by another hex digit, but again we don't care.
        } else if (TryConsume('u')) {
          if (!TryConsumeOne<HexDigit>() ||
              !TryConsumeOne<HexDigit>() ||
              !TryConsumeOne<HexDigit>() ||
              !TryConsumeOne<HexDigit>()) {
            AddError("Expected four hex digits for \\u escape sequence.");
          }
        } else if (TryConsume('U')) {
          // We expect 8 hex digits; but only the range up to 0x10ffff is
          // legal.
          if (!TryConsume('0') ||
              !TryConsume('0') ||
              !(TryConsume('0') || TryConsume('1')) ||
              !TryConsumeOne<HexDigit>() ||
              !TryConsumeOne<HexDigit>() ||
              !TryConsumeOne<HexDigit>() ||
              !TryConsumeOne<HexDigit>() ||
              !TryConsumeOne<HexDigit>()) {
            AddError("Expected eight hex digits up to 10ffff for \\U escape "
                     "sequence");
          }
        } else {
          AddError("Invalid escape sequence in string literal.");
        }
        break;
      }

      default: {
        if (current_char_ == delimiter) {
          NextChar();
          return;
        }
        NextChar();
        break;
      }
    }
  }
}

Tokenizer::TokenType Tokenizer::ConsumeNumber(bool started_with_zero,
                                              bool started_with_dot) {
  bool is_float = false;

  if (started_with_zero && (TryConsume('x') || TryConsume('X'))) {
    // A hex number (started with "0x").
    ConsumeOneOrMore<HexDigit>("\"0x\" must be followed by hex digits.");

  } else if (started_with_zero && LookingAt<Digit>()) {
    // An octal number (had a leading zero).
    ConsumeZeroOrMore<OctalDigit>();
    if (LookingAt<Digit>()) {
      AddError("Numbers starting with leading zero must be in octal.");
      ConsumeZeroOrMore<Digit>();
    }

  } else {
    // A decimal number.
    if (started_with_dot) {
      is_float = true;
      ConsumeZeroOrMore<Digit>();
    } else {
      ConsumeZeroOrMore<Digit>();

      if (TryConsume('.')) {
        is_float = true;
        ConsumeZeroOrMore<Digit>();
      }
    }

    if (TryConsume('e') || TryConsume('E')) {
      is_float = true;
      TryConsume('-') || TryConsume('+');
      ConsumeOneOrMore<Digit>("\"e\" must be followed by exponent.");
    }

    if (allow_f_after_float_ && (TryConsume('f') || TryConsume('F'))) {
      is_float = true;
    }
  }

  if (LookingAt<Letter>()) {
    AddError("Need space between number and identifier.");
  } else if (current_char_ == '.') {
    if (is_float) {
      AddError(
        "Already saw decimal point or exponent; can't have another one.");
    } else {
      AddError("Hex and octal numbers must be integers.");
    }
  }

  return is_float ? TYPE_FLOAT : TYPE_INTEGER;
}

void Tokenizer::ConsumeLineComment(string* content) {
  if (content != NULL) RecordTo(content);

  while (current_char_ != '\0' && current_char_ != '\n') {
    NextChar();
  }
  TryConsume('\n');

  if (content != NULL) StopRecording();
}

void Tokenizer::ConsumeBlockComment(string* content) {
  int start_line = line_;
  int start_column = column_ - 2;

  if (content != NULL) RecordTo(content);

  while (true) {
    while (current_char_ != '\0' &&
           current_char_ != '*' &&
           current_char_ != '/' &&
           current_char_ != '\n') {
      NextChar();
    }

    if (TryConsume('\n')) {
      if (content != NULL) StopRecording();

      // Consume leading whitespace and asterisk;
      ConsumeZeroOrMore<WhitespaceNoNewline>();
      if (TryConsume('*')) {
        if (TryConsume('/')) {
          // End of comment.
          break;
        }
      }

      if (content != NULL) RecordTo(content);
    } else if (TryConsume('*') && TryConsume('/')) {
      // End of comment.
      if (content != NULL) {
        StopRecording();
        // Strip trailing "*/".
        content->erase(content->size() - 2);
      }
      break;
    } else if (TryConsume('/') && current_char_ == '*') {
      // Note:  We didn't consume the '*' because if there is a '/' after it
      //   we want to interpret that as the end of the comment.
      AddError(
        "\"/*\" inside block comment.  Block comments cannot be nested.");
    } else if (current_char_ == '\0') {
      AddError("End-of-file inside block comment.");
      error_collector_->AddError(
        start_line, start_column, "  Comment started here.");
      if (content != NULL) StopRecording();
      break;
    }
  }
}

Tokenizer::NextCommentStatus Tokenizer::TryConsumeCommentStart() {
  if (comment_style_ == CPP_COMMENT_STYLE && TryConsume('/')) {
    if (TryConsume('/')) {
      return LINE_COMMENT;
    } else if (TryConsume('*')) {
      return BLOCK_COMMENT;
    } else {
      // Oops, it was just a slash.  Return it.
      current_.type = TYPE_SYMBOL;
      current_.text = "/";
      current_.line = line_;
      current_.column = column_ - 1;
      current_.end_column = column_;
      return SLASH_NOT_COMMENT;
    }
  } else if (comment_style_ == SH_COMMENT_STYLE && TryConsume('#')) {
    return LINE_COMMENT;
  } else {
    return NO_COMMENT;
  }
}

// -------------------------------------------------------------------

bool Tokenizer::Next() {
  previous_ = current_;

  while (!read_error_) {
    ConsumeZeroOrMore<Whitespace>();

    switch (TryConsumeCommentStart()) {
      case LINE_COMMENT:
        ConsumeLineComment(NULL);
        continue;
      case BLOCK_COMMENT:
        ConsumeBlockComment(NULL);
        continue;
      case SLASH_NOT_COMMENT:
        return true;
      case NO_COMMENT:
        break;
    }

    // Check for EOF before continuing.
    if (read_error_) break;

    if (LookingAt<Unprintable>() || current_char_ == '\0') {
      AddError("Invalid control characters encountered in text.");
      NextChar();
      // Skip more unprintable characters, too.  But, remember that '\0' is
      // also what current_char_ is set to after EOF / read error.  We have
      // to be careful not to go into an infinite loop of trying to consume
      // it, so make sure to check read_error_ explicitly before consuming
      // '\0'.
      while (TryConsumeOne<Unprintable>() ||
             (!read_error_ && TryConsume('\0'))) {
        // Ignore.
      }

    } else {
      // Reading some sort of token.
      StartToken();

      if (TryConsumeOne<Letter>()) {
        ConsumeZeroOrMore<Alphanumeric>();
        current_.type = TYPE_IDENTIFIER;
      } else if (TryConsume('0')) {
        current_.type = ConsumeNumber(true, false);
      } else if (TryConsume('.')) {
        // This could be the beginning of a floating-point number, or it could
        // just be a '.' symbol.

        if (TryConsumeOne<Digit>()) {
          // It's a floating-point number.
          if (previous_.type == TYPE_IDENTIFIER &&
              current_.line == previous_.line &&
              current_.column == previous_.end_column) {
            // We don't accept syntax like "blah.123".
            error_collector_->AddError(line_, column_ - 2,
              "Need space between identifier and decimal point.");
          }
          current_.type = ConsumeNumber(false, true);
        } else {
          current_.type = TYPE_SYMBOL;
        }
      } else if (TryConsumeOne<Digit>()) {
        current_.type = ConsumeNumber(false, false);
      } else if (TryConsume('\"')) {
        ConsumeString('\"');
        current_.type = TYPE_STRING;
      } else if (TryConsume('\'')) {
        ConsumeString('\'');
        current_.type = TYPE_STRING;
      } else {
        NextChar();
        current_.type = TYPE_SYMBOL;
      }

      EndToken();
      return true;
    }
  }

  // EOF
  current_.type = TYPE_END;
  current_.text.clear();
  current_.line = line_;
  current_.column = column_;
  current_.end_column = column_;
  return false;
}

namespace {

// Helper class for collecting comments and putting them in the right places.
//
// This basically just buffers the most recent comment until it can be decided
// exactly where that comment should be placed.  When Flush() is called, the
// current comment goes into either prev_trailing_comments or detached_comments.
// When the CommentCollector is destroyed, the last buffered comment goes into
// next_leading_comments.
class CommentCollector {
 public:
  CommentCollector(string* prev_trailing_comments,
                   vector<string>* detached_comments,
                   string* next_leading_comments)
      : prev_trailing_comments_(prev_trailing_comments),
        detached_comments_(detached_comments),
        next_leading_comments_(next_leading_comments),
        has_comment_(false),
        is_line_comment_(false),
        can_attach_to_prev_(true) {
    if (prev_trailing_comments != NULL) prev_trailing_comments->clear();
    if (detached_comments != NULL) detached_comments->clear();
    if (next_leading_comments != NULL) next_leading_comments->clear();
  }

  ~CommentCollector() {
    // Whatever is in the buffer is a leading comment.
    if (next_leading_comments_ != NULL && has_comment_) {
      comment_buffer_.swap(*next_leading_comments_);
    }
  }

  // About to read a line comment.  Get the comment buffer pointer in order to
  // read into it.
  string* GetBufferForLineComment() {
    // We want to combine with previous line comments, but not block comments.
    if (has_comment_ && !is_line_comment_) {
      Flush();
    }
    has_comment_ = true;
    is_line_comment_ = true;
    return &comment_buffer_;
  }

  // About to read a block comment.  Get the comment buffer pointer in order to
  // read into it.
  string* GetBufferForBlockComment() {
    if (has_comment_) {
      Flush();
    }
    has_comment_ = true;
    is_line_comment_ = false;
    return &comment_buffer_;
  }

  void ClearBuffer() {
    comment_buffer_.clear();
    has_comment_ = false;
  }

  // Called once we know that the comment buffer is complete and is *not*
  // connected to the next token.
  void Flush() {
    if (has_comment_) {
      if (can_attach_to_prev_) {
        if (prev_trailing_comments_ != NULL) {
          prev_trailing_comments_->append(comment_buffer_);
        }
        can_attach_to_prev_ = false;
      } else {
        if (detached_comments_ != NULL) {
          detached_comments_->push_back(comment_buffer_);
        }
      }
      ClearBuffer();
    }
  }

  void DetachFromPrev() {
    can_attach_to_prev_ = false;
  }

 private:
  string* prev_trailing_comments_;
  vector<string>* detached_comments_;
  string* next_leading_comments_;

  string comment_buffer_;

  // True if any comments were read into comment_buffer_.  This can be true even
  // if comment_buffer_ is empty, namely if the comment was "/**/".
  bool has_comment_;

  // Is the comment in the comment buffer a line comment?
  bool is_line_comment_;

  // Is it still possible that we could be reading a comment attached to the
  // previous token?
  bool can_attach_to_prev_;
};

} // namespace

bool Tokenizer::NextWithComments(string* prev_trailing_comments,
                                 vector<string>* detached_comments,
                                 string* next_leading_comments) {
  CommentCollector collector(prev_trailing_comments, detached_comments,
                             next_leading_comments);

  if (current_.type == TYPE_START) {
    collector.DetachFromPrev();
  } else {
    // A comment appearing on the same line must be attached to the previous
    // declaration.
    ConsumeZeroOrMore<WhitespaceNoNewline>();
    switch (TryConsumeCommentStart()) {
      case LINE_COMMENT:
        ConsumeLineComment(collector.GetBufferForLineComment());

        // Don't allow comments on subsequent lines to be attached to a trailing
        // comment.
        collector.Flush();
        break;
      case BLOCK_COMMENT:
        ConsumeBlockComment(collector.GetBufferForBlockComment());

        ConsumeZeroOrMore<WhitespaceNoNewline>();
        if (!TryConsume('\n')) {
          // Oops, the next token is on the same line.  If we recorded a comment
          // we really have no idea which token it should be attached to.
          collector.ClearBuffer();
          return Next();
        }

        // Don't allow comments on subsequent lines to be attached to a trailing
        // comment.
        collector.Flush();
        break;
      case SLASH_NOT_COMMENT:
        return true;
      case NO_COMMENT:
        if (!TryConsume('\n')) {
          // The next token is on the same line.  There are no comments.
          return Next();
        }
        break;
    }
  }

  // OK, we are now on the line *after* the previous token.
  while (true) {
    ConsumeZeroOrMore<WhitespaceNoNewline>();

    switch (TryConsumeCommentStart()) {
      case LINE_COMMENT:
        ConsumeLineComment(collector.GetBufferForLineComment());
        break;
      case BLOCK_COMMENT:
        ConsumeBlockComment(collector.GetBufferForBlockComment());

        // Consume the rest of the line so that we don't interpret it as a
        // blank line the next time around the loop.
        ConsumeZeroOrMore<WhitespaceNoNewline>();
        TryConsume('\n');
        break;
      case SLASH_NOT_COMMENT:
        return true;
      case NO_COMMENT:
        if (TryConsume('\n')) {
          // Completely blank line.
          collector.Flush();
          collector.DetachFromPrev();
        } else {
          bool result = Next();
          if (!result ||
              current_.text == "}" ||
              current_.text == "]" ||
              current_.text == ")") {
            // It looks like we're at the end of a scope.  In this case it
            // makes no sense to attach a comment to the following token.
            collector.Flush();
          }
          return result;
        }
        break;
    }
  }
}

// -------------------------------------------------------------------
// Token-parsing helpers.  Remember that these don't need to report
// errors since any errors should already have been reported while
// tokenizing.  Also, these can assume that whatever text they
// are given is text that the tokenizer actually parsed as a token
// of the given type.

bool Tokenizer::ParseInteger(const string& text, uint64 max_value,
                             uint64* output) {
  // Sadly, we can't just use strtoul() since it is only 32-bit and strtoull()
  // is non-standard.  I hate the C standard library.  :(

//  return strtoull(text.c_str(), NULL, 0);

  const char* ptr = text.c_str();
  int base = 10;
  if (ptr[0] == '0') {
    if (ptr[1] == 'x' || ptr[1] == 'X') {
      // This is hex.
      base = 16;
      ptr += 2;
    } else {
      // This is octal.
      base = 8;
    }
  }

  uint64 result = 0;
  for (; *ptr != '\0'; ptr++) {
    int digit = DigitValue(*ptr);
    GOOGLE_LOG_IF(DFATAL, digit < 0 || digit >= base)
      << " Tokenizer::ParseInteger() passed text that could not have been"
         " tokenized as an integer: " << CEscape(text);
    if (digit > max_value || result > (max_value - digit) / base) {
      // Overflow.
      return false;
    }
    result = result * base + digit;
  }

  *output = result;
  return true;
}

double Tokenizer::ParseFloat(const string& text) {
  const char* start = text.c_str();
  char* end;
  double result = NoLocaleStrtod(start, &end);

  // "1e" is not a valid float, but if the tokenizer reads it, it will
  // report an error but still return it as a valid token.  We need to
  // accept anything the tokenizer could possibly return, error or not.
  if (*end == 'e' || *end == 'E') {
    ++end;
    if (*end == '-' || *end == '+') ++end;
  }

  // If the Tokenizer had allow_f_after_float_ enabled, the float may be
  // suffixed with the letter 'f'.
  if (*end == 'f' || *end == 'F') {
    ++end;
  }

  GOOGLE_LOG_IF(DFATAL, end - start != text.size() || *start == '-')
    << " Tokenizer::ParseFloat() passed text that could not have been"
       " tokenized as a float: " << CEscape(text);
  return result;
}

// Helper to append a Unicode code point to a string as UTF8, without bringing
// in any external dependencies.
static void AppendUTF8(uint32 code_point, string* output) {
  uint32 tmp = 0;
  int len = 0;
  if (code_point <= 0x7f) {
    tmp = code_point;
    len = 1;
  } else if (code_point <= 0x07ff) {
    tmp = 0x0000c080 |
        ((code_point & 0x07c0) << 2) |
        (code_point & 0x003f);
    len = 2;
  } else if (code_point <= 0xffff) {
    tmp = 0x00e08080 |
        ((code_point & 0xf000) << 4) |
        ((code_point & 0x0fc0) << 2) |
        (code_point & 0x003f);
    len = 3;
  } else if (code_point <= 0x1fffff) {
    tmp = 0xf0808080 |
        ((code_point & 0x1c0000) << 6) |
        ((code_point & 0x03f000) << 4) |
        ((code_point & 0x000fc0) << 2) |
        (code_point & 0x003f);
    len = 4;
  } else {
    // UTF-16 is only defined for code points up to 0x10FFFF, and UTF-8 is
    // normally only defined up to there as well.
    StringAppendF(output, "\\U%08x", code_point);
    return;
  }
  tmp = ghtonl(tmp);
  output->append(reinterpret_cast<const char*>(&tmp) + sizeof(tmp) - len, len);
}

// Try to read <len> hex digits from ptr, and stuff the numeric result into
// *result. Returns true if that many digits were successfully consumed.
static bool ReadHexDigits(const char* ptr, int len, uint32* result) {
  *result = 0;
  if (len == 0) return false;
  for (const char* end = ptr + len; ptr < end; ++ptr) {
    if (*ptr == '\0') return false;
    *result = (*result << 4) + DigitValue(*ptr);
  }
  return true;
}

// Handling UTF-16 surrogate pairs. UTF-16 encodes code points in the range
// 0x10000...0x10ffff as a pair of numbers, a head surrogate followed by a trail
// surrogate. These numbers are in a reserved range of Unicode code points, so
// if we encounter such a pair we know how to parse it and convert it into a
// single code point.
static const uint32 kMinHeadSurrogate = 0xd800;
static const uint32 kMaxHeadSurrogate = 0xdc00;
static const uint32 kMinTrailSurrogate = 0xdc00;
static const uint32 kMaxTrailSurrogate = 0xe000;

static inline bool IsHeadSurrogate(uint32 code_point) {
  return (code_point >= kMinHeadSurrogate) && (code_point < kMaxHeadSurrogate);
}

static inline bool IsTrailSurrogate(uint32 code_point) {
  return (code_point >= kMinTrailSurrogate) &&
      (code_point < kMaxTrailSurrogate);
}

// Combine a head and trail surrogate into a single Unicode code point.
static uint32 AssembleUTF16(uint32 head_surrogate, uint32 trail_surrogate) {
  GOOGLE_DCHECK(IsHeadSurrogate(head_surrogate));
  GOOGLE_DCHECK(IsTrailSurrogate(trail_surrogate));
  return 0x10000 + (((head_surrogate - kMinHeadSurrogate) << 10) |
      (trail_surrogate - kMinTrailSurrogate));
}

// Convert the escape sequence parameter to a number of expected hex digits.
static inline int UnicodeLength(char key) {
  if (key == 'u') return 4;
  if (key == 'U') return 8;
  return 0;
}

// Given a pointer to the 'u' or 'U' starting a Unicode escape sequence, attempt
// to parse that sequence. On success, returns a pointer to the first char
// beyond that sequence, and fills in *code_point. On failure, returns ptr
// itself.
static const char* FetchUnicodePoint(const char* ptr, uint32* code_point) {
  const char* p = ptr;
  // Fetch the code point.
  const int len = UnicodeLength(*p++);
  if (!ReadHexDigits(p, len, code_point))
    return ptr;
  p += len;

  // Check if the code point we read is a "head surrogate." If so, then we
  // expect it to be immediately followed by another code point which is a valid
  // "trail surrogate," and together they form a UTF-16 pair which decodes into
  // a single Unicode point. Trail surrogates may only use \u, not \U.
  if (IsHeadSurrogate(*code_point) && *p == '\\' && *(p + 1) == 'u') {
    uint32 trail_surrogate;
    if (ReadHexDigits(p + 2, 4, &trail_surrogate) &&
        IsTrailSurrogate(trail_surrogate)) {
      *code_point = AssembleUTF16(*code_point, trail_surrogate);
      p += 6;
    }
    // If this failed, then we just emit the head surrogate as a code point.
    // It's bogus, but so is the string.
  }

  return p;
}

// The text string must begin and end with single or double quote
// characters.
void Tokenizer::ParseStringAppend(const string& text, string* output) {
  // Reminder: text[0] is always a quote character.  (If text is
  // empty, it's invalid, so we'll just return).
  const size_t text_size = text.size();
  if (text_size == 0) {
    GOOGLE_LOG(DFATAL)
      << " Tokenizer::ParseStringAppend() passed text that could not"
         " have been tokenized as a string: " << CEscape(text);
    return;
  }

  // Reserve room for new string. The branch is necessary because if
  // there is already space available the reserve() call might
  // downsize the output.
  const size_t new_len = text_size + output->size();
  if (new_len > output->capacity()) {
    output->reserve(new_len);
  }

  // Loop through the string copying characters to "output" and
  // interpreting escape sequences.  Note that any invalid escape
  // sequences or other errors were already reported while tokenizing.
  // In this case we do not need to produce valid results.
  for (const char* ptr = text.c_str() + 1; *ptr != '\0'; ptr++) {
    if (*ptr == '\\' && ptr[1] != '\0') {
      // An escape sequence.
      ++ptr;

      if (OctalDigit::InClass(*ptr)) {
        // An octal escape.  May one, two, or three digits.
        int code = DigitValue(*ptr);
        if (OctalDigit::InClass(ptr[1])) {
          ++ptr;
          code = code * 8 + DigitValue(*ptr);
        }
        if (OctalDigit::InClass(ptr[1])) {
          ++ptr;
          code = code * 8 + DigitValue(*ptr);
        }
        output->push_back(static_cast<char>(code));

      } else if (*ptr == 'x') {
        // A hex escape.  May zero, one, or two digits.  (The zero case
        // will have been caught as an error earlier.)
        int code = 0;
        if (HexDigit::InClass(ptr[1])) {
          ++ptr;
          code = DigitValue(*ptr);
        }
        if (HexDigit::InClass(ptr[1])) {
          ++ptr;
          code = code * 16 + DigitValue(*ptr);
        }
        output->push_back(static_cast<char>(code));

      } else if (*ptr == 'u' || *ptr == 'U') {
        uint32 unicode;
        const char* end = FetchUnicodePoint(ptr, &unicode);
        if (end == ptr) {
          // Failure: Just dump out what we saw, don't try to parse it.
          output->push_back(*ptr);
        } else {
          AppendUTF8(unicode, output);
          ptr = end - 1;  // Because we're about to ++ptr.
        }
      } else {
        // Some other escape code.
        output->push_back(TranslateEscape(*ptr));
      }

    } else if (*ptr == text[0] && ptr[1] == '\0') {
      // Ignore final quote matching the starting quote.
    } else {
      output->push_back(*ptr);
    }
  }
}

}  // namespace io
}  // namespace protobuf
}  // namespace google
