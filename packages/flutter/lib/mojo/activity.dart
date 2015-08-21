// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky';
import 'dart:async';

import 'package:sky/mojo/shell.dart' as shell;
import 'package:sky_services/activity/activity.mojom.dart';

export 'package:sky_services/activity/activity.mojom.dart';

/// Dart wrapper around Activity mojo service available in Sky on Android.
///
/// Most clients will want to use these methods instead of the activity service
/// directly.

const int NEW_DOCUMENT = 0x00080000;
const int NEW_TASK = 0x10000000;
const int MULTIPLE_TASK = 0x08000000;

ActivityProxy _initActivityProxy() {
  ActivityProxy activity = new ActivityProxy.unbound();
  shell.requestService('mojo:sky_viewer', activity);
  return activity;
}

final ActivityProxy _activityProxy = _initActivityProxy();
final Activity activity = _activityProxy.ptr;

UserFeedbackProxy _initUserFeedbackProxy() {
  UserFeedbackProxy proxy = new UserFeedbackProxy.unbound();
  _activityProxy.ptr.getUserFeedback(proxy);
  return proxy;
}

final UserFeedbackProxy _userFeedbackProxy = _initUserFeedbackProxy();
final UserFeedback userFeedback = _userFeedbackProxy.ptr;

Color _cachedPrimaryColor;
String _cachedLabel;

/// Sets the TaskDescription for the current Activity
void updateTaskDescription(String label, Color color) {
  if (_cachedPrimaryColor == color && _cachedLabel == label)
    return;

  _cachedPrimaryColor = color;
  _cachedLabel = label;

  TaskDescription description = new TaskDescription()
    ..label = label
    ..primaryColor = (color != null ? color.value : null);

  _activityProxy.ptr.setTaskDescription(description);
}

Future<String> getFilesDir() async => (await _activityProxy.ptr.getFilesDir()).path;
Future<String> getCacheDir() async => (await _activityProxy.ptr.getCacheDir()).path;
