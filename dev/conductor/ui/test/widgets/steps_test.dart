// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/conductor_core.dart';
import 'package:conductor_core/proto.dart' as pb;
import 'package:conductor_ui/widgets/progression.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform/platform.dart';

void main() {
  group('Progession steps and substeps workflow', () {
    testWidgets('Step 2 should be disabled if Step 1 is disabled',
        (WidgetTester tester) async {
      const String channelName = 'dev';
      final pb.ConductorState state = pb.ConductorState(
        releaseChannel: channelName,
      );
      await tester.pumpWidget(
        MainProgression(
          releaseState: state,
          stateFilePath: defaultStateFilePath(const LocalPlatform()),
        ),
      );

      expect(find.text('Initialize a New Flutter Release'), findsOneWidget);
    });
  });
}
