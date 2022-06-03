// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart' show clampDouble;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'constants.dart';
import 'debug.dart';
import 'material.dart';
import 'material_localizations.dart';
import 'text_button.dart';
import 'text_selection_toolbar.dart';
import 'theme.dart';

const double _kToolbarScreenPadding = 8.0;
const double _kToolbarWidth = 222.0;

class _DesktopTextSelectionControls extends TextSelectionControls {
  /// Desktop has no text selection handles.
  @override
  Size getHandleSize(double textLineHeight) {
    return Size.zero;
  }

  /// Builder for the Material-style desktop copy/paste text selection toolbar.
  @override
  Widget buildToolbar(
    BuildContext context,
    Rect globalEditableRegion,
    double textLineHeight,
    Offset selectionMidpoint,
    List<TextSelectionPoint> endpoints,
    TextSelectionDelegate delegate,
    ClipboardStatusNotifier? clipboardStatus,
    Offset? lastSecondaryTapDownPosition,
  ) {
    return _DesktopTextSelectionControlsToolbar(
      clipboardStatus: clipboardStatus,
      endpoints: endpoints,
      globalEditableRegion: globalEditableRegion,
      handleCut: canCut(delegate) ? () => handleCut(delegate) : null,
      handleCopy: canCopy(delegate) ? () => handleCopy(delegate) : null,
      handlePaste: canPaste(delegate) ? () => handlePaste(delegate) : null,
      handleSelectAll: canSelectAll(delegate) ? () => handleSelectAll(delegate) : null,
      selectionMidpoint: selectionMidpoint,
      lastSecondaryTapDownPosition: lastSecondaryTapDownPosition,
      textLineHeight: textLineHeight,
    );
  }

  /// Builds the text selection handles, but desktop has none.
  @override
  Widget buildHandle(BuildContext context, TextSelectionHandleType type, double textLineHeight, [VoidCallback? onTap]) {
    return const SizedBox.shrink();
  }

  /// Gets the position for the text selection handles, but desktop has none.
  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight) {
    return Offset.zero;
  }

  @override
  bool canSelectAll(TextSelectionDelegate delegate) {
    // Allow SelectAll when selection is not collapsed, unless everything has
    // already been selected. Same behavior as Android.
    final TextEditingValue value = delegate.textEditingValue;
    return delegate.selectAllEnabled &&
           value.text.isNotEmpty &&
           !(value.selection.start == 0 && value.selection.end == value.text.length);
  }

  @override
  void handleSelectAll(TextSelectionDelegate delegate) {
    super.handleSelectAll(delegate);
    delegate.hideToolbar();
  }
}

/// Text selection controls that loosely follows Material design conventions.
final TextSelectionControls desktopTextSelectionControls =
    _DesktopTextSelectionControls();

// Generates the child that's passed into DesktopTextSelectionToolbar.
class _DesktopTextSelectionControlsToolbar extends StatefulWidget {
  const _DesktopTextSelectionControlsToolbar({
    required this.clipboardStatus,
    required this.endpoints,
    required this.globalEditableRegion,
    required this.handleCopy,
    required this.handleCut,
    required this.handlePaste,
    required this.handleSelectAll,
    required this.selectionMidpoint,
    required this.textLineHeight,
    required this.lastSecondaryTapDownPosition,
  });

  final ClipboardStatusNotifier? clipboardStatus;
  final List<TextSelectionPoint> endpoints;
  final Rect globalEditableRegion;
  final VoidCallback? handleCopy;
  final VoidCallback? handleCut;
  final VoidCallback? handlePaste;
  final VoidCallback? handleSelectAll;
  final Offset? lastSecondaryTapDownPosition;
  final Offset selectionMidpoint;
  final double textLineHeight;

  @override
  _DesktopTextSelectionControlsToolbarState createState() => _DesktopTextSelectionControlsToolbarState();
}

class _DesktopTextSelectionControlsToolbarState extends State<_DesktopTextSelectionControlsToolbar> {
  void _onChangedClipboardStatus() {
    setState(() {
      // Inform the widget that the value of clipboardStatus has changed.
    });
  }

  @override
  void initState() {
    super.initState();
    widget.clipboardStatus?.addListener(_onChangedClipboardStatus);
  }

  @override
  void didUpdateWidget(_DesktopTextSelectionControlsToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clipboardStatus != widget.clipboardStatus) {
      oldWidget.clipboardStatus?.removeListener(_onChangedClipboardStatus);
      widget.clipboardStatus?.addListener(_onChangedClipboardStatus);
    }
  }

  @override
  void dispose() {
    super.dispose();
    widget.clipboardStatus?.removeListener(_onChangedClipboardStatus);
  }

  @override
  Widget build(BuildContext context) {
    // Don't render the menu until the state of the clipboard is known.
    if (widget.handlePaste != null && widget.clipboardStatus?.value == ClipboardStatus.unknown) {
      return const SizedBox(width: 0.0, height: 0.0);
    }

    assert(debugCheckHasMediaQuery(context));
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    final Offset midpointAnchor = Offset(
      clampDouble(widget.selectionMidpoint.dx - widget.globalEditableRegion.left,
        mediaQuery.padding.left,
        mediaQuery.size.width - mediaQuery.padding.right,
      ),
      widget.selectionMidpoint.dy - widget.globalEditableRegion.top,
    );

    assert(debugCheckHasMaterialLocalizations(context));
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    final List<Widget> items = <Widget>[];

    void addToolbarButton(
      String text,
      VoidCallback onPressed,
    ) {
      items.add(_DesktopTextSelectionToolbarButton.text(
        context: context,
        onPressed: onPressed,
        text: text,
      ));
    }

    if (widget.handleCut != null) {
      addToolbarButton(localizations.cutButtonLabel, widget.handleCut!);
    }
    if (widget.handleCopy != null) {
      addToolbarButton(localizations.copyButtonLabel, widget.handleCopy!);
    }
    if (widget.handlePaste != null
        && widget.clipboardStatus?.value == ClipboardStatus.pasteable) {
      addToolbarButton(localizations.pasteButtonLabel, widget.handlePaste!);
    }
    if (widget.handleSelectAll != null) {
      addToolbarButton(localizations.selectAllButtonLabel, widget.handleSelectAll!);
    }

    // If there is no option available, build an empty widget.
    if (items.isEmpty) {
      return const SizedBox(width: 0.0, height: 0.0);
    }

    return _DesktopTextSelectionToolbar(
      anchor: widget.lastSecondaryTapDownPosition ?? midpointAnchor,
      children: items,
    );
  }
}

