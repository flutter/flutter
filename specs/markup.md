Sky Markup: Syntax
==================

A Sky file must consist of the following components:

 1. If the file is intended to be a top-level Sky application, the
    string "```#!mojo mojo:sky```" followed by a U+0020, U+000A or
    U+000D character.

    If the file is intended to be a module, then the string "SKY", a
    U+0020 (space) character, the string "MODULE", and a U+0020,
    U+000A or U+000D character.

    These signatures make it more difficult to e.g. embed some Sky
    markup into a PNG and then cause someone to import that image as a
    module.

 2. Zero or more of the following, in any order:
     - comments
     - text
     - escapes
     - elements

Sky files must be encoded using UTF-8.

A file that doesn't begin with the "```#!mojo mojo:sky```" signature
isn't a Sky application file. For example:

    #!mojo https://example.com/runtimes/sky.asmjs
    Hello World

...is not a Sky file, even if ```https://example.com/runtimes/sky.asmjs```
is an implementation of the Sky runtime: it's just a file intended
specifically for that runtime.

The ```mojo:sky``` URL represents the generic Sky runtime provided by
your Mojo runtime vendor.


Comments
--------

Comments start with the sequence "```<!--```" and end with the
sequence "```-->```", where the start and end hyphens don't overlap.
In between these characters, any sequence of characters is allowed
except "```-->```", which terminates the comment. Comments cannot,
therefore, be nested.


Text
----

Any sequence of Unicode characters other than ```<```, ```&```, and
U+0000.


Escapes
-------

There are three kinds of escapes:

### Hex

They begin with the sequence ```&#x``` or ```&#X```, followed by a
sequence of hex characters (lowercase or uppercase), followed by a
semicolon. The number 0 is not allowed.

### Decimal

They begin with the sequence ```&#``` or ```&#```, followed by a
sequence of decimal characters, followed by a semicolon. The number 0
is not allowed.

### Named

They begin with the sequence ```&```, followed by any characters,
followed by a semicolon.

The following names work:

| Name | Character | Unicode |
| ---- | --------- | ------- |
| `lt` | `<` | U+003C LESS-THAN SIGN character |
| `gt` | `>` | U+003E GREATER-THAN SIGN character |
| `amp` | `&` | U+0026 AMPERSAND character |
| `apos` | `'` | U+0027 APOSTROPHE character |
| `quot` | `"` | U+0022 QUOTATION MARK character |


Elements
--------

An element consists of the following:

1. ```<```
2. Tag name: A sequence of characters other than ```/```, ```>```,
   U+0020, U+000A, U+000D (whitespace).
3. Zero or more of the following:
   1. One or more U+0020, U+000A, U+000D (whitespace).
   2. Attribute name: A sequence of characters other than ```/```,
      ```=```, ```>```, U+0020, U+000A, U+000D (whitespace).
   3. Optionally:
      1. ```=```
      2. Attribute value: Either:
         - ```'``` followed by attribute text other than ```'```
           followed by a terminating ```'```.
         - ```"``` followed by attribute text other than ```'```
           followed by a terminating ```"```.
         - attribute text other than ```/```, ```>```,
           U+0020, U+000A, U+000D (whitespace).
         "Attribute text" is escapes or any unicode characters other
         than U+0000.
4. Either:
   - For a void element:
     1. ```/```, indicating an empty element.
     2. ```>```
   - For a non-void element:
     2. ```>```
     3. The element's contents:
        - If the element's tag name is ```script```, then any sequence of
          characters other than U+0000, but there must not be the
          substring ```</script```. The sequence must be valid sky script.
        - If the element's tag name is ```style```, then any sequence of
          characters other than U+0000, but there must not be the
          substring ```</style```. The sequence must be valid sky style.
        - Otherwise, zero or more of the following, in any order:
          - comments
          - text
          - escapes
          - elements
     4. Finally, the end tag, which may be omitted if the element's tag
        name is not ```template```, consisting of:
        1. ```<```
        2. ```/```
        3. Same sequence of characters as "tag name" above.
        4. ```>```


Sky Markup: Elements
====================

The Sky language consists of very few elements, since it is expected
that everything of note would be provided by frameworks.

<import src="foo.sky">
 - Downloads and imports foo.sky in the background.

<import src="foo.sky" as="foo">
 - Downloads and imports foo.sky in the background, using "foo" as its
   local name (see <script>).

<template>
 - The contents of the element aren't placed in the Element itself.
   They are instead placed into a DocumentFragment that you can obtain
   from the element's "content" attribute.

<script>
 - Blocks until all previous imports have been loaded, then runs the
   script, with either 'module' or 'application' as the first
   argument, the exports of any imports that have "as" attributes at
   this time passed in as subsequent arguments, and with "this" set to
   null.
   TODO(ianh): could be something other than null?

<style>
 - Adds the contents to the document's styles.

<content>
<content select="...">
 - In a shadow tree, acts as an insertion point for distributed nodes.
   The select="" attribute gives the selector to use to pick the nodes
   to place in this insertion point; it defaults to everything.

<shadow>
 - In a shadow tree, acts as an insertion point for older shadow trees.

<img src="foo.bin">
 - Sky fetches the bits for foo.bin, looks for a decoder for those
   bits, and renders the bits that the decoder returns.

<iframe src="foo.bin">
 - Sky tells mojo to open an application for foo.bin, and hands that
   application a view so that the application can render appropriately.

<t>
 - Within a <t> section, whitespace is not trimmed from the start and
   end of text nodes by the parser.
   TOOD(ianh): figure out if the authoring aesthetics of this are ok

<a href="foo.bin">
 - A widget that, when invoked, causes mojo to open a new application
   for "foo.bin".

<title>
 - Sets the contents as the document's title (as provided by Sky to
   the view manager). (Actually just ensures that any time the element
   is mutated, theTitleElement.ownerScope.ownerDocument.title is set
   to the element's contents.)


Sky Markup: Global Attributes
=============================

The following attributes are available on all elements:

id="" (any value)
class="" (any value, space-separated)
style="" (declaration part of a Sky style rule)
lang="" (language code)
dir="" (ltr or rtl only)

contenteditable="" (subject to future developments)
tabindex="" (subject to future developments)
