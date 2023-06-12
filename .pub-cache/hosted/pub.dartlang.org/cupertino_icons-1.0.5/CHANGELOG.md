## 1.0.5

* Updates README to reference correct URL.

## 1.0.4

* Updates README to link to API docs.

## 1.0.3
* Source moved to flutter/packages.

## 1.0.2
* Vertically center align the glyphs in the .ttf.

## 1.0.1+2
* Update README images

## 1.0.1+1
* Add README note that version 1.0.0 should be used until nnbd is on stable.

## 1.0.1
* Add Dart SDK constraint to make it compatible with null safety.

## 1.0.0
* Move to 1.0.0 and remove SDK version constraint since the font's codepoints
  are now fully compatible and missing glyphs are backfilled.

## 1.0.0-dev.4
* dev.3's codepoints were off by 1. The previous "car" glyph was added but
  was not manually mapped to its previous codepoint.

## 1.0.0-dev.3
* Serve icons map on GitHub Pages
* Auto width everything since not all SVGs have the same canvas.
* Add back missing icons from 0.1.3 not part of the new iOS icon repertoire
  to preserve backward compatibility.
* Duplicate codepoints for merged icons so they're addressable from different
  CupertinoIcons that have now merged.

## 1.0.0-dev.2
* Add back 2 thicker chevrons for back/forward navigation.

## 1.0.0-dev.1
* Updated font content to the iOS 13 system icons repertoire for use on Flutter
SDK versions 1.22+.

## 0.1.3

* Updated 'chevron left' and 'chevron right' icons to match San Francisco font.

## 0.1.2

* Fix linter warning for missing lib/ folder.
* Constrain to Dart 2.

## 0.1.1

* Initial release.
