// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'button_style.dart';
import 'color_scheme.dart';
import 'divider.dart';
import 'icons.dart';
import 'material.dart';
import 'material_localizations.dart';
import 'material_state.dart';
import 'menu_bar_theme.dart';
import 'text_button.dart';
import 'text_button_theme.dart';
import 'theme.dart';
import 'theme_data.dart';

// The time after a menu item is opened via hover during which clicks on a child
// menu item with a submenu will be ignored by the menu item. This is so that
// users aren't surprised by hovering over a main menu to open it, and then
// quickly moving to a submenu and clicking on it to open it. Without this
// delay, it often just feels like the menu opened briefly and closed when
// clicked on, when in reality they opened it via the hover before they ever
// clicked on it.
const Duration _kMenuHoverClickBanDelay = Duration(milliseconds: 500);

// The default size of the arrow that indicates that a menu has a submenu.
const double _kDefaultSubmenuIconSize = 24.0;

// The default spacing between the the leading icon, label, trailing icon, and
// shortcut label in a _MenuBarItemLabel.
const double _kLabelItemDefaultSpacing = 18.0;

// The minimum spacing between the the leading icon, label, trailing icon, and
// shortcut label in a _MenuBarItemLabel.
const double _kLabelItemMinSpacing = 4.0;

// The minimum horizontal spacing on the outside of the top level menu.
const double _kTopLevelMenuHorizontalMinPadding = 4.0;

const Map<ShortcutActivator, Intent> _kMenuTraversalShortcuts = <ShortcutActivator, Intent>{
  SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
  SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
  SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
  SingleActivator(LogicalKeyboardKey.gameButtonA): ActivateIntent(),
  SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
  SingleActivator(LogicalKeyboardKey.tab): NextFocusIntent(),
  SingleActivator(LogicalKeyboardKey.tab, shift: true): PreviousFocusIntent(),
  SingleActivator(LogicalKeyboardKey.arrowDown): DirectionalFocusIntent(TraversalDirection.down),
  SingleActivator(LogicalKeyboardKey.arrowUp): DirectionalFocusIntent(TraversalDirection.up),
  SingleActivator(LogicalKeyboardKey.arrowLeft): DirectionalFocusIntent(TraversalDirection.left),
  SingleActivator(LogicalKeyboardKey.arrowRight): DirectionalFocusIntent(TraversalDirection.right),
};

/// A menu bar with cascading child menus.
///
/// This is a Material Design menu bar that resides above the main body of an
/// application that defines a menu system for invoking callbacks or firing
/// [Intent]s in response to user selection of the menu item.
///
/// The menu can be navigated by the user using the arrow keys, and can be
/// dismissed using the escape key, or by clicking away from the menu item
/// (anywhere that is not a part of the menu bar or cascading menus). Once a
/// menu is open, the menu hierarchy can be navigated by hovering over the menu
/// with the mouse.
///
/// Menu items can have a [SingleActivator] or [CharacterActivator] assigned to
/// them as their [MenuBarButton.shortcut], so that if the shortcut key sequence
/// is pressed, the menu item corresponding to that shortcut will be selected
/// even if the menu is closed. Shortcuts must be unique in the ambient
/// [ShortcutRegistry].
///
/// Selecting a menu item causes the [MenuBarButton.onSelected] callback to be
/// called.
///
/// When a menu item with a submenu is clicked on, it toggles the visibility of
/// the submenu. When the menu item is hovered over, the submenu will open after
/// a slight delay, and hovering over other items will close that menu and open
/// the newly hovered one. When those occur, [MenuBarMenu.onOpen], and
/// [MenuBarMenu.onClose] are called, respectively.
///
/// {@tool dartpad}
/// This example shows a [MenuBar] that contains a single top level menu,
/// containing three items for "About", a checkbox menu item for showing a
/// message, and "Quit". The items are identified with an enum value.
///
/// ** See code in examples/api/lib/material/menu_bar/menu_bar.0.dart **
/// {@end-tool}
///
/// {@tool sample}
/// This example shows a [MenuBar] that contains a simple menu for a desktop
/// application. It is set up to be adaptive, so that on macOS it will use the
/// system menu bar, and on other systems will use a Material [MenuBar].
///
/// On macOS, it will add the "About" and "Quit" system-provided menu items.
///
/// The menu items are all identified by an enum value (`MenuSelection`).
///
/// ** See code in examples/api/lib/material/menu_bar/menu_bar.1.dart **
/// {@end-tool}
///
/// See also:
///
///  * [MenuBarMenu], a menu item which manages a submenu.
///  * [MenuItemGroup], a menu item which collects its members into a group
///    separated from other menu items by a divider.
///  * [MenuBarButton], a leaf menu item which displays the label, an optional
///    shortcut label, and optional leading and trailing icons.
///  * [MenuBarController], a class that allows closing of menus from outside of
///    the menu bar.
///  * [PlatformMenuBar], which creates a menu bar that is rendered by the host
///    platform instead of by Flutter (on macOS, for example).
///  * [ShortcutRegistry], a registry of shortcuts that apply for the entire
///    application, used by the `MenuBar` to register its shortcuts.
class MenuBar extends StatelessWidget with DiagnosticableTreeMixin {
  /// Creates a const [MenuBar].
  const MenuBar({
    super.key,
    this.controller,
    this.enabled = true,
    this.backgroundColor,
    this.height,
    this.padding,
    this.elevation,
    this.menus = const <MenuBarItem>[],
  }) : _usePlatformMenu = false;

  // A private constructor for the MenuBar.adaptive factory constructor to use.
  const MenuBar._({
    super.key,
    this.controller,
    this.enabled = true,
    this.backgroundColor,
    this.height,
    this.padding,
    this.elevation,
    required bool isPlatformMenu,
    this.menus = const <MenuBarItem>[],
  }) : _usePlatformMenu = isPlatformMenu;

  /// Creates an adaptive [MenuBar] that renders using platform APIs with a
  /// [PlatformMenuBar] on platforms that support it, currently only macOS, and
  /// using Flutter rendering on platforms that don't (everywhere else).
  ///
  /// Some aspects of [MenuBar] are ignored when they are rendered by the
  /// platform, such as any visual attributes (geometry, colors). Platform menus
  /// also can't be closed with [MenuBarController.closeAll].
  ///
  /// See also:
  ///
  ///  * [PlatformMenuBar], which will configure platform provided menus on
  ///    macOS only.
  ///  * [PlatformMenuItem], which is the base class for [MenuBarButton], and
  ///    shows which parameters are supported on platform provided menus.
  factory MenuBar.adaptive({
    Key? key,
    MenuBarController? controller,
    bool enabled = true,
    MaterialStateProperty<Color?>? backgroundColor,
    double? height,
    EdgeInsets? padding,
    MaterialStateProperty<double?>? elevation,
    List<MenuBarItem> menus = const <MenuBarItem>[],
  }) {
    bool isPlatformMenu;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.iOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        isPlatformMenu = false;
        break;
      case TargetPlatform.macOS:
        isPlatformMenu = true;
        break;
    }

    return MenuBar._(
      key: key,
      controller: controller,
      enabled: enabled,
      backgroundColor: backgroundColor,
      height: height,
      padding: padding,
      elevation: elevation,
      isPlatformMenu: isPlatformMenu,
      menus: menus,
    );
  }

  /// The list of menu items that are the top level children of the
  /// [PlatformMenuBar].
  ///
  /// The `menus` member contains [MenuItem]s. They will not be part
  /// of the widget tree, since they are not widgets. They are provided to
  /// configure the properties of the menus on the platform menu bar.
  ///
  /// Also, a Widget in Flutter is immutable, so directly modifying the
  /// `menus` with `List` APIs such as
  /// `somePlatformMenuBarWidget.menus.add(...)` will result in incorrect
  /// behaviors. Whenever the menus list is modified, a new list object
  /// should be provided.
  final List<MenuBarItem> menus;

  /// An optional controller that allows outside control of the menu bar.
  ///
  /// Setting this controller will allow closing of any open menus from outside
  /// of the menu bar using [MenuBarController.closeAll].
  ///
  /// Descendants of the [MenuBar] can access its [MenuBarController] using
  /// [MenuBarController.of].
  ///
  /// {@template flutter.material.MenuBar.ignored_for_platform_provided_menus}
  /// This attribute is ignored if [MenuBar.adaptive] is used on a platform that
  /// supports platform provided menus (e.g. macOS).
  /// {@endtemplate}
  final MenuBarController? controller;

  /// Whether or not this menu bar is enabled.
  ///
  /// When disabled, all menus are closed, the menu bar buttons are disabled,
  /// and menu shortcuts are ignored.
  ///
  /// {@macro flutter.material.MenuBar.ignored_for_platform_provided_menus}
  final bool enabled;

  /// The background color of the menu bar.
  ///
  /// Defaults to [MenuBarThemeData.barBackgroundColor] if not set.
  ///
  /// {@macro flutter.material.MenuBar.ignored_for_platform_provided_menus}
  final MaterialStateProperty<Color?>? backgroundColor;

  /// The preferred minimum height of the menu bar.
  ///
  /// Defaults to the value of [MenuBarThemeData.barHeight] if not set.
  ///
  /// {@macro flutter.material.MenuBar.ignored_for_platform_provided_menus}
  final double? height;

  /// The padding around the contents of the menu bar itself.
  ///
  /// Defaults to the value of [MenuBarThemeData.barPadding] if not set.
  ///
  /// {@macro flutter.material.MenuBar.ignored_for_platform_provided_menus}
  final EdgeInsets? padding;

  /// The Material elevation of the menu bar (if any).
  ///
  /// Defaults to the [MenuBarThemeData.barElevation] value of the ambient
  /// [MenuBarTheme].
  ///
  /// {@macro flutter.material.MenuBar.ignored_for_platform_provided_menus}
  /// See also:
  ///
  ///  * [Material.elevation] for a description of what elevation implies.
  final MaterialStateProperty<double?>? elevation;

  /// Whether or not this should be rendered as a [PlatformMenuBar] or a
  /// Material [_MenuBar].
  ///
  /// If true, then a [PlatformMenuBar] will be substituted with the same
  /// [menus], [child], and [enabled] but none of the visual attributes will
  /// be passed along.
  final bool _usePlatformMenu;

  @override
  Widget build(BuildContext context) {
    if (_usePlatformMenu) {
      return PlatformMenuBar(menus: menus);
    }
    return _MenuBar(
      key: key,
      controller: controller,
      enabled: enabled,
      backgroundColor: backgroundColor,
      height: height,
      padding: padding,
      elevation: elevation,
      menus: menus,
    );
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return <DiagnosticsNode>[...menus.map<DiagnosticsNode>((MenuBarItem item) => item.toDiagnosticsNode())];
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('enabled', value: enabled, ifFalse: 'DISABLED'));
    properties.add(DiagnosticsProperty<MenuBarController>('controller', controller, defaultValue: null));
    properties.add(
        DiagnosticsProperty<MaterialStateProperty<Color?>>('backgroundColor', backgroundColor, defaultValue: null));
    properties.add(DoubleProperty('height', height, defaultValue: null));
    properties.add(DiagnosticsProperty<EdgeInsets?>('padding', padding, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<double?>>('elevation', elevation, defaultValue: null));
  }
}

class _MenuBar extends StatefulWidget with DiagnosticableTreeMixin {
  /// Creates a const [MenuBar].
  const _MenuBar({
    super.key,
    this.controller,
    this.enabled = true,
    this.backgroundColor,
    this.height,
    this.padding,
    this.elevation,
    this.menus = const <MenuBarItem>[],
  });

  /// The list of menu items that are the top level children of the
  /// [PlatformMenuBar].
  final List<MenuBarItem> menus;

  /// An optional controller that allows outside control of the menu bar.
  final MenuBarController? controller;

  /// Whether or not this menu bar is enabled.
  ///
  /// When disabled, all menus are closed, the menu bar buttons are disabled,
  /// and menu shortcuts are ignored.
  final bool enabled;

