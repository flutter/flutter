// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:conductor_ui/main.dart';
import 'package:conductor_core/proto.dart' as pb;

import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App prints release channel', (WidgetTester tester) async {
    const String channelName = 'dev';
    final pb.ConductorState state = pb.ConductorState(
      releaseChannel: channelName,
    );
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(state));

    // Verify that our counter starts at 0.
    expect(find.text('Flutter Conductor'), findsOneWidget);
    expect(find.textContaining(channelName), findsOneWidget);
    expect(find.text('1'), findsNothing);
  });
}
