// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/material.dart';
library;

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'actions.dart';
import 'basic.dart';
import 'focus_manager.dart';
import 'focus_traversal.dart';
import 'framework.dart';
import 'media_query.dart';
import 'overlay.dart';
import 'scroll_position.dart';
import 'scrollable.dart';
import 'shortcuts.dart';
import 'tap_region.dart';

// Examples can assume:
// late BuildContext context;
// late List<Widget> menuItems;

const bool _kDebugMenus = false;

const Map<ShortcutActivator, Intent> _kMenuTraversalShortcuts = <ShortcutActivator, Intent>{
  SingleActivator(LogicalKeyboardKey.gameButtonA): ActivateIntent(),
  SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
  SingleActivator(LogicalKeyboardKey.arrowDown): DirectionalFocusIntent(TraversalDirection.down),
  SingleActivator(LogicalKeyboardKey.arrowUp): DirectionalFocusIntent(TraversalDirection.up),
  SingleActivator(LogicalKeyboardKey.arrowLeft): DirectionalFocusIntent(TraversalDirection.left),
  SingleActivator(LogicalKeyboardKey.arrowRight): DirectionalFocusIntent(TraversalDirection.right),
};

/// Anchor and menu information passed to [RawMenuAnchor].
@immutable
class RawMenuOverlayInfo {
  /// Creates a [RawMenuOverlayInfo].
  const RawMenuOverlayInfo({
    required this.anchorRect,
    required this.overlaySize,
    required this.tapRegionGroupId,
    this.position,
  });

  /// The position of the anchor widget that the menu is attached to, relative to
  /// the nearest ancestor [Overlay] when [RawMenuAnchor.useRootOverlay] is false,
  /// or the root [Overlay] when [RawMenuAnchor.useRootOverlay] is true.
  final ui.Rect anchorRect;

  /// The [Size] of the overlay that the menu is being shown in.
  final ui.Size overlaySize;

  /// The `position` argument passed to [MenuController.open].
  ///
  /// The position should be used to offset the menu relative to the top-left
  /// corner of the anchor.
  final Offset? position;

  /// The [TapRegion.groupId] of the [TapRegion] that wraps widgets in this menu
  /// system.
  final Object tapRegionGroupId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other.runtimeType != runtimeType) {
      return false;
    }

    return other is RawMenuOverlayInfo &&
        other.anchorRect == anchorRect &&
        other.overlaySize == overlaySize &&
        other.position == position &&
        other.tapRegionGroupId == tapRegionGroupId;
  }

  @override
  int get hashCode {
    return Object.hash(anchorRect, overlaySize, position, tapRegionGroupId);
  }
}

/// The type of builder function used by [RawMenuAnchor] to build
/// the overlay attached to a [RawMenuAnchor].
///
/// The `context` is the context that the overlay is being built in.
///
/// The `info` describes the info of the menu overlay for the
/// [RawMenuAnchor] constructor.
typedef RawMenuAnchorOverlayBuilder =
    Widget Function(BuildContext context, RawMenuOverlayInfo info);

/// The type of builder function used by [RawMenuAnchor.builder] to build the
/// widget that the [RawMenuAnchor] surrounds.
///
/// The `context` is the context in which the anchor is being built.
///
/// The `controller` is the [MenuController] that can be used to open and close
/// the menu.
///
/// The `child` is an optional child supplied as the [RawMenuAnchor.child]
/// attribute. The child is intended to be incorporated in the result of the
/// function.
typedef RawMenuAnchorChildBuilder =
    Widget Function(BuildContext context, MenuController controller, Widget? child);

// An inherited widget that provides the [RawMenuAnchor] to its descendants.
//
// Used to notify anchor descendants when the menu opens and closes, and to
// access the anchor's controller.
class _RawMenuAnchorScope extends InheritedWidget {
  const _RawMenuAnchorScope({
    required this.anchor,
    required this.isOpen,
    required this.controller,
    required super.child,
  });

  final _RawMenuAnchorState anchor;
  final bool isOpen;
  final MenuController controller;

