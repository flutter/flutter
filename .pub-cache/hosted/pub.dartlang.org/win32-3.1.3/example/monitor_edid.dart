// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Reads out the EDID information of the monitor.

// ignore_for_file: camel_case_extensions

import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

class Size {
  final int width;
  final int height;
  const Size({required this.width, required this.height});
}

Size getMonitorSizeInMM() {
  final guidptr = GUIDFromString(GUID_CLASS_MONITOR);
  // Get the handle for the first monitor.
  final ptr = SetupDiGetClassDevs(guidptr, nullptr, 0, DIGCF_PRESENT);
  var width = 0;
  var height = 0;

  final data = calloc<SP_DEVINFO_DATA>();
  data.ref.cbSize = sizeOf<SP_DEVINFO_DATA>();
  // Get the device information for the first member of the first monitor
  final ret = SetupDiEnumDeviceInfo(ptr, 0, data);
  if (ret == TRUE) {
    // Get the registry key for the first member of the first monitor
    final hDevRegKey = SetupDiOpenDevRegKey(
        ptr, data, DICS_FLAG_GLOBAL, 0, DIREG_DEV, KEY_READ);

    const nameSize = 128;
    final lpValueName = wsalloc(nameSize);
    const edidDataSize = 256;

    final lpcchValueName = calloc<DWORD>()..value = nameSize;
    final lpData = calloc<BYTE>(edidDataSize);
    final lpcbData = calloc<DWORD>()..value = edidDataSize;

    // Get the first value of the registry key for the first member of the first monitor
    final retValue = RegEnumValue(hDevRegKey, 0, lpValueName, lpcchValueName,
        nullptr, nullptr, lpData, lpcbData);

    // https://en.wikipedia.org/wiki/Extended_Display_Identification_Data
    // Extended Display Identification Data (EDID) of the first monitor
    // 128-256 bytes of data
    //
    // EDID Detailed Timing Descriptor is stored in bytes 54-71
    // 54 + 12 = 66. byte = Horizontal image size, mm, 8 lsbits (0–255 mm, 161 in)
    const hSize = 66;
    // 54 + 13 = 67. byte = Vertical image size, mm, 8 lsbits (0–255 mm, 161 in)
    const vSize = 67;
    const bound = 68;
    // lpData contains the width and height of the monitor in millimeters which are
    // extracted by accessing the correct bytes.
    if (retValue == ERROR_SUCCESS && lpValueName.toDartString() == 'EDID') {
      width = ((lpData[bound] & 0xF0) << 4) + lpData[hSize];
      height = ((lpData[bound] & 0x0F) << 8) + lpData[vSize];
    }

    free(lpValueName);
    free(lpcchValueName);
    free(lpData);
    free(lpcbData);

    RegCloseKey(hDevRegKey);
  }
  free(data);

  SetupDiDestroyDeviceInfoList(ptr);
  free(guidptr);
  return Size(width: width, height: height);
}

Size getMonitorSizeInMMBackup() {
  final hdc = GetDC(NULL);
  final width = GetDeviceCaps(hdc, 4);
  final height = GetDeviceCaps(hdc, 6);
  return Size(width: width, height: height);
}

void main() {
  final size = getMonitorSizeInMM();
  print('Physical Size of Monitor: '
      'Width: ${size.width}mm Height: ${size.height}mm');
  final sizeBackup = getMonitorSizeInMMBackup();
  print('Physical Size of Monitor Backup: '
      'Width: ${sizeBackup.width}mm Height: ${sizeBackup.height}mm');
}