  /// The background color of the menu bar.
  ///
  /// Defaults to [MenuBarThemeData.barBackgroundColor] if not set.
  final MaterialStateProperty<Color?>? backgroundColor;

  /// The preferred minimum height of the menu bar.
  ///
  /// Defaults to the value of [MenuBarThemeData.barHeight] if not set.
  final double? height;

  /// The padding around the contents of the menu bar itself.
  ///
  /// Defaults to the value of [MenuBarThemeData.barPadding] if not set.
  final EdgeInsets? padding;

  /// The Material elevation of the menu bar (if any).
  ///
  /// Defaults to the [MenuBarThemeData.barElevation] value of the ambient
  /// [MenuBarTheme].
  final MaterialStateProperty<double?>? elevation;

  @override
  State<_MenuBar> createState() => _MenuBarState();

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return <DiagnosticsNode>[...menus.map<DiagnosticsNode>((MenuBarItem item) => item.toDiagnosticsNode())];
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('enabled', value: enabled, ifFalse: 'DISABLED'));
    properties.add(DiagnosticsProperty<MenuBarController>('controller', controller, defaultValue: null));
    properties.add(
        DiagnosticsProperty<MaterialStateProperty<Color?>>('backgroundColor', backgroundColor, defaultValue: null));
    properties.add(DoubleProperty('height', height, defaultValue: null));
    properties.add(DiagnosticsProperty<EdgeInsets?>('padding', padding, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<double?>>('elevation', elevation, defaultValue: null));
  }
}

class _MenuBarState extends State<_MenuBar> {
  // The shortcuts registered with the ShortcutRegistry when the menu bar is
  // enabled.
  late Map<MenuSerializableShortcut, Intent> _shortcuts;

  // The root of the menu node tree. The tree has the same lifetime as the menu
  // bar, whereas the individual menu widgets are only around when they are
  // displayed.
  final _MenuNode _root = _MenuNode.root();

  // The map of focus nodes to menus. This is used to look up which menu node
  // goes with which focus node when finding the currently focused menu node.
  final Map<FocusNode, _MenuNode> _focusNodes = <FocusNode, _MenuNode>{};

  // The render boxes of all the MenuBarMenus that are displaying menu items.
  // This is used to do hit testing to make sure that a pointer down has not hit
  // a menu, and so to close all the menus.
  final Set<RenderBox> _menuRenderBoxes = <RenderBox>{};

  // If set, this is the overlay entry that contains all of the submenus. It is
  // only non-null when there is a menu open.
  OverlayEntry? _overlayEntry;

  // This holds the previously focused widget when a top level menu is opened,
  // so that when the last menu is dismissed, the focus can be restored.
  FocusNode? _previousFocus;

  // The primary focus at the time of the last pointer down event. This needs to
  // be captured immediately before the FocusTrap unfocuses to the scope.
  FocusNode? _focusBeforeClick;

  // A menu that has been opened, but the menu widgets haven't been created yet.
  // Once they are, then request focus on it.
  _MenuNode? _pendingFocusedMenu;

  // Used to tell if we've already been disposed, for both debug checks, and to
  // avoid causing widget changes after being disposed.
  bool _disposed = false;

  bool get menuIsOpen => openMenu != null;
  bool get enabled => widget.enabled;

  final FocusScopeNode menuBarScope = FocusScopeNode(debugLabel: 'MenuBar');
  final FocusScopeNode overlayScope = FocusScopeNode(debugLabel: 'MenuBar overlay');

  // Returns the active menu bar state in the given context, and creates a
  // dependency relationship that will rebuild the context when the menu bar
  // changes.
  static _MenuBarState of(BuildContext context) {
    final _MenuBarState? found = context.dependOnInheritedWidgetOfExactType<_MenuBarMarker>()?.state;
    if (found == null) {
      throw FlutterError('A ${context.widget.runtimeType} requested a '
          'MenuBarController, but was not a descendant of a MenuBar: $context');
    }
    return found;
  }

  @override
  void initState() {
    super.initState();
    _shortcuts = _getShortcuts();
    widget.controller?._attach(this);
    _createMenuTree(widget.menus);
    GestureBinding.instance.pointerRouter.addGlobalRoute(_handlePointerEvent);
    widget.controller?._menuBarStateChanged();
  }

  @override
  void deactivate() {
    super.deactivate();
    widget.controller?._detach(this);
  }