  @override
  bool updateShouldNotify(_RawMenuAnchorScope oldWidget) {
    return anchor != oldWidget.anchor ||
        isOpen != oldWidget.isOpen ||
        controller != oldWidget.controller;
  }
}

/// A widget that wraps a child and anchors a floating menu.
///
/// The child can be any widget, but is typically a button, a text field, or, in
/// the case of context menus, the entire screen.
///
/// A [RawMenuAnchor]'s menu is shown by calling [MenuController.open] on an
/// attached [MenuController]. A [MenuController] is passed to the
/// [RawMenuAnchor.builder] function, or an externally-created [MenuController]
/// can be passed to the [controller] property.
///
/// When a [RawMenuAnchor] is opened, [overlayBuilder] is called to construct
/// the menu contents within an [Overlay]. The [Overlay] allows the menu to
/// "float" on top of other widgets. The `info` argument passed to
/// [overlayBuilder] provides the anchor's [Rect], the [Size] of the overlay,
/// the [TapRegion.groupId] used by members of the menu system, and the
/// [position] argument passed to [MenuController.open].
///
/// If [MenuController.open] is called with a `position` argument, it will be
/// passed to the `info` argument of the `overlayBuilder` function.
///
/// Users are responsible for managing the positioning, semantics, and focus of
/// the menu.
///
/// {@tool dartpad}
///
/// This example uses a [RawMenuAnchor] to build an a basic select menu with
/// four items.
///
/// ** See code in examples/api/lib/widgets/raw_menu_anchor/raw_menu_anchor.0.dart **
/// {@end-tool}
class RawMenuAnchor extends _RawMenuAnchor {
  /// A [RawMenuAnchor] that delegates overlay construction to an [overlayBuilder].
  ///
  /// The [overlayBuilder] should not be null.
  const RawMenuAnchor({
    super.key,
    super.controller,
    super.childFocusNode,
    super.consumeOutsideTaps = false,
    this.onOpen,
    this.onClose,
    this.useRootOverlay = false,
    this.builder,
    required this.overlayBuilder,
    this.child,
  });

  /// A callback that is invoked when the menu is opened.
  final VoidCallback? onOpen;

  /// A callback that is invoked when the menu is closed.
  final VoidCallback? onClose;

  /// A builder that builds the widget that this [RawMenuAnchor] surrounds.
  ///
  /// Typically, this is a button used to open the menu by calling
  /// [MenuController.open] on the `controller` passed to the builder.
  ///
  /// If not supplied, then the [RawMenuAnchor] will be the size that its parent
  /// allocates for it.
  final RawMenuAnchorChildBuilder? builder;

  /// The optional child to be passed to the [builder].
  ///
  /// Supply this child if there is a portion of the widget tree built in
  /// [builder] that doesn't depend on the `controller` or `context` supplied to
  /// the [builder]. It will be more efficient, since Flutter doesn't then need
  /// to rebuild this child when those change.
  final Widget? child;

  /// The [overlayBuilder] function is passed a [RawMenuOverlayInfo] object that
  /// defines the anchor's [Rect], the [Size] of the overlay, the
  /// [TapRegion.groupId] for the menu system, and the position [Offset] passed
  /// to [MenuController.open].
  ///
  /// To ensure taps are properly consumed, the
  /// [RawMenuOverlayInfo.tapRegionGroupId] should be passed to a [TapRegion]
  /// widget that wraps the menu panel.
  ///
  /// ```dart
  /// TapRegion(
  ///   groupId: position.tapRegionGroupId,
  ///   onTapOutside: (PointerDownEvent event) {
  ///     MenuController.maybeOf(context)?.close();
  ///   },
  ///   child: Column(children: menuItems),
  /// )
  /// ```
  final RawMenuAnchorOverlayBuilder overlayBuilder;

