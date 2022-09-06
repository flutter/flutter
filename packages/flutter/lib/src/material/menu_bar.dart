// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'button_style.dart';
import 'button_style_button.dart';
import 'color_scheme.dart';
import 'colors.dart';
import 'constants.dart';
import 'icons.dart';
import 'ink_well.dart';
import 'material.dart';
import 'material_localizations.dart';
import 'material_state.dart';
import 'menu_bar_theme.dart';
import 'menu_button_theme.dart';
import 'menu_style.dart';
import 'menu_theme.dart';
import 'text_button.dart';
import 'theme.dart';
import 'theme_data.dart';

// Enable if you want verbose logging about menu changes.
const bool _kDebugMenus = false;

// How close to the edge of the safe area the menu will be placed.
const double _kMenuViewPadding = 8.0;

// The default size of the arrow in _MenuItemLabel that indicates that a menu
// has a submenu.
const double _kDefaultSubmenuIconSize = 24.0;

// The default spacing between the the leading icon, label, trailing icon, and
// shortcut label in a _MenuItemLabel.
const double _kLabelItemDefaultSpacing = 18.0;

// The minimum spacing between the the leading icon, label, trailing icon, and
// shortcut label in a _MenuItemLabel.
const double _kLabelItemMinSpacing = 4.0;

// The minimum vertical spacing on the outside of menus.
const double _kMenuVerticalMinPadding = 4.0;

// The minimum horizontal spacing on the outside of the top level menu.
const double _kTopLevelMenuHorizontalMinPadding = 4.0;

// Navigation shortcuts that we need to make sure are active when menus are
// open.
const Map<ShortcutActivator, Intent> _kMenuTraversalShortcuts = <ShortcutActivator, Intent>{
  SingleActivator(LogicalKeyboardKey.gameButtonA): ActivateIntent(),
  SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
  SingleActivator(LogicalKeyboardKey.tab): NextFocusIntent(),
  SingleActivator(LogicalKeyboardKey.tab, shift: true): PreviousFocusIntent(),
  SingleActivator(LogicalKeyboardKey.arrowDown): DirectionalFocusIntent(TraversalDirection.down),
  SingleActivator(LogicalKeyboardKey.arrowUp): DirectionalFocusIntent(TraversalDirection.up),
  SingleActivator(LogicalKeyboardKey.arrowLeft): DirectionalFocusIntent(TraversalDirection.left),
  SingleActivator(LogicalKeyboardKey.arrowRight): DirectionalFocusIntent(TraversalDirection.right),
};

/// A menu bar that manages cascading child menus.
///
/// This is a Material Design menu bar that typically resides above the main
/// body of an application (but can go anywhere) that defines a menu system for
/// invoking callbacks or firing [Intent]s in response to user selection of a
/// menu item.
///
/// The menus can be opened with a click or tap. Once a menu is opened, it can
/// be navigated by using the arrow and tab keys or via mouse hover. Selecting a
/// menu item can be done by pressing enter, or by clicking or tapping on the
/// menu item. Clicking or tapping on any part of the user interface that isn't
/// part of the menu system controlled by the same controller will cause all of
/// the menus controlled by that controller to close, as will pressing the
/// escape key.
///
/// When a menu item with a submenu is clicked on, it toggles the visibility of
/// the submenu. When the menu item is hovered over, the submenu will open, and
/// hovering over other items will close the previous menu and open the newly
/// hovered one. When those open/close transitions occur, [MenuButton.onOpen],
/// and [MenuButton.onClose] are called on the corresponding [MenuButton] child
/// of the menu bar.
///
/// {@template flutter.material.menu_bar.shortcuts_note}
/// Menu items using [MenuItemButton] can have a [SingleActivator] or
/// [CharacterActivator] assigned to them as their [MenuItemButton.shortcut],
/// which will display an appropriate shortcut hint. Even though their labels
/// are displayed in the menu, shortcuts are not automatically handled, they
/// must be available in whatever context they are appropriate, and handled
/// via another mechanism.
///
/// If shortcuts should be generally enabled, but are not easily defined in a
/// context surrounding the menu bar, consider registering them with a
/// [ShortcutRegistry] (one is already included in the [WidgetsApp], and thus
/// also [MaterialApp] and [CupertinoApp]), as shown in the example below. To be
/// sure that selecting a menu item and triggering the shortcut do the same
/// thing, it is recommended that they call the same callback.
///
/// {@tool dartpad}
/// This example shows a [MenuBar] that contains a single top level menu,
/// containing three items for "About", a checkbox menu item for showing a
/// message, and "Quit". The items are identified with an enum value, and the
/// shortcuts are registered globally with the [ShortcutRegistry].
///
/// ** See code in examples/api/lib/material/menu_bar/menu_bar.0.dart **
/// {@end-tool}
/// {@endtemplate}
///
/// See also:
///
/// * [MenuButton], a menu item which manages a submenu.
/// * [MenuItemButton], a leaf menu item which displays the label, an optional
///   shortcut label, and optional leading and trailing icons.
/// * [createMaterialMenu], a function that creates a [MenuHandle] that allows
///   creation and management of a cascading menu anywhere.
/// * [MenuController], a class that allows controlling and connecting menus.
/// * [PlatformMenuBar], which creates a menu bar that is rendered by the host
///   platform instead of by Flutter (on macOS, for example).
/// * [ShortcutRegistry], a registry of shortcuts that apply for the entire
///   application.
/// * [VoidCallbackIntent] to define intents that will call a [VoidCallback] and
///   work with the [Actions] and [Shortcuts] system.
/// * [CallbackShortcuts] to define shortcuts that simply call a callback and
///   don't involve using [Actions].
class MenuBar extends StatefulWidget with DiagnosticableTreeMixin {
  /// Creates a const [MenuBar].
  const MenuBar({
    super.key,
    this.controller,
    this.style,
    this.clipBehavior = Clip.none,
    required this.children,
  });

  /// An optional controller that allows outside control of the menu bar.
  ///
  /// A controller can be used to close any open menus from outside of the menu
  /// bar using [MenuController.closeAll].
  ///
  /// Controllers also collect multiple menus into a group: moving from one menu
  /// to another that uses the same menu controller is possible using the
  /// keyboard arrow keys.
  ///
  /// If a controller is provided here, it must be disposed by the owner of the
  /// controller when it is done being used. It cannot be used after
  /// [MenuController.dispose] is called.
  final MenuController? controller;

  /// The [MenuStyle] that defines the visual attributes of the menu bar.
  ///
  /// Colors and sizing of the menus is controllable via the [MenuStyle].
  ///
  /// Defaults to the ambient [MenuThemeData.style].
  final MenuStyle? style;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.none], and must not be null.
  final Clip clipBehavior;

  /// The list of menu items that are the top level children of the
  /// [MenuBar].
  ///
  /// A Widget in Flutter is immutable, so directly modifying the `children`
  /// with [List] APIs such as `someMenuBarWidget.menus.add(...)` will result in
  /// incorrect behaviors. Whenever the menus list is modified, a new list
  /// object should be provided.
  ///
  /// {@macro flutter.material.menu_bar.shortcuts_note}
  final List<Widget> children;

  @override
  State<MenuBar> createState() => _MenuBarState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<MenuController?>('controller', controller, defaultValue: null));
    properties.add(DiagnosticsProperty<MenuStyle?>('style', style, defaultValue: null));
    properties.add(DiagnosticsProperty<Clip>('clipBehavior', clipBehavior, defaultValue: null));
  }
}

class _MenuBarState extends State<MenuBar> with DiagnosticableTreeMixin {
  MenuController? _internalController;
  MenuController get _controller {
    return widget.controller ?? (_internalController ??= MenuController());
  }

  @override
  void initState() {
    super.initState();
    assert(() {
      _controller._root._menuScopeNode.debugLabel = 'MenuBar';
      return true;
    }());
  }