  @override
  void activate() {
    super.activate();
    widget.controller?._attach(this);
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    menuBarScope.dispose();
    overlayScope.dispose();
    _root.children.clear();
    _focusNodes.clear();
    _previousFocus = null;
    _focusBeforeClick = null;
    _pendingFocusedMenu = null;
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_handlePointerEvent);
    super.dispose();
    _disposed = true;
  }

  @override
  void didUpdateWidget(_MenuBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _shortcuts = _getShortcuts();
    if (widget.controller != oldWidget.controller) {
      assert(widget.controller?._menuBar == this || widget.controller?._menuBar == null);
      oldWidget.controller?._menuBar = null;
      assert(widget.controller?._menuBar == null);
      widget.controller?._menuBar = this;
    }
    if (widget.menus != oldWidget.menus) {
      _createMenuTree(widget.menus);
    }
    if (!widget.enabled) {
      closeAll();
    }
    _markMenuDirtyAndDelayIfNecessary();
  }

  // These are only used in debug mode to make sure there aren't any duplicate
  // shortcut definitions.
  bool _debugCheckForDuplicateShortcuts() {
    final Map<MenuSerializableShortcut, VoidCallback> shortcutCallbacks = <MenuSerializableShortcut, VoidCallback>{};
    final Map<VoidCallback, MenuItem> callbackToMenuItem = <VoidCallback, MenuItem>{};
    final Map<Intent, MenuItem> intentToMenuItem = <Intent, MenuItem>{};

    Map<MenuSerializableShortcut, Intent> collectChildShortcuts(List<MenuBarItem> children) {
      final Map<MenuSerializableShortcut, Intent> shortcuts = <MenuSerializableShortcut, Intent>{};
      for (final MenuBarItem child in children) {
        if (child.onSelected != null) {
          callbackToMenuItem[child.onSelected!] = child;
        }
        if (child.onSelectedIntent != null) {
          intentToMenuItem[child.onSelectedIntent!] = child;
        }
        if (child.menus.isNotEmpty) {
          shortcuts.addAll(collectChildShortcuts(child.menus));
        } else if (child.shortcut != null && child.onSelected != null) {
          if (shortcuts.containsKey(child.shortcut) &&
              (shortcutCallbacks[child.shortcut!] != child.onSelected ||
                  shortcuts[child.shortcut] is! VoidCallbackIntent)) {
            throw FlutterError('Duplicate callback shortcut detected.\n'
                'The same shortcut has been bound to two different menus with '
                'different select functions or intents: ${child.shortcut} is bound to both '
                '${shortcuts[child.shortcut] is VoidCallbackIntent ? callbackToMenuItem[shortcutCallbacks[child.shortcut!]] : intentToMenuItem[shortcuts[child.shortcut!]]} and '
                ' menu $child with different select callbacks or intents.');
          }
          shortcutCallbacks[child.shortcut!] = child.onSelected!;
          shortcuts[child.shortcut!] = VoidCallbackIntent(child.onSelected!);
        } else if (child.shortcut != null && child.onSelectedIntent != null) {
          if (shortcuts.containsKey(child.shortcut) && shortcuts[child.shortcut!] != child.onSelectedIntent) {
            throw FlutterError('Duplicate intent shortcut mapping detected.\n'
                'The same shortcut has been bound to '
                'two different intents: ${child.shortcut} is bound to '
                '${shortcuts[child.shortcut!]} on '
                '${intentToMenuItem[shortcuts[child.shortcut!]]} and '
                '${child.onSelectedIntent} on menu $child.');
          }
          shortcuts[child.shortcut!] = child.onSelectedIntent!;
        } else if (child.members.isNotEmpty) {
          shortcuts.addAll(collectChildShortcuts(child.members));
        }
      }
      return shortcuts;
    }

    collectChildShortcuts(widget.menus);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasOverlay(context));
    final Set<MaterialState> state = <MaterialState>{if (!widget.enabled) MaterialState.disabled};
    final MenuBarThemeData menuBarTheme = MenuBarTheme.of(context);
    return _MenuBarMarker(
      state: this,
      child: Actions(
        actions: <Type, Action<Intent>>{
          NextFocusIntent: _MenuNextFocusAction(menuBar: this),
          PreviousFocusIntent: _MenuPreviousFocusAction(menuBar: this),
          DirectionalFocusIntent: _MenuDirectionalFocusAction(
            menuBar: this,
          ),
          DismissIntent: _MenuDismissAction(menuBar: this),
        },
        child: Builder(builder: (BuildContext context) {
          return _ShortcutRegistration(
            shortcuts: widget.enabled ? _shortcuts : const <MenuSerializableShortcut, Intent>{},
            child: ExcludeFocus(
              excluding: !widget.enabled || !menuIsOpen,
              child: FocusScope(
                node: menuBarScope,
                child: Shortcuts(
                  // Make sure that these override any shortcut bindings from
                  // the menu items when a menu is open. If someone wants to
                  // bind an arrow or tab to a menu item, it would otherwise
                  // override the default traversal keys. We want their
                  // shortcut to apply everywhere but in the menu itself,
                  // since there we have to be able to traverse menus.
                  shortcuts: _kMenuTraversalShortcuts,
                  child: _MenuBarTopLevelBar(
                    elevation: (widget.elevation ?? menuBarTheme.barElevation ?? _TokenDefaultsM3(context).barElevation)
                        .resolve(state)!,
                    height: widget.height ?? menuBarTheme.barHeight ?? _TokenDefaultsM3(context).barHeight,
                    enabled: widget.enabled,
                    color: (widget.backgroundColor ??
                            menuBarTheme.barBackgroundColor ??
                            _TokenDefaultsM3(context).barBackgroundColor)
                        .resolve(state)!,
                    padding: widget.padding ?? menuBarTheme.barPadding ?? _TokenDefaultsM3(context).barPadding,
                    children: widget.menus,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  void _doSelect(Intent onSelected) {
    if (widget.enabled) {
      Actions.maybeInvoke(FocusManager.instance.primaryFocus!.context!, onSelected);
    }
    closeAll();
  }

  Map<MenuSerializableShortcut, Intent> _getShortcuts() {
    assert(_debugCheckForDuplicateShortcuts());
    Map<MenuSerializableShortcut, Intent> collectChildShortcuts(List<MenuBarItem> children) {
      final Map<MenuSerializableShortcut, Intent> newShortcuts = <MenuSerializableShortcut, Intent>{};
      for (final MenuBarItem child in children) {
        if (child.menus.isNotEmpty) {
          // Short circuit if it's a menu item with a submenu.
          newShortcuts.addAll(collectChildShortcuts(child.menus));
        } else if (child.shortcut != null && child.onSelected != null) {
          // onSelected takes priority over onSelectedIntent (they can't specify
          // both anyhow).
          newShortcuts[child.shortcut!] = VoidCallbackIntent(child.onSelected!);
        } else if (child.shortcut != null && child.onSelectedIntent != null) {
          newShortcuts[child.shortcut!] = child.onSelectedIntent!;
        } else if (child.members.isNotEmpty) {
          // Groups can't have onSelected/onSelectedIntent or menus.
          newShortcuts.addAll(collectChildShortcuts(child.members));
        }
      }
      return newShortcuts;
    }

    final Map<MenuSerializableShortcut, Intent> collectedShortcuts = collectChildShortcuts(widget.menus);
    return collectedShortcuts.map<MenuSerializableShortcut, Intent>((MenuSerializableShortcut key, Intent value) {
      return MapEntry<MenuSerializableShortcut, Intent>(key, VoidCallbackIntent(() => _doSelect(value)));
    });
  }

  List<_MenuNode> get openMenus {
    if (openMenu == null) {
      return const <_MenuNode>[];
    }
    return <_MenuNode>[...openMenu!.ancestors, openMenu!];
  }

  _MenuNode? get openMenu => _openMenu;
  _MenuNode? _openMenu;
  set openMenu(_MenuNode? value) {
    assert(value != _root);
    if (_openMenu == value) {
      // Nothing changed.
      return;
    }
    if (value != null && _openMenu == null) {
      // We're opening the first menu, so cache the primary focus so that we can
      // try to return to it when the menu is dismissed.
      // If we captured a focus before the click, then use that, otherwise use
      // the current primary focus.
      _previousFocus = _focusBeforeClick ?? FocusManager.instance.primaryFocus;
    } else if (value == null && _openMenu != null) {
      // Closing all menus, so restore the previous focus.
      _previousFocus?.requestFocus();
      _previousFocus = null;
    }
    _focusBeforeClick = null;
    if (!mounted) {
      _openMenu = value;
      return;
    }
    final _MenuNode? oldMenu = _openMenu;
    setState(() {
      _openMenu = value;
    });
    oldMenu?.ancestorDifference(_openMenu).forEach((_MenuNode node) {
      node.close();
    });
    _openMenu?.ancestorDifference(oldMenu).forEach((_MenuNode node) {
      node.open();
    });
    if (value != null && value.focusNode?.hasPrimaryFocus != true) {
      // Request focus on the new thing that is now open, if any, so that
      // focus traversal starts from that location.
      if (value.focusNode == null || !value.focusNode!.canRequestFocus) {
        // If we don't have a focus node to ask yet, or it can't be focused yet,
        // then keep the menu until it gets registered, or something else sets
        // the menu.
        _pendingFocusedMenu = value;
      } else {
        _pendingFocusedMenu = null;
        value.focusNode!.requestFocus();
      }
    }
    _manageOverlayEntry();
    _markMenuDirtyAndDelayIfNecessary();
  }

  // Creates or removes the overlay entry that contains the stack of all menus.
  void _manageOverlayEntry() {
    if (openMenu != null) {
      if (_overlayEntry == null) {
        _overlayEntry = OverlayEntry(builder: (BuildContext context) => _MenuStack(this));
        Overlay.of(context)?.insert(_overlayEntry!);
      }
    } else {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }

  void _markMenuDirtyAndDelayIfNecessary() {
    if (_disposed || !mounted) {
      return;
    }
    void markMenuDirty() {
      _overlayEntry?.markNeedsBuild();
      widget.controller?._menuBarStateChanged();
    }

    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      // If we're in the middle of a build, we need to mark dirty in a post
      // frame callback, since this function will often be called by a part of
      // the tree that isn't in the overlay, but calling this would request that
      // the overlay be rebuilt.
      SchedulerBinding.instance.addPostFrameCallback((Duration _) => markMenuDirty());
    } else {
      // If we're not in the middle of a build, we can just call it right away.
      markMenuDirty();
    }
  }

  // Build the node hierarchy based upon the MenuItem hierarchy.
  void _createMenuTree(List<MenuBarItem> topLevel) {
    _root.children.clear();
    _focusNodes.clear();
    _previousFocus = null;
    _pendingFocusedMenu = null;
    for (final MenuBarItem item in topLevel) {
      _MenuNode(item: item, parent: _root).createChildren();
    }
    assert(_root.children.length == topLevel.length);
  }

  // Closes the given menu, and any open descendant menus.
  //
  // Leaves ancestor menus open, if any.
  //
  // Notifies listeners if the menu changed.
  void close(_MenuNode node) {
    if (openMenu == null) {
      // Everything is already closed.
      return;
    }
    if (isAnOpenMenu(node)) {
      // Don't call onClose, notifyListeners, etc, here, because setting
      // openMenu will call them if needed.
      if (node.parent == _root) {
        openMenu = null;
      } else {
        openMenu = node.parent;
      }
    }
  }

  void closeAll() {
    openMenu = null;
  }

  // Returns true if the given menu or one of its ancestors is open.
  bool isAnOpenMenu(_MenuNode menu) {
    if (_openMenu == null) {
      return false;
    }
    return _openMenu == menu || (_openMenu?.ancestors.contains(menu) ?? false);
  }

  // Handles any pointer events that occur in the app, checking them against
  // open menus to see if the menus should be closed or not.
  // This isn't called if no menus are open.
  void _handlePointerEvent(PointerEvent event) {
    if (event is! PointerDownEvent) {
      return;
    }
    bool isInsideMenu = false;
    final RenderBox? menuBarBox = context.findRenderObject() as RenderBox?;
    final List<RenderBox> renderBoxes = <RenderBox>[
      if (menuBarBox != null) menuBarBox,
      ..._menuRenderBoxes,
    ];
    for (final RenderBox renderBox in renderBoxes) {
      assert(renderBox.attached);
      isInsideMenu =
          renderBox.hitTest(BoxHitTestResult(), position: renderBox.globalToLocal(event.position)) || isInsideMenu;
      if (isInsideMenu) {
        break;
      }
    }
    if (!isInsideMenu) {
      closeAll();
    } else {
      _focusBeforeClick = FocusManager.instance.primaryFocus;
    }
  }

  // Registers the given menu in the _MenuBarState whenever a menu item
  // widget is created or updated.
  void registerMenu({
    required BuildContext menuContext,
    required _MenuNode node,
    WidgetBuilder? menuBuilder,
    FocusNode? buttonFocus,
  }) {
    if (node.focusNode != buttonFocus) {
      node.focusNode?.removeListener(_handleItemFocus);
      node.focusNode = buttonFocus;
      node.focusNode?.addListener(_handleItemFocus);
      if (buttonFocus != null) {
        _focusNodes[buttonFocus] = node;
      }
    }

    node.menuBuilder = menuBuilder;

    if (node == _pendingFocusedMenu) {
      node.focusNode?.requestFocus();
      _pendingFocusedMenu = null;
    }
  }

  // Unregisters the given context from the _MenuBarState.
  //
  // If the given context corresponds to the currently open menu, then close
  // it.
  void unregisterMenu(_MenuNode node) {
    node.focusNode?.removeListener(_handleItemFocus);
    node.focusNode = null;
    node.menuBuilder = null;
    _focusNodes.remove(node.focusNode);
    if (node == _pendingFocusedMenu) {
      _pendingFocusedMenu = null;
    }
    if (openMenu == node) {
      close(node);
    }
  }

  // Used to register the menu's render box whenever it changes, so that it can
  // be used to do hit detection and find out if a pointer event hit a menu or
  // not without participating in the gesture arena.
  void registerMenuRenderObject(RenderBox menu) {
    _menuRenderBoxes.add(menu);
  }

  // Used to unregister the menu's previous render box whenever it changes, or
  // remove it when it is disposed.
  void unregisterMenuRenderObject(RenderBox menu) {
    _menuRenderBoxes.remove(menu);
  }

  // Handles focus notifications for menu items so that the focused item can be
  // set as the currently open menu.
  void _handleItemFocus() {
    if (openMenu == null) {
      // Don't traverse the menu hierarchy on focus unless the user opened a
      // menu already.
      return;
    }
    final _MenuNode? focused = focusedItem;
    if (focused != null && !isAnOpenMenu(focused)) {
      openMenu = focused;
    }
  }

  _MenuNode? get focusedItem {
    final Iterable<FocusNode> focusedItems = _focusNodes.keys.where((FocusNode node) => node.hasFocus);
    assert(
        focusedItems.length <= 1,
        'The same focus node is registered to more than one MenuItem '
        'menu:\n  ${focusedItems.first}');
    return focusedItems.isNotEmpty ? _focusNodes[focusedItems.first] : null;
  }

  String? get debugCurrentItem {
    String? result;
    assert(() {
      if (openMenu != null) {
        result = openMenus.map<String>((_MenuNode node) => node.toStringShort()).join(' > ');
      }
      return true;
    }());
    return result;
  }

  String? get debugFocusedItem {
    String? result;
    assert(() {
      if (primaryFocus?.context != null) {
        result = _focusNodes[primaryFocus]?.toStringShort();
      }
      return true;
    }());
    return result;
  }
}

// The InheritedWidget marker for _MenuBarController, used to find the nearest
// ancestor _MenuBarController.
class _MenuBarMarker extends InheritedWidget {
  const _MenuBarMarker({
    required this.state,
    required super.child,
  });

  final _MenuBarState state;

  @override
  bool updateShouldNotify(covariant _MenuBarMarker oldWidget) {
    return state != oldWidget.state;
  }
}

/// A controller that allows control of a [MenuBar] from other places in the
/// widget hierarchy.
///
/// Typically, it's not necessary to create a `MenuBarController` to use a
/// [MenuBar], but if an open menu needs to be closed with the [closeAll] method
/// in response to an event, a `MenuBarController` can be created and passed to
/// the [MenuBar].
///
/// The controller can be listened to for changes in the state of the menu bar,
/// to see if [menuIsOpen] has changed, for instance.
class MenuBarController with ChangeNotifier {
  /// Closes any menus that are currently open.
  void closeAll() => _menuBar?.closeAll();

  /// Returns true if any menu in the menu bar is open.
  bool get menuIsOpen => _menuBar?.menuIsOpen ?? false;
  bool _menuIsOpen = false;

  /// A testing method used to provide access to a testing description of the
  /// currently open menu for tests.
  ///
  /// Only meant to be called by tests. Will return null in release mode.
  @visibleForTesting
  String? get debugCurrentItem => _menuBar?.debugCurrentItem;

  /// A testing method used to provide access to a testing description of the
  /// currently focused menu item for tests.
  ///
  /// Only meant to be called by tests. Will return null in release mode.
  @visibleForTesting
  String? get debugFocusedItem => _menuBar?.debugFocusedItem;

  // Called by _MenuBarState when its state changes.
  void _menuBarStateChanged() {
    if (_menuIsOpen != _menuBar?.menuIsOpen) {
      _menuIsOpen = _menuBar?.menuIsOpen ?? false;
      notifyListeners();
    }
  }

  void _attach(_MenuBarState menuBar) {
    assert(_menuBar == null);
    _menuBar = menuBar;
  }

  void _detach(_MenuBarState menuBar) {
    // Can't just assert this, since on reassemble, the order of reassembling
    // isn't guaranteed.
    if (_menuBar == menuBar) {
      _menuBar = null;
    }
  }

  // The menu bar this controller is attached to.
  _MenuBarState? _menuBar;
}

/// The base type for all menu items in a [MenuBar] widget.
///
/// Provides default implementations for [MenuItem] members, to serve as a mixin
/// class for the [MenuBarButton], [MenuItemGroup] and [MenuBarMenu] classes to make their
/// declarations simpler, and free of members that are irrelevant for each of
/// them.
mixin MenuBarItem implements PlatformMenuItem, Widget {
  /// A required label displayed on the entry for this item in the menu.
  ///
  /// This is rendered by default in a [Text] widget.
  /// The label appearance can be overridden by using a [labelWidget] to render
  /// a different widget in its place.
  ///
  /// This label is also used as the default [semanticsLabel].
  @override
  String get label;

  /// An optional widget that will be displayed in place of the default [Text]
  /// widget containing the [label].
  ///
  /// If both the `labelWidget` and [semanticsLabel] are provided, the
  /// [semanticsLabel] will take precedence for defining semantic information.
  Widget? get labelWidget => null;

  @override
  MenuSerializableShortcut? get shortcut => null;

  /// The function called when the mouse leaves or enters this menu item's
  /// button.
  ValueChanged<bool>? get onHover => null;

  @override
  List<MenuBarItem> get menus => const <MenuBarItem>[];

  @override
  List<MenuBarItem> get descendants => const <MenuBarItem>[];

  @override
  Intent? get onSelectedIntent => null;

  @override
  VoidCallback? get onSelected => null;

  @override
  VoidCallback? get onOpen => null;

  @override
  VoidCallback? get onClose => null;

  @override
  List<MenuBarItem> get members => const <MenuBarItem>[];

  @override
  String toStringShort() => '${describeIdentity(this)}($label)';
}

/// An item in a [MenuBar] that can be activated by click, keyboard navigation,
/// or via a shortcut.
///
/// This widget represents a leaf entry in a menu that is part of a [MenuBar].
/// It shows a label and a hint for an associated shortcut, if any. When
/// selected via click, hitting enter while focused, or activating the
/// associated [shortcut], it will call its [onSelected] callback or fire its
/// [onSelectedIntent] intent, depending on which is defined. If neither is
/// defined, then this item will be disabled.
///
/// See also:
///
///  * [MenuBarMenu], a class that represents a sub menu in a [MenuBar] that
///    contains [MenuItem]s.
///  * [MenuBar], a class that renders data in a [MenuBarButton] using
///    Flutter-rendered widgets in a Material Design style.
///  * [PlatformMenuBar], a class that renders similar menu bar items from a
///    [PlatformMenuItem] using platform-native APIs.
class MenuBarButton extends StatefulWidget with MenuBarItem {
  /// Creates a const [MenuBarButton].
  ///
  /// The [label] attribute is required.
  const MenuBarButton({
    super.key,
    required this.label,
    this.labelWidget,
    this.shortcut,
    this.onSelected,
    this.onSelectedIntent,
    this.onHover,
    this.focusNode,
    this.leadingIcon,
    this.trailingIcon,
    this.semanticsLabel,
    this.backgroundColor,
    this.foregroundColor,
    this.overlayColor,
    this.textStyle,
    this.padding,
    this.shape,
  })  : _hasMenu = false,
        _menuPadding = null,
        _menuBackgroundColor = null,
        _menuShape = null,
        _menuElevation = null,
        assert(onSelected == null || onSelectedIntent == null,
            'Only one of onSelected or onSelectedIntent may be specified');

  // Used for MenuBarMenu's button, which has some slightly different behavior.
  const MenuBarButton._forMenu({
    required this.label,
    this.labelWidget,
    this.onSelected,
    this.onHover,
    this.focusNode,
    this.leadingIcon,
    this.trailingIcon,
    this.semanticsLabel,
    this.backgroundColor,
    this.foregroundColor,
    this.overlayColor,
    this.textStyle,
    this.padding,
    EdgeInsets? menuPadding,
    MaterialStateProperty<Color?>? menuBackgroundColor,
    MaterialStateProperty<ShapeBorder?>? menuShape,
    MaterialStateProperty<double?>? menuElevation,
    this.shape,
  })  : _hasMenu = true,
        onSelectedIntent = null,
        shortcut = null,
        _menuPadding = menuPadding,
        _menuBackgroundColor = menuBackgroundColor,
        _menuShape = menuShape,
        _menuElevation = menuElevation;

  @override
  final String label;

  @override
  final Widget? labelWidget;

  @override
  final MenuSerializableShortcut? shortcut;

  @override
  final Intent? onSelectedIntent;

  @override
  final VoidCallback? onSelected;

  @override
  final ValueChanged<bool>? onHover;

  /// The focus node to use for the menu item button.
  final FocusNode? focusNode;

  /// An optional icon to display before the label text.
  final Widget? leadingIcon;

  /// An optional icon to display after the label text.
  final Widget? trailingIcon;

  /// The semantic label of the menu item used by accessibility frameworks to
  /// announce its label when the menu is focused.
  ///
  /// If this label is not provided, it will default to [label].
  ///
  /// If [labelWidget] is also provided, this semantics label will take
  /// precedence over semantics information provided in [labelWidget].
  final String? semanticsLabel;

  /// The background color for this [MenuBarButton].
  ///
  /// Defaults to the value of [MenuBarThemeData.itemBackgroundColor] if not set.
  final MaterialStateProperty<Color?>? backgroundColor;

  /// The foreground color for this [MenuBarButton].
  ///
  /// Defaults to the value of [MenuBarThemeData.itemForegroundColor] if not set.
  final MaterialStateProperty<Color?>? foregroundColor;

  /// The overlay color for this [MenuBarButton].
  ///
  /// Defaults to the value of [MenuBarThemeData.itemOverlayColor] if not set.
  final MaterialStateProperty<Color?>? overlayColor;

  /// The padding around the contents of the [MenuBarButton].
  ///
  /// Defaults to the value of [MenuBarThemeData.itemPadding] if not set.
  final EdgeInsets? padding;

  /// The text style for the text in this menu bar item.
  ///
  /// May be overridden inside of [labelWidget], if supplied.
  ///
  /// Defaults to the value of [MenuBarThemeData.itemTextStyle] if not set.
  final MaterialStateProperty<TextStyle?>? textStyle;

  /// The shape of this menu bar item.
  ///
  /// Defaults to the value of [MenuBarThemeData.itemShape] if not set.
  final MaterialStateProperty<OutlinedBorder?>? shape;

  // Indicates that this is a button for a submenu, not just a regular item.
  final bool _hasMenu;

  // The properties below here only apply to menu items that are hosts for a
  // submenu, when the menu item is created by calling MenuItem._forMenu.

  // The padding around the edges of a submenu. Passed in from the MenuBarMenu
  // so that it can be given during registration with the _MenuBarState.
  final EdgeInsets? _menuPadding;

  // The background color of the submenu, when _hasMenu is true.
  final MaterialStateProperty<Color?>? _menuBackgroundColor;

  // The shape of the submenu, when _hasMenu is true.
  final MaterialStateProperty<ShapeBorder?>? _menuShape;

  // The elevation of the submenu, when _hasMenu is true.
  final MaterialStateProperty<double?>? _menuElevation;

  @override
  State<MenuBarButton> createState() => _MenuBarButtonState();

  @override
  Iterable<Map<String, Object?>> toChannelRepresentation(PlatformMenuDelegate delegate,
      {required int Function(MenuItem) getId}) {
    return <Map<String, Object?>>[PlatformMenuItem.serialize(this, delegate, getId)];
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('enabled', value: onSelected != null || onSelectedIntent != null, ifFalse: 'DISABLED'));
    properties.add(DiagnosticsProperty<FocusNode>('focusNode', focusNode, defaultValue: null));
    properties.add(DiagnosticsProperty<Widget>('leadingIcon', leadingIcon, defaultValue: null));
    properties.add(StringProperty('label', label));
    properties.add(DiagnosticsProperty<Widget>('trailingIcon', trailingIcon, defaultValue: null));
    properties.add(StringProperty('semanticLabel', semanticsLabel, defaultValue: null));
    properties.add(DiagnosticsProperty<EdgeInsets?>('padding', padding, defaultValue: null));
    properties.add(
        DiagnosticsProperty<MaterialStateProperty<Color?>>('backgroundColor', backgroundColor, defaultValue: null));
    properties.add(
        DiagnosticsProperty<MaterialStateProperty<Color?>>('foregroundColor', foregroundColor, defaultValue: null));
    properties
        .add(DiagnosticsProperty<MaterialStateProperty<Color?>>('overlayColor', overlayColor, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<TextStyle?>>('textStyle', textStyle, defaultValue: null));
  }
}

class _MenuBarButtonState extends State<MenuBarButton> {
  _MenuNode? _menu;
  late _MenuBarState _menuBar;
  FocusNode get _focusNode => widget.focusNode ?? _internalFocusNode!;
  FocusNode? _internalFocusNode;

  bool get _enabled {
    return (widget.onSelected != null || widget.onSelectedIntent != null) && _menuBar.enabled;
  }

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _internalFocusNode = FocusNode(debugLabel: 'MenuBarItem');
      assert(() {
        _internalFocusNode!.debugLabel = 'MenuBarItem(${widget.label})';
        return true;
      }());
    }
  }

  @override
  void dispose() {
    _menuBar.unregisterMenu(_menu!);
    _internalFocusNode?.dispose();
    _internalFocusNode = null;
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    _updateMenuRegistration();
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(MenuBarButton oldWidget) {
    if (widget.focusNode != null) {
      _internalFocusNode?.dispose();
      _internalFocusNode = null;
    } else {
      _internalFocusNode ??= FocusNode();
      assert(() {
        _internalFocusNode!.debugLabel = 'MenuBarItem(${widget.label})';
        return true;
      }());
    }
    _updateMenuRegistration();
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final MenuBarThemeData menuBarTheme = MenuBarTheme.of(context);
    final _TokenDefaultsM3 defaultTheme = _TokenDefaultsM3(context);
    final Size densityAdjustedSize = const Size(64, 48) + Theme.of(context).visualDensity.baseSizeAdjustment;
    final MaterialStateProperty<EdgeInsets?> resolvedPadding;
    if (widget._hasMenu && _menu!.isTopLevel) {
      resolvedPadding =
          MaterialStateProperty.all<EdgeInsets?>(widget.padding ?? menuBarTheme.barPadding ?? defaultTheme.barPadding);
    } else {
      resolvedPadding = MaterialStateProperty.all<EdgeInsets?>(
          widget.padding ?? menuBarTheme.itemPadding ?? defaultTheme.itemPadding);
    }
    return Semantics(
      enabled: _enabled,
      // Will default to the label in the Text widget or labelWidget below if
      // not specified.
      label: widget.semanticsLabel,
      child: TextButton(
        style: (TextButtonTheme.of(context).style ?? const ButtonStyle()).copyWith(
          minimumSize: MaterialStateProperty.all<Size?>(densityAdjustedSize),
          backgroundColor:
              widget.backgroundColor ?? menuBarTheme.itemBackgroundColor ?? defaultTheme.itemBackgroundColor,
          foregroundColor:
              widget.foregroundColor ?? menuBarTheme.itemForegroundColor ?? defaultTheme.itemForegroundColor,
          overlayColor: widget.overlayColor ?? menuBarTheme.itemOverlayColor ?? defaultTheme.itemOverlayColor,
          padding: resolvedPadding,
          shape: widget.shape ?? menuBarTheme.itemShape ?? defaultTheme.itemShape,
          textStyle: widget.textStyle ?? menuBarTheme.itemTextStyle ?? defaultTheme.itemTextStyle,
        ),
        focusNode: _focusNode,
        onHover: _enabled ? _handleHover : null,
        onPressed: _enabled ? _handleSelect : null,
        child: _MenuBarItemLabel(
          leadingIcon: widget.leadingIcon,
          label: widget.labelWidget ?? Text(widget.label),
          shortcut: widget.shortcut,
          trailingIcon: widget.trailingIcon,
          hasSubmenu: widget._hasMenu,
        ),
      ),
    );
  }

  // Expands groups and adds dividers when necessary.
  List<Widget> _expandGroups(MenuItem parent) {
    final List<Widget> expanded = <Widget>[];
    bool lastWasGroup = false;
    for (final MenuItem item in parent.menus) {
      if (lastWasGroup) {
        expanded.add(const _MenuItemDivider());
      }
      if (item.members.isNotEmpty) {
        expanded.addAll(item.members.cast<Widget>());
        lastWasGroup = true;
      } else {
        expanded.add(item as Widget);
        lastWasGroup = false;
      }
    }
    return expanded;
  }

  // Wraps the given child with the appropriate Positioned widget for the
  // submenu.
  Widget _wrapWithPosition({
    required BuildContext menuButtonContext,
    required _MenuNode menuButtonNode,
    required Widget child,
  }) {
    final TextDirection textDirection = Directionality.of(menuButtonContext);
    final RenderBox button = menuButtonContext.findRenderObject()! as RenderBox;
    final RenderBox menuBarBox = _menuBar.context.findRenderObject()! as RenderBox;
    final RenderBox overlay = Overlay.of(menuButtonContext)!.context.findRenderObject()! as RenderBox;

    final EdgeInsets menuPadding =
        widget._menuPadding ?? MenuBarTheme.of(context).menuPadding ?? _TokenDefaultsM3(context).menuPadding;
    Offset menuOrigin;
    switch (textDirection) {
      case TextDirection.rtl:
        final Offset menuBarOrigin = menuBarBox.localToGlobal(menuBarBox.paintBounds.topRight, ancestor: overlay);
        if (menuButtonNode.isTopLevel) {
          menuOrigin = button.localToGlobal(button.paintBounds.bottomRight, ancestor: overlay);
          menuOrigin = Offset(menuBarOrigin.dx - menuOrigin.dx, menuOrigin.dy);
        } else {
          menuOrigin = button.localToGlobal(button.paintBounds.topLeft, ancestor: overlay);
          menuOrigin =
              Offset(menuBarOrigin.dx - menuOrigin.dx, menuOrigin.dy) + Offset(-menuPadding.right, -menuPadding.top);
        }
        break;
      case TextDirection.ltr:
        if (menuButtonNode.isTopLevel) {
          menuOrigin = button.localToGlobal(button.paintBounds.bottomLeft, ancestor: menuBarBox);
        } else {
          menuOrigin = button.localToGlobal(button.paintBounds.topRight, ancestor: overlay) +
              Offset(menuPadding.left, -menuPadding.top);
        }
        break;
    }
    return Positioned.directional(
      textDirection: textDirection,
      top: menuOrigin.dy,
      start: menuOrigin.dx,
      child: child,
    );
  }

  // A builder for a submenu that should be positioned relative to the menu
  // button whose context is given.
  Widget _buildPositionedMenu(_MenuNode menuButtonNode) {
    final _TokenDefaultsM3 defaultTheme = _TokenDefaultsM3(_menuBar.context);
    final MenuBarThemeData menuBarTheme = MenuBarTheme.of(_menuBar.context);
    final TextDirection textDirection = Directionality.of(_menuBar.context);
    final Set<MaterialState> disabled = <MaterialState>{
      if (!_enabled) MaterialState.disabled,
    };
    // Because this is all in the overlay, we have to duplicate a lot of state
    // that exists in the context of the menu button.
    return _wrapWithPosition(
      menuButtonContext: context,
      menuButtonNode: menuButtonNode,
      child: Directionality(
        textDirection: textDirection,
        child: InheritedTheme.captureAll(
          _menuBar.context,
          Builder(
            builder: (BuildContext context) {
              return _MenuNodeWrapper(
                menu: menuButtonNode,
                child: _MenuBarMarker(
                  state: _menuBar,
                  child: _MenuBarMenuList(
                    direction: Axis.vertical,
                    elevation: (widget._menuElevation ?? menuBarTheme.menuElevation ?? defaultTheme.menuElevation)
                        .resolve(disabled)!,
                    shape: (widget._menuShape ?? menuBarTheme.menuShape ?? defaultTheme.menuShape).resolve(disabled)!,
                    backgroundColor: (widget._menuBackgroundColor ??
                            menuBarTheme.menuBackgroundColor ??
                            defaultTheme.menuBackgroundColor)
                        .resolve(disabled)!,
                    menuPadding: widget._menuPadding ?? menuBarTheme.menuPadding ?? defaultTheme.menuPadding,
                    textDirection: Directionality.of(context),
                    children: _expandGroups(menuButtonNode.item),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _updateMenuRegistration() {
    final _MenuNode newMenu = _MenuNodeWrapper.of(context);
    final _MenuBarState newMenuBar = _MenuBarState.of(context);
    if (newMenu != _menu || newMenuBar != _menuBar) {
      _menuBar = newMenuBar;
      _menu = newMenu;
      newMenuBar.registerMenu(
        menuContext: context,
        node: newMenu,
        buttonFocus: _focusNode,
        menuBuilder: _menu!.hasSubmenu ? (BuildContext context) => _buildPositionedMenu(_menu!) : null,
      );
    }
  }

  void _handleSelect() {
    widget.onSelected?.call();

    if (!widget._hasMenu) {
      _menuBar.closeAll();
    }
  }

  void _handleHover(bool hovering) {
    widget.onHover?.call(hovering);

    if (!widget._hasMenu && hovering && !_menuBar.isAnOpenMenu(_menu!)) {
      setState(() {
        _menuBar.openMenu = _menu;
      });
    }
  }
}

/// A menu item widget that displays a hierarchical cascading menu as part of a
/// [MenuBar].
///
/// This widget represents an entry in [MenuBar.menus] that has a submenu. Like
/// the leaf [MenuBarButton], it shows a label with an optional leading or
/// trailing icon.
///
/// If this [MenuBarMenu] appears at the top level (as the immediate child menu
/// of a [MenuBar]), then the submenu will appear below the menu bar. Otherwise,
/// the submenu will appear to one side, with the side depending on the
/// [Directionality] of the widget tree (in RTL directionality, it will appear
/// on the right, in LTR it will appear on the left). If it is not a top level
/// menu, it will also include a small arrow indicating that there is a submenu.
///
/// When activated (clicked, through keyboard navigation, or via hovering with
/// a mouse), it will open a submenu containing the [menus].
///
/// See also:
///
///  * [MenuBarButton], a widget that represents a leaf [MenuBar] item.
///  * [MenuBar], a widget that renders data in a menu hierarchy using
///    Flutter-rendered widgets in a Material Design style.
///  * [PlatformMenuBar], a widget that renders similar menu bar items from a
///    [MenuBarItem] using platform-native APIs.
class MenuBarMenu extends StatefulWidget with MenuBarItem implements PlatformMenu {
  /// Creates a const [MenuBarMenu].
  ///
  /// The [label] attribute is required.
  const MenuBarMenu({
    super.key,
    required this.label,
    this.labelWidget,
    this.leadingIcon,
    this.trailingIcon,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
    this.backgroundColor,
    this.shape,
    this.elevation,
    this.padding,
    this.buttonPadding,
    this.buttonBackgroundColor,
    this.buttonForegroundColor,
    this.buttonOverlayColor,
    this.buttonShape,
    this.buttonTextStyle,
    this.onOpen,
    this.onClose,
    this.onHover,
    this.menus = const <MenuBarItem>[],
  });

  /// An optional icon to display before the label text.
  final Widget? leadingIcon;

  @override
  final String label;

  @override
  final Widget? labelWidget;

  /// An optional icon to display after the label text.
  final Widget? trailingIcon;

  /// The semantic label to use for this menu item for its [Semantics].
  final String? semanticLabel;

  /// The focus node to use for the menu item button.
  final FocusNode? focusNode;

  /// If true, will request focus when first built if nothing else has focus.
  final bool autofocus;

  /// The background color of the cascading menu specified by [menus].
  ///
  /// Defaults to the value of [MenuBarThemeData.menuBackgroundColor] value of the
  /// ambient [MenuBarTheme].
  final MaterialStateProperty<Color?>? backgroundColor;

  /// The shape of the cascading menu specified by [menus].
  ///
  /// Defaults to the value of [MenuBarThemeData.menuShape] value of the
  /// ambient [MenuBarTheme].
  final MaterialStateProperty<ShapeBorder?>? shape;

  /// The Material elevation of the submenu (if any).
  ///
  /// Defaults to the [MenuBarThemeData.barElevation] value of the ambient
  /// [MenuBarTheme].
  ///
  /// See also:
  ///
  ///  * [Material.elevation] for a description of what elevation is.
  final MaterialStateProperty<double?>? elevation;

  /// The padding around the outside of the contents of a [MenuBarMenu].
  ///
  /// Defaults to the [MenuBarThemeData.menuPadding] value of the ambient
  /// [MenuBarTheme].
  final EdgeInsets? padding;

  /// The padding around the outside of the button that opens a [MenuBarMenu]'s
  /// submenu.
  ///
  /// Defaults to the [MenuBarThemeData.itemPadding] value of the ambient
  /// [MenuBarTheme].
  final EdgeInsets? buttonPadding;

  /// The background color of the button that opens the submenu.
  ///
  /// Defaults to the value of [MenuBarThemeData.itemBackgroundColor] value of
  /// the ambient [MenuBarTheme].
  final MaterialStateProperty<Color?>? buttonBackgroundColor;

  /// The foreground color of the button that opens the submenu.
  ///
  /// Defaults to the value of [MenuBarThemeData.itemForegroundColor] value of
  /// the ambient [MenuBarTheme].
  final MaterialStateProperty<Color?>? buttonForegroundColor;

  /// The overlay color of the button that opens the submenu.
  ///
  /// Defaults to the value of [MenuBarThemeData.itemOverlayColor] value of
  /// the ambient [MenuBarTheme].
  final MaterialStateProperty<Color?>? buttonOverlayColor;

  /// The shape of the button that opens the submenu.
  ///
  /// Defaults to the value of [MenuBarThemeData.menuShape] value of the
  /// ambient [MenuBarTheme].
  final MaterialStateProperty<OutlinedBorder?>? buttonShape;

  /// The text style of the button that opens the submenu.
  ///
  /// The color in this text style will only be used if [buttonOverlayColor]
  /// is unset.
  final MaterialStateProperty<TextStyle?>? buttonTextStyle;

  /// Called when the button that opens the submenu is hovered over.
  @override
  final ValueChanged<bool>? onHover;

  @override
  final VoidCallback? onOpen;

  @override
  final VoidCallback? onClose;

  @override
  final List<MenuBarItem> menus;

  @override
  State<MenuBarMenu> createState() => _MenuBarMenuState();

  @override
  Iterable<Map<String, Object?>> toChannelRepresentation(PlatformMenuDelegate delegate,
      {required int Function(MenuItem) getId}) {
    return <Map<String, Object?>>[PlatformMenu.serialize(this, delegate, getId)];
  }

  @override
  List<MenuBarItem> get descendants => PlatformMenu.getDescendants(this).cast<MenuBarItem>();

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return <DiagnosticsNode>[
      ...menus.map<DiagnosticsNode>((MenuItem child) {
        return child.toDiagnosticsNode();
      })
    ];
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Widget>('leadingIcon', leadingIcon, defaultValue: null));
    properties.add(StringProperty('label', label));
    properties.add(DiagnosticsProperty<Widget>('trailingIcon', trailingIcon, defaultValue: null));
    properties.add(StringProperty('semanticLabel', semanticLabel, defaultValue: null));
    properties.add(
        DiagnosticsProperty<MaterialStateProperty<Color?>>('backgroundColor', backgroundColor, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<ShapeBorder?>>('shape', shape, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<double?>>('elevation', elevation, defaultValue: null));
    properties.add(DiagnosticsProperty<EdgeInsets?>('padding', padding, defaultValue: null));
    properties.add(DiagnosticsProperty<EdgeInsets?>('buttonPadding', buttonPadding, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<Color?>>('buttonBackgroundColor', buttonBackgroundColor,
        defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<Color?>>('buttonForegroundColor', buttonForegroundColor,
        defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<Color?>>('buttonOverlayColor', buttonOverlayColor,
        defaultValue: null));
    properties
        .add(DiagnosticsProperty<MaterialStateProperty<ShapeBorder?>>('buttonShape', buttonShape, defaultValue: null));
    properties.add(
        DiagnosticsProperty<MaterialStateProperty<TextStyle?>>('buttonTextStyle', buttonTextStyle, defaultValue: null));
  }
}

class _MenuBarMenuState extends State<MenuBarMenu> {
  _MenuNode? _menu;
  late _MenuBarState _menuBar;
  Timer? _clickBanTimer;
  bool _clickBan = false;
  FocusNode get _focusNode => widget.focusNode ?? _internalFocusNode!;
  FocusNode? _internalFocusNode;

  bool get _isAnOpenMenu {
    return _menu != null && _menuBar.isAnOpenMenu(_menu!);
  }

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _internalFocusNode = FocusNode(debugLabel: 'MenuBarItem');
      assert(() {
        _internalFocusNode!.debugLabel = 'MenuBarMenu(${widget.label})';
        return true;
      }());
    }
  }

  @override
  void dispose() {
    _internalFocusNode?.dispose();
    _internalFocusNode = null;
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    _menu = _MenuNodeWrapper.of(context);
    _menuBar = _MenuBarState.of(context);
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(MenuBarMenu oldWidget) {
    if (widget.focusNode != null) {
      _internalFocusNode?.dispose();
      _internalFocusNode = null;
    } else {
      _internalFocusNode ??= FocusNode();
      assert(() {
        _internalFocusNode!.debugLabel = 'MenuBarMenu(${widget.label})';
        return true;
      }());
    }
    super.didUpdateWidget(oldWidget);
  }

  bool get _enabled => _menuBar.enabled && widget.menus.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return MenuBarButton._forMenu(
      label: widget.label,
      labelWidget: widget.labelWidget,
      onSelected: _enabled ? _maybeToggleShowMenu : null,
      onHover: _enabled ? _handleMenuHover : null,
      focusNode: _focusNode,
      leadingIcon: widget.leadingIcon,
      trailingIcon: widget.trailingIcon,
      semanticsLabel: widget.semanticLabel,
      backgroundColor: widget.buttonBackgroundColor,
      foregroundColor: widget.buttonForegroundColor,
      overlayColor: widget.buttonOverlayColor,
      textStyle: widget.buttonTextStyle,
      padding: widget.buttonPadding,
      shape: widget.buttonShape,
      menuPadding: widget.padding,
      menuBackgroundColor: widget.backgroundColor,
      menuShape: widget.shape,
    );
  }

  // Shows the submenu if there is one, and it wasn't visible. Hides the menu if
  // it was already visible.
  void _maybeToggleShowMenu() {
    if (_clickBan) {
      // If we just opened the menu because the user is hovering, then ignore
      // clicks for a bit.
      return;
    }

    if (_isAnOpenMenu) {
      _menuBar.close(_menu!);
    } else {
      _menuBar.openMenu = _menu;
    }
  }

  // Called when the pointer is hovering over the menu button.
  void _handleMenuHover(bool hovering) {
    // Cancel any click ban in place if hover changes.
    _clickBanTimer?.cancel();
    _clickBanTimer = null;
    _clickBan = false;

    // Don't open the top level menu bar buttons on hover unless something else
    // is already open. This means that the user has to first open the menu bar
    // before hovering allows them to traverse it.
    if (_menu!.isTopLevel && _menuBar.openMenu == null) {
      return;
    }

    if (hovering && !_isAnOpenMenu) {
      _menuBar.openMenu = _menu;
      // If we just opened the menu because the user is hovering, then just
      // ignore any clicks for a bit. Otherwise, the user hovers to the
      // submenu, and sometimes clicks to open it just after the hover timer
      // has run out, causing the menu to open briefly, then immediately
      // close, which is surprising to the user.
      _clickBan = true;
      _clickBanTimer = Timer(_kMenuHoverClickBanDelay, () {
        _clickBan = false;
        _clickBanTimer = null;
      });
    }
  }
}

/// A widget that groups [MenuItem]s (e.g. [MenuBarButton]s and [MenuBarMenu]s)
/// into sections delineated by a [Divider].
///
/// It inserts dividers as necessary before and after the group, only inserting
/// them if there are other menu items before or after this group in the menu.
class MenuItemGroup extends StatelessWidget with MenuBarItem {
  /// Creates a const [MenuItemGroup].
  ///
  /// The [members] attribute is required.
  const MenuItemGroup({super.key, required this.members});

  /// The members of this [MenuItemGroup].
  ///
  /// It empty, then this group will not appear in the menu.
  @override
  final List<MenuBarItem> members;

  /// Converts this [MenuItemGroup] into a data structure accepted by the
  /// 'flutter/menu' method channel method 'Menu.SetMenu'.
  ///
  /// This is used by [PlatformMenuBar] when rendering this [MenuItemGroup]
  /// using platform APIs.
  @override
  Iterable<Map<String, Object?>> toChannelRepresentation(PlatformMenuDelegate delegate,
      {required int Function(MenuItem) getId}) {
    return PlatformMenuItemGroup.serialize(this, delegate, getId: getId);
  }

  @override
  Widget build(BuildContext context) {
    final _MenuNode menu = _MenuNodeWrapper.of(context);
    final bool hasDividerBefore = menu.parentIndex != 0 && !menu.previousSibling!.isGroup;
    final bool hasDividerAfter = menu.parentIndex != (menu.parent!.children.length - 1);
    if (menu.isTopLevel) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (hasDividerBefore) const _MenuItemDivider(axis: Axis.horizontal),
          ...members.cast<Widget>(),
          if (hasDividerAfter) const _MenuItemDivider(axis: Axis.horizontal),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (hasDividerBefore) const _MenuItemDivider(),
        ...members.cast<Widget>(),
        if (hasDividerAfter) const _MenuItemDivider(),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty<MenuBarItem>('members', members));
  }

  @override
  String get label => ''; // MenuItemGroups don't have labels.
}

class _MenuItemDivider extends StatelessWidget {
  /// Creates a [_MenuItemDivider].
  const _MenuItemDivider({this.axis = Axis.vertical});

  final Axis axis;

  @override
  Widget build(BuildContext context) {
    switch (axis) {
      case Axis.horizontal:
        return VerticalDivider(width: math.max(2, 16 + Theme.of(context).visualDensity.horizontal * 4));
      // return Container(width: 10, height: 20, color: const Color(0xffff0000));
      case Axis.vertical:
        return Divider(height: math.max(2, 16 + Theme.of(context).visualDensity.vertical * 4));
    }

    // switch (axis) {
    //   case Axis.horizontal:
    //     return VerticalDivider(width: math.max(2, 16 + Theme.of(context).visualDensity.horizontal * 4));
    //   case Axis.vertical:
    //     return Divider(height: math.max(2, 16 + Theme.of(context).visualDensity.vertical * 4));
    // }
  }
}

// A widget used as the main widget for the overlay entry in the
// _MenuBarController. Since the overlay is a Stack, this widget produces a
// Positioned widget that fills the overlay, containing its own Stack to arrange
// the menus with. Positioning of the top level submenus is relative to the
// position of the menu buttons.
class _MenuStack extends StatelessWidget {
  const _MenuStack(this.menuBar);

  final _MenuBarState menuBar;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: FocusScope(
        node: menuBar.overlayScope,
        child: Actions(
          actions: <Type, Action<Intent>>{
            NextFocusIntent: _MenuNextFocusAction(menuBar: menuBar),
            PreviousFocusIntent: _MenuPreviousFocusAction(menuBar: menuBar),
            DirectionalFocusIntent: _MenuDirectionalFocusAction(
              menuBar: menuBar,
            ),
            DismissIntent: _MenuDismissAction(menuBar: menuBar),
            VoidCallbackIntent: VoidCallbackAction(),
          },
          child: Shortcuts(
            // These are here to make sure that these override any shortcut
            // bindings from the menu items when a menu is open. If someone
            // wants to bind an arrow or tab to a menu item, it would otherwise
            // override the default traversal keys. We want their shortcuts to
            // apply everywhere but override these in the menu itself, since
            // there we have to be able to traverse the menus.
            shortcuts: _kMenuTraversalShortcuts,
            child: _MenuBarMarker(
              state: menuBar,
              child: Stack(
                children: <Widget>[
                  ...menuBar.openMenus.where((_MenuNode node) => node.menuBuilder != null).map<Widget>(
                    (_MenuNode node) {
                      return Builder(
                        key: ValueKey<_MenuNode>(node),
                        builder: node.menuBuilder!,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A tree node class for [MenuItem] that contains extra metadata that allows
/// rendering of the menu item, including the parent and children for this node,
/// forming a tree.
///
/// Nodes have a longer lifetime than the widgets they are connected to, since
/// the widgets only exist while their menus are visible, but nodes exist with
/// the same lifetime as the [MenuBar].
class _MenuNode with Diagnosticable, DiagnosticableTreeMixin {
  _MenuNode({required this.item, this.parent}) : children = <_MenuNode>[] {
    assert(!isGroup || !hasSubmenu);
    if (!isGroup) {
      // If this is a group, don't add it to the parent, since only its members
      // will be added.
      parent?.children.add(this);
    }
  }

  /// Makes a node suitable for the root node of the tree which doesn't contain
  /// a valid [item].
  _MenuNode.root()
      : children = <_MenuNode>[],
        parent = null;

  /// Adds any members of groups, or submenus to the tree, instantiating new
  /// menu nodes as needed.
  ///
  /// Does not add [MenuItemGroup]s, since they don't participate in the tree.
  void createChildren() {
    assert(!isGroup || item.menus.isEmpty);
    if (isGroup) {
      // Don't add groups to the parent, just the members of the group. This
      // attaches nodes for each of the members, but not this group item itself.
      for (final MenuBarItem member in item.members) {
        _MenuNode(item: member, parent: parent).createChildren();
      }
    } else {
      assert(parent?.children.contains(this) ?? true);
      for (final MenuBarItem child in item.menus) {
        // Children get automatically linked into the menu tree by attaching
        // this node.
        _MenuNode(item: child, parent: this).createChildren();
      }
    }
  }

  /// This is the parent of this node in the hierarchy, so that we can traverse
  /// ancestors. The source [MenuItem] hierarchy only has children, not parents,
  /// so this is the only way to traverse ancestors without starting at the root
  /// each time.
  final _MenuNode? parent;

  /// These are the menu nodes that wrap the children of the menu item.
  final List<_MenuNode> children;

  /// The widget/menu item with the menu data in it.
  // declared late final so that the root constructor can make one without
  // setting the item.
  late final MenuBarItem item;

  /// Whether or not this menu item is currently open, in order to avoid
  /// duplicate calls to [onOpen] or [onClose].
  ///
  /// Set by the [_MenuBarState].
  bool isOpen = false;

  /// The focus node that corresponds to this menu item, so that it can be
  /// focused when set as the open menu.
  ///
  /// Set by the [_MenuBarState].
  FocusNode? focusNode;

  /// The builder function that builds a submenu, if any. Will be null if there
  /// is no submenu.
  ///
  /// Set by the [_MenuBarState].
  WidgetBuilder? menuBuilder;

  /// Returns true if this menu item is a group (e.g. [MenuItemGroup]).
  bool get isGroup => item.members.isNotEmpty;

  /// Returns true if this menu has a submenu (e.g. [MenuBarMenu]).
  bool get hasSubmenu => children.isNotEmpty;

  /// Returns true if this menu is a child of the (invisible) root menu item.
  bool get isTopLevel => parent?.parent == null && !isRoot;

  /// Returns true if this menu is the (invisible) root of the menu item hierarchy.
  bool get isRoot => parent == null;

  /// Returns all the ancestors of this node, except for the root node.
  List<_MenuNode> get ancestors {
    final List<_MenuNode> result = <_MenuNode>[];
    if (parent == null) {
      return result;
    }
    _MenuNode? node = parent;
    while (node != null && node.parent != null) {
      result.insert(0, node);
      node = node.parent;
    }
    return result;
  }

  /// Returns the topmost menu for this menu item. This is the menu item that is
  /// both an ancestor of this item and a child of the root menu item.
  _MenuNode get topLevel {
    assert(parent != null); // Can't request top level of root.
    if (isTopLevel) {
      // Top level nodes are their own topLevel.
      return this;
    }
    _MenuNode? node = parent;
    _MenuNode lastNode = node!;
    while (node != null && node.parent != null) {
      lastNode = node;
      node = node.parent;
    }
    assert(lastNode.isTopLevel);
    return lastNode;
  }

  /// Returns the index of this menu node in the parent. This is used to find
  /// siblings.
  int get parentIndex {
    if (isRoot) {
      // The root node has no parent index.
      return -1;
    }
    final int result = parent!.children.indexOf(this);
    assert(result != -1, 'Child not found in parent.');
    return result;
  }

  /// Returns the next sibling for this node.
  ///
  /// If there is no next sibling (i.e. this is the last of the parent's
  /// children), this returns null.
  _MenuNode? get nextSibling {
    if (isRoot) {
      // The root has no next sibling.
      return null;
    }
    final int thisIndex = parentIndex;
    if (parent!.children.length > thisIndex + 1) {
      return parent!.children[thisIndex + 1];
    }
    return null;
  }

  /// Returns the previous sibling for this node.
  ///
  /// If there is no previous sibling (i.e. this is the first of the parent's
  /// children), this returns null.
  _MenuNode? get previousSibling {
    final int thisIndex = parentIndex;
    if (thisIndex > 0) {
      return parent!.children[thisIndex - 1];
    }
    return null;
  }

  /// Returns all descendants of this node, recursively, in depth order.
  Iterable<_MenuNode> get descendants {
    Iterable<_MenuNode> visitChildren(_MenuNode node) {
      return <_MenuNode>[node, for (final _MenuNode child in node.children) ...visitChildren(child)];
    }

    return visitChildren(this);
  }

  /// Returns the list of node ancestors with any of the ancestors that appear
  /// in the [other]'s ancestors removed. Includes this node in the results.
  List<_MenuNode> ancestorDifference(_MenuNode? other) {
    final List<_MenuNode> myAncestors = <_MenuNode>[...ancestors, this];
    final List<_MenuNode> otherAncestors = other == null ? const <_MenuNode>[] : <_MenuNode>[...other.ancestors, other];
    int skip = 0;
    for (; skip < myAncestors.length && skip < otherAncestors.length; skip += 1) {
      if (myAncestors[skip] != otherAncestors[skip]) {
        break;
      }
    }
    return myAncestors.sublist(skip);
  }

  /// Get all of the registered children of the given menu that are focusable.
  /// Used for menu traversal.
  List<_MenuNode> get focusableChildren {
    return children.where((_MenuNode child) => child.focusNode?.canRequestFocus ?? false).toList();
  }

  /// Called whenever this menu is opened by being set as the
  /// [_MenuBarController.openMenu].
  ///
  /// Used to avoid calling [MenuItem.onOpen] unnecessarily.
  void open() {
    if (isOpen) {
      return;
    }
    isOpen = true;
    item.onOpen?.call();
  }

  /// Called whenever this menu is closed by another menu being set as the
  /// [_MenuBarController.openMenu].
  ///
  /// Used to avoid calling [MenuItem.onClose] unnecessarily.
  void close() {
    if (!isOpen) {
      return;
    }
    isOpen = false;
    item.onClose?.call();
  }

  // Used for testing to verify which item this is.
  @override
  String toStringShort({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return item.toStringShort();
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return <DiagnosticsNode>[
      ...children.map<DiagnosticsNode>((_MenuNode item) => item.toDiagnosticsNode()),
    ];
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<MenuBarItem>('item', item));
    properties.add(DiagnosticsProperty<_MenuNode>('parent', parent, defaultValue: null));
    properties.add(IntProperty('numChildren', children.length, defaultValue: null));
  }
}

/// An inherited widget used to provide its subtree with a [_MenuNode], so that
/// the children of a [MenuBar] can find their associated [_MenuNode]s without
/// having to be stateful widgets.
///
/// This is how a [MenuBarButton] knows what it's node is in the menu tree: it
/// looks up the nearest [_MenuNodeWrapper] and asks for the [_MenuNode].
///
/// Nodes have a longer lifetime than the widgets they are connected to, since
/// the widgets only exist while their menus are visible, but nodes exist with
/// the same lifetime as the [MenuBar].
class _MenuNodeWrapper extends InheritedWidget {
  const _MenuNodeWrapper({
    required this.menu,
    required super.child,
  });

  final _MenuNode menu;

  static _MenuNode of(BuildContext context) {
    final _MenuNodeWrapper? wrapper = context.dependOnInheritedWidgetOfExactType<_MenuNodeWrapper>();
    assert(wrapper != null, 'Missing _MenuNodeWrapper for $context');
    return wrapper!.menu;
  }

  @override
  bool updateShouldNotify(_MenuNodeWrapper oldWidget) {
    return oldWidget.menu != menu;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<_MenuNode>('menu', menu, defaultValue: null));
  }
}

/// A widget that manages the top level of menu buttons in a bar. This widget is
/// what gets drawn in the main widget hierarchy, while the rest of the menu
/// widgets are drawn in an overlay.
class _MenuBarTopLevelBar extends StatelessWidget implements PreferredSizeWidget {
  _MenuBarTopLevelBar({
    required this.enabled,
    required this.elevation,
    required this.height,
    required this.color,
    required this.padding,
    required this.children,
  }) : preferredSize = Size.fromHeight(height);

  /// Whether or not this [_MenuBarTopLevelBar] is enabled.
  final bool enabled;

  /// The elevation to give the material behind the menu bar.
  final double elevation;

  /// The minimum height to give the menu bar.
  final double height;

  /// The background color of the menu app bar.
  final Color color;

  /// The padding around the outside of the menu bar contents.
  final EdgeInsets padding;

  @override
  final Size preferredSize;

  /// The list of widgets to use as children of this menu bar.
  ///
  /// These are the top level [MenuBarMenu]s.
  final List<MenuBarItem> children;

  @override
  Widget build(BuildContext context) {
    final _MenuBarState menuBar = _MenuBarState.of(context);

    int index = 0;
    return _MenuNodeWrapper(
      menu: menuBar._root,
      child: _MenuBarMenuList(
        backgroundColor: color,
        textDirection: Directionality.of(context),
        direction: Axis.horizontal,
        elevation: elevation,
        menuPadding: padding,
        crossAxisMinSize: height,
        shape: const RoundedRectangleBorder(),
        children: <Widget>[
          ...children.map<Widget>((MenuItem child) {
            final Widget result = _MenuNodeWrapper(
              menu: menuBar._root.children[index],
              child: child as Widget,
            );
            index += 1;
            return result;
          }).toList(),
        ],
      ),
    );
  }
}

/// A label widget that is used as the default label for a [MenuBarButton] or
/// [MenuBarMenu].
///
/// It not only shows the [MenuBarMenu.label] or [MenuBarButton.label], but if
/// there is a shortcut associated with the [MenuBarButton], it will display a
/// mnemonic for the shortcut. For [MenuBarMenu]s, it will display a visual
/// indicator that there is a submenu.
class _MenuBarItemLabel extends StatelessWidget {
  /// Creates a const [_MenuBarItemLabel].
  ///
  /// The [menuBarItem] argument is required.
  const _MenuBarItemLabel({
    this.leadingIcon,
    required this.label,
    this.trailingIcon,
    this.shortcut,
    required this.hasSubmenu,
  });

  /// The optional icon that comes before the [label].
  final Widget? leadingIcon;

  /// The required label widget.
  final Widget label;

  /// The optional icon that comes after the [label].
  final Widget? trailingIcon;

  /// The shortcut for this label, so that it can generate a string describing
  /// the shortcut.
  final MenuSerializableShortcut? shortcut;

  /// Whether or not this menu has a submenu.
  final bool hasSubmenu;

  @override
  Widget build(BuildContext context) {
    final _MenuBarState menuBar = _MenuBarState.of(context);
    final bool isTopLevelItem = _MenuNodeWrapper.of(context).parent == menuBar._root;
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
              child: label,
            ),
            if (trailingIcon != null)
              Padding(
                padding: EdgeInsetsDirectional.only(start: horizontalPadding),
                child: trailingIcon,
              ),
          ],
        ),
        if (!isTopLevelItem) SizedBox(width: horizontalPadding),
        if (shortcut != null && !isTopLevelItem)
          Padding(
            padding: EdgeInsetsDirectional.only(start: horizontalPadding),
            child: Text(
              _LocalizedShortcutLabeler.instance.getShortcutLabel(
                shortcut!,
                MaterialLocalizations.of(context),
              ),
            ),
          ),
        if (hasSubmenu && !isTopLevelItem)
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
}

/// A menu container for [MenuBarButton]s that can be vertical (like regular
/// menus), or horizontal (like the top level menu items).
///
/// Depending on the [direction], this widget contains a column (or row) of
/// widgets, and sizes its width (or height) to the widest (tallest) child, and
/// then forces all the other children to be that same width (or height). It
/// adopts a height (or width) large enough to accommodate all the children.
///
/// It is used by [MenuBarMenu] to render its child items.
class _MenuBarMenuList extends StatefulWidget {
  /// Create a const [_MenuBarMenuList].
  ///
  /// All parameters except `key` and [shape] are required.
  const _MenuBarMenuList({
    required this.direction,
    required this.backgroundColor,
    required this.shape,
    required this.elevation,
    required this.menuPadding,
    required this.textDirection,
    required this.children,
    this.crossAxisMinSize = 0.0,
  });

  /// The main axis direction of the list.
  final Axis direction;

  /// The background color of this submenu.
  final Color backgroundColor;

  /// The shape of the border on this submenu.
  ///
  /// Defaults to a rectangle.
  final ShapeBorder shape;

  /// The Material elevation for the menu's shadow.
  ///
  /// See also:
  ///
  ///  * [Material.elevation] for a description of what elevation implies.
  final double elevation;

  /// The padding around the inside of the menu panel.
  final EdgeInsets menuPadding;

  /// The text direction to use for rendering this menu.
  final TextDirection textDirection;

  /// The minimum size in the main axis.
  ///
  /// Mainly used to enforce the main menu height.
  ///
  /// If null, then defaults to zero.
  final double crossAxisMinSize;

  /// The menu items that fill this submenu.
  final List<Widget> children;

  @override
  State<_MenuBarMenuList> createState() => _MenuBarMenuListState();
}

class _MenuBarMenuListState extends State<_MenuBarMenuList> {
  late _MenuBarState _menuBar;

  List<Widget> _expandGroups() {
    int index = 0;
    final _MenuNode parentMenu = _MenuNodeWrapper.of(context);
    final List<Widget> expanded = <Widget>[];

    for (final Widget child in widget.children) {
      if (child is! MenuItem) {
        // If it's not a menu item, then it's probably a _MenuItemDivider. Don't
        // increment the index, or wrap non-MenuItems with _MenuNodeWrapper:
        // they're not represented in the node tree.
        expanded.add(child);
        continue;
      }
      final MenuItem childMenuItem = child as MenuItem;
      assert(index < parentMenu.children.length);
      if (childMenuItem.members.isEmpty) {
        expanded.add(
          _MenuNodeWrapper(
            menu: parentMenu.children[index],
            child: child,
          ),
        );
        index += 1;
      } else {
        // Groups are expanded in the node tree, so expand them here too.
        expanded.addAll(childMenuItem.members.map<Widget>((MenuItem member) {
          final Widget wrapper = _MenuNodeWrapper(
            menu: parentMenu.children[index],
            child: child,
          );
          index += 1;
          return wrapper;
        }));
      }
    }
    return expanded;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _menuBar = _MenuBarState.of(context);
  }

  @override
  void didUpdateWidget(_MenuBarMenuList oldWidget) {
    super.didUpdateWidget(oldWidget);
    _menuBar = _MenuBarState.of(context);
  }

  Widget _intrinsicCrossSize({required Widget child}) {
    switch (widget.direction) {
      case Axis.horizontal:
        return IntrinsicHeight(child: child);
      case Axis.vertical:
        return IntrinsicWidth(child: child);
    }
  }

  BoxConstraints? _getMinSizeConstraint() {
    if (widget.crossAxisMinSize == null) {
      return null;
    }
    switch (widget.direction) {
      case Axis.horizontal:
        return BoxConstraints(minHeight: widget.crossAxisMinSize);
      case Axis.vertical:
        return BoxConstraints(minWidth: widget.crossAxisMinSize);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _RegisteredRenderBox(
      menuBar: _menuBar,
      child: Container(
        constraints: _getMinSizeConstraint(),
        child: Material(
          color: widget.backgroundColor,
          shape: widget.shape,
          elevation: widget.elevation,
          child: _intrinsicCrossSize(
            child: Padding(
              padding: widget.menuPadding,
              child: Flex(
                textDirection: widget.textDirection,
                direction: widget.direction,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ..._expandGroups(),
                  if (widget.direction == Axis.horizontal) const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// A widget that wraps a render box that is registered with the _MenuBarState so
// that when a pointer event comes in, it can check to see if the pointer hit a
// menu or not.
class _RegisteredRenderBox extends SingleChildRenderObjectWidget {
  const _RegisteredRenderBox({required this.menuBar, required super.child});

  final _MenuBarState menuBar;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderRegisteredRenderBox(menuBar: menuBar);
  }

  @override
  void updateRenderObject(BuildContext context, covariant _RenderRegisteredRenderBox renderObject) {
    renderObject.menuBar = menuBar;
  }
}

// A RenderProxyBox that registers and unregisters itself with the
// _MenuBarState so that when a pointer event comes in, the _MenuBarState can
// check to see if the pointer event hit a menu or not.
class _RenderRegisteredRenderBox extends RenderProxyBox {
  _RenderRegisteredRenderBox({required _MenuBarState menuBar}) : _menuBar = menuBar {
    _menuBar.registerMenuRenderObject(this);
  }

  _MenuBarState get menuBar => _menuBar;
  _MenuBarState _menuBar;
  set menuBar(_MenuBarState value) {
    if (_menuBar != value) {
      _menuBar.unregisterMenuRenderObject(this);
      _menuBar = value;
      _menuBar.registerMenuRenderObject(this);
      markNeedsLayout();
    }
  }

  @override
  void dispose() {
    _menuBar.unregisterMenuRenderObject(this);
    super.dispose();
  }
}

class _ShortcutRegistration extends StatefulWidget {
  const _ShortcutRegistration({required this.shortcuts, required this.child});

  final Map<MenuSerializableShortcut, Intent> shortcuts;
  final Widget child;

  @override
  State<_ShortcutRegistration> createState() => _ShortcutRegistrationState();
}

class _ShortcutRegistrationState extends State<_ShortcutRegistration> {
  ShortcutRegistryEntry? _entry;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _entry?.dispose();
    _entry = ShortcutRegistry.of(context).addAll(
      widget.shortcuts.cast<ShortcutActivator, Intent>(),
    );
  }

  @override
  void didUpdateWidget(_ShortcutRegistration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shortcuts != oldWidget.shortcuts || _entry == null) {
      _entry?.dispose();
      _entry = ShortcutRegistry.of(context).addAll(
        widget.shortcuts.cast<ShortcutActivator, Intent>(),
      );
    }
  }

  @override
  void deactivate() {
    super.deactivate();
    _entry?.dispose();
    _entry = null;
  }

  @override
  void activate() {
    super.activate();
    _entry = ShortcutRegistry.of(context).addAll(
      widget.shortcuts.cast<ShortcutActivator, Intent>(),
    );
  }

  @override
  void dispose() {
    _entry?.dispose();
    _entry = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// A helper class used to generate shortcut labels for a [ShortcutActivator].
///
/// This helper class is typically used by the [MenuBarButton] class to display a
/// label for its assigned shortcut.
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
  _MenuDismissAction({required this.menuBar});

  final _MenuBarState menuBar;

  @override
  bool isEnabled(DismissIntent intent) {
    return menuBar.openMenu != null;
  }

  @override
  void invoke(DismissIntent intent) {
    menuBar.closeAll();
  }
}

class _MenuNextFocusAction extends NextFocusAction {
  _MenuNextFocusAction({required this.menuBar});

  final _MenuBarState menuBar;

  @override
  void invoke(NextFocusIntent intent) {
    if (menuBar.openMenu == null) {
      // Nothing is open, select first top level menu item.
      if (menuBar._root.children.isEmpty) {
        return;
      }
      menuBar.openMenu = menuBar._root.children[0];
      return;
    }
    final List<_MenuNode> enabledNodes = menuBar._root.descendants.where((_MenuNode node) {
      return menuBar.enabled &&
          node != menuBar._root &&
          (node.item.menus.isNotEmpty || node.item.onSelected != null || node.item.onSelectedIntent != null);
    }).toList();
    if (enabledNodes.isEmpty) {
      return;
    }
    final int index = enabledNodes.indexOf(menuBar.openMenu!);
    if (index == -1) {
      return;
    }
    if (index == enabledNodes.length - 1) {
      menuBar.openMenu = enabledNodes.first;
      return;
    }
    menuBar.openMenu = enabledNodes[index + 1];
  }
}

class _MenuPreviousFocusAction extends PreviousFocusAction {
  _MenuPreviousFocusAction({required this.menuBar});

  final _MenuBarState menuBar;

  @override
  void invoke(PreviousFocusIntent intent) {
    if (menuBar.openMenu == null) {
      // Nothing is open, select first top level menu item.
      if (menuBar._root.children.isEmpty) {
        return;
      }
      menuBar.openMenu = menuBar._root.children.last;
      return;
    }
    final List<_MenuNode> enabledNodes = menuBar._root.descendants.where((_MenuNode node) {
      return menuBar.enabled &&
          node != menuBar._root &&
          (node.item.menus.isNotEmpty || node.item.onSelected != null || node.item.onSelectedIntent != null);
    }).toList();
    final List<MenuBarItem> enabledItems = enabledNodes.map<MenuBarItem>((_MenuNode node) => node.item).toList();
    if (enabledNodes.isEmpty) {
      return;
    }
    final int index = enabledItems.indexOf(menuBar.openMenu!.item);
    if (index == -1) {
      return;
    }
    if (index == 0) {
      menuBar.openMenu = enabledNodes.last;
      return;
    }
    menuBar.openMenu = enabledNodes[index - 1];
    return;
  }
}

class _MenuDirectionalFocusAction extends DirectionalFocusAction {
  /// Creates a [DirectionalFocusAction].
  _MenuDirectionalFocusAction({required this.menuBar});

  final _MenuBarState menuBar;

  bool _moveForward() {
    if (menuBar.openMenu == null) {
      return false;
    }
    final _MenuNode? focusedItem = menuBar.focusedItem;
    if (focusedItem == null) {
      return false;
    }
    if (focusedItem.hasSubmenu && focusedItem.parent != menuBar._root) {
      // If no submenu is open, then arrow opens the submenu.
      if (focusedItem.children.isNotEmpty) {
        menuBar.openMenu = focusedItem.children.first;
      }
    } else {
      // If there's no submenu, then an arrow moves to the next top
      // level sibling, wrapping around if need be.
      final _MenuNode? next = focusedItem.topLevel.nextSibling;
      if (next != null) {
        menuBar.openMenu = next;
      } else {
        menuBar.openMenu = menuBar._root.children.isNotEmpty ? menuBar._root.children.first : null;
      }
    }
    return true;
  }

  bool _moveBackward() {
    if (menuBar.openMenu == null) {
      return false;
    }
    final _MenuNode? focusedItem = menuBar.focusedItem;
    if (focusedItem == null) {
      return false;
    }
    // Back moves between siblings on the top level menu.
    // Wraps around if there is no previous.
    _MenuNode? previous;
    if (focusedItem.isTopLevel) {
      previous = focusedItem.previousSibling;
    } else {
      if (focusedItem.parent!.isTopLevel) {
        previous = focusedItem.parent!.previousSibling;
      } else {
        previous = focusedItem.parent;
      }
    }
    if (previous != null) {
      menuBar.openMenu = previous;
    } else {
      menuBar.openMenu = menuBar._root.children.isNotEmpty ? menuBar._root.children.last : null;
    }
    return true;
  }

  bool _moveUp() {
    if (menuBar.openMenu == null) {
      return false;
    }
    final _MenuNode? focusedItem = menuBar.focusedItem;
    if (focusedItem == null) {
      return false;
    }
    if (focusedItem.parent == menuBar._root) {
      // Pressing on a top level menu closes all the menus.
      menuBar.openMenu = null;
      return true;
    }
    _MenuNode? previousFocusable = focusedItem.previousSibling;
    while (previousFocusable != null && !previousFocusable.focusNode!.canRequestFocus) {
      previousFocusable = previousFocusable.previousSibling;
    }
    if (previousFocusable != null) {
      menuBar.openMenu = previousFocusable;
    } else if (focusedItem.parent?.parent == menuBar._root) {
      // Pressing on a next-to-top level menu, moves to the parent.
      menuBar.openMenu = focusedItem.parent;
    }
    return true;
  }

  bool _moveDown() {
    final _MenuNode? focusedItem = menuBar.focusedItem;
    if (focusedItem == null) {
      return false;
    }
    if (focusedItem.parent == menuBar._root) {
      if (menuBar.openMenu == null) {
        menuBar.openMenu = focusedItem;
        return true;
      }
      final List<_MenuNode> children = focusedItem.focusableChildren;
      if (children.isNotEmpty) {
        menuBar.openMenu = children[0];
      }
      return true;
    }
    _MenuNode? nextFocusable = focusedItem.nextSibling;
    while (nextFocusable != null && !nextFocusable.focusNode!.canRequestFocus) {
      nextFocusable = nextFocusable.nextSibling;
    }
    if (nextFocusable != null) {
      menuBar.openMenu = nextFocusable;
    }
    return true;
  }

  @override
  void invoke(DirectionalFocusIntent intent) {
    final TextDirection textDirection = Directionality.of(menuBar.context);
    switch (intent.direction) {
      case TraversalDirection.up:
        if (_moveUp()) {
          return;
        }
        break;
      case TraversalDirection.down:
        if (_moveDown()) {
          return;
        }
        break;
      case TraversalDirection.left:
        switch (textDirection) {
          case TextDirection.rtl:
            if (_moveForward()) {
              return;
            }
            break;
          case TextDirection.ltr:
            if (_moveBackward()) {
              return;
            }
            break;
        }
        break;
      case TraversalDirection.right:
        switch (textDirection) {
          case TextDirection.rtl:
            if (_moveBackward()) {
              return;
            }
            break;
          case TextDirection.ltr:
            if (_moveForward()) {
              return;
            }
            break;
        }

        break;
    }
    super.invoke(intent);
  }
}

// This class will eventually be auto-generated, so it should remain at the end
// of the file.
class _TokenDefaultsM3 extends MenuBarThemeData {
  _TokenDefaultsM3(this.context)
      : super(
          barElevation: MaterialStateProperty.all<double?>(2.0),
          menuElevation: MaterialStateProperty.all<double?>(4.0),
          menuShape: MaterialStateProperty.all<ShapeBorder?>(_defaultBorder),
          menuPadding: const EdgeInsets.symmetric(vertical: 8.0),
          itemShape: MaterialStateProperty.all<OutlinedBorder?>(_defaultItemBorder),
        );

  static const RoundedRectangleBorder _defaultBorder =
      RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.elliptical(2.0, 3.0)));

  static const RoundedRectangleBorder _defaultItemBorder = RoundedRectangleBorder();

  final BuildContext context;
  late final ColorScheme _colors = Theme.of(context).colorScheme;

  @override
  double get barHeight {
    return 40 + Theme.of(context).visualDensity.baseSizeAdjustment.dy;
  }

  @override
  EdgeInsets get barPadding {
    return EdgeInsets.symmetric(
      horizontal: math.max(
        _kTopLevelMenuHorizontalMinPadding,
        2 + Theme.of(context).visualDensity.baseSizeAdjustment.dx,
      ),
    );
  }

  @override
  MaterialStateProperty<Color?> get barBackgroundColor {
    return MaterialStateProperty.all<Color?>(_colors.surface);
  }

  @override
  MaterialStateProperty<double?> get barElevation => super.barElevation!;

  @override
  MaterialStateProperty<Color?> get menuBackgroundColor {
    return MaterialStateProperty.all<Color?>(_colors.surface);
  }

  @override
  MaterialStateProperty<double?> get menuElevation => super.menuElevation!;

  @override
  MaterialStateProperty<ShapeBorder?> get menuShape => super.menuShape!;

  @override
  EdgeInsets get menuPadding => super.menuPadding!;

  @override
  MaterialStateProperty<Color?> get itemBackgroundColor {
    return MaterialStateProperty.all<Color?>(_colors.surface);
  }

  @override
  MaterialStateProperty<Color?> get itemForegroundColor {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.disabled)) {
        return _colors.onSurface.withOpacity(0.38);
      }
      return _colors.primary;
    });
  }

  @override
  MaterialStateProperty<Color?> get itemOverlayColor {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      // Use the component default.
      return null;
    });
  }

  @override
  MaterialStateProperty<TextStyle?> get itemTextStyle {
    return MaterialStateProperty.all<TextStyle?>(Theme.of(context).textTheme.labelLarge);
  }

  @override
  EdgeInsets get itemPadding {
    final VisualDensity density = Theme.of(context).visualDensity;
    return EdgeInsets.symmetric(
      vertical: math.max(0, density.vertical * 2),
      horizontal: math.max(0, 24 + density.horizontal * 2),
    );
  }

  @override
  MaterialStateProperty<OutlinedBorder?> get itemShape => super.itemShape!;
}
