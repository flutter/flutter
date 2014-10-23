Parsing
=======

Parsing in Sky is a strict pipeline consisting of four stages:

- decoding, which converts incoming bytes into Unicode characters
  using UTF-8

- normalising, which converts certain sequences of characters

- tokenising, which converts these characters into tokens

- tree construction, which converts these tokens into a tree of nodes

Later stages cannot affect earlier stages.

When a sequence of bytes is to be parsed, there is always a defined
_parsing context_, which is either "application" or "module".


Decoding stage
--------------

To decode a sequence of bytes _bytes_ for parsing, the [UTF-8
decoder](https://encoding.spec.whatwg.org/#utf-8-decoder) must be used
to transform _bytes_ into a sequence of characters _characters_.

This sequence must then be passed to the normalisation stage.


Normalisation stage
-------------------

To normalise a sequence of characters, apply the following rules:

* Any U+000D character followed by a U+000A character must be removed.

* Any U+000D character not followed by a U+000A character must be
  converted to a U+000A character.

* Any U+0000 character must be converted to a U+FFFD character.

The converted sequence of characters must then be passed to the
tokenisation stage.


Tokenisation stage
------------------

To tokenise a sequence of characters, a state machine is used.

Initially, the state machine must begin in the **signature** state.

Each character in turn must be processed according to the rules of the
state at the time the character is processed. A character is processed
once it has been _consumed_. This produces a stream of tokens; the
tokens must be passed to the tree construction stage.

When the last character is consumed, the tokeniser ends.


### Expecting a string ###

When the user agent is to _expect a string_, it must run these steps:

1. Let _expectation_ be the string to expect. When this string is
   indexed, the first character has index 0.

2. Assertion: The first character in _expectation_ is the current
   character, and _expectation_ has more than one character.

3. Consume the current character.

4. Let _index_ be 1.

5. Let _success_ and _failure_ be the states specified for success and
   failure respectively.

6. Switch to the **expect a string** state.


### Tokeniser states ###

#### **Signature** state ####

If the current character is...

* '```#```': If the _parsing context_ is not "application", switch to
  the _failed signature_ state. Otherwise, expect the string
  "```#!mojo mojo:sky```", with _after signature_ as the _success_
  state and _failed signature_ as the _failure_ state.

* '```S```': If the _parsing context_ is not "module", switch to the
  _failed signature_ state. Otherwise, expect the string
  "```SKY MODULE```", with _after signature_ as the _success_ state,
  and _failed signature_ as the _failure_ state.

* Anything else: Jump to the **failed signature** state.


#### **Expect a string** state ####

If the current character is not the same as the <i>index</i>th character in
_expectation_, then switch to the _failure_ state.

Otherwise, consume the character, and increase _index_. If _index_ is
now equal to the length of _expectation_, then switch to the _success_
state.


#### **After signature** state ####

If the current character is...

* U+000A: Consume the character and switch to the **data** state.
* U+0020: Consume the character and switch to the **consume rest of
  line** state.
* Anything else: Switch to the **failed signature** state.


#### **Failed signature** state ####

Stop parsing. No tokens are emitted. The file is not a sky file.


#### **Consume rest of line** state ####

If the current character is...

* U+000A: Consume the character and switch to the **data** state.
* Anything else: Consume the character and stay in this state.


### Data state ###

If the current character is...

* '```&```': Consume the character and switch to the **character
  reference** state.

* '```<```': Consume the character and switch to the **tag open** state.

* Anything else: Emit the current input character as a character
  token. Consume the character. Stay in this state.


TODO(ianh): Add the remaining tokenizer states.

TOOD(ianh): &lt;script>, &lt;style>

Tree construction
-----------------

To construct a node tree from a _sequence of tokens_ and a document _document_:

1. Initialize the _stack of open nodes_ to be _document_.
2. Consider each token _token_ in the _sequence of tokens_ in turn.
   - If _token_ is a text token,
     1. Create a text node _node_ with character data _token.data_.
     2. Append _node_ to the top node in the _stack of open nodes_.
   - If _token_ is a start tag token,
     1. Create an element _node_ with tag name _token.tagName_ and attributes
        _token.attributes_.
     2. Append _node_ to the top node in the _stack of open nodes_.
     3. If the _token.selfClosing_ flag is not set, push _node_ onto the
        _stack of open elements_.
     4. If _token.tagName_ is _script_, TODO: Execute the script.
   - If _token_ is an end tag token,
     1. If the _stack of open nodes_ contains a node whose _tagName_ is
        _token.tagName_,
        - Pop nodes from the _stack of open nodes_ until a node with
          a _tagName_ equal to _token.tagName_ has been popped.
     2. Otherwise, ignore _token_.
   - If _token_ is a comment token,
     1. Ignore _token_.
   - If _token_ is an EOF token,
     1. Pop all the nodes from the _stack of open nodes_.
     2. Signal _document_ that parsing is complete.

TODO(ianh): &lt;template>, &lt;t>
