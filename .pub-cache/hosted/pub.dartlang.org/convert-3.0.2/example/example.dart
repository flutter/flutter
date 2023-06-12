// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:convert/convert.dart';

void main(List<String> args) {
  // Creates a Codec that converts a UTF-8 strings to/from percent encoding
  final fusedCodec = utf8.fuse(percent);

  final input = args.isNotEmpty ? args.first : 'ABC 123 @!(';
  print(input);
  final encodedMessage = fusedCodec.encode(input);
  print(encodedMessage);

  final decodedMessage = fusedCodec.decode(encodedMessage);
  assert(decodedMessage == input);
}
