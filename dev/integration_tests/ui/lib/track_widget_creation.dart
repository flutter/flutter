// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/widgets.dart';

void main() {
  final Set<Widget> widgets = <Widget>{};
  widgets.add(const Text('same'));
  widgets.add(const Text('same'));

  // If track-widget-creation is enabled, the set will have 2 members.
  // Otherwise is will only have one.
  print('SET WIDGETS: ${widgets.length}');
  exit(0);
}
