import 'package:test/test.dart';
import 'package:win32/winrt.dart';

// Test the WinRT map helper functions to make sure everything is working
// correctly.

void main() {
  test('isSupportedKeyValuePair', () {
    expect(isSupportedKeyValuePair<int, IInspectable?>(), isTrue);
    expect(isSupportedKeyValuePair<int, int?>(), isFalse);
    expect(isSupportedKeyValuePair<int, Object?>(), isFalse);
    expect(isSupportedKeyValuePair<int, String?>(), isFalse);
    expect(isSupportedKeyValuePair<int, WinRTEnum?>(), isFalse);

    expect(isSupportedKeyValuePair<GUID, IInspectable?>(), isTrue);
    expect(isSupportedKeyValuePair<GUID, Object?>(), isTrue);
    expect(isSupportedKeyValuePair<GUID, String?>(), isFalse);
    expect(isSupportedKeyValuePair<GUID, WinRTEnum?>(), isFalse);

    expect(isSupportedKeyValuePair<PedometerStepKind, PedometerReading?>(),
        isTrue);
    expect(isSupportedKeyValuePair<PedometerStepKind, Object?>(), isFalse);
    expect(isSupportedKeyValuePair<PedometerStepKind, String?>(), isFalse);
    expect(isSupportedKeyValuePair<PedometerStepKind, WinRTEnum?>(), isFalse);

    expect(isSupportedKeyValuePair<Object, IInspectable?>(), isFalse);
    expect(isSupportedKeyValuePair<Object, Object?>(), isTrue);
    expect(isSupportedKeyValuePair<Object, String?>(), isFalse);
    expect(isSupportedKeyValuePair<Object, WinRTEnum?>(), isFalse);

    expect(isSupportedKeyValuePair<String, Object?>(), isTrue);
    expect(isSupportedKeyValuePair<String, String?>(), isTrue);
    expect(isSupportedKeyValuePair<String, IInspectable?>(), isTrue);
    expect(isSupportedKeyValuePair<String, WinRTEnum?>(), isTrue);
  });
}
