// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'basic.dart';
import 'framework.dart';
import 'layout_builder.dart';
import 'media_query.dart';

/// Signature for a function that builds a widget given an [Orientation].
///
/// Used by [OrientationBuilder.builder].
typedef OrientationWidgetBuilder = Widget Function(BuildContext context, Orientation orientation);

/// Builds a widget tree that can depend on the parent widget's orientation
/// (distinct from the device orientation).
///
/// See also:
///
///  * [LayoutBuilder], which exposes the complete constraints, not just the
///    orientation.
///  * [CustomSingleChildLayout], which positions its child during layout.
///  * [CustomMultiChildLayout], with which you can define the precise layout
///    of a list of children during the layout phase.
///  * [MediaQueryData.orientation], which exposes whether the device is in
///    landscape or portrait mode.
class OrientationBuilder extends StatelessWidget {
  /// Creates an orientation builder.
  const OrientationBuilder({super.key, required this.builder});

  /// Builds the widgets below this widget given this widget's orientation.
  ///
  /// A widget's orientation is a factor of its width relative to its
  /// height. For example, a [Column] widget will have a landscape orientation
  /// if its width exceeds its height, even though it displays its children in
  /// a vertical array.
  final OrientationWidgetBuilder builder;

  Widget _buildWithConstraints(BuildContext context, BoxConstraints constraints) {
    // If the constraints are fully unbounded (i.e., maxWidth and maxHeight are
    // both infinite), we prefer Orientation.portrait because its more common to
    // scroll vertically then horizontally.
    final Orientation orientation = constraints.maxWidth > constraints.maxHeight
        ? Orientation.landscape
        : Orientation.portrait;
    return builder(context, orientation);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: _buildWithConstraints);
  }
}

/// Builds a widget tree that can depend on the device's orientation.
///
/// The orientation is obtained from [MediaQuery.orientationOf], which reflects
/// the actual device orientation as reported by the platform. This ensures
/// consistency with [MediaQueryData.orientation] and correct behavior on
/// foldable devices and other scenarios where the device orientation may differ
/// from layout dimensions.
///
/// This is different from [OrientationBuilder], which determines orientation
/// based on the parent widget's layout constraints (width vs height), not the
/// device's physical orientation.
///
/// {@tool snippet}
/// This example shows how to use [DeviceOrientationBuilder] to display
/// different widgets based on the device orientation.
///
/// ```dart
/// DeviceOrientationBuilder(
///   builder: (BuildContext context, Orientation orientation) {
///     return Text(orientation == Orientation.portrait
///         ? 'Device is in Portrait'
///         : 'Device is in Landscape');
///   },
/// )
/// ```
/// {@end-tool}
///
/// This widget requires a [MediaQuery] ancestor to obtain the orientation.
/// Typically, this is provided by [MaterialApp] or [WidgetsApp].
///
/// See also:
///
///  * [OrientationBuilder], which builds based on parent widget's layout
///    constraints rather than device orientation.
///  * [MediaQueryData.orientation], which provides the device orientation
///    directly from [MediaQuery].
///  * [LayoutBuilder], which exposes the complete layout constraints.
class DeviceOrientationBuilder extends StatelessWidget {
  /// Creates a device orientation builder.
  const DeviceOrientationBuilder({super.key, required this.builder});

  /// Builds the widgets below this widget given the device's orientation.
  ///
  /// The orientation is obtained from [MediaQuery.orientationOf], which
  /// reflects the actual device orientation as reported by the platform.
  final OrientationWidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    final Orientation orientation = MediaQuery.orientationOf(context);
    return builder(context, orientation);
  }
}
