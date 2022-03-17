// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'binding.dart';
import 'framework.dart';
import 'shortcuts.dart';

// "flutter/menu" Method channel methods.
const String _kMenuSetMethod = 'Menu.SetMenu';
const String _kMenuSelectedCallbackMethod = 'Menu.SelectedCallback';
const String _kMenuItemOpenedMethod = 'Menu.Opened';
const String _kMenuItemClosedMethod = 'Menu.Closed';

// Keys for channel communication map.
const String _kIdKey = 'id';
const String _kLabelKey = 'label';
const String _kEnabledKey = 'enabled';
const String _kChildrenKey = 'children';
const String _kIsDividerKey = 'isDivider';
const String _kPlatformDefaultMenuKey = 'platformProvidedMenu';
const String _kShortcutTriggerKey = 'shortcutTrigger';
const String _kShortcutModifiersKey = 'shortcutModifiers';

// Bit masks for modifier keys sent in channel communication.
const int _kFlutterShortcutModifierMeta = 1 << 0;
const int _kFlutterShortcutModifierShift = 1 << 1;
const int _kFlutterShortcutModifierAlt = 1 << 2;
const int _kFlutterShortcutModifierControl = 1 << 3;

/// An abstract class for describing cascading menu hierarchies that are part of
/// a [PlatformMenuBar].
///
/// This type is used by the [PlatformMenuDelegate.setMenus] to accept the menu
/// hierarchy to be sent to the platform, and by [PlatformMenuBar] to define the
/// menu hierarchy.
///
/// See also:
///
///  * [PlatformMenuBar], a widget that renders menu items using
///    platform APIs instead of Flutter.
abstract class MenuItem with Diagnosticable {
  /// Allows subclasses to have const constructors.
  const MenuItem();
}

/// An abstract delegate class that can be used to set
/// [WidgetsBinding.platformMenuDelegate] to provide for managing platform
/// menus.
///
/// This can be subclassed to provide a different menu plugin than the default
/// system-provided plugin for managing [PlatformMenuBar] menus.
///
/// The [setMenus] method allows for setting of the menu hierarchy when the
/// [PlatformMenuBar] menu hierarchy changes.
///
/// This delegate doesn't handle the results of clicking on a menu item, which
/// is left to the implementor of subclasses of `PlatformMenuDelegate` to
/// handle for their implementation.
///
/// This delegate typically knows how to serialize a [PlatformSubMenu]
/// hierarchy, send it over a channel, and register for calls from the channel
/// when a menu is invoked or a submenu is opened or closed.
///
/// See [DefaultPlatformMenuDelegate] for an example of implementing one of
/// these.
///
/// See also:
///
///  * [PlatformMenuBar], the widget that adds a platform menu bar to an
///    application.
///  * [PlatformSubMenu], the class that describes a menu item with children
///    that appear in a cascading menu.
///  * [PlatformMenuBarItem], the class that describes the leaves of a menu
///    hierarchy.
abstract class PlatformMenuDelegate {
  /// A const constructor so that subclasses can have const constructors.
  const PlatformMenuDelegate();

  /// Sets the entire menu hierarchy for a platform-rendered menu bar.
  ///
  /// `topLevelMenus` is the list of menus that appear in the menu bar, which
  /// themselves can have children.
  ///
  /// See also:
  ///
  ///  * [PlatformMenuBar], the widget that adds a platform menu bar to an
  ///    application.
  ///  * [PlatformSubMenu], the class that describes a menu item with children
  ///    that appear in a cascading menu.
  ///  * [PlatformMenuBarItem], the class that describes the leaves of a menu
  ///    hierarchy.
  void setMenus(List<MenuItem> topLevelMenus);

  /// Clears any existing platform-rendered menus.
  void clearMenus();

  /// This is called by [PlatformMenuBar] when it is initialized, to be sure that
  /// only one is active at a time.
  ///
  /// If your implementation of a [PlatformMenuDelegate] can have only limited
  /// active instances, enforce it when you override this.
  ///
  /// See also:
  ///
  ///  * [unlock], where the delegate is unlocked.
  void lock(BuildContext context);

