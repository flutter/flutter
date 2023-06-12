// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:http/http.dart' as http;
import 'package:http/retry.dart';

Future<void> main() async {
  final client = RetryClient(http.Client());
  try {
    print(await client.read(Uri.http('example.org', '')));
  } finally {
    client.close();
  }
}
