## 3.0.1 - 2022-05-23
### Changed
- Improve asset manifest loading errors 
- Improve testing guidance

## 3.0.0 - 2022-05-20
### Added
- Cache busting for font updates
- Support for removing fonts
- `Akaya Kanadaka`
- `Akshar`
- `Alumni Sans Inline One`
- `Anek Bangla`
- `Anek Devanagari`
- `Anek Gujarati`
- `Anek Gurmukhi`
- `Anek Kannada`
- `Anek Latin`
- `Anek Malayalam`
- `Anek Odia`
- `Anek Tamil`
- `Anek Telugu`
- `Angkor`
- `Antonio`
- `Anybody`
- `Asap Condensed`
- `BIZ UDGothic`
- `BIZ UDMincho`
- `BIZ UDPGothic`
- `BIZ UDPMincho`
- `Babylonica`
- `Ballet`
- `Battambang`
- `Bayon`
- `Beau Rivage`
- `Benne`
- `BhuTuka Expanded One`
- `Bodoni Moda`
- `Bokor`
- `Chenla`
- `Content`
- `Dangrek`
- `Familjen Grotesk`
- `Fasthand`
- `Fredoka`
- `Freehand`
- `Grape Nuts`
- `Hanuman`
- `Hubballi`
- `Imbue`
- `Imperial Script`
- `Ingrid Darling`
- `Inspiration`
- `Island Moments`
- `Karantina`
- `Khmer`
- `Kiwi Maru`
- `Kolker Brush`
- `Koulen`
- `Lavishly Yours`
- `League Gothic`
- `League Spartan`
- `Libre Barcode EAN13 Text`
- `Libre Bodoni`
- `Licorice`
- `Love Light`
- `Luxurious Roman`
- `Mea Culpa`
- `Metal`
- `Moo Lah Lah`
- `Moon Dance`
- `Moul`
- `Moulpali`
- `Ms Madi`
- `My Soul`
- `Neonderthaw`
- `Newsreader`
- `Nokora`
- `Noto Emoji`
- `Ole`
- `Oooh Baby`
- `Orelega One`
- `Plus Jakarta Sans`
- `Preahvihear`
- `Qwitcher Grypen`
- `Radio Canada`
- `Roboto Flex`
- `Roboto Serif`
- `Rubik Bubbles`
- `Rubik Glitch`
- `Rubik Microbe`
- `Rubik Moonrocks`
- `Rubik Puddles`
- `Rubik Wet Paint`
- `Send Flowers`
- `Siemreap`
- `Smooch Sans`
- `Source Serif 4`
- `Spline Sans`
- `Square Peg`
- `Suwannaphum`
- `Tapestry`
- `Taprom`
- `Texturina`
- `The Nautigal`
- `Truculenta`
- `Twinkle Star`
- `Updock`
- `Vazirmatn`
- `Vujahday Script`
- `Water Brush`
- `Waterfall`
- `Whisper`
- `Zen Dots`

### Changed
- Complete null safety migration
- Improve documentation
- Improve support around HTTP fetching errors

### Removed
- `Amatica SC`
- `Andada`
- `Baloo`
- `Baloo Bhai`
- `Baloo Bhaijaan`
- `Baloo Bhaina`
- `Baloo Chettan`
- `Baloo Da`
- `Baloo Paaji`
- `Baloo Tamma`
- `Baloo Tammudu`
- `Baloo Thambi`
- `Be Vietnam`
- `Crimson Text`
- `Droid Sans`
- `Droid Sans Mono`
- `Droid Serif`
- `Muli`
- `Noto Color Emoji Compat`
- `Pushster`
- `Scheherazade`
- `Spartan`

## 2.3.3 - 2022-05-19
### Changed
- Updated the value of the pubspec 'repository' field

## 2.3.2 - 2022-04-25
### Added
- Add warning on macOS about entitlements

## 2.3.1 - 2022-02-04
### Added
- Introduce Flutter SDK constraint minimum of 2.10

## 2.3.0 - 2022-02-04
### Changed
- Update 2018 text style names to 2021 text style names (`display`, `headline`, `title`, `body`, `label` X `large`, `medium`, `small`)

## 2.2.0 - 2021-12-29
### Changed
- Added the latest fonts from fonts.google.com

## 2.1.1 - 2021-12-07
### Changed
- Migrated from `pedantic` to `flutter_lints`

## 2.1.0 - 2021-05-14
### Changed
- Added the latest fonts from fonts.google.com

## 2.0.0 - 2021-02-26
### Changed
- Migrated the main library to null safety
- Require Dart 2.12 or greater

## 1.1.2 - 2021-01-25
### Changed
- Bump dependency constraints for null safety

## 1.1.1 - 2020-10-02
### Changed
- Use conditional imports to separate out web from destkop + mobile `file_io` implementations