  /// This is called by [PlatformMenuBar] when it is disposed, so that another
  /// one can take over.
  ///
  /// See also:
  ///
  ///  * [lock], where the delegate is locked.
  void unlock(BuildContext context);
}

/// A mixin for doing serialization of [MenuItem] objects.
///
/// This is used by the [DefaultPlatformMenuDelegate] to serialize menu
/// hierarchies for sending to the platform for rendering.
mixin DefaultPlatformMenuDelegateSerializer {
  /// Converts the representation of this item into a map suitable for sending
  /// over the default "flutter/menu" channel used by
  /// [DefaultPlatformMenuDelegate].
  Map<String, Object?> toChannelRepresentation(DefaultPlatformMenuDelegate delegate);
}

/// The platform menu delegate that handles the built-in macOS platform menu
/// generation using the 'flutter/menu' channel.
///
/// An instance of this class is set on [WidgetsBinding.platformMenuDelegate] by
/// default when the [WidgetsBinding] is initialized.
///
/// See also:
///
///  * [PlatformMenuBar], the widget that adds a platform menu bar to an
///    application.
///  * [PlatformSubMenu], the class that describes a menu item with children
///    that appear in a cascading menu.
///  * [PlatformMenuBarItem], the class that describes the leaves of a menu
///    hierarchy.
class DefaultPlatformMenuDelegate extends PlatformMenuDelegate {
  /// Creates a const [DefaultPlatformMenuDelegate].
  DefaultPlatformMenuDelegate({MethodChannel? channel})
      : channel = channel ?? SystemChannels.menu,
        _idMap = <int, MenuItem>{} {
    this.channel.setMethodCallHandler(_methodCallHandler);
  }

  // Map of distributed IDs to menu items.
  final Map<int, MenuItem> _idMap;
  // An ever increasing value used to dole out IDs.
  int _serial = 0;

  @override
  void clearMenus() => setMenus(<MenuItem>[]);

  @override
  void setMenus(List<MenuItem> topLevelMenus) {
    _idMap.clear();
    List<Map<String, Object?>> representation;
    if (topLevelMenus.isNotEmpty) {
      representation = _expandGroups(topLevelMenus);
    } else {
      representation = const <Map<String, Object?>>[];
    }
    channel.invokeMethod<void>(_kMenuSetMethod, representation);
  }

  /// Sets the channel that the [DefaultPlatformMenuDelegate] uses to
  /// communicate with the platform.
  ///
  /// Clears any menus in the old channel before setting the new channel, and in
  /// the new channel.
  ///
  /// If the channel is the same as the one already set, nothing is cleared.
  final MethodChannel channel;

  /// Get the next serialization ID.
  ///
  /// This is called by each [DefaultPlatformMenuDelegateSerializer] when
  /// serializing a new object so that it has a unique ID.
  int getId(MenuItem item) {
    _serial += 1;
    _idMap[_serial] = item;
    return _serial;
  }

  /// Expands groups in a menu to include any necessary dividers, flattening all
  /// of the PlatformMenuItemGroups in the process.
  ///
  /// Called by each [DefaultPlatformMenuDelegateSerializer] when
  List<Map<String, Object?>> _expandGroups(List<MenuItem> children) {
    final List<Map<String, Object?>> expanded = <Map<String, Object?>>[];
    bool lastWasGroup = false;
    for (final MenuItem item in children) {
      if (lastWasGroup) {
        expanded.add(<String, Object?>{
          _kIdKey: getId(item),
          _kIsDividerKey: true,
        });
      }
      if (item is PlatformMenuItemGroup) {
        expanded.addAll(
          item.members.map<Map<String, Object?>>(
            (MenuItem item) {
              if (item is DefaultPlatformMenuDelegateSerializer) {
                return (item as DefaultPlatformMenuDelegateSerializer).toChannelRepresentation(this);
              } else {
                throw UnimplementedError(
                    'Tried to serialize a menu item that was not a DefaultPlatformMenuDelegateSerializer');
              }
            },
          ),
        );
        lastWasGroup = true;
      } else {
        if (item is DefaultPlatformMenuDelegateSerializer) {
          expanded.add((item as DefaultPlatformMenuDelegateSerializer).toChannelRepresentation(this));
        } else {
          throw UnimplementedError(
              'Tried to serialize a menu item that was not a DefaultPlatformMenuDelegateSerializer');
        }
        lastWasGroup = false;
      }
    }
    return expanded;
  }

