// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/executable.dart';

import '../src/common.dart';

void main() {
  group('findCommandName', () {
    test('finds a command given on its own', () {
      expect(findCommandName(<String>['doctor']), 'doctor');
      expect(findCommandName(<String>['help']), 'help');
    });

    test('finds a command followed by its own arguments', () {
      expect(findCommandName(<String>['doctor', '-v']), 'doctor');
      expect(findCommandName(<String>['doctor', '--android-licenses']), 'doctor');
      expect(findCommandName(<String>['test', 'test/widget_test.dart']), 'test');
    });

    test('finds a command preceded by global options', () {
      expect(findCommandName(<String>['-v', 'doctor']), 'doctor');
      expect(findCommandName(<String>['--no-version-check', 'doctor', '-v']), 'doctor');
      expect(findCommandName(<String>['--no-version-check', 'help', '-v']), 'help');
      expect(
        findCommandName(<String>['--suppress-analytics', '--no-color', 'doctor', '-v']),
        'doctor',
      );
    });

    test('does not mistake the value of a global option for the command', () {
      expect(findCommandName(<String>['--local-engine', 'host_debug', 'doctor']), 'doctor');
      expect(findCommandName(<String>['--local-engine=host_debug', 'doctor']), 'doctor');
      expect(findCommandName(<String>['--wrap-column', '100', 'doctor']), 'doctor');
      expect(findCommandName(<String>['-d', 'emulator-5554', 'doctor']), 'doctor');
    });

    test('does not mistake an argument of the command for the command', () {
      expect(findCommandName(<String>['create', 'doctor']), 'create');
      expect(findCommandName(<String>['create', 'daemon']), 'create');
      expect(findCommandName(<String>['create', 'widget-preview']), 'create');
      expect(findCommandName(<String>['help', 'doctor']), 'help');
    });

    test('returns null when no command is given', () {
      expect(findCommandName(<String>[]), isNull);
      expect(findCommandName(<String>['-v']), isNull);
      expect(findCommandName(<String>['-h']), isNull);
      expect(findCommandName(<String>['--version', '-v']), isNull);
    });

    test('returns null when the global options cannot be parsed', () {
      expect(findCommandName(<String>['--not-a-real-flag', 'doctor']), isNull);
    });
  });
}
