// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/base/user_messages.dart';
import 'package:mockito/mockito.dart';

import '../src/common.dart';

void main() {
  testWithoutContext('Defaults to a wrapped terminal columns with color if no '
    'args are provided', () {
    final MockUserMessage userMessages = MockUserMessage();
    final MockStdio stdio = MockStdio();
    when(stdio.terminalColumns).thenReturn(80);

    final OutputPreferences preferences = OutputPreferences.fromArguments(
      <String>[],
      userMessages: userMessages,
      stdio: stdio,
    );

    expect(preferences.showColor, true);
    expect(preferences.wrapText, true);
    expect(preferences.wrapColumn, 80);
  });

  testWithoutContext('Can be configured with --no-color', () {
    final MockUserMessage userMessages = MockUserMessage();
    final MockStdio stdio = MockStdio();
    when(stdio.terminalColumns).thenReturn(80);

    final OutputPreferences preferences = OutputPreferences.fromArguments(
      <String>['--no-color'],
      userMessages: userMessages,
      stdio: stdio,
    );

    expect(preferences.showColor, false);
    expect(preferences.wrapText, true);
    expect(preferences.wrapColumn, 80);
  });

  testWithoutContext('Can be configured with a specific wrap length', () {
    final MockUserMessage userMessages = MockUserMessage();
    final MockStdio stdio = MockStdio();
    when(stdio.terminalColumns).thenReturn(80);

    final OutputPreferences preferences = OutputPreferences.fromArguments(
      <String>['--wrap-column=123'],
      userMessages: userMessages,
      stdio: stdio,
    );

    expect(preferences.showColor, true);
    expect(preferences.wrapText, true);
    expect(preferences.wrapColumn, 123);
  });

  testWithoutContext('Will wrap to 100 when there is no terminal columns available', () {
    final MockUserMessage userMessages = MockUserMessage();
    final MockStdio stdio = MockStdio();
    when(stdio.terminalColumns).thenReturn(null);

    final OutputPreferences preferences = OutputPreferences.fromArguments(
      <String>['--wrap'],
      userMessages: userMessages,
      stdio: stdio,
    );

    expect(preferences.showColor, true);
    expect(preferences.wrapText, true);
    expect(preferences.wrapColumn, 100);
  });

  testWithoutContext('Can be configured to disable wrapping', () {
    final MockUserMessage userMessages = MockUserMessage();
    final MockStdio stdio = MockStdio();
    when(stdio.terminalColumns).thenReturn(80);

    final OutputPreferences preferences = OutputPreferences.fromArguments(
      <String>['--no-wrap'],
      userMessages: userMessages,
      stdio: stdio,
    );

    expect(preferences.showColor, true);
    expect(preferences.wrapText, false);
  });

  testWithoutContext('Throws a tool exit when an invalid wrap number is given', () {
    final MockUserMessage userMessages = MockUserMessage();
    final MockStdio stdio = MockStdio();
    when(stdio.terminalColumns).thenReturn(80);

    expect(() => OutputPreferences.fromArguments(
      <String>['--wrap-column=a'],
      userMessages: userMessages,
      stdio: stdio,
    ), throwsA(isA<ToolExit>()));
  });

  testWithoutContext('Throws a tool exit when wrap is given without a number', () {
    final MockUserMessage userMessages = MockUserMessage();
    final MockStdio stdio = MockStdio();
    when(stdio.terminalColumns).thenReturn(80);

    expect(() => OutputPreferences.fromArguments(
      <String>['--wrap-column='],
      userMessages: userMessages,
      stdio: stdio,
    ), throwsA(isA<ToolExit>()));
  });
}

class MockUserMessage extends Mock implements UserMessages {}
class MockStdio extends Mock implements Stdio {}
