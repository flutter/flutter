// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'button_theme.dart';
import 'colors.dart';
import 'constants.dart';
import 'debug.dart';
import 'icons.dart';
import 'ink_well.dart';
import 'input_decorator.dart';
import 'material.dart';
import 'material_localizations.dart';
import 'scrollbar.dart';
import 'shadows.dart';
import 'theme.dart';

const Duration _kDropdownMenuDuration = Duration(milliseconds: 300);
const double _kMenuItemHeight = 48.0;
const double _kDenseButtonHeight = 24.0;
const EdgeInsets _kMenuItemPadding = EdgeInsets.symmetric(horizontal: 16.0);
const EdgeInsetsGeometry _kAlignedButtonPadding = EdgeInsetsDirectional.only(start: 16.0, end: 4.0);
const EdgeInsets _kUnalignedButtonPadding = EdgeInsets.zero;
const EdgeInsets _kAlignedMenuMargin = EdgeInsets.zero;
const EdgeInsetsGeometry _kUnalignedMenuMargin = EdgeInsetsDirectional.only(start: 16.0, end: 24.0);

class _DropdownMenuPainter extends CustomPainter {
  _DropdownMenuPainter({
    this.color,
    this.elevation,
    this.selectedIndex,
    this.resize,
  }) : _painter = BoxDecoration(
         // If you add an image here, you must provide a real
         // configuration in the paint() function and you must provide some sort
         // of onChanged callback here.
         color: color,
         borderRadius: BorderRadius.circular(2.0),
         boxShadow: kElevationToShadow[elevation]
       ).createBoxPainter(),
       super(repaint: resize);

  final Color color;
  final int elevation;
  final int selectedIndex;
  final Animation<double> resize;

  final BoxPainter _painter;

  @override
  void paint(Canvas canvas, Size size) {
    final double selectedItemOffset = selectedIndex * _kMenuItemHeight + kMaterialListPadding.top;
    final Tween<double> top = Tween<double>(
      begin: selectedItemOffset.clamp(0.0, size.height - _kMenuItemHeight),
      end: 0.0,
    );

    final Tween<double> bottom = Tween<double>(
      begin: (top.begin + _kMenuItemHeight).clamp(_kMenuItemHeight, size.height),
      end: size.height,
    );

    final Rect rect = Rect.fromLTRB(0.0, top.evaluate(resize), size.width, bottom.evaluate(resize));

    _painter.paint(canvas, rect.topLeft, ImageConfiguration(size: rect.size));
  }

  @override
  bool shouldRepaint(_DropdownMenuPainter oldPainter) {
    return oldPainter.color != color
        || oldPainter.elevation != elevation
        || oldPainter.selectedIndex != selectedIndex
        || oldPainter.resize != resize;
  }
}

// Do not use the platform-specific default scroll configuration.
// Dropdown menus should never overscroll or display an overscroll indicator.
class _DropdownScrollBehavior extends ScrollBehavior {
  const _DropdownScrollBehavior();

  @override
  TargetPlatform getPlatform(BuildContext context) => Theme.of(context).platform;

  @override
  Widget buildViewportChrome(BuildContext context, Widget child, AxisDirection axisDirection) => child;

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) => const ClampingScrollPhysics();
}

class _DropdownMenu<T> extends StatefulWidget {
  const _DropdownMenu({
    Key key,
    this.padding,
    this.route,
  }) : super(key: key);

  final _DropdownRoute<T> route;
  final EdgeInsets padding;

  @override
  _DropdownMenuState<T> createState() => _DropdownMenuState<T>();
}

class _DropdownMenuState<T> extends State<_DropdownMenu<T>> {
  CurvedAnimation _fadeOpacity;
  CurvedAnimation _resize;

