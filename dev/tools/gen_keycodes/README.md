## Keycode Generator

This directory contains a keycode generator that can generate Dart code for
the `LogicalKeyboardKey` and `PhysicalKeyboardKey` classes.

It generates multiple files across Flutter.  For framework, it generates

* [`keyboard_key.dart`](../../../packages/flutter/lib/src/services/keyboard_key.dart), which contains the definition and list of logical keys and physical keys; and
* [`keyboard_maps.dart`](../../../packages/flutter/lib/src/services/keyboard_maps.dart), which contains platform-specific immutable maps used for the `RawKeyboard` API.

For engine, it generates one key mapping file for each platform.

It draws information from various source bases, including online
repositories, and manual mapping in the `data` subdirectory.  It incorporates
this information into a giant list of physical keys
([`physical_key_data.json`](data/physical_key_data.json)),
and another for logical keys
([`logical_key_data.json`](data/logical_key_data.json)).
The two files are checked in, and can be used as the data source next time so that
output files can be generated without the Internet.

## Running the tool

The tool can be run based on the existing database. To do this, run:

```bash
/PATH/TO/ROOT/bin/gen_keycodes
```

The tool can also be run by rebuilding the database by drawing online information
anew before generating the files. To do this, run:

```bash
/PATH/TO/ROOT/bin/gen_keycodes --collect
```

This will generate `physical_key_data.json` and `logical_key_data.json`. These
files should be checked in.

By default this tool assumes that the gclient directory for flutter/engine
and the root for the flutter/flutter are placed at the same folder.  If not,
use `--engine-root=/ENGINE/GCLIENT/ROOT` to specify the engine root.

Other options can be found using `--help`.

## Key Code ID Scheme

To provide logical keys with unique ID codes, Flutter uses a scheme
to assign logical keycodes which keeps us out of the business of minting new
codes ourselves. This only applies to logical key codes: Flutter's
physical key codes are just defined as USB HID codes.

The logical codes are meant to be opaque to the user, and should never be
unpacked for meaning, since the coding scheme could change at any time and the
meaning is likely to be retrievable more reliably and correctly from
the API.

However, if you are porting Flutter to a new platform, you should follow the
following guidelines for specifying logical key codes.

The logical key code is a 37-bit integer in a namespace that we control and
define. It has values in the following ranges.

- **0x00 0000 0000 - 0x0 0010 FFFF**: For keys that generate Unicode
  characters when pressed (this includes dead keys, but not e.g. function keys
  or shift keys), the logical key code is the Unicode code point corresponding
  to the representation of the key in the current keyboard mapping. The
  Unicode code point might not match the string that is generated for
  an unshifted keypress of that key, for example, we would use U+0034 for the
  “4 \$” key in the US layout, and also the “4 ;” key in the Russian layout,
  and also, maybe less intuitively, for the “' 4 {“ in French layout (wherein
  the latter case, an unshifted press gets you a ', not a 4). Similarly, the Q
  key in the US layout outputs a q in normal usage, but its code would be 0x0
  0000 0051 (U+00051 being the code for the uppercase Q).

- **0x01 0000 0000 - 0x01 FFFF FFFF**: For keys that are defined by the [USB HID
  standard](https://www.usb.org/sites/default/files/documents/hut1_12v2.pdf),
  the key code consists of the 32 bit USB extended usage code. For
  example, the Enter key would have code 0x01 0007 0028. Only keys that fall
  into collections "Keyboard", "Keypad", and "Tablet PC System Controls" are
  considered for this API; for example, a mixing desk with multiple
  collections of volume controls would not be exposed via DOWN and UP events,
  nor would a mouse, joystick, or golf simulator control.

- **0x02 0000 0000 - 0xFF FFFF FFFF**: For keys that aren't defined in USB at the
  time of implementation, but that we need to support. For example, if Flutter
  were ever ported to the Symbolics LM-2, the "thumb up" key might be given
  the code 0x14 0000 0001, where 0x14 is defined as the “Symbolics” platform
  range. Where possible, we will use specific subranges of this space to reuse
  keys from other platforms. When this is not possible, the prefix 0xFF is
  reserved for “Custom” codes. Each platform from which we take codes will get
  a unique prefix in the range 0x2-0xFE. If multiple systems define keys with
  the same usage (not the same number), then the value with the lowest prefix
  is used as the defining code.

  Prefixes will be:

  | Code | Platform |
  | ---- | -------- |
  | 0x02 | Android  |
  | 0x03 | Fuchsia  |
  | 0x04 | iOS      |
  | 0x05 | macOS    |
  | 0x06 | Linux    |
  | 0x07 | Windows  |
  | 0x08 | Web      |
  | 0xFF | Custom   |

  Further ranges will be added as platforms are added. The platform prefix
  does not define the platform it is used on, it is just the platform that
  decides what the value is: the codes are mapped to the same value on all
  platforms.

- **0x100 0000 0000 - 0x1FF FFFF FFFF**: For keys that have no definition yet in
  Flutter, but that are encountered in the field, this range is used to embed
  the platform-specific keycode in an ID that must be tested for in a
  platform-specific way. For instance, if a platform generates a new USB
  HID code 0x07 00E8 that a Flutter app wasn’t compiled with, then it would
  appear in the app as 0x100 0007 00E8, and the app could test against that
  code. Yes, this also means that once they recompile with a version of
  Flutter that supports this new HID code, apps looking for this code will
  break. This situation is only meant to provide a fallback ability for apps
  to handle esoteric codes that their version of Flutter doesn’t support yet.
  The prefix for this code is the platform prefix from the previous sections,
  plus 0x100.

- **0x200 0000 0000 - 0x2FF FFFF FFFF**: For pseudo-keys which represent
  combinations of other keys, and conceptual keys which don't have a physical
  representation. This is where things like key synonyms are defined (e.g.
  "shiftLeft" is a synonym for "shift": the "shift" key is a pseudo-key
  representing either the left or right shift key).

**This is intended to get us out of the business of defining key codes where
possible.** We still have to have mapping tables, but at least the actual minting
of codes is deferred to other organizations to a large extent. Coming up with a
code is a mechanical process consisting of just picking the lowest number code
possible that matches the semantic meaning of the key according to the
definitions above.

Here are some examples:

For example, on a French keyboard layout, pressing CAPS LOCK then pressing
SHIFT + Y would generate the following sequence:

DOWN, code 0x0100070039. (CAPS LOCK DOWN)<br>
UP, code 0x0100070039. (CAPS LOCK UP)<br>
DOWN, code 0x01000700E1 (LEFT SHIFT DOWN)<br>
DOWN, code 0x0000000059, string U+00059 (Y DOWN)<br>
UP, code 0x0000000059 (Y UP)<br>
UP, code 0x01000700E1 (LEFT SHIFT UP)<br>

Here's another example. On a German keyboard layout, you press ^e (the ^ key is
at the top left of the keyboard and is a dead key) to produce an “ê”:

DOWN, code 0x0000000302 (CIRCUMFLEX DOWN) It produces no string, because it's a dead
key. The key code is for "Combining circumflex accent U+0302" in Unicode.<br>
UP, code 0x0000000302 (CIRCUMFLEX UP)<br>
DOWN, code 0x0000000065, string U+000EA (Unicode for ê‬) (E DOWN).<br>
UP, code 0x0000000065. (E UP).<br>

It is an important point that even though we’re representing many keys with USB
HID codes, these are not necessarily the same HID codes produced by the hardware
and presented to the driver, since on most platforms we have to map the platform
representation back to an HID code because we don’t have access to the original
HID code. USB HID is simply a conveniently well-defined standard that includes
many of the keys we would want.
