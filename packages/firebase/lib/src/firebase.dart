// Copyright 2015, the Flutter authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:sky_services/firebase/firebase.mojom.dart' as mojo;

export 'package:sky_services/firebase/firebase.mojom.dart' show DataSnapshot, EventType;

class Firebase {

  mojo.FirebaseProxy _firebase;

  Firebase(String url) : _firebase = new mojo.FirebaseProxy.unbound() {
    shell.connectToService("firebase::Firebase", _firebase);
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

  Future<mojo.DataSnapshot> once(mojo.EventType eventType) async {
    return (await _firebase.ptr.observeSingleEventOfType(eventType)).snapshot;
  }
}
