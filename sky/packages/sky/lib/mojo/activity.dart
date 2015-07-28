// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky';

import 'package:mojom/activity/activity.mojom.dart';
import 'package:sky/mojo/shell.dart' as shell;

export 'package:mojom/activity/activity.mojom.dart' show Intent, ComponentName, StringExtra;

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


void finishCurrentActivity() {
  _activity.ptr.finishCurrentActivity();
}

void startActivity(Intent intent) {
  _activity.ptr.startActivity(intent);
}

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
