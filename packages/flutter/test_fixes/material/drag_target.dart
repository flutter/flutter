// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

void main() {
  // Changes made in https://github.com/flutter/flutter/pull/133691
  const dragTarget = DragTarget();
  dragTarget = DragTarget(onWillAccept: (data) => ());
  dragTarget = DragTarget(onWillAcceptWithDetails: (data) => ());

  // Changes made in https://github.com/flutter/flutter/pull/133691
  const dragTarget = DragTarget();
  dragTarget = DragTarget(onAccept: (data) => ());
  dragTarget = DragTarget(onAcceptWithDetails: (data) => ());
}