## 1.1.0 - 2020-05-11
### Changed
- Increase the flutter SDK dependency to version `1.17` (latest stable). This is needed for updated text theme names and a fix in the engine
- Update text theme names

## 1.0.0 - 2020-04-22
### Changed
- Removed beta notice from README
- Public API is now defined, as per [semantic versioning guidelines](https://semver.org/spec/v2.0.0-rc.1.html)

## 0.7.0 - 2020-04-22
### Changed
- Added the following variable fonts: Bellota, Bellota Text, Comic Neue, Fira Code, Gotu, Hepta Slab, Inria Sans, Inter, Literata, Manrope, Markazi Text, Public Sans, Sen, Spartan, Viaoda Libre

## 0.6.2 - 2020-04-17
### Changed
- Clean up code

## 0.6.1 - 2020-04-17
### Changed
- Memoize asset manifest

## 0.6.0 - 2020-04-16
### Changed
- Rename `config.allowHttp` to `config.allowRuntimeFetching`

## 0.5.0 - 2020-04-14
### Changed
- Use more accurate naming algorithm for `GoogleFonts.foo` and `GoogleFonts.fooTextTheme`

## 0.4.3 - 2020-04-14
### Added
- Add `GoogleFonts.getTextTheme(...)` method for dynamically getting a text theme from a font name

## 0.4.2 - 2020-04-14
### Changed
- Change loadFontIfNecessary to only follow through once per unique family when called in parallel

## 0.4.1 - 2020-04-13
### Changed
- Update README to include instructions for how to include licenses for fonts

## 0.4.0 - 2020-03-20
### Added
- Added ability to load fonts dynamically through `getFont` method
- Added `asMap` method which returns a map with font family names mapped to methods

## 0.3.10 - 2020-03-18
### Changed
- Update Fonts API url in generator to add in missing fonts

## 0.3.9 - 2020-02-13
### Fixed
- Fix `path_provider` usage for web

## 0.3.8 - 2020-02-10
### Added
- Add byte length and checksum verification for font files downloaded

## 0.3.7 - 2020-02-03
### Changed
- Fix asset font loading bug

### Fixed
- Update asset font README instructions

## 0.3.6 - 2020-01-31
### Added
- Add a config to the `GoogleFonts` class with an `allowHttp` option

## 0.3.5 - 2020-01-23
### Added
- Add `CONTRIBUTING.md`

### Changed
- Update generator to get most up-to-date urls from fonts.google.com

## 0.3.4 - 2020-01-23
### Changed
- Store downloaded font files in device's support directory instead of documents directory

## 0.3.3 - 2020-01-22
### Changed
- Update font URLs to https to properly support web

## 0.3.2 - 2020-01-07
### Fixed
- README image path fixes

## 0.3.1 - 2020-01-07
### Fixed
- README fixes

## 0.3.0 - 2020-01-07
### Added
- Added dartdocs to every public method in the google fonts package

- Added the ability to include font files in pubspec assets (see README)


## 0.2.0 - 2019-12-12
### Changed
- Updated to include all fonts currently on fonts.google.com

## 0.1.1 - 2019-12-10
### Changed
- Generated method names changed back to pre 0.1.0 (breaking change). For example, `GoogleFonts.latoTextStyle(...)` is now `GoogleFonts.lato(...)`

- Text theme parameters are now optional positional parameters (breaking change). For example, `GoogleFonts.latoTextTheme(textTheme: TextTheme(...))` is now `GoogleFonts.latoTextTheme(TextTheme(...))`


## 0.1.0 - 2019-12-06
### Changed
- Generated method names changed (breaking change). For example,

- Text theme support. Every font family now *also* has a `TextTheme` method. For example, the `Lato` font now has `GoogleFonts.latoTextStyle()` and `GoogleFonts.latoTextTheme()`. See README for more examples

- Refactored implementation, updated READMEs, and usage docs


## 0.0.8 - 2019-12-04
### Changed
- Internal refactor and added tests

## 0.0.7 - 2019-12-04
### Changed
- BETA support for Flutter web

## 0.0.6 - 2019-12-04
### Changed
- Minor updates to README

## 0.0.5 - 2019-11-20
### Changed
- Mark as experimental in more places

## 0.0.4 - 2019-11-20
### Added
- Add pubspec instructions to README

## 0.0.3 - 2019-11-20
### Fixed
- Fix homepage and main gif

## 0.0.2 - 2019-11-20
### Changed
- Update README with import instructions

## 0.0.1 - 2019-11-15
### Added
- Initial release: supports all 960 fonts and variants from fonts.google.com

- ttf files are downloaded via http on demand, and saved to local disk so that they can be loaded without making another http request for future font requests

- Fonts are loaded asynchronously through the font loader and Text widgets that use them are refreshed when they are ready