# 2.0.1

* Define properties for `global.location` and `global.document` rather than
  setting them. This avoids `TypeError`s on Electron.

# 2.0.0

* Null safety release.

# 1.4.13

* Fixes detection on Electron with `nodeIntegration` disabled

# 1.4.10-1.4.12

Hotfix again for Electron support, quite embarassing at this point. Verified using the awesome Electron Fiddle tool.

## 1.4.9

* Change behavior of Node.js detection that now takes into account:
  - Web workers in browser
  - Electron 

## 1.4.8

* Fixed previous build `1.4.7` when minified file is used.

## 1.4.7

Thanks! @lexaknyazev

* Move `url` module import to Node.js-only block.
* Fix for when we try to load `url` on Node.js but are also using Webpack.

## 1.4.6

* Make `location.href` compatible with Node versions earlier than 10.12.0 again.

## 1.4.5

* Improve `location.href` so that Dart's `Uri.current` works for more paths.
    * Make `location.href` a getter so Dart's `Uri.current` changes along with the
      process's working directory.

* Fixes for Angular 6+ applications using compiled Dart package w/ preamble:
    * Checks for global if it's not polyfilled, then try for window.
    * Don't assume that since we have CommonJS we have process, __dirname, __filename.

## 1.4.4

* Explicitly support Dart 2 stable releases.

## 1.4.3

* Add Node detector for Browserify/Webpack-type environments. (thanks to @lexaknyazev for reporting!)
* Add examples for pub (thanks @bcko!)

## 1.4.2

* Keep `Uri.base` up to date when the current working directory changes.
* Add .dart_tool to gitignore. 

## 1.4.1

* Make sure to replace all backslashes for cwd on Windows, not just the first.

## 1.4.0

* Add __dirname and __filename to exposed globals. Adds ability of exposing more
  globals in the preamble by calling `getPreamble(additionalGlobals: ["__dirname", ...])`.

## 1.3.0

* Add minified versions of the preamble accessible as `lib/preamble.min.js` and
  by calling `getPreamble(minified: true)`.

## 1.2.0

* Prevent encapsulation, `global.self = global` (old) vs.
  `var self = Object.create(global)` (new).

## 1.1.0

* Set `global.location` so that `Uri.base()` works properly on Windows in most
  cases.

* Define `global.exports` so that it's visible to the compiled JS.
