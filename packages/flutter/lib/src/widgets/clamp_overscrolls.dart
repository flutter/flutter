// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'framework.dart';

/// If true, the ClampOverscroll's [Scrollable] descendant will clamp its
/// viewport's scrollOffsets to the [ScrollBehavior]'s min and max values.
/// In this case the Scrollable's scrollOffset will still over and undershoot
/// the ScrollBehavior's limits, but the viewport itself will not.
class ClampOverscrolls extends InheritedWidget {
  ClampOverscrolls({
    Key key,
    this.value,
    Widget child
  }) : super(key: key, child: child) {
    assert(value != null);
    assert(child != null);
  }

  /// True if the [Scrollable] descendant should clamp its viewport's scrollOffset
  /// values when they are less than the [ScrollBehavior]'s minimum or greater than
  /// its maximum.
  final bool value;

  static bool of(BuildContext context) {
    final ClampOverscrolls result = context.inheritFromWidgetOfExactType(ClampOverscrolls);
    return result?.value ?? false;
  }

  @override
  bool updateShouldNotify(ClampOverscrolls old) => value != old.value;

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('value: $value');
  }
}
