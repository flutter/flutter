// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' show Platform;

import 'package:conductor_core/proto.dart' as pb;
import 'package:conductor_ui/main.dart';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Main app', () {
    testWidgets('Handles null state', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp(null));

      expect(find.textContaining('Flutter Desktop Conductor'), findsOneWidget);
      expect(find.textContaining('No persistent state file found at'), findsOneWidget);
    });

    testWidgets('App prints release channel from state file',
        (WidgetTester tester) async {
      const String channelName = 'dev';
      final pb.ConductorState state = pb.ConductorState(
        releaseChannel: channelName,
      );
      await tester.pumpWidget(MyApp(state));

      expect(find.textContaining('Flutter Desktop Conductor'), findsOneWidget);
      expect(find.textContaining('Conductor version'), findsOneWidget);
      expect(find.text('1'), findsNothing);
    });
  }, skip: Platform.isWindows); // This app does not support Windows [intended]
}
