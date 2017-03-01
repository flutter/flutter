// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'framework.dart';
import 'scroll_controller.dart';

class PrimaryScrollController extends InheritedWidget {
  PrimaryScrollController({
    Key key,
    @required this.controller,
    @required Widget child
  }) : super(key: key, child: child) {
    assert(controller != null);
  }

  const PrimaryScrollController.none({
    Key key,
    @required Widget child
  }) : super(key: key, child: child);

  final ScrollController controller;

  static ScrollController of(BuildContext context) {
    PrimaryScrollController result = context.inheritFromWidgetOfExactType(PrimaryScrollController);
    return result?.controller;
  }

  @override
  bool updateShouldNotify(PrimaryScrollController old) => controller != old.controller;

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('${controller ?? 'no controller'}');
  }
}
