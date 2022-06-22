// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
import 'menu_theme.dart';
import 'text_button.dart';
import 'text_button_theme.dart';
import 'text_theme.dart';
import 'theme.dart';
import 'theme_data.dart';

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

/// A mixin for describing cascading menu hierarchies that are part of
/// a [MenuBar] or other cascading menu.
///
/// This class is abstract, and so can't be used directly. Typically subclasses
/// like [MenuBarItem] and [MenuItemGroup] are used in practice.
///
/// See also:
///
///  * [MenuBar], a widget that renders menus in Flutter with a Material design
///    style.
///  * [PlatformMenuBar], a widget that renders menu items using platform APIs
///    instead of Flutter.
mixin MenuItem on Diagnosticable implements Widget {
  /// A required label displayed on the entry for this item in the menu.
  ///
  /// This is rendered by default in a [Text] widget.
  /// The label appearance can be overridden by using a [labelWidget] to render
  /// a different widget in its place.
  ///
  /// This label is also used as the default [semanticsLabel].
  String get label;

  /// An optional widget that will be displayed in place of the default [Text]
  /// widget containing the [label].
  ///
  /// If both the `labelWidget` and [semanticsLabel] are provided, the
  /// [semanticsLabel] will take precedence for defining semantic information.
  Widget? get labelWidget => null;

  /// The optional shortcut that selects this [MenuItem].
  ///
  /// This shortcut is only enabled when [onSelected] is set.
  MenuSerializableShortcut? get shortcut => null;

  /// Returns any child [MenuItem]s of this item.
  ///
  /// Returns an empty list if this type of menu item doesn't have
  /// children.
  List<Widget> get children => const <Widget>[];

  /// The function called when the mouse leaves or enters this menu item's
  /// button.
  ValueChanged<bool>? get onHover => null;

  /// Returns a callback, if any, to be invoked if the platform menu receives a
  /// "Menu.selectedCallback" method call from the platform for this item.
  ///
  /// Only items that do not have submenus will have this callback invoked.
  ///
  /// Only one of [onSelected] or [onSelectedIntent] may be specified.
  ///
  /// If neither [onSelected] nor [onSelectedIntent] are specified, then this
  /// menu item is considered to be disabled.
  ///
  /// The default implementation returns null.
  VoidCallback? get onSelected => null;

  /// Returns an intent, if any, to be invoked if the platform receives a
  /// "Menu.selectedCallback" method call from the platform for this item.
  ///
  /// Only items that do not have submenus will have this intent invoked.
  ///
  /// Only one of [onSelected] or [onSelectedIntent] may be specified.
  ///
  /// If neither [onSelected] nor [onSelectedIntent] are specified, then this
  /// menu item is considered to be disabled.
  ///
  /// The default implementation returns null.
  Intent? get onSelectedIntent => null;

  /// Returns a callback, if any, to be invoked if the platform menu receives a
  /// "Menu.opened" method call from the platform for this item.
  ///
  /// Only items that have submenus will have this callback invoked.
  ///
  /// The default implementation returns null.
  VoidCallback? get onOpen => null;

  /// Returns a callback, if any, to be invoked if the platform menu receives a
  /// "Menu.closed" method call from the platform for this item.
  ///
  /// Only items that have submenus will have this callback invoked.
  ///
  /// The default implementation returns null.
  VoidCallback? get onClose => null;

  /// Returns the list of group members if this menu item is a "grouping" menu
  /// item, such as [PlatformMenuItemGroup].
  ///
  /// Defaults to an empty list.
  List<Widget> get members => const <Widget>[];

  @override
  String toStringShort() => '${describeIdentity(this)}($label)';
}

/// A menu bar with cascading child menus.
///
/// This is a Material Design menu bar that typically resides above the main
/// body of an application (but can go anywhere) that defines a menu system for
/// invoking callbacks or firing [Intent]s in response to user selection of a
/// menu item.
///
/// The menu can be navigated by using the arrow keys. It can be dismissed using
/// the escape key, or by clicking away from the menu item (anywhere that is not
/// a part of the menu bar or cascading menus). Once a menu is open, the menu
/// hierarchy can be navigated by hovering over the menu with the mouse.
///
/// Menu items can have a [SingleActivator] or [CharacterActivator] assigned to
/// them as their [MenuBarButton.shortcut], so that if the shortcut key sequence
/// is pressed, the menu item corresponding to that shortcut will be selected
/// even if its menu is closed. Shortcuts must be unique in the ambient
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
class MenuBar extends StatefulWidget with DiagnosticableTreeMixin {
  /// Creates a const [MenuBar].
  const MenuBar({
    super.key,
    this.controller,
    this.enabled = true,
    this.backgroundColor,
    this.minimumHeight,
    this.padding,
    this.elevation,
    this.children = const <Widget>[],
  });

  /// The list of menu items that are the top level children of the
  /// [MenuBar].
  ///
  /// The `menus` member contains [MenuItem]s, which are specialized widgets
  /// that provide additional API allowing them to form a hierarchy that can be
  /// traversed even when the widgets are not visible, and are thus are only
  /// part of the regular widget hierarchy when the associated menus are open.
  ///
  /// Shortcuts defined on the menus in the hierarchy are in effect even if the
  /// menu item they are attached to is not currently visible.
  ///
  /// Also, a Widget in Flutter is immutable, so directly modifying the
  /// `menus` with `List` APIs such as
  /// `someMenuBarWidget.menus.add(...)` will result in incorrect
  /// behaviors. Whenever the menus list is modified, a new list object
  /// should be provided.
  final List<Widget> children;

  /// An optional controller that allows outside control of the menu bar.
  ///
  /// Setting this controller will allow closing of any open menus from outside
  /// of the menu bar using [MenuBarController.closeAll].
  ///
  /// Descendants of the [MenuBar] can access its [MenuBarController] using
  /// [MenuBarController.of].
  final MenuBarController? controller;

  /// Whether or not this menu bar is enabled.
  ///
  /// When disabled, all menus are closed, the menu bar buttons are disabled,
  /// and menu shortcuts are ignored.
  final bool enabled;