  @override
  void initState() {
    super.initState();
    // We need to hold these animations as state because of their curve
    // direction. When the route's animation reverses, if we were to recreate
    // the CurvedAnimation objects in build, we'd lose
    // CurvedAnimation._curveDirection.
    _fadeOpacity = CurvedAnimation(
      parent: widget.route.animation,
      curve: const Interval(0.0, 0.25),
      reverseCurve: const Interval(0.75, 1.0),
    );
    _resize = CurvedAnimation(
      parent: widget.route.animation,
      curve: const Interval(0.25, 0.5),
      reverseCurve: const Threshold(0.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The menu is shown in three stages (unit timing in brackets):
    // [0s - 0.25s] - Fade in a rect-sized menu container with the selected item.
    // [0.25s - 0.5s] - Grow the otherwise empty menu container from the center
    //   until it's big enough for as many items as we're going to show.
    // [0.5s - 1.0s] Fade in the remaining visible items from top to bottom.
    //
    // When the menu is dismissed we just fade the entire thing out
    // in the first 0.25s.
    assert(debugCheckHasMaterialLocalizations(context));
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    final _DropdownRoute<T> route = widget.route;
    final double unit = 0.5 / (route.items.length + 1.5);
    final List<Widget> children = <Widget>[];
    for (int itemIndex = 0; itemIndex < route.items.length; ++itemIndex) {
      CurvedAnimation opacity;
      if (itemIndex == route.selectedIndex) {
        opacity = CurvedAnimation(parent: route.animation, curve: const Threshold(0.0));
      } else {
        final double start = (0.5 + (itemIndex + 1) * unit).clamp(0.0, 1.0);
        final double end = (start + 1.5 * unit).clamp(0.0, 1.0);
        opacity = CurvedAnimation(parent: route.animation, curve: Interval(start, end));
      }
      children.add(FadeTransition(
        opacity: opacity,
        child: InkWell(
          child: Container(
            padding: widget.padding,
            child: route.items[itemIndex],
          ),
          onTap: () => Navigator.pop(
            context,
            _DropdownRouteResult<T>(route.items[itemIndex].value),
          ),
        ),
      ));
    }

    return FadeTransition(
      opacity: _fadeOpacity,
      child: CustomPaint(
        painter: _DropdownMenuPainter(
          color: Theme.of(context).canvasColor,
          elevation: route.elevation,
          selectedIndex: route.selectedIndex,
          resize: _resize,
        ),
        child: Semantics(
          scopesRoute: true,
          namesRoute: true,
          explicitChildNodes: true,
          label: localizations.popupMenuLabel,
          child: Material(
              type: MaterialType.transparency,
              textStyle: route.style,
              child: ScrollConfiguration(
                behavior: const _DropdownScrollBehavior(),
                child: Scrollbar(
                  child: ListView(
                    controller: widget.route.scrollController,
                    padding: kMaterialListPadding,
                    itemExtent: _kMenuItemHeight,
                    shrinkWrap: true,
                    children: children,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
  }
}

class _DropdownMenuRouteLayout<T> extends SingleChildLayoutDelegate {
  _DropdownMenuRouteLayout({
    @required this.buttonRect,
    @required this.menuTop,
    @required this.menuHeight,
    @required this.textDirection,
  });

  final Rect buttonRect;
  final double menuTop;
  final double menuHeight;
  final TextDirection textDirection;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    // The maximum height of a simple menu should be one or more rows less than
    // the view height. This ensures a tappable area outside of the simple menu
    // with which to dismiss the menu.
    //   -- https://material.google.com/components/menus.html#menus-simple-menus
    final double maxHeight = math.max(0.0, constraints.maxHeight - 2 * _kMenuItemHeight);
    // The width of a menu should be at most the view width. This ensures that
    // the menu does not extend past the left and right edges of the screen.
    final double width = math.min(constraints.maxWidth, buttonRect.width);
    return BoxConstraints(
      minWidth: width,
      maxWidth: width,
      minHeight: 0.0,
      maxHeight: maxHeight,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    assert(() {
      final Rect container = Offset.zero & size;
      if (container.intersect(buttonRect) == buttonRect) {
        // If the button was entirely on-screen, then verify
        // that the menu is also on-screen.
        // If the button was a bit off-screen, then, oh well.
        assert(menuTop >= 0.0);
        assert(menuTop + menuHeight <= size.height);
      }
      return true;
    }());
    assert(textDirection != null);
    double left;
    switch (textDirection) {
      case TextDirection.rtl:
      left = buttonRect.right.clamp(0.0, size.width) - childSize.width;
        break;
      case TextDirection.ltr:
        left = buttonRect.left.clamp(0.0, size.width - childSize.width);
        break;
    }
    return Offset(left, menuTop);
  }

  @override
  bool shouldRelayout(_DropdownMenuRouteLayout<T> oldDelegate) {
    return buttonRect != oldDelegate.buttonRect
        || menuTop != oldDelegate.menuTop
        || menuHeight != oldDelegate.menuHeight
        || textDirection != oldDelegate.textDirection;
  }
}

// We box the return value so that the return value can be null. Otherwise,
// canceling the route (which returns null) would get confused with actually
// returning a real null value.
class _DropdownRouteResult<T> {
  const _DropdownRouteResult(this.result);

  final T result;

  @override
  bool operator ==(dynamic other) {
    if (other is! _DropdownRouteResult<T>)
      return false;
    final _DropdownRouteResult<T> typedOther = other;
    return result == typedOther.result;
  }

  @override
  int get hashCode => result.hashCode;
}

class _DropdownRoute<T> extends PopupRoute<_DropdownRouteResult<T>> {
  _DropdownRoute({
    this.items,
    this.padding,
    this.buttonRect,
    this.selectedIndex,
    this.elevation = 8,
    this.theme,
    @required this.style,
    this.barrierLabel,
  }) : assert(style != null);

  final List<DropdownMenuItem<T>> items;
  final EdgeInsetsGeometry padding;
  final Rect buttonRect;
  final int selectedIndex;
  final int elevation;
  final ThemeData theme;
  final TextStyle style;

  ScrollController scrollController;

  @override
  Duration get transitionDuration => _kDropdownMenuDuration;

  @override
  bool get barrierDismissible => true;

  @override
  Color get barrierColor => null;

  @override
  final String barrierLabel;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    assert(debugCheckHasDirectionality(context));
    final double screenHeight = MediaQuery.of(context).size.height;
    final double maxMenuHeight = screenHeight - 2.0 * _kMenuItemHeight;

    final double buttonTop = buttonRect.top;
    final double buttonBottom = buttonRect.bottom;

    // If the button is placed on the bottom or top of the screen, its top or
    // bottom may be less than [_kMenuItemHeight] from the edge of the screen.
    // In this case, we want to change the menu limits to align with the top
    // or bottom edge of the button.
    final double topLimit = math.min(_kMenuItemHeight, buttonTop);
    final double bottomLimit = math.max(screenHeight - _kMenuItemHeight, buttonBottom);

    final double selectedItemOffset = selectedIndex * _kMenuItemHeight + kMaterialListPadding.top;

    double menuTop = (buttonTop - selectedItemOffset) - (_kMenuItemHeight - buttonRect.height) / 2.0;
    final double preferredMenuHeight = (items.length * _kMenuItemHeight) + kMaterialListPadding.vertical;

    // If there are too many elements in the menu, we need to shrink it down
    // so it is at most the maxMenuHeight.
    final double menuHeight = math.min(maxMenuHeight, preferredMenuHeight);

    double menuBottom = menuTop + menuHeight;

    // If the computed top or bottom of the menu are outside of the range
    // specified, we need to bring them into range. If the item height is larger
    // than the button height and the button is at the very bottom or top of the
    // screen, the menu will be aligned with the bottom or top of the button
    // respectively.
    if (menuTop < topLimit)
      menuTop = math.min(buttonTop, topLimit);
    if (menuBottom > bottomLimit) {
      menuBottom = math.max(buttonBottom, bottomLimit);
      menuTop = menuBottom - menuHeight;
    }

    if (scrollController == null) {
      // The limit is asymmetrical because we do not care how far positive the
      // limit goes. We are only concerned about the case where the value of
      // [buttonTop - menuTop] is larger than selectedItemOffset, ie. when
      // the button is close to the bottom of the screen and the selected item
      // is close to 0.
      final double scrollOffset = preferredMenuHeight > maxMenuHeight ? math.max(0.0, selectedItemOffset - (buttonTop - menuTop)) : 0.0;
      scrollController = ScrollController(initialScrollOffset: scrollOffset);
    }

    final TextDirection textDirection = Directionality.of(context);
    Widget menu = _DropdownMenu<T>(
      route: this,
      padding: padding.resolve(textDirection),
    );

    if (theme != null)
      menu = Theme(data: theme, child: menu);

    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      removeBottom: true,
      removeLeft: true,
      removeRight: true,
      child: Builder(
        builder: (BuildContext context) {
          return CustomSingleChildLayout(
            delegate: _DropdownMenuRouteLayout<T>(
              buttonRect: buttonRect,
              menuTop: menuTop,
              menuHeight: menuHeight,
              textDirection: textDirection,
            ),
            child: menu,
          );
        },
      ),
    );
  }

  void _dismiss() {
    navigator?.removeRoute(this);
  }
}

/// An item in a menu created by a [DropdownButton].
///
/// The type `T` is the type of the value the entry represents. All the entries
/// in a given menu must represent values with consistent types.
class DropdownMenuItem<T> extends StatelessWidget {
  /// Creates an item for a dropdown menu.
  ///
  /// The [child] argument is required.
  const DropdownMenuItem({
    Key key,
    this.value,
    @required this.child,
  }) : assert(child != null),
       super(key: key);

  /// The widget below this widget in the tree.
  ///
  /// Typically a [Text] widget.
  final Widget child;

  /// The value to return if the user selects this menu item.
  ///
  /// Eventually returned in a call to [DropdownButton.onChanged].
  final T value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _kMenuItemHeight,
      alignment: AlignmentDirectional.centerStart,
      child: child,
    );
  }
}

/// An inherited widget that causes any descendant [DropdownButton]
/// widgets to not include their regular underline.
///
/// This is used by [DataTable] to remove the underline from any
/// [DropdownButton] widgets placed within material data tables, as
/// required by the material design specification.
class DropdownButtonHideUnderline extends InheritedWidget {
  /// Creates a [DropdownButtonHideUnderline]. A non-null [child] must
  /// be given.
  const DropdownButtonHideUnderline({
    Key key,
    @required Widget child,
  }) : assert(child != null),
       super(key: key, child: child);

  /// Returns whether the underline of [DropdownButton] widgets should
  /// be hidden.
  static bool at(BuildContext context) {
    return context.inheritFromWidgetOfExactType(DropdownButtonHideUnderline) != null;
  }

  @override
  bool updateShouldNotify(DropdownButtonHideUnderline oldWidget) => false;
}

/// A material design button for selecting from a list of items.
///
/// A dropdown button lets the user select from a number of items. The button
/// shows the currently selected item as well as an arrow that opens a menu for
/// selecting another item.
///
/// The type `T` is the type of the values the dropdown menu represents. All the
/// entries in a given menu must represent values with consistent types.
/// Typically, an enum is used. Each [DropdownMenuItem] in [items] must be
/// specialized with that same type argument.
///
/// Requires one of its ancestors to be a [Material] widget.
///
/// See also:
///
///  * [DropdownMenuItem], the class used to represent the [items].
///  * [DropdownButtonHideUnderline], which prevents its descendant dropdown buttons
///    from displaying their underlines.
///  * [RaisedButton], [FlatButton], ordinary buttons that trigger a single action.
///  * <https://material.google.com/components/buttons.html#buttons-dropdown-buttons>
class DropdownButton<T> extends StatefulWidget {
  /// Creates a dropdown button.
  ///
  /// The [items] must have distinct values and if [value] isn't null it must be among them.
  /// If [items] or [onChanged] is null, the button will be disabled, the down arrow will be grayed out, and
  /// the [disabledHint] will be shown (if provided).
  ///
  /// The [elevation] and [iconSize] arguments must not be null (they both have
  /// defaults, so do not need to be specified).
  DropdownButton({
    Key key,
    @required this.items,
    this.value,
    this.hint,
    this.disabledHint,
    @required this.onChanged,
    this.elevation = 8,
    this.style,
    this.iconSize = 24.0,
    this.isDense = false,
    this.isExpanded = false,
  }) : assert(items == null || value == null || items.where((DropdownMenuItem<T> item) => item.value == value).length == 1),
      super(key: key);

  /// The list of possible items to select among.
  final List<DropdownMenuItem<T>> items;

  /// The currently selected item, or null if no item has been selected. If
  /// value is null then the menu is popped up as if the first item was
  /// selected.
  final T value;

  /// Displayed if [value] is null.
  final Widget hint;

  /// A message to show when the dropdown is disabled.
  ///
  /// Displayed if [items] or [onChanged] is null.
  final Widget disabledHint;

  /// Called when the user selects an item.
  final ValueChanged<T> onChanged;

  /// The z-coordinate at which to place the menu when open.
  ///
  /// The following elevations have defined shadows: 1, 2, 3, 4, 6, 8, 9, 12, 16, 24
  ///
  /// Defaults to 8, the appropriate elevation for dropdown buttons.
  final int elevation;

  /// The text style to use for text in the dropdown button and the dropdown
  /// menu that appears when you tap the button.
  ///
  /// Defaults to the [TextTheme.subhead] value of the current
  /// [ThemeData.textTheme] of the current [Theme].
  final TextStyle style;

  /// The size to use for the drop-down button's down arrow icon button.
  ///
  /// Defaults to 24.0.
  final double iconSize;

  /// Reduce the button's height.
  ///
  /// By default this button's height is the same as its menu items' heights.
  /// If isDense is true, the button's height is reduced by about half. This
  /// can be useful when the button is embedded in a container that adds
  /// its own decorations, like [InputDecorator].
  final bool isDense;

  /// Set the dropdown's inner contents to horizontally fill its parent.
  ///
  /// By default this button's inner width is the minimum size of its contents.
  /// If [isExpanded] is true, the inner width is expanded to fill its
  /// surrounding container.
  final bool isExpanded;

  @override
  _DropdownButtonState<T> createState() => _DropdownButtonState<T>();
}

class _DropdownButtonState<T> extends State<DropdownButton<T>> with WidgetsBindingObserver {
  int _selectedIndex;
  _DropdownRoute<T> _dropdownRoute;

  @override
  void initState() {
    super.initState();
    _updateSelectedIndex();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _removeDropdownRoute();
    super.dispose();
  }

  // Typically called because the device's orientation has changed.
  // Defined by WidgetsBindingObserver
  @override
  void didChangeMetrics() {
    _removeDropdownRoute();
  }

  void _removeDropdownRoute() {
    _dropdownRoute?._dismiss();
    _dropdownRoute = null;
  }

  @override
  void didUpdateWidget(DropdownButton<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateSelectedIndex();
  }

  void _updateSelectedIndex() {
    if (!_enabled) {
      return;
    }

    assert(widget.value == null ||
      widget.items.where((DropdownMenuItem<T> item) => item.value == widget.value).length == 1);
    _selectedIndex = null;
    for (int itemIndex = 0; itemIndex < widget.items.length; itemIndex++) {
      if (widget.items[itemIndex].value == widget.value) {
        _selectedIndex = itemIndex;
        return;
      }
    }
  }

  TextStyle get _textStyle => widget.style ?? Theme.of(context).textTheme.subhead;

  void _handleTap() {
    final RenderBox itemBox = context.findRenderObject();
    final Rect itemRect = itemBox.localToGlobal(Offset.zero) & itemBox.size;
    final TextDirection textDirection = Directionality.of(context);
    final EdgeInsetsGeometry menuMargin = ButtonTheme.of(context).alignedDropdown
      ?_kAlignedMenuMargin
      : _kUnalignedMenuMargin;

    assert(_dropdownRoute == null);
    _dropdownRoute = _DropdownRoute<T>(
      items: widget.items,
      buttonRect: menuMargin.resolve(textDirection).inflateRect(itemRect),
      padding: _kMenuItemPadding.resolve(textDirection),
      selectedIndex: _selectedIndex ?? 0,
      elevation: widget.elevation,
      theme: Theme.of(context, shadowThemeOnly: true),
      style: _textStyle,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    );

    Navigator.push(context, _dropdownRoute).then<void>((_DropdownRouteResult<T> newValue) {
      _dropdownRoute = null;
      if (!mounted || newValue == null)
        return;
      if (widget.onChanged != null)
        widget.onChanged(newValue.result);
    });
  }

  // When isDense is true, reduce the height of this button from _kMenuItemHeight to
  // _kDenseButtonHeight, but don't make it smaller than the text that it contains.
  // Similarly, we don't reduce the height of the button so much that its icon
  // would be clipped.
  double get _denseButtonHeight {
    return math.max(_textStyle.fontSize, math.max(widget.iconSize, _kDenseButtonHeight));
  }

  Color get _downArrowColor {
    // These colors are not defined in the Material Design spec.
    if (_enabled) {
      if (Theme.of(context).brightness == Brightness.light) {
        return Colors.grey.shade700;
      } else {
        return Colors.white70;
      }
    } else {
      if (Theme.of(context).brightness == Brightness.light) {
        return Colors.grey.shade400;
      } else {
        return Colors.white10;
      }
    }
  }

  bool get _enabled => widget.items != null && widget.items.isNotEmpty && widget.onChanged != null;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    assert(debugCheckHasMaterialLocalizations(context));

    // The width of the button and the menu are defined by the widest
    // item and the width of the hint.
    final List<Widget> items = _enabled ? List<Widget>.from(widget.items) : <Widget>[];
    int hintIndex;
    if (widget.hint != null || (!_enabled && widget.disabledHint != null)) {
      final Widget emplacedHint =
        _enabled ? widget.hint : DropdownMenuItem<Widget>(child: widget.disabledHint ?? widget.hint);
      hintIndex = items.length;
      items.add(DefaultTextStyle(
        style: _textStyle.copyWith(color: Theme.of(context).hintColor),
        child: IgnorePointer(
          child: emplacedHint,
          ignoringSemantics: false,
        ),
      ));
    }

    final EdgeInsetsGeometry padding = ButtonTheme.of(context).alignedDropdown
      ? _kAlignedButtonPadding
      : _kUnalignedButtonPadding;

    // If value is null (then _selectedIndex is null) or if disabled then we
    // display the hint or nothing at all.
    final IndexedStack innerItemsWidget = IndexedStack(
      index: _enabled ? (_selectedIndex ?? hintIndex) : hintIndex,
      alignment: AlignmentDirectional.centerStart,
      children: items,
    );

    Widget result = DefaultTextStyle(
      style: _textStyle,
      child: Container(
        padding: padding.resolve(Directionality.of(context)),
        height: widget.isDense ? _denseButtonHeight : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            widget.isExpanded ? Expanded(child: innerItemsWidget) : innerItemsWidget,
            Icon(Icons.arrow_drop_down,
              size: widget.iconSize,
              color: _downArrowColor,
            ),
          ],
        ),
      ),
    );

    if (!DropdownButtonHideUnderline.at(context)) {
      final double bottom = widget.isDense ? 0.0 : 8.0;
      result = Stack(
        children: <Widget>[
          result,
          Positioned(
            left: 0.0,
            right: 0.0,
            bottom: bottom,
            child: Container(
              height: 1.0,
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFBDBDBD), width: 0.0))
              ),
            ),
          ),
        ],
      );
    }

    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: _enabled ? _handleTap : null,
        behavior: HitTestBehavior.opaque,
        child: result
      ),
    );
  }
}

