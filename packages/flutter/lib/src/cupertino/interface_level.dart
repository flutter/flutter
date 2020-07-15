// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/foundation.dart';

import '../widgets/framework.dart';

/// Indicates the visual level for a piece of content. Equivalent to `UIUserInterfaceLevel`
/// from `UIKit`.
///
/// See also:
///
///  * `UIUserInterfaceLevel`, the UIKit equivalent: https://developer.apple.com/documentation/uikit/uiuserinterfacelevel.
enum CupertinoUserInterfaceLevelData {
  /// The level for your window's main content.
  base,

  /// The level for content visually above [base].
  elevated,
}

/// Establishes a subtree in which [CupertinoUserInterfaceLevel.of] resolves to
/// the given data.
///
/// Querying the current elevation status using [CupertinoUserInterfaceLevel.of]
/// will cause your widget to rebuild automatically whenever the [CupertinoUserInterfaceLevelData]
/// changes.
///
/// If no [CupertinoUserInterfaceLevel] is in scope then the [CupertinoUserInterfaceLevel.of]
/// method will throw an exception, unless the `nullOk` argument is set to true,
/// in which case it returns null.
///
/// See also:
///
///  * [CupertinoUserInterfaceLevelData], specifies the visual level for the content
///    in the subtree [CupertinoUserInterfaceLevel] established.
class CupertinoUserInterfaceLevel extends InheritedWidget {
  /// Creates a [CupertinoUserInterfaceLevel] to change descendant Cupertino widget's
  /// visual level.
  const CupertinoUserInterfaceLevel({
    Key key,
    @required CupertinoUserInterfaceLevelData data,
    Widget child,
  }) : assert(data != null),
      _data = data,
      super(key: key, child: child);

  final CupertinoUserInterfaceLevelData _data;

  @override
  bool updateShouldNotify(CupertinoUserInterfaceLevel oldWidget) => oldWidget._data != _data;

  /// The data from the closest instance of this class that encloses the given
  /// context.
  ///
  /// You can use this function to query the user interface elevation level within
  /// the given [BuildContext]. When that information changes, your widget will
  /// be scheduled to be rebuilt, keeping your widget up-to-date.
  static CupertinoUserInterfaceLevelData of(BuildContext context, { bool nullOk = false }) {
    assert(context != null);
    assert(nullOk != null);
    final CupertinoUserInterfaceLevel query = context.dependOnInheritedWidgetOfExactType<CupertinoUserInterfaceLevel>();
    if (query != null)
      return query._data;
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<CupertinoUserInterfaceLevelData>('user interface level', _data));
  }
}
