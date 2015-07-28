// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import 'package:sky/base/debug.dart';

typedef void Callback(double timeStamp);

bool _haveScheduledVisualUpdate = false;
int _nextCallbackId = 1;

final List<Callback> _persistentCallbacks = new List<Callback>();
Map<int, Callback> _transientCallbacks = new Map<int, Callback>();

void _beginFrame(double timeStamp) {
  timeStamp /= timeDilation;

  _haveScheduledVisualUpdate = false;

  Map<int, Callback> callbacks = _transientCallbacks;
  _transientCallbacks = new Map<int, Callback>();

  callbacks.forEach((id, callback) {
    callback(timeStamp);
  });

  for (Callback callback in _persistentCallbacks)
    callback(timeStamp);
}

void init() {
  sky.view.setFrameCallback(_beginFrame);
}

void addPersistentFrameCallback(Callback callback) {
  _persistentCallbacks.add(callback);
}

int requestAnimationFrame(Callback callback) {
  int id = _nextCallbackId++;
  _transientCallbacks[id] = callback;
  ensureVisualUpdate();
  return id;
}

void cancelAnimationFrame(int id) {
  _transientCallbacks.remove(id);
}

void ensureVisualUpdate() {
  if (_haveScheduledVisualUpdate)
    return;
  sky.view.scheduleFrame();
  _haveScheduledVisualUpdate = true;
}
