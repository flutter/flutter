// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

/// Decodes a UTF8-encoded byte array into a list of Strings, where each list
/// entry represents a line of text.
List<String> decode(List<int> data) =>
    const LineSplitter().convert(utf8.decode(data));

/// Consumes and returns an entire stream of bytes.
Future<List<int>> consume(Stream<List<int>> stream) =>
    stream.expand((List<int> data) => data).toList();
