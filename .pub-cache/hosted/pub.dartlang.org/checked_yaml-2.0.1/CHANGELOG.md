## 2.0.1

- If `CheckedFromJsonException` is caught for a key missing in the source map,
  include those details in the thrown `ParsedYamlException`.

- Correctly handle the case where `CheckedFromJsonException.message` is `null`.

## 2.0.0

- *BREAKING* `checkedYamlDecode` `sourceUrl` parameter is now a `Uri`.
- Require at least Dart `2.12.0-0`.

## 1.0.4

- Allow `package:yaml` `v3.x`.

## 1.0.3

- Require at least Dart `2.7.0`.
- Allow `package:json_annotation` `v4.x`.

## 1.0.2

- Require at least Dart `2.3.0`.
- Support the latest `package:json_annotation`.

## 1.0.1

- Fix readme.

## 1.0.0

- Initial release.
