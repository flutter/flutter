// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'framework.dart';

/// Applies a [ColorFilter] to its child.
///
/// This widget applies a function independently to each pixel of [child]'s
/// content, according to the [ColorFilter] specified.
/// Use the [ColorFilter.mode] constructor to apply a [Color] using a [BlendMode].
/// Use the [BackdropFilter] widget instead, if the [ColorFilter]
/// needs to be applied onto the content beneath [child].
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=F7Cll22Dno8}
///
/// {@tool dartpad --template=stateless_widget_scaffold}
///
/// These two images have two [ColorFilter]s applied with different [BlendMode]s,
/// one with red color and [BlendMode.modulate] another with a grey color and [BlendMode.saturation].
///
/// ```dart
/// Widget build(BuildContext context) {
///   return SingleChildScrollView(
///     child: Column(
///       children: <Widget>[
///         ColorFiltered(
///           colorFilter: const ColorFilter.mode(
///             Colors.red,
///             BlendMode.modulate,
///           ),
///           child: Image.network(
///               'https://flutter.github.io/assets-for-api-docs/assets/widgets/owl-2.jpg'),
///         ),
///         ColorFiltered(
///           colorFilter: const ColorFilter.mode(
///             Colors.grey,
///             BlendMode.saturation,
///           ),
///           child: Image.network(
///               'https://flutter.github.io/assets-for-api-docs/assets/widgets/owl.jpg'),
///         ),
///       ],
///     ),
///   );
/// }
/// ```
///{@end-tool}
///
/// See Also:
///
///  * [BlendMode], describes how to blend a source image with the destination image.
///  * [ColorFilter], which describes a function that modify a color to a different color.

@immutable
class ColorFiltered extends SingleChildRenderObjectWidget {
  /// Creates a widget that applies a [ColorFilter] to its child.
  ///
  /// The [colorFilter] must not be null.
  const ColorFiltered({required this.colorFilter, Widget? child, Key? key})
      : assert(colorFilter != null),
        super(key: key, child: child);

  /// The color filter to apply to the child of this widget.
  final ColorFilter colorFilter;

  @override
  RenderObject createRenderObject(BuildContext context) => _ColorFilterRenderObject(colorFilter);

  @override
  void updateRenderObject(BuildContext context, _ColorFilterRenderObject renderObject) {
    renderObject.colorFilter = colorFilter;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ColorFilter>('colorFilter', colorFilter));
  }
}

class _ColorFilterRenderObject extends RenderProxyBox {
  _ColorFilterRenderObject(this._colorFilter);

  ColorFilter get colorFilter => _colorFilter;
  ColorFilter _colorFilter;
  set colorFilter(ColorFilter value) {
    assert(value != null);
    if (value != _colorFilter) {
      _colorFilter = value;
      markNeedsPaint();
    }
  }

  @override
  bool get alwaysNeedsCompositing => child != null;

  @override
  void paint(PaintingContext context, Offset offset) {
    layer = context.pushColorFilter(offset, colorFilter, super.paint, oldLayer: layer as ColorFilterLayer?);
  }
}
