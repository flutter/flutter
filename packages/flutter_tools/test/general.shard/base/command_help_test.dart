// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/command_help.dart';
import 'package:flutter_tools/src/base/terminal.dart' show OutputPreferences, outputPreferences;
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';

import '../../src/common.dart';
import '../../src/context.dart';

// Used to use the message length in different scenarios in a DRY way
Future<void> Function() _testMessageLength(bool stdoutSupportsAnsi, int maxTestLineLength) => () async {
  when(globals.platform.stdoutSupportsAnsi).thenReturn(stdoutSupportsAnsi);

  int expectedWidth = maxTestLineLength;

  if (stdoutSupportsAnsi) {
    const int ansiMetaCharactersLength = 33;
    expectedWidth += ansiMetaCharactersLength;
  }

  expect(CommandHelp.L.toString().length, lessThanOrEqualTo(expectedWidth));
  expect(CommandHelp.P.toString().length, lessThanOrEqualTo(expectedWidth));
  expect(CommandHelp.R.toString().length, lessThanOrEqualTo(expectedWidth));
  expect(CommandHelp.S.toString().length, lessThanOrEqualTo(expectedWidth));
  expect(CommandHelp.U.toString().length, lessThanOrEqualTo(expectedWidth));
  expect(CommandHelp.a.toString().length, lessThanOrEqualTo(expectedWidth));
  expect(CommandHelp.d.toString().length, lessThanOrEqualTo(expectedWidth));
  expect(CommandHelp.h.toString().length, lessThanOrEqualTo(expectedWidth));
  expect(CommandHelp.i.toString().length, lessThanOrEqualTo(expectedWidth));
  expect(CommandHelp.o.toString().length, lessThanOrEqualTo(expectedWidth));
  expect(CommandHelp.p.toString().length, lessThanOrEqualTo(expectedWidth));
  expect(CommandHelp.q.toString().length, lessThanOrEqualTo(expectedWidth));
  expect(CommandHelp.r.toString().length, lessThanOrEqualTo(expectedWidth));
  expect(CommandHelp.s.toString().length, lessThanOrEqualTo(expectedWidth));
  expect(CommandHelp.t.toString().length, lessThanOrEqualTo(expectedWidth));
  expect(CommandHelp.w.toString().length, lessThanOrEqualTo(expectedWidth));
  expect(CommandHelp.z.toString().length, lessThanOrEqualTo(expectedWidth));
};

