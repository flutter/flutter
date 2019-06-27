// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_tool_api/extension.dart';
import 'package:flutter_tool_api/doctor.dart';

class FlutterLinuxExtension extends ToolExtension {
  @override
  String get name => 'Linux Desktop';

  @override
  final LinuxDoctorDomain doctorDomain = LinuxDoctorDomain();
}

class LinuxDoctorDomain extends DoctorDomain {
  /// The minimum version of clang supported.
  final _Version _minimumClangVersion = _Version(3, 4, 0);
  static const String _kValidatiorName = 'Linux toolchain - develop for Linux desktop';

  @override
  Future<ValidationResult> diagnose() async {
    ValidationType validationType = ValidationType.installed;
    final List<ValidationMessage> messages = <ValidationMessage>[];

    /// Check for a minimum version of Clang.
    ProcessResult clangResult;
    try {
      clangResult = await processManager.run(const <String>[
        'clang++',
        '--version',
      ]);
    } on ArgumentError {
      // ignore error.
    }
    if (clangResult == null || clangResult.exitCode != 0) {
      validationType = ValidationType.missing;
      messages.add(const ValidationMessage(
        'clang++ is not installed',
        type: ValidationMessageType.error,
      ));
    } else {
      final String firstLine = (clangResult.stdout as String).split('\n').first.trim();
      final String versionString = RegExp(r'[0-9]+\.[0-9]+\.[0-9]+').firstMatch(firstLine).group(0);
      final _Version version = _Version.parse(versionString);
      if (version >= _minimumClangVersion) {
        messages.add(ValidationMessage('clang++ $version'));
      } else {
        validationType = ValidationType.partial;
        messages.add(ValidationMessage(
          'clang++ $version is below minimum version of $_minimumClangVersion',
          type: ValidationMessageType.error,
        ));
      }
    }

    /// Check for make.
    // TODO(jonahwilliams): tighten this check to include a version when we have
    // a better idea about what is supported.
    ProcessResult makeResult;
    try {
      makeResult = await processManager.run(const <String>[
        'make',
        '--version',
      ]);
    } on ArgumentError {
      // ignore error.
    }
    if (makeResult == null || makeResult.exitCode != 0) {
      validationType = ValidationType.missing;
      messages.add(const ValidationMessage(
        'make is not installed',
        type: ValidationMessageType.error,
      ));
    } else {
      final String firstLine = (makeResult.stdout as String).split('\n').first.trim();
      messages.add(ValidationMessage(firstLine));
    }

    return ValidationResult(
      type: validationType,
      messages: messages,
      name: _kValidatiorName,
    );
  }
}

/// HACK: establish code sharing library (base?) for 1p extension
class _Version implements Comparable<_Version> {
  /// Creates a new [_Version] object.
  factory _Version(int major, int minor, int patch, {String text}) {
    if (text == null) {
      text = major == null ? '0' : '$major';
      if (minor != null)
        text = '$text.$minor';
      if (patch != null)
        text = '$text.$patch';
    }

    return _Version._(major ?? 0, minor ?? 0, patch ?? 0, text);
  }

  _Version._(this.major, this.minor, this.patch, this._text) {
    if (major < 0)
      throw ArgumentError('Major version must be non-negative.');
    if (minor < 0)
      throw ArgumentError('Minor version must be non-negative.');
    if (patch < 0)
      throw ArgumentError('Patch version must be non-negative.');
  }

  /// Creates a new [_Version] by parsing [text].
  factory _Version.parse(String text) {
    final Match match = versionPattern.firstMatch(text ?? '');
    if (match == null) {
      return null;
    }

    try {
      final int major = int.parse(match[1] ?? '0');
      final int minor = int.parse(match[3] ?? '0');
      final int patch = int.parse(match[5] ?? '0');
      return _Version._(major, minor, patch, text);
    } on FormatException {
      return null;
    }
  }

  /// Returns the primary version out of a list of candidates.
  ///
  /// This is the highest-numbered stable version.
  static _Version primary(List<_Version> versions) {
    _Version primary;
    for (_Version version in versions) {
      if (primary == null || (version > primary)) {
        primary = version;
      }
    }
    return primary;
  }


  static _Version get unknown => _Version(0, 0, 0, text: 'unknown');

  /// The major version number: "1" in "1.2.3".
  final int major;

  /// The minor version number: "2" in "1.2.3".
  final int minor;

  /// The patch version number: "3" in "1.2.3".
  final int patch;

  /// The original string representation of the version number.
  ///
  /// This preserves textual artifacts like leading zeros that may be left out
  /// of the parsed version.
  final String _text;

  static final RegExp versionPattern =
      RegExp(r'^(\d+)(\.(\d+)(\.(\d+))?)?');

  /// Two [_Version]s are equal if their version numbers are. The version text
  /// is ignored.
  @override
  bool operator ==(dynamic other) {
    if (other is! _Version)
      return false;
    return major == other.major && minor == other.minor && patch == other.patch;
  }

  @override
  int get hashCode => major ^ minor ^ patch;

  bool operator <(_Version other) => compareTo(other) < 0;
  bool operator >(_Version other) => compareTo(other) > 0;
  bool operator <=(_Version other) => compareTo(other) <= 0;
  bool operator >=(_Version other) => compareTo(other) >= 0;

  @override
  int compareTo(_Version other) {
    if (major != other.major)
      return major.compareTo(other.major);
    if (minor != other.minor)
      return minor.compareTo(other.minor);
    return patch.compareTo(other.patch);
  }

  @override
  String toString() => _text;
}
