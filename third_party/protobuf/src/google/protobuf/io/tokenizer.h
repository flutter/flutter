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
// Class for parsing tokenized text from a ZeroCopyInputStream.

#ifndef GOOGLE_PROTOBUF_IO_TOKENIZER_H__
#define GOOGLE_PROTOBUF_IO_TOKENIZER_H__

#include <string>
#include <vector>
#include <google/protobuf/stubs/common.h>

namespace google {
namespace protobuf {
namespace io {

class ZeroCopyInputStream;     // zero_copy_stream.h

// Defined in this file.
class ErrorCollector;
class Tokenizer;

// Abstract interface for an object which collects the errors that occur
// during parsing.  A typical implementation might simply print the errors
// to stdout.
class LIBPROTOBUF_EXPORT ErrorCollector {
 public:
  inline ErrorCollector() {}
  virtual ~ErrorCollector();

  // Indicates that there was an error in the input at the given line and
  // column numbers.  The numbers are zero-based, so you may want to add
  // 1 to each before printing them.
  virtual void AddError(int line, int column, const string& message) = 0;

  // Indicates that there was a warning in the input at the given line and
  // column numbers.  The numbers are zero-based, so you may want to add
  // 1 to each before printing them.
  virtual void AddWarning(int line, int column, const string& message) { }

 private:
  GOOGLE_DISALLOW_EVIL_CONSTRUCTORS(ErrorCollector);
};

// This class converts a stream of raw text into a stream of tokens for
// the protocol definition parser to parse.  The tokens recognized are
// similar to those that make up the C language; see the TokenType enum for
// precise descriptions.  Whitespace and comments are skipped.  By default,
// C- and C++-style comments are recognized, but other styles can be used by
// calling set_comment_style().
class LIBPROTOBUF_EXPORT Tokenizer {
 public:
  // Construct a Tokenizer that reads and tokenizes text from the given
  // input stream and writes errors to the given error_collector.
  // The caller keeps ownership of input and error_collector.
  Tokenizer(ZeroCopyInputStream* input, ErrorCollector* error_collector);
  ~Tokenizer();

  enum TokenType {
    TYPE_START,       // Next() has not yet been called.
    TYPE_END,         // End of input reached.  "text" is empty.

    TYPE_IDENTIFIER,  // A sequence of letters, digits, and underscores, not
                      // starting with a digit.  It is an error for a number
                      // to be followed by an identifier with no space in
                      // between.
    TYPE_INTEGER,     // A sequence of digits representing an integer.  Normally
                      // the digits are decimal, but a prefix of "0x" indicates
                      // a hex number and a leading zero indicates octal, just
                      // like with C numeric literals.  A leading negative sign
                      // is NOT included in the token; it's up to the parser to
                      // interpret the unary minus operator on its own.
    TYPE_FLOAT,       // A floating point literal, with a fractional part and/or
                      // an exponent.  Always in decimal.  Again, never
                      // negative.
    TYPE_STRING,      // A quoted sequence of escaped characters.  Either single
                      // or double quotes can be used, but they must match.
                      // A string literal cannot cross a line break.
    TYPE_SYMBOL,      // Any other printable character, like '!' or '+'.
                      // Symbols are always a single character, so "!+$%" is
                      // four tokens.
  };

  // Structure representing a token read from the token stream.
  struct Token {
    TokenType type;
    string text;       // The exact text of the token as it appeared in
                       // the input.  e.g. tokens of TYPE_STRING will still
                       // be escaped and in quotes.

    // "line" and "column" specify the position of the first character of
    // the token within the input stream.  They are zero-based.
    int line;
    int column;
    int end_column;
  };

  // Get the current token.  This is updated when Next() is called.  Before
  // the first call to Next(), current() has type TYPE_START and no contents.
  const Token& current();

  // Return the previous token -- i.e. what current() returned before the
  // previous call to Next().
  const Token& previous();

  // Advance to the next token.  Returns false if the end of the input is
  // reached.
  bool Next();

