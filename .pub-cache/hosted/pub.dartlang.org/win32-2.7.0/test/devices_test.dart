@TestOn('windows')

import 'dart:ffi';
import 'package:ffi/ffi.dart';

import 'package:test/test.dart';
import 'package:win32/win32.dart';

void main() {
  test('Volume management API', () {
    final volumeNamePtr = wsalloc(MAX_PATH);

    final hFindVolume = FindFirstVolume(volumeNamePtr, MAX_PATH);
    expect(hFindVolume, isNot(INVALID_HANDLE_VALUE));

    final volume = volumeNamePtr.toDartString();

    expect(volume, startsWith(r'\\?\'));

    free(volumeNamePtr);
  });

  test('Power management API', () {
    final powerStatus = calloc<SYSTEM_POWER_STATUS>();

    final result = GetSystemPowerStatus(powerStatus);

    // Sanity check results against some API provided ranges
    final validBatteryPercentages = [for (var i = 0; i <= 100; i += 1) i, 255];

    expect(result, isNonZero);
    expect(powerStatus.ref.ACLineStatus, isIn([0, 1, 255]));
    expect(powerStatus.ref.SystemStatusFlag, isIn([0, 1]));
    expect(powerStatus.ref.BatteryLifePercent, isIn(validBatteryPercentages));

    free(powerStatus);
  });

  test('CallNtPowerInformation() sanity check', () {
    final batteryStatus = calloc<SYSTEM_BATTERY_STATE>();

    final result = CallNtPowerInformation(
        POWER_INFORMATION_LEVEL.SystemBatteryState,
        nullptr,
        0,
        batteryStatus,
        sizeOf<SYSTEM_BATTERY_STATE>());

    // Sanity check results against some API provided ranges
    expect(result, equals(STATUS_SUCCESS));
    expect(batteryStatus.ref.AcOnLine, isIn([FALSE, TRUE]));
    expect(batteryStatus.ref.BatteryPresent, isIn([FALSE, TRUE]));
    expect(batteryStatus.ref.Charging, isIn([FALSE, TRUE]));
    expect(batteryStatus.ref.Discharging, isIn([FALSE, TRUE]));

    free(batteryStatus);
  });
}
