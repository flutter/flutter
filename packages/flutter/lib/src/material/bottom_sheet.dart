// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'bottom_sheet_scroll_controller.dart';
import 'colors.dart';
import 'debug.dart';
import 'material.dart';
import 'material_localizations.dart';
import 'scaffold.dart';
import 'theme.dart';

const Duration _kBottomSheetDuration = Duration(milliseconds: 200);

/// A material design bottom sheet.
///
/// There are two kinds of bottom sheets in material design:
///
///  * _Persistent_. A persistent bottom sheet shows information that
///    supplements the primary content of the app. A persistent bottom sheet
///    remains visible even when the user interacts with other parts of the app.
///    Persistent bottom sheets can be created and displayed with the
///    [ScaffoldState.showBottomSheet] function or by specifying the
///    [Scaffold.bottomSheet] constructor parameter.
///
///  * _Modal_. A modal bottom sheet is an alternative to a menu or a dialog and
///    prevents the user from interacting with the rest of the app. Modal bottom
///    sheets can be created and displayed with the [showModalBottomSheet]
///    function.
///
/// The [BottomSheet] widget itself is rarely used directly. Instead, prefer to
/// create a persistent bottom sheet with [ScaffoldState.showBottomSheet] or
/// [Scaffold.bottomSheet], and a modal bottom sheet with [showModalBottomSheet].
///
/// See also:
///
///  * [showBottomSheet] and [ScaffoldState.showBottomSheet], for showing
///    non-modal "persistent" bottom sheets.
///  * [showModalBottomSheet], which can be used to display a modal bottom
///    sheet.
///  * <https://material.io/design/components/sheets-bottom.html>
class BottomSheet extends StatefulWidget {
  /// Creates a bottom sheet.
  ///
  /// Typically, bottom sheets are created implicitly by
  /// [ScaffoldState.showBottomSheet], for persistent bottom sheets, or by
  /// [showModalBottomSheet], for modal bottom sheets.
  const BottomSheet({
    Key key,
    @required this.scrollController,
    this.elevation = 0.0,
    @required this.onClosing,
    @required this.builder
  }) : assert(onClosing != null),
       assert(scrollController != null),
       assert(builder != null),
       assert(elevation != null && elevation >= 0.0),
       super(key: key);

  /// The [BottomSheetScrollController] that will act as the [PrimaryScrollController]
  /// for this [BottomSheet], controlling its height and its child's scroll offset.
  final BottomSheetScrollController scrollController;

  /// Called when the bottom sheet begins to close.
  ///
  /// A bottom sheet might be prevented from closing (e.g., by user
  /// interaction) even after this callback is called. For this reason, this
  /// callback might be call multiple times for a given bottom sheet.
  final VoidCallback onClosing;

  /// A builder for the contents of the sheet.
  ///
  /// The bottom sheet will wrap the widget produced by this builder in a
  /// [Material] widget.
  final WidgetBuilder builder;

  /// The z-coordinate at which to place this material relative to its parent.
  ///
  /// This controls the size of the shadow below the material.
  ///
  /// Defaults to 0. The value is non-negative.
  final double elevation;

  @override
  _BottomSheetState createState() => _BottomSheetState();

  /// Creates a [BottomSheetScrollController] suitable for animating the
  /// [BottomSheet].
  static BottomSheetScrollController createScrollController({
    double initialHeightPercentage = 0.5,
    double minTop = 0.0,
    bool isPersistent = false,
    @required BuildContext context,
    bool forFullScreen = false,
  }) {
    assert(minTop != null);
    assert(context != null);
    assert(debugCheckHasMediaQuery(context));

    return BottomSheetScrollController(
      debugLabel: 'BottomSheetScrollController',
      initialHeightPercentage: initialHeightPercentage,
      minTop: minTop,
      isPersistent: isPersistent,
      context: context,
      forFullScreen: forFullScreen,
    );
  }
}

class _BottomSheetState extends State<BottomSheet> {
  @override
  void initState() {
    super.initState();
    widget.scrollController.addTopListener(_maybeCloseBottomSheet);
  }