  /// {@template flutter.widgets.RawMenuAnchor.useRootOverlay}
  /// Whether the menu panel should be rendered in the root [Overlay].
  ///
  /// When true, the menu is mounted in the root overlay. Rendering the menu in
  /// the root overlay prevents the menu from being obscured by other widgets.
  ///
  /// When false, the menu is rendered in the nearest ancestor [Overlay].
  ///
  /// Submenus will always use the same overlay as their top-level ancestor, so
  /// setting a [useRootOverlay] value on a submenu will have no effect.
  /// {@endtemplate}
  ///
  /// Defaults to false on overlay menus.
  final bool useRootOverlay;

  @override
  State<RawMenuAnchor> createState() => _RawMenuAnchorOverlayState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ObjectFlagProperty<MenuController>.has('controller', controller));
    properties.add(ObjectFlagProperty<FocusNode>.has('focusNode', childFocusNode));
    properties.add(
      FlagProperty(
        'useRootOverlay',
        value: useRootOverlay,
        ifFalse: 'use nearest overlay',
        ifTrue: 'use root overlay',
      ),
    );
  }
}

// Base class that provides the common interface and state for both types of
// [RawMenuAnchor]s, [RawMenuAnchor] and [RawMenuAnchorGroup].
abstract class _RawMenuAnchor extends StatefulWidget {
  const _RawMenuAnchor({
    super.key,
    this.childFocusNode,
    this.consumeOutsideTaps = false,
    this.controller,
  });

  // The [FocusNode] attached to the widget that takes focus when the
  // menu is opened or closed.
  //
  // If not supplied, the anchor will not retain focus when the menu is opened.
  final FocusNode? childFocusNode;

  // Whether or not a tap event that closes the menu will be permitted to
  // continue on to the gesture arena.
  //
  // If false, then tapping outside of a menu when the menu is open will both
  // close the menu, and allow the tap to participate in the gesture arena.
  //
  // If true, then it will only close the menu, and the tap event will be
  // consumed.
  //
  // Defaults to false.
  final bool consumeOutsideTaps;

  // An optional [MenuController] that allows opening and closing of the menu
  // from other widgets.
  //
  // If not supplied, [RawMenuAnchor] will create and manage a [MenuController].
  final MenuController? controller;

  @override
  State<_RawMenuAnchor> createState();
}

@optionalTypeArgs
sealed class _RawMenuAnchorState<T extends _RawMenuAnchor> extends State<T> {
  final List<_RawMenuAnchorState> _anchorChildren = <_RawMenuAnchorState>[];
  _RawMenuAnchorState? _parent;
  ScrollPosition? _scrollPosition;
  Size? _viewSize;
  MenuController? _internalMenuController;
  MenuController get _menuController {
    return widget.controller ?? (_internalMenuController ??= MenuController());
  }

  bool get _isRoot => _parent == null;
  bool get _isOpen;
  _RawMenuAnchorState get _root {
    _RawMenuAnchorState anchor = this;
    while (anchor._parent != null) {
      anchor = anchor._parent!;
    }
    return anchor;
  }