  /// This is called by [PlatformMenuBar] when it is initialized, to be sure that
  /// only one is active at a time.
  ///
  /// Takes the [BuildContext] of the [PlatformMenuBar] that is locking this
  /// delegate.
  ///
  /// Only one instance of [PlatformMenuBar] can be using the
  /// [DefaultPlatformMenuDelegate] at a time, so this function will assert if
  /// more than one attempts to lock at the same time.
  ///
  /// See also:
  ///
  ///  * [unlock], where the delegate is unlocked.
  @override
  void lock(BuildContext context) {
    assert(
        _lockedContext == null || _lockedContext == context,
        'More than one active $PlatformMenuBar detected. Only one active '
        'platform-rendered menu bar is allowed at a time.');
    _lockedContext = context;
  }

  /// This is called by [PlatformMenuBar] when it is disposed, so that another
  /// menu bar can take over.
  ///
  /// Takes the [BuildContext] of the [PlatformMenuBar] that is unlocking this
  /// delegate.
  ///
  /// See also:
  ///
  ///  * [lock], where the delegate is locked.
  @override
  void unlock(BuildContext context) {
    assert(_lockedContext == context, 'tried to unlock the $DefaultPlatformMenuDelegate more than once.');
    _lockedContext = null;
    // Clear all the platform menus on an unlock.
    clearMenus();
  }

  BuildContext? _lockedContext;

  // Handles the method calls from the plugin to forward to selection and
  // open/close callbacks.
  Future<Object?> _methodCallHandler(MethodCall call) {
    final int id = call.arguments as int;
    assert(_idMap.containsKey(id),
        'Received a menu ${call.method} for a menu item with an ID that was not recognized: $id');
    if (!_idMap.containsKey(id)) {
      return Future<void>.value();
    }
    final MenuItem item = _idMap[id]!;
    if (item is PlatformMenuBarItem && call.method == _kMenuSelectedCallbackMethod) {
      item.onSelected?.call();
    } else if (item is PlatformSubMenu && call.method == _kMenuItemOpenedMethod) {
      item.onOpen?.call();
    } else if (item is PlatformSubMenu && call.method == _kMenuItemClosedMethod) {
      item.onClose?.call();
    }
    return Future<void>.value();
  }
}

/// A menu bar that uses the platform's native APIs to construct and render a
/// menu described by a [PlatformSubMenu]/[PlatformMenuBarItem] hierarchy.
///
/// This widget is especially useful on macOS, where a system menu is a required
/// part of every application. Flutter only includes support for macOS out of
/// the box, but support for other platforms may be provided via plugins that
/// set [WidgetsBinding.platformMenuDelegate] in their initialization.
///
/// The [children] member contains [MenuItem]s. They will not be part of the
/// widget tree, since they are not required to be widgets (even if they happen
/// to be widgets that implement [MenuItem], they still won't be part of the
/// widget tree). They are provided to configure the properties of the menus on
/// the platform menu bar.
///
/// As far as Flutter is concerned, this widget has no visual representation,
/// and intercepts no events: it just returns the [body] from its build
/// function. This is because all of the rendering, shortcuts, and event
/// handling for the menu is handled by the plugin on the host platform.
///
/// There can only be one [PlatformMenuBar] at a time using the same
/// [PlatformMenuDelegate]. It will assert if more than one is detected.
///
/// {@tool sample}
/// This example shows a [PlatformMenuBar] that contains a single top level
/// menu, containing three items for "About", a toggleable menu item for showing
/// a message, a cascading submenu with message choices, and "Quit".
///
/// **This example will only work on macOS.**
///
/// ** See code in examples/api/lib/material/platform_menu_bar/platform_menu_bar.0.dart **
/// {@end-tool}
class PlatformMenuBar extends StatefulWidget with DiagnosticableTreeMixin {
  /// Creates a const [PlatformMenuBar].
  ///
  /// The [body] and [children] attributes are required.
  const PlatformMenuBar({
    Key? key,
    required this.body,
    required this.children,
  }) : super(key: key);

