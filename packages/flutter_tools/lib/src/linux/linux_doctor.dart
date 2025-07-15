// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:process/process.dart';

import '../base/io.dart';
import '../base/user_messages.dart';
import '../base/version.dart';
import '../convert.dart';
import '../doctor_validator.dart';

/// A combination of version description and parsed version number.
class _VersionInfo {
  /// Constructs a VersionInfo from a version description string.
  ///
  /// This should contain a version number. For example:
  ///     "clang version 9.0.1-6+build1"
  _VersionInfo(this.description) {
    final String? versionString = RegExp(
      r'[0-9]+\.[0-9]+(?:\.[0-9]+)?',
    ).firstMatch(description)?.group(0);
    number = Version.parse(versionString);
  }

  // The full info string reported by the binary.
  String description;

  // The parsed Version.
  Version? number;
}

/// Information about graphics drivers.
class _DriverInformation {
  _DriverInformation({required ProcessManager processManager}) : _processManager = processManager;

  final ProcessManager _processManager;
  var _sections = <List<String>>[];

  Future<bool> load() async {
    ProcessResult? result;
    try {
      result = await _processManager.run(<String>['eglinfo'], stdoutEncoding: utf8);
    } on ArgumentError {
      // ignore error.
    } on ProcessException {
      return false;
    }
    // result.exitCode is ignored, as this is non-zero if some platforms are not avaiable.
    // The output information is still parsable in all cases.
    if (result == null) {
      return false;
    }

    // Break into sections separated by an empty line.
    final List<String> lines = (result.stdout as String).split('\n');
    final sections = <List<String>>[<String>[]];
    for (final line in lines) {
      if (line == '') {
        if (sections.last.isNotEmpty) {
          sections.add(<String>[]);
        }
      } else {
        sections.last.add(line);
      }
    }
    if (sections.last.isEmpty) {
      sections.removeLast();
    }
    _sections = sections;

    return true;
  }

  List<String>? _getSection(String sectionName) {
    for (final List<String> lines in _sections) {
      if (lines[0] == '$sectionName:') {
        return lines;
      }
    }

    return null;
  }

  // Extracts a variable from eglinfo output.
  String? getVariable(String sectionName, String name) {
    final List<String>? lines = _getSection(sectionName);
    if (lines == null) {
      return null;
    }

    final prefix = '$name:';
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].startsWith(prefix)) {
        String value = lines[i].substring(prefix.length).trim();
        // Combine multi-line indented values.
        if (value == '') {
          for (int j = i + 1; j < lines.length && lines[j].startsWith('    '); j++) {
            if (value == '') {
              value += ' ';
            }
            value += lines[j].trim();
          }
        }
        return value;
      }
    }

    return null;
  }

  // Extracts a comma separated list variable.
  List<String>? getListVariable(String sectionName, String name) {
    return getVariable(sectionName, name)?.split(',').map((String s) => s.trim()).toList();
  }
}

/// A validator that checks for Clang and Make build dependencies.
class LinuxDoctorValidator extends DoctorValidator {
  LinuxDoctorValidator({required ProcessManager processManager, required UserMessages userMessages})
    : _processManager = processManager,
      _userMessages = userMessages,
      super('Linux toolchain - develop for Linux desktop');

  final ProcessManager _processManager;
  final UserMessages _userMessages;

  static const kClangBinary = 'clang++';
  static const kCmakeBinary = 'cmake';
  static const kNinjaBinary = 'ninja';
  static const kPkgConfigBinary = 'pkg-config';

  final _requiredBinaryVersions = <String, Version>{
    kClangBinary: Version(3, 4, 0),
    kCmakeBinary: Version(3, 10, 0),
    kNinjaBinary: Version(1, 8, 0),
    kPkgConfigBinary: Version(0, 29, 0),
  };

  final _requiredGtkLibraries = <String>['gtk+-3.0', 'glib-2.0', 'gio-2.0'];

