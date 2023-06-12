## 1.2.1-dev

## 1.2.1

- Added support for `funding` field.

## 1.2.0

- Added support for `screenshots` field.
- Update `HostedDetails` to reflect how `hosted` dependencies are parsed in
  Dart 2.15:
   - Add `HostedDetails.declaredName` as the (optional) `name` property in a 
     `hosted` block.
   - `HostedDetails.name` now falls back to the name of the dependency if no
      name is declared in the block.
- Require Dart SDK >= 2.14.0

## 1.1.0

- Export `HostedDetails` publicly.

## 1.0.0

- Migrate to null-safety.
- Pubspec: `author` and `authors` are both now deprecated.
  See https://dart.dev/tools/pub/pubspec#authorauthors

## 0.1.8

- Allow the latest `package:pub_semver`.

## 0.1.7

- Allow `package:yaml` `v3.x`.

## 0.1.6

- Update SDK requirement to `>=2.7.0 <3.0.0`.
- Allow `package:json_annotation` `v4.x`.

## 0.1.5

- Update SDK requirement to `>=2.2.0 <3.0.0`.
- Support the latest `package:json_annotation`.

## 0.1.4

- Added `lenient` named argument to `Pubspec.fromJson` to ignore format and type errors.

## 0.1.3

- Added support for `flutter`, `issue_tracker`, `publish_to`, and `repository`
  fields.

## 0.1.2+3

- Support the latest version of `package:json_annotation`.

## 0.1.2+2

- Support `package:json_annotation` v1.

## 0.1.2+1

- Support the Dart 2 stable release.

## 0.1.2

- Allow superfluous `version` keys with `git` and `path` dependencies.
- Improve errors when unsupported keys are provided in dependencies.
- Provide better errors with invalid `sdk` dependency values.
- Support "scp-like syntax" for Git SSH URIs in the form
  `[user@]host.xz:path/to/repo.git/`.

## 0.1.1

- Fixed name collision with error type in latest `package:json_annotation`.
- Improved parsing of hosted dependencies and environment constraints.

## 0.1.0

- Initial release.