  // Like Next(), but also collects comments which appear between the previous
  // and next tokens.
  //
  // Comments which appear to be attached to the previous token are stored
  // in *prev_tailing_comments.  Comments which appear to be attached to the
  // next token are stored in *next_leading_comments.  Comments appearing in
  // between which do not appear to be attached to either will be added to
  // detached_comments.  Any of these parameters can be NULL to simply discard
  // the comments.
  //
  // A series of line comments appearing on consecutive lines, with no other
  // tokens appearing on those lines, will be treated as a single comment.
  //
  // Only the comment content is returned; comment markers (e.g. //) are
  // stripped out.  For block comments, leading whitespace and an asterisk will
  // be stripped from the beginning of each line other than the first.  Newlines
  // are included in the output.
  //
  // Examples:
  //
  //   optional int32 foo = 1;  // Comment attached to foo.
  //   // Comment attached to bar.
  //   optional int32 bar = 2;
  //
  //   optional string baz = 3;
  //   // Comment attached to baz.
  //   // Another line attached to baz.
  //
  //   // Comment attached to qux.
  //   //
  //   // Another line attached to qux.
  //   optional double qux = 4;
  //
  //   // Detached comment.  This is not attached to qux or corge
  //   // because there are blank lines separating it from both.
  //
  //   optional string corge = 5;
  //   /* Block comment attached
  //    * to corge.  Leading asterisks
  //    * will be removed. */
  //   /* Block comment attached to
  //    * grault. */
  //   optional int32 grault = 6;
  bool NextWithComments(string* prev_trailing_comments,
                        vector<string>* detached_comments,
                        string* next_leading_comments);

  // Parse helpers ---------------------------------------------------

  // Parses a TYPE_FLOAT token.  This never fails, so long as the text actually
  // comes from a TYPE_FLOAT token parsed by Tokenizer.  If it doesn't, the
  // result is undefined (possibly an assert failure).
  static double ParseFloat(const string& text);

  // Parses a TYPE_STRING token.  This never fails, so long as the text actually
  // comes from a TYPE_STRING token parsed by Tokenizer.  If it doesn't, the
  // result is undefined (possibly an assert failure).
  static void ParseString(const string& text, string* output);

  // Identical to ParseString, but appends to output.
  static void ParseStringAppend(const string& text, string* output);

  // Parses a TYPE_INTEGER token.  Returns false if the result would be
  // greater than max_value.  Otherwise, returns true and sets *output to the
  // result.  If the text is not from a Token of type TYPE_INTEGER originally
  // parsed by a Tokenizer, the result is undefined (possibly an assert
  // failure).
  static bool ParseInteger(const string& text, uint64 max_value,
                           uint64* output);

  // Options ---------------------------------------------------------

  // Set true to allow floats to be suffixed with the letter 'f'.  Tokens
  // which would otherwise be integers but which have the 'f' suffix will be
  // forced to be interpreted as floats.  For all other purposes, the 'f' is
  // ignored.
  void set_allow_f_after_float(bool value) { allow_f_after_float_ = value; }

  // Valid values for set_comment_style().
  enum CommentStyle {
    // Line comments begin with "//", block comments are delimited by "/*" and
    // "*/".
    CPP_COMMENT_STYLE,
    // Line comments begin with "#".  No way to write block comments.
    SH_COMMENT_STYLE
  };

  // Sets the comment style.
  void set_comment_style(CommentStyle style) { comment_style_ = style; }

  // -----------------------------------------------------------------
 private:
  GOOGLE_DISALLOW_EVIL_CONSTRUCTORS(Tokenizer);

  Token current_;           // Returned by current().
  Token previous_;          // Returned by previous().

  ZeroCopyInputStream* input_;
  ErrorCollector* error_collector_;

  char current_char_;       // == buffer_[buffer_pos_], updated by NextChar().
  const char* buffer_;      // Current buffer returned from input_.
  int buffer_size_;         // Size of buffer_.
  int buffer_pos_;          // Current position within the buffer.
  bool read_error_;         // Did we previously encounter a read error?

  // Line and column number of current_char_ within the whole input stream.
  int line_;
  int column_;

