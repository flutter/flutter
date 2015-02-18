Fonts
=====

Mojo has a font service, which takes a URL and hands back glyphs.

Sky has an API that takes a URL, a name, and hands back a promise
which, when resolved, indicates that Sky has now associated that font
name with the relevant glyphs (by calling the Mojo service).

The text part of Sky's drawing API accepts a list of font names, and
uses those to draw the relevant glyphs, falling back through the
provided fonts, then all the loaded fonts, until a glyph is found.

By default, three fonts are loaded, with the names 'serif',
'sans-serif', and 'monospace'. They have good Unicode coverage.

TODO(ianh): Actually define these APIs and so on.
