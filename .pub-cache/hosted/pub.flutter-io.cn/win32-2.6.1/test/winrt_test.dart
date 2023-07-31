@TestOn('windows')

import 'package:test/test.dart';
import 'package:win32/win32.dart';

void main() {
  if (isWindowsRuntimeAvailable()) {
    test('WinRT initialization should succeed', () {
      final hr = RoInitialize(RO_INIT_TYPE.RO_INIT_MULTITHREADED);
      expect(hr, equals(S_OK));
      RoUninitialize();
    });

    test('WinRT double initialization should succeed with warning', () {
      final hr = RoInitialize(RO_INIT_TYPE.RO_INIT_MULTITHREADED);
      expect(SUCCEEDED(hr), isTrue);
      expect(hr, equals(S_OK));

      final hr2 = RoInitialize(RO_INIT_TYPE.RO_INIT_MULTITHREADED);
      expect(SUCCEEDED(hr2), isTrue);
      expect(hr2, equals(S_FALSE));

      // Balance out uninitialization. This is deliberately called twice.
      RoUninitialize();
      RoUninitialize();
    });

    test('WinRT change of threading model should fail', () {
      final hr = RoInitialize(RO_INIT_TYPE.RO_INIT_MULTITHREADED);
      expect(SUCCEEDED(hr), isTrue);
      expect(hr, equals(S_OK));

      final hr2 = RoInitialize(RO_INIT_TYPE.RO_INIT_SINGLETHREADED);
      expect(FAILED(hr2), isTrue);
      expect(hr2, equals(RPC_E_CHANGED_MODE));

      // Balance out uninitialization. This is deliberately only called once,
      // because it only succeeded once.
      RoUninitialize();
    });

    test('WinRT basic test', () {
      winrtInitialize();

      final object =
          CreateObject('Windows.Globalization.Calendar', IID_ICalendar);
      final calendar = ICalendar(object);

      expect(calendar.Year, greaterThanOrEqualTo(2020));
      free(object);
      winrtUninitialize();
    });

    test('WinRT getRuntimeClassName test', () {
      winrtInitialize();

      const calendarClassName = 'Windows.Globalization.Calendar';

      final object = CreateObject(calendarClassName, IID_ICalendar);
      final calendar = ICalendar(object);

      expect(calendar.runtimeClassName, equals(calendarClassName));

      free(object);
      winrtUninitialize();
    });

    test('WinRT getTrustLevel test of base trust class', () {
      winrtInitialize();

      const calendarClassName = 'Windows.Globalization.Calendar';

      final object = CreateObject(calendarClassName, IID_ICalendar);
      final calendar = ICalendar(object);

      expect(calendar.trustLevel, equals(TrustLevel.baseTrust));

      free(object);
      winrtUninitialize();
    });

    test('WinRT getTrustLevel test of partial trust class', () {
      winrtInitialize();

      const className = 'Windows.Storage.Pickers.FileOpenPicker';

      final object = CreateObject(className, IID_IInspectable);
      final inspectableObject = IInspectable(object);

      expect(inspectableObject.trustLevel, equals(TrustLevel.partialTrust));

      free(object);
      winrtUninitialize();
    });
  }
}
