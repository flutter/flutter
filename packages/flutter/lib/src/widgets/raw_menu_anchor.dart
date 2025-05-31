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
// late RawMenuOverlayInfo info;

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

/// Signature for the builder function used by [RawMenuAnchor.overlayBuilder] to
/// build a menu's overlay.
///
/// The `context` is the context that the overlay is being built in.
///
/// The `info` describes the anchor's [Rect], the [Size] of the overlay,
/// the [TapRegion.groupId] used by members of the menu system, and the
/// `position` argument passed to [MenuController.open].
typedef RawMenuAnchorOverlayBuilder =
    Widget Function(BuildContext context, RawMenuOverlayInfo info);

/// Signature for the builder function used by [RawMenuAnchor.builder] to build
/// the widget that the [RawMenuAnchor] surrounds.
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

/// Signature for the callback used by [RawMenuAnchor.onOpenRequested] to
/// intercept requests to open a menu.
///
/// See [RawMenuAnchor.onOpenRequested] for more information.
typedef RawMenuAnchorOpenRequestedCallback =
    void Function(Offset? position, VoidCallback showOverlay);

/// Signature for the callback used by [RawMenuAnchor.onCloseRequested] to
/// intercept requests to close a menu.
///
/// See [RawMenuAnchor.onCloseRequested] for more information.
typedef RawMenuAnchorCloseRequestedCallback = void Function(VoidCallback hideOverlay);

// An InheritedWidget used to notify anchor descendants when a menu opens
// and closes, and to pass the anchor's controller to descendants.
class _MenuControllerScope extends InheritedWidget {
  const _MenuControllerScope({
    required this.isOpen,
    required this.controller,
    required super.child,
  });

  final bool isOpen;
  final MenuController controller;

  @override
  bool updateShouldNotify(_MenuControllerScope oldWidget) {
    return isOpen != oldWidget.isOpen;
  }
}

/// A widget that wraps a child and anchors a floating menu.
///
/// The child can be any widget, but is typically a button, a text field, or, in
/// the case of context menus, the entire screen.
///
/// The menu overlay of a [RawMenuAnchor] is shown by calling
/// [MenuController.open] on an attached [MenuController].
///
/// When a [RawMenuAnchor] is opened, [overlayBuilder] is called to construct
/// the menu contents within an [Overlay]. The [Overlay] allows the menu to
/// "float" on top of other widgets. The `info` argument passed to
/// [overlayBuilder] provides the anchor's [Rect], the [Size] of the overlay,
/// the [TapRegion.groupId] used by members of the menu system, and the
/// `position` argument passed to [MenuController.open].
///
/// If [MenuController.open] is called with a `position` argument, it will be
/// passed to the `info` argument of the `overlayBuilder` function.
///
/// The [RawMenuAnchor] does not manage semantics and focus of the menu.
///
/// ### Adding animations to menus
///
/// A [RawMenuAnchor] has no knowledge of animations, as evident from its APIs,
/// which don't involve [AnimationController] at all. It only knows whether the
/// overlay is shown or hidden.
///
/// If another widget intends to implement a menu with opening and closing
/// transitions, [RawMenuAnchor]'s overlay should remain visible throughout both
/// the opening and closing animation durations.
///
/// This means that the `showOverlay` callback passed to [onOpenRequested]
/// should be called before the first frame of the opening animation.
/// Conversely, `hideOverlay` within [onCloseRequested] should only be called
/// after the closing animation has completed.
///
/// This also means that, if [MenuController.open] is called while the overlay
/// is already visible, [RawMenuAnchor] has no way of knowing whether the menu
/// is currently opening, closing, or stably displayed. The parent widget will
/// need to manage additional information (such as the state of an
/// [AnimationController]) to determine how to respond in such scenarios.
///
/// To programmatically control a [RawMenuAnchor], like opening or closing it,
/// or checking its state, you can get its associated [MenuController]. Use
/// `MenuController.maybeOf(BuildContext context)` to retrieve the controller
/// for the closest [RawMenuAnchor] ancestor of a given `BuildContext`. More
/// detailed usage of [MenuController] is available in its class documentation.
///
/// {@tool dartpad}
///
/// This example uses a [RawMenuAnchor] to build a basic select menu with four
/// items.
///
/// ** See code in examples/api/lib/widgets/raw_menu_anchor/raw_menu_anchor.0.dart **
/// {@end-tool}
///
/// {@tool dartpad}
///
/// This example uses [RawMenuAnchor.onOpenRequested] and
/// [RawMenuAnchor.onCloseRequested] to build an animated menu.
///
/// ** See code in examples/api/lib/widgets/raw_menu_anchor/raw_menu_anchor.2.dart **
/// {@end-tool}
///
/// {@tool dartpad}
///
/// This example uses [RawMenuAnchor.onOpenRequested] and
/// [RawMenuAnchor.onCloseRequested] to build an animated nested menu.
///
/// ** See code in examples/api/lib/widgets/raw_menu_anchor/raw_menu_anchor.3.dart **
/// {@end-tool}
class RawMenuAnchor extends StatefulWidget {
  /// A [RawMenuAnchor] that delegates overlay construction to an [overlayBuilder].
  ///
  /// The [overlayBuilder] must not be null.
  const RawMenuAnchor({
    super.key,
    this.childFocusNode,
    this.consumeOutsideTaps = false,
    this.onOpen,
    this.onClose,
    this.onOpenRequested = _defaultOnOpenRequested,
    this.onCloseRequested = _defaultOnCloseRequested,
    this.useRootOverlay = false,
    this.builder,
    required this.controller,
    required this.overlayBuilder,
    this.child,
  });

