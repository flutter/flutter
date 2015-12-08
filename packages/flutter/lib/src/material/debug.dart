// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'material.dart';

bool debugCheckHasMaterial(BuildContext context) {
  assert(() {
    if (context.widget is Material || context.ancestorWidgetOfType(Material) != null)
      return true;
    Element element = context;
    debugPrint('${context.widget} needs to be placed inside a Material widget. Ownership chain:\n${element.debugGetOwnershipChain(10)}');
    return false;
  });
  return true;
}