  /// The background color of the menu bar.
  ///
  /// Defaults to [MenuThemeData.barBackgroundColor] if null.
  final MaterialStateProperty<Color?>? backgroundColor;

  /// The preferred minimum height of the menu bar.
  ///
  /// Defaults to the value of [MenuThemeData.barMinimumHeight] if null.
  final double? minimumHeight;

  /// The padding around the contents of the menu bar itself.
  ///
  /// Defaults to the value of [MenuThemeData.barPadding] if null.
  final EdgeInsets? padding;

  /// The Material elevation of the menu bar (if any).
  ///
  /// Defaults to the [MenuThemeData.barElevation] value of the ambient
  /// [MenuTheme].
  ///
  /// See also:
  ///
  ///  * [Material.elevation] for a description of what elevation implies.
  final MaterialStateProperty<double?>? elevation;

  @override
  State<MenuBar> createState() => _MenuBarState();

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return <DiagnosticsNode>[...children.map<DiagnosticsNode>((Widget item) => item.toDiagnosticsNode())];
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('enabled', value: enabled, ifFalse: 'DISABLED'));
    properties.add(DiagnosticsProperty<MenuBarController>('controller', controller, defaultValue: null));
    properties.add(
        DiagnosticsProperty<MaterialStateProperty<Color?>>('backgroundColor', backgroundColor, defaultValue: null));
    properties.add(DoubleProperty('minimumHeight', minimumHeight, defaultValue: null));
    properties.add(DiagnosticsProperty<EdgeInsets?>('padding', padding, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<double?>>('elevation', elevation, defaultValue: null));
  }
}

class _MenuBarState extends State<MenuBar> {
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

  // Used to tell if we've already been disposed, for both debug checks, and to
  // avoid causing widget changes after being disposed.
  bool _disposed = false;

  // The set of menus that are currently open.
  final Map<_MenuBarMenuState, WidgetBuilder> _openMenus = <_MenuBarMenuState, WidgetBuilder>{};

  // The tree of menu item nodes corresponding to menus that are currently
  // *visible* (does not include any menu items that are not currently visible),
  // and their associated MenuBarButtons.
  final _MenuNode root = _RootMenuNode();

  bool get menuIsOpen => _openMenus.isNotEmpty;
  bool get enabled => widget.enabled;

  final FocusScopeNode menuBarScope = FocusScopeNode(debugLabel: 'MenuBar');
  final FocusScopeNode overlayScope = FocusScopeNode(debugLabel: 'MenuBar overlay');

