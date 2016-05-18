// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'basic.dart';
import 'framework.dart';
import 'scroll_behavior.dart';

typedef Widget WrapScrollWidget(Widget scrollWidget);

class ScrollConfiguration extends InheritedWidget {
  ScrollConfiguration({
    Key key,
    this.createScrollBehavior,
    this.wrapScrollWidget,
    Widget child
  }) : super(key: key, child: child);

  final ValueGetter<ExtentScrollBehavior> createScrollBehavior;

  final WrapScrollWidget wrapScrollWidget;

  static ScrollConfiguration of(BuildContext context) {
    return context.inheritFromWidgetOfExactType(ScrollConfiguration);
  }

  static Widget wrap(BuildContext context, Widget scrollWidget) {
    WrapScrollWidget wrap = of(context)?.wrapScrollWidget;
    return (wrap != null) ? wrap(scrollWidget) : scrollWidget;
  }

  @override
  bool updateShouldNotify(ScrollConfiguration old) {
   return createScrollBehavior != old.createScrollBehavior ||
      wrapScrollWidget != wrapScrollWidget;
  }
}
