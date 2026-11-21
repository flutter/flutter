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
/// Currently, only supports iOS, where it shows the system loupe on iOS 17.0
/// and above and displays nothing on earlier iOS versions. Check [isSupported]
/// before building this widget.
///
/// Flutter typically draws the text magnifier itself, for example with
/// [CupertinoTextMagnifier], which approximates the platform's look. The
/// system loupe is drawn by the platform, so it has the platform's current
/// look and animations.
///
/// Return this widget from [TextMagnifierConfiguration.magnifierBuilder]. It
/// shows the loupe when it is inserted into the tree, moves it whenever
/// [magnifierInfo] changes, and hides it when it is removed from the tree.
///
/// On iOS 17.4 and above, the platform shows no loupe when the caret is much
/// taller than the loupe, as with very large text. The platform's own text
/// fields behave the same way.
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<ValueListenable<MagnifierInfo>>('magnifierInfo', magnifierInfo),
    );
  }
}

class _SystemTextMagnifierState extends State<SystemTextMagnifier> {
  // Set when the platform reports that it has no system magnifier. This then
  // stops listening to the magnifier info and sends nothing more.
  bool _unsupported = false;

  @override
  void initState() {
    super.initState();
    widget.magnifierInfo.addListener(_show);
    _show();
  }

  @override
  void didUpdateWidget(SystemTextMagnifier oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_unsupported && oldWidget.magnifierInfo != widget.magnifierInfo) {
      oldWidget.magnifierInfo.removeListener(_show);
      widget.magnifierInfo.addListener(_show);
      _show();
    }
  }

  @override
  void dispose() {
    if (!_unsupported) {
      widget.magnifierInfo.removeListener(_show);
      SystemMagnifier.hide();
    }
    super.dispose();
  }

  void _show() {
    // The magnifier info is in the root overlay's coordinates, and the
    // platform takes coordinates in the Flutter view.
    final overlay = Overlay.of(context, rootOverlay: true).context.findRenderObject() as RenderBox?;
    // There is no position to show the magnifier at until the overlay is laid
    // out.
    if (overlay == null || !overlay.hasSize) {
      return;
    }
    final Matrix4 toView = overlay.getTransformTo(null);
    // The transform is singular, for example zero when an ancestor does not
    // paint the overlay, so there is no position to show the magnifier at.
    if (toView.determinant() == 0.0) {
      return;
    }
    final MagnifierInfo info = widget.magnifierInfo.value;
    SystemMagnifier.show(
      gesturePosition: MatrixUtils.transformPoint(toView, info.globalGesturePosition),
      caretRect: MatrixUtils.transformRect(toView, info.caretRect),
    ).then((SystemMagnifierShowResult result) {
      if (!mounted || _unsupported || result != SystemMagnifierShowResult.unsupported) {
        return;
      }
      _unsupported = true;
      widget.magnifierInfo.removeListener(_show);
    });
  }

  @override
  Widget build(BuildContext context) {
    assert(SystemTextMagnifier.isSupported(context));
    return const SizedBox.shrink();
  }
}