  @override
  void initState() {
    super.initState();
    _menuController._attach(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final _RawMenuAnchorState? newParent = MenuController.maybeOf(context)?._anchor;
    if (newParent != _parent) {
      assert(
        newParent != this,
        'A MenuController should only be attached to one anchor at a time.',
      );
      _parent?._removeChild(this);
      _parent = newParent;
      _parent?._addChild(this);
    }

    _scrollPosition?.isScrollingNotifier.removeListener(_handleScroll);
    _scrollPosition = Scrollable.maybeOf(context)?.position;
    _scrollPosition?.isScrollingNotifier.addListener(_handleScroll);
    final Size newSize = MediaQuery.sizeOf(context);
    if (_viewSize != null && newSize != _viewSize) {
      // Close the menus if the view changes size.
      _root.close();
    }
    _viewSize = newSize;
  }

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _internalMenuController)?._detach(this);
      if (widget.controller != null) {
        _internalMenuController = null;
      }
      _menuController._attach(this);
    }
    assert(_menuController._anchor == this);
    assert(widget.controller == null || _internalMenuController == null);
  }

  @override
  void dispose() {
    assert(_debugMenuInfo('Disposing of $this'));
    if (_isOpen) {
      close(inDispose: true);
    }

    _parent?._removeChild(this);
    _parent = null;
    _anchorChildren.clear();
    _menuController._detach(this);
    _internalMenuController = null;
    super.dispose();
  }

  void _addChild(_RawMenuAnchorState child) {
    assert(_isRoot || _debugMenuInfo('Added root child: $child'));
    assert(!_anchorChildren.contains(child));
    _anchorChildren.add(child);
    assert(_debugMenuInfo('Added:\n${child.widget.toStringDeep()}'));
    assert(_debugMenuInfo('Tree:\n${widget.toStringDeep()}'));
  }

  void _removeChild(_RawMenuAnchorState child) {
    assert(_isRoot || _debugMenuInfo('Removed root child: $child'));
    assert(_anchorChildren.contains(child));
    assert(_debugMenuInfo('Removing:\n${child.widget.toStringDeep()}'));
    _anchorChildren.remove(child);
    assert(_debugMenuInfo('Tree:\n${widget.toStringDeep()}'));
  }

  void _handleScroll() {
    // If an ancestor scrolls, and we're a root anchor, then close the menus.
    // Don't just close it on *any* scroll, since we want to be able to scroll
    // menus themselves if they're too big for the view.
    if (_isRoot) {
      close();
    }
  }

  void _childChangedOpenState() {
    _parent?._childChangedOpenState();
    if (SchedulerBinding.instance.schedulerPhase != SchedulerPhase.persistentCallbacks) {
      setState(() {
        // Mark dirty now, but only if not in a build.
      });
    } else {
      SchedulerBinding.instance.addPostFrameCallback((Duration timestamp) {
        setState(() {
          // Mark dirty
        });
      });
    }
  }

  /// Open the menu, optionally at a position relative to the [RawMenuAnchor].
  ///
  /// Call this when the menu should be shown to the user.
  ///
  /// The optional `position` argument should specify the location of the menu in
  /// the local coordinates of the [RawMenuAnchor].
  @protected
  void open({Offset? position});

  @protected
  void close({bool inDispose = false});

  @protected
  void closeChildren({bool inDispose = false}) {
    assert(_debugMenuInfo('Closing children of $this${inDispose ? ' (dispose)' : ''}'));
    for (final _RawMenuAnchorState child in List<_RawMenuAnchorState>.from(_anchorChildren)) {
      child.close(inDispose: inDispose);
    }
  }

  void _handleOutsideTap(PointerDownEvent pointerDownEvent) {
    assert(_debugMenuInfo('Tapped Outside ${widget.controller}'));
    closeChildren();
  }

  // Used to build the anchor widget in subclasses.
  Widget _buildAnchor(BuildContext context);

  @override
  @nonVirtual
  Widget build(BuildContext context) {
    return _RawMenuAnchorScope(
      anchor: this,
      isOpen: _isOpen,
      controller: _menuController,
      child: Actions(
        actions: <Type, Action<Intent>>{
          // Check if open to allow DismissIntent to bubble when the menu is
          // closed.
          if (_isOpen) DismissIntent: DismissMenuAction(controller: _menuController),
        },
        child: Builder(builder: _buildAnchor),
      ),
    );
  }

  @override
  String toString({DiagnosticLevel? minLevel}) => describeIdentity(this);
}

class _RawMenuAnchorOverlayState extends _RawMenuAnchorState<RawMenuAnchor> {
  // This is the global key that is used later to determine the bounding rect
  // for the anchor's region that the CustomSingleChildLayout's delegate
  // uses to determine where to place the menu on the screen and to avoid the
  // view's edges.
  final GlobalKey _anchorKey = GlobalKey<_RawMenuAnchorOverlayState>(
    debugLabel: kReleaseMode ? null : 'MenuAnchor',
  );
  final OverlayPortalController _overlayController = OverlayPortalController(
    debugLabel: kReleaseMode ? null : 'MenuAnchor controller',
  );

  bool get useRootOverlay {
    if (_parent case _RawMenuAnchorOverlayState(useRootOverlay: final bool useRoot)) {
      return useRoot;
    }

    assert(_isRootAnchor);
    return widget.useRootOverlay;
  }