  /// Called when the menu overlay is shown.
  ///
  /// When [MenuController.open] is called, [onOpenRequested] is invoked with a
  /// `showOverlay` callback that, when called, shows the menu overlay and
  /// triggers [onOpen].
  ///
  /// The default implementation of [onOpenRequested] calls `showOverlay`
  /// synchronously, thereby calling [onOpen] synchronously. In this case,
  /// [onOpen] is called regardless of whether the menu overlay is already
  /// showing.
  ///
  /// Custom implementations of [onOpenRequested] can delay the call to
  /// `showOverlay`, or not call it at all, in which case [onOpen] will not be
  /// called. Calling `showOverlay` after disposal is a no-op, and will not
  /// trigger [onOpen].
  ///
  /// A typical usage is to respond when the menu first becomes interactive,
  /// such as by setting focus to a menu item.
  final VoidCallback? onOpen;

  /// Called when the menu overlay is hidden.
  ///
  /// When [MenuController.close] is called, [onCloseRequested] is invoked with
  /// a `hideOverlay` callback that, when called, hides the menu overlay and
  /// triggers [onClose].
  ///
  /// The default implementation of [onCloseRequested] calls `hideOverlay`
  /// synchronously, thereby calling [onClose] synchronously. In this case,
  /// [onClose] is called regardless of whether the menu overlay is already
  /// hidden.
  ///
  /// Custom implementations of [onCloseRequested] can delay the call to
  /// `hideOverlay` or not call it at all, in which case [onClose] will not be
  /// called. Calling `hideOverlay` after disposal is a no-op, and will not
  /// trigger [onClose].
  final VoidCallback? onClose;

  /// Called when a request is made to open the menu.
  ///
  /// This callback is triggered every time [MenuController.open] is called,
  /// even when the menu overlay is already showing. As a result, this callback
  /// is a good place to begin menu opening animations, or observe when a menu
  /// is repositioned.
  ///
  /// After an open request is intercepted, the `showOverlay` callback should be
  /// called when the menu overlay (the widget built by [overlayBuilder]) is
  /// ready to be shown. This can occur immediately (the default behavior), or
  /// after a delay. Calling `showOverlay` sets [MenuController.isOpen] to true,
  /// builds (or rebuilds) the overlay widget, and shows the menu overlay at the
  /// front of the overlay stack.
  ///
  /// If `showOverlay` is not called, the menu will stay hidden. Calling
  /// `showOverlay` after disposal is a no-op, meaning it will not trigger
  /// [onOpen] or show the menu overlay.
  ///
  /// If a [RawMenuAnchor] is used in a themed menu that plays an opening
  /// animation, the themed menu should show the overlay before starting the
  /// opening animation, since the animation plays on the overlay itself.
  ///
  /// The `position` argument is the `position` that [MenuController.open] was
  /// called with.
  ///
  /// A typical [onOpenRequested] consists of the following steps:
  ///
  ///  1. Optional delay.
  ///  2. Call `showOverlay` (whose call chain eventually invokes [onOpen]).
  ///  3. Optionally start the opening animation.
  ///
  /// Defaults to a callback that immediately shows the menu.
  final RawMenuAnchorOpenRequestedCallback onOpenRequested;

