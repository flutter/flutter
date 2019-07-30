// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../widgets/framework.dart';

enum CupertinoUserInterfaceLevelData {
  elevated, base
}

class CupertinoUserInterfaceLevel extends InheritedWidget {
  const CupertinoUserInterfaceLevel({
    Key key,
    @required this.data,
    Widget child,
  })
    : assert(data != null),
      super(key: key, child: child);

  final CupertinoUserInterfaceLevelData data;

  @override
  bool updateShouldNotify(CupertinoUserInterfaceLevel oldWidget) => oldWidget.data != data;

  static CupertinoUserInterfaceLevelData of(BuildContext context, { bool nullOk = false }) {
    assert(context != null);
    assert(nullOk != null);
    final CupertinoUserInterfaceLevel query = context.inheritFromWidgetOfExactType(CupertinoUserInterfaceLevel);
    if (query != null)
      return query.data;
    if (nullOk)
      return null;
    throw FlutterError(
      'CupertinoUserInterfaceLevel.of() called with a context that does not contain a CupertinoUserInterfaceLevel.\n'
      'No CupertinoUserInterfaceLevel ancestor could be found starting from the context that was passed '
      'to CupertinoUserInterfaceLevel.of(). This can happen because you do not have a WidgetsApp or '
      'MaterialApp widget (those widgets introduce a CupertinoUserInterfaceLevel), or it can happen '
      'if the context you use comes from a widget above those widgets.\n'
      'The context used was:\n'
      '  $context'
    );
  }
}