  Offset? _menuPosition;
  bool get _isRootAnchor => _parent is! _RawMenuAnchorOverlayState;

  @override
  bool get _isOpen => _overlayController.isShowing;

  @override
  Widget _buildAnchor(BuildContext context) {
    final Widget child = Shortcuts(
      includeSemantics: false,
      shortcuts: _kMenuTraversalShortcuts,
      child: TapRegion(
        groupId: _root._menuController,
        consumeOutsideTaps: _root._isOpen && widget.consumeOutsideTaps,
        onTapOutside: _handleOutsideTap,
        child: Builder(
          key: _anchorKey,
          builder: (BuildContext context) {
            return widget.builder?.call(context, _menuController, widget.child) ??
                widget.child ??
                const SizedBox();
          },
        ),
      ),
    );

    if (useRootOverlay) {
      return OverlayPortal.targetsRootOverlay(
        controller: _overlayController,
        overlayChildBuilder: _buildOverlay,
        child: child,
      );
    } else {
      return OverlayPortal(
        controller: _overlayController,
        overlayChildBuilder: _buildOverlay,
        child: child,
      );
    }
  }

  Widget _buildOverlay(BuildContext context) {
    final BuildContext anchorContext = _anchorKey.currentContext!;
    final RenderBox overlay =
        Overlay.of(anchorContext, rootOverlay: useRootOverlay).context.findRenderObject()!
            as RenderBox;
    final RenderBox anchorBox = anchorContext.findRenderObject()! as RenderBox;
    final ui.Offset upperLeft = anchorBox.localToGlobal(Offset.zero, ancestor: overlay);
    final ui.Offset bottomRight = anchorBox.localToGlobal(
      anchorBox.size.bottomRight(Offset.zero),
      ancestor: overlay,
    );

    final RawMenuOverlayInfo info = RawMenuOverlayInfo(
      anchorRect: Rect.fromPoints(upperLeft, bottomRight),
      overlaySize: overlay.size,
      position: _menuPosition,
      tapRegionGroupId: _root._menuController,
    );

    return widget.overlayBuilder(context, info);
  }

  @override
  void open({Offset? position}) {
    assert(_menuController._anchor == this);
    if (_isOpen) {
      if (position == _menuPosition) {
        assert(_debugMenuInfo("Not opening $this because it's already open"));
        // The menu is open and not being moved, so just return.
        return;
      }

      // The menu is already open, but we need to move to another location, so
      // close it first.
      close();
    }

    assert(_debugMenuInfo('Opening $this at ${position ?? Offset.zero}'));

    // Close all siblings.
    _parent?.closeChildren();
    assert(!_overlayController.isShowing);

    _parent?._childChangedOpenState();
    _menuPosition = position;
    _overlayController.show();

    if (_isRootAnchor) {
      widget.childFocusNode?.requestFocus();
    }

    widget.onOpen?.call();
    if (mounted && SchedulerBinding.instance.schedulerPhase != SchedulerPhase.persistentCallbacks) {
      setState(() {
        // Mark dirty to notify MenuController dependents.
      });
    }
  }

  // Close the menu.
  //
  // Call this when the menu should be closed. Has no effect if the menu is
  // already closed.
  @override
  void close({bool inDispose = false}) {
    assert(_debugMenuInfo('Closing $this'));
    if (!_isOpen) {
      return;
    }

    closeChildren(inDispose: inDispose);
    // Don't hide if we're in the middle of a build.
    if (SchedulerBinding.instance.schedulerPhase != SchedulerPhase.persistentCallbacks) {
      _overlayController.hide();
    } else if (!inDispose) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _overlayController.hide();
      }, debugLabel: 'MenuAnchor.hide');
    }

    if (!inDispose) {
      // Notify that _childIsOpen changed state, but only if not
      // currently disposing.
      _parent?._childChangedOpenState();
      widget.onClose?.call();
      if (mounted &&
          SchedulerBinding.instance.schedulerPhase != SchedulerPhase.persistentCallbacks) {
        setState(() {
          // Mark dirty, but only if mounted and not in a build.
        });
      }
    }
  }

  @override
  String toString({DiagnosticLevel? minLevel}) {
    return describeIdentity(this);
  }
}

