// Copyright 2015, the Flutter authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:sky_services/firebase/firebase.mojom.dart' as mojo;

enum EventType {
  added,
  removed,
  changed,
  moved,
  value
}

class _WrappedEventType {
  const _WrappedEventType(this._eventType);
  final EventType _eventType;
  int get value {
    switch (_eventType) {
      case EventType.added: return 0;
      case EventType.removed: return 1;
      case EventType.changed: return 2;
      case EventType.moved: return 3;
      case EventType.value: return 4;
    }
  }
}

class Firebase {

  mojo.FirebaseProxy _firebase;

  Firebase(String url) : _firebase = new mojo.FirebaseProxy.unbound() {
    shell.connectToService(null, _firebase);
    _firebase.ptr.initWithUrl(url);
  }

  Firebase._withProxy(mojo.FirebaseProxy firebase) : _firebase = firebase;

  Firebase get root {
    mojo.FirebaseProxy proxy = new mojo.FirebaseProxy.unbound();
    _firebase.ptr.getRoot(proxy);
    return new Firebase._withProxy(proxy);
  }

  Firebase childByAppendingPath(String path) {
    mojo.FirebaseProxy proxy = new mojo.FirebaseProxy.unbound();
    _firebase.ptr.getChild(path, proxy);
    return new Firebase._withProxy(proxy);
  }

  Future<mojo.DataSnapshot> once(EventType eventType) {
    var completer = new Completer<mojo.DataSnapshot>();
    _firebase.ptr.observeSingleEventOfType(
      new _WrappedEventType(eventType),
      (mojo.DataSnapshot snapshot) => completer.complete(snapshot)
    );
    return completer.future;
  }
}