  // Returns the active parent menu bar state in the given context, and creates
  // a dependency relationship that will rebuild the context when the menu bar
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
    GestureBinding.instance.pointerRouter.addGlobalRoute(_handlePointerEvent);
    widget.controller?._attach(this);
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
    _previousFocus = null;
    _focusBeforeClick = null;
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_handlePointerEvent);
    super.dispose();
    _disposed = true;
  }

  @override
  void didUpdateWidget(MenuBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      assert(widget.controller?._menuBar == this || widget.controller?._menuBar == null);
      oldWidget.controller?._menuBar = null;
      assert(widget.controller?._menuBar == null);
      widget.controller?._menuBar = this;
    }
    if (!widget.enabled) {
      closeAll();
    }
    _markMenuDirtyAndDelayIfNecessary();
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasOverlay(context));
    final Set<MaterialState> state = <MaterialState>{if (!widget.enabled) MaterialState.disabled};
    final MenuThemeData menuTheme = MenuTheme.of(context);
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
          return ExcludeFocus(
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
                  elevation: (widget.elevation ?? menuTheme.barElevation ?? _TokenDefaultsM3(context).barElevation)
                      .resolve(state)!,
                  height:
                      widget.minimumHeight ?? menuTheme.barMinimumHeight ?? _TokenDefaultsM3(context).barMinimumHeight,
                  enabled: widget.enabled,
                  color: (widget.backgroundColor ??
                          menuTheme.barBackgroundColor ??
                          _TokenDefaultsM3(context).barBackgroundColor)
                      .resolve(state)!,
                  padding: widget.padding ?? menuTheme.barPadding ?? _TokenDefaultsM3(context).barPadding,
                  children: widget.children,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  void openMenu(_MenuBarMenuState menu, WidgetBuilder builder) {
    if (!menuIsOpen) {
      // We're opening the first menu, so cache the primary focus so that we can
      // try to return to it when the menu is dismissed.
      // If we captured a focus before the click, then use that, otherwise use
      // the current primary focus.
      _previousFocus = _focusBeforeClick ?? FocusManager.instance.primaryFocus;
    }
    _focusBeforeClick = null;
    final List<_MenuBarMenuState> ancestors = menu.ancestors;
    _openMenus.removeWhere((_MenuBarMenuState key, WidgetBuilder builder) => !ancestors.contains(key));
    _openMenus[menu] = builder;
    _markMenuDirtyAndDelayIfNecessary();
  }

  void closeMenu(_MenuBarMenuState menu) {
    final Set<_MenuBarMenuState> toClose = <_MenuBarMenuState>{menu};
    for (final _MenuBarMenuState openMenu in _openMenus.keys) {
      if (openMenu.ancestors.contains(menu)) {
        toClose.add(openMenu);
      }
    }
    _openMenus.removeWhere((_MenuBarMenuState key, WidgetBuilder value) => toClose.contains(key));
    _markMenuDirtyAndDelayIfNecessary();
  }

  void closeAll() {
    _focusBeforeClick = null;
    _openMenus.clear();
    _previousFocus?.requestFocus();
    _markMenuDirtyAndDelayIfNecessary();
  }

  void _markMenuDirtyAndDelayIfNecessary() {
    if (_disposed || !mounted) {
      return;
    }
    if (menuIsOpen) {
      if (_overlayEntry == null) {
        _overlayEntry = OverlayEntry(builder: (BuildContext context) => _MenuStack(this));
        Overlay.of(context)?.insert(_overlayEntry!);
      }
    } else {
      _overlayEntry?.remove();
      _overlayEntry = null;
      // If there aren't any menus open, then there's no need to mark the
      // overlay dirty, since we just removed the overlay entry.
      widget.controller?._menuBarStateChanged();
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

  // Returns true if the given menu or one of its ancestors is open.
  bool isAnOpenMenu(_MenuBarMenuState menu) => _openMenus.containsKey(menu);

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

  String? get debugCurrentItem {
    String? result;
    assert(() {
      if (menuIsOpen) {
        result = _openMenus.keys.map<String>((_MenuBarMenuState node) => node.toStringShort()).join(' > ');
      }
      return true;
    }());
    return result;
  }

  String? get debugFocusedItem {
    String? result;
    assert(() {
      if (primaryFocus?.context != null) {
        result = primaryFocus?.toStringShort();
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
  String? get debugFocusedItem {
    return _menuBar?.debugFocusedItem;
  }

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
class MenuBarButton extends StatefulWidget with MenuItem {
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
  }) : assert(onSelected == null || onSelectedIntent == null,
            'Only one of onSelected or onSelectedIntent may be specified');

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
  /// Defaults to the ambient [Theme]'s [ColorScheme.surface] if null.
  ///
  /// See also:
  ///
  ///  * [MenuThemeData.itemBackgroundColor], for the value in the [MenuTheme] that
  ///    can be set instead of this property.
  final MaterialStateProperty<Color?>? backgroundColor;

  /// The foreground color for this [MenuBarButton].
  ///
  /// Defaults to the ambient [Theme]'s [ColorScheme.primary] if null.
  ///
  /// See also:
  ///
  ///  * [MenuThemeData.itemForegroundColor], for the value in the [MenuTheme] that
  ///    can be set instead of this property.
  final MaterialStateProperty<Color?>? foregroundColor;

  /// The overlay color for this [MenuBarButton].
  ///
  /// Defaults to the ambient [Theme]'s [ColorScheme.primary] (with appropriate
  /// state-dependent opacity) if null.
  ///
  /// See also:
  ///
  ///  * [MenuThemeData.itemOverlayColor], for the value in the [MenuTheme] that
  ///    can be set instead of this property.
  final MaterialStateProperty<Color?>? overlayColor;

  /// The padding around the contents of the [MenuBarButton].
  ///
  /// Defaults to zero in the vertical direction, and 24 pixels on each side in
  /// the horizontal direction.
  ///
  /// See also:
  ///
  ///  * [MenuThemeData.itemPadding], for the value in the [MenuTheme] that
  ///    can be set instead of this property.
  final EdgeInsets? padding;

  /// The text style for the text in this menu bar item.
  ///
  /// May be overridden inside of [labelWidget], if supplied.
  ///
  /// Defaults to the ambient [ThemeData.textTheme]'s [TextTheme.labelLarge] if null.
  ///
  /// See also:
  ///
  ///  * [MenuThemeData.itemTextStyle], for the value in the [MenuTheme] that
  ///    can be set instead of this property.
  final MaterialStateProperty<TextStyle?>? textStyle;

  /// The shape of this menu bar item.
  ///
  /// Defaults to a [RoundedRectangleBorder] with a border radius of zero (i.e.
  /// a rectangle) if null.
  ///
  /// See also:
  ///
  ///  * [MenuThemeData.itemShape], for the value in the [MenuTheme] that
  ///    can be set instead of this property.
  final MaterialStateProperty<OutlinedBorder?>? shape;

  @override
  State<MenuBarButton> createState() => _MenuBarButtonState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('enabled', value: onSelected != null || onSelectedIntent != null, ifFalse: 'DISABLED'));
    properties.add(DiagnosticsProperty<FocusNode>('focusNode', focusNode, defaultValue: null));
    properties.add(DiagnosticsProperty<Widget>('leadingIcon', leadingIcon, defaultValue: null));
    properties.add(StringProperty('label', label));
    properties.add(DiagnosticsProperty<Widget>('trailingIcon', trailingIcon, defaultValue: null));
    properties.add(StringProperty('semanticsLabel', semanticsLabel, defaultValue: null));
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

class _MenuBarButtonState extends State<MenuBarButton> with _MenuNode {
  late _MenuBarState _menuBar;
  _MenuBarMenuState? _parent;
  int _parentIndex = -1;
  FocusNode get _focusNode => widget.focusNode ?? _internalFocusNode!;
  FocusNode? _internalFocusNode;

  bool get _enabled {
    return (widget.onSelected != null || widget.onSelectedIntent != null) && _menuBar.enabled;
  }

  @override
  Map<int, _MenuNode> get children => const <int, _MenuNode>{};

  @override
  _MenuNode? get parent => _parent;

  @override
  int get parentIndex => _parentIndex;

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
    _internalFocusNode?.dispose();
    _internalFocusNode = null;
    parent?.removeChild(parentIndex, this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _menuBar = _MenuBarState.of(context);
    parent?.removeChild(parentIndex, this);
    final _MenuItemWrapper? wrapper = _MenuItemWrapper.maybeOf(context);
    _parent = wrapper?.parent;
    _parentIndex = wrapper?.index ?? -1;
    parent?.addChild(parentIndex, this);
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
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final MenuThemeData menuTheme = MenuTheme.of(context);
    final _TokenDefaultsM3 defaultTheme = _TokenDefaultsM3(context);
    final Size densityAdjustedSize = const Size(64, 48) + Theme.of(context).visualDensity.baseSizeAdjustment;
    final MaterialStateProperty<EdgeInsets?> resolvedPadding =
        MaterialStateProperty.all<EdgeInsets?>(widget.padding ?? menuTheme.itemPadding ?? defaultTheme.itemPadding);
    return Semantics(
      enabled: _enabled,
      // Will default to the label in the Text widget or labelWidget below if
      // not specified.
      label: widget.semanticsLabel,
      child: TextButton(
        style: (TextButtonTheme.of(context).style ?? const ButtonStyle()).copyWith(
          minimumSize: MaterialStateProperty.all<Size?>(densityAdjustedSize),
          backgroundColor: widget.backgroundColor ?? menuTheme.itemBackgroundColor ?? defaultTheme.itemBackgroundColor,
          foregroundColor: widget.foregroundColor ?? menuTheme.itemForegroundColor ?? defaultTheme.itemForegroundColor,
          overlayColor: widget.overlayColor ?? menuTheme.itemOverlayColor ?? defaultTheme.itemOverlayColor,
          padding: resolvedPadding,
          shape: widget.shape ?? menuTheme.itemShape ?? defaultTheme.itemShape,
          textStyle: widget.textStyle ?? menuTheme.itemTextStyle ?? defaultTheme.itemTextStyle,
        ),
        focusNode: _focusNode,
        onHover: _enabled ? _handleHover : null,
        onPressed: _enabled ? _handleSelect : null,
        child: _MenuBarItemLabel(
          leadingIcon: widget.leadingIcon,
          label: widget.labelWidget ?? Text(widget.label),
          shortcut: widget.shortcut,
          trailingIcon: widget.trailingIcon,
          hasSubmenu: false,
        ),
      ),
    );
  }

  void _handleSelect() {
    widget.onSelected?.call();
    _menuBar.closeAll();
  }

  void _handleHover(bool hovering) {
    widget.onHover?.call(hovering);
    // Will make sure that the parent is open, but all other menus (including
    // submenus of sibling buttons) are closed.
    _parent?.open();
  }
}

/// A menu item widget that displays a hierarchical cascading menu as part of a
/// [MenuBar].
///
/// This widget represents an entry in [MenuBar.children] that has a submenu. Like
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
/// a mouse), it will open a submenu containing the [children].
///
/// See also:
///
///  * [MenuBarButton], a widget that represents a leaf [MenuBar] item.
///  * [MenuBar], a widget that renders data in a menu hierarchy using
///    Flutter-rendered widgets in a Material Design style.
///  * [PlatformMenuBar], a widget that renders similar menu bar items from a
///    [PlatformMenuItem] using platform-native APIs.
class MenuBarMenu extends StatefulWidget with MenuItem {
  /// Creates a const [MenuBarMenu].
  ///
  /// The [label] attribute is required.
  const MenuBarMenu({
    super.key,
    required this.label,
    this.labelWidget,
    this.leadingIcon,
    this.trailingIcon,
    this.semanticsLabel,
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
    this.children = const <Widget>[],
  });

  /// An optional icon to display before the label text.
  final Widget? leadingIcon;

  @override
  final String label;

  @override
  final Widget? labelWidget;

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

  /// The focus node to use for the menu item button.
  final FocusNode? focusNode;

  /// If true, will request focus when first built if nothing else has focus.
  final bool autofocus;

  /// The background color of the cascading menu specified by [children].
  ///
  /// Defaults to the value of [MenuThemeData.menuBackgroundColor] value of the
  /// ambient [MenuTheme].
  final MaterialStateProperty<Color?>? backgroundColor;

  /// The shape of the cascading menu specified by [children].
  ///
  /// Defaults to the value of [MenuThemeData.menuShape] value of the
  /// ambient [MenuTheme].
  final MaterialStateProperty<ShapeBorder?>? shape;

  /// The Material elevation of the submenu (if any).
  ///
  /// Defaults to the [MenuThemeData.barElevation] value of the ambient
  /// [MenuTheme].
  ///
  /// See also:
  ///
  ///  * [Material.elevation] for a description of what elevation is.
  final MaterialStateProperty<double?>? elevation;

  /// The padding around the outside of the contents of a [MenuBarMenu].
  ///
  /// Defaults to the [MenuThemeData.menuPadding] value of the ambient
  /// [MenuTheme].
  final EdgeInsets? padding;

  /// The padding around the outside of the button that opens a [MenuBarMenu]'s
  /// submenu.
  ///
  /// Defaults to the [MenuThemeData.itemPadding] value of the ambient
  /// [MenuTheme].
  final EdgeInsets? buttonPadding;

  /// The background color of the button that opens the submenu.
  ///
  /// Defaults to the value of [MenuThemeData.itemBackgroundColor] value of
  /// the ambient [MenuTheme].
  final MaterialStateProperty<Color?>? buttonBackgroundColor;

  /// The foreground color of the button that opens the submenu.
  ///
  /// Defaults to the value of [MenuThemeData.itemForegroundColor] value of
  /// the ambient [MenuTheme].
  final MaterialStateProperty<Color?>? buttonForegroundColor;

  /// The overlay color of the button that opens the submenu.
  ///
  /// Defaults to the value of [MenuThemeData.itemOverlayColor] value of
  /// the ambient [MenuTheme].
  final MaterialStateProperty<Color?>? buttonOverlayColor;

  /// The shape of the button that opens the submenu.
  ///
  /// Defaults to the value of [MenuThemeData.menuShape] value of the
  /// ambient [MenuTheme].
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
  final List<Widget> children;

  @override
  State<MenuBarMenu> createState() => _MenuBarMenuState();

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return <DiagnosticsNode>[
      ...children.map<DiagnosticsNode>((Widget child) {
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
    properties.add(StringProperty('semanticsLabel', semanticsLabel, defaultValue: null));
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

class _MenuBarMenuState extends State<MenuBarMenu> with _MenuNode {
  late _MenuBarState _menuBar;
  FocusNode get _focusNode => widget.focusNode ?? _internalFocusNode!;
  FocusNode? _internalFocusNode;
  _MenuBarMenuState? _parent;
  int _parentIndex = -1;
  bool get _showingSubmenu => _menuBar.isAnOpenMenu(this);
  bool get _isTopLevelMenu => _parent == null;
  bool get _enabled => _menuBar.enabled && widget.children.isNotEmpty;

  @override
  final Map<int, _MenuNode> children = <int, _MenuNode>{};

  @override
  _MenuNode? get parent => _parent;

  @override
  int get parentIndex => _parentIndex;

  @override
  void addChild(int index, _MenuNode child) {
    assert(
        children[index] == null, 'Index $index already set. Tried to set to $child. Already set to ${children[index]}');
    children[index] = child;
  }

  @override
  void removeChild(int index, _MenuNode child) {
    assert(children[index] == child, 'Child $child not found at index $index in $children');
    children.remove(index);
  }

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _internalFocusNode = FocusNode();
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
    parent?.removeChild(parentIndex, this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _menuBar = _MenuBarState.of(context);
    parent?.removeChild(parentIndex, this);
    final _MenuItemWrapper? wrapper = _MenuItemWrapper.maybeOf(context);
    _parent = wrapper?.parent;
    _parentIndex = wrapper?.index ?? -1;
    parent?.addChild(parentIndex, this);
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

  void close() {
    setState(() {
      _menuBar.closeMenu(this);
    });
  }

  void open() {
    setState(() {
      _menuBar.openMenu(this, _buildPositionedMenu);
    });
  }

  @override
  List<_MenuBarMenuState> get ancestors => super.ancestors.cast<_MenuBarMenuState>();

  List<_MenuBarMenuState> ancestorDifference(_MenuBarMenuState? other) {
    final List<_MenuBarMenuState> myAncestors = <_MenuBarMenuState>[...ancestors, this];
    final List<_MenuBarMenuState> otherAncestors =
        other == null ? const <_MenuBarMenuState>[] : <_MenuBarMenuState>[...other.ancestors, other];
    int skip = 0;
    for (; skip < myAncestors.length && skip < otherAncestors.length; skip += 1) {
      if (myAncestors[skip] != otherAncestors[skip]) {
        break;
      }
    }
    return myAncestors.sublist(skip);
  }

  void _toggleShowMenu() {
    if (_showingSubmenu) {
      close();
    } else {
      open();
    }
  }

  // Called when the pointer is hovering over the menu button.
  void _handleMenuHover(bool hovering) {
    // Don't open the top level menu bar buttons on hover unless something else
    // is already open. This means that the user has to first open the menu bar
    // before hovering allows them to traverse it.
    if (_parent == null && !_menuBar.menuIsOpen) {
      return;
    }
    if (hovering) {
      open();
    }
  }

  @override
  Widget build(BuildContext context) {
    final MenuThemeData menuTheme = MenuTheme.of(context);
    final _TokenDefaultsM3 defaultTheme = _TokenDefaultsM3(context);
    final Size densityAdjustedSize = const Size(64, 48) + Theme.of(context).visualDensity.baseSizeAdjustment;
    final MaterialStateProperty<EdgeInsets?> resolvedPadding;
    if (_isTopLevelMenu) {
      resolvedPadding =
          MaterialStateProperty.all<EdgeInsets?>(widget.padding ?? menuTheme.barPadding ?? defaultTheme.barPadding);
    } else {
      resolvedPadding =
          MaterialStateProperty.all<EdgeInsets?>(widget.padding ?? menuTheme.itemPadding ?? defaultTheme.itemPadding);
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
              widget.buttonBackgroundColor ?? menuTheme.itemBackgroundColor ?? defaultTheme.itemBackgroundColor,
          foregroundColor:
              widget.buttonForegroundColor ?? menuTheme.itemForegroundColor ?? defaultTheme.itemForegroundColor,
          overlayColor: widget.buttonOverlayColor ?? menuTheme.itemOverlayColor ?? defaultTheme.itemOverlayColor,
          padding: resolvedPadding,
          shape: widget.buttonShape ?? menuTheme.itemShape ?? defaultTheme.itemShape,
          textStyle: widget.buttonTextStyle ?? menuTheme.itemTextStyle ?? defaultTheme.itemTextStyle,
        ),
        focusNode: _focusNode,
        onHover: _enabled ? _handleMenuHover : null,
        onPressed: _enabled ? _toggleShowMenu : null,
        child: _MenuBarItemLabel(
          leadingIcon: widget.leadingIcon,
          label: widget.labelWidget ?? Text(widget.label),
          shortcut: widget.shortcut,
          trailingIcon: widget.trailingIcon,
          hasSubmenu: true,
        ),
      ),
    );
  }

  // Wraps the given child with the appropriate Positioned widget for the
  // submenu.
  Widget _wrapWithPosition({
    required BuildContext menuButtonContext,
    required Widget child,
  }) {
    final TextDirection textDirection = Directionality.of(menuButtonContext);
    final RenderBox button = menuButtonContext.findRenderObject()! as RenderBox;
    final RenderBox menuBarBox = _menuBar.context.findRenderObject()! as RenderBox;
    final RenderBox overlay = Overlay.of(menuButtonContext)!.context.findRenderObject()! as RenderBox;

    final EdgeInsets menuPadding =
        widget.padding ?? MenuTheme.of(context).menuPadding ?? _TokenDefaultsM3(context).menuPadding;
    Offset menuOrigin;
    switch (textDirection) {
      case TextDirection.rtl:
        final Offset menuBarOrigin = menuBarBox.localToGlobal(menuBarBox.paintBounds.topRight, ancestor: overlay);
        if (_parent == null) {
          menuOrigin = button.localToGlobal(button.paintBounds.bottomRight, ancestor: menuBarBox);
          menuOrigin = Offset(menuBarOrigin.dx - menuOrigin.dx, menuBarOrigin.dy + menuOrigin.dy);
        } else {
          menuOrigin = button.localToGlobal(button.paintBounds.topLeft, ancestor: overlay);
          menuOrigin =
              Offset(menuBarOrigin.dx - menuOrigin.dx, menuOrigin.dy) + Offset(-menuPadding.left, -menuPadding.top);
        }
        break;
      case TextDirection.ltr:
        if (_parent == null) {
          menuOrigin = button.localToGlobal(button.paintBounds.bottomLeft, ancestor: overlay);
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
  Widget _buildPositionedMenu(BuildContext context) {
    final _TokenDefaultsM3 defaultTheme = _TokenDefaultsM3(_menuBar.context);
    final MenuThemeData menuTheme = MenuTheme.of(_menuBar.context);
    final TextDirection textDirection = Directionality.of(_menuBar.context);
    final Set<MaterialState> disabled = <MaterialState>{
      if (!_enabled) MaterialState.disabled,
    };
    // Because this is all in the overlay, we have to duplicate a lot of state
    // that exists in the context of the menu button.
    int index = 0;
    return _wrapWithPosition(
      // Use the menu button's context, not the passed-in context.
      menuButtonContext: this.context,
      child: Directionality(
        textDirection: textDirection,
        child: InheritedTheme.captureAll(
          _menuBar.context,
          Builder(
            builder: (BuildContext context) {
              return _MenuBarMarker(
                state: _menuBar,
                child: Material(
                  color: (widget.backgroundColor ?? menuTheme.menuBackgroundColor ?? defaultTheme.menuBackgroundColor)
                      .resolve(disabled),
                  shape: (widget.shape ?? menuTheme.menuShape ?? defaultTheme.menuShape).resolve(disabled),
                  elevation:
                      (widget.elevation ?? menuTheme.menuElevation ?? defaultTheme.menuElevation).resolve(disabled)!,
                  child: Padding(
                    padding: widget.padding ?? menuTheme.menuPadding ?? defaultTheme.menuPadding,
                    child: _MenuBarMenuList(
                      direction: Axis.vertical,
                      textDirection: Directionality.of(context),
                      children: widget.children.map<Widget>((Widget child) {
                        final Widget result = _MenuItemWrapper(
                          parent: this,
                          index: index,
                          child: child,
                        );
                        if (child is MenuItemGroup) {
                          index += child.members.length;
                        } else {
                          index += 1;
                        }
                        return result;
                      }).toList(),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// A widget that groups [MenuItem]s (e.g. [MenuBarButton]s and [MenuBarMenu]s)
/// into sections delineated by a [Divider].
///
/// It inserts dividers as necessary before and after the group, only inserting
/// them if there are other menu items before or after this group in the menu.
class MenuItemGroup extends StatefulWidget with MenuItem {
  /// Creates a const [MenuItemGroup].
  ///
  /// The [members] attribute is required.
  const MenuItemGroup({super.key, required this.members});

  @override
  String get label => '';

  /// The members of this [MenuItemGroup].
  ///
  /// It empty, then this group will not appear in the menu.
  @override
  final List<Widget> members;

  @override
  State<MenuItemGroup> createState() => _MenuItemGroupState();
}

class _MenuItemGroupState extends State<MenuItemGroup> with _MenuNode {
  _MenuNode? _parent;
  int _parentIndex = -1;

  @override
  final Map<int, _MenuNode> children = <int, _MenuNode>{};

  @override
  int get memberCount => widget.members.length;

  @override
  _MenuNode? get parent => _parent;

  @override
  int get parentIndex => _parentIndex;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Don't add/remove groups to the parents: they are not part of the tree,
    // only the members matter.
    final _MenuItemWrapper? wrapper = _MenuItemWrapper.maybeOf(context);
    _parent = wrapper?.parent;
    _parentIndex = wrapper?.index ?? -1;
  }

  @override
  Widget build(BuildContext context) {
    final _MenuItemWrapper? wrapper = _MenuItemWrapper.maybeOf(context);
    final _MenuBarMenuState? parent = wrapper?.parent;
    bool skipPrevious = false;
    bool skipNext = false;
    if (parent != null) {
      final int numChildren = parent.children.length;
      final int index = parentIndex;
      if (index != -1) {
        if (index == 0) {
          skipPrevious = true;
        } else if (index > 0) {
          skipPrevious = parent.children[index - 1]!.memberCount > 0;
        }
        if (index == numChildren - 1) {
          skipNext = true;
        } else if (index > 0 && index < numChildren - 1) {
          skipNext = parent.children[index + 1]!.memberCount > 0;
        }
      }
    }
    int childIndex = 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (!skipPrevious) const _MenuItemDivider(),
        ...widget.members.map<Widget>((Widget child) {
          final Widget result = _MenuItemWrapper(
            parent: parent,
            // When the group is added, the parent adds enough space in the
            // index to accommodate all of the members.
            index: parentIndex + childIndex,
            child: child,
          );
          childIndex += 1;
          return result;
        }),
        if (!skipNext) const _MenuItemDivider(),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty<Widget>('members', widget.members));
  }
}

class _MenuItemDivider extends StatelessWidget {
  const _MenuItemDivider({this.axis = Axis.vertical});

  final Axis axis;

  @override
  Widget build(BuildContext context) {
    switch (axis) {
      case Axis.horizontal:
        return VerticalDivider(width: math.max(2, 16 + Theme.of(context).visualDensity.horizontal * 4));
      case Axis.vertical:
        return Divider(height: math.max(2, 16 + Theme.of(context).visualDensity.vertical * 4));
    }
  }
}

// A widget used as the main widget for the overlay entry in the _MenuBarState.
// Since the overlay is a Stack, this widget produces a Positioned widget that
// fills the overlay, containing its own Stack to arrange the menus with.
// Positioning of the top level submenus is relative to the position of the menu
// buttons.
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
                  ...menuBar._openMenus.entries.map<Widget>(
                    (MapEntry<_MenuBarMenuState, WidgetBuilder> entry) {
                      return Builder(
                        key: ValueKey<_MenuBarMenuState>(entry.key),
                        builder: entry.value,
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

mixin _MenuNode {
  int get parentIndex;

  /// This is the parent of this node in the hierarchy, so that we can traverse
  /// ancestors.
  _MenuNode? get parent;

  /// These are the menu nodes that are the children of the menu item.
  /// This is a reverse mapping of [indices].
  Map<int, _MenuNode> get children;

  /// The number of additional members that this node represents. Will be zero
  /// for everything except groups.
  int get memberCount => 0;

  /// Adds the given child to the end of the list of children.
  void addChild(int index, _MenuNode child) {
    throw UnimplementedError("The $runtimeType class doesn't support adding menu children.");
  }

  /// Removes the given child from the list of children.
  void removeChild(int index, _MenuNode child) {
    throw UnimplementedError("The $runtimeType class doesn't support removing menu children.");
  }

  /// Return the list of ancestors for this node.
  List<_MenuNode> get ancestors {
    final List<_MenuNode> result = <_MenuNode>[];
    _MenuNode? node = this;
    while (node != null) {
      node = node.parent;
      if (node != null) {
        result.add(node);
      }
    }
    return result;
  }

  _MenuNode? nextSibling(int index) {
    assert(children.containsKey(index));
    if (index == children.length - 1) {
      return null;
    }
    final List<int> indices = children.keys.toList()..sort();
    final int listIndex = indices.indexOf(index);
    assert(listIndex == index);
    if (listIndex == indices.length - 1) {
      return null;
    }
    return children[indices[listIndex - 1]];
  }

  _MenuNode? previousSibling(int index) {
    assert(children.containsKey(index));
    if (index == 0 || index == children.length - 1) {
      return null;
    }
    final List<int> indices = children.keys.toList()..sort();
    final int listIndex = indices.indexOf(index);
    assert(listIndex == index);
    if (listIndex == 0 || listIndex == indices.length - 1) {
      return null;
    }
    return children[indices[listIndex + 1]];
  }
}

class _RootMenuNode with _MenuNode {
  /// Makes a node suitable for the root node of the tree which doesn't contain
  /// a valid [item].
  _RootMenuNode() : children = <int, _MenuNode>{};

  @override
  int get parentIndex => 0;

  @override
  _MenuNode? get parent => null;

  @override
  final Map<int, _MenuNode> children;

  @override
  void addChild(int index, _MenuNode child) {
    children[index] = child;
  }

  @override
  void removeChild(int index, _MenuNode child) {
    assert(children[index] != null);
    children.remove(index);
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
class _MenuItemWrapper extends InheritedWidget {
  const _MenuItemWrapper({
    required this.parent,
    required this.index,
    required super.child,
  });

  /// The parent that owns this _MenuItemWrapper.
  ///
  /// May be null if this is a top-level menu.
  final _MenuBarMenuState? parent;

  /// The index of this menu item in the parent's list of menu items.
  final int index;

  static _MenuItemWrapper? maybeOf(BuildContext context) {
    final _MenuItemWrapper? wrapper = context.dependOnInheritedWidgetOfExactType<_MenuItemWrapper>();
    if (wrapper == null) {
      throw FlutterError('A menu item was created without a $MenuBar.\n'
          'A menu item must have a $MenuBar ancestor, and one was not found '
          'in the widget tree. The widget that was created outside of a '
          '$MenuBar was: $context');
    }

    return wrapper;
  }

  @override
  bool updateShouldNotify(_MenuItemWrapper oldWidget) {
    return oldWidget.parent != parent || oldWidget.index != index;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<_MenuBarMenuState>('parent', parent, defaultValue: null));
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
  final List<Widget> children;

  List<Widget> _expandGroups() {
    final List<Widget> expanded = <Widget>[];
    bool lastWasGroup = false;
    for (final Widget item in children) {
      if (lastWasGroup) {
        expanded.add(const _MenuItemDivider(axis: Axis.horizontal));
      }
      if (item is MenuItemGroup) {
        if (item.members.isNotEmpty) {
          if (!lastWasGroup && expanded.isNotEmpty) {
            expanded.add(const _MenuItemDivider(axis: Axis.horizontal));
          }
          expanded.addAll(item.members);
          lastWasGroup = true;
        }
      } else {
        expanded.add(item);
        lastWasGroup = false;
      }
    }
    return expanded;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: const RoundedRectangleBorder(),
      elevation: elevation,
      child: Padding(
        padding: padding,
        child: _MenuBarMenuList(
          textDirection: Directionality.of(context),
          direction: Axis.horizontal,
          crossAxisMinSize: height,
          children: _expandGroups(),
        ),
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
    final bool isTopLevelItem = _MenuItemWrapper.maybeOf(context)?.parent == null;
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
            Text(_MenuItemWrapper.maybeOf(context)?.index.toString() ?? 'X'),
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
    required this.textDirection,
    required this.children,
    this.crossAxisMinSize = 0.0,
  });

  /// The main axis direction of the list.
  final Axis direction;

  /// The text direction to use for rendering this menu.
  final TextDirection textDirection;

  /// The minimum size in the main axis.
  ///
  /// Mainly used to enforce the main menu height.
  ///
  /// Defaults to zero.
  final double crossAxisMinSize;

  /// The menu items that fill this submenu.
  final List<Widget> children;

  @override
  State<_MenuBarMenuList> createState() => _MenuBarMenuListState();
}

class _MenuBarMenuListState extends State<_MenuBarMenuList> {
  late _MenuBarState _menuBar;

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

  BoxConstraints _getMinSizeConstraint() {
    switch (widget.direction) {
      case Axis.horizontal:
        return BoxConstraints(minHeight: widget.crossAxisMinSize);
      case Axis.vertical:
        return BoxConstraints(minWidth: widget.crossAxisMinSize);
    }
  }

  @override
  Widget build(BuildContext context) {
    int index = 0;
    return _RegisteredRenderBox(
      menuBar: _menuBar,
      child: ConstrainedBox(
        constraints: _getMinSizeConstraint(),
        child: _intrinsicCrossSize(
          child: Flex(
            textDirection: widget.textDirection,
            direction: widget.direction,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ...widget.children.map<Widget>((Widget child) {
                final Widget result = _MenuItemWrapper(parent: null, index: index, child: child);
                index += 1;
                return result;
              }).toList(),
              if (widget.direction == Axis.horizontal) const Spacer(),
            ],
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
    return menuBar.enabled;
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
    // if (!menuBar.menuIsOpen) {
    //   menuBar.openMenu(menuBar.);
    //   return;
    // }
    // final List<_MenuNode> enabledNodes = menuBar._root.descendants.where((_MenuNode node) {
    //   return menuBar.enabled &&
    //       node != menuBar._root &&
    //       (node.item.children.isNotEmpty || node.item.onSelected != null || node.item.onSelectedIntent != null);
    // }).toList();
    // if (enabledNodes.isEmpty) {
    //   return;
    // }
    // final int index = enabledNodes.indexOf(menuBar.openMenu!);
    // if (index == -1) {
    //   return;
    // }
    // if (index == enabledNodes.length - 1) {
    //   menuBar.openMenu(enabledNodes.first);
    //   return;
    // }
    // menuBar.openMenu(enabledNodes[index + 1]);
  }
}

class _MenuPreviousFocusAction extends PreviousFocusAction {
  _MenuPreviousFocusAction({required this.menuBar});

  final _MenuBarState menuBar;

  @override
  void invoke(PreviousFocusIntent intent) {
    // if (!menuBar.menuIsOpen) {
    //   // Nothing is open, select first top level menu item.
    //   if (menuBar._root.children.isEmpty) {
    //     return;
    //   }
    //   menuBar.openMenu(menuBar._root.children.last);
    //   return;
    // }
    // final List<_MenuNode> enabledNodes = menuBar._root.descendants.where((_MenuNode node) {
    //   return menuBar.enabled &&
    //       node != menuBar._root &&
    //       (node.item.children.isNotEmpty || node.item.onSelected != null || node.item.onSelectedIntent != null);
    // }).toList();
    // final List<Widget> enabledItems = enabledNodes.map<Widget>((_MenuNode node) => node.item).toList();
    // if (enabledNodes.isEmpty) {
    //   return;
    // }
    // final int index = enabledItems.indexOf(menuBar.openMenu!.item);
    // if (index == -1) {
    //   return;
    // }
    // if (index == 0) {
    //   menuBar.openMenu(enabledNodes.last);
    //   return;
    // }
    // menuBar.openMenu(enabledNodes[index - 1]);
    // return;
  }
}

class _MenuDirectionalFocusAction extends DirectionalFocusAction {
  /// Creates a [DirectionalFocusAction].
  _MenuDirectionalFocusAction({required this.menuBar});

  final _MenuBarState menuBar;

  // bool _moveForward() {
  //   if (!menuBar.menuIsOpen) {
  //     return false;
  //   }
  //   final _MenuNode? focusedItem = menuBar.focusedItem;
  //   if (focusedItem == null) {
  //     return false;
  //   }
  //   if (focusedItem.hasSubmenu && focusedItem.parent != menuBar._root) {
  //     // If no submenu is open, then arrow opens the submenu.
  //     if (focusedItem.children.isNotEmpty) {
  //       menuBar.openMenu(focusedItem.children.first);
  //     }
  //   } else {
  //     // If there's no submenu, then an arrow moves to the next top
  //     // level sibling, wrapping around if need be.
  //     final _MenuNode? next = focusedItem.topLevel.nextSibling;
  //     if (next != null) {
  //       menuBar.openMenu(next);
  //     } else {
  //       menuBar.openMenu(menuBar._root.children.isNotEmpty ? menuBar._root.children.first : null);
  //     }
  //   }
  //   return true;
  // }
  //
  // bool _moveBackward() {
  //   if (!menuBar.menuIsOpen) {
  //     return false;
  //   }
  //   final _MenuNode? focusedItem = menuBar.focusedItem;
  //   if (focusedItem == null) {
  //     return false;
  //   }
  //   // Back moves between siblings on the top level menu.
  //   // Wraps around if there is no previous.
  //   _MenuNode? previous;
  //   if (focusedItem.isTopLevel) {
  //     previous = focusedItem.previousSibling;
  //   } else {
  //     if (focusedItem.parent!.isTopLevel) {
  //       previous = focusedItem.parent!.previousSibling;
  //     } else {
  //       previous = focusedItem.parent;
  //     }
  //   }
  //   if (previous != null) {
  //     menuBar.openMenu(previous);
  //   } else {
  //     menuBar.openMenu(menuBar._root.children.isNotEmpty ? menuBar._root.children.last : null);
  //   }
  //   return true;
  // }
  //
  // bool _moveUp() {
  //   if (menuBar.openMenus) {
  //     return false;
  //   }
  //   final _MenuNode? focusedItem = menuBar.focusedItem;
  //   if (focusedItem == null) {
  //     return false;
  //   }
  //   if (focusedItem.parent == menuBar._root) {
  //     // Pressing on a top level menu closes all the menus.
  //     menuBar.openMenu(null);
  //     return true;
  //   }
  //   _MenuNode? previousFocusable = focusedItem.previousSibling;
  //   while (previousFocusable != null && !previousFocusable.focusNode!.canRequestFocus) {
  //     previousFocusable = previousFocusable.previousSibling;
  //   }
  //   if (previousFocusable != null) {
  //     menuBar.openMenu(previousFocusable);
  //   } else if (focusedItem.parent?.parent == menuBar._root) {
  //     // Pressing on a next-to-top level menu, moves to the parent.
  //     menuBar.openMenu(focusedItem.parent);
  //   }
  //   return true;
  // }
  //
  // bool _moveDown() {
  //   final _MenuNode? focusedItem = menuBar.focusedItem;
  //   if (focusedItem == null) {
  //     return false;
  //   }
  //   if (focusedItem.parent == menuBar._root) {
  //     if (!menuBar.menuIsOpen) {
  //       menuBar.openMenu(focusedItem);
  //       return true;
  //     }
  //     final List<_MenuNode> children = focusedItem.focusableChildren;
  //     if (children.isNotEmpty) {
  //       menuBar.openMenu(children[0]);
  //     }
  //     return true;
  //   }
  //   _MenuNode? nextFocusable = focusedItem.nextSibling;
  //   while (nextFocusable != null && !nextFocusable.focusNode!.canRequestFocus) {
  //     nextFocusable = nextFocusable.nextSibling;
  //   }
  //   if (nextFocusable != null) {
  //     menuBar.openMenu(nextFocusable);
  //   }
  //   return true;
  // }

  @override
  void invoke(DirectionalFocusIntent intent) {
    // final TextDirection textDirection = Directionality.of(menuBar.context);
    // switch (intent.direction) {
    //   case TraversalDirection.up:
    //     if (_moveUp()) {
    //       return;
    //     }
    //     break;
    //   case TraversalDirection.down:
    //     if (_moveDown()) {
    //       return;
    //     }
    //     break;
    //   case TraversalDirection.left:
    //     switch (textDirection) {
    //       case TextDirection.rtl:
    //         if (_moveForward()) {
    //           return;
    //         }
    //         break;
    //       case TextDirection.ltr:
    //         if (_moveBackward()) {
    //           return;
    //         }
    //         break;
    //     }
    //     break;
    //   case TraversalDirection.right:
    //     switch (textDirection) {
    //       case TextDirection.rtl:
    //         if (_moveBackward()) {
    //           return;
    //         }
    //         break;
    //       case TextDirection.ltr:
    //         if (_moveForward()) {
    //           return;
    //         }
    //         break;
    //     }
    //
    //     break;
    // }
    super.invoke(intent);
  }
}

// This class will eventually be auto-generated, so it should remain at the end
// of the file.
class _TokenDefaultsM3 extends MenuThemeData {
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
  double get barMinimumHeight {
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
