# version
[![version 2.0.0](https://img.shields.io/badge/pub-2.0.0-brightgreen.svg)](https://pub.dartlang.org/packages/version)
[![Tests](https://github.com/dartninja/version/workflows/Tests/badge.svg)](https://github.com/dartninja/version/actions/workflows/test.yml)
[![Coverage Status](https://coveralls.io/repos/github/dartninja/version/badge.svg?branch=master)](https://coveralls.io/github/dartninja/version?branch=master)

A dart library providing a Version object for comparing and incrementing version numbers in compliance with the Semantic Versioning spec at http://semver.org/

This is in contrast to [pub_semver][pub_semver], which is close to the spec but diverts in a few specific ways.

[pub_semver]: https://pub.dartlang.org/packages/pub_semver

# Installation
In your `pubspec.yaml`:

```yaml
dependencies:
  version: ^2.0.0
```

## Usage

A simple usage example:

    import 'package:version/version.dart';
    
    void main() {
      Version currentVersion = new Version(1, 0, 3);
      Version latestVersion = Version.parse("2.1.0");
    
      if (latestVersion > currentVersion) {
        print("Update is available");
      }
    
      Version betaVersion = new Version(2, 1, 0, preRelease: ["beta"]);
      // Note: this test will return false, as pre-release versions are considered
      // lesser then a non-pre-release version that otherwise has the same numbers.
      if (betaVersion > latestVersion) {
        print("More recent beta available");
      }
    }

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/dartninja/version/issues
