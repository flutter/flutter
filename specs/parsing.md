Parsing
=======

Parsing in Sky is a strict pipeline consisting of five stages:

- decoding, which converts incoming bytes into Unicode characters
  using UTF-8.

- normalising, which manipulates the sequence of characters.

- tokenising, which converts these characters into three kinds of
  tokens: character tokens, start tag tokens, and end tag tokens.
  Character tokens have a single character value. Tag tokens have a
  tag name, and a list of name/value pairs known as attributes.

- token cleanup, which converts sequences of character tokens into
  string tokens, and removes duplicate attributes in tag tokens.

- tree construction, which converts these tokens into a tree of nodes.

Later stages cannot affect earlier stages.

When a sequence of bytes is to be parsed, there is always a defined
_parsing context_, which is either an Application object or a Module
object.


Decoding stage
--------------

To decode a sequence of bytes _bytes_ for parsing, the [utf-8
decode](https://encoding.spec.whatwg.org/#utf-8-decode) algorithm must
be used to transform _bytes_ into a sequence of characters
_characters_.

Note: The decoder will strip a leading BOM if any.

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
tokens must be passed to the token cleanup stage.

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

* '``#``': If the _parsing context_ is not an Application, switch to
  the _failed signature_ state. Otherwise, expect the string
  "``#!mojo mojo:sky``", with _after signature_ as the _success_
  state and _failed signature_ as the _failure_ state.

* '``S``': If the _parsing context_ is not a Module, switch to the
  _failed signature_ state. Otherwise, expect the string
  "``SKY MODULE``", with _after signature_ as the _success_ state,
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


#### **Data** state ####

If the current character is...

* '``<``': Consume the character and switch to the **tag open** state.

* '``&``': Consume the character and switch to the **character
  reference** state, with the _return state_ set to the **data**
  state, and the _emitting operation_ being to emit a character token
  for the given character.

* Anything else: Emit the current input character as a character
  token. Consume the character. Stay in this state.


#### **Script raw data** state ####

If the current character is...

* '``<``': Consume the character and switch to the **script raw
  data: close 1** state.

* Anything else: Emit the current input character as a character
  token. Consume the character. Stay in this state.


#### **Script raw data: close 1** state ####

If the current character is...

* '``/``': Consume the character and switch to the **script raw
  data: close 2** state.

* Anything else: Emit '``<``' character tokens. Switch to the
  **script raw data** state without consuming the character.


#### **Script raw data: close 2** state ####

If the current character is...

* '``s``': Consume the character and switch to the **script raw
  data: close 3** state.

* Anything else: Emit '``</``' character tokens. Switch to the
  **script raw data** state without consuming the character.


#### **Script raw data: close 3** state ####

If the current character is...

* '``c``': Consume the character and switch to the **script raw
  data: close 4** state.

* Anything else: Emit '``</s``' character tokens. Switch to the
  **script raw data** state without consuming the character.


#### **Script raw data: close 4** state ####

If the current character is...

* '``r``': Consume the character and switch to the **script raw
  data: close 5** state.

* Anything else: Emit '``</sc``' character tokens. Switch to the
  **script raw data** state without consuming the character.


#### **Script raw data: close 5** state ####

If the current character is...

* '``i``': Consume the character and switch to the **script raw
  data: close 6** state.

* Anything else: Emit '``</scr``' character tokens. Switch to the
  **script raw data** state without consuming the character.


#### **Script raw data: close 6** state ####

If the current character is...

* '``p``': Consume the character and switch to the **script raw
  data: close 7** state.

* Anything else: Emit '``</scri``' character tokens. Switch to the
  **script raw data** state without consuming the character.


#### **Script raw data: close 7** state ####

If the current character is...

* '``t``': Consume the character and switch to the **script raw
  data: close 8** state.

* Anything else: Emit '``</scrip``' character tokens. Switch to the
  **script raw data** state without consuming the character.


#### **Script raw data: close 8** state ####

If the current character is...

* U+0020, U+000A, '``/``', '``>``': Create an end tag token, and
  let its tag name be the string '``script``'. Switch to the
  **before attribute name** state without consuming the character.

* Anything else: Emit '``</script``' character tokens. Switch to the
  **script raw data** state without consuming the character.


#### **Style raw data** state ####

If the current character is...

* '``<``': Consume the character and switch to the **style raw
  data: close 1** state.

* Anything else: Emit the current input character as a character
  token. Consume the character. Stay in this state.


#### **Style raw data: close 1** state ####

If the current character is...

* '``/``': Consume the character and switch to the **style raw
  data: close 2** state.

* Anything else: Emit '``<``' character tokens. Switch to the
  **style raw data** state without consuming the character.


#### **Style raw data: close 2** state ####

If the current character is...

* '``s``': Consume the character and switch to the **style raw
  data: close 3** state.

* Anything else: Emit '``</``' character tokens. Switch to the
  **style raw data** state without consuming the character.


#### **Style raw data: close 3** state ####

If the current character is...

* '``t``': Consume the character and switch to the **style raw
  data: close 4** state.

* Anything else: Emit '``</s``' character tokens. Switch to the
  **style raw data** state without consuming the character.


#### **Style raw data: close 4** state ####

If the current character is...

* '``y``': Consume the character and switch to the **style raw
  data: close 5** state.

* Anything else: Emit '``</st``' character tokens. Switch to the
  **style raw data** state without consuming the character.


#### **Style raw data: close 5** state ####

If the current character is...

* '``l``': Consume the character and switch to the **style raw
  data: close 6** state.

* Anything else: Emit '``</sty``' character tokens. Switch to the
  **style raw data** state without consuming the character.


#### **Style raw data: close 6** state ####

If the current character is...

* '``e``': Consume the character and switch to the **style raw
  data: close 7** state.

* Anything else: Emit '``</styl``' character tokens. Switch to the
  **style raw data** state without consuming the character.


#### **Style raw data: close 7** state ####

If the current character is...

* U+0020, U+000A, '``/``', '``>``': Create an end tag token, and
  let its tag name be the string '``style``'. Switch to the
  **before attribute name** state without consuming the character.

* Anything else: Emit '``</style``' character tokens. Switch to the
  **style raw data** state without consuming the character.


#### **Tag open** state ####

If the current character is...

* '``!``': Consume the character and switch to the **comment start
  1** state.

* '``/``': Consume the character and switch to the **close tag
  state** state.

* '``>``': Emit character tokens for '``<>``'. Consume the current
  character. Switch to the **data** state.

* '``0``'..'``9``', '``a``'..'``z``', '``A``'..'``Z``',
  '``-``', '``_``', '``.``': Create a start tag token, let its
  tag name be the current character, consume the current character and
  switch to the **tag name** state.

* Anything else: Emit the character token for '``<``'. Switch to the
  **data** state without consuming the current character.


#### **Close tag** state ####

If the current character is...

* '``>``': Emit character tokens for '``</>``'. Consume the current
  character. Switch to the **data** state.

* '``0``'..'``9``', '``a``'..'``z``', '``A``'..'``Z``',
  '``-``', '``_``', '``.``': Create an end tag token, let its
  tag name be the current character, consume the current character and
  switch to the **tag name** state.

* Anything else: Emit the character tokens for '``</``'. Switch to
  the **data** state without consuming the current character.


#### **Tag name** state ####

If the current character is...

* U+0020, U+000A: Consume the current character. Switch to the
  **before attribute name** state.

* '``/``': Consume the current character. Switch to the **void tag**
  state.

* '``>``': Consume the current character. Switch to the **after
  tag** state.

* Anything else: Append the current character to the tag name, and
  consume the current character. Stay in this state.


#### **Void tag** state ####

If the current character is...

* '``>``': Consume the current character. Switch to the **after void
  tag** state.

* Anything else: Switch to the **before attribute name** state without
  consuming the current character.


#### **Before attribute name** state ####

If the current character is...

* U+0020, U+000A: Consume the current character. Stay in this state.

* '``/``': Consume the current character. Switch to the **void tag**
  state.

* '``>``': Consume the current character. Switch to the **after
  tag** state.

* Anything else: Create a new attribute in the tag token, and set its
  name to the current character and its value to the empty string.
  Consume the current character. Switch to the **attribute name**
  state.


#### **Attribute name** state ####

If the current character is...

* U+0020, U+000A: Consume the current character. Switch to the **after
  attribute name** state.

* '``/``': Consume the current character. Switch to the **void tag**
  state.

* '``=``': Consume the current character. Switch to the **before
  attribute value** state.

* '``>``': Consume the current character. Switch to the **after
  tag** state.

* Anything else: Append the current character to the most recently
  added attribute's name, and consume the current character. Stay in
  this state.


#### **After attribute name** state ####

If the current character is...

* U+0020, U+000A: Consume the current character. Stay in this state.

* '``/``': Consume the current character. Switch to the **void tag**
  state.

* '``=``': Consume the current character. Switch to the **before
  attribute value** state.

* '``>``': Consume the current character. Switch to the **after
  tag** state.

* Anything else: Create a new attribute in the tag token, and set its
  name to the current character and its value to the empty string.
  Consume the current character. Switch to the **attribute name**
  state.


#### **Before attribute value** state ####

If the current character is...

* U+0020, U+000A: Consume the current character. Stay in this state.

* '``>``': Consume the current character. Switch to the **after
  tag** state.

* '``'``': Consume the current character. Switch to the
  **single-quoted attribute value** state.

* '``"``': Consume the current character. Switch to the
  **double-quoted attribute value** state.

* Anything else: Switch to the **unquoted attribute value** state
  without consuming the current character.


#### **Single-quoted attribute value** state ####

If the current character is...

* '``'``': Consume the current character. Switch to the
  **before attribute name** state.

* '``&``': Consume the character and switch to the **character
  reference** state, with the _return state_ set to the
  **single-quoted attribute value** state and the _emitting operation_
  being to append the given character to the value of the most
  recently added attribute.

* Anything else: Append the current character to the value of the most
  recently added attribute. Consume the current character. Stay in
  this state.


#### **Double-quoted attribute value** state ####

If the current character is...

* '``"``': Consume the current character. Switch to the
  **before attribute name** state.

* '``&``': Consume the character and switch to the **character
  reference** state, with the _return state_ set to the
  **double-quoted attribute value** state and the _emitting operation_
  being to append the given character to the value of the most
  recently added attribute.

* Anything else: Append the current character to the value of the most
  recently added attribute. Consume the current character. Stay in
  this state.


#### **Unquoted attribute value** state ####

If the current character is...

* U+0020, U+000A: Consume the current character. Switch to the
  **before attribute name** state.

* '``>``': Consume the current character. Switch to the **after tag**
  state.

* '``&``': Consume the character and switch to the **character
  reference** state, with the _return state_ set to the **unquoted
  attribute value** state, and the _emitting operation_ being to
  append the given character to the value of the most recently added
  attribute.

* Anything else: Append the current character to the value of the most
  recently added attribute. Consume the current character. Stay in
  this state.


#### **After tag** state ####

Emit the tag token.

If the tag token was a start tag token and the tag name was
'``script``', then and switch to the **script raw data** state.

If the tag token was a start tag token and the tag name was
'``style``', then and switch to the **style raw data** state.

Otherwise, switch to the **data** state.


#### **After void tag** state ####

Emit the tag token.

If the tag token is a start tag token, emit an end tag token with the
same tag name.

Switch to the **data** state.


#### **Comment start 1** state ####

If the current character is...

* '``-``': Consume the character and switch to the **comment start
  2** state.

* Anything else: Emit character tokens for '``<!``'. Switch to the
  **data** state without consuming the current character.


#### **Comment start 2** state ####

If the current character is...

* '``-``': Consume the character and switch to the **comment**
  state.

* Anything else: Emit character tokens for '``<!-``'. Switch to the
  **data** state without consuming the current character.


#### **Comment** state ####

If the current character is...

* '``-``': Consume the character and switch to the **comment end 1**
  state.

* Anything else: Consume the character and stay in this state.


#### **Comment end 1** state ####

If the current character is...

* '``-``': Consume the character, switch to the **comment end 2**
  state.

* Anything else: Consume the character, and switch to the **comment**
  state.


#### **Comment end 2** state ####

If the current character is...

* '``>``': Consume the character and switch to the **data** state.

* '``-``': Consume the character, but stay in this state.

* Anything else: Consume the character, and switch to the **comment**
  state.


#### **Character reference** state ####

Let _raw value_ be the string '``&``'.

Append the current character to _raw value_.

If the current character is...

* '``#``': Consume the character, and switch to the **numeric
  character reference** state.

* '``0``'..'``9``', '``a``'..'``f``', '``A``'..'``F``': switch to the
  **named character reference** state without consuming the current
  character.

* Anything else: Run the _emitting operation_ for all but the last
  character in _raw value_, and switch to the _return state_ without
  consuming the current character.


#### **Numeric character reference** state ####

Append the current character to _raw value_.

If the current character is...

* '``x``', '``X``': Consume the character and switch to the **before
  hexadecimal numeric character reference** state.

* '``0``'..'``9``': Let _value_ be the numeric value of the
  current character interpreted as a decimal digit, consume the
  character, and switch to the **decimal numeric character reference**
  state.

* Anything else: Run the _emitting operation_ for all but the last
  character in _raw value_, and switch to the _return state_ without
  consuming the current character.


#### **Before hexadecimal numeric character reference** state ####

Append the current character to _raw value_.

If the current character is...

* '``0``'..'``9``', '``a``'..'``f``', '``A``'..'``F``':
  Let _value_ be the numeric value of the current character
  interpreted as a hexadecimal digit, consume the character, and
  switch to the **hexadecimal numeric character reference** state.

* Anything else: Run the _emitting operation_ for all but the last
  character in _raw value_, and switch to the _return state_ without
  consuming the current character.


#### **Hexadecimal numeric character reference** state ####

Append the current character to _raw value_.

If the current character is...

* '``0``'..'``9``', '``a``'..'``f``', '``A``'..'``F``':
  Let _value_ be sixteen times _value_ plus the numeric value of the
  current character interpreted as a hexadecimal digit.

* '``;``': Consume the character. If _value_ is between 0x0001 and
  0x10FFFF inclusive, but is not between 0xD800 and 0xDFFF inclusive,
  run the _emitting operation_ with a unicode character having the
  scalar value _value_; otherwise, run the _emitting operation_ with
  the character U+FFFD. Then, in either case, switch to the _return
  state_.

* Anything else: Run the _emitting operation_ for all but the last
  character in _raw value_, and switch to the _return state_ without
  consuming the current character.


#### **Decimal numeric character reference** state ####

Append the current character to _raw value_.

If the current character is...

* '``0``'..'``9``': Let _value_ be ten times _value_ plus the
  numeric value of the current character interpreted as a decimal
  digit.

* '``;``': Consume the character. If _value_ is between 0x0001 and
  0x10FFFF inclusive, but is not between 0xD800 and 0xDFFF inclusive,
  run the _emitting operation_ with a unicode character having the
  scalar value _value_; otherwise, run the _emitting operation_ with
  the character U+FFFD. Then, in either case, switch to the _return
  state_.

* Anything else: Run the _emitting operation_ for all but the last
  character in _raw value_, and switch to the _return state_ without
  consuming the current character.


#### **Named character reference** state ####

Append the current character to _raw value_.

If the current character is...

* '``;``': Consume the character.
  If the _raw value_ is...

  - '``&amp;``: Emit Run the _emitting operation_ for the character
    '``&``'.

  - '``&apos;``: Emit Run the _emitting operation_ for the character
    '``'``'.

  - '``&gt;``: Emit Run the _emitting operation_ for the character
    '``>``'.

  - '``&lt;``: Emit Run the _emitting operation_ for the character
    '``<``'.

  - '``&quot;``: Emit Run the _emitting operation_ for the character
    '``"``'.

  Then, switch to the _return state_.

* '``0``'..'``9``', '``a``'..'``z``', '``A``'..'``Z``': Consume the
  character and stay in this state.

* Anything else: Run the _emitting operation_ for all but the last
  character in _raw value_, and switch to the _return state_ without
  consuming the current character.


Token cleanup stage
-------------------

Replace each sequence of character tokens with a single string token
whose value is the concatenation of all the characters in the
character tokens.

For each start tag token, remove all but the first name/value pair for
each name (i.e. remove duplicate attributes, keeping only the first
one).

TODO(ianh): maybe sort the attributes?

For each end tag token, remove the attributes entirely.

If the token is a start tag token, notify the JavaScript token stream
callback of the token.

Then, pass the tokens to the tree construction stage.


Tree construction stage
-----------------------

To construct a node tree from a _sequence of tokens_ and a document
_document_:

1. Initialize the _stack of open nodes_ to be _document_.
2. Initialize _imported modules_ to an empty list.
3. Consider each token _token_ in the _sequence of tokens_ in turn, as
   follows. If a token is to be skipped, then jump straight to the
   next token, without doing any more work with the skipped token.
   - If _token_ is a string token,
     1. If the value of the token contains only U+0020 and U+000A
        characters, and there is no ``t`` element on the _stack of
        open nodes_, then skip the token.
     2. Create a text node _node_ whose character data is the value of
        the token.
     3. Append _node_ to the top node in the _stack of open nodes_.
   - If _token_ is a start tag token,
     1. Create an element _node_ with tag name and attributes given by
        the token.
     2. Append _node_ to the top node in the _stack of open nodes_.
     3. Push _node_ onto the top of the _stack of open nodes_.
     4. If _node_ is a ``template`` element, then:
        1. Let _fragment_ be the ``DocumentFragment`` object that the
           ``template`` element uses as its template contents container.
        2. Push _fragment_ onto the top of the _stack of open nodes_.
        If _node_ is an ``import`` element, then:
        1. Let ``url`` be the value of _node_'s ``src`` attribute.
        2. Call ``parsing context``'s ``importModule()`` method,
           passing it ``url``.
        3. Add the returned promise to _imported modules_; if _node_
           has an ``as`` attribute, associate the entry with that
           name.
   - If _token_ is an end tag token:
     1. Let _node_ be the topmost node in the _stack of open nodes_
        whose tag name is the same as the token's tag name, if any. If
        there isn't one, skip this token.
     2. If there's a ``template`` element in the _stack of open
        nodes_ above _node_, then skip this token.
     3. Pop nodes from the _stack of open nodes_ until _node_ has been
        popped.
     4. If _node_'s tag name is ``script``, then yield until _imported
        modules_ contains no entries with unresolved promises, then
        execute the script given by the element's contents, using the
        associated names as appropriate.
4. Yield until _imported modules_ has no promises.
5. Fire a ``load`` event at the _parsing context_ object.
