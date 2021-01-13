// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'desktop_text_selection_toolbar.dart';
import 'desktop_text_selection_toolbar_button.dart';
import 'localizations.dart';
import 'theme.dart';

// Read off from the output on iOS 12. This color does not vary with the
// application's theme color.
const double _kSelectionHandleOverlap = 1.5;
// Extracted from https://developer.apple.com/design/resources/.
const double _kSelectionHandleRadius = 6;

// Minimal padding from tip of the selection toolbar arrow to horizontal edges of the
// screen. Eyeballed value.
const double _kArrowScreenPadding = 26.0;

// This value was measured from a screenshot of TextEdit on MacOS 10.15.7 on a
// Macbook Pro.
const EdgeInsets _kToolbarButtonPadding = EdgeInsets.symmetric(
  // TODO(justinmc): This vertical padding seems good, but the text seems not
  // vertically centered within it.
  vertical: 1.0,
  horizontal: 20.0,
);

/// Draws a single text selection handle with a bar and a ball.
class _TextSelectionHandlePainter extends CustomPainter {
  const _TextSelectionHandlePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const double halfStrokeWidth = 1.0;
    final Paint paint = Paint()..color = color;
    final Rect circle = Rect.fromCircle(
      center: const Offset(_kSelectionHandleRadius, _kSelectionHandleRadius),
      radius: _kSelectionHandleRadius,
    );
    final Rect line = Rect.fromPoints(
      const Offset(
        _kSelectionHandleRadius - halfStrokeWidth,
        2 * _kSelectionHandleRadius - _kSelectionHandleOverlap,
      ),
      Offset(_kSelectionHandleRadius + halfStrokeWidth, size.height),
    );
    final Path path = Path()
      ..addOval(circle)
    // Draw line so it slightly overlaps the circle.
      ..addRect(line);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TextSelectionHandlePainter oldPainter) => color != oldPainter.color;
}

class _CupertinoDesktopTextSelectionControls extends TextSelectionControls {
  /// Returns the size of the CupertinoDesktop handle.
  @override
  Size getHandleSize(double textLineHeight) {
    return Size(
      _kSelectionHandleRadius * 2,
      textLineHeight + _kSelectionHandleRadius * 2 - _kSelectionHandleOverlap,
    );
  }

  /// Builder for the Mac-style copy/paste text selection toolbar.
  @override
  Widget buildToolbar(
    BuildContext context,
    Rect globalEditableRegion,
    double textLineHeight,
    Offset selectionMidpoint,
    List<TextSelectionPoint> endpoints,
    TextSelectionDelegate delegate,
    ClipboardStatusNotifier clipboardStatus,
    Offset? lastTapDownPosition,
  ) {
    return _CupertinoDesktopTextSelectionControlsToolbar(
      clipboardStatus: clipboardStatus,
      endpoints: endpoints,
      globalEditableRegion: globalEditableRegion,
      handleCut: canCut(delegate) ? () => handleCut(delegate) : null,
      handleCopy: canCopy(delegate) ? () => handleCopy(delegate, clipboardStatus) : null,
      handlePaste: canPaste(delegate) ? () => handlePaste(delegate) : null,
      handleSelectAll: canSelectAll(delegate) ? () => handleSelectAll(delegate) : null,
      selectionMidpoint: selectionMidpoint,
      lastTapDownPosition: lastTapDownPosition,
      textLineHeight: textLineHeight,
    );
  }

  // TODO(justinmc): Can I get rid of the handles here?
  /// Builder for iOS text selection edges.
  @override
  Widget buildHandle(BuildContext context, TextSelectionHandleType type, double textLineHeight) {
    // We want a size that's a vertical line the height of the text plus a 18.0
    // padding in every direction that will constitute the selection drag area.
    final Size desiredSize = getHandleSize(textLineHeight);

    final Widget handle = SizedBox.fromSize(
      size: desiredSize,
      child: CustomPaint(
        painter: _TextSelectionHandlePainter(CupertinoTheme.of(context).primaryColor),
      ),
    );

    // [buildHandle]'s widget is positioned at the selection cursor's bottom
    // baseline. We transform the handle such that the SizedBox is superimposed
    // on top of the text selection endpoints.
    switch (type) {
      case TextSelectionHandleType.left:
        return handle;
      case TextSelectionHandleType.right:
        // Right handle is a vertical mirror of the left.
        return Transform(
          transform: Matrix4.identity()
            ..translate(desiredSize.width / 2, desiredSize.height / 2)
            ..rotateZ(math.pi)
            ..translate(-desiredSize.width / 2, -desiredSize.height / 2),
          child: handle,
        );
      // iOS doesn't draw anything for collapsed selections.
      case TextSelectionHandleType.collapsed:
        return const SizedBox();
    }
  }

  /// Gets anchor for cupertino-style text selection handles.
  ///
  /// See [TextSelectionControls.getHandleAnchor].
  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight) {
    final Size handleSize = getHandleSize(textLineHeight);
    switch (type) {
      // The circle is at the top for the left handle, and the anchor point is
      // all the way at the bottom of the line.
      case TextSelectionHandleType.left:
        return Offset(
          handleSize.width / 2,
          handleSize.height,
        );
      // The right handle is vertically flipped, and the anchor point is near
      // the top of the circle to give slight overlap.
      case TextSelectionHandleType.right:
        return Offset(
          handleSize.width / 2,
          handleSize.height - 2 * _kSelectionHandleRadius + _kSelectionHandleOverlap,
        );
      // A collapsed handle anchors itself so that it's centered.
      case TextSelectionHandleType.collapsed:
        return Offset(
          handleSize.width / 2,
          textLineHeight + (handleSize.height - textLineHeight) / 2,
        );
    }
  }
}

