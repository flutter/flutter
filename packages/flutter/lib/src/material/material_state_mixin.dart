// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'material_state.dart';

/// Mixin for [State] classes that require knowledge of changing [MaterialState]
/// values for their child widgets.
///
/// This mixin does nothing by mere application to a [State] class, but is
/// helpful when writing `build` methods that include child [InkWell],
/// [GestureDetector], [MouseRegion], or [Focus] widgets. Instead of manually
/// creating handlers for each type of user interaction, such [State] classes can
/// instead provide a `ValueChanged<bool>` function and allow [MaterialStateMixin]
/// to manage the set of active [MaterialState]s, and the calling of [setState]
/// as necessary.
///
/// {@tool snippet}
/// This example shows how to write a [StatefulWidget] that uses the
/// [MaterialStateMixin] class to watch [MaterialState] values.
///
/// ```dart
/// class MyWidget extends StatefulWidget {
///   const MyWidget({super.key, required this.color, required this.child});
///
///   final MaterialStateColor color;
///   final Widget child;
///
///   @override
///   State<MyWidget> createState() => MyWidgetState();
/// }
///
/// class MyWidgetState extends State<MyWidget> with MaterialStateMixin<MyWidget> {
///   @override
///   Widget build(BuildContext context) {
///     return InkWell(
///       onFocusChange: updateMaterialState(MaterialState.focused),
///       child: ColoredBox(
///         color: widget.color.resolve(materialStates),
///         child: widget.child,
///       ),
///     );
///   }
/// }
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [WidgetStateMixin], the generic version of `MaterialStatesController`
///    that can be used with non-Material widgets.
@optionalTypeArgs
@Deprecated(
  'Use WidgetStateMixin instead. '
  'Deprecated to make code available outside of Material. '
  'This feature was deprecated after [beta version at time of deprecation].'
)
typedef MaterialStateMixin = WidgetStateMixin;