  @override
  void didUpdateWidget(MenuBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != null) {
      _internalController?.dispose();
      _internalController = null;
    }
  }

  @override
  void dispose() {
    _internalController?.dispose();
    _internalController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasOverlay(context));
    return FocusScope(
      node: _controller._menuScopeNode,
      child: Actions(
        actions: <Type, Action<Intent>>{
          DirectionalFocusIntent: _MenuDirectionalFocusAction(controller: _controller),
          DismissIntent: _MenuDismissAction(controller: _controller),
        },
        child: Shortcuts(
          shortcuts: _kMenuTraversalShortcuts,
          child: MenuAnchor(
            controller: _controller,
            builder: (BuildContext context) {
              return _MenuPanel(
                menuStyle: widget.style,
                clipBehavior: widget.clipBehavior,
                orientation: Axis.horizontal,
                children: widget.children,
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return <DiagnosticsNode>[
      ...widget.children.map<DiagnosticsNode>(
        (Widget item) => item.toDiagnosticsNode(),
      ),
    ];
  }
}

/// A button for use in a [MenuBar] or menu created with [createMaterialMenu]
/// that can be activated by click or keyboard navigation that displays a
/// shortcut hint and optional leading/trailing icons.
///
/// This widget represents a leaf entry in a menu hierarchy that is typically
/// part of a [MenuBar], but may be used independently, or as part of a menu
/// created with [createMaterialMenu].
///
/// The menu item shows a hint for an associated shortcut, if any. When selected
/// via click or by pressing enter while focused, it will call its [onPressed]
/// callback. Pressing the [shortcut] will not automatically call the
/// [onPressed] callback: handling of the shortcut must happen outside of the
/// menu system. If [onPressed] is null, then this item will be disabled.
///
/// {@macro flutter.material.menu_bar.shortcuts_note}
///
/// See also:
///
/// * [MenuBar], a class that creates a top level menu bar in a Material Design
///   style.
/// * [createMaterialMenu], a function that creates a [MenuHandle] that allows
///   creation and management of a cascading menu anywhere.
/// * [MenuButton], a menu item similar to this one which manages a submenu.
/// * [MenuController], a class that allows controlling and connecting menus.
/// * [PlatformMenuBar], which creates a menu bar that is rendered by the host
///   platform instead of by Flutter (on macOS, for example).
/// * [ShortcutRegistry], a registry of shortcuts that apply for the entire
///   application.
/// * [VoidCallbackIntent] to define intents that will call a [VoidCallback] and
///   work with the [Actions] and [Shortcuts] system.
/// * [CallbackShortcuts] to define shortcuts that simply call a callback and
///   don't involve using [Actions].
class MenuItemButton extends StatefulWidget {
  /// Creates a const [MenuItemButton].
  ///
  /// The [child] attribute is required.
  const MenuItemButton({
    super.key,
    this.shortcut,
    this.onPressed,
    this.onHover,
    this.onFocusChange,
    this.focusNode,
    this.style,
    this.statesController,
    this.clipBehavior = Clip.none,
    this.leadingIcon,
    this.trailingIcon,
    required this.child,
  });

  /// Called when the button is tapped or otherwise activated.
  ///
  /// If this callback is null, then the button will be disabled.
  ///
  /// See also:
  ///
  ///  * [enabled], which is true if the button is enabled.
  final VoidCallback? onPressed;

  /// Called when a pointer enters or exits the button response area.
  ///
  /// The value passed to the callback is true if a pointer has entered button
  /// area and false if a pointer has exited.
  final ValueChanged<bool>? onHover;

  /// Handler called when the focus changes.
  ///
  /// Called with true if this widget's node gains focus, and false if it loses
  /// focus.
  final ValueChanged<bool>? onFocusChange;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.none].
  final Clip clipBehavior;

  /// {@macro flutter.widgets.Focus.focusNode}
  final FocusNode? focusNode;

  /// Customizes this button's appearance.
  ///
  /// Non-null properties of this style override the corresponding properties in
  /// [themeStyleOf] and [defaultStyleOf]. [MaterialStateProperty]s that resolve
  /// to non-null values will similarly override the corresponding
  /// [MaterialStateProperty]s in [themeStyleOf] and [defaultStyleOf].
  ///
  /// Null by default.
  final ButtonStyle? style;

  /// {@macro flutter.material.inkwell.statesController}
  final MaterialStatesController? statesController;

  /// The widget displayed in the center of this button.
  ///
  /// Typically this is the button's label, using a [Text] widget.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget? child;

  /// The optional shortcut that selects this [MenuItemButton].
  ///
  /// {@macro flutter.material.menu_bar.shortcuts_note}
  final MenuSerializableShortcut? shortcut;

  /// An optional icon to display before the [child] label.
  final Widget? leadingIcon;

  /// An optional icon to display after the [child] label.
  final Widget? trailingIcon;

  /// Whether the button is enabled or disabled.
  ///
  /// To enable a button, set its [onPressed] property to a non-null value.
  bool get enabled => onPressed != null;

  @override
  State<MenuItemButton> createState() => _MenuItemButtonState();

  /// Defines the button's default appearance.
  ///
  /// The button [child]'s [Text] and [Icon] widgets are rendered with
  /// the [style]'s foreground color. The button's [InkWell] adds
  /// the [style]'s overlay color when the button is focused, hovered
  /// or pressed. The button's background color becomes its [Material]
  /// color and is transparent by default.
  ///
  /// All of the [ButtonStyle]'s defaults appear below.
  ///
  /// In this list "Theme.foo" is shorthand for `Theme.of(context).foo`. Color
  /// scheme values like "onSurface(0.38)" are shorthand for
  /// `onSurface.withOpacity(0.38)`. [MaterialStateProperty] valued properties
  /// that are not followed by a list have the same value for all states,
  /// otherwise the values are as specified for each state and "others" means
  /// all other states.
  ///
  /// The `textScaleFactor` is the value of
  /// `MediaQuery.of(context).textScaleFactor` and the names of the
  /// [EdgeInsets] constructors and [EdgeInsetsGeometry.lerp] have been
  /// abbreviated for readability.
  ///
  /// The color of the [ButtonStyle.textStyle] is not used, the
  /// [ButtonStyle.foregroundColor] color is used instead.
  ///
  /// * `textStyle` - Theme.textTheme.labelLarge
  /// * `backgroundColor` - transparent
  /// * `foregroundColor`
  ///   * disabled - Theme.colorScheme.onSurface(0.38)
  ///   * others - Theme.colorScheme.primary
  /// * `overlayColor`
  ///   * hovered - Theme.colorScheme.primary(0.08)
  ///   * focused or pressed - Theme.colorScheme.primary(0.12)
  ///   * others - null
  /// * `shadowColor` - null
  /// * `surfaceTintColor` - null
  /// * `elevation` - 0
  /// * `padding`
  ///   * `textScaleFactor <= 1` - all(8)
  ///   * `1 < textScaleFactor <= 2` - lerp(all(8), horizontal(8))
  ///   * `2 < textScaleFactor <= 3` - lerp(horizontal(8), horizontal(4))
  ///   * `3 < textScaleFactor` - horizontal(4)
  /// * `minimumSize` - Size(64, 40)
  /// * `fixedSize` - null
  /// * `maximumSize` - Size.infinite
  /// * `side` - null
  /// * `shape` - StadiumBorder()
  /// * `mouseCursor`
  ///   * disabled - SystemMouseCursors.basic
  ///   * others - SystemMouseCursors.click
  /// * `visualDensity` - theme.visualDensity
  /// * `tapTargetSize` - theme.materialTapTargetSize
  /// * `animationDuration` - kThemeChangeDuration
  /// * `enableFeedback` - true
  /// * `alignment` - Alignment.center
  /// * `splashFactory` - Theme.splashFactory
  ButtonStyle defaultStyleOf(BuildContext context) {
    return _MenuButtonDefaultsM3(context);
  }

  /// Returns the [MenuButtonThemeData.style] of the closest
  /// [MenuButtonTheme] ancestor.
  ButtonStyle? themeStyleOf(BuildContext context) {
    return MenuButtonTheme.of(context).style;
  }

  /// A static convenience method that constructs a [MenuItemButton]'s
  /// [ButtonStyle] given simple values.
  ///
  /// The [foregroundColor] color is used to create a [MaterialStateProperty]
  /// [ButtonStyle.foregroundColor] value. Specify a value for [foregroundColor]
  /// to specify the color of the button's icons. Use [backgroundColor] for the
  /// button's background fill color. Use [disabledForegroundColor] and
  /// [disabledBackgroundColor] to specify the button's disabled icon and fill
  /// color.
  ///
  /// All of the other parameters are either used directly or used to create a
  /// [MaterialStateProperty] with a single value for all states.
  ///
  /// All parameters default to null, by default this method returns a
  /// [ButtonStyle] that doesn't override anything.
  ///
  /// For example, to override the default foreground color for a
  /// [MenuItemButton], as well as its overlay color, with all of the standard
  /// opacity adjustments for the pressed, focused, and hovered states, one
  /// could write:
  ///
  /// ```dart
  /// MenuItemButton(
  ///   leadingIcon: const Icon(Icons.pets),
  ///   style: MenuItemButton.styleFrom(foregroundColor: Colors.green),
  ///   onPressed: () {
  ///     // ...
  ///   },
  ///   child: const Text('Button Label'),
  /// ),
  /// ```
  static ButtonStyle styleFrom({
    Color? foregroundColor,
    Color? backgroundColor,
    Color? disabledForegroundColor,
    Color? disabledBackgroundColor,
    Color? shadowColor,
    Color? surfaceTintColor,
    TextStyle? textStyle,
    double? elevation,
    EdgeInsetsGeometry? padding,
    Size? minimumSize,
    Size? fixedSize,
    Size? maximumSize,
    MouseCursor? enabledMouseCursor,
    MouseCursor? disabledMouseCursor,
    BorderSide? side,
    OutlinedBorder? shape,
    VisualDensity? visualDensity,
    MaterialTapTargetSize? tapTargetSize,
    Duration? animationDuration,
    bool? enableFeedback,
    AlignmentGeometry? alignment,
    InteractiveInkFeatureFactory? splashFactory,
  }) {
    return TextButton.styleFrom(
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
      disabledBackgroundColor: disabledBackgroundColor,
      disabledForegroundColor: disabledForegroundColor,
      shadowColor: shadowColor,
      surfaceTintColor: surfaceTintColor,
      textStyle: textStyle,
      elevation: elevation,
      padding: padding,
      minimumSize: minimumSize,
      fixedSize: fixedSize,
      maximumSize: maximumSize,
      enabledMouseCursor: enabledMouseCursor,
      disabledMouseCursor: disabledMouseCursor,
      side: side,
      shape: shape,
      visualDensity: visualDensity,
      tapTargetSize: tapTargetSize,
      animationDuration: animationDuration,
      enableFeedback: enableFeedback,
      alignment: alignment,
      splashFactory: splashFactory,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('enabled', value: onPressed != null, ifFalse: 'DISABLED'));
    properties.add(DiagnosticsProperty<String>('child', child.toString()));
    properties.add(DiagnosticsProperty<ButtonStyle?>('style', style, defaultValue: null));
    properties.add(DiagnosticsProperty<MenuSerializableShortcut?>('shortcut', shortcut, defaultValue: null));
    properties.add(DiagnosticsProperty<Widget?>('leadingIcon', leadingIcon, defaultValue: null));
    properties.add(DiagnosticsProperty<Widget?>('trailingIcon', trailingIcon, defaultValue: null));
    properties.add(DiagnosticsProperty<FocusNode?>('focusNode', focusNode, defaultValue: null));
    properties.add(EnumProperty<Clip>('clipBehavior', clipBehavior, defaultValue: Clip.none));
    properties
        .add(DiagnosticsProperty<MaterialStatesController?>('statesController', statesController, defaultValue: null));
  }
}

class _MenuItemButtonState extends State<MenuItemButton> {
  FocusNode? _internalFocusNode;
  FocusNode get _focusNode => widget.focusNode ?? _internalFocusNode!;
  bool get _enabled => widget.onPressed != null;

  @override
  void initState() {
    super.initState();
    _createInternalFocusNodeIfNeeded();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _internalFocusNode?.dispose();
    _internalFocusNode = null;
    super.dispose();
  }

  @override
  void didUpdateWidget(MenuItemButton oldWidget) {
    if (widget.focusNode != oldWidget.focusNode) {
      _focusNode.removeListener(_handleFocusChange);
      if (widget.focusNode != null) {
        _internalFocusNode?.dispose();
        _internalFocusNode = null;
      }
      _createInternalFocusNodeIfNeeded();
      _focusNode.addListener(_handleFocusChange);
    }
    super.didUpdateWidget(oldWidget);
  }

  void _handleFocusChange() {
    if (!_focusNode.hasPrimaryFocus) {
      // Close any child menus of this menu.
      _MenuHandleBase.maybeOf(context)?._closeChildren();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Since we don't want to use the theme style or default style from the
    // TextButton, we merge the styles, merging them in the right order when
    // each type of style exists. Each "*StyleOf" function is only called once.
    final ButtonStyle mergedStyle =
        widget.style?.merge(widget.themeStyleOf(context)?.merge(widget.defaultStyleOf(context))) ??
            widget.themeStyleOf(context)?.merge(widget.defaultStyleOf(context)) ??
            widget.defaultStyleOf(context);

    return TextButton(
      onPressed: _enabled ? _handleSelect : null,
      onHover: _enabled ? _handleHover : null,
      onFocusChange: _enabled ? widget.onFocusChange : null,
      focusNode: _focusNode,
      style: mergedStyle,
      statesController: widget.statesController,
      clipBehavior: widget.clipBehavior,
      child: _MenuItemLabel(
        leadingIcon: widget.leadingIcon,
        shortcut: widget.shortcut,
        trailingIcon: widget.trailingIcon,
        hasSubmenu: false,
        child: widget.child!,
      ),
    );
  }

  void _createInternalFocusNodeIfNeeded() {
    if (widget.focusNode == null) {
      _internalFocusNode = FocusNode();
      assert(() {
        if (_internalFocusNode != null) {
          _internalFocusNode!.debugLabel = '$MenuItemButton(${widget.child})';
        }
        return true;
      }());
    }
  }

  void _handleHover(bool hovering) {
    widget.onHover?.call(hovering);
    if (hovering) {
      setState(() {
        assert(_debugMenuInfo('Requesting focus for $_focusNode from hover'));
        _focusNode.requestFocus();
      });
    }
  }

  void _handleSelect() {
    assert(_debugMenuInfo('Selected ${widget.child} menu'));
    widget.onPressed?.call();
    MenuController.of(context).closeAll();
  }
}

/// A menu button that displays a cascading menu as part of a [MenuBar], or as
/// part of a menu defined by [createMaterialMenu].
///
/// This widget represents an item in a [MenuBar] or menu that has a submenu.
/// Like the leaf [MenuItemButton], it shows a label with an optional leading or
/// trailing icon, but additionally shows an arrow icon showing that it has a
/// submenu.
///
/// By default the submenu will appear to the side of the controlling button.
/// The alignment and offset of the submenu can be controlled by setting
/// [MenuStyle.alignment] on the [style] and [alignmentOffset] argument,
/// respectively.
///
/// When activated (clicked, through keyboard navigation, or via hovering with a
/// mouse), it will open a submenu containing the [menuChildren].
///
/// If [menuChildren] is empty, then this menu item will appear disabled.
///
/// See also:
///
/// * [MenuItemButton], a widget that represents a leaf menu item that does not
///   host a submenu.
/// * [MenuBar], a widget that renders menu items in a row in a Material Design
///   style.
/// * [createMaterialMenu], a function that creates a menu and shows it when
///   requested.
/// * [PlatformMenuBar], a widget that renders similar menu bar items from a
///   [PlatformMenuItem] using platform-native APIs instead of Flutter.
class MenuButton extends StatefulWidget {
  /// Creates a const [MenuButton].
  ///
  /// The [child] attribute is required.
  const MenuButton({
    super.key,
    this.onHover,
    this.onFocusChange,
    this.style,
    this.focusNode,
    this.clipBehavior = Clip.none,
    this.statesController,
    this.leadingIcon,
    this.trailingIcon,
    this.onOpen,
    this.onClose,
    this.menuStyle,
    this.alignmentOffset,
    required this.menuChildren,
    required this.child,
  });

  /// Called when a pointer enters or exits the button response area.
  ///
  /// The value passed to the callback is true if a pointer has entered this
  /// part of the button and false if a pointer has exited.
  final ValueChanged<bool>? onHover;

  /// Handler called when the focus changes.
  ///
  /// Called with true if this widget's node gains focus, and false if it loses
  /// focus.
  final ValueChanged<bool>? onFocusChange;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.none], and must not be null.
  final Clip clipBehavior;

  /// {@macro flutter.widgets.Focus.focusNode}
  final FocusNode? focusNode;

  /// Customizes this button's appearance.
  ///
  /// Non-null properties of this style override the corresponding properties in
  /// [themeStyleOf] and [defaultStyleOf]. [MaterialStateProperty]s that resolve
  /// to non-null values will similarly override the corresponding
  /// [MaterialStateProperty]s in [themeStyleOf] and [defaultStyleOf].
  ///
  /// Null by default.
  final ButtonStyle? style;

  /// {@macro flutter.material.inkwell.statesController}
  final MaterialStatesController? statesController;

  /// Typically the button's label.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget? child;

  /// The offset in pixels of the menu relative to the alignment origin
  /// determined by [MenuStyle.alignment] on the [style] attribute.
  ///
  /// Use this for fine adjustments of the menu placement.
  ///
  /// Defaults to the [EdgeInsetsDirectional.start] portion of
  /// [MenuStyle.padding] on the [style] attribute for menus whose parent menu
  /// (the menu that the button for this menu resides in) is vertical, and the
  /// [EdgeInsetsDirectional.top] portion of [MenuStyle.padding] on the [style]
  /// attribute when it is horizontal.
  final Offset? alignmentOffset;

  /// An optional icon to display before the [child].
  final Widget? leadingIcon;

  /// An optional icon to display after the [child].
  final Widget? trailingIcon;

  /// The [MenuStyle] of the menu specified by [menuChildren].
  ///
  /// Defaults to the value of [MenuThemeData.style] of the
  /// ambient [MenuTheme].
  final MenuStyle? menuStyle;

  /// A callback that is invoked when the menu is opened.
  final VoidCallback? onOpen;

  /// A callback that is invoked when the menu is closed.
  final VoidCallback? onClose;

  /// The list of widgets that appear in the menu when it is opened.
  ///
  /// These can be any widget, but are typically either [MenuItemButton] or
  /// [MenuButton] widgets.
  ///
  /// If `menuChildren` is empty, then the button for this menu item will be
  /// disabled.
  final List<Widget> menuChildren;

  /// Defines the button's default appearance.
  ///
  /// The button [child]'s [Text] and [Icon] widgets are rendered with
  /// the [ButtonStyle]'s foreground color. The button's [InkWell] adds
  /// the style's overlay color when the button is focused, hovered
  /// or pressed. The button's background color becomes its [Material]
  /// color and is transparent by default.
  ///
  /// All of the ButtonStyle's defaults appear below.
  ///
  /// In this list "Theme.foo" is shorthand for
  /// `Theme.of(context).foo`. Color scheme values like
  /// "onSurface(0.38)" are shorthand for
  /// `onSurface.withOpacity(0.38)`. [MaterialStateProperty] valued
  /// properties that are not followed by a sublist have the same
  /// value for all states, otherwise the values are as specified for
  /// each state and "others" means all other states.
  ///
  /// The `textScaleFactor` is the value of
  /// `MediaQuery.of(context).textScaleFactor` and the names of the
  /// EdgeInsets constructors and `EdgeInsetsGeometry.lerp` have been
  /// abbreviated for readability.
  ///
  /// The color of the [ButtonStyle.textStyle] is not used, the
  /// [ButtonStyle.foregroundColor] color is used instead.
  ///
  /// * `textStyle` - Theme.textTheme.labelLarge
  /// * `backgroundColor` - transparent
  /// * `foregroundColor`
  ///   * disabled - Theme.colorScheme.onSurface(0.38)
  ///   * others - Theme.colorScheme.primary
  /// * `overlayColor`
  ///   * hovered - Theme.colorScheme.primary(0.08)
  ///   * focused or pressed - Theme.colorScheme.primary(0.12)
  ///   * others - null
  /// * `shadowColor` - null
  /// * `surfaceTintColor` - null
  /// * `elevation` - 0
  /// * `padding`
  ///   * `textScaleFactor <= 1` - all(8)
  ///   * `1 < textScaleFactor <= 2` - lerp(all(8), horizontal(8))
  ///   * `2 < textScaleFactor <= 3` - lerp(horizontal(8), horizontal(4))
  ///   * `3 < textScaleFactor` - horizontal(4)
  /// * `minimumSize` - Size(64, 40)
  /// * `fixedSize` - null
  /// * `maximumSize` - Size.infinite
  /// * `side` - null
  /// * `shape` - StadiumBorder()
  /// * `mouseCursor`
  ///   * disabled - SystemMouseCursors.basic
  ///   * others - SystemMouseCursors.click
  /// * `visualDensity` - theme.visualDensity
  /// * `tapTargetSize` - theme.materialTapTargetSize
  /// * `animationDuration` - kThemeChangeDuration
  /// * `enableFeedback` - true
  /// * `alignment` - Alignment.center
  /// * `splashFactory` - Theme.splashFactory
  ButtonStyle defaultStyleOf(BuildContext context) {
    return _MenuButtonDefaultsM3(context);
  }

  /// Returns the [MenuButtonThemeData.style] of the closest
  /// [MenuButtonTheme] ancestor.
  ButtonStyle? themeStyleOf(BuildContext context) {
    return MenuButtonTheme.of(context).style;
  }

  /// A static convenience method that constructs a [MenuButton]'s [ButtonStyle]
  /// given simple values.
  ///
  /// The [foregroundColor] color is used to create a [MaterialStateProperty]
  /// [ButtonStyle.foregroundColor] value. Specify a value for [foregroundColor]
  /// to specify the color of the button's icons. Use [backgroundColor] for the
  /// button's background fill color. Use [disabledForegroundColor] and
  /// [disabledBackgroundColor] to specify the button's disabled icon and fill
  /// color.
  ///
  /// All of the other parameters are either used directly or used to create a
  /// [MaterialStateProperty] with a single value for all states.
  ///
  /// All parameters default to null, by default this method returns a
  /// [ButtonStyle] that doesn't override anything.
  ///
  /// For example, to override the default foreground color for a [MenuButton],
  /// as well as its overlay color, with all of the standard opacity adjustments
  /// for the pressed, focused, and hovered states, one could write:
  ///
  /// ```dart
  /// MenuButton(
  ///   leadingIcon: const Icon(Icons.pets),
  ///   style: MenuButton.styleFrom(foregroundColor: Colors.green),
  ///   menuChildren: const <Widget>[ /* ... */ ],
  ///   child: const Text('Button Label'),
  /// ),
  /// ```
  static ButtonStyle styleFrom({
    Color? foregroundColor,
    Color? backgroundColor,
    Color? disabledForegroundColor,
    Color? disabledBackgroundColor,
    Color? shadowColor,
    Color? surfaceTintColor,
    TextStyle? textStyle,
    double? elevation,
    EdgeInsetsGeometry? padding,
    Size? minimumSize,
    Size? fixedSize,
    Size? maximumSize,
    MouseCursor? enabledMouseCursor,
    MouseCursor? disabledMouseCursor,
    BorderSide? side,
    OutlinedBorder? shape,
    VisualDensity? visualDensity,
    MaterialTapTargetSize? tapTargetSize,
    Duration? animationDuration,
    bool? enableFeedback,
    AlignmentGeometry? alignment,
    InteractiveInkFeatureFactory? splashFactory,
  }) {
    return TextButton.styleFrom(
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
      disabledBackgroundColor: disabledBackgroundColor,
      disabledForegroundColor: disabledForegroundColor,
      shadowColor: shadowColor,
      surfaceTintColor: surfaceTintColor,
      textStyle: textStyle,
      elevation: elevation,
      padding: padding,
      minimumSize: minimumSize,
      fixedSize: fixedSize,
      maximumSize: maximumSize,
      enabledMouseCursor: enabledMouseCursor,
      disabledMouseCursor: disabledMouseCursor,
      side: side,
      shape: shape,
      visualDensity: visualDensity,
      tapTargetSize: tapTargetSize,
      animationDuration: animationDuration,
      enableFeedback: enableFeedback,
      alignment: alignment,
      splashFactory: splashFactory,
    );
  }

  @override
  State<MenuButton> createState() => _MenuButtonState();

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return <DiagnosticsNode>[
      ...menuChildren.map<DiagnosticsNode>((Widget child) {
        return child.toDiagnosticsNode();
      })
    ];
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<String>('label', child.toString(), defaultValue: null));
    properties.add(DiagnosticsProperty<MenuStyle>('menuStyle', menuStyle, defaultValue: null));
    properties.add(DiagnosticsProperty<Widget>('leadingIcon', leadingIcon, defaultValue: null));
    properties.add(DiagnosticsProperty<Widget>('trailingIcon', trailingIcon, defaultValue: null));
  }
}

class _MenuButtonState extends State<MenuButton> {
  MenuHandle? _handle;
  bool get _enabled => widget.menuChildren.isNotEmpty;
  FocusNode? _internalFocusNode;
  MenuController? _internalMenuController;
  FocusNode get _buttonFocusNode => widget.focusNode ?? _internalFocusNode!;
  bool _waitingToFocusMenu = false;
  final GlobalKey _buttonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _internalFocusNode = FocusNode();
      assert(() {
        if (_internalFocusNode != null) {
          _internalFocusNode!.debugLabel = '$MenuButton(${widget.child})';
        }
        return true;
      }());
    }
    _buttonFocusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _handle?.dispose();
    _internalFocusNode?.removeListener(_handleFocusChange);
    _internalFocusNode?.dispose();
    _internalMenuController?.dispose();
    _internalFocusNode = null;
    super.dispose();
  }

  @override
  void didUpdateWidget(MenuButton oldWidget) {
    if (widget.focusNode != oldWidget.focusNode) {
      if (oldWidget.focusNode == null) {
        _internalFocusNode?.removeListener(_handleFocusChange);
        _internalFocusNode?.dispose();
        _internalFocusNode = null;
      } else {
        oldWidget.focusNode!.removeListener(_handleFocusChange);
      }
      if (widget.focusNode == null) {
        _internalFocusNode ??= FocusNode();
        assert(() {
          if (_internalFocusNode != null) {
            _internalFocusNode!.debugLabel = '$MenuButton(${widget.child})';
          }
          return true;
        }());
      }
      _buttonFocusNode.addListener(_handleFocusChange);
    }
    super.didUpdateWidget(oldWidget);
  }

  void _updateChildMenu(BuildContext context) {
    final MenuController controller = MenuController.maybeOf(context) ?? (_internalMenuController ??= MenuController());
    final _MenuHandleBase parent = _MenuHandleBase.maybeOf(context) ?? controller._root;
    final MenuStyle? themeStyle = MenuTheme.of(context).style;
    final MenuStyle defaultStyle = _MenuDefaultsM3(context);

    T? effectiveValue<T>(T? Function(MenuStyle? style) getProperty) {
      return getProperty(widget.menuStyle) ?? getProperty(themeStyle) ?? getProperty(defaultStyle);
    }

    T? resolve<T>(MaterialStateProperty<T>? Function(MenuStyle? style) getProperty) {
      return effectiveValue(
        (MenuStyle? style) {
          return getProperty(style)?.resolve(widget.statesController?.value ?? const <MaterialState>{});
        },
      );
    }

    final Offset menuPaddingOffset;
    final TextDirection textDirection = Directionality.of(context);
    final EdgeInsets menuPadding =
        resolve<EdgeInsetsGeometry?>((MenuStyle? style) => style?.padding)!.resolve(textDirection);
    switch (parent._orientation) {
      case Axis.horizontal:
        switch (textDirection) {
          case TextDirection.rtl:
            menuPaddingOffset = widget.alignmentOffset ?? Offset(-menuPadding.right, 0);
            break;
          case TextDirection.ltr:
            menuPaddingOffset = widget.alignmentOffset ?? Offset(-menuPadding.left, 0);
            break;
        }
        break;
      case Axis.vertical:
        menuPaddingOffset = widget.alignmentOffset ?? Offset(0, -menuPadding.top);
        break;
    }

    _handle?.dispose();
    _handle = MenuHandle._(
      parent: parent,
      buttonFocusNode: _buttonFocusNode,
      buttonStyle: widget.style,
      menuStyle: widget.menuStyle,
      menuClipBehavior: widget.clipBehavior,
      onOpen: widget.onOpen,
      onClose: widget.onClose,
      alignmentOffset: menuPaddingOffset,
      menuChildren: widget.menuChildren,
    );
  }

  @override
  Widget build(BuildContext context) {
    _updateChildMenu(context);
    return _MenuHandleMarker(
      handle: _handle!,
      child: MenuAnchor(
        builder: (BuildContext context) {
          // Since we don't want to use the theme style or default style from the
          // TextButton, we merge the styles, merging them in the right order when
          // each type of style exists. Each "*StyleOf" function is only called once.
          final ButtonStyle mergedStyle =
              widget.style?.merge(widget.themeStyleOf(context)?.merge(widget.defaultStyleOf(context))) ??
                  widget.themeStyleOf(context)?.merge(widget.defaultStyleOf(context)) ??
                  widget.defaultStyleOf(context);

          return TextButton(
            key: _buttonKey,
            style: mergedStyle,
            focusNode: _buttonFocusNode,
            onHover: _enabled ? (bool hovering) => _handleHover(hovering, context) : null,
            onPressed: _enabled ? () => _toggleShowMenu(context) : null,
            child: _MenuItemLabel(
              leadingIcon: widget.leadingIcon,
              trailingIcon: widget.trailingIcon,
              hasSubmenu: true,
              showDecoration: !_handle!._isTopLevel,
              child: widget.child!,
            ),
          );
        },
      ),
    );
  }

  void _toggleShowMenu(BuildContext context) {
    if (_handle!.isOpen) {
      _handle!.close();
    } else {
      _handle!.open(context);
      if (!_waitingToFocusMenu) {
        // Only schedule this if it's not already scheduled.
        SchedulerBinding.instance.addPostFrameCallback((Duration _) {
          // This has to happen in the next frame because the menu bar is not
          // focusable until the first menu is open.
          _handle!._focusButton();
          _waitingToFocusMenu = false;
        });
        _waitingToFocusMenu = true;
      }
    }
  }

  // Called when the pointer is hovering over the menu button.
  void _handleHover(bool hovering, BuildContext context) {
    widget.onHover?.call(hovering);

    // Don't open the root menu bar menus on hover unless something else
    // is already open. This means that the user has to first click to open a
    // menu on the menu bar before hovering allows them to traverse it.
    if (_handle!._isTopLevel && !_handle!._root._descendantIsOpen) {
      return;
    }

    if (hovering) {
      _handle!.open(context);
      _handle!._focusButton();
    }
  }

  void _handleFocusChange() {
    if (_buttonFocusNode.hasPrimaryFocus) {
      // If it's already open, this does nothing.
      _handle!.open(_buttonKey.currentContext!);
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<String>('label', widget.child.toString()));
  }
}