  // String to which text should be appended as we advance through it.
  // Call RecordTo(&str) to start recording and StopRecording() to stop.
  // E.g. StartToken() calls RecordTo(&current_.text).  record_start_ is the
  // position within the current buffer where recording started.
  string* record_target_;
  int record_start_;

  // Options.
  bool allow_f_after_float_;
  CommentStyle comment_style_;

  // Since we count columns we need to interpret tabs somehow.  We'll take
  // the standard 8-character definition for lack of any way to do better.
  static const int kTabWidth = 8;

  // -----------------------------------------------------------------
  // Helper methods.

  // Consume this character and advance to the next one.
  void NextChar();

  // Read a new buffer from the input.
  void Refresh();

  inline void RecordTo(string* target);
  inline void StopRecording();

  // Called when the current character is the first character of a new
  // token (not including whitespace or comments).
  inline void StartToken();
  // Called when the current character is the first character after the
  // end of the last token.  After this returns, current_.text will
  // contain all text consumed since StartToken() was called.
  inline void EndToken();

  // Convenience method to add an error at the current line and column.
  void AddError(const string& message) {
    error_collector_->AddError(line_, column_, message);
  }

  // -----------------------------------------------------------------
  // The following four methods are used to consume tokens of specific
  // types.  They are actually used to consume all characters *after*
  // the first, since the calling function consumes the first character
  // in order to decide what kind of token is being read.

  // Read and consume a string, ending when the given delimiter is
  // consumed.
  void ConsumeString(char delimiter);

  // Read and consume a number, returning TYPE_FLOAT or TYPE_INTEGER
  // depending on what was read.  This needs to know if the first
  // character was a zero in order to correctly recognize hex and octal
  // numbers.
  // It also needs to know if the first characted was a . to parse floating
  // point correctly.
  TokenType ConsumeNumber(bool started_with_zero, bool started_with_dot);

  // Consume the rest of a line.
  void ConsumeLineComment(string* content);
  // Consume until "*/".
  void ConsumeBlockComment(string* content);

  enum NextCommentStatus {
    // Started a line comment.
    LINE_COMMENT,

    // Started a block comment.
    BLOCK_COMMENT,

    // Consumed a slash, then realized it wasn't a comment.  current_ has
    // been filled in with a slash token.  The caller should return it.
    SLASH_NOT_COMMENT,

    // We do not appear to be starting a comment here.
    NO_COMMENT
  };

  // If we're at the start of a new comment, consume it and return what kind
  // of comment it is.
  NextCommentStatus TryConsumeCommentStart();

  // -----------------------------------------------------------------
  // These helper methods make the parsing code more readable.  The
  // "character classes" refered to are defined at the top of the .cc file.
  // Basically it is a C++ class with one method:
  //   static bool InClass(char c);
  // The method returns true if c is a member of this "class", like "Letter"
  // or "Digit".

  // Returns true if the current character is of the given character
  // class, but does not consume anything.
  template<typename CharacterClass>
  inline bool LookingAt();

  // If the current character is in the given class, consume it and return
  // true.  Otherwise return false.
  // e.g. TryConsumeOne<Letter>()
  template<typename CharacterClass>
  inline bool TryConsumeOne();

  // Like above, but try to consume the specific character indicated.
  inline bool TryConsume(char c);

  // Consume zero or more of the given character class.
  template<typename CharacterClass>
  inline void ConsumeZeroOrMore();

  // Consume one or more of the given character class or log the given
  // error message.
  // e.g. ConsumeOneOrMore<Digit>("Expected digits.");
  template<typename CharacterClass>
  inline void ConsumeOneOrMore(const char* error);
};

// inline methods ====================================================
inline const Tokenizer::Token& Tokenizer::current() {
  return current_;
}

inline const Tokenizer::Token& Tokenizer::previous() {
  return previous_;
}

inline void Tokenizer::ParseString(const string& text, string* output) {
  output->clear();
  ParseStringAppend(text, output);
}

}  // namespace io
}  // namespace protobuf

}  // namespace google
#endif  // GOOGLE_PROTOBUF_IO_TOKENIZER_H__
