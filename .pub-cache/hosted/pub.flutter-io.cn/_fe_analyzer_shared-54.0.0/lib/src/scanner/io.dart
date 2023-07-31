// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library _fe_analyzer_shared.scanner.io;

import 'dart:io' show File, RandomAccessFile;

import 'dart:typed_data' show Uint8List;

List<int> readBytesFromFileSync(Uri uri) {
  RandomAccessFile file = new File.fromUri(uri).openSync();
  Uint8List list;
  try {
    int length = file.lengthSync();
    // +1 to have a 0 terminated list, see [Scanner].
    list = new Uint8List(length + 1);
    file.readIntoSync(list, /* start = */ 0, length);
  } finally {
    file.closeSync();
  }
  return list;
}

Future<List<int>> readBytesFromFile(Uri uri,
    {bool ensureZeroTermination = true}) async {
  RandomAccessFile file = await new File.fromUri(uri).open();
  Uint8List list;
  try {
    int length = await file.length();
    // +1 to have a 0 terminated list, see [Scanner].
    list = new Uint8List(ensureZeroTermination ? length + 1 : length);
    int read = await file.readInto(list);
    if (read != length) {
      throw "Error reading file: ${uri}";
    }
  } finally {
    await file.close();
  }
  return list;
}