  /// The widget to be rendered in the Flutter window that these platform menus
  /// are associated with.
  ///
  /// This is typically the body of the application's UI.
  final Widget body;

  /// The list of menu items that are the top level children of the
  /// [PlatformMenuBar].
  ///
  /// The `children` member contains [MenuItem]s. They will not be part
  /// of the widget tree, since they are not widgets. They are provided to
  /// configure the properties of the menus on the platform menu bar.
  final List<MenuItem> children;

  @override
  State<PlatformMenuBar> createState() => _PlatformMenuBarState();

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return children.map<DiagnosticsNode>((MenuItem child) => child.toDiagnosticsNode()).toList();
  }
}

class _PlatformMenuBarState extends State<PlatformMenuBar> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.platformMenuDelegate.lock(context);
    _updateMenu();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.platformMenuDelegate.unlock(context);
    super.dispose();
  }

  @override
  void didUpdateWidget(PlatformMenuBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final List<MenuItem> newDescendants = <MenuItem>[
      for (final MenuItem item in widget.children) ...<MenuItem>[
        item,
        if (item is PlatformSubMenu) ...item.descendants,
      ],
    ];
    final List<MenuItem> oldDescendants = <MenuItem>[
      for (final MenuItem item in oldWidget.children) ...<MenuItem>[
        item,
        if (item is PlatformSubMenu) ...item.descendants,
      ],
    ];
    if (!listEquals(newDescendants, oldDescendants)) {
      _updateMenu();
    }
  }

  // Updates the data structures for the menu and send them to the platform
  // plugin.
  void _updateMenu() {
    WidgetsBinding.instance.platformMenuDelegate.setMenus(widget.children);
  }

  @override
  Widget build(BuildContext context) {
    // PlatformMenuBar is really about managing the platform menu bar, and
    // doesn't do any rendering or event handling in Flutter.
    return widget.body;
  }
}

/// An class for representing menu items that have child submenus.
///
/// See also:
///
///  * [PlatformMenuBarItem], a class representing a leaf menu item in a
///    [PlatformMenuBar].
class PlatformSubMenu extends MenuItem with DiagnosticableTreeMixin, DefaultPlatformMenuDelegateSerializer {
  /// Creates a const [PlatformSubMenu].
  ///
  /// The [label] and [children] fields are required.
  const PlatformSubMenu({
    required this.label,
    this.enabled = true,
    this.onOpen,
    this.onClose,
    required this.children,
  });

  /// The label used by default for rendering the menu item, and for
  /// accessibility labeling.
  final String label;

  /// Whether or not this submenu is enabled.
  ///
  /// If the submenu is disabled, then it can't be opened.
  final bool enabled;

  /// The callback that is called when this submenu is opened.
  final VoidCallback? onOpen;

  /// The callback that is called when this submenu is closed.
  final VoidCallback? onClose;

  /// The child menus of this menu item.
  ///
  /// If empty, this menu item will be show as if [enabled] were false.
  final List<MenuItem> children;

  /// Returns all descendant [MenuItem]s of this item.
  List<MenuItem> get descendants => getDescendants(this);

  /// Returns all descendants of the given item.
  ///
  /// This API is supplied so that implementers of [PlatformSubMenu] can share
  /// this implementation.
  static List<MenuItem> getDescendants(PlatformSubMenu item) {
    return <MenuItem>[
      for (final MenuItem child in item.children) ...<MenuItem>[
        child,
        if (child is PlatformSubMenu) ...child.descendants,
      ],
    ];
  }

