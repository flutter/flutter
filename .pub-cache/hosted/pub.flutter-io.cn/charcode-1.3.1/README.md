[![Build Status](https://github.com/lrhn/charcode/workflows/Dart%20CI/badge.svg)](https://github.com/lrhn/charcode/actions?query=workflow%3A"Dart+CI")
[![Pub](https://img.shields.io/pub/v/charcode.svg)](https://pub.dev/packages/charcode)

# Character code constants

This package can *generate* constant symbolic names for character codes.

The constants can used when working directly with characters as integers,
to make the code more readable: `if (firstChar == $A) ...` vs
`if (firstChar == 0x41 /*A*/)`.

# Pre-defined constants

The package also provides a set of pre-defined constants covering all
ASCII characters and all HTML entities.

Those constants are intended for use while developing
a new package or application. When development is done,
it's recommended that you generate a file for yourself,
containing only the constants that you actually use,
and include that in your project.

## Usage

To generate a set of constants, run the `charcode` application with a list
of the characters you want to reference.

Example:
```bash
dart run charcode -o lib/src/charcodes.dart "09.e\-ftn{}[],:"
```

Run `dart run charcode --help` to see other options.

After switching to the generated constants file, you can, and should,
remove your dependency on this package, or keep it as a dev-dependency
in case you want to generate the file again.

To use the pre-defined constants, import either the ASCII or the HTML library
```dart
import "package:charcode/ascii.dart";
// or
import "package:charcode/html_entity.dart";
```
or import both libraries using the combined `charcode.dart` library:
```dart
import "package:charcode/charcode.dart";
```
(Importing both libraries directly causes some conflicting names
to be inaccessible.)

## Naming

The character names are preceded by a `$` to avoid conflicting with other
variables, due to their short and common names (for example "$i").

Characters that are valid in a Dart identifier directly follow the `$`.
Examples: `$_`, `$a`, `$B` and `$3`. Other characters are given symbolic names.

The names of letters are lower-case for lower-case letters (`$sigma` for `σ`),
and mixed- or upper-case for upper-case letters (`$Sigma` for `Σ`).
The names of symbols and punctuation are all lower-case or camelCase,
and omit suffixes like "sign", "symbol" and "mark".
Examples: `$plus`, `$exclamation`, `$tilde`, `$doubleQuote`.

The `ascii.dart` library defines a symbolic name for each ASCII character.
Some characters have more than one name. For example the common name `$tab`
and the official abbreviation `$ht` for the horizontal tab.

The `html_entity.dart` library defines a constant for each HTML 4.01 character
entity using their standard entity abbreviation, including case.
Examples: `$nbsp` for `&nbps;`, `$aring` for the lower-case `&aring;`
and `$Aring` for the upper-case `&Aring;`.

The HTML entities include all characters in the Latin-1 code page, Greek
letters and some mathematical symbols.

The `charcode.dart` library exports both `ascii.dart` and
`html_entity.dart`. Where both libraries define the same name,
the HTML entity name is preferred.

## Rationale

The Dart language doesn't have character literals.
If that ever changes, this package will become irrelevant.
Until then, this package can be used for the most common characters.
See [request for character literals](https://dartbug.com/4415).