  /// Called when a request is made to close the menu.
  ///
  /// This callback is triggered every time [MenuController.close] is called,
  /// regardless of whether the overlay is already hidden. As a result, this
  /// callback can be used to add a delay or a closing animation before the menu
  /// is hidden.
  ///
  /// If the menu is not closed, this callback will also be called when the root
  /// menu anchor is scrolled and when the screen is resized.
  ///
  /// After a close request is intercepted and closing behaviors have completed,
  /// the `hideOverlay` callback should be called. This callback sets
  /// [MenuController.isOpen] to false and hides the menu overlay widget. If the
  /// [RawMenuAnchor] is used in a themed menu that plays a closing animation,
  /// `hideOverlay` should be called after the closing animation has ended,
  /// since the animation plays on the overlay itself. This means that
  /// [MenuController.isOpen] will stay true while closing animations are
  /// running.
  ///
  /// Calling `hideOverlay` after disposal is a no-op, meaning it will not
  /// trigger [onClose] or hide the menu overlay.
  ///
  /// Typically, [onCloseRequested] consists of the following steps:
  ///
  ///  1. Optionally start the closing animation and wait for it to complete.
  ///  2. Call `hideOverlay` (whose call chain eventually invokes [onClose]).
  ///
  /// Throughout the closing sequence, menus should typically not be focusable
  /// or interactive.
  ///
  /// Defaults to a callback that immediately hides the menu.
  final RawMenuAnchorCloseRequestedCallback onCloseRequested;

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

  /// Called to build and position the menu overlay.
  ///
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
  ///   groupId: info.tapRegionGroupId,
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

  /// The [FocusNode] attached to the widget that takes focus when the
  /// menu is opened or closed.
  ///
  /// If not supplied, the anchor will not retain focus when the menu is opened.
  final FocusNode? childFocusNode;

  /// Whether a tap event that closes the menu will be permitted to continue on
  /// to the gesture arena.
  ///
  /// If false, then tapping outside of a menu when the menu is open will both
  /// close the menu, and allow the tap to participate in the gesture arena.
  ///
  /// If true, then it will only close the menu, and the tap event will be
  /// consumed.
  ///
  /// Defaults to false.
  final bool consumeOutsideTaps;

  /// A [MenuController] that allows opening and closing of the menu from other
  /// widgets.
  final MenuController controller;

  static void _defaultOnOpenRequested(Offset? position, VoidCallback showOverlay) {
    showOverlay();
  }

  static void _defaultOnCloseRequested(VoidCallback hideOverlay) {
    hideOverlay();
  }