  @override
  Map<String, Object?> toChannelRepresentation(DefaultPlatformMenuDelegate delegate) {
    return serialize(this, delegate);
  }

  /// Converts the supplied object to the correct channel representation for the
  /// 'flutter/menu' channel.
  ///
  /// This API is supplied so that implementers of [PlatformSubMenu] can share
  /// this implementation.
  static Map<String, Object?> serialize(
    PlatformSubMenu item,
    DefaultPlatformMenuDelegate delegate,
  ) {
    return <String, Object?>{
      _kIdKey: delegate.getId(item),
      _kLabelKey: item.label,
      _kEnabledKey: item.enabled,
      _kChildrenKey: delegate._expandGroups(item.children),
    };
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return children.map<DiagnosticsNode>((MenuItem child) => child.toDiagnosticsNode()).toList();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('label', label));
    properties.add(FlagProperty('enabled', value: enabled, ifFalse: 'DISABLED'));
  }
}

/// An interface for [MenuItem]s that group other menu items into sections
/// delineated by dividers.
///
/// Visual dividers will be added before and after this group if other menu
/// items appear in the submenu.
class PlatformMenuItemGroup extends MenuItem with DefaultPlatformMenuDelegateSerializer {
  /// Creates a const [PlatformMenuItemGroup].
  ///
  /// The [members] field is required.
  const PlatformMenuItemGroup({required this.members});

  /// The [MenuItem]s that are members of this menu item group.
  ///
  /// If empty, this menu item will be disabled.
  final List<MenuItem> members;

  @override
  Map<String, Object?> toChannelRepresentation(DefaultPlatformMenuDelegate delegate) {
    // This method shouldn't get called, since delegate.expandGroups should skip it.
    throw UnimplementedError('Unexpected call of toChannelRepresentation for PlatformMenuItemGroup');
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty<MenuItem>('members', members));
  }
}

/// An interface for [MenuItem]s that do not have submenus, but can be
/// activated.
///
/// These [MenuItem]s are the leaves of the menu item tree, and can be activated
/// by clicking on them, or via an optional keyboard [shortcut].
class PlatformMenuBarItem extends MenuItem with DefaultPlatformMenuDelegateSerializer {
  /// Creates a const [PlatformMenuBarItem].
  ///
  /// The [label] attribute is required.
  const PlatformMenuBarItem({
    required this.label,
    this.shortcut,
    this.onSelected,
  });

  /// The required label used by default for rendering the menu item, and for
  /// accessibility labeling.
  final String label;

  /// The optional shortcut that activates this [PlatformMenuBarItem].
  final ShortcutActivator? shortcut;

  /// An optional callback that is called when this [PlatformMenuBarItem] is
  /// activated.
  ///
  /// If unset, this menu item will be disabled.
  final VoidCallback? onSelected;

  @override
  Map<String, Object?> toChannelRepresentation(DefaultPlatformMenuDelegate delegate) {
    return PlatformMenuBarItem.serialize(this, delegate);
  }

  /// Converts the given [PlatformMenuBarItem] into a data structure accepted by
  /// the 'flutter/menu' method channel method 'Menu.SetMenu'.
  ///
  /// This API is supplied so that implementers of [PlatformMenuBarItem] can share
  /// this implementation.
  static Map<String, Object?> serialize(PlatformMenuBarItem item, DefaultPlatformMenuDelegate delegate) {
    int modifiers = 0;
    int? logicalKeyId;
    final ShortcutActivator? shortcut = item.shortcut;
    if (item.shortcut != null && shortcut is SingleActivator) {
      if (shortcut.shift) {
        modifiers |= _kFlutterShortcutModifierShift;
      }
      if (shortcut.alt) {
        modifiers |= _kFlutterShortcutModifierAlt;
      }
      if (shortcut.meta) {
        modifiers |= _kFlutterShortcutModifierMeta;
      }
      if (shortcut.control) {
        modifiers |= _kFlutterShortcutModifierControl;
      }
      logicalKeyId = shortcut.trigger.keyId;
    }
    return <String, Object?>{
      _kIdKey: delegate.getId(item),
      _kLabelKey: item.label,
      _kEnabledKey: item.onSelected != null,
      if (shortcut != null) _kShortcutTriggerKey: logicalKeyId,
      if (shortcut != null) _kShortcutModifiersKey: modifiers,
    };
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('label', label));
    properties.add(DiagnosticsProperty<ShortcutActivator?>('shortcut', shortcut, defaultValue: null));
    properties.add(FlagProperty('enabled', value: onSelected != null, ifFalse: 'DISABLED'));
  }
}