/// A Material-style desktop text selection toolbar.
///
/// Typically displays buttons for text manipulation, e.g. copying and pasting
/// text.
///
/// Tries to position itself as closely as possible to [anchor] while remaining
/// fully on-screen.
///
/// See also:
///
///  * [_DesktopTextSelectionControls.buildToolbar], where this is used by
///    default to build a Material-style desktop toolbar.
///  * [TextSelectionToolbar], which is similar, but builds an Android-style
///    toolbar.
class _DesktopTextSelectionToolbar extends StatelessWidget {
  /// Creates an instance of _DesktopTextSelectionToolbar.
  const _DesktopTextSelectionToolbar({
    required this.anchor,
    required this.children,
  }) : assert(children.length > 0);

  /// The point at which the toolbar will attempt to position itself as closely
  /// as possible.
  final Offset anchor;

  /// {@macro flutter.material.TextSelectionToolbar.children}
  ///
  /// See also:
  ///   * [DesktopTextSelectionToolbarButton], which builds a default
  ///     Material-style desktop text selection toolbar text button.
  final List<Widget> children;

  // Builds a desktop toolbar in the Material style.
  static Widget _defaultToolbarBuilder(BuildContext context, Widget child) {
    return SizedBox(
      width: _kToolbarWidth,
      child: Material(
        borderRadius: const BorderRadius.all(Radius.circular(7.0)),
        clipBehavior: Clip.antiAlias,
        elevation: 1.0,
        type: MaterialType.card,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    final double paddingAbove = mediaQuery.padding.top + _kToolbarScreenPadding;
    final Offset localAdjustment = Offset(_kToolbarScreenPadding, paddingAbove);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        _kToolbarScreenPadding,
        paddingAbove,
        _kToolbarScreenPadding,
        _kToolbarScreenPadding,
      ),
      child: CustomSingleChildLayout(
        delegate: DesktopTextSelectionToolbarLayoutDelegate(
          anchor: anchor - localAdjustment,
        ),
        child: _defaultToolbarBuilder(context, Column(
          mainAxisSize: MainAxisSize.min,
          children: children,
        )),
      ),
    );
  }
}

const TextStyle _kToolbarButtonFontStyle = TextStyle(
  inherit: false,
  fontSize: 14.0,
  letterSpacing: -0.15,
  fontWeight: FontWeight.w400,
);

const EdgeInsets _kToolbarButtonPadding = EdgeInsets.fromLTRB(
  20.0,
  0.0,
  20.0,
  3.0,
);

/// A [TextButton] for the Material desktop text selection toolbar.
class _DesktopTextSelectionToolbarButton extends StatelessWidget {
  /// Creates an instance of DesktopTextSelectionToolbarButton.
  const _DesktopTextSelectionToolbarButton({
    required this.onPressed,
    required this.child,
  });

  /// Create an instance of [_DesktopTextSelectionToolbarButton] whose child is
  /// a [Text] widget in the style of the Material text selection toolbar.
  _DesktopTextSelectionToolbarButton.text({
    required BuildContext context,
    required this.onPressed,
    required String text,
  }) : child = Text(
         text,
         overflow: TextOverflow.ellipsis,
         style: _kToolbarButtonFontStyle.copyWith(
           color: Theme.of(context).colorScheme.brightness == Brightness.dark
               ? Colors.white
               : Colors.black87,
         ),
       );

  /// {@macro flutter.material.TextSelectionToolbarTextButton.onPressed}
  final VoidCallback onPressed;

  /// {@macro flutter.material.TextSelectionToolbarTextButton.child}
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // TODO(hansmuller): Should be colorScheme.onSurface
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.colorScheme.brightness == Brightness.dark;
    final Color primary = isDark ? Colors.white : Colors.black87;

    return SizedBox(
      width: double.infinity,
      child: TextButton(
        style: TextButton.styleFrom(
          alignment: Alignment.centerLeft,
          enabledMouseCursor: SystemMouseCursors.basic,
          disabledMouseCursor: SystemMouseCursors.basic,
          primary: primary,
          shape: const RoundedRectangleBorder(),
          minimumSize: const Size(kMinInteractiveDimension, 36.0),
          padding: _kToolbarButtonPadding,
        ),
        onPressed: onPressed,
        child: child,
      ),
    );
  }
}
