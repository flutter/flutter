// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A widget which scopes and names a route.
///
/// On Android, TalkBack uses [routeName] as the text value for an edge 
/// triggered semantics update. On iOS, no additional semantic information
/// is inserted since by convention VoiceOver uses a standard chime sound 
/// effect for most navigation events.
///
/// See also:
///
///  * [SemanticsProperties.namesRoute], for a description of how route name
///    semantics work.
class RouteName extends StatelessWidget  {
  /// Creates a widget which provides a semantic route name.
  ///
  /// [child] and [routeName] are required arguments.
  const RouteName({
    Key key,
    @required this.child,
    @required this.routeName,
  }) : assert(child != null),
       super(key: key);

  /// A semantic label for the route.
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
          scopesRoute: true,
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