/// Creates a menu anchor that is always visible and is not displayed in an
/// [OverlayPortal].
///
/// A [RawMenuAnchorGroup] can be used to create a menu bar that handles
/// external taps and keyboard shortcuts, but defines no default focus or
/// keyboard traversal to enable more flexibility.
///
/// When a [MenuController] is given to a [RawMenuAnchorGroup],
///  - [MenuController.open] has no effect.
///  - [MenuController.close] closes all child [RawMenuAnchor]s that are open
///  - [MenuController.isOpen] reflects whether any child [RawMenuAnchor] is
///    open.
///
/// A [child] must be provided.
///
/// {@tool dartpad}
///
/// This example uses [RawMenuAnchorGroup] to build a menu bar with four
/// submenus. Hovering over menu items opens their respective submenus.
/// Selecting a menu item will close the menu and update the selected item text.
///
/// ** See code in examples/api/lib/widgets/raw_menu_anchor/raw_menu_anchor.3.dart **
/// {@end-tool}
///
/// See also:
/// * [MenuBar], which wraps this widget with standard layout and semantics and
///   focus management.
/// * [MenuAnchor], a menu anchor that follows the Material Design guidelines.
/// * [RawMenuAnchor], a widget that defines a region attached to a floating
///   submenu.
class RawMenuAnchorGroup extends _RawMenuAnchor {
  /// Creates a [RawMenuAnchorGroup].
  const RawMenuAnchorGroup({super.key, super.controller, required this.child})
    : super(consumeOutsideTaps: false);

  /// The child displayed by the [RawMenuAnchorGroup].
  ///
  /// To access the [MenuController] from the [child], place the child in a
  /// builder and call [MenuController.maybeOf].
  final Widget child;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ObjectFlagProperty<MenuController>.has('controller', controller));
  }

  @override
  State<RawMenuAnchorGroup> createState() => _RawMenuAnchorGroupState();
}

class _RawMenuAnchorGroupState extends _RawMenuAnchorState<RawMenuAnchorGroup> {
  @override
  bool get _isOpen => _anchorChildren.any((_RawMenuAnchorState child) => child._isOpen);

  @override
  void close({bool inDispose = false}) {
    if (!_isOpen) {
      return;
    }
    closeChildren(inDispose: inDispose);
    if (!inDispose) {
      if (SchedulerBinding.instance.schedulerPhase != SchedulerPhase.persistentCallbacks) {
        setState(() {
          // Mark dirty, but only if mounted and not in a build.
        });
      } else {
        SchedulerBinding.instance.addPostFrameCallback((Duration timestamp) {
          if (mounted) {
            setState(() {
              // Mark dirty.
            });
          }
        });
      }
    }
  }

  @override
  void open({Offset? position}) {
    assert(_menuController._anchor == this);
    // Menu nodes are always open, so this is a no-op.
    return;
  }

  @override
  Widget _buildAnchor(BuildContext context) {
    return TapRegion(
      groupId: _root._menuController,
      consumeOutsideTaps: _root._isOpen && widget.consumeOutsideTaps,
      onTapOutside: _handleOutsideTap,
      child: widget.child,
    );
  }
}

/// A controller used to manage a menu created by [MenuBar], [MenuAnchor], or
/// [RawMenuAnchor].
///
/// A [MenuController] is used to control and interrogate a menu after it has
/// been created, with methods such as [open] and [close], and state accessors
/// like [isOpen].
///
/// [MenuController.maybeOf] can be used to retrieve a controller from the
/// [BuildContext] of a widget that is a descendant of a [MenuAnchor],
/// [MenuBar], [SubmenuButton], or [RawMenuAnchor]. By doing so, the widget will
/// establish a dependency relationship that will rebuild the widget when the
/// parent menu opens and closes.
///
/// See also:
///
/// * [MenuAnchor], a menu anchor that follows the Material Design guidelines.
/// * [MenuBar], a widget that creates a menu bar that can take an optional
///   [MenuController].
/// * [SubmenuButton], a Material widget that has a button that manages a submenu.
/// * [RawMenuAnchor], a generic widget that defines a region that build an overlay.
class MenuController {
  /// The anchor that this controller controls.
  ///
  /// This is set automatically when a [MenuController] is given to the anchor
  /// it controls.
  _RawMenuAnchorState? _anchor;

