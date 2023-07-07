// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Support code to generate the hex-lists in test/decode_test.dart from
// a hex-stream.
import 'dart:io';

void formatHexStream(String hexStream) {
  String s = '';
  for (int i = 0; i < hexStream.length / 2; i++) {
    if (s.isNotEmpty) {
      s += ', ';
    }
    s += '0x';
    final String x = hexStream.substring(i * 2, i * 2 + 2);
    s += x;
    if (((i + 1) % 8) == 0) {
      s += ',';
      print(s);
      s = '';
    }
  }
  if (s.isNotEmpty) {
    print(s);
  }
}

// Support code for generating the hex-lists in test/decode_test.dart.
void hexDumpList(List<int> package) {
  String s = '';
  for (int i = 0; i < package.length; i++) {
    if (s.isNotEmpty) {
      s += ', ';
    }
    s += '0x';
    final String x = package[i].toRadixString(16);
    if (x.length == 1) {
      s += '0';
    }
    s += x;
    if (((i + 1) % 8) == 0) {
      s += ',';
      print(s);
      s = '';
    }
  }
  if (s.isNotEmpty) {
    print(s);
  }
}

void dumpDatagram(Datagram datagram) {
  String _toHex(List<int> ints) {
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < ints.length; i++) {
      buffer.write(ints[i].toRadixString(16).padLeft(2, '0'));
      if ((i + 1) % 10 == 0) {
        buffer.writeln();
      } else {
        buffer.write(' ');
      }
    }
    return buffer.toString();
  }

  print('${datagram.address.address}:${datagram.port}:');
  print(_toHex(datagram.data));
  print('');
}