///
class MenuAnchor extends StatefulWidget {
  ///
  const MenuAnchor({
    super.key,
    required this.builder,
    this.controller,
  });

  ///
  final WidgetBuilder builder;

  /// The supplied controller is owned by the caller, and must be disposed by
  /// the owner when it is no longer in use. If a `controller` is supplied,
  /// calling [MenuController.closeAll] on the controller will close all
  /// associated menus.
  final MenuController? controller;

  @override
  State<MenuAnchor> createState() => _MenuAnchorState();
}

class _MenuAnchorState extends State<MenuAnchor> {
  final LayerLink _link = LayerLink();
  final GlobalKey _anchorKey = GlobalKey(debugLabel: kReleaseMode ? null : 'MenuAnchor');
  bool _controllerChangeScheduled = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_handleControllerChanged);
    super.dispose();
    _disposed = true;
  }

  @override
  void didUpdateWidget(covariant MenuAnchor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_handleControllerChanged);
      widget.controller?.addListener(_handleControllerChanged);
    }
  }

  void _handleControllerChanged() {
    if (!mounted || _disposed) {
      return;
    }
    final SchedulerPhase phase = SchedulerBinding.instance.schedulerPhase;
    switch (phase) {
      case SchedulerPhase.idle:
      case SchedulerPhase.postFrameCallbacks:
      case SchedulerPhase.transientCallbacks:
        setState(() {
          // Controller changed state, so update the anchor's state.
        });
        break;
      case SchedulerPhase.midFrameMicrotasks:
      case SchedulerPhase.persistentCallbacks:
        if (_controllerChangeScheduled) {
          return;
        }
        _controllerChangeScheduled = true;
        SchedulerBinding.instance.addPostFrameCallback((Duration timeStamp) {
          _controllerChangeScheduled = false;
          if (!mounted || _disposed) {
            return;
          }
          setState(() {
            // Controller changed state, so update the anchor's state.
          });
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget child = Builder(
      key: _anchorKey,
      builder: widget.builder,
    );

    if (widget.controller != null) {
      child = ExcludeFocus(
        excluding: !widget.controller!.menuIsOpen,
        child: TapRegion(
          groupId: widget.controller,
          onTapOutside: (PointerDownEvent event) {
            assert(_debugMenuInfo('Tapped Outside ${widget.controller}'));
            widget.controller!.closeAll();
          },
          child: _MenuHandleMarker(
            handle: widget.controller!,
            child: child,
          ),
        ),
      );
    }

    return CompositedTransformTarget(
      link: _link,
      child: _MenuAnchorMarker(
        link: _link,
        anchorKey: _anchorKey,
        child: child,
      ),
    );
  }
}

class _MenuAnchorMarker extends InheritedWidget {
  const _MenuAnchorMarker({
    required super.child,
    required this.link,
    required this.anchorKey,
  });

  final LayerLink link;
  final GlobalKey anchorKey;

  static _MenuAnchorMarker? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_MenuAnchorMarker>();
  }

  @override
  bool updateShouldNotify(_MenuAnchorMarker oldWidget) {
    return link != oldWidget.link || anchorKey != oldWidget.anchorKey;
  }
}

/// Creates a new cascading menu given the focus node for the controlling
/// widget.
///
/// Calling `createMaterialMenu` creates a new cascading menu controlled by
/// another widget, typically some type of button.
///
/// The menu is created in a closed state, and [MenuHandle.open] must be called
/// for the menu to be shown.
///
/// The required argument is a [GlobalKey] that us used to associate a widget
/// with the menu. The [BuildContext] of the associated widget supplies the
/// themes and directionality to use for the menu. If `globalMenuPosition` is
/// not supplied, then this also serves to provide the rectangle used for
/// determining the alignment of the submenu. Typically this is a [GlobalKey]
/// attached to the button that is used to open the menu, but a
/// `globalMenuPosition` may be supplied to override that position, and the key
/// only needs to indicate the widget where the ambient themes and
/// directionality can be found.
///
/// {@template flutter.material.menu_bar.createMaterialMenu.tap_region_note}
/// When creating a menu using [createMaterialMenu], in order to handle the case
/// where the user taps on the control that this menu is associated with and the
/// menu should toggle its open state, it is sometimes necessary to wrap the
/// associated control with a [TapRegion] where the [TapRegion.groupId] is set
/// to the controller for the menu. In this case, it is also necessary to create
/// a [MenuController] to pass.
///
/// If this [TapRegion] is left out, then tapping on the associated control will
/// be considered tapping "outside" of the menu, and close the menu
/// automatically. Since tapping the control is often used to call
/// [MenuHandle.open], the menu will appear to never close when the control is
/// tapped on, instead of toggling, since it closes and is immediately reopened.
/// {@endtemplate}
///
/// The returned [MenuHandle] allows control of menu visibility, and
/// reconfiguration of the menu. Setting values on the returned [MenuHandle]
/// will update the menu with those changes in the next frame. The [MenuHandle]
/// can be listened to for state changes.
///
/// The `buttonFocusNode` argument supplies the optional [FocusNode] of the
/// widget that opens the menu.  If not supplied, then keyboard traversal from
/// the menu to the controlling button will not be possible.
///
/// The optional `controller` argument is a [MenuController] that allows this
/// menu to be coordinated with other related menus. The supplied controller is
/// owned by the caller, and must be disposed by the owner when it is no longer
/// in use. If a `controller` is supplied, calling [MenuController.closeAll] on
/// the controller will close all associated menus.
///
/// An optional [MenuController] may be supplied to allow this menu to be
/// coordinated with other related menus. If you supplied a controller to
/// [MenuAnchor.controller] to the anchor for this menu, you should supply the
/// same one for the `controller` argument here. The supplied controller is
/// owned by the caller, and must be disposed by the owner when it is no longer
/// in use. If a `controller` is supplied, calling [MenuController.closeAll] on
/// the controller will close all associated menus.
///
/// The `style` attribute is the [MenuStyle] object that describes the stylistic
/// attributes of the menu. Any null style attribute will defer to the ambient
/// [MenuTheme] in the context of the [GlobalKey] given as the required
/// argument.
///
/// The `clipBehavior` argument describes how the immediate menu child clips its
/// children. It defaults to [Clip.none].
///
/// The optional `onOpen` callback argument is called whenever the child menu is
/// opened.
///
/// The optional `onClose` callback argument is called whenever the child menu
/// is closed.
///
/// The `alignmentOffset` argument describes a directional offset from either
/// the [MenuStyle.alignment] origin calculated from the ambient [MenuAnchor] in
/// the `context` given to [MenuHandle.open], or from the `globalMenuPosition`
/// argument, if set. The offset depends on the ambient [Directionality], so
/// that increases in `alignmentOffset.dx` will result in moving towards the
/// "end", and decreases will move towards "start".
///
/// The `globalMenuPosition` argument describes the global coordinate where the
/// menu should appear. If unset, then the [MenuStyle.alignment] is used to
/// determine the location instead. The `alignmentOffset` is applied to this
/// position to find the final position that is used. The `globalMenuPosition`
/// argument takes precedence over the ambient [MenuAnchor] and
/// [MenuStyle.alignment].
///
/// The `children` attribute is a list of child menu items to place in the menu.
/// These are typically a tree made up of [MenuButton]s and [MenuItemButton]s,
/// but can be any [Widget].
///
/// {@tool dartpad} This example shows a menu created with `createMaterialMenu`
/// that contains a single top level menu, containing three items: one for
/// "About", a checkbox menu item for showing a message, and "Quit". The items
/// are identified with an enum value.
///
/// ** See code in
/// examples/api/lib/material/menu_bar/create_material_menu.0.dart **
/// {@end-tool}
///
/// See also:
///
/// * [MenuHandle], the handle returned from this function.
/// * [MenuBar], a widget that creates and manages a menu bar with cascading
///   menus.
/// * [MenuButton], a menu button that hosts a submenu.
/// * [MenuItemButton], a menu button that is a leaf menu item, showing an
///   optional shortcut label and leading/trailing icon.
MenuHandle createMaterialMenu({
  FocusNode? buttonFocusNode,
  MenuController? controller,
  MenuStyle? style,
  VoidCallback? onOpen,
  VoidCallback? onClose,
  Offset alignmentOffset = Offset.zero,
  Offset? globalMenuPosition,
  Clip clipBehavior = Clip.none,
  List<Widget> children = const <Widget>[],
}) {
  final bool ownsController = controller == null;
  controller ??= MenuController();
  return MenuHandle._(
    buttonFocusNode: buttonFocusNode,
    parent: controller,
    menuStyle: style,
    menuClipBehavior: clipBehavior,
    onOpen: onOpen,
    onClose: onClose,
    alignmentOffset: alignmentOffset,
    globalMenuPosition: globalMenuPosition,
    menuChildren: children,
    ownsParent: ownsController,
  );
}

RelativeRect _getMenuButtonRect(BuildContext context) {
  final RenderBox button = context.findRenderObject()! as RenderBox;
  final RenderBox overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
  final Offset upperLeft = button.localToGlobal(Offset.zero, ancestor: overlay);
  final Offset lowerRight = button.localToGlobal(button.paintBounds.bottomRight, ancestor: overlay);
  return RelativeRect.fromRect(Rect.fromPoints(upperLeft, lowerRight), overlay.paintBounds);
}

// A widget that defines the menu drawn inside of the overlay entry.
class _Submenu extends StatefulWidget {
  const _Submenu();

  @override
  State<_Submenu> createState() => _SubmenuState();
}

class _SubmenuState extends State<_Submenu> {
  late MenuHandle _handle;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _handle = _MenuHandleBase.maybeOf(context)! as MenuHandle;
  }

  @override
  Widget build(BuildContext context) {
    // Use the text direction of the context where the button is.
    final TextDirection textDirection = Directionality.of(context);
    final MenuButtonThemeData menuButtonTheme = MenuButtonTheme.of(context);
    final Set<MaterialState> state = <MaterialState>{};

    final MenuStyle? themeStyle;
    final MenuStyle defaultStyle;
    switch (_handle._parent!._orientation) {
      case Axis.horizontal:
        themeStyle = MenuBarTheme.of(context).style;
        defaultStyle = _MenuBarDefaultsM3(context);
        break;
      case Axis.vertical:
        themeStyle = MenuTheme.of(context).style;
        defaultStyle = _MenuDefaultsM3(context);
        break;
    }
    final MenuStyle? widgetStyle = _handle._menuStyle;

    T? effectiveValue<T>(T? Function(MenuStyle? style) getProperty) {
      return getProperty(widgetStyle) ?? getProperty(themeStyle) ?? getProperty(defaultStyle);
    }

    final MaterialStateMouseCursor mouseCursor = _MouseCursor(
      (Set<MaterialState> states) => effectiveValue((MenuStyle? style) => style?.mouseCursor?.resolve(states)),
    );

    final VisualDensity visualDensity =
        effectiveValue((MenuStyle? style) => style?.visualDensity) ?? VisualDensity.standard;
    final AlignmentGeometry alignment = effectiveValue((MenuStyle? style) => style?.alignment)!;

    final EdgeInsetsGeometry buttonPadding = _handle._buttonStyle?.padding?.resolve(state) ??
        menuButtonTheme.style?.padding?.resolve(state) ??
        _MenuButtonDefaultsM3(context).padding!.resolve(state);

    final _MenuAnchorMarker? anchor = _handle._globalMenuPosition == null ? _MenuAnchorMarker.maybeOf(context) : null;

    Widget child = CustomSingleChildLayout(
      delegate: _MenuLayout(
        buttonRect: anchor != null ? _getMenuButtonRect(anchor.anchorKey.currentContext!) : null,
        textDirection: textDirection,
        buttonPadding: buttonPadding,
        avoidBounds: DisplayFeatureSubScreen.avoidBounds(MediaQuery.of(context)).toSet(),
        alignment: alignment,
        alignmentOffset: _handle._alignmentOffset,
        globalMenuPosition: _handle._globalMenuPosition,
        orientation: _handle._orientation,
        parentOrientation: _handle._parent!._orientation,
      ),
      child: MouseRegion(
        cursor: mouseCursor,
        hitTestBehavior: HitTestBehavior.deferToChild,
        child: FocusScope(
          node: _handle._menuScopeNode,
          child: Actions(
            actions: <Type, Action<Intent>>{
              DirectionalFocusIntent: _MenuDirectionalFocusAction(controller: _handle._root),
              DismissIntent: _MenuDismissAction(controller: _handle._root),
            },
            child: Shortcuts(
              shortcuts: _kMenuTraversalShortcuts,
              child: _MenuHandleMarker(
                handle: _handle,
                child: Directionality(
                  // Copy the directionality from the button into the overlay.
                  textDirection: textDirection,
                  child: _MenuPanel(
                    menuStyle: widgetStyle,
                    clipBehavior: _handle._menuClipBehavior,
                    orientation: _handle._orientation,
                    children: _handle._menuChildren,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (anchor != null) {
      child = CompositedTransformFollower(
        link: anchor.link,
        offset: -(_handle._buttonRect?.topLeft ?? Offset.zero),
        child: child,
      );
    }

    return Theme(
      data: Theme.of(context).copyWith(
        visualDensity: visualDensity,
      ),
      child: child,
    );
  }
}

// The InheritedWidget marker for _MenuNode, used to find the nearest ancestor
// _MenuNode for a menu.
class _MenuHandleMarker extends InheritedWidget {
  const _MenuHandleMarker({
    required this.handle,
    required super.child,
  });

  final _MenuHandleBase handle;

  @override
  bool updateShouldNotify(_MenuHandleMarker oldWidget) {
    return handle != oldWidget.handle;
  }
}

/// A widget that manages a list of menu buttons in a menu.
///
/// It sizes itself to the widest/tallest item it contains, and then sizes all
/// the other entries to match.
class _MenuPanel extends StatefulWidget {
  const _MenuPanel({
    required this.menuStyle,
    this.clipBehavior = Clip.none,
    required this.orientation,
    required this.children,
  });

  /// The menu style that has all the attributes for this menu panel.
  final MenuStyle? menuStyle;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.none].
  final Clip clipBehavior;

  /// The layout orientation of this panel.
  final Axis orientation;

  /// The list of widgets to use as children of this menu bar.
  ///
  /// These are the top level [MenuButton]s.
  final List<Widget> children;

  @override
  State<_MenuPanel> createState() => _MenuPanelState();
}

class _MenuPanelState extends State<_MenuPanel> {
  Widget _intrinsicCrossSize({required Widget child}) {
    switch (widget.orientation) {
      case Axis.horizontal:
        return IntrinsicHeight(child: child);
      case Axis.vertical:
        return IntrinsicWidth(child: child);
    }
  }

  @override
  Widget build(BuildContext context) {
    final MenuStyle? themeStyle;
    final MenuStyle defaultStyle;
    switch (widget.orientation) {
      case Axis.horizontal:
        themeStyle = MenuBarTheme.of(context).style;
        defaultStyle = _MenuBarDefaultsM3(context);
        break;
      case Axis.vertical:
        themeStyle = MenuTheme.of(context).style;
        defaultStyle = _MenuDefaultsM3(context);
        break;
    }
    final MenuStyle? widgetStyle = widget.menuStyle;

    T? effectiveValue<T>(T? Function(MenuStyle? style) getProperty) {
      return getProperty(widgetStyle) ?? getProperty(themeStyle) ?? getProperty(defaultStyle);
    }

    T? resolve<T>(MaterialStateProperty<T>? Function(MenuStyle? style) getProperty) {
      return effectiveValue(
        (MenuStyle? style) {
          return getProperty(style)?.resolve(<MaterialState>{});
        },
      );
    }

    final Color? backgroundColor = resolve<Color?>((MenuStyle? style) => style?.backgroundColor);
    final Color? shadowColor = resolve<Color?>((MenuStyle? style) => style?.shadowColor);
    final Color? surfaceTintColor = resolve<Color?>((MenuStyle? style) => style?.surfaceTintColor);
    final double elevation = resolve<double?>((MenuStyle? style) => style?.elevation) ?? 0;
    final EdgeInsetsGeometry padding =
        resolve<EdgeInsetsGeometry?>((MenuStyle? style) => style?.padding) ?? EdgeInsets.zero;
    final Size? minimumSize = resolve<Size?>((MenuStyle? style) => style?.minimumSize);
    final Size? fixedSize = resolve<Size?>((MenuStyle? style) => style?.fixedSize);
    final Size? maximumSize = resolve<Size?>((MenuStyle? style) => style?.maximumSize);
    final BorderSide? side = resolve<BorderSide?>((MenuStyle? style) => style?.side);
    final OutlinedBorder shape = resolve<OutlinedBorder?>((MenuStyle? style) => style?.shape)!.copyWith(side: side);
    final VisualDensity visualDensity =
        effectiveValue((MenuStyle? style) => style?.visualDensity) ?? VisualDensity.standard;
    final Offset densityAdjustment = visualDensity.baseSizeAdjustment;

    BoxConstraints effectiveConstraints = visualDensity.effectiveConstraints(
      BoxConstraints(
        minWidth: minimumSize?.width ?? 0,
        minHeight: minimumSize?.height ?? 0,
        maxWidth: maximumSize?.width ?? double.infinity,
        maxHeight: maximumSize?.height ?? double.infinity,
      ),
    );
    if (fixedSize != null) {
      final Size size = effectiveConstraints.constrain(fixedSize);
      if (size.width.isFinite) {
        effectiveConstraints = effectiveConstraints.copyWith(
          minWidth: size.width,
          maxWidth: size.width,
        );
      }
      if (size.height.isFinite) {
        effectiveConstraints = effectiveConstraints.copyWith(
          minHeight: size.height,
          maxHeight: size.height,
        );
      }
    }

    // Per the Material Design team: don't allow the VisualDensity
    // adjustment to reduce the width of the left/right padding. If we
    // did, VisualDensity.compact, the default for desktop/web, would
    // reduce the horizontal padding to zero.
    final double dy = densityAdjustment.dy;
    final double dx = math.max(0, densityAdjustment.dx);
    final EdgeInsetsGeometry resolvedPadding = padding
        .add(EdgeInsets.fromLTRB(dx, dy, dx, dy))
        .clamp(EdgeInsets.zero, EdgeInsetsGeometry.infinity); // ignore_clamp_double_lint
    return ConstrainedBox(
      constraints: effectiveConstraints,
      child: UnconstrainedBox(
        constrainedAxis: widget.orientation,
        clipBehavior: Clip.hardEdge,
        alignment: AlignmentDirectional.centerStart,
        child: _intrinsicCrossSize(
          child: Material(
            elevation: elevation,
            shape: shape,
            color: backgroundColor,
            shadowColor: shadowColor,
            surfaceTintColor: surfaceTintColor,
            type: backgroundColor == null ? MaterialType.transparency : MaterialType.canvas,
            clipBehavior: widget.clipBehavior,
            child: Padding(
              padding: resolvedPadding,
              child: SingleChildScrollView(
                scrollDirection: widget.orientation,
                child: Flex(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  textDirection: Directionality.of(context),
                  direction: widget.orientation,
                  mainAxisSize: MainAxisSize.min,
                  children: widget.children,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A label widget that is used as the default label for a [MenuItemButton] or
/// [MenuButton].
///
/// It not only shows the [MenuButton.child] or [MenuItemButton.child], but if
/// there is a shortcut associated with the [MenuItemButton], it will display a
/// mnemonic for the shortcut. For [MenuButton]s, it will display a visual
/// indicator that there is a submenu.
class _MenuItemLabel extends StatelessWidget {
  /// Creates a const [_MenuItemLabel].
  ///
  /// The [child] and [hasSubmenu] arguments are required.
  const _MenuItemLabel({
    required this.child,
    required this.hasSubmenu,
    this.leadingIcon,
    this.trailingIcon,
    this.shortcut,
    this.showDecoration = true,
  });

  /// The required label widget.
  final Widget child;

  /// Whether or not this menu has a submenu.
  ///
  /// Determines whether the submenu arrow is shown or not.
  final bool hasSubmenu;

  /// The optional icon that comes before the [child].
  final Widget? leadingIcon;

  /// The optional icon that comes after the [child].
  final Widget? trailingIcon;

  /// The shortcut for this label, so that it can generate a string describing
  /// the shortcut.
  final MenuSerializableShortcut? shortcut;

  /// Whether or not this item should show decorations like shortcut labels or
  /// submenu arrows.
  final bool showDecoration;

  @override
  Widget build(BuildContext context) {
    final VisualDensity density = Theme.of(context).visualDensity;
    final double horizontalPadding = math.max(
      _kLabelItemMinSpacing,
      _kLabelItemDefaultSpacing + density.horizontal * 2,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (leadingIcon != null) leadingIcon!,
            Padding(
              padding: leadingIcon != null ? EdgeInsetsDirectional.only(start: horizontalPadding) : EdgeInsets.zero,
              child: child,
            ),
            if (trailingIcon != null)
              Padding(
                padding: EdgeInsetsDirectional.only(start: horizontalPadding),
                child: trailingIcon,
              ),
          ],
        ),
        if (showDecoration && (shortcut != null || hasSubmenu)) SizedBox(width: horizontalPadding),
        if (showDecoration && shortcut != null)
          Padding(
            padding: EdgeInsetsDirectional.only(start: horizontalPadding),
            child: Text(
              _LocalizedShortcutLabeler.instance.getShortcutLabel(
                shortcut!,
                MaterialLocalizations.of(context),
              ),
            ),
          ),
        if (showDecoration && hasSubmenu)
          Padding(
            padding: EdgeInsetsDirectional.only(start: horizontalPadding),
            child: const Icon(
              Icons.arrow_right, // Automatically switches with text direction.
              size: _kDefaultSubmenuIconSize,
            ),
          ),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<String>('child', child.toString()));
    properties.add(DiagnosticsProperty<MenuSerializableShortcut>('shortcut', shortcut, defaultValue: null));
  }
}

// Positions the menu in the view while trying to keep as much as possible
// visible in the view.
class _MenuLayout extends SingleChildLayoutDelegate {
  const _MenuLayout({
    required this.buttonRect,
    required this.textDirection,
    required this.buttonPadding,
    required this.alignment,
    required this.alignmentOffset,
    required this.avoidBounds,
    required this.globalMenuPosition,
    required this.orientation,
    required this.parentOrientation,
  });

  // Rectangle of underlying button, relative to the overlay's dimensions.
  final RelativeRect? buttonRect;

  // Whether to prefer going to the left or to the right.
  final TextDirection textDirection;

  // The padding around the button opening the menu. This is used to determine
  // how far away from the edge of the screen to place the menu, since otherwise
  // the first menu in a menu bar will be closer to the edge of the screen than
  // allowed, and will get moved over.
  final EdgeInsetsGeometry buttonPadding;

  // The alignment to use when finding the ideal location for the menu.
  final AlignmentGeometry alignment;

  // The offset from the alignment position or the globalMenuPosition to find
  // the ideal location for the menu.
  final Offset alignmentOffset;

  // List of rectangles that we should avoid overlapping. Unusable screen area.
  final Set<Rect> avoidBounds;

  final Offset? globalMenuPosition;
  final Axis orientation;
  final Axis parentOrientation;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    // The menu can be at most the size of the overlay minus _kMenuViewPadding
    // pixels in each direction.
    return BoxConstraints.loose(constraints.biggest).deflate(
      const EdgeInsets.all(_kMenuViewPadding),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    // size: The size of the overlay.
    // childSize: The size of the menu, when fully open, as determined by
    // getConstraintsForChild.
    final Rect overlayRect = Offset.zero & size;
    final Rect absoluteButtonRect = globalMenuPosition != null
        ? Rect.fromCenter(center: globalMenuPosition!, width: 0, height: 0)
        : (buttonRect?.toRect(overlayRect) ?? Rect.zero);
    final Alignment alignment = this.alignment.resolve(textDirection);
    final Offset desiredPosition = alignment.withinRect(absoluteButtonRect);
    final Offset originCenter = absoluteButtonRect.center;
    final Iterable<Rect> subScreens = DisplayFeatureSubScreen.subScreensInBounds(overlayRect, avoidBounds);
    final Rect screen = _closestScreen(subScreens, originCenter);
    final EdgeInsets resolvedButtonPadding = buttonPadding.resolve(textDirection);

    double x = desiredPosition.dx;
    double y = desiredPosition.dy + alignmentOffset.dy;
    switch (textDirection) {
      case TextDirection.rtl:
        x -= childSize.width + alignmentOffset.dx;
        break;
      case TextDirection.ltr:
        x += alignmentOffset.dx;
        break;
    }

    final Rect allowedRect = Rect.fromLTRB(
      screen.left + resolvedButtonPadding.left,
      screen.top + resolvedButtonPadding.top,
      screen.right - resolvedButtonPadding.right,
      screen.bottom - resolvedButtonPadding.bottom,
    );
    bool offLeftSide(double x) => x < allowedRect.left;
    bool offRightSide(double x) => x + childSize.width > allowedRect.right;
    bool offTop(double y) => y < allowedRect.top;
    bool offBottom(double y) => y + childSize.height > allowedRect.bottom;
    // Avoid going outside an area defined as the rectangle offset from the
    // edge of the screen by the button padding. If the menu is off of the screen,
    // move the menu to the other side of the button first, and then if it
    // doesn't fit there, then just move it over as much as needed to make it
    // fit.
    if (childSize.width >= allowedRect.width) {
      // It just doesn't fit, so put as much on the screen as possible.
      x = allowedRect.left;
    } else {
      if (offLeftSide(x)) {
        // If the parent is a different orientation than the current one, then
        // just push it over instead of trying the other side.
        if (parentOrientation != orientation) {
          x = allowedRect.left;
        } else {
          final double newX = absoluteButtonRect.right;
          if (!offRightSide(newX)) {
            x = newX;
          } else {
            x = allowedRect.left;
          }
        }
      } else if (offRightSide(x)) {
        if (parentOrientation != orientation) {
          x = allowedRect.right - childSize.width;
        } else {
          final double newX = absoluteButtonRect.left - childSize.width;
          if (!offLeftSide(newX)) {
            x = newX;
          } else {
            x = allowedRect.right - childSize.width;
          }
        }
      }
    }
    if (childSize.height >= allowedRect.height) {
      // Too tall to fit, fit as much on as possible.
      y = allowedRect.top;
    } else {
      if (offTop(y)) {
        final double newY = absoluteButtonRect.bottom;
        if (!offBottom(newY)) {
          y = newY;
        } else {
          y = allowedRect.top;
        }
      } else if (offBottom(y)) {
        final double newY = absoluteButtonRect.top - childSize.height;
        if (!offTop(newY)) {
          y = newY;
        } else {
          y = allowedRect.bottom - childSize.height;
        }
      }
    }
    return Offset(x, y);
  }

  Rect _closestScreen(Iterable<Rect> screens, Offset point) {
    Rect closest = screens.first;
    for (final Rect screen in screens) {
      if ((screen.center - point).distance < (closest.center - point).distance) {
        closest = screen;
      }
    }
    return closest;
  }

  @override
  bool shouldRelayout(_MenuLayout oldDelegate) {
    return buttonRect != oldDelegate.buttonRect ||
        textDirection != oldDelegate.textDirection ||
        buttonPadding != oldDelegate.buttonPadding ||
        alignment != oldDelegate.alignment ||
        alignmentOffset != oldDelegate.alignmentOffset ||
        globalMenuPosition != oldDelegate.globalMenuPosition ||
        orientation != oldDelegate.orientation ||
        parentOrientation != oldDelegate.parentOrientation ||
        !setEquals(avoidBounds, oldDelegate.avoidBounds);
  }
}

// Base class for all menu nodes that make up the menu tree, to allow walking of
// the tree for navigation.
abstract class _MenuHandleBase with DiagnosticableTreeMixin, ChangeNotifier {
  _MenuHandleBase? get _parent;
  bool get isOpen;
  bool get _isRoot => _parent == null;
  bool get _isTopLevel => _parent?._isRoot ?? false;
  Axis get _orientation;

  @protected
  final List<_MenuHandleBase> _children = <_MenuHandleBase>[];

  void _notifyListenersSafely() {
    assert(ChangeNotifier.debugAssertNotDisposed(this));
    notifyListeners();
  }

  @protected
  void _addChild(_MenuHandleBase child) {
    assert(ChangeNotifier.debugAssertNotDisposed(this));
    assert(_isRoot || _debugMenuInfo('Added root child: $child'));
    assert(!_children.contains(child));
    _children.add(child);
    assert(_debugMenuInfo('Tree:\n${toStringDeep()}'));
  }

  @protected
  void _removeChild(_MenuHandleBase child) {
    assert(ChangeNotifier.debugAssertNotDisposed(this));
    assert(_isRoot || _debugMenuInfo('Removed root child: $child'));
    assert(_children.contains(child));
    _children.remove(child);
    assert(_debugMenuInfo('Tree:\n${toStringDeep()}'));
  }

  @protected
  void _closeChildren({bool inDispose = false}) {
    assert(ChangeNotifier.debugAssertNotDisposed(this));
    assert(_debugMenuInfo('Closing children of ${this}${inDispose ? ' (dispose)' : ''}'));
    for (final MenuHandle child in List<MenuHandle>.from(_children)) {
      child.close(inDispose: inDispose);
    }
  }

  MenuController get _root {
    assert(ChangeNotifier.debugAssertNotDisposed(this));
    _MenuHandleBase handle = this;
    while (handle._parent != null) {
      handle = handle._parent!;
    }
    return handle as MenuController;
  }

  @protected
  _MenuHandleBase get _topLevel {
    assert(ChangeNotifier.debugAssertNotDisposed(this));
    _MenuHandleBase handle = this;
    while (handle._parent!._isTopLevel) {
      handle = handle._parent!;
    }
    return handle;
  }

  @protected
  bool get _descendantIsOpen {
    assert(ChangeNotifier.debugAssertNotDisposed(this));
    for (final _MenuHandleBase child in _children) {
      if (child._descendantIsOpen) {
        return true;
      }
    }
    return isOpen;
  }

  @protected
  _MenuHandleBase? get _previousSibling {
    assert(ChangeNotifier.debugAssertNotDisposed(this));
    final int index = _parent!._children.indexOf(this);
    assert(index != -1, 'Unable to find this widget $this in parent $_parent');
    if (index > 0) {
      return _parent!._children[index - 1];
    }
    return null;
  }

  @protected
  _MenuHandleBase? get _nextSibling {
    assert(ChangeNotifier.debugAssertNotDisposed(this));
    final int index = _parent!._children.indexOf(this);
    assert(index != -1, 'Unable to find this widget $this in parent $_parent');
    if (index < _parent!._children.length - 1) {
      return _parent!._children[index + 1];
    }
    return null;
  }

  // Returns the active menu node in the given context, if any, and creates a
  // dependency relationship that will rebuild the context when the node
  // changes.
  static _MenuHandleBase? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_MenuHandleMarker>()?.handle;
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return <DiagnosticsNode>[
      ...super.debugDescribeChildren(),
      ..._children.map<DiagnosticsNode>((_MenuHandleBase child) => child.toDiagnosticsNode()),
    ];
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('isRoot', value: _isRoot, ifTrue: 'ROOT', defaultValue: false));
    properties.add(DiagnosticsProperty<_MenuHandleBase?>('parent', _isRoot ? null : _parent, defaultValue: null));
  }
}

/// A controller that allows control of a [MenuBar] from other places in the
/// widget hierarchy.
///
/// Typically, it's not necessary to create a `MenuController` to use a
/// [MenuBar] or to call [createMaterialMenu], but if open menus need to be
/// closed with the [closeAll] method in response to an event, a
/// `MenuController` can be created and passed to the [MenuBar] or
/// [createMaterialMenu].
///
/// The controller can be listened to for some changes in the state of the menu
/// bar, to see if [menuIsOpen] has changed, for instance.
///
/// {@macro flutter.material.menu_bar.createMaterialMenu.tap_region_note}
///
/// The [dispose] method must be called on the controller when it is no longer
/// needed.
class MenuController extends _MenuHandleBase {
  /// Creates a [MenuController] that can be used with a [MenuBar] or
  /// [createMaterialMenu].
  MenuController() : _menuScopeNode = FocusScopeNode() {
    assert(() {
      _menuScopeNode.debugLabel = 'Menu Root Scope';
      return true;
    }());
  }
  // This holds the previously focused widget when a top level menu is opened,
  // so that when the last menu is dismissed, the focus can be restored.
  FocusNode? _previousFocus;

  /// Returns true if any menu served by this controller is currently open.
  bool get menuIsOpen => _descendantIsOpen;

  final FocusScopeNode _menuScopeNode;

  @override
  Axis get _orientation => Axis.horizontal;

  @override
  MenuController? get _parent => null;

  /// The root menu is always "closed".
  @override
  bool get isOpen => false;

  @override
  MenuController get _root => this;

  /// The [dispose] method must be called on the controller when it is no longer
  /// needed.
  ///
  /// Do not use the object after dispose has been called.
  @override
  void dispose() {
    _previousFocus = null;
    super.dispose();
  }

  /// Close any open menus controlled by this [MenuController].
  void closeAll() {
    assert(ChangeNotifier.debugAssertNotDisposed(this));
    if (menuIsOpen) {
      assert(_debugMenuInfo('Controller closing all open menus'));
      _closeChildren();
    }
  }

  /// Returns the active controller in the given context, and creates a
  /// dependency relationship that will rebuild the context when the controller
  /// is swapped for a different one.
  ///
  /// The controller itself can be listened to for state changes (it is a
  /// [ChangeNotifier]).
  ///
  /// See also:
  ///
  /// * [maybeOf], which returns the active controller in the given context, if
  ///   any, and null otherwise.
  static MenuController of(BuildContext context) {
    final MenuController? found = maybeOf(context);
    if (found == null) {
      throw FlutterError('A ${context.widget.runtimeType} requested a '
          'MenuController, but was not a descendant of a MenuBar: $context');
    }
    return found;
  }

  /// Returns the active controller in the given context, if any, and creates a
  /// dependency relationship that will rebuild the context when the controller
  /// is swapped for a different one.
  ///
  /// The controller itself can be listened to for state changes (it is a
  /// [ChangeNotifier]).
  ///
  /// See also:
  ///
  /// * [of], which returns the active controller in the given context, and
  ///   throws if one is not found.
  static MenuController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_MenuHandleMarker>()?.handle._root;
  }

  // Called by MenuHandle.open to notify the controller when a menu item has
  // been opened.
  void _menuOpened(MenuHandle open, {required bool wasOpen}) {
    assert(ChangeNotifier.debugAssertNotDisposed(this));
    if (!wasOpen && !menuIsOpen) {
      // We're opening the first menu, so cache the primary focus so that we can
      // try to return to it when the menu is dismissed. Skips any focus nodes
      // that are part of a menu system, since we don't want to return to those
      // when the menu closes, or it will never close.
      if (FocusManager.instance.primaryFocus?.context != null &&
          MenuController.maybeOf(FocusManager.instance.primaryFocus!.context!) == null) {
        assert(_debugMenuInfo('Storing previous focus as $primaryFocus'));
        _previousFocus = FocusManager.instance.primaryFocus;
      } else {
        _previousFocus = null;
      }
    }
    _notifyListenersSafely();
    assert(_debugMenuInfo('Menu opened: $open'));
  }

  // Called by the _MenuNode.close to notify the controller when a menu item has
  // been closed.
  void _menuClosed(_MenuHandleBase close, {bool inDispose = false}) {
    assert(ChangeNotifier.debugAssertNotDisposed(this));
    if (!menuIsOpen && _previousFocus != null) {
      // This needs to happen in the next frame so that in cases where we're
      // closing everything, and the _previousFocus is a focus scope that
      // currently thinks its first focus is in the menu bar, the menu bar will
      // be unfocusable by the time the scope tries to refocus it because no
      // menus will be open, and it will have a more appropriate first focus.
      SchedulerBinding.instance.addPostFrameCallback((Duration _) {
        assert(_debugMenuInfo('Returning focus to $_previousFocus'));
        _previousFocus?.requestFocus();
        _previousFocus = null;
      });
    }
    _notifyListenersSafely();
    assert(_debugMenuInfo('Menu closed $close'));
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<FocusNode>('previousFocus', _previousFocus));
  }
}

/// A handle to a menu created by [createMaterialMenu].
///
/// A `MenuHandle` can only be created by calling [createMaterialMenu].
///
/// `MenuHandle` is used to control and interrogate a menu after it has been
/// created, with methods such as [open] and [close], and state like [isOpen].
///
/// The [dispose] method must be called when the menu handle is no longer
/// needed. The object shouldn't be used after [dispose] is called.
///
/// See also:
///
/// * [createMaterialMenu], the function that creates a menu given a focus node
///   for the controlling widget and the desired menus, and returns a
///   `MenuHandle`.
/// * [MenuBar], a widget that manages its own `MenuHandle` internally.
/// * [MenuButton], a widget that has a button that manages a submenu.
/// * [MenuItemButton], a widget that draws a menu button with optional shortcut
///   labels.
class MenuHandle extends _MenuHandleBase {
  /// Private constructor because menu entries can only be created by
  /// [createMaterialMenu].
  MenuHandle._({
    _MenuHandleBase? parent,
    required List<Widget> menuChildren,
    FocusNode? buttonFocusNode,
    VoidCallback? onOpen,
    VoidCallback? onClose,
    Offset alignmentOffset = Offset.zero,
    Offset? globalMenuPosition,
    ButtonStyle? buttonStyle,
    MenuStyle? menuStyle,
    Clip menuClipBehavior = Clip.none,
    bool ownsParent = false,
  })  : _parent = parent,
        _menuChildren = menuChildren,
        _buttonFocusNode = buttonFocusNode,
        _onOpen = onOpen,
        _onClose = onClose,
        _alignmentOffset = alignmentOffset,
        _globalMenuPosition = globalMenuPosition,
        _buttonStyle = buttonStyle,
        _menuStyle = menuStyle,
        _menuClipBehavior = menuClipBehavior,
        _ownsParent = ownsParent,
        _menuScopeNode = FocusScopeNode() {
    assert(() {
      _menuScopeNode.debugLabel = 'Menu Scope';
      return true;
    }());
    _parent?._addChild(this);
  }

  @override
  final _MenuHandleBase? _parent;

  @override
  bool get isOpen => _overlayEntry != null;

  @override
  Axis get _orientation => Axis.vertical;

  final List<Widget> _menuChildren;
  final FocusScopeNode _menuScopeNode;
  final MenuStyle? _menuStyle;
  final ButtonStyle? _buttonStyle;
  final VoidCallback? _onOpen;
  final VoidCallback? _onClose;
  final FocusNode? _buttonFocusNode;
  final Clip _menuClipBehavior;
  final Offset _alignmentOffset;
  final bool _ownsParent;
  Rect? _buttonRect;
  Offset? _globalMenuPosition;

  @protected
  OverlayEntry? _overlayEntry;

  FocusNode? get _firstItemFocusNode {
    assert(ChangeNotifier.debugAssertNotDisposed(this));
    if (_menuScopeNode.context == null) {
      return null;
    }
    final FocusTraversalPolicy policy =
        FocusTraversalGroup.maybeOf(_menuScopeNode.context!) ?? ReadingOrderTraversalPolicy();
    return policy.findFirstFocus(_menuScopeNode, ignoreCurrentFocus: true);
  }

  /// Open the menu, optionally at a global position.
  ///
  /// Call this when the menu should be shown to the user.
  ///
  /// The optional `position` argument will update the global coordinate where
  /// the menu should be opened, taking into account the [_alignmentOffset].
  ///
  /// If `position` is not given, and no `globalMenuPosition` was given to
  /// [createMaterialMenu], the menu appears at the location that is
  /// [_alignmentOffset] away from the alignment origin specified by
  /// [MenuStyle.alignment] for the menu.
  ///
  /// If `position` is not given and a `globalMenuPosition` was given to
  /// [createMaterialMenu], then it will appear at that position.
  void open(BuildContext context, {Offset? position}) {
    assert(ChangeNotifier.debugAssertNotDisposed(this));
    if (isOpen && position == _globalMenuPosition) {
      assert(_debugMenuInfo("Not opening $this because it's already open"));
      return;
    }
    assert(_debugMenuInfo(
        'Opening ${this}${_globalMenuPosition != null ? ' at ${position ?? _globalMenuPosition}' : ''}'));
    final bool somethingWasOpen = _root._descendantIsOpen;
    _parent?._closeChildren(); // Close all siblings.
    assert(_overlayEntry == null);

    _globalMenuPosition = position ?? _globalMenuPosition;
    final _MenuAnchorMarker? anchor = _MenuAnchorMarker.maybeOf(context);
    assert(
        anchor != null || _globalMenuPosition != null,
        'Unable to determine menu position.\n'
        'Menus either need to have a globalMenuPosition set, or there needs to '
        'be a MenuAnchor widget ancestor in the given context: $context');
    // The globalMenuPosition should take precedence over the anchor.
    if (anchor != null && _globalMenuPosition == null) {
      final RenderBox renderBox = anchor.anchorKey.currentContext!.findRenderObject()! as RenderBox;
      _buttonRect = Rect.fromPoints(
        renderBox.localToGlobal(Offset.zero),
        renderBox.localToGlobal(renderBox.size.bottomRight(Offset.zero)),
      );
    } else {
      _buttonRect = null;
    }

    final BuildContext outerContext = context;
    _overlayEntry = OverlayEntry(
      builder: (BuildContext context) {
        final OverlayState overlay = Overlay.of(outerContext);
        final Widget child = Directionality(
          textDirection: Directionality.of(outerContext),
          child: _MenuHandleMarker(
            handle: this,
            child: InheritedTheme.captureAll(
              // Copy all the themes from the supplied outer context to the
              // overlay.
              outerContext,
              TapRegion(
                groupId: _root,
                child: const _Submenu(),
              ),
              to: overlay.context,
            ),
          ),
        );
        if (anchor != null && _globalMenuPosition == null) {
          // Copy any information from the anchor (which might not be in the
          // overlay) into a new marker in the overlay.
          return _MenuAnchorMarker(
            anchorKey: anchor.anchorKey,
            link: anchor.link,
            child: child,
          );
        }
        return child;
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
    _root._menuOpened(this, wasOpen: somethingWasOpen);
    _onOpen?.call();
    _notifyListenersSafely();
  }

  /// Close the menu.
  ///
  /// Call this when the menu should be closed. Has no effect if the menu is
  /// already closed.
  void close({bool inDispose = false}) {
    assert(ChangeNotifier.debugAssertNotDisposed(this));
    if (!isOpen) {
      assert(_debugMenuInfo("Not closing $this because it's already closed"));
      return;
    }
    assert(_debugMenuInfo('Closing $this'));
    _closeChildren();
    _overlayEntry?.remove();
    _overlayEntry = null;
    _globalMenuPosition = null;
    _root._menuClosed(this, inDispose: inDispose);
    _onClose?.call();
    _notifyListenersSafely();
  }

  /// Dispose of the menu.
  ///
  /// Must be called when the menu is no longer needed, typically when the
  /// controlling widget is disposed.
  @override
  void dispose() {
    assert(ChangeNotifier.debugAssertNotDisposed(this));
    assert(_debugMenuInfo('Disposing of $this'));
    if (!isOpen) {
      _children.clear();
      return;
    }
    _closeChildren(inDispose: true);
    _overlayEntry?.remove();
    _overlayEntry = null;
    _parent?._removeChild(this);
    _children.clear();
    if (_ownsParent) {
      _parent?.dispose();
    }
    super.dispose();
  }

  void _focusButton() {
    assert(ChangeNotifier.debugAssertNotDisposed(this));
    assert(_debugMenuInfo('Requesting focus for $_buttonFocusNode'));
    _buttonFocusNode?.requestFocus();
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return <DiagnosticsNode>[
      ...super.debugDescribeChildren(),
      ..._children.map<DiagnosticsNode>((_MenuHandleBase child) => child.toDiagnosticsNode()),
    ];
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('isRoot', value: _isRoot, ifTrue: 'ROOT', defaultValue: false));
    properties.add(DiagnosticsProperty<_MenuHandleBase?>('parent', _parent, defaultValue: null));
    properties.add(FlagProperty('isOpen', value: isOpen, ifTrue: 'OPEN', defaultValue: false));
    properties.add(DiagnosticsProperty<FocusNode>('buttonFocusNode', _buttonFocusNode));
    properties.add(DiagnosticsProperty<FocusScopeNode>('menuScopeNode', _menuScopeNode));
    properties.add(DiagnosticsProperty<Offset>('globalMenuPosition', _globalMenuPosition));
    properties.add(DiagnosticsProperty<Offset>('alignmentOffset', _alignmentOffset));
  }
}

/// A helper class used to generate shortcut labels for a [ShortcutActivator].
///
/// This helper class is typically used by the [MenuItemButton] class to display
/// a label for its assigned shortcut.
///
/// Call [getShortcutLabel] with the [ShortcutActivator] to get a label for it.
///
/// For instance, calling [getShortcutLabel] with `SingleActivator(trigger:
/// LogicalKeyboardKey.keyA, control: true)` would return "⌃ A" on macOS, "Ctrl
/// A" in an US English locale, and "Strg A" in a German locale.
class _LocalizedShortcutLabeler {
  _LocalizedShortcutLabeler._();

  /// Return the instance for this singleton.
  static _LocalizedShortcutLabeler get instance {
    return _instance ??= _LocalizedShortcutLabeler._();
  }

  static _LocalizedShortcutLabeler? _instance;

  // Caches the created shortcut key maps so that creating one of these isn't
  // expensive after the first time for each unique localizations object.
  final Map<MaterialLocalizations, Map<LogicalKeyboardKey, String>> _cachedShortcutKeys =
      <MaterialLocalizations, Map<LogicalKeyboardKey, String>>{};

  static final Map<LogicalKeyboardKey, String> _shortcutGraphicEquivalents = <LogicalKeyboardKey, String>{
    LogicalKeyboardKey.arrowLeft: '←',
    LogicalKeyboardKey.arrowRight: '→',
    LogicalKeyboardKey.arrowUp: '↑',
    LogicalKeyboardKey.arrowDown: '↓',
    LogicalKeyboardKey.enter: '↵',
    LogicalKeyboardKey.shift: '⇧',
    LogicalKeyboardKey.shiftLeft: '⇧',
    LogicalKeyboardKey.shiftRight: '⇧',
  };

  static final Set<LogicalKeyboardKey> _modifiers = <LogicalKeyboardKey>{
    LogicalKeyboardKey.alt,
    LogicalKeyboardKey.control,
    LogicalKeyboardKey.meta,
    LogicalKeyboardKey.shift,
    LogicalKeyboardKey.altLeft,
    LogicalKeyboardKey.controlLeft,
    LogicalKeyboardKey.metaLeft,
    LogicalKeyboardKey.shiftLeft,
    LogicalKeyboardKey.altRight,
    LogicalKeyboardKey.controlRight,
    LogicalKeyboardKey.metaRight,
    LogicalKeyboardKey.shiftRight,
  };

  // Tries to look up the key in an internal table, and if it can't find it,
  // then fall back to the key's keyLabel.
  String? _getLocalizedName(LogicalKeyboardKey key, MaterialLocalizations localizations) {
    // Since this is an expensive table to build, we cache it based on the
    // localization object. There's currently no way to clear the cache, but
    // it's unlikely that more than one or two will be cached for each run, and
    // they're not huge.
    _cachedShortcutKeys[localizations] ??= <LogicalKeyboardKey, String>{
      LogicalKeyboardKey.altGraph: localizations.keyboardKeyAltGraph,
      LogicalKeyboardKey.backspace: localizations.keyboardKeyBackspace,
      LogicalKeyboardKey.capsLock: localizations.keyboardKeyCapsLock,
      LogicalKeyboardKey.channelDown: localizations.keyboardKeyChannelDown,
      LogicalKeyboardKey.channelUp: localizations.keyboardKeyChannelUp,
      LogicalKeyboardKey.delete: localizations.keyboardKeyDelete,
      LogicalKeyboardKey.eject: localizations.keyboardKeyEject,
      LogicalKeyboardKey.end: localizations.keyboardKeyEnd,
      LogicalKeyboardKey.escape: localizations.keyboardKeyEscape,
      LogicalKeyboardKey.fn: localizations.keyboardKeyFn,
      LogicalKeyboardKey.home: localizations.keyboardKeyHome,
      LogicalKeyboardKey.insert: localizations.keyboardKeyInsert,
      LogicalKeyboardKey.numLock: localizations.keyboardKeyNumLock,
      LogicalKeyboardKey.numpad1: localizations.keyboardKeyNumpad1,
      LogicalKeyboardKey.numpad2: localizations.keyboardKeyNumpad2,
      LogicalKeyboardKey.numpad3: localizations.keyboardKeyNumpad3,
      LogicalKeyboardKey.numpad4: localizations.keyboardKeyNumpad4,
      LogicalKeyboardKey.numpad5: localizations.keyboardKeyNumpad5,
      LogicalKeyboardKey.numpad6: localizations.keyboardKeyNumpad6,
      LogicalKeyboardKey.numpad7: localizations.keyboardKeyNumpad7,
      LogicalKeyboardKey.numpad8: localizations.keyboardKeyNumpad8,
      LogicalKeyboardKey.numpad9: localizations.keyboardKeyNumpad9,
      LogicalKeyboardKey.numpad0: localizations.keyboardKeyNumpad0,
      LogicalKeyboardKey.numpadAdd: localizations.keyboardKeyNumpadAdd,
      LogicalKeyboardKey.numpadComma: localizations.keyboardKeyNumpadComma,
      LogicalKeyboardKey.numpadDecimal: localizations.keyboardKeyNumpadDecimal,
      LogicalKeyboardKey.numpadDivide: localizations.keyboardKeyNumpadDivide,
      LogicalKeyboardKey.numpadEnter: localizations.keyboardKeyNumpadEnter,
      LogicalKeyboardKey.numpadEqual: localizations.keyboardKeyNumpadEqual,
      LogicalKeyboardKey.numpadMultiply: localizations.keyboardKeyNumpadMultiply,
      LogicalKeyboardKey.numpadParenLeft: localizations.keyboardKeyNumpadParenLeft,
      LogicalKeyboardKey.numpadParenRight: localizations.keyboardKeyNumpadParenRight,
      LogicalKeyboardKey.numpadSubtract: localizations.keyboardKeyNumpadSubtract,
      LogicalKeyboardKey.pageDown: localizations.keyboardKeyPageDown,
      LogicalKeyboardKey.pageUp: localizations.keyboardKeyPageUp,
      LogicalKeyboardKey.power: localizations.keyboardKeyPower,
      LogicalKeyboardKey.powerOff: localizations.keyboardKeyPowerOff,
      LogicalKeyboardKey.printScreen: localizations.keyboardKeyPrintScreen,
      LogicalKeyboardKey.scrollLock: localizations.keyboardKeyScrollLock,
      LogicalKeyboardKey.select: localizations.keyboardKeySelect,
      LogicalKeyboardKey.space: localizations.keyboardKeySpace,
    };
    return _cachedShortcutKeys[localizations]![key];
  }

  String _getModifierLabel(LogicalKeyboardKey modifier, MaterialLocalizations localizations) {
    assert(_modifiers.contains(modifier), '${modifier.keyLabel} is not a modifier key');
    if (modifier == LogicalKeyboardKey.meta ||
        modifier == LogicalKeyboardKey.metaLeft ||
        modifier == LogicalKeyboardKey.metaRight) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
          return localizations.keyboardKeyMeta;
        case TargetPlatform.windows:
          return localizations.keyboardKeyMetaWindows;
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          return '⌘';
      }
    }
    if (modifier == LogicalKeyboardKey.alt ||
        modifier == LogicalKeyboardKey.altLeft ||
        modifier == LogicalKeyboardKey.altRight) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          return localizations.keyboardKeyAlt;
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          return '⌥';
      }
    }
    if (modifier == LogicalKeyboardKey.control ||
        modifier == LogicalKeyboardKey.controlLeft ||
        modifier == LogicalKeyboardKey.controlRight) {
      // '⎈' (a boat helm wheel, not an asterisk) is apparently the standard
      // icon for "control", but only seems to appear on the French Canadian
      // keyboard. A '✲' (an open center asterisk) appears on some Microsoft
      // keyboards. For all but macOS (which has standardized on "⌃", it seems),
      // we just return the local translation of "Ctrl".
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          return localizations.keyboardKeyControl;
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          return '⌃';
      }
    }
    if (modifier == LogicalKeyboardKey.shift ||
        modifier == LogicalKeyboardKey.shiftLeft ||
        modifier == LogicalKeyboardKey.shiftRight) {
      return _shortcutGraphicEquivalents[LogicalKeyboardKey.shift]!;
    }
    throw ArgumentError('Keyboard key ${modifier.keyLabel} is not a modifier.');
  }

  /// Returns the label to be shown to the user in the UI when a
  /// [ShortcutActivator] is used as a keyboard shortcut.
  ///
  /// To keep the representation short, this will return graphical key
  /// representations when it can. For instance, the default
  /// [LogicalKeyboardKey.shift] will return '⇧', and the arrow keys will return
  /// arrows.
  ///
  /// When [defaultTargetPlatform] is [TargetPlatform.macOS] or
  /// [TargetPlatform.iOS], the key [LogicalKeyboardKey.meta] will show as '⌘',
  /// [LogicalKeyboardKey.control] will show as '˄', and
  /// [LogicalKeyboardKey.alt] will show as '⌥'.
  String getShortcutLabel(MenuSerializableShortcut shortcut, MaterialLocalizations localizations) {
    final ShortcutSerialization serialized = shortcut.serializeForMenu();
    if (serialized.trigger != null) {
      final List<String> modifiers = <String>[];
      final LogicalKeyboardKey trigger = serialized.trigger!;
      // These should be in this order, to match the LogicalKeySet version.
      if (serialized.alt!) {
        modifiers.add(_getModifierLabel(LogicalKeyboardKey.alt, localizations));
      }
      if (serialized.control!) {
        modifiers.add(_getModifierLabel(LogicalKeyboardKey.control, localizations));
      }
      if (serialized.meta!) {
        modifiers.add(_getModifierLabel(LogicalKeyboardKey.meta, localizations));
      }
      if (serialized.shift!) {
        modifiers.add(_getModifierLabel(LogicalKeyboardKey.shift, localizations));
      }
      String? shortcutTrigger;
      final int logicalKeyId = trigger.keyId;
      if (_shortcutGraphicEquivalents.containsKey(trigger)) {
        shortcutTrigger = _shortcutGraphicEquivalents[trigger];
      } else {
        // Otherwise, look it up, and if we don't have a translation for it,
        // then fall back to the key label.
        shortcutTrigger = _getLocalizedName(trigger, localizations);
        if (shortcutTrigger == null && logicalKeyId & LogicalKeyboardKey.planeMask == 0x0) {
          // If the trigger is a Unicode-character-producing key, then use the character.
          shortcutTrigger = String.fromCharCode(logicalKeyId & LogicalKeyboardKey.valueMask).toUpperCase();
        }
        // Fall back to the key label if all else fails.
        shortcutTrigger ??= trigger.keyLabel;
      }
      return <String>[
        ...modifiers,
        if (shortcutTrigger != null && shortcutTrigger.isNotEmpty) shortcutTrigger,
      ].join(' ');
    } else if (serialized.character != null) {
      return serialized.character!;
    }
    throw UnimplementedError('Shortcut labels for ShortcutActivators that do not implement '
        'MenuSerializableShortcut (e.g. ShortcutActivators other than SingleActivator or '
        'CharacterActivator) are not supported.');
  }
}

class _MenuDismissAction extends DismissAction {
  _MenuDismissAction({required this.controller});

  final MenuController controller;

  @override
  bool isEnabled(DismissIntent intent) {
    return controller.menuIsOpen;
  }

  @override
  void invoke(DismissIntent intent) {
    assert(_debugMenuInfo('Dismiss action: Dismissing menus all open menus.'));
    controller.closeAll();
  }
}

class _MenuDirectionalFocusAction extends DirectionalFocusAction {
  /// Creates a [DirectionalFocusAction].
  _MenuDirectionalFocusAction({required this.controller});

  final MenuController controller;

  bool _moveToSubmenu(MenuHandle currentMenu) {
    assert(_debugMenuInfo('Opening submenu'));
    if (!currentMenu.isOpen) {
      // If no submenu is open, then an arrow opens the submenu.
      currentMenu.open(primaryFocus!.context!);
      return true;
    } else {
      final FocusNode? firstNode = currentMenu._firstItemFocusNode;
      if (firstNode != null && firstNode.nearestScope != firstNode) {
        // Don't request focus if the "first" found node is a focus scope, since that
        // means that nothing else in the submenu is focusable.
        firstNode.requestFocus();
      }
      return true;
    }
  }

  bool _moveToParent(MenuHandle currentMenu) {
    assert(_debugMenuInfo('Moving focus to parent menu button'));
    if (!(currentMenu._buttonFocusNode?.hasPrimaryFocus ?? true)) {
      currentMenu._focusButton();
    }
    return true;
  }

  bool _moveToPrevious(MenuHandle currentMenu) {
    assert(_debugMenuInfo('Moving focus to previous item in menu'));
    // Need to invalidate the scope data because we're switching scopes, and
    // otherwise the anti-hysteresis code will interfere with moving to the
    // correct node.
    if (currentMenu._buttonFocusNode != null) {
      final FocusTraversalPolicy? policy = FocusTraversalGroup.maybeOf(primaryFocus!.context!);
      policy?.invalidateScopeData(currentMenu._buttonFocusNode!.nearestScope!);
    }
    return false;
  }

  bool _moveToNext(MenuHandle currentMenu) {
    assert(_debugMenuInfo('Moving focus to next item in menu'));
    // Need to invalidate the scope data because we're switching scopes, and
    // otherwise the anti-hysteresis code will interfere with moving to the
    // correct node.
    if (currentMenu._buttonFocusNode != null) {
      final FocusTraversalPolicy? policy = FocusTraversalGroup.maybeOf(primaryFocus!.context!);
      policy?.invalidateScopeData(currentMenu._buttonFocusNode!.nearestScope!);
    }
    return false;
  }

  bool _moveToNextTopLevel(MenuHandle currentMenu) {
    final MenuHandle? sibling = currentMenu._topLevel._nextSibling as MenuHandle?;
    if (sibling == null) {
      // Wrap around to the first top level.
      (currentMenu._topLevel._parent!._children.first as MenuHandle)._focusButton();
    } else {
      sibling._focusButton();
    }
    return true;
  }

  bool _moveToPreviousTopLevel(MenuHandle currentMenu) {
    final MenuHandle? sibling = currentMenu._topLevel._previousSibling as MenuHandle?;
    if (sibling == null) {
      // Already on the first one, wrap around to the last one.
      (currentMenu._topLevel._parent!._children.last as MenuHandle)._focusButton();
    } else {
      sibling._focusButton();
    }
    return true;
  }

  @override
  void invoke(DirectionalFocusIntent intent) {
    assert(_debugMenuInfo('_MenuDirectionalFocusAction invoked with $intent'));
    final BuildContext? context = FocusManager.instance.primaryFocus?.context;
    if (context == null) {
      super.invoke(intent);
      return;
    }
    final _MenuHandleBase? menu =
        primaryFocus?.context == null ? null : _MenuHandleBase.maybeOf(primaryFocus!.context!);
    if (menu == null || !menu._root._descendantIsOpen || menu._isRoot || menu is! MenuHandle) {
      super.invoke(intent);
      return;
    }
    final bool buttonIsFocused = menu._buttonFocusNode?.hasPrimaryFocus ?? false;
    Axis orientation;
    if (buttonIsFocused) {
      orientation = menu._parent!._orientation;
    } else {
      orientation = menu._orientation;
    }
    final bool firstItemIsFocused = menu._firstItemFocusNode?.hasPrimaryFocus ?? false;
    assert(_debugMenuInfo('In _MenuDirectionalFocusAction, current node is ${menu._buttonFocusNode?.debugLabel}, '
        'button is${buttonIsFocused ? '' : ' not'} focused. Assuming ${orientation.name} orientation.'));

    switch (intent.direction) {
      case TraversalDirection.up:
        switch (orientation) {
          case Axis.horizontal:
            if (_moveToParent(menu)) {
              return;
            }
            break;
          case Axis.vertical:
            if (firstItemIsFocused) {
              if (_moveToParent(menu)) {
                return;
              }
            }
            if (_moveToPrevious(menu)) {
              return;
            }
            break;
        }
        break;
      case TraversalDirection.down:
        switch (orientation) {
          case Axis.horizontal:
            if (_moveToSubmenu(menu)) {
              return;
            }
            break;
          case Axis.vertical:
            if (_moveToNext(menu)) {
              return;
            }
            break;
        }
        break;
      case TraversalDirection.left:
        switch (orientation) {
          case Axis.horizontal:
            switch (Directionality.of(context)) {
              case TextDirection.rtl:
                if (_moveToNext(menu)) {
                  return;
                }
                break;
              case TextDirection.ltr:
                if (_moveToPrevious(menu)) {
                  return;
                }
                break;
            }
            break;
          case Axis.vertical:
            switch (Directionality.of(context)) {
              case TextDirection.rtl:
                if (buttonIsFocused) {
                  if (_moveToSubmenu(menu)) {
                    return;
                  }
                } else {
                  if (_moveToNextTopLevel(menu)) {
                    return;
                  }
                }
                break;
              case TextDirection.ltr:
                switch (menu._parent!._orientation) {
                  case Axis.horizontal:
                    if (_moveToPreviousTopLevel(menu)) {
                      return;
                    }
                    break;
                  case Axis.vertical:
                    if (buttonIsFocused) {
                      if (_moveToPreviousTopLevel(menu)) {
                        return;
                      }
                    } else {
                      if (_moveToParent(menu)) {
                        return;
                      }
                    }
                    break;
                }
                break;
            }
            break;
        }
        break;
      case TraversalDirection.right:
        switch (orientation) {
          case Axis.horizontal:
            switch (Directionality.of(context)) {
              case TextDirection.rtl:
                if (_moveToPrevious(menu)) {
                  return;
                }
                break;
              case TextDirection.ltr:
                if (_moveToNext(menu)) {
                  return;
                }
                break;
            }
            break;
          case Axis.vertical:
            switch (Directionality.of(context)) {
              case TextDirection.rtl:
                switch (menu._parent!._orientation) {
                  case Axis.horizontal:
                    if (_moveToPreviousTopLevel(menu)) {
                      return;
                    }
                    break;
                  case Axis.vertical:
                    if (_moveToParent(menu)) {
                      return;
                    }
                    break;
                }
                break;
              case TextDirection.ltr:
                if (buttonIsFocused) {
                  if (_moveToSubmenu(menu)) {
                    return;
                  }
                } else {
                  if (_moveToNextTopLevel(menu)) {
                    return;
                  }
                }
                break;
            }
            break;
        }
        break;
    }
    super.invoke(intent);
  }
}

// Wraps the MaterialStateMouseCursor so that it can default to
// MouseCursor.uncontrolled if none is set, and so it has a debug description.
class _MouseCursor extends MaterialStateMouseCursor {
  const _MouseCursor(this.resolveCallback);

  final MaterialPropertyResolver<MouseCursor?> resolveCallback;

  @override
  MouseCursor resolve(Set<MaterialState> states) => resolveCallback(states) ?? MouseCursor.uncontrolled;

  @override
  String get debugDescription => 'Menu_MouseCursor';
}

// A debug print function, which should only be called within an assert, like
// so:
//   assert(_debugMenuInfo('Debug Message'));
//
// so that the call is entirely removed in release builds.
//
// Enabled debug printing by setting _kDebugMenus to true at the top of the
// file.
bool _debugMenuInfo(String message, [Iterable<String>? details]) {
  assert(() {
    if (_kDebugMenus) {
      debugPrint('MENU: $message');
      if (details != null && details.isNotEmpty) {
        for (final String detail in details) {
          debugPrint('    $detail');
        }
      }
    }
    return true;
  }());
  // Return true so that it can be easily used inside of an assert.
  return true;
}

// This class will eventually be auto-generated, so it should remain at the end
// of the file.
class _MenuButtonDefaultsM3 extends ButtonStyle {
  _MenuButtonDefaultsM3(this.context)
      : super(
          animationDuration: kThemeChangeDuration,
          enableFeedback: true,
          alignment: AlignmentDirectional.centerStart,
        );

  final BuildContext context;
  late final ColorScheme _colors = Theme.of(context).colorScheme;

  @override
  MaterialStateProperty<TextStyle?> get textStyle =>
      MaterialStatePropertyAll<TextStyle?>(Theme.of(context).textTheme.labelLarge);

  @override
  MaterialStateProperty<Color?>? get backgroundColor => ButtonStyleButton.allOrNull<Color>(Colors.transparent);

  @override
  MaterialStateProperty<Color?>? get foregroundColor => MaterialStateProperty.resolveWith((Set<MaterialState> states) {
        if (states.contains(MaterialState.disabled)) {
          return _colors.onSurface.withOpacity(0.38);
        }
        return _colors.primary;
      });

  @override
  MaterialStateProperty<Color?>? get overlayColor => MaterialStateProperty.resolveWith((Set<MaterialState> states) {
        if (states.contains(MaterialState.hovered)) {
          return _colors.primary.withOpacity(0.08);
        }
        if (states.contains(MaterialState.focused)) {
          return _colors.primary.withOpacity(0.12);
        }
        if (states.contains(MaterialState.pressed)) {
          return _colors.primary.withOpacity(0.12);
        }
        return null;
      });

  // No default shadow color

  // No default surface tint color

  @override
  MaterialStateProperty<double>? get elevation => ButtonStyleButton.allOrNull<double>(0.0);

  @override
  MaterialStateProperty<EdgeInsetsGeometry>? get padding =>
      ButtonStyleButton.allOrNull<EdgeInsetsGeometry>(_scaledPadding(context));

  @override
  MaterialStateProperty<Size>? get minimumSize => ButtonStyleButton.allOrNull<Size>(const Size(64.0, 40.0));

  // No default fixedSize

  @override
  MaterialStateProperty<Size>? get maximumSize => ButtonStyleButton.allOrNull<Size>(Size.infinite);

  // No default side

  @override
  MaterialStateProperty<OutlinedBorder>? get shape =>
      ButtonStyleButton.allOrNull<OutlinedBorder>(const RoundedRectangleBorder());

  @override
  MaterialStateProperty<MouseCursor?>? get mouseCursor =>
      MaterialStateProperty.resolveWith((Set<MaterialState> states) {
        if (states.contains(MaterialState.disabled)) {
          return SystemMouseCursors.basic;
        }
        return SystemMouseCursors.click;
      });

  @override
  VisualDensity? get visualDensity => Theme.of(context).visualDensity;

  @override
  MaterialTapTargetSize? get tapTargetSize => Theme.of(context).materialTapTargetSize;

  @override
  InteractiveInkFeatureFactory? get splashFactory => Theme.of(context).splashFactory;

  EdgeInsetsGeometry _scaledPadding(BuildContext context) {
    return ButtonStyleButton.scaledPadding(
      const EdgeInsets.all(8),
      const EdgeInsets.symmetric(horizontal: 8),
      const EdgeInsets.symmetric(horizontal: 4),
      MediaQuery.maybeOf(context)?.textScaleFactor ?? 1,
    );
  }
}

// This class will eventually be auto-generated, so it should remain at the end
// of the file.
class _MenuDefaultsM3 extends MenuStyle {
  _MenuDefaultsM3(this.context)
      : super(
          elevation: const MaterialStatePropertyAll<double?>(4.0),
          shape: const MaterialStatePropertyAll<OutlinedBorder>(_defaultMenuBorder),
          alignment: AlignmentDirectional.topEnd,
        );

  static const RoundedRectangleBorder _defaultMenuBorder =
      RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.elliptical(2.0, 3.0)));

  final BuildContext context;
  late final ColorScheme _colors = Theme.of(context).colorScheme;

  @override
  MaterialStateProperty<EdgeInsetsGeometry?>? get padding {
    return MaterialStatePropertyAll<EdgeInsetsGeometry>(
      EdgeInsetsDirectional.symmetric(
        vertical: math.max(
          _kMenuVerticalMinPadding,
          2 + Theme.of(context).visualDensity.baseSizeAdjustment.dy,
        ),
      ),
    );
  }

  @override
  MaterialStateProperty<Color?> get backgroundColor {
    return MaterialStatePropertyAll<Color?>(_colors.surface);
  }
}

// This class will eventually be auto-generated, so it should remain at the end
// of the file.
class _MenuBarDefaultsM3 extends MenuStyle {
  _MenuBarDefaultsM3(this.context)
      : super(
          elevation: const MaterialStatePropertyAll<double?>(4.0),
          shape: const MaterialStatePropertyAll<OutlinedBorder>(_defaultMenuBorder),
          alignment: AlignmentDirectional.bottomStart,
        );

  static const RoundedRectangleBorder _defaultMenuBorder =
      RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.elliptical(2.0, 3.0)));

  final BuildContext context;
  late final ColorScheme _colors = Theme.of(context).colorScheme;

  @override
  MaterialStateProperty<EdgeInsetsGeometry?>? get padding {
    return MaterialStatePropertyAll<EdgeInsetsGeometry>(
      EdgeInsetsDirectional.symmetric(
        horizontal: math.max(
          _kTopLevelMenuHorizontalMinPadding,
          2 + Theme.of(context).visualDensity.baseSizeAdjustment.dx,
        ),
      ),
    );
  }

  @override
  MaterialStateProperty<Color?> get backgroundColor {
    return MaterialStatePropertyAll<Color?>(_colors.surface);
  }
}
