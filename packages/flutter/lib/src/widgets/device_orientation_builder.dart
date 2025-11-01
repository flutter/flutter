// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'framework.dart';
import 'media_query.dart';
import 'orientation_builder.dart';

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