/// A widget that represents a menu item that is preconfigured for the given
/// platform.
///
/// This is used to add things like the "About" and "Quit" menu items to a
/// platform menu.
///
/// The [type] enum determines which type of platform defined menu will be
/// added.
///
/// This is most useful on a macOS platform where there are many different types
/// of platform provided menu items in the standard menu setup.
///
/// In order to know if a [PlatformProvidedMenuItem] is available on a
/// particular platform, call [PlatformProvidedMenuItem.hasMenu].
///
/// If the platform does not support the given [type], then the menu item will
/// throw an [ArgumentError].
///
/// See also:
///
///  * [PlatformMenuBar] which takes these items for inclusion in a
///    platform-rendered menu bar.
class PlatformProvidedMenuItem extends PlatformMenuBarItem with DefaultPlatformMenuDelegateSerializer {
  /// Creates a const [PlatformProvidedMenuItem] of the appropriate type. Throws if the
  /// platform doesn't support the given default menu type.
  ///
  /// The [type] argument is required.
  const PlatformProvidedMenuItem({
    required this.type,
    this.enabled = true,
  }) : super(
          label: '', // The label is ignored for standard menus.
        );

  /// The type of default menu this is.
  ///
  /// See [PlatformProvidedMenuItemType] for the different types available.  Not
  /// all of the types will be available on every platform. Use [hasMenu] to
  /// determine if the current platform has a given default menu item.
  ///
  /// If the platform does not support the given [type], then the menu item will
  /// throw an [ArgumentError].
  final PlatformProvidedMenuItemType type;

  /// True if this [PlatformProvidedMenuItem] should be enabled or not.
  final bool enabled;

  /// Checks to see if the given default menu type is supported on this
  /// platform.
  static bool hasMenu(PlatformProvidedMenuItemType menu) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        return false;
      case TargetPlatform.linux:
        return const <PlatformProvidedMenuItemType>{
          PlatformProvidedMenuItemType.about,
          PlatformProvidedMenuItemType.quit,
        }.contains(menu);
      case TargetPlatform.macOS:
        return const <PlatformProvidedMenuItemType>{
          PlatformProvidedMenuItemType.about,
          PlatformProvidedMenuItemType.quit,
          PlatformProvidedMenuItemType.servicesSubmenu,
          PlatformProvidedMenuItemType.hide,
          PlatformProvidedMenuItemType.hideOtherApplications,
          PlatformProvidedMenuItemType.showAllApplications,
          PlatformProvidedMenuItemType.startSpeaking,
          PlatformProvidedMenuItemType.stopSpeaking,
          PlatformProvidedMenuItemType.toggleFullScreen,
          PlatformProvidedMenuItemType.minimizeWindow,
          PlatformProvidedMenuItemType.zoomWindow,
          PlatformProvidedMenuItemType.arrangeWindowInFront,
        }.contains(menu);
      case TargetPlatform.windows:
        return const <PlatformProvidedMenuItemType>{
          PlatformProvidedMenuItemType.about,
          PlatformProvidedMenuItemType.quit,
        }.contains(menu);
    }
  }

  @override
  Map<String, Object?> toChannelRepresentation(DefaultPlatformMenuDelegate delegate) {
    if (!hasMenu(type)) {
      throw ArgumentError(
        'Platform ${defaultTargetPlatform.name} has no standard menu for '
        '$type. Call StandardMenuItem.hasMenu to determine this before '
        'instantiating one.',
      );
    }

    return <String, Object?>{
      _kIdKey: delegate.getId(this),
      _kEnabledKey: enabled,
      _kPlatformDefaultMenuKey: type.index,
    };
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('enabled', value: enabled, ifFalse: 'DISABLED'));
  }
}

