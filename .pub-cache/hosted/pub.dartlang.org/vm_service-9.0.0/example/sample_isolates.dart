// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate';

void main(List<String> args) async {
  var arr = newArray(5);
  var arr2 = newArray(417);
  var hash1 = newHash(5);
  var hash2 = newHash(417);

  // ignore unused
  arr.length;
  arr2.length;
  hash1.length;
  hash2.length;

  startIsolate(1);
  startIsolate(2);
  startIsolate(3);
  startIsolate(4);

  await Future.delayed(Duration(seconds: 5));

  print('at end of main...');
}

void startIsolate(int val) {
  Isolate.spawn(isolateEntry, val);
}

Future isolateEntry(message) async {
  print('starting $message');
  await Future.delayed(Duration(seconds: message));
  print('ending $message');
}

List newArray(int length) {
  List l = [];
  for (int i = 0; i < length; i++) {
    l.add('entry_$i');
  }
  return l;
}

Map newHash(int length) {
  Map m = {};
  for (int i = 0; i < length; i++) {
    m['entry_$i'] = i;
  }
  return m;
}