  @override
  State<RawMenuAnchor> createState() => _RawMenuAnchorState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
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

// Base mixin that provides the common interface and state for both types of
// [RawMenuAnchor]s, [RawMenuAnchor] and [RawMenuAnchorGroup].
@optionalTypeArgs
mixin _RawMenuAnchorBaseMixin<T extends StatefulWidget> on State<T> {
  final List<_RawMenuAnchorBaseMixin> _anchorChildren = <_RawMenuAnchorBaseMixin>[];
  _RawMenuAnchorBaseMixin? _parent;
  ScrollPosition? _scrollPosition;
  Size? _viewSize;

  /// Whether this [_RawMenuAnchorBaseMixin] is the top node of the menu tree.
  @protected
  bool get isRoot => _parent == null;

  /// The [MenuController] that is used by the [_RawMenuAnchorBaseMixin].
  ///
  /// If an overriding widget does not provide a [MenuController], then
  /// [_RawMenuAnchorBaseMixin] will create and manage its own.
  MenuController get menuController;

  /// Whether this submenu's overlay is visible.
  @protected
  bool get isOpen;

  /// The root of the menu tree that this [RawMenuAnchor] is in.
  @protected
  _RawMenuAnchorBaseMixin get root {
    _RawMenuAnchorBaseMixin anchor = this;
    while (anchor._parent != null) {
      anchor = anchor._parent!;
    }
    return anchor;
  }

  @override
  void initState() {
    super.initState();
    menuController._attach(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final _RawMenuAnchorBaseMixin? newParent = MenuController.maybeOf(context)?._anchor;
    if (newParent != _parent) {
      assert(
        newParent != this,
        'A MenuController should only be attached to one anchor at a time.',
      );
      _parent?._removeChild(this);
      _parent = newParent;
      _parent?._addChild(this);
    }

    if (isRoot) {
      _scrollPosition?.isScrollingNotifier.removeListener(_handleScroll);
      _scrollPosition = Scrollable.maybeOf(context)?.position;
      _scrollPosition?.isScrollingNotifier.addListener(_handleScroll);

      final Size newSize = MediaQuery.sizeOf(context);
      if (_viewSize != null && newSize != _viewSize && isOpen) {
        // Close the menus if the view changes size.
        handleCloseRequest();
      }
      _viewSize = newSize;
    }
  }

  @override
  void dispose() {
    assert(_debugMenuInfo('Disposing of $this'));
    if (isOpen) {
      close(inDispose: true);
    }

    _parent?._removeChild(this);
    _parent = null;
    _anchorChildren.clear();
    menuController._detach(this);
    super.dispose();
  }

  void _addChild(_RawMenuAnchorBaseMixin child) {
    assert(isRoot || _debugMenuInfo('Added root child: $child'));
    assert(!_anchorChildren.contains(child));
    _anchorChildren.add(child);
    assert(_debugMenuInfo('Added:\n${child.widget.toStringDeep()}'));
    assert(_debugMenuInfo('Tree:\n${widget.toStringDeep()}'));
  }

  void _removeChild(_RawMenuAnchorBaseMixin child) {
    assert(isRoot || _debugMenuInfo('Removed root child: $child'));
    assert(_anchorChildren.contains(child));
    assert(_debugMenuInfo('Removing:\n${child.widget.toStringDeep()}'));
    _anchorChildren.remove(child);
    assert(_debugMenuInfo('Tree:\n${widget.toStringDeep()}'));
  }

  void _handleScroll() {
    // If an ancestor scrolls, and we're a root anchor, then close the menus.
    // Don't just close it on *any* scroll, since we want to be able to scroll
    // menus themselves if they're too big for the view.
    if (isOpen) {
      handleCloseRequest();
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
  /// Call this when the menu overlay should be shown and added to the widget
  /// tree.
  ///
  /// The optional `position` argument should specify the location of the menu
  /// in the local coordinates of the [RawMenuAnchor].
  @protected
  void open({Offset? position});

  /// Close the menu and all of its children.
  ///
  /// Call this when the menu overlay should be hidden and removed from the
  /// widget tree.
  ///
  /// If `inDispose` is true, this method call was triggered by the widget being
  /// unmounted.
  @protected
  void close({bool inDispose = false});

  /// Implemented by subclasses to define what to do when [MenuController.open]
  /// is called.
  ///
  /// This method should not be directly called by subclasses. Its call chain
  /// should eventually invoke `_RawMenuAnchorBaseMixin.open`
  @protected
  void handleOpenRequest({Offset? position});

  /// Implemented by subclasses to define what to do when [MenuController.close]
  /// is called.
  ///
  /// This method should not be directly called by subclasses. Its call chain
  /// should eventually invoke `_RawMenuAnchorBaseMixin.close`.
  @protected
  void handleCloseRequest();

  /// Request that the submenus of this menu be closed.
  ///
  /// By default, this method will call [handleCloseRequest] on each child of this
  /// menu, which will trigger the closing sequence of each child.
  ///
  /// If `inDispose` is true, this method was triggered by the widget being
  /// unmounted.
  @protected
  void closeChildren({bool inDispose = false}) {
    assert(_debugMenuInfo('Closing children of $this${inDispose ? ' (dispose)' : ''}'));
    for (final _RawMenuAnchorBaseMixin child in List<_RawMenuAnchorBaseMixin>.of(_anchorChildren)) {
      if (inDispose) {
        child.close(inDispose: inDispose);
      } else {
        child.handleCloseRequest();
      }
    }
  }

  /// Handles taps outside of the menu surface.
  ///
  /// By default, this closes this submenu's children.
  @protected
  void handleOutsideTap(PointerDownEvent pointerDownEvent) {
    assert(_debugMenuInfo('Tapped Outside $menuController'));
    if (isOpen) {
      closeChildren();
    }
  }

  // Used to build the anchor widget in subclasses.
  @protected
  Widget buildAnchor(BuildContext context);

  @override
  @nonVirtual
  Widget build(BuildContext context) {
    return _MenuControllerScope(
      isOpen: isOpen,
      controller: menuController,
      child: Actions(
        actions: <Type, Action<Intent>>{
          // Check if open to allow DismissIntent to bubble when the menu is
          // closed.
          if (isOpen) DismissIntent: DismissMenuAction(controller: menuController),
        },
        child: Builder(builder: buildAnchor),
      ),
    );
  }

  @override
  String toString({DiagnosticLevel? minLevel}) => describeIdentity(this);
}

class _RawMenuAnchorState extends State<RawMenuAnchor> with _RawMenuAnchorBaseMixin<RawMenuAnchor> {
  // The global key used to determine the bounding rect for the anchor.
  final GlobalKey _anchorKey = GlobalKey<_RawMenuAnchorState>(
    debugLabel: kReleaseMode ? null : 'MenuAnchor',
  );
  final OverlayPortalController _overlayController = OverlayPortalController(
    debugLabel: kReleaseMode ? null : 'MenuAnchor controller',
  );

  Offset? _menuPosition;
  bool get _isRootOverlayAnchor => _parent is! _RawMenuAnchorState;

  // If we are a nested menu, we still want to use the same overlay as the
  // root menu.
  bool get useRootOverlay {
    if (_parent case _RawMenuAnchorState(useRootOverlay: final bool useRoot)) {
      return useRoot;
    }

    assert(_isRootOverlayAnchor);
    return widget.useRootOverlay;
  }

  @override
  bool get isOpen => _overlayController.isShowing;

  @override
  MenuController get menuController => widget.controller;

  @override
  void didUpdateWidget(RawMenuAnchor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller._detach(this);
      widget.controller._attach(this);
    }
  }

  @override
  void open({Offset? position}) {
    if (!mounted) {
      return;
    }

    if (isOpen) {
      // The menu is already open, but we need to move to another location, so
      // close it first.
      close();
    }

    assert(_debugMenuInfo('Opening $this at ${position ?? Offset.zero}'));

    // Close all siblings.
    _parent?.closeChildren();
    assert(!_overlayController.isShowing);
    _menuPosition = position;
    _parent?._childChangedOpenState();
    _overlayController.show();

    if (_isRootOverlayAnchor) {
      widget.childFocusNode?.requestFocus();
    }

    widget.onOpen?.call();
    setState(() {
      // Mark dirty to notify MenuController dependents.
    });
  }

  @override
  void close({bool inDispose = false}) {
    assert(_debugMenuInfo('Closing $this'));
    if (!isOpen) {
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
  void handleOpenRequest({ui.Offset? position}) {
    widget.onOpenRequested(position, () {
      open(position: position);
    });
  }

  @override
  void handleCloseRequest() {
    // Changes in MediaQuery.sizeOf(context) cause RawMenuAnchor to close during
    // didChangeDependencies. When this happens, calling setState during the
    // closing sequence (handleCloseRequest -> onCloseRequested -> hideOverlay)
    // will throw an error, since we'd be scheduling a build during a build. We
    // avoid this by checking if we're in a build, and if so, we schedule the
    // close for the next frame.
    if (SchedulerBinding.instance.schedulerPhase != SchedulerPhase.persistentCallbacks) {
      widget.onCloseRequested(close);
    } else {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onCloseRequested(close);
        }
      }, debugLabel: 'RawMenuAnchor.handleCloseRequest');
    }
  }

  Widget _buildOverlay(BuildContext context, OverlayChildLayoutInfo layoutInfo) {
    final Matrix4 transform = layoutInfo.childPaintTransform;
    final Size anchorSize = layoutInfo.childSize;

    // Transform the anchor rectangle using the full transform matrix.
    final Rect anchorRect = MatrixUtils.transformRect(transform, Offset.zero & anchorSize);

    final RawMenuOverlayInfo info = RawMenuOverlayInfo(
      anchorRect: anchorRect,
      overlaySize: layoutInfo.overlaySize,
      position: _menuPosition,
      tapRegionGroupId: root.menuController,
    );

    return widget.overlayBuilder(context, info);
  }

  @override
  Widget buildAnchor(BuildContext context) {
    final Widget child = Shortcuts(
      includeSemantics: false,
      shortcuts: _kMenuTraversalShortcuts,
      child: TapRegion(
        groupId: root.menuController,
        consumeOutsideTaps: root.isOpen && widget.consumeOutsideTaps,
        onTapOutside: handleOutsideTap,
        child: Builder(
          key: _anchorKey,
          builder: (BuildContext context) {
            return widget.builder?.call(context, menuController, widget.child) ??
                widget.child ??
                const SizedBox();
          },
        ),
      ),
    );

    return OverlayPortal.overlayChildLayoutBuilder(
      controller: _overlayController,
      overlayChildBuilder: _buildOverlay,
      overlayLocation: useRootOverlay
          ? OverlayChildLocation.rootOverlay
          : OverlayChildLocation.nearestOverlay,
      child: child,
    );
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
///  - [MenuController.close] closes all child [RawMenuAnchor]s that are open.
///  - [MenuController.isOpen] reflects whether any child [RawMenuAnchor] is
///    open.
///
/// A [child] must be provided.
///
/// {@tool dartpad}
///
/// This example uses [RawMenuAnchorGroup] to build a menu bar with four
/// submenus. Hovering over a menu item opens its respective submenu. Selecting
/// a menu item will close the menu and update the selected item text.
///
/// ** See code in examples/api/lib/widgets/raw_menu_anchor/raw_menu_anchor.1.dart **
/// {@end-tool}
///
/// See also:
/// * [MenuBar], which wraps this widget with standard layout and semantics and
///   focus management.
/// * [MenuAnchor], a menu anchor that follows the Material Design guidelines.
/// * [RawMenuAnchor], a widget that defines a region attached to a floating
///   submenu.
class RawMenuAnchorGroup extends StatefulWidget {
  /// Creates a [RawMenuAnchorGroup].
  const RawMenuAnchorGroup({super.key, required this.child, required this.controller});

  /// The child displayed by the [RawMenuAnchorGroup].
  ///
  /// To access the [MenuController] from the [child], place the child in a
  /// builder and call [MenuController.maybeOf].
  final Widget child;

  /// An [MenuController] that allows the closing of the menu from other
  /// widgets.
  final MenuController controller;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ObjectFlagProperty<MenuController>.has('controller', controller));
  }

  @override
  State<RawMenuAnchorGroup> createState() => _RawMenuAnchorGroupState();
}

class _RawMenuAnchorGroupState extends State<RawMenuAnchorGroup>
    with _RawMenuAnchorBaseMixin<RawMenuAnchorGroup> {
  @override
  bool get isOpen => _anchorChildren.any((_RawMenuAnchorBaseMixin child) => child.isOpen);

  @override
  MenuController get menuController => widget.controller;

  @override
  void didUpdateWidget(RawMenuAnchorGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller._detach(this);
      widget.controller._attach(this);
    }
  }

  @override
  void close({bool inDispose = false}) {
    if (!isOpen) {
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
    assert(menuController._anchor == this);
    // Menu nodes are always open, so this is a no-op.
    return;
  }

  @override
  void handleCloseRequest() {
    assert(_debugMenuInfo('Requesting close $this'));
    close();
  }

  @override
  void handleOpenRequest({ui.Offset? position}) {
    assert(_debugMenuInfo('Requesting open $this'));
    open(position: position);
  }

  @override
  Widget buildAnchor(BuildContext context) {
    return TapRegion(
      groupId: root.menuController,
      onTapOutside: handleOutsideTap,
      child: widget.child,
    );
  }
}

/// A controller used to manage a menu created by a subclass of [RawMenuAnchor],
/// such as [MenuAnchor], [MenuBar], [SubmenuButton].
///
/// A [MenuController] is used to control and interrogate a menu after it has
/// been created, with methods such as [open] and [close], and state accessors
/// like [isOpen].
///
/// [MenuController.maybeOf] can be used to retrieve a controller from the
/// [BuildContext] of a widget that is a descendant of a [MenuAnchor],
/// [MenuBar], [SubmenuButton], or [RawMenuAnchor]. Doing so will not establish
/// a dependency relationship.
///
/// See also:
///
/// * [MenuAnchor], a menu anchor that follows the Material Design guidelines.
/// * [MenuBar], a widget that creates a menu bar that can take an optional
///   [MenuController].
/// * [SubmenuButton], a widget that has a button that manages a submenu.
/// * [RawMenuAnchor], a widget that defines a region that has submenu.
class MenuController {
  // The anchor that this controller controls.
  //
  // This is set automatically when this `MenuController` is attached to an
  // anchor.
  _RawMenuAnchorBaseMixin? _anchor;

  /// Whether or not the menu associated with this [MenuController] is open.
  bool get isOpen => _anchor?.isOpen ?? false;

  /// Opens the menu that this [MenuController] is associated with.
  ///
  /// If `position` is given, then the menu will open at the position given, in
  /// the coordinate space of the [RawMenuAnchor] that this controller is
  /// attached to.
  ///
  /// If given, the `position` will override the [MenuAnchor.alignmentOffset]
  /// given to the [MenuAnchor].
  ///
  /// If the menu's anchor point is scrolled by an ancestor, or the view changes
  /// size, then any open menu will automatically close.
  void open({Offset? position}) {
    assert(_anchor != null);
    _anchor!.handleOpenRequest(position: position);
  }

  /// Close the menu that this [MenuController] is associated with.
  ///
  /// Associating with a menu is done by passing a [MenuController] to a
  /// [MenuAnchor], [RawMenuAnchor], or [RawMenuAnchorGroup].
  ///
  /// If the menu's anchor point is scrolled by an ancestor, or the view changes
  /// size, then any open menu will automatically close.
  void close() {
    _anchor?.handleCloseRequest();
  }

  /// Close the children of the menu associated with this [MenuController],
  /// without closing the menu itself.
  void closeChildren() {
    assert(_anchor != null);
    _anchor!.closeChildren();
  }

  // ignore: use_setters_to_change_properties
  void _attach(_RawMenuAnchorBaseMixin anchor) {
    _anchor = anchor;
  }

  void _detach(_RawMenuAnchorBaseMixin anchor) {
    if (_anchor == anchor) {
      _anchor = null;
    }
  }

  /// Returns the [MenuController] of the ancestor [RawMenuAnchor] nearest to
  /// the given `context`, if one exists. Otherwise, returns null.
  ///
  /// This method will not establish a dependency relationship, so the calling
  /// widget will not rebuild when the menu opens and closes, nor when the
  /// [MenuController] changes.
  static MenuController? maybeOf(BuildContext context) {
    return context.getInheritedWidgetOfExactType<_MenuControllerScope>()?.controller;
  }

  /// Returns the value of [MenuController.isOpen] of the ancestor
  /// [RawMenuAnchor] or [RawMenuAnchorGroup] nearest to the given `context`, if
  /// one exists. Otherwise, returns null.
  ///
  /// This method will establish a dependency relationship, so the calling
  /// widget will rebuild when the menu opens and closes.
  static bool? maybeIsOpenOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_MenuControllerScope>()?.isOpen;
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
    controller._anchor!.root.handleCloseRequest();
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
