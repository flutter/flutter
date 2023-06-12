[![Build Status](https://github.com/dart-lang/characters/workflows/Dart%20CI/badge.svg)](https://github.com/dart-lang/characters/actions?query=workflow%3A"Dart+CI"+branch%3Amaster)
[![pub package](https://img.shields.io/pub/v/characters.svg)](https://pub.dev/packages/characters)
[![package publisher](https://img.shields.io/pub/publisher/characters.svg)](https://pub.dev/packages/characters/publisher)

[`Characters`][Characters] are strings viewed as
sequences of **user-perceived character**s,
also known as [Unicode (extended) grapheme clusters][Grapheme Clusters].

The [`Characters`][Characters] class allows access to
the individual characters of a string,
and a way to navigate back and forth between them
using a [`CharacterRange`][CharacterRange].

## Unicode characters and representations

There is no such thing as plain text.

Computers only know numbers,
so any "text" on a computer is represented by numbers,
which are again stored as bytes in memory.

The meaning of those bytes are provided by layers of interpretation,
building up to the *glyph*s that the computer displays on the screen.

| Abstraction           | Dart Type                                                    | Usage                                                        | Example                                                      |
| --------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| Bytes                 | [`ByteBuffer`][ByteBuffer],<br />[`Uint8List`][Uint8List]                           | Physical layout: Memory or network communication.            | `file.readAsBytesSync()`                                     |
| [Code units][]        | [`Uint8List`][Uint8List] (UTF&#x2011;8)<br />[`Uint16List`][Uint16List], [`String`][String] (UTF&#x2011;16) | Standard formats for<br /> encoding code points in memory.<br />Stored in memory using one (UTF&#x2011;8) or more (UTF&#x2011;16) bytes. One or more code units encode a code point. | `string.codeUnits`<br />`string.codeUnitAt(index)`<br />`utf8.encode(string)` |
| [Code points][]       | [`Runes`][Runes]                                                    | The Unicode unit of meaning.                                 | `string.runes`                                               |
| [Grapheme Clusters][] | [`Characters`][Characters]                                               | Human perceived character. One or more code points.          | `string.characters`                                          |
| [Glyphs][]            |                                                              | Visual rendering of grapheme clusters.                       | `print(string)`                                              |

A Dart `String` is a sequence of UTF-16 code units,
just like strings in JavaScript and Java.
The runtime system decides on the underlying physical representation.

That makes plain strings inadequate
when needing to manipulate the text that a user is viewing, or entering,
because string operations are not working at the grapheme cluster level.

For example, to abbreviate a text to, say, the 15 first characters or glyphs,
a string like "A 🇬🇧 text in English"
should abbreviate to "A 🇬🇧 text in Eng&mldr; when counting characters,
but will become "A 🇬🇧 text in &mldr;"
if counting code units using [`String`][String] operations.

Whenever you need to manipulate strings at the character level,
you should be using the [`Characters`][Characters] type,
not the methods of the [`String`][String] class.

## The Characters class

The [`Characters`][Characters] class exposes a string
as a sequence of grapheme clusters.
All operations on [`Characters`][Characters] operate
on entire grapheme clusters,
so it removes the risk of splitting combined characters or emojis
that are inherent in the code-unit based [`String`][String] operations.

You can get a [`Characters`][Characters] object for a string using either
the constructor [`Characters(string)`][Characters constructor]
or the extension getter `string.characters`.

At its core, the class is an [`Iterable<String>`][Iterable]
where the element strings are single grapheme clusters.
This allows sequential access to the individual grapheme clusters
of the original string.

On top of that, there are operations mirroring the operations
of [`String`][String] that are not index, code-unit or code-point based,
like [`startsWith`][Characters.startsWith]
or [`replaceAll`][Characters.replaceAll].
There are some differences between these and the [`String`][String] operations.
For example the replace methods only accept characters as pattern.
Regular expressions are not grapheme cluster aware,
so they cannot be used safely on a sequence of characters.

Grapheme clusters have varying length in the underlying representation,
so operations on a [`Characters`][Characters] sequence cannot be index based.
Instead the [`CharacterRange`][CharacterRange] *iterator*
provided by [`Characters.iterator`][Characters.iterator]
has been greatly enhanced.
It can move both forwards and backwards,
and it can span a *range* of grapheme cluster.
Most operations that can be performed on a full [`Characters`][Characters]
can also be performed on the grapheme clusters
in the range of a [`CharacterRange`][CharacterRange].
The range can be contracted, expanded or moved in various ways,
not restricted to using [`moveNext`][CharacterRange.moveNext],
to move to the next grapheme cluster.

Example:

```dart
// Using String indices.
String firstTagString(String source) {
  var start = string.indexOf("<") + 1;
  if (start > 0) {
    var end = string.indexOf(">", start);
    if (end >= 0) {
	    return string.substring(start, end);
    }
  }
  return null;
}

// Using CharacterRange operations.
Characters firstTagCharacters(Characters source) {
  var range = source.findFirst("<".characters);
  if (range != null && range.moveUntil(">".characters)) {
    return range.currentCharacters;
  }
  return null;
}
```

[ByteBuffer]: https://api.dart.dev/stable/2.0.0/dart-typed_data/ByteBuffer-class.html	"ByteBuffer class"
[CharacterRange.moveNext]:  https://pub.dev/documentation/characters/latest/characters/CharacterRange/moveNext.html "CharacterRange.moveNext"
[CharacterRange]:  https://pub.dev/documentation/characters/latest/characters/CharacterRange-class.html "CharacterRange class"
[Characters constructor]: https://pub.dev/documentation/characters/latest/characters/Characters/Characters.html "Characters constructor"
[Characters.iterator]: https://pub.dev/documentation/characters/latest/characters/Characters/iterator.html "CharactersRange get iterator"
[Characters.replaceAll]: https://pub.dev/documentation/characters/latest/characters/Characters/replaceAll.html "Characters.replaceAlle"
[Characters.startsWith]: https://pub.dev/documentation/characters/latest/characters/Characters/startsWith.html "Characters.startsWith"
[Characters]: https://pub.dev/documentation/characters/latest/characters/Characters-class.html "Characters class"
[Code Points]: https://unicode.org/glossary/#code_point "Unicode Code Point"
[Code Units]: https://unicode.org/glossary/#code_unit "Unicode Code Units"
[Glyphs]: https://unicode.org/glossary/#glyph "Unicode Glyphs"
[Grapheme Clusters]: https://unicode.org/reports/tr29/#Grapheme_Cluster_Boundaries "Unicode (Extended) Grapheme Cluster"
[Iterable]: https://api.dart.dev/stable/2.0.0/dart-core/Iterable-class.html	"Iterable class"
[Runes]: https://api.dart.dev/stable/2.0.0/dart-core/Runes-class.html	"Runes class"
[String]: https://api.dart.dev/stable/2.0.0/dart-core/String-class.html	"String class"
[Uint16List]: https://api.dart.dev/stable/2.0.0/dart-typed_data/Uint16List-class.html	"Uint16List class"
[Uint8List]: https://api.dart.dev/stable/2.0.0/dart-typed_data/Uint8List-class.html	"Uint8List class"
