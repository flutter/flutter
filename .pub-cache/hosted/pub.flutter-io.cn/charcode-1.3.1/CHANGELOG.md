## 1.3.1

* Optimize for Pub score.

## 1.3.0

* Add camelCase constant names as alternatives for current snake_case constants.
  Example `$doubleQuote` as alternative to `$double_quote`.
* Internal tweaks to flag parsing.
* Switch to using `package:lints`.

## 1.2.0

* Stable release for null safety.

## 1.2.0-nullsafety.3

* Update SDK constraints to `>=2.12.0-0 <3.0.0` based on beta release
  guidelines.

## 1.2.0-nullsafety.2

* Allow prerelease versions of the 2.12 sdk.
- Add command line functionality to generate constants.
  Allows clients to generate their own constants instead of
  depending on the package at run-time.
  Example: To generate the characters needed
  for a hexadecimal numeral, run `pub run charcode a-fA-F\d+-`.

## 1.2.0-nullsafety.1

- Allow 2.10 stable and 2.11.0 dev SDK versions.

## 1.2.0-nullsafety

- Opt in to null safety.

## 1.1.3

- Added example, changed lints.

## 1.1.2

- Updated the SDK constraint.

## 1.1.1

- Spelling and linting fixes.

## 1.1.0

- Initial version
