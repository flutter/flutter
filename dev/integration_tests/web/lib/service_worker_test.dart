// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;
import 'package:flutter/services.dart';

Future<void> main() async {
  await rootBundle.load('lib/a.dart');
  await rootBundle.load('lib/b.dart');
  await html.HttpRequest.getString('CLOSE');
}
