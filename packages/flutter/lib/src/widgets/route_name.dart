// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A widget which provides a semantic name for a route.
///
/// On iOS, no additional semantic information is inserted.
///
/// See also:
///
///  * [SemanticsProperties.routeName], for a description of how route name
///    semantics work.
class RouteName extends StatelessWidget  {
  /// Creates a widget which provides a semantic route name.
  ///
  /// [child] and [routeName] are required arguments.
  const RouteName({
    Key key,
    this.child,
    @required this.routeName,
  }) : super(key: key);

  /// A semantic name for the route.
  /// 
  /// On iOS platforms this value is ignored.
  final String routeName;

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  @override
  Widget build(BuildContext context) {
    Widget result;
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        result = child;
        break;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        result = new Semantics(
          namesRoute: true,
          explicitChildNodes: true,
          label: routeName,
          child: child,
        );
        break;
    }
    return result;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(new StringProperty('routeName', routeName, defaultValue: null));
  }
}
