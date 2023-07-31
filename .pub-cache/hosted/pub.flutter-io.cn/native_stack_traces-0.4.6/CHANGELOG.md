## 0.4.6

- Upgrade to `package:lints` 2.0.
- Populate the pubspec `repository` field.

## 0.4.5

- Handle stack traces larger than 100 entries.

## 0.4.5-dev

- Require Dart >= 2.14

## 0.4.4

- Added handling of dynamic tables for testing.

## 0.4.3

- Exported some more of the ELF utilities for use in Dart tests.

## 0.4.2

- When decoding a stack trace, frames corresponding to the functions
  with DW_AT_artificial DWARF attribute are now omitted from the symbolized
  stack traces. This is needed because Dart VM no longer omits invisible
  functions from binary stack traces in certain cases.

## 0.4.1

- Exported some ELF utilities in lib/elf.dart for use in Dart tests.

## 0.4.0

- Stable null safe version of package.

## 0.4.0-nullsafety

- Unstable null safe version of package.

## 0.3.8

- Support columns when present in line number programs.

## 0.3.7

- Added buildId accessor for retrieving GNU build IDs from DWARF files that
  include them.

## 0.3.6

- Adjusts RegExp for stack trace header line to be more flexible in what it
  permits to allow additional information to be added in the Dart VM.

## 0.3.5

- Use virtual addresses in non-symbolic stack frames as a fallback if we cannot
  retrieve an appropriate offset from the instructions section otherwise.

## 0.3.4

- Decoded Dart calls are now never considered internal, only VM stub calls.
  This is due to a concurrent change in the Dart VM that no longer prints
  non-symbolic frames for functions considered invisible, which matches the
  symbolic frame printer and removes the need for the decoder to guess which
  frames should be hidden.

  This package still works on earlier versions of Dart, so the dependencies have
  not changed. However, it may print more frame information than expected when
  decoding stack frames from a Dart VM that does not include this change to
  non-symbolic stack printing.

## 0.3.3

- No externally visible changes.

## 0.3.2

- The `find` command can now look up addresses given as offsets from static
  symbols, not just hexadecimal virtual or absolute addresses.
- Integer inputs (addresses or offsets) without an '0x' prefix or hexadecimal
  digits will now be parsed as decimal unless the `-x`/`--force_hexadecimal`
  flag is used.

## 0.3.1

- Uses dynamic symbol information embedded in stack frame lines when available.

## 0.3.0

- Adds handling of virtual addresses within stub code payloads.

## 0.2.2

- Finds instruction sections by the dynamic symbols the Dart VM creates instead
  of assuming there are two text sections.

## 0.2.1

- Added static method `Dwarf.fromBuffer`.

## 0.2.0

- API and documentation cleanups

## 0.1.0

- Initial release
