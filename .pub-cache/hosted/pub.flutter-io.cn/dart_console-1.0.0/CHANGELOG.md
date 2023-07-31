## 1.0.0

- Support sound null safety and latest win32 and ffi dependencies.

## 0.6.2

- Bumped minver of win32

## 0.6.1

- Update to latest win32 package
- Add scrollback ignore option (thanks @averynortonsmith)
- Fix readme (thanks @md-weber)

## 0.6.0

- Shift all FFI code to the new [win32](https://pub.dev/packages/win32) package

## 0.5.0

- Add `writeErrorLine` function which writes to stderr
- *BREAKING*: Automatically print a new line to the console after every
  `readLine` input
- *BREAKING*: `readLine` now returns a null string, rather than an empty
  string, when Ctrl+Break or Escape are pressed.
- Add Game of Life example (thanks to @erf)

## 0.4.0

- Update to new FFI API

## 0.3.0

- Add support for Windows consoles that recognize ANSI escape sequences

## 0.2.0

- Add `readline` function and escape character support

## 0.1.0

- Initial version
