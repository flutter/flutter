## 2.1.0

- Adds `minVersion` to `findPackageConfig` and `findPackageConfigVersion`
  which allows ignoring earlier versions (which currently only means
  ignoring version 1, aka. `.packages` files.)

- Changes the version number of `SimplePackageConfig.empty` to the
  current maximum version.

- Improve file read performance; improve lookup performance.
- Emit an error when a package is inside the package root of another package.
- Fix a link in the readme.

## 2.0.2

- Update package description and README.
- Change to package:lints for style checking.
- Add an example.

## 2.0.1

- Use unique library names to correct docs issue.

## 2.0.0

- Migrate to null safety.
- Remove legacy APIs.
- Adds `relativeRoot` property to `Package` which controls whether to
  make the root URI relative when writing a configuration file.

## 1.9.3

- Fix `Package` constructor not accepting relative `packageUriRoot`.

## 1.9.2

- Updated to support new rules for picking `package_config.json` over
  a specified `.packages`.
- Deduce package root from `.packages` derived package configuration,
  and default all such packages to language version 2.7.

## 1.9.1

- Remove accidental transitive import of `dart:io` from entrypoints that are
  supposed to be cross-platform compatible.

## 1.9.0

- Based on new JSON file format with more content.
- This version includes all the new functionality intended for a 2.0.0
  version, as well as the, now deprecated, version 1 functionality.
  When we release 2.0.0, the deprectated functionality will be removed.

## 1.1.0

- Allow parsing files with default-package entries and metadata.
  A default-package entry has an empty key and a valid package name
  as value.
  Metadata is attached as fragments to base URIs.

## 1.0.5

- Fix usage of SDK constants.

## 1.0.4

- Set max SDK version to <3.0.0.

## 1.0.3

- Removed unneeded dependency constraint on SDK.

## 1.0.2

- Update SDK constraint to be 2.0.0 dev friendly.

## 1.0.1

- Fix test to not write to sink after it's closed.

## 1.0.0

- Public API marked stable.

## 0.1.5

- `FilePackagesDirectoryPackages.getBase(..)` performance improvements.

## 0.1.4

- Strong mode fixes.

## 0.1.3

- Invalid test cleanup (to keep up with changes in `Uri`).

## 0.1.1

- Syntax updates.

## 0.1.0

- Initial implementation.
