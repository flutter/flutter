// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Plays a MIDI file using MCI_OPEN and MCI_PLAY.

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

void main() {
  // Open the device by specifying the device and filename.
  // MCI will attempt to choose the MIDI mapper as the output port.
  final deviceType = TEXT('sequencer');
  final elementName = TEXT(r'c:\Windows\Media\flourish.mid');
  final mciOpenParams = calloc<MCI_OPEN_PARMS>()
    ..ref.lpstrDeviceType = deviceType
    ..ref.lpstrElementName = elementName;

  var dwReturn = mciSendCommand(
      NULL, MCI_OPEN, MCI_OPEN_TYPE | MCI_OPEN_ELEMENT, mciOpenParams.address);

  if (dwReturn != 0) {
    // Don't close it; just return error.
    print('Failed to open device.');
    exit(dwReturn);
  }

  // The device opened successfully; get the device ID.
  final deviceID = mciOpenParams.ref.wDeviceID;

  // Check if the output port is the MIDI mapper.
  final mciStatusParams = calloc<MCI_STATUS_PARMS>()
    ..ref.dwItem = MCI_SEQ_STATUS_PORT;

  dwReturn = mciSendCommand(
      deviceID, MCI_STATUS, MCI_STATUS_ITEM, mciStatusParams.address);

  if (dwReturn != 0) {
    print('Status command failed.');
    mciSendCommand(deviceID, MCI_CLOSE, 0, NULL);
    exit(dwReturn);
  }

  // The output port is not the MIDI mapper.
  // Ask if the user wants to continue.
  if (LOWORD(mciStatusParams.ref.dwReturn) != MIDI_MAPPER) {
    final warningMessage = TEXT('The MIDI mapper is not available. Continue?');
    try {
      if (MessageBox(NULL, warningMessage, nullptr, MB_YESNO) == IDNO) {
        // User does not want to continue. Not an error;
        // just close the device and return.
        mciSendCommand(deviceID, MCI_CLOSE, 0, NULL);
        return;
      }
    } finally {
      free(warningMessage);
    }
  }

  // Begin playback. The command will not return until playback has finished,
  // unless Ctrl+Break is pressed.
  final mciPlayParams = calloc<MCI_PLAY_PARMS>();
  dwReturn =
      mciSendCommand(deviceID, MCI_PLAY, MCI_WAIT, mciPlayParams.address);

  mciSendCommand(deviceID, MCI_CLOSE, 0, NULL);

  if (dwReturn != 0) {
    print('Playback failed.');
    exit(dwReturn);
  }

  final message = TEXT('Press OK to stop');
  final caption = TEXT('Midi Sample');
  MessageBox(NULL, message, caption, MB_OK);

  // Clear up
  free(message);
  free(caption);

  free(mciPlayParams);
  free(mciStatusParams);
  free(mciOpenParams);
  free(deviceType);
  free(elementName);
}
