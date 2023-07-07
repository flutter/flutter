## 1.0.4

- Fix un-await-ed Future in `SkiaPerfDestination.update`.

## 1.0.3

- Filter out host_name, load_avg and caches keys from context
  before adding to a MetricPoint object.

## 1.0.2

- Updated the GoogleBenchmark parser to correctly parse new keys added
  in the JSON schema.
- Fix `unnecessary_import` lint errors.
- Update version titles in CHANGELOG.md so plugins tooling understands them.
  - (Moved from `# X.Y.Z` to `## X.Y.Z`)

## 1.0.1

- `update` now requires taskName to scale metric writes

## 1.0.0

- Null safety support

## 0.1.1

- Update packages to null safe

## 0.1.0

- `update` now requires DateTime when commit was merged
- Removed `github` dependency

## 0.0.9

- Remove legacy datastore and destination.

## 0.0.8

- Allow tests to override LegacyFlutterDestination GCP project id.

## 0.0.7

- Expose constants that were missing since 0.0.4+1.

## 0.0.6

- Allow `datastoreFromCredentialsJson` to specify project id.

## 0.0.5

- `FlutterDestination` writes into both Skia perf GCS and the legacy datastore.
- `FlutterDestination.makeFromAccessToken` returns a `Future`.

## 0.0.4+1

- Moved to the `flutter/packages` repository
