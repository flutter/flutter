// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart';

import '../base/io.dart';
import '../base/process.dart';
import '../convert.dart';
import '../doctor_validator.dart';
import 'gtk4_capabilities.dart';

/// Optional host diagnostics. Package metadata can refer to a sysroot, so it
/// must never stand in for the version loaded by the runtime probe.
class Gtk4DoctorValidator extends DoctorValidator {
  Gtk4DoctorValidator({
    required this._processUtils,
    required this._dartBinary,
    required this._probePath,
    this.requiredForBuild = false,
  }) : super('GTK4 host capabilities');

  final ProcessUtils _processUtils;
  final String _dartBinary;
  final String _probePath;
  final bool requiredForBuild;

  @override
  Future<ValidationResult> validateImpl() async {
    final messages = <ValidationMessage>[];
    ValidationType type = ValidationType.success;
    void unavailable(String message) {
      if (requiredForBuild) {
        type = ValidationType.partial;
        messages.add(ValidationMessage.hint(message));
      } else {
        messages.add(ValidationMessage(message));
      }
    }

    try {
      final RunResult headers = await _processUtils.run(<String>[
        'pkg-config',
        '--modversion',
        'gtk4',
      ], timeout: const Duration(seconds: 10));
      if (headers.exitCode == 0 && headers.stdout.trim().isNotEmpty) {
        messages.add(ValidationMessage('GTK4 development package: ${headers.stdout.trim()}'));
      } else {
        unavailable(
          'GTK4 development package unavailable. Install libgtk-4-dev or gtk4-devel to build GTK4 apps.',
        );
      }
    } on ProcessException {
      unavailable(
        'Cannot query GTK4 development packages. Install pkg-config and GTK4 development packages to build GTK4 apps.',
      );
    }

    try {
      final RunResult result = await _processUtils.run(<String>[
        _dartBinary,
        _probePath,
      ], timeout: const Duration(seconds: 10));
      if (result.exitCode != 0) {
        unavailable('GTK4 runtime probe failed (exit ${result.exitCode}); capabilities unknown.');
      } else {
        final Object? payload = jsonDecode(result.stdout);
        if (payload case <String, Object?>{'available': false}) {
          unavailable('GTK4 runtime unavailable. Install libgtk-4-1 or gtk4 to run GTK4 apps.');
        } else if (payload
            case <String, Object?>{
              'available': true,
              'version': [final int major, final int minor, final int micro],
              'symbols': final List<Object?> symbols,
            }
            when symbols.every((Object? symbol) => symbol is String)) {
          messages.add(
            ValidationMessage('GTK4 host runtime: $major.$minor.$micro (libgtk-4.so.1)'),
          );
          if (major != 4 || minor < 8) {
            unavailable('GTK4 apps require GTK 4.8 or later. Upgrade the host GTK4 runtime.');
          }
          for (final Gtk4Capability capability in gtk4Capabilities) {
            final bool available =
                major == 4 &&
                minor >= capability.minorVersion &&
                capability.symbols.every(symbols.contains);
            messages.add(
              ValidationMessage(
                '${capability.name}: ${available ? 'available' : 'unavailable'} (requires GTK 4.${capability.minorVersion}+ and matching symbols)',
              ),
            );
          }
          messages.add(
            const ValidationMessage(
              'API availability does not establish screen-reader parity or engine feature enablement.',
            ),
          );
          messages.add(
            const ValidationMessage(
              'DMA-BUF import and presentation support require an app-time GPU/display/format check.',
            ),
          );
          messages.add(
            const ValidationMessage(
              'Host probe uses the current library search environment; sandboxed or bundled apps may load different libraries.',
            ),
          );
        } else {
          unavailable('GTK4 runtime probe returned invalid data; capabilities unknown.');
        }
      }
    } on ProcessException {
      unavailable('GTK4 runtime probe could not complete; capabilities unknown.');
    } on FormatException {
      unavailable('GTK4 runtime probe returned invalid data; capabilities unknown.');
    }
    return ValidationResult(type, messages);
  }
}