  @override
  Future<ValidationResult> validateImpl() async {
    ValidationType validationType = ValidationType.success;
    final messages = <ValidationMessage>[];

    final installedVersions = <String, _VersionInfo?>{
      // Sort the check to make the call order predictable for unit tests.
      for (final String binary in _requiredBinaryVersions.keys.toList()..sort())
        binary: await _getBinaryVersion(binary),
    };

    // Determine overall validation level.
    if (installedVersions.values.any((_VersionInfo? versionInfo) => versionInfo?.number == null)) {
      validationType = ValidationType.missing;
    } else if (installedVersions.keys.any(
      (String binary) => installedVersions[binary]!.number! < _requiredBinaryVersions[binary]!,
    )) {
      validationType = ValidationType.partial;
    }

    // Message for Clang.
    {
      final _VersionInfo? version = installedVersions[kClangBinary];
      if (version == null || version.number == null) {
        messages.add(ValidationMessage.error(_userMessages.clangMissing));
      } else {
        assert(_requiredBinaryVersions.containsKey(kClangBinary));
        messages.add(ValidationMessage(version.description));
        final Version requiredVersion = _requiredBinaryVersions[kClangBinary]!;
        if (version.number! < requiredVersion) {
          messages.add(
            ValidationMessage.error(_userMessages.clangTooOld(requiredVersion.toString())),
          );
        }
      }
    }

    // Message for CMake.
    {
      final _VersionInfo? version = installedVersions[kCmakeBinary];
      if (version == null || version.number == null) {
        messages.add(ValidationMessage.error(_userMessages.cmakeMissing));
      } else {
        assert(_requiredBinaryVersions.containsKey(kCmakeBinary));
        messages.add(ValidationMessage(version.description));
        final Version requiredVersion = _requiredBinaryVersions[kCmakeBinary]!;
        if (version.number! < requiredVersion) {
          messages.add(
            ValidationMessage.error(_userMessages.cmakeTooOld(requiredVersion.toString())),
          );
        }
      }
    }

    // Message for ninja.
    {
      final _VersionInfo? version = installedVersions[kNinjaBinary];
      if (version == null || version.number == null) {
        messages.add(ValidationMessage.error(_userMessages.ninjaMissing));
      } else {
        assert(_requiredBinaryVersions.containsKey(kNinjaBinary));
        // The full version description is just the number, so add context.
        messages.add(ValidationMessage(_userMessages.ninjaVersion(version.description)));
        final Version requiredVersion = _requiredBinaryVersions[kNinjaBinary]!;
        if (version.number! < requiredVersion) {
          messages.add(
            ValidationMessage.error(_userMessages.ninjaTooOld(requiredVersion.toString())),
          );
        }
      }
    }

    // Message for pkg-config.
    {
      final _VersionInfo? version = installedVersions[kPkgConfigBinary];
      if (version == null || version.number == null) {
        messages.add(ValidationMessage.error(_userMessages.pkgConfigMissing));
        // Exit early because we cannot validate libraries without pkg-config.
        return ValidationResult(validationType, messages);
      } else {
        assert(_requiredBinaryVersions.containsKey(kPkgConfigBinary));
        // The full version description is just the number, so add context.
        messages.add(ValidationMessage(_userMessages.pkgConfigVersion(version.description)));
        final Version requiredVersion = _requiredBinaryVersions[kPkgConfigBinary]!;
        if (version.number! < requiredVersion) {
          messages.add(
            ValidationMessage.error(_userMessages.pkgConfigTooOld(requiredVersion.toString())),
          );
        }
      }
    }

    // Messages for libraries.
    {
      var libraryMissing = false;
      for (final String library in _requiredGtkLibraries) {
        if (!await _libraryIsPresent(library)) {
          libraryMissing = true;
          break;
        }
      }
      if (libraryMissing) {
        validationType = ValidationType.missing;
        messages.add(ValidationMessage.error(_userMessages.gtkLibrariesMissing));
      }
    }

    // Messages for drivers.
    {
      final driverInfo = _DriverInformation(processManager: _processManager);
      if (!await driverInfo.load()) {
        messages.add(ValidationMessage.hint(_userMessages.eglinfoMissing));
      } else {
        const kWaylandPlatform = 'Wayland platform';
        const kX11Platform = 'X11 platform';
        const kOpenGLCoreProfileRenderer = 'OpenGL core profile renderer';
        const kOpenGLCoreProfileShadingLanguageVersion =
            'OpenGL core profile shading language version';
        const kOpenGLCoreProfileVersion = 'OpenGL core profile version';
        const kOpenGLCoreProfileExtensions = 'OpenGL core profile extensions';
        const kOpenGLESProfileRenderer = 'OpenGL ES profile renderer';
        const kOpenGLESProfileVersion = 'OpenGL ES profile version';
        const kOpenGLESProfileShadingLanguageVersion = 'OpenGL ES profile shading language version';
        const kOpenGLESProfileExtensions = 'OpenGL ES profile extensions';

        // Check both Wayland and X11 platforms for value.
        String? getPlatformVariable(String name) {
          final String? waylandValue = driverInfo.getVariable(kWaylandPlatform, name);
          final String? x11Value = driverInfo.getVariable(kX11Platform, name);
          if (waylandValue == null && x11Value == null) {
            return null;
          }

          if (waylandValue == null) {
            return '$x11Value (X11)';
          } else if (x11Value == null) {
            return '$waylandValue (Wayland)';
          } else if (waylandValue == x11Value) {
            return waylandValue;
          } else {
            return '$waylandValue (Wayland) $x11Value (X11)';
          }
        }

        // Check if has specified OpenGL extension.
        ValidationMessage extensionStatus(String variableName, String extensionName) {
          final List<String> waylandExtensions =
              driverInfo.getListVariable(kWaylandPlatform, variableName) ?? <String>[];
          final List<String> x11Extensions =
              driverInfo.getListVariable(kX11Platform, variableName) ?? <String>[];

          final bool hasWayland = waylandExtensions.contains(extensionName);
          final bool hasX11 = x11Extensions.contains(extensionName);
          String status;
          if (!hasWayland && !hasX11) {
            status = 'no';
          } else if (!hasWayland) {
            status = 'yes (X11)';
          } else if (!hasX11) {
            status = 'yes (Wayland)';
          } else {
            status = 'yes';
          }

          return ValidationMessage('$extensionName: $status');
        }

        final String? renderer = getPlatformVariable(kOpenGLCoreProfileRenderer);
        if (renderer != null) {
          messages.add(ValidationMessage('OpenGL core renderer: $renderer'));
          final String version = getPlatformVariable(kOpenGLCoreProfileVersion) ?? 'unknown';
          messages.add(ValidationMessage('OpenGL core version: $version'));
          final String shadingLanguageVersion =
              getPlatformVariable(kOpenGLCoreProfileShadingLanguageVersion) ?? 'unknown';
          messages.add(
            ValidationMessage('OpenGL core shading language version: $shadingLanguageVersion'),
          );
        }
        final String? esRenderer = getPlatformVariable(kOpenGLESProfileRenderer);
        if (esRenderer != null) {
          messages.add(ValidationMessage('OpenGL ES renderer: $esRenderer'));
          final String version = getPlatformVariable(kOpenGLESProfileVersion) ?? 'unknown';
          messages.add(ValidationMessage('OpenGL ES version: $version'));
          final String shadingLanguageVersion =
              getPlatformVariable(kOpenGLESProfileShadingLanguageVersion) ?? 'unknown';
          messages.add(
            ValidationMessage('OpenGL ES shading language version: $shadingLanguageVersion'),
          );
        }
        messages.add(extensionStatus(kOpenGLCoreProfileExtensions, 'GL_EXT_framebuffer_blit'));
        messages.add(extensionStatus(kOpenGLESProfileExtensions, 'GL_EXT_texture_format_BGRA8888'));
      }
    }

    return ValidationResult(validationType, messages);
  }

  /// Returns the installed version of [binary], or null if it's not installed.
  ///
  /// Requires tha [binary] take a '--version' flag, and print a version of the
  /// form x.y.z somewhere on the first line of output.
  Future<_VersionInfo?> _getBinaryVersion(String binary) async {
    ProcessResult? result;
    try {
      result = await _processManager.run(<String>[binary, '--version']);
    } on ArgumentError {
      // ignore error.
    } on ProcessException {
      // ignore error.
    }
    if (result == null || result.exitCode != 0) {
      return null;
    }
    final String firstLine = (result.stdout as String).split('\n').first.trim();
    return _VersionInfo(firstLine);
  }

  /// Checks that [library] is available via pkg-config.
  Future<bool> _libraryIsPresent(String library) async {
    ProcessResult? result;
    try {
      result = await _processManager.run(<String>['pkg-config', '--exists', library]);
    } on ArgumentError {
      // ignore error.
    }
    return (result?.exitCode ?? 1) == 0;
  }
}
