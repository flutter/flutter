import 'package:test/test.dart';
import 'package:win32/winrt.dart';

// Test the WinRT helper functions to make sure everything is working correctly.

void main() {
  test('isSameType', () {
    expect(isSameType<GUID, GUID>(), isTrue);
    expect(isSameType<int, int>(), isTrue);
    expect(isSameType<int, int?>(), isFalse);
    expect(isSameType<Object, Object>(), isTrue);
    expect(isSameType<String, String>(), isTrue);
    expect(isSameType<String?, String>(), isFalse);
  });

  test('isSimilarType', () {
    expect(isSimilarType<GUID, GUID>(), isTrue);
    expect(isSimilarType<int?, int>(), isTrue);
    expect(isSimilarType<int?, int?>(), isTrue);
    expect(isSimilarType<Object, Object>(), isTrue);
    expect(isSimilarType<String, String>(), isTrue);
    expect(isSimilarType<String?, String?>(), isTrue);
  });

  test('isSubtype', () {
    expect(isSubtype<Calendar, IInspectable>(), isTrue);
    expect(isSubtype<IFileOpenPicker, IInspectable>(), isTrue);
    expect(isSubtype<IUnknown, IInspectable>(), isFalse);
    expect(isSubtype<IInspectable, IUnknown>(), isTrue);
  });

  test('isSubtypeOfInspectable', () {
    expect(isSubtypeOfInspectable<Calendar>(), isTrue);
    expect(isSubtypeOfInspectable<IFileOpenPicker>(), isTrue);
    expect(isSubtypeOfInspectable<IUnknown>(), isFalse);
    expect(isSubtypeOfInspectable<INetwork>(), isFalse);
  });

  test('isSubtypeOfWinRTEnum', () {
    expect(isSubtypeOfWinRTEnum<AsyncStatus>(), isTrue);
    expect(isSubtypeOfWinRTEnum<FileAttributes>(), isTrue);
    expect(isSubtypeOfWinRTEnum<IAsyncInfo>(), isFalse);
  });
}
