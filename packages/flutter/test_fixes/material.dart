// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

void main() {
  // Change made in https://github.com/flutter/flutter/pull/15303
  showDialog(child: Text('Fix me.'));

  // Changes made in https://github.com/flutter/flutter/pull/45941
  final WidgetsBinding binding = WidgetsBinding.instance!;
  binding.deferFirstFrameReport();
  binding.allowFirstFrameReport();

  // Changes made in https://github.com/flutter/flutter/pull/44189
  const StatefulElement statefulElement = StatefulElement(myWidget);
  statefulElement.inheritFromElement(ancestor);

  // Changes made in https://github.com/flutter/flutter/pull/44189
  const BuildContext buildContext = Element(myWidget);
  buildContext.inheritFromElement(ancestor);
  buildContext.inheritFromWidgetOfExactType(targetType);
  buildContext.ancestorInheritedElementForWidgetOfExactType(targetType);
  buildContext.ancestorWidgetOfExactType(targetType);
  buildContext.ancestorStateOfType(TypeMatcher<targetType>());
  buildContext.rootAncestorStateOfType(TypeMatcher<targetType>());
  buildContext.ancestorRenderObjectOfType(TypeMatcher<targetType>());
}