  void _maybeCloseBottomSheet() {
    if (!widget.scrollController.isPersistent &&
        widget.scrollController.top >= widget.scrollController.maxTop) {
      // onClosing is asserted not null
      widget.onClosing();
   }
  }

  @override
  Widget build(BuildContext context) {
    return PrimaryScrollController(
      controller: widget.scrollController,
      child: Material(
        elevation: widget.elevation,
        child: SizedBox.expand(
          child: widget.builder(context),
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget.scrollController.removeTopListener(_maybeCloseBottomSheet);
    super.dispose();
  }
}

// PERSISTENT BOTTOM SHEETS

// See scaffold.dart


// MODAL BOTTOM SHEETS

class _ModalBottomSheetLayout extends SingleChildLayoutDelegate {
  _ModalBottomSheetLayout(this.top);

  final double top;

  @override
  Size getSize(BoxConstraints constraints) {
    return Size(constraints.maxWidth, top);
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    return Offset(0.0, top);
  }

  @override
  bool shouldRelayout(_ModalBottomSheetLayout oldDelegate) {
    return top != oldDelegate.top;
  }
}

class _ModalBottomSheet<T> extends StatefulWidget {
  const _ModalBottomSheet({
    Key key,
    this.route,
    @required this.scrollController,
  }) : assert(scrollController != null),
       super(key: key);

  final _ModalBottomSheetRoute<T> route;
  final BottomSheetScrollController scrollController;

  @override
  _ModalBottomSheetState<T> createState() => _ModalBottomSheetState<T>();
}

class _ModalBottomSheetState<T> extends State<_ModalBottomSheet<T>> {
  @override
  void initState() {
    super.initState();
    widget.scrollController.addTopListener(_rebuild);
  }

  /// Rebuild the sheet when the [BottomSheetScrollController.top] value has changed.
  void _rebuild() {
    setState(() { /* state is contained in BottomSheetScrollController.top */ });
  }

  @override
  Widget build(BuildContext context) {
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    String routeLabel;
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        routeLabel = '';
        break;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        routeLabel = localizations.dialogLabel;
        break;
    }

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      label: routeLabel,
      explicitChildNodes: true,
      child: ClipRect(
        child: CustomSingleChildLayout(
          delegate: _ModalBottomSheetLayout(widget.scrollController.top),
          child: BottomSheet(
            onClosing: () => Navigator.pop(context),
            builder: widget.route.builder,
            scrollController: widget.scrollController,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget.scrollController.removeTopListener(_rebuild);
    super.dispose();
  }
}

class _ModalBottomSheetRoute<T> extends PopupRoute<T> {
  _ModalBottomSheetRoute({
    this.builder,
    this.theme,
    this.barrierLabel,
    this.initialHeightPercentage,
    this.clampTop = false,
    RouteSettings settings,
  }) : super(settings: settings);

  final WidgetBuilder builder;
  final ThemeData theme;
  final double initialHeightPercentage;
  final bool clampTop;

  BottomSheetScrollController _scrollController;

  @override
  Duration get transitionDuration => _kBottomSheetDuration;

  @override
  bool get barrierDismissible => true;

  @override
  final String barrierLabel;

  @override
  Color get barrierColor => Colors.black54;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    _scrollController = BottomSheet.createScrollController(
      initialHeightPercentage: initialHeightPercentage,
      minTop: clampTop ? initialHeightPercentage : 0.0,
      context: context,
      forFullScreen: true,
    );
    // By definition, the bottom sheet is aligned to the bottom of the page
    // and isn't exposed to the top padding of the MediaQuery.
    Widget bottomSheet = MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: _ModalBottomSheet<T>(
        route: this,
        scrollController: _scrollController,
      ),
    );
    if (theme != null)
      bottomSheet = Theme(data: theme, child: bottomSheet);
    return bottomSheet;
  }
}

/// Shows a modal material design bottom sheet.
///
/// A modal bottom sheet is an alternative to a menu or a dialog and prevents
/// the user from interacting with the rest of the app.
///
/// A closely related widget is a persistent bottom sheet, which shows
/// information that supplements the primary content of the app without
/// preventing the use from interacting with the app. Persistent bottom sheets
/// can be created and displayed with the [showBottomSheet] function or the
/// [ScaffoldState.showBottomSheet] method.
///
/// The `context` argument is used to look up the [Navigator] and [Theme] for
/// the bottom sheet. It is only used when the method is called. Its
/// corresponding widget can be safely removed from the tree before the bottom
/// sheet is closed.
///
/// The `initialTop` argument will limit the
///
/// Returns a `Future` that resolves to the value (if any) that was passed to
/// [Navigator.pop] when the modal bottom sheet was closed.
///
/// See also:
///
///  * [BottomSheet], which is the widget normally returned by the function
///    passed as the `builder` argument to [showModalBottomSheet].
///  * [showBottomSheet] and [ScaffoldState.showBottomSheet], for showing
///    non-modal bottom sheets.
///  * <https://material.io/design/components/sheets-bottom.html#modal-bottom-sheet>
Future<T> showModalBottomSheet<T>({
  @required BuildContext context,
  @required WidgetBuilder builder,
  double initialHeightPercentage = 0.5,
  bool clampTop = false,
}) {
  assert(clampTop != null);
  assert(context != null);
  assert(builder != null);
  assert(!clampTop || initialHeightPercentage != null,
    'If you wish to clamp the top, you must specify an initial value.');
  assert(initialHeightPercentage != null);
  assert(initialHeightPercentage >= 0.0 && initialHeightPercentage <= 1.0);
  assert(debugCheckHasMediaQuery(context));
  assert(debugCheckHasMaterialLocalizations(context));

  return Navigator.push(context, _ModalBottomSheetRoute<T>(
    builder: builder,
    theme: Theme.of(context, shadowThemeOnly: true),
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    initialHeightPercentage: initialHeightPercentage,
    clampTop: clampTop,
  ));
}

/// Shows a persistent material design bottom sheet in the nearest [Scaffold].
///
/// Returns a controller that can be used to close and otherwise manipulate the
/// bottom sheet.
///
/// To rebuild the bottom sheet (e.g. if it is stateful), call
/// [StandardBottomSheetController.setState] on the controller returned by
/// this method.
///
/// The new bottom sheet becomes a [LocalHistoryEntry] for the enclosing
/// [ModalRoute] and a back button is added to the appbar of the [Scaffold]
/// that closes the bottom sheet.
///
/// To create a persistent bottom sheet that is not a [LocalHistoryEntry] and
/// does not add a back button to the enclosing Scaffold's appbar, use the
/// [Scaffold.bottomSheet] constructor parameter.
///
/// A persistent bottom sheet shows information that supplements the primary
/// content of the app. A persistent bottom sheet remains visible even when
/// the user interacts with other parts of the app.
///
/// A closely related widget is a modal bottom sheet, which is an alternative
/// to a menu or a dialog and prevents the user from interacting with the rest
/// of the app. Modal bottom sheets can be created and displayed with the
/// [showModalBottomSheet] function.
///
/// The `context` argument is used to look up the [Scaffold] for the bottom
/// sheet. It is only used when the method is called. Its corresponding widget
/// can be safely removed from the tree before the bottom sheet is closed.
///
/// See also:
///
///  * [BottomSheet], which is the widget typically returned by the `builder`.
///  * [showModalBottomSheet], which can be used to display a modal bottom
///    sheet.
///  * [Scaffold.of], for information about how to obtain the [BuildContext].
///  * <https://material.io/design/components/sheets-bottom.html#standard-bottom-sheet>
StandardBottomSheetController<T> showBottomSheet<T>({
  @required BuildContext context,
  @required WidgetBuilder builder,
  double initialHeightPercentage = 0.5,
  bool clampTop = false,
}) {
  assert(context != null);
  assert(builder != null);
  assert(clampTop != null);
  assert(debugCheckHasScaffold(context));

  return Scaffold.of(context).showBottomSheet<T>(
    builder,
    initialHeightPercentage: initialHeightPercentage,
    clampTop: clampTop,
  );
}
