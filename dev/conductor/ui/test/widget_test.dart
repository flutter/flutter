// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/proto.dart' as pb;
import 'package:conductor_ui/main.dart';

import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App prints release channel', (WidgetTester tester) async {
    const String channelName = 'dev';
    final pb.ConductorState state = pb.ConductorState(
      releaseChannel: channelName,
    );
    await tester.pumpWidget(MyApp(state));

    expect(find.text('Flutter Conductor'), findsOneWidget);
    expect(find.textContaining(channelName), findsOneWidget);
    expect(find.text('1'), findsNothing);
  });
}
