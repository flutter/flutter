// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky';
import 'dart:async';

import 'package:sky/mojo/shell.dart' as shell;
import 'package:sky_services/activity/activity.mojom.dart';

export 'package:sky_services/activity/activity.mojom.dart' show Intent, ComponentName, StringExtra, SystemUIVisibility_STANDARD, SystemUIVisibility_FULLSCREEN, SystemUIVisibility_IMMERSIVE;

/// Dart wrapper around Activity mojo service available in Sky on Android.
///
/// Most clients will want to use these methods instead of the activity service
/// directly.

const int NEW_DOCUMENT = 0x00080000;
const int NEW_TASK = 0x10000000;
const int MULTIPLE_TASK = 0x08000000;

ActivityProxy _initActivity() {
  ActivityProxy activity = new ActivityProxy.unbound();
  shell.requestService('mojo:sky_viewer', activity);
  return activity;
}

final ActivityProxy _activity = _initActivity();

Color _cachedPrimaryColor;
String _cachedLabel;

/// Ends the current activity.
void finishCurrentActivity() {
  _activity.ptr.finishCurrentActivity();
}

/// Asks the Android ActivityManager to start a new Intent-based Activity.
void startActivity(Intent intent) {
  _activity.ptr.startActivity(intent);
}

/// Sets the TaskDescription for the current Activity
void updateTaskDescription(String label, Color color) {
  if (_cachedPrimaryColor == color && _cachedLabel == label)
    return;

  _cachedPrimaryColor = color;
  _cachedLabel = label;

  TaskDescription description = new TaskDescription()
    ..label = label
    ..primaryColor = (color != null ? color.value : null);

  _activity.ptr.setTaskDescription(description);
}

int _cachedSystemUiVisibility = SystemUIVisibility_STANDARD;

void setSystemUiVisibility(int visibility) {
  if (_cachedSystemUiVisibility == visibility)
    return;
  _cachedSystemUiVisibility = visibility;
  _activity.ptr.setSystemUiVisibility(visibility);
}

Future<String> getFilesDir() async => (await _activity.ptr.getFilesDir()).path;

Future<String> getCacheDir() async => (await _activity.ptr.getCacheDir()).path;