/// The list of possible standard, prebuilt menus for use in a [PlatformMenuBar].
///
/// These are menus that the platform typically provides that cannot be
/// reproduced in Flutter without calling platform functions, but are standard
/// on the platform.
///
/// Examples include things like the "Quit" or "Services" menu items on macOS.
/// Not all platforms support all menu item types. Use
/// [PlatformProvidedMenuItem.hasMenu] to know if a particular type is supported
/// on a the current platform.
///
/// Add these to your [PlatformMenuBar] using the [PlatformProvidedMenuItem]
/// class.
///
/// You can tell if the platform supports the given standard menu using the
/// [PlatformProvidedMenuItem.hasMenu] method.
// Must be kept in sync with the plugin code's enum of the same name.
enum PlatformProvidedMenuItemType {
  /// The system provided "About" menu item.
  ///
  /// On macOS, this is the `orderFrontStandardAboutPanel` default menu.
  about,

  /// The system provided "Quit" menu item.
  ///
  /// On macOS, this is the `terminate` default menu.
  ///
  /// This menu item will simply exit the application when activated.
  quit,

  /// The system provided "Services" submenu.
  ///
  /// This submenu provides a list of system provided application services.
  ///
  /// This default menu is only supported on macOS.
  servicesSubmenu,

  /// The system provided "Hide" menu item.
  ///
  /// This menu item hides the application window.
  ///
  /// On macOS, this is the `hide` default menu.
  ///
  /// This default menu is only supported on macOS.
  hide,

  /// The system provided "Hide Others" menu item.
  ///
  /// This menu item hides other application windows.
  ///
  /// On macOS, this is the `hideOtherApplications` default menu.
  ///
  /// This default menu is only supported on macOS.
  hideOtherApplications,

  /// The system provided "Show All" menu item.
  ///
  /// This menu item shows all hidden application windows.
  ///
  /// On macOS, this is the `unhideAllApplications` default menu.
  ///
  /// This default menu is only supported on macOS.
  showAllApplications,

  /// The system provided "Start Dictation..." menu item.
  ///
  /// This menu item tells the system to start the screen reader.
  ///
  /// On macOS, this is the `startSpeaking` default menu.
  ///
  /// This default menu is currently only supported on macOS.
  startSpeaking,

  /// The system provided "Stop Dictation..." menu item.
  ///
  /// This menu item tells the system to stop the screen reader.
  ///
  /// On macOS, this is the `stopSpeaking` default menu.
  ///
  /// This default menu is currently only supported on macOS.
  stopSpeaking,

  /// The system provided "Enter Full Screen" menu item.
  ///
  /// This menu item tells the system to toggle full screen mode for the window.
  ///
  /// On macOS, this is the `toggleFullScreen` default menu.
  ///
  /// This default menu is currently only supported on macOS.
  toggleFullScreen,

  /// The system provided "Minimize" menu item.
  ///
  /// This menu item tells the system to minimize the window.
  ///
  /// On macOS, this is the `performMiniaturize` default menu.
  ///
  /// This default menu is currently only supported on macOS.
  minimizeWindow,

  /// The system provided "Zoom" menu item.
  ///
  /// This menu item tells the system to expand the window size.
  ///
  /// On macOS, this is the `performZoom` default menu.
  ///
  /// This default menu is currently only supported on macOS.
  zoomWindow,

  /// The system provided "Bring To Front" menu item.
  ///
  /// This menu item tells the system to stack the window above other windows.
  ///
  /// On macOS, this is the `arrangeInFront` default menu.
  ///
  /// This default menu is currently only supported on macOS.
  arrangeWindowInFront,
}
