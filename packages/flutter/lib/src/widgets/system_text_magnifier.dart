// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/cupertino.dart';
/// @docImport 'package:flutter/material.dart';
///
/// @docImport 'system_context_menu.dart';
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'basic.dart';
import 'framework.dart';
import 'magnifier.dart';
import 'overlay.dart';

/// Displays the platform's text magnifier instead of one drawn by Flutter.
///
/// Currently, only supports iOS 17.0 and above, where it shows the system
/// loupe, and displays nothing on other platforms and earlier iOS versions.
///
/// Flutter typically draws the text magnifier itself, for example with
/// [CupertinoTextMagnifier]. A magnifier drawn by Flutter can only magnify what
/// Flutter draws. The system loupe magnifies the screen as the platform shows
/// it, including platform views, and has the platform's current look.
///
/// Return this widget from [TextMagnifierConfiguration.magnifierBuilder]. It
/// shows the loupe when it is inserted into the tree, moves it whenever
/// [magnifierInfo] changes, and hides it when it is removed from the tree.
///
/// This example shows the system loupe where supported and the default
/// magnifier elsewhere:
///
/// ```dart
/// TextField(
///   magnifierConfiguration: TextMagnifierConfiguration(
///     magnifierBuilder: (
///       BuildContext context,
///       MagnifierController controller,
///       ValueNotifier<MagnifierInfo> magnifierInfo,
///     ) {
///       if (SystemTextMagnifier.isSupported(context)) {
///         return SystemTextMagnifier(magnifierInfo: magnifierInfo);
///       }
///       return TextMagnifier.adaptiveMagnifierConfiguration.magnifierBuilder(
///         context,
///         controller,
///         magnifierInfo,
///       );
///     },
///   ),
/// )
/// ```
///
/// See also:
///
///  * [TextMagnifierConfiguration], which configures the magnifier of a text
///    field.
///  * [SystemContextMenu], which shows the platform's context menu in a
///    similar way.
class SystemTextMagnifier extends StatefulWidget {
  /// Creates a [SystemTextMagnifier] that follows [magnifierInfo].
  const SystemTextMagnifier({super.key, required this.magnifierInfo});

  /// The gesture and caret positions to show the magnifier at, in the
  /// coordinates of the root [Overlay], as given to
  /// [TextMagnifierConfiguration.magnifierBuilder].
  final ValueListenable<MagnifierInfo> magnifierInfo;

  /// Whether the current platform can show a [SystemTextMagnifier].
  ///
  /// Returns true on iOS. On iOS versions before 17.0, which have no system
  /// loupe, a [SystemTextMagnifier] displays nothing.
  static bool isSupported(BuildContext context) {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  State<SystemTextMagnifier> createState() => _SystemTextMagnifierState();
}

class _SystemTextMagnifierState extends State<SystemTextMagnifier> {
  late final bool _isSupported = SystemTextMagnifier.isSupported(context);

  @override
  void initState() {
    super.initState();
    widget.magnifierInfo.addListener(_show);
    _show();
  }

  @override
  void didUpdateWidget(SystemTextMagnifier oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.magnifierInfo != widget.magnifierInfo) {
      oldWidget.magnifierInfo.removeListener(_show);
      widget.magnifierInfo.addListener(_show);
      _show();
    }
  }

  @override
  void dispose() {
    widget.magnifierInfo.removeListener(_show);
    if (_isSupported) {
      SystemChannels.platform.invokeMethod<void>('Magnifier.hideSystemMagnifier');
    }
    super.dispose();
  }

  void _show() {
    if (!_isSupported) {
      return;
    }
    final MagnifierInfo info = widget.magnifierInfo.value;
    // The magnifier info is in the root overlay's coordinates, and the
    // platform takes coordinates in the Flutter view.
    final RenderObject? overlay = Overlay.maybeOf(
      context,
      rootOverlay: true,
    )?.context.findRenderObject();
    final Matrix4 toView = overlay is RenderBox && overlay.hasSize
        ? overlay.getTransformTo(null)
        : Matrix4.identity();
    final Offset position = MatrixUtils.transformPoint(toView, info.globalGesturePosition);
    final Rect caretRect = MatrixUtils.transformRect(toView, info.caretRect);
    SystemChannels.platform.invokeMethod<bool>('Magnifier.showSystemMagnifier', <String, Object>{
      'position': <String, double>{'x': position.dx, 'y': position.dy},
      'caretRect': <String, double>{
        'x': caretRect.left,
        'y': caretRect.top,
        'width': caretRect.width,
        'height': caretRect.height,
      },
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