void main() {
  group('CommandHelp', () {
    group('toString', () {

      testUsingContext('should have a bold command key', () async {
        when(globals.platform.stdoutSupportsAnsi).thenReturn(true);

        expect(CommandHelp.L.toString(), startsWith('\x1B[1mL\x1B[22m'));
        expect(CommandHelp.P.toString(), startsWith('\x1B[1mP\x1B[22m'));
        expect(CommandHelp.R.toString(), startsWith('\x1B[1mR\x1B[22m'));
        expect(CommandHelp.S.toString(), startsWith('\x1B[1mS\x1B[22m'));
        expect(CommandHelp.U.toString(), startsWith('\x1B[1mU\x1B[22m'));
        expect(CommandHelp.a.toString(), startsWith('\x1B[1ma\x1B[22m'));
        expect(CommandHelp.d.toString(), startsWith('\x1B[1md\x1B[22m'));
        expect(CommandHelp.h.toString(), startsWith('\x1B[1mh\x1B[22m'));
        expect(CommandHelp.i.toString(), startsWith('\x1B[1mi\x1B[22m'));
        expect(CommandHelp.o.toString(), startsWith('\x1B[1mo\x1B[22m'));
        expect(CommandHelp.p.toString(), startsWith('\x1B[1mp\x1B[22m'));
        expect(CommandHelp.q.toString(), startsWith('\x1B[1mq\x1B[22m'));
        expect(CommandHelp.r.toString(), startsWith('\x1B[1mr\x1B[22m'));
        expect(CommandHelp.s.toString(), startsWith('\x1B[1ms\x1B[22m'));
        expect(CommandHelp.t.toString(), startsWith('\x1B[1mt\x1B[22m'));
        expect(CommandHelp.w.toString(), startsWith('\x1B[1mw\x1B[22m'));
        expect(CommandHelp.z.toString(), startsWith('\x1B[1mz\x1B[22m'));
      }, overrides: <Type, Generator>{
        OutputPreferences: () => OutputPreferences(wrapColumn: maxLineWidth),
        Platform: () => MockPlatform(),
      });

      testUsingContext('commands L,P,S,U,a,i,o,p,t,w should have a grey bolden parenthetical text', () async {
        when(globals.platform.stdoutSupportsAnsi).thenReturn(true);

        expect(CommandHelp.L.toString(), endsWith('\x1B[1;30m(debugDumpLayerTree)\x1B[39m'));
        expect(CommandHelp.P.toString(), endsWith('\x1B[1;30m(WidgetsApp.showPerformanceOverlay)\x1B[39m'));
        expect(CommandHelp.S.toString(), endsWith('\x1B[1;30m(debugDumpSemantics)\x1B[39m'));
        expect(CommandHelp.U.toString(), endsWith('\x1B[1;30m(debugDumpSemantics)\x1B[39m'));
        expect(CommandHelp.a.toString(), endsWith('\x1B[1;30m(debugProfileWidgetBuilds)\x1B[39m'));
        expect(CommandHelp.i.toString(), endsWith('\x1B[1;30m(WidgetsApp.showWidgetInspectorOverride)\x1B[39m'));
        expect(CommandHelp.o.toString(), endsWith('\x1B[1;30m(defaultTargetPlatform)\x1B[39m'));
        expect(CommandHelp.p.toString(), endsWith('\x1B[1;30m(debugPaintSizeEnabled)\x1B[39m'));
        expect(CommandHelp.t.toString(), endsWith('\x1B[1;30m(debugDumpRenderTree)\x1B[39m'));
        expect(CommandHelp.w.toString(), endsWith('\x1B[1;30m(debugDumpApp)\x1B[39m'));
      }, overrides: <Type, Generator>{
        OutputPreferences: () => OutputPreferences(wrapColumn: maxLineWidth),
        Platform: () => MockPlatform(),
      });

      testUsingContext('should not create a help text longer than maxLineWidth without ansi support',
        _testMessageLength(false, maxLineWidth),
        overrides: <Type, Generator>{
          OutputPreferences: () => OutputPreferences(wrapColumn: 0),
          Platform: () => MockPlatform(),
      });

      testUsingContext('should not create a help text longer than maxLineWidth with ansi support',
        _testMessageLength(true, maxLineWidth),
        overrides: <Type, Generator>{
          OutputPreferences: () => OutputPreferences(wrapColumn: 0),
          Platform: () => MockPlatform(),
      });

      testUsingContext('should not create a help text longer than outputPreferences.wrapColumn without ansi support',
        _testMessageLength(false, outputPreferences.wrapColumn),
          overrides: <Type, Generator>{
          Platform: () => MockPlatform(),
      });

      testUsingContext('should not create a help text longer than outputPreferences.wrapColumn with ansi support',
        _testMessageLength(true, outputPreferences.wrapColumn),
        overrides: <Type, Generator>{
          Platform: () => MockPlatform(),
        });

      testUsingContext('should create the correct help text with ansi support', () async {
        when(globals.platform.stdoutSupportsAnsi).thenReturn(true);

        expect(CommandHelp.L.toString(), equals('\x1B[1mL\x1B[22m Dump layer tree to the console.                               \x1B[1;30m(debugDumpLayerTree)\x1B[39m'));
        expect(CommandHelp.P.toString(), equals('\x1B[1mP\x1B[22m Toggle performance overlay.                    \x1B[1;30m(WidgetsApp.showPerformanceOverlay)\x1B[39m'));
        expect(CommandHelp.R.toString(), equals('\x1B[1mR\x1B[22m Hot restart.'));
        expect(CommandHelp.S.toString(), equals('\x1B[1mS\x1B[22m Dump accessibility tree in traversal order.                   \x1B[1;30m(debugDumpSemantics)\x1B[39m'));
        expect(CommandHelp.U.toString(), equals('\x1B[1mU\x1B[22m Dump accessibility tree in inverse hit test order.            \x1B[1;30m(debugDumpSemantics)\x1B[39m'));
        expect(CommandHelp.a.toString(), equals('\x1B[1ma\x1B[22m Toggle timeline events for all widget build methods.    \x1B[1;30m(debugProfileWidgetBuilds)\x1B[39m'));
        expect(CommandHelp.d.toString(), equals('\x1B[1md\x1B[22m Detach (terminate "flutter run" but leave application running).'));
        expect(CommandHelp.h.toString(), equals('\x1B[1mh\x1B[22m Repeat this help message.'));
        expect(CommandHelp.i.toString(), equals('\x1B[1mi\x1B[22m Toggle widget inspector.                  \x1B[1;30m(WidgetsApp.showWidgetInspectorOverride)\x1B[39m'));
        expect(CommandHelp.o.toString(), equals('\x1B[1mo\x1B[22m Simulate different operating systems.                      \x1B[1;30m(defaultTargetPlatform)\x1B[39m'));
        expect(CommandHelp.p.toString(), equals('\x1B[1mp\x1B[22m Toggle the display of construction lines.                  \x1B[1;30m(debugPaintSizeEnabled)\x1B[39m'));
        expect(CommandHelp.q.toString(), equals('\x1B[1mq\x1B[22m Quit (terminate the application on the device).'));
        expect(CommandHelp.r.toString(), equals('\x1B[1mr\x1B[22m Hot reload. $fire$fire$fire'));
        expect(CommandHelp.s.toString(), equals('\x1B[1ms\x1B[22m Save a screenshot to flutter.png.'));
        expect(CommandHelp.t.toString(), equals('\x1B[1mt\x1B[22m Dump rendering tree to the console.                          \x1B[1;30m(debugDumpRenderTree)\x1B[39m'));
        expect(CommandHelp.w.toString(), equals('\x1B[1mw\x1B[22m Dump widget hierarchy to the console.                               \x1B[1;30m(debugDumpApp)\x1B[39m'));
        expect(CommandHelp.z.toString(), equals('\x1B[1mz\x1B[22m Toggle elevation checker.'));
      }, overrides: <Type, Generator>{
        OutputPreferences: () => OutputPreferences(wrapColumn: maxLineWidth),
        Platform: () => MockPlatform(),
      });

      testUsingContext('should create the correct help text without ansi support', () async {
        when(globals.platform.stdoutSupportsAnsi).thenReturn(false);

        expect(CommandHelp.L.toString(), equals('L Dump layer tree to the console.                               (debugDumpLayerTree)'));
        expect(CommandHelp.P.toString(), equals('P Toggle performance overlay.                    (WidgetsApp.showPerformanceOverlay)'));
        expect(CommandHelp.R.toString(), equals('R Hot restart.'));
        expect(CommandHelp.S.toString(), equals('S Dump accessibility tree in traversal order.                   (debugDumpSemantics)'));
        expect(CommandHelp.U.toString(), equals('U Dump accessibility tree in inverse hit test order.            (debugDumpSemantics)'));
        expect(CommandHelp.a.toString(), equals('a Toggle timeline events for all widget build methods.    (debugProfileWidgetBuilds)'));
        expect(CommandHelp.d.toString(), equals('d Detach (terminate "flutter run" but leave application running).'));
        expect(CommandHelp.h.toString(), equals('h Repeat this help message.'));
        expect(CommandHelp.i.toString(), equals('i Toggle widget inspector.                  (WidgetsApp.showWidgetInspectorOverride)'));
        expect(CommandHelp.o.toString(), equals('o Simulate different operating systems.                      (defaultTargetPlatform)'));
        expect(CommandHelp.p.toString(), equals('p Toggle the display of construction lines.                  (debugPaintSizeEnabled)'));
        expect(CommandHelp.q.toString(), equals('q Quit (terminate the application on the device).'));
        expect(CommandHelp.r.toString(), equals('r Hot reload. $fire$fire$fire'));
        expect(CommandHelp.s.toString(), equals('s Save a screenshot to flutter.png.'));
        expect(CommandHelp.t.toString(), equals('t Dump rendering tree to the console.                          (debugDumpRenderTree)'));
        expect(CommandHelp.w.toString(), equals('w Dump widget hierarchy to the console.                               (debugDumpApp)'));
        expect(CommandHelp.z.toString(), equals('z Toggle elevation checker.'));
      }, overrides: <Type, Generator>{
        OutputPreferences: () => OutputPreferences(wrapColumn: maxLineWidth),
        Platform: () => MockPlatform(),
      });

    });
  });
}

class MockPlatform extends Mock implements Platform {
  @override
  Map<String, String> environment = <String, String>{
    'FLUTTER_ROOT': '/',
  };
}
