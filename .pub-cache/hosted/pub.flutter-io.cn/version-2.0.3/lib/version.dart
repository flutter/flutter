// Copyright (c) 2021, Matthew Barbour. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

/// Provides version objects to enforce conformance to the Semantic Versioning 2.0 spec. The spec can be read at http://semver.org/
library version;

/// Provides immutable storage and comparison of semantic version numbers.
class Version implements Comparable<Version> {
  static final RegExp _versionRegex =
      RegExp(r"^([\d.]+)(-([0-9A-Za-z\-.]+))?(\+([0-9A-Za-z\-.]+))?$");
  static final RegExp _buildRegex = RegExp(r"^[0-9A-Za-z\-.]+$");
  static final RegExp _preReleaseRegex = RegExp(r"^[0-9A-Za-z\-]+$");

  /// The major number of the version, incremented when making breaking changes.
  final int major;

  /// The minor number of the version, incremented when adding new functionality in a backwards-compatible manner.
  final int minor;

  /// The patch number of the version, incremented when making backwards-compatible bug fixes.
  final int patch;

  /// Build information relevant to the version. Does not contribute to sorting.
  final String build;

  final List<String> _preRelease;

  /// Indicates that the version is a pre-release. Returns true if preRelease has any segments, otherwise false
  bool get isPreRelease => _preRelease.isNotEmpty;

  /// Creates a new instance of [Version].
  ///
  /// [major], [minor], and [patch] are all required, all must be greater than 0 and not null, and at least one must be greater than 0.
  /// [preRelease] is optional, but if specified must be a [List] of [String] and must not be null. Each element in the list represents one of the period-separated segments of the pre-release information, and may only contain [0-9A-Za-z-].
  /// [build] is optional, but if specified must be a [String]. must contain only [0-9A-Za-z-.], and must not be null.
  /// Throws a [FormatException] if the [String] content does not follow the character constraints defined above.
  /// Throes an [ArgumentError] if any of the other conditions are violated.
  Version(this.major, this.minor, this.patch,
      {List<String> preRelease = const <String>[], this.build = ""})
      : _preRelease = preRelease {
    for (int i = 0; i < _preRelease.length; i++) {
      if (_preRelease[i].toString().trim().isEmpty) {
        throw ArgumentError("preRelease segments must not be empty");
      }
      // Just in case
      _preRelease[i] = _preRelease[i].toString();
      if (!_preReleaseRegex.hasMatch(_preRelease[i])) {
        throw FormatException(
            "preRelease segments must only contain [0-9A-Za-z-]");
      }
    }
    if (this.build.isNotEmpty && !_buildRegex.hasMatch(this.build)) {
      throw FormatException("build must only contain [0-9A-Za-z-.]");
    }

    if (major < 0 || minor < 0 || patch < 0) {
      throw ArgumentError("Version numbers must be greater than 0");
    }
  }

  @override
  int get hashCode => this.toString().hashCode;

  /// Pre-release information segments.
  List<String> get preRelease => List<String>.from(_preRelease);

  /// Determines whether the left-hand [Version] represents a lower precedence than the right-hand [Version].
  bool operator <(dynamic o) => o is Version && _compare(this, o) < 0;

  /// Determines whether the left-hand [Version] represents an equal or lower precedence than the right-hand [Version].
  bool operator <=(dynamic o) => o is Version && _compare(this, o) <= 0;

  /// Determines whether the left-hand [Version] represents an equal precedence to the right-hand [Version].
  @override
  bool operator ==(dynamic o) => o is Version && _compare(this, o) == 0;

  /// Determines whether the left-hand [Version] represents a greater precedence than the right-hand [Version].
  bool operator >(dynamic o) => o is Version && _compare(this, o) > 0;

  /// Determines whether the left-hand [Version] represents an equal or greater precedence than the right-hand [Version].
  bool operator >=(dynamic o) => o is Version && _compare(this, o) >= 0;

  @override
  int compareTo(Version? other) {
    if (other == null) {
      throw ArgumentError.notNull("other");
    }

    return _compare(this, other);
  }

  /// Creates a new [Version] with the [major] version number incremented.
  ///
  /// Also resets the [minor] and [patch] numbers to 0, and clears the [build] and [preRelease] information.
  Version incrementMajor() => Version(this.major + 1, 0, 0);

  /// Creates a new [Version] with the [minor] version number incremented.
  ///
  /// Also resets the [patch] number to 0, and clears the [build] and [preRelease] information.
  Version incrementMinor() => Version(this.major, this.minor + 1, 0);

  /// Creates a new [Version] with the [patch] version number incremented.
  ///
  /// Also clears the [build] and [preRelease] information.
  Version incrementPatch() => Version(this.major, this.minor, this.patch + 1);

