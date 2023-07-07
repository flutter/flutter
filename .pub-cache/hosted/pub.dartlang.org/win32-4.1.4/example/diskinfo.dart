// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Prints information about the physical characteristics of a disk drive.

// ignore_for_file: non_constant_identifier_names

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

bool GetDriveGeometry(Pointer<Utf16> wszPath, Pointer<DISK_GEOMETRY> pdg) {
  final bytesReturned = calloc<Uint32>();

  try {
    final hDevice = CreateFile(
        wszPath, // drive to open
        0, // no access to the drive
        FILE_SHARE_READ | FILE_SHARE_WRITE,
        nullptr, // default security attributes
        OPEN_EXISTING,
        0, // file attributes
        NULL); // do not copy file attributes

    if (hDevice == INVALID_HANDLE_VALUE) // cannot open the drive
    {
      return false;
    }

    final bResult = DeviceIoControl(
        hDevice, // device to be queried
        IOCTL_DISK_GET_DRIVE_GEOMETRY, // operation to perform
        nullptr,
        0, // no input buffer
        pdg,
        sizeOf<DISK_GEOMETRY>(), // output buffer
        bytesReturned, // # bytes returned
        nullptr); // synchronous I/O

    CloseHandle(hDevice);

    return bResult == TRUE;
  } finally {
    free(bytesReturned);
  }
}

void main() {
  final wszDrive = r"\\.\PhysicalDrive0".toNativeUtf16();
  final pdg = calloc<DISK_GEOMETRY>();

  try {
    final bResult = GetDriveGeometry(wszDrive, pdg);

    if (bResult) {
      print('Drive path      = ${wszDrive.toDartString()}');
      print('Cylinders       = ${pdg.ref.Cylinders}');
      print('Tracks/cylinder = ${pdg.ref.TracksPerCylinder}');
      print('Sectors/track   = ${pdg.ref.SectorsPerTrack}');
      print('Bytes/sector    = ${pdg.ref.BytesPerSector}');

      final DiskSize = pdg.ref.Cylinders *
          pdg.ref.TracksPerCylinder *
          pdg.ref.SectorsPerTrack *
          pdg.ref.BytesPerSector;
      print('Disk size       = $DiskSize (Bytes)\n'
          '                = ${DiskSize / (1024 * 1024 * 1024).toInt()} (Gb)');
    } else {
      print('GetDriveGeometry failed.');
    }
  } finally {
    free(wszDrive);
    free(pdg);
  }
}
