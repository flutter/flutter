// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:flutter_tools/src/linux/gtk4_capabilities.dart';
import 'package:flutter_tools/src/linux/gtk4_doctor.dart';
import 'package:flutter_tools_core/flutter_tools_core.dart';

import '../../src/common.dart';
import '../../src/fake_process_manager.dart';

void main() {
  Future<ValidationResult> validate({
    int minor = 14,
    List<String>? symbols,
    bool available = true,
    bool requiredForBuild = false,
    int probeExitCode = 0,
    bool headers = true,
    String? output,
    ProcessException? exception,
  }) async {
    final manager = FakeProcessManager.list(<FakeCommand>[
      FakeCommand(
        command: const <String>['pkg-config', '--modversion', 'gtk4'],
        exitCode: headers ? 0 : 1,
        stdout: headers ? '4.8.3\n' : '',
      ),
      FakeCommand(
        command: const <String>['/sdk/dart', '/sdk/gtk4_runtime_probe.dart'],
        exitCode: probeExitCode,
        exception: exception,
        stdout:
            output ??
            jsonEncode(<String, Object>{
              'available': available,
              'version': <int>[4, minor, 0],
              'symbols': symbols ?? gtk4Capabilities.expand((c) => c.symbols).toList(),
            }),
      ),
    ]);
    final ValidationResult result = await Gtk4DoctorValidator(
      processUtils: ProcessUtils(processManager: manager, logger: BufferLogger.test()),
      dartBinary: '/sdk/dart',
      probePath: '/sdk/gtk4_runtime_probe.dart',
      requiredForBuild: requiredForBuild,
    ).validate();
    expect(manager, hasNoRemainingExpectations);
    return result;
  }

  String messages(ValidationResult result) => result.messages.map((m) => m.message).join('\n');

  testWithoutContext('separates runtime from development package and graphics support', () async {
    final ValidationResult result = await validate();
    expect(result.type, ValidationType.success);
    expect(messages(result), contains('development package: 4.8.3'));
    expect(messages(result), contains('host runtime: 4.14.0'));
    for (final Gtk4Capability capability in gtk4Capabilities) {
      expect(messages(result), contains('${capability.name}: available'));
    }
    expect(messages(result), contains('app-time GPU/display/format check'));
  });

  for (final minor in <int>[8, 10, 14, 16]) {
    testWithoutContext('gates APIs on runtime 4.$minor', () async {
      final ValidationResult result = await validate(minor: minor);
      for (final Gtk4Capability capability in gtk4Capabilities) {
        expect(
          messages(result),
          contains(
            '${capability.name}: ${minor >= capability.minorVersion ? 'available' : 'unavailable'}',
          ),
        );
      }
    });
  }

  for (final Gtk4Capability capability in gtk4Capabilities) {
    for (final String missing in capability.symbols) {
      testWithoutContext('requires $missing even on a newer runtime', () async {
        final ValidationResult result = await validate(
          minor: 16,
          symbols: gtk4Capabilities.expand((c) => c.symbols).where((s) => s != missing).toList(),
        );
        expect(messages(result), contains('${capability.name}: unavailable'));
      });
    }
  }

  testWithoutContext('optional missing GTK4 does not fail GTK3 doctor', () async {
    final ValidationResult result = await validate(available: false, headers: false);
    expect(result.type, ValidationType.success);
    expect(messages(result), contains('runtime unavailable'));
  });

  testWithoutContext('selected GTK4 warns about missing runtime', () async {
    expect((await validate(available: false, requiredForBuild: true)).type, ValidationType.partial);
  });

  testWithoutContext('selected GTK4 warns about missing headers', () async {
    expect((await validate(headers: false, requiredForBuild: true)).type, ValidationType.partial);
  });

  testWithoutContext('optional APIs do not fail selected GTK4', () async {
    expect((await validate(minor: 8, requiredForBuild: true)).type, ValidationType.success);
  });

  testWithoutContext('too old selected runtime warns', () async {
    expect((await validate(minor: 6, requiredForBuild: true)).type, ValidationType.partial);
  });

  for (final output in <String>['garbage', '{}', '{"available":true,"version":[4],"symbols":[]}']) {
    testWithoutContext('malformed probe $output is unknown, not available', () async {
      expect(
        messages(await validate(output: output)),
        contains('invalid data; capabilities unknown'),
      );
    });
  }

  testWithoutContext('probe crash is reported without crashing doctor', () async {
    expect(messages(await validate(probeExitCode: -11)), contains('probe failed'));
  });

  testWithoutContext('probe launch failure or timeout is unknown', () async {
    expect(
      messages(await validate(exception: const ProcessException('dart', <String>[]))),
      contains('could not complete'),
    );
  });
}
