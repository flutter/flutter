// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

void main() {
  // Changes made in https://github.com/flutter/flutter/pull/68921
  Actions.find(error: '');
  Actions.find(context, nullOk: true);
  Actions.find(context, nullOk: false);
  Actions.handler(context, nullOk: true);
  Actions.handler(context, nullOk: false);
  Actions.handler(error: '');
  Actions.invoke(error: '');
  Actions.invoke(context, nullOk: true);
  Actions.invoke(context, nullOk: false);
}
