// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:sky' as sky;

typedef void Callback(double timeStamp);

bool _haveScheduledVisualUpdate = false;
int _nextCallbackId = 1;

final List<Callback> _persistentCallbacks = new List<Callback>();
Map<int, Callback> _transientCallbacks = new Map<int, Callback>();

void _beginFrame(double timeStamp) {
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
  assert(sky.window == null);
  sky.view.setBeginFrameCallback(_beginFrame);
}

void addPersistentFrameCallback(Callback callback) {
  assert(sky.window == null);
  _persistentCallbacks.add(callback);
}

int requestAnimationFrame(Callback callback) {
  if (sky.window != null)
    return sky.window.requestAnimationFrame(callback);
  int id = _nextCallbackId++;
  _transientCallbacks[id] = callback;
  ensureVisualUpdate();
  return id;
}

void cancelAnimationFrame(int id) {
  if (sky.window != null)
    return sky.window.cancelAnimationFrame(id);
  _transientCallbacks.remove(id);
}

void ensureVisualUpdate() {
  assert(sky.window == null);
  if (_haveScheduledVisualUpdate)
    return;
  sky.view.scheduleFrame();
  _haveScheduledVisualUpdate = true;
}
