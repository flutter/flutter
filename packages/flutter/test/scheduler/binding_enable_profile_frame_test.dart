import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  SchedulerBinding.debugOverrideEnableProfileFrame = false;
  final _TestWidgetsFlutterBinding binding = _TestWidgetsFlutterBinding();

  // this test must be in a separate file, because it tests
  // binding initialization
  testWidgets('when enableProfileFrame is false, should not post events', (WidgetTester tester) async {
    await tester.pumpWidget(const CircularProgressIndicator());
    for (int i = 0; i < 20; ++i) {
      await tester.pump();
    }

    expect(binding.postEventCount, 0, reason: 'when not EnableProfileFrame, should not post event');
  });
}

class _TestWidgetsFlutterBinding extends AutomatedTestWidgetsFlutterBinding {
  int postEventCount = 0;

  @protected
  @override
  void postEvent(String eventKind, Map<String, dynamic> eventData) {
    postEventCount++;
  }
}
