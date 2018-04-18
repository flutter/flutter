// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../android/android_sdk.dart';
import '../android/android_workflow.dart';
import '../base/process.dart';
import '../emulator.dart';
import 'android_sdk.dart';

class AndroidEmulators extends EmulatorDiscovery {
  @override
  bool get supportsPlatform => true;

  @override
  bool get canListAnything => androidWorkflow.canListDevices;

  @override
  Future<List<Emulator>> get emulators async => getEmulatorAvds();
}

class AndroidEmulator extends Emulator {
  AndroidEmulator(
    String id
  ) : super(id);

  @override
  String get name => id;

  // @override
  // Future<bool> launch() async {
  //   // TODO: ...
  //   return null;Í
  // }
}

/// Return the list of available emulator AVDs.
List<AndroidEmulator> getEmulatorAvds() {
  final String emulatorPath = getEmulatorPath(androidSdk);
  if (emulatorPath == null)
    return <AndroidEmulator>[];
  final String text = runSync(<String>[emulatorPath, '-list-avds']);
  final List<AndroidEmulator> devices = <AndroidEmulator>[];
  parseEmulatorAvdOutput(text, devices);
  return devices;
}

/// Parse the given `emulator -list-avds` output in [text], and fill out the given list
/// of emulators.
@visibleForTesting
void parseEmulatorAvdOutput(String text,
  List<AndroidEmulator> emulators) {
  for (String line in text.trim().split('\n')) {
    emulators.add(new AndroidEmulator(line));
  }
}