/// A convenience widget that wraps a [DropdownButton] in a [FormField].
class DropdownButtonFormField<T> extends FormField<T> {
  /// Creates a [DropdownButton] widget wrapped in an [InputDecorator] and
  /// [FormField].
  ///
  /// The [DropdownButton] [items] parameters must not be null.
  DropdownButtonFormField({
    Key key,
    T value,
    @required List<DropdownMenuItem<T>> items,
    this.onChanged,
    InputDecoration decoration = const InputDecoration(),
    FormFieldSetter<T> onSaved,
    FormFieldValidator<T> validator,
    Widget hint,
  }) : assert(decoration != null),
       super(
         key: key,
         onSaved: onSaved,
         initialValue: value,
         validator: validator,
         builder: (FormFieldState<T> field) {
           final InputDecoration effectiveDecoration = decoration
             .applyDefaults(Theme.of(field.context).inputDecorationTheme);
           return InputDecorator(
             decoration: effectiveDecoration.copyWith(errorText: field.errorText),
             isEmpty: value == null,
             child: DropdownButtonHideUnderline(
               child: DropdownButton<T>(
                 isDense: true,
                 value: value,
                 items: items,
                 hint: hint,
                 onChanged: field.didChange,
               ),
             ),
           );
         }
       );

  /// Called when the user selects an item.
  final ValueChanged<T> onChanged;

  @override
  FormFieldState<T> createState() => _DropdownButtonFormFieldState<T>();
}

class _DropdownButtonFormFieldState<T> extends FormFieldState<T> {
  @override
  DropdownButtonFormField<T> get widget => super.widget;

  @override
  void didChange(T value) {
    super.didChange(value);
    if (widget.onChanged != null)
      widget.onChanged(value);
  }
}