  /// Whether or not the menu associated with this [MenuController] is open.
  bool get isOpen => _anchor?._isOpen ?? false;

  /// Opens the menu that this [MenuController] is associated with.
  ///
  /// If `position` is given, then the menu will open at the position given, in
  /// the coordinate space of the root overlay.
  ///
  /// If given, the `position` will override the [RawMenuAnchor.alignmentOffset]
  /// given to the [RawMenuAnchor].
  ///
  /// If the menu's anchor point (either a [MenuBar], [MenuAnchor], or a
  /// [RawMenuAnchor]) is scrolled by an ancestor, or the view changes size,
  /// then any open menu will automatically close.
  void open({Offset? position}) {
    assert(_anchor != null);
    _anchor!.open(position: position);
  }

  /// Close the menu that this [MenuController] is associated with.
  ///
  /// Associating with a menu is done by passing a [MenuController] to a
  /// [RawMenuAnchor]. A [MenuController] is also be received by the
  /// [RawMenuAnchor.builder] when invoked.
  ///
  /// If the menu's anchor point (either a [MenuBar], [MenuAnchor], or a
  /// [RawMenuAnchor]) is scrolled by an ancestor, or the view changes size,
  /// then any open menu will automatically close.
  void close() {
    _anchor?.close();
  }

  /// Close the children of the menu associated with this [MenuController],
  /// without closing the menu itself.
  void closeChildren() {
    assert(_anchor != null);
    _anchor!.closeChildren();
  }

  // ignore: use_setters_to_change_properties
  void _attach(_RawMenuAnchorState anchor) {
    _anchor = anchor;
  }

  void _detach(_RawMenuAnchorState anchor) {
    if (_anchor == anchor) {
      _anchor = null;
    }
  }

  /// Returns the [MenuController] of the ancestor [RawMenuAnchor] nearest to
  /// the given `context`, if one exists. Otherwise, returns null.
  ///
  /// If `createDependency` is true, then the provided [BuildContext] will
  /// rebuild when the menu opens and closes, or when the [MenuController]
  /// changes.
  static MenuController? maybeOf(BuildContext context, {bool createDependency = false}) {
    if (createDependency) {
      return context.dependOnInheritedWidgetOfExactType<_RawMenuAnchorScope>()?.controller;
    } else {
      return context.getInheritedWidgetOfExactType<_RawMenuAnchorScope>()?.controller;
    }
  }

  @override
  String toString() => describeIdentity(this);
}

/// An action that closes all the menus associated with the given
/// [MenuController].
///
/// See also:
///
///  * [MenuAnchor], a material-themed widget that hosts a cascading submenu.
///  * [MenuBar], a widget that defines a menu bar with cascading submenus.
///  * [RawMenuAnchor], a widget that hosts a cascading submenu.
///  * [MenuController], a controller used to manage menus created by a
///    [RawMenuAnchor].
class DismissMenuAction extends DismissAction {
  /// Creates a [DismissMenuAction].
  DismissMenuAction({required this.controller});

  /// The [MenuController] that manages the menu which should be dismissed upon
  /// invocation.
  final MenuController controller;

  @override
  void invoke(DismissIntent intent) {
    controller._anchor!._root.close();
  }

  @override
  bool isEnabled(DismissIntent intent) {
    return controller._anchor != null;
  }
}

/// A debug print function, which should only be called within an assert, like
/// so:
///
///   assert(_debugMenuInfo('Debug Message'));
///
/// so that the call is entirely removed in release builds.
///
/// Enable debug printing by setting [_kDebugMenus] to true at the top of the
/// file.
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
