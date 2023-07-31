// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';

final _usage = 'Usage: dart hash.dart <md5|sha1|sha256> <input_filename>';

Future<void> main(List<String> args) async {
  if (args.length != 2) {
    print(_usage);
    exitCode = 64; // Command was used incorrectly.
    return;
  }

  Hash hasher;

  switch (args[0]) {
    case 'md5':
      hasher = md5;
      break;
    case 'sha1':
      hasher = sha1;
      break;
    case 'sha256':
      hasher = sha256;
      break;
    default:
      print(_usage);
      exitCode = 64; // Command was used incorrectly.
      return;
  }

  var filename = args[1];
  var input = File(filename);

  if (!input.existsSync()) {
    print('File "$filename" does not exist.');
    exitCode = 66; // An input file did not exist or was not readable.
    return;
  }

  var value = await hasher.bind(input.openRead()).first;

  print(value);
}