/// Text selection controls that follows Mac design conventions.
final TextSelectionControls cupertinoDesktopTextSelectionControls =
    _CupertinoDesktopTextSelectionControls();

// Generates the child that's passed into CupertinoDesktopTextSelectionToolbar.
class _CupertinoDesktopTextSelectionControlsToolbar extends StatefulWidget {
  const _CupertinoDesktopTextSelectionControlsToolbar({
    Key? key,
    required this.clipboardStatus,
    required this.endpoints,
    required this.globalEditableRegion,
    required this.handleCopy,
    required this.handleCut,
    required this.handlePaste,
    required this.handleSelectAll,
    required this.selectionMidpoint,
    required this.textLineHeight,
    this.lastTapDownPosition,
  }) : super(key: key);

  final ClipboardStatusNotifier? clipboardStatus;
  final List<TextSelectionPoint> endpoints;
  final Rect globalEditableRegion;
  final VoidCallback? handleCopy;
  final VoidCallback? handleCut;
  final VoidCallback? handlePaste;
  final VoidCallback? handleSelectAll;
  final Offset? lastTapDownPosition;
  final Offset selectionMidpoint;
  final double textLineHeight;

  @override
  _CupertinoDesktopTextSelectionControlsToolbarState createState() => _CupertinoDesktopTextSelectionControlsToolbarState();
}

class _CupertinoDesktopTextSelectionControlsToolbarState extends State<_CupertinoDesktopTextSelectionControlsToolbar> {
  late ClipboardStatusNotifier _clipboardStatus;

  void _onChangedClipboardStatus() {
    setState(() {
      // Inform the widget that the value of clipboardStatus has changed.
    });
  }

  @override
  void initState() {
    super.initState();
    _clipboardStatus = widget.clipboardStatus ?? ClipboardStatusNotifier();
    _clipboardStatus.addListener(_onChangedClipboardStatus);
    _clipboardStatus.update();
  }

  @override
  void didUpdateWidget(_CupertinoDesktopTextSelectionControlsToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clipboardStatus == null && widget.clipboardStatus != null) {
      _clipboardStatus.removeListener(_onChangedClipboardStatus);
      _clipboardStatus.dispose();
      _clipboardStatus = widget.clipboardStatus!;
    } else if (oldWidget.clipboardStatus != null) {
      if (widget.clipboardStatus == null) {
        _clipboardStatus = ClipboardStatusNotifier();
        _clipboardStatus.addListener(_onChangedClipboardStatus);
        oldWidget.clipboardStatus!.removeListener(_onChangedClipboardStatus);
      } else if (widget.clipboardStatus != oldWidget.clipboardStatus) {
        _clipboardStatus = widget.clipboardStatus!;
        _clipboardStatus.addListener(_onChangedClipboardStatus);
        oldWidget.clipboardStatus!.removeListener(_onChangedClipboardStatus);
      }
    }
    if (widget.handlePaste != null) {
      _clipboardStatus.update();
    }
  }

  @override
  void dispose() {
    super.dispose();
    // When used in an Overlay, this can be disposed after its creator has
    // already disposed _clipboardStatus.
    if (!_clipboardStatus.disposed) {
      _clipboardStatus.removeListener(_onChangedClipboardStatus);
      if (widget.clipboardStatus == null) {
        _clipboardStatus.dispose();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't render the menu until the state of the clipboard is known.
    if (widget.handlePaste != null
        && _clipboardStatus.value == ClipboardStatus.unknown) {
      return const SizedBox(width: 0.0, height: 0.0);
    }

    assert(debugCheckHasMediaQuery(context));
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    final Offset midpointAnchor = Offset(
      (widget.selectionMidpoint.dx - widget.globalEditableRegion.left).clamp(
        _kArrowScreenPadding + mediaQuery.padding.left,
        mediaQuery.size.width - mediaQuery.padding.right - _kArrowScreenPadding,
      ),
      widget.selectionMidpoint.dy - widget.globalEditableRegion.top,
    );

    final List<Widget> items = <Widget>[];
    final CupertinoLocalizations localizations = CupertinoLocalizations.of(context);
    final Widget onePhysicalPixelVerticalDivider =
        SizedBox(width: 1.0 / MediaQuery.of(context).devicePixelRatio);

    void addToolbarButton(
      String text,
      VoidCallback onPressed,
    ) {
      if (items.isNotEmpty) {
        items.add(onePhysicalPixelVerticalDivider);
      }

      items.add(CupertinoDesktopButton(
        text: text,
        onPressed: onPressed,
        padding: _kToolbarButtonPadding,
      ));
    }

    if (widget.handleCut != null) {
      addToolbarButton(localizations.cutButtonLabel, widget.handleCut!);
    }
    if (widget.handleCopy != null) {
      addToolbarButton(localizations.copyButtonLabel, widget.handleCopy!);
    }
    if (widget.handlePaste != null
        && _clipboardStatus.value == ClipboardStatus.pasteable) {
      addToolbarButton(localizations.pasteButtonLabel, widget.handlePaste!);
    }
    if (widget.handleSelectAll != null) {
      addToolbarButton(localizations.selectAllButtonLabel, widget.handleSelectAll!);
    }

    // If there is no option available, build an empty widget.
    if (items.isEmpty) {
      return const SizedBox(width: 0.0, height: 0.0);
    }

    return CupertinoDesktopTextSelectionToolbar(
      // TODO(justinmc): Can the menu ever be shown without a lastTapDownPosition?
      anchor: widget.lastTapDownPosition ?? midpointAnchor,
      children: items,
    );
  }
}
