// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_TEST_EXPECTATIONS_PARSER_H_
#define BASE_TEST_EXPECTATIONS_PARSER_H_

#include <string>

#include "base/basictypes.h"
#include "base/strings/string_piece.h"
#include "base/test/expectations/expectation.h"

namespace test_expectations {

// This is the internal parser for test expectations. It parses an input
// string and reports information to its Delegate as it's processing the
// input.
//
// The input format is documented here:
// https://docs.google.com/a/chromium.org/document/d/1edhMJ5doY_dzfbKNCzeJJ-8XxPrexTbNL2Y_jVvLB8Q/view
//
// Basic format:
// "http://bug/1234 [ OS-Version ] Test.Name = Result"
//
// The parser is implemented as a state machine, with each state returning a
// function pointer to the next state.
class Parser {
 public:
  // The parser will call these methods on its delegate during a Parse()
  // operation.
  class Delegate {
   public:
    // When a well-formed and valid Expectation has been parsed from the input,
    // it is reported to the delegate via this method.
    virtual void EmitExpectation(const Expectation& expectation) = 0;

    // Called when the input string is not well-formed. Parsing will stop after
    // this method is called.
    virtual void OnSyntaxError(const std::string& message) = 0;

    // Called when an Expectation has been parsed because it is well-formed but
    // contains invalid data (i.e. the modifiers or result are not valid
    // keywords). This Expectation will not be reported via EmitExpectation.
    virtual void OnDataError(const std::string& message) = 0;
  };

  // Creates a new parser for |input| that will send data to |delegate|.
  Parser(Delegate* delegate, const std::string& input);
  ~Parser();

  // Runs the parser of the input string.
  void Parse();

 private:
  // This bit of hackery is used to implement a function pointer type that
  // returns a pointer to a function of the same signature. Since a definition
  // like that is inherently recursive, it's impossible to do:
  //     type StateFunc(*StateFunc)(StateData*);
  // However, this approach works without the need to use void*. Inspired by
  // <http://www.gotw.ca/gotw/057.htm>.
  struct StateFunc;
  typedef StateFunc(Parser::*StateFuncPtr)();
  struct StateFunc {
    StateFunc(StateFuncPtr pf) : pf_(pf) {}
    operator StateFuncPtr() {
      return pf_;
    }
    StateFuncPtr pf_;
  };

  // Tests whether there is at least one more character at pos_ before end_.
  bool HasNext();

  // The parser state functions. On entry, the parser state is at the beginning
  // of the token. Each returns a function pointer to the next state function,
  // or NULL to end parsing. On return, the parser is at the beginning of the
  // next token.
  StateFunc Start();
  StateFunc ParseComment();
  StateFunc ParseBugURL();
  StateFunc BeginModifiers();
  StateFunc InModifiers();
  StateFunc SaveModifier();
  StateFunc EndModifiers();
  StateFunc ParseTestName();
  StateFunc SaveTestName();
  StateFunc ParseExpectation();
  StateFunc ParseExpectationType();
  StateFunc SaveExpectationType();
  StateFunc End();

  // A state function that collects character data from the current position
  // to the next whitespace character. Returns the |success| function when at
  // the end of the string, with the data stored in |extracted_string_|.
  StateFunc ExtractString(StateFunc success);

  // Function that skips over horizontal whitespace characters and then returns
  // the |next| state.
  StateFunc SkipWhitespace(StateFunc next);

  // Does the same as SkipWhitespace but includes newlines.
  StateFunc SkipWhitespaceAndNewLines(StateFunc next);

  // State function that reports the given syntax error |message| to the
  // delegate and then returns NULL, ending the parse loop.
  StateFunc SyntaxError(const std::string& message);

  // Function that reports the data |error| to the delegate without stopping
  // parsing.
  void DataError(const std::string& error);

  // Parser delegate.
  Delegate* delegate_;

  // The input string.
  std::string input_;

  // Current location in the |input_|.
  const char* pos_;

  // Pointer to the end of the |input_|.
  const char* end_;

  // Current line number, as updated by SkipWhitespace().
  int line_number_;

  // The character data extracted from |input_| as a result of the
  // ExtractString() state.
  base::StringPiece extracted_string_;

  // The Expectation object that is currently being processed by the parser.
  // Reset in Start().
  Expectation current_;

  // If DataError() has been called during the course of parsing |current_|.
  // If true, then |current_| will not be emitted to the Delegate.
  bool data_error_;
};

}  // namespace test_expectations

#endif  // BASE_TEST_EXPECTATIONS_PARSER_H_