  /// Creates a new [Version] with the right-most numeric [preRelease] segment incremented.
  /// If no numeric segment is found, one will be added with the value "1".
  ///
  /// If this [Version] is not a pre-release version, an Exception will be thrown.
  Version incrementPreRelease() {
    if (!this.isPreRelease) {
      throw Exception(
          "Cannot increment pre-release on a non-pre-release [Version]");
    }
    var newPreRelease = this.preRelease;

    var found = false;
    for (var i = newPreRelease.length - 1; i >= 0; i--) {
      var segment = newPreRelease[i];
      if (Version._isNumeric(segment)) {
        var intVal = int.parse(segment);
        intVal++;
        newPreRelease[i] = intVal.toString();
        found = true;
        break;
      }
    }
    if (!found) {
      newPreRelease.add("1");
    }

    return Version(this.major, this.minor, this.patch,
        preRelease: newPreRelease);
  }

  /// Returns a [String] representation of the [Version].
  ///
  /// Uses the format "$major.$minor.$patch".
  /// If [preRelease] has segments available they are appended as "-segmentOne.segmentTwo", with each segment separated by a period.
  /// If [build] is specified, it is appended as "+build.info" where "build.info" is whatever value [build] is set to.
  /// If all [preRelease] and [build] are specified, then both are appended, [preRelease] first and [build] second.
  /// An example of such output would be "1.0.0-preRelease.segment+build.info".
  @override
  String toString() {
    final StringBuffer output = StringBuffer("$major.$minor.$patch");
    if (_preRelease.isNotEmpty) {
      output.write("-${_preRelease.join('.')}");
    }
    if (build.trim().isNotEmpty) {
      output.write("+${build.trim()}");
    }
    return output.toString();
  }

  /// Creates a [Version] instance from a string.
  ///
  /// The string must conform to the specification at http://semver.org/
  /// Throws [FormatException] if the string is empty or does not conform to the spec.
  static Version parse(String? versionString) {
    if (versionString?.trim().isEmpty ?? true) {
      throw FormatException("Cannot parse empty string into version");
    }
    if (!_versionRegex.hasMatch(versionString!)) {
      throw FormatException("Not a properly formatted version string");
    }
    final Match m = _versionRegex.firstMatch(versionString)!;
    final String version = m.group(1)!;

    int? major, minor, patch;
    final List<String> parts = version.split(".");
    major = int.parse(parts[0]);
    if (parts.length > 1) {
      minor = int.parse(parts[1]);
      if (parts.length > 2) {
        patch = int.parse(parts[2]);
      }
    }

    final String preReleaseString = m.group(3) ?? "";
    List<String> preReleaseList = <String>[];
    if (preReleaseString.trim().isNotEmpty) {
      preReleaseList = preReleaseString.split(".");
    }
    final String build = m.group(5) ?? "";

    return Version(major, minor ?? 0, patch ?? 0,
        build: build, preRelease: preReleaseList);
  }

  static int _compare(Version? a, Version? b) {
    if (a == null) {
      throw ArgumentError.notNull("a");
    }

    if (b == null) {
      throw ArgumentError.notNull("b");
    }

    if (a.major > b.major) return 1;
    if (a.major < b.major) return -1;

    if (a.minor > b.minor) return 1;
    if (a.minor < b.minor) return -1;

    if (a.patch > b.patch) return 1;
    if (a.patch < b.patch) return -1;

    if (a.preRelease.isEmpty) {
      if (b.preRelease.isEmpty) {
        return 0;
      } else {
        return 1;
      }
    } else if (b.preRelease.isEmpty) {
      return -1;
    } else {
      int preReleaseMax = a.preRelease.length;
      if (b.preRelease.length > a.preRelease.length) {
        preReleaseMax = b.preRelease.length;
      }

      for (int i = 0; i < preReleaseMax; i++) {
        if (b.preRelease.length <= i) {
          return 1;
        } else if (a.preRelease.length <= i) {
          return -1;
        }

        if (a.preRelease[i] == b.preRelease[i]) continue;

        final bool aNumeric = _isNumeric(a.preRelease[i]);
        final bool bNumeric = _isNumeric(b.preRelease[i]);

        if (aNumeric && bNumeric) {
          final double aNumber = double.parse(a.preRelease[i]);
          final double bNumber = double.parse(b.preRelease[i]);
          if (aNumber > bNumber) {
            return 1;
          } else {
            return -1;
          }
        } else if (bNumeric) {
          return 1;
        } else if (aNumeric) {
          return -1;
        } else {
          return a.preRelease[i].compareTo(b.preRelease[i]);
        }
      }
    }
    return 0;
  }

  static bool _isNumeric(String? s) {
    if (s == null) {
      return false;
    }
    return double.tryParse(s) != null;
  }
}
