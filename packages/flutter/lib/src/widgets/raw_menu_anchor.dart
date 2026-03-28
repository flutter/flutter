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
    required this.tapRegionGroupId,
    required super.child,
  });

  final bool isOpen;
  final MenuController controller;
  final Object tapRegionGroupId;

  @override
  bool updateShouldNotify(_MenuControllerScope oldWidget) {
    return isOpen != oldWidget.isOpen || tapRegionGroupId != oldWidget.tapRegionGroupId;
  }
}

/// An interface used to define the behavior of a [RawMenuNode].
///
/// Typically, [RawMenuNodeDelegate] is implemented by the [State] of a widget
/// that builds a [RawMenuNode].
///
/// See [RawMenuAnchor] for example usage of this delegate.
abstract interface class RawMenuNodeDelegate {
  /// Whether the menu is open.
  bool get isOpen;

  /// Implementers should define what to do when [MenuController.open] is
  /// called.
  ///
  /// The `position` argument is the `position` argument passed to
  /// [MenuController.open]. It should be used to position the menu in the local
  /// coordinates of the [RawMenuNode.child].
  ///
  /// The `showOverlay` callback should be called when the menu should be shown.
  /// This can occur immediately (the default behavior), or after a delay.
  ///
  /// If an opening animation is required, it should typically be started
  /// immediately after calling `showOverlay` within this method.
  void didRequestMenuOpen(Offset? position, VoidCallback showOverlay);

  /// Implementers should define what to do when [MenuController.close] is
  /// called.
  ///
  /// The `hideOverlay` callback should be called when the menu should be
  /// hidden. This can occur immediately (the default behavior), or after a
  /// delay, such as after a closing animation has completed.
  ///
  /// The [hideOverlay] callback is safe to call after the widget is dismounted,
  /// or not at all.
  ///
  /// Pending timers started in a previous call to [handleMenuCloseRequest] should be
  /// canceled when this callback is triggered.
  ///
  /// This method is not called if the menu is already closed.
  void handleMenuCloseRequest(VoidCallback hideOverlay);

  /// Implement to define how to open the menu.
  ///
  /// This is called when the menu overlay should be shown and added to the
  /// widget tree.
  ///
  /// The optional `position` argument should be used to position the menu in
  /// the local coordinates of the [RawMenuNode.child].
  void handleMenuOpen({Offset? position});

  /// Implement to define how to close the menu.
  ///
  /// This is called when the menu overlay should be hidden and removed from the
  /// widget tree.
  ///
  /// Prior to [handleMenuClose] being called, all descendant menus will have been closed.
  ///
  /// This method is not called if the menu is already closed.
  void handleMenuClose();
}

/// A widget that acts as a logical node in a menu tree and delegates its
/// presentation to a [RawMenuNodeDelegate].
///
/// Its primary responsibilities are:
///
/// 1.  **State Coordination**: It orchestrates open/close operations across the
///     menu tree. For example, when this node opens, it first begins closing
///     all siblings.
///
/// 2.  **Inheritance**: It provides the [MenuController] and
///     [RawMenuNodeDelegate.isOpen] to descendants. These can be accessed using
///     [MenuController.maybeOf] and [MenuController.maybeIsOpenOf],
///     respectively.
///
/// 3.  **Behavioral Triggers**: It listens for external events (like scrolling
///     or screen resizing) to automatically close the menu tree when necessary.
///
/// ### Relationship to [RawMenuAnchor]
///
/// [RawMenuAnchor] uses [RawMenuNode] internally. Its state mixes in
/// [RawMenuNodeDelegate] and builds a [RawMenuNode] that delegates to itself.
/// For most use cases, [RawMenuAnchor] is the correct widget to use.
/// [RawMenuNode] is intended for cases where the anchor widget needs full
/// control over its own presentation — for example, when the menu content is
/// rendered in a [Stack] rather than in an [Overlay].
///
/// See also:
///
///  * [RawMenuNodeDelegate], the mixin that defines what should happen when a
///    [RawMenuNode] is opened or closed.
///  * [RawMenuAnchor], a widget that wraps a [RawMenuNode] and presents its
///    menu in an [OverlayPortal].
///  * [RawMenuAnchorGroup], a widget that registers a group of related
///    [RawMenuNode]s in the menu tree without displaying its own overlay.
///  * [MenuController], the controller used to open, close, and interrogate a
///    menu anchor.
class RawMenuNode extends StatefulWidget {
  ///
  const RawMenuNode({
    super.key,
    required this.delegate,
    required this.controller,
    required this.child,
  });

  /// The delegate that defines the presentation of this menu.
  ///
  /// This is typically the [State] of the widget that wraps this [RawMenuNode].
  final RawMenuNodeDelegate delegate;

  /// A [MenuController] that allows opening and closing of the menu from other
  /// widgets.
  final MenuController controller;

  /// The child widget that this [RawMenuNode] surrounds.
  ///
  /// This is typically a widget that contains both the menu button and the menu
  /// panel, such as a [Stack].
  final Widget child;

  @override
  State<RawMenuNode> createState() => _RawMenuNodeState();
}

class _RawMenuNodeState extends State<RawMenuNode> {
  final List<_RawMenuNodeState> _anchorChildren = <_RawMenuNodeState>[];
  _RawMenuNodeState? _parent;
  ScrollPosition? _scrollPosition;
  Size? _viewSize;

  RawMenuNodeDelegate get delegate => widget.delegate;
  bool get isOpen => delegate.isOpen;

  /// Whether this [_RawMenuNodeState] is the top node of the menu tree.
  bool get isRoot => _parent == null;

  /// The root of the menu tree that this [RawMenuAnchor] is in.
  _RawMenuNodeState get root {
    var anchor = this;
    while (anchor._parent != null) {
      anchor = anchor._parent!;
    }
    return anchor;
  }

  @override
  void initState() {
    super.initState();
    widget.controller._attach(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final _RawMenuNodeState? newParent = MenuController.maybeOf(context)?._anchor;
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
        // handleCloseRequest();
      }
      _viewSize = newSize;
    }
  }

  @override
  void didUpdateWidget(RawMenuNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller._detach(this);
      widget.controller._attach(this);
    }
  }

  @override
  void dispose() {
    assert(_debugMenuInfo('Disposing of $this'));
    _parent?._removeChild(this);
    _parent = null;
    _anchorChildren.clear();
    widget.controller._detach(this);
    super.dispose();
  }

  void _addChild(_RawMenuNodeState child) {
    assert(isRoot || _debugMenuInfo('Added root child: $child'));
    assert(!_anchorChildren.contains(child));
    _anchorChildren.add(child);
    assert(_debugMenuInfo('Added:\n${child.widget.toStringDeep()}'));
    assert(_debugMenuInfo('Tree:\n${widget.toStringDeep()}'));
  }

  void _removeChild(_RawMenuNodeState child) {
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
    _scheduleSafeCallback(() {
      if (mounted) {
        setState(() {
          // Mark dirty to notify MenuController dependents.
        });
      }
    }, debugLabel: '_RawMenuAnchorBaseState._childChangedOpenState');
  }

  /// Open the menu, optionally at a position relative to the [RawMenuAnchor].
  ///
  /// Call this when the menu overlay should be shown and added to the widget
  /// tree.
  ///
  /// The optional `position` argument should specify the location of the menu
  /// in the local coordinates of the [RawMenuAnchor].
  void open({Offset? position}) {
    if (!mounted) {
      return;
    }

    if (isOpen) {
      // The menu is already open, but we need to move to another location. If a
      // child of this menu is open, calling OverlayPortalController.show() will
      // show this menu above the child. To avoid this, we close the menu and
      // all of its children first, which will remove the menu overlay from the
      // widget tree.
      close();
    }

    assert(_debugMenuInfo('Opening $this at ${position ?? Offset.zero}'));

    // Close all siblings.
    _parent?.requestChildrenClose();
    delegate.handleMenuOpen(position: position);
    _parent?._childChangedOpenState();
    setState(() {
      // Mark dirty to notify MenuController dependents.
    });
  }

  /// Close the menu and all of its children.
  ///
  /// Called when the menu overlay should be hidden and removed from the widget
  /// tree.
  void close() {
    assert(_debugMenuInfo('Closing $this'));
    if (!isOpen) {
      return;
    }

    assert(mounted, 'A RawMenuAnchorDelegate returned true from isOpen after it was disposed.');
    closeChildren();
    delegate.handleMenuClose();
    _parent?._childChangedOpenState();
    setState(() {
      // Mark dirty to notify MenuController dependents.
    });
  }

  /// Called by [MenuController.open] to trigger the opening sequence of this
  /// menu, which eventually leads to [_RawMenuNodeState.open].
  void handleOpenRequest({ui.Offset? position}) {
    delegate.didRequestMenuOpen(position, () {
      open(position: position);
    });
  }

  /// Called by [MenuController.close] to trigger the closing sequence of this
  /// menu, which eventually leads to [_RawMenuNodeState.close].
  void handleCloseRequest() {
    if (!isOpen) {
      return;
    }

    // Changes in MediaQuery.sizeOf(context) cause RawMenuAnchor to close during
    // didChangeDependencies. When this happens, calling setState during the
    // closing sequence (handleCloseRequest -> onCloseRequested -> hideOverlay)
    // will throw an error, since we'd be scheduling a build during a build. We
    // avoid this by checking if we're in a build, and if so, we schedule the
    // close for the next frame.
    _scheduleSafeCallback(() {
      if (mounted) {
        delegate.handleMenuCloseRequest(close);
      }
    }, debugLabel: '_RawMenuAnchorBaseState.handleCloseRequest');
    requestChildrenClose();
  }

  /// Close the open submenus of this menu.
  ///
  /// This method will call [close] on each child of this menu, which will
  /// immediately close the child.
  void closeChildren() {
    assert(_debugMenuInfo('Closing children of $this'));
    final children = List<_RawMenuNodeState>.of(_anchorChildren);
    for (final child in children) {
      child.close();
    }
  }

  /// Request that the open submenus of this menu be closed.
  ///
  /// This method will call [handleCloseRequest] on each child of this
  /// menu, which will trigger the closing sequence of each child.
  void requestChildrenClose() {
    assert(_debugMenuInfo('Calling handleCloseRequest for children of $this'));
    final children = List<_RawMenuNodeState>.of(_anchorChildren);
    for (final child in children) {
      child.handleCloseRequest();
    }
  }

  void handleOutsideTap(PointerDownEvent pointerDownEvent) {
    assert(_debugMenuInfo('Tapped Outside ${widget.controller}'));
    if (isOpen) {
      requestChildrenClose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _MenuControllerScope(
      isOpen: isOpen,
      controller: widget.controller,
      tapRegionGroupId: root.widget.controller,
      child: Actions(
        actions: <Type, Action<Intent>>{
          // Check if open to allow DismissIntent to bubble when the menu is
          // closed.
          if (isOpen) DismissIntent: DismissMenuAction(controller: widget.controller),
        },
        child: widget.child,
      ),
    );
  }

  @override
  String toString({DiagnosticLevel? minLevel}) {
    return describeIdentity(this);
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
  /// This callback is also triggered when a parent [RawMenuAnchor] is opened,
  /// since that triggers [MenuController.close] on all descendant menu
  /// controllers. As a result, pending timers or animations started in
  /// [onCloseRequested] should be canceled when this callback is triggered, to
  /// prevent them from closing the menu at an unintended time.
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

class _RawMenuAnchorState extends State<RawMenuAnchor> implements RawMenuNodeDelegate {
  final OverlayPortalController _overlayController = OverlayPortalController(
    debugLabel: kReleaseMode ? null : 'MenuAnchor controller',
  );

  Offset? _menuPosition;
  RawMenuNodeDelegate? get parent => widget.controller._anchor?._parent?.delegate;
  bool get _isRootOverlayAnchor {
    return parent is! _RawMenuAnchorState;
  }

  // If we are a nested menu, we still want to use the same overlay as the
  // root menu.
  bool get useRootOverlay {
    if (parent case _RawMenuAnchorState(useRootOverlay: final bool useRoot)) {
      return useRoot;
    }

    assert(_isRootOverlayAnchor);
    return widget.useRootOverlay;
  }

  @override
  bool get isOpen => _overlayController.isShowing;

  @override
  void handleMenuClose() {
    _scheduleSafeCallback(() {
      if (mounted) {
        _overlayController.hide();
        widget.onClose?.call();
      }
    }, debugLabel: 'MenuAnchor.onClose');
  }

  @override
  void handleMenuCloseRequest(ui.VoidCallback hideOverlay) {
    widget.onCloseRequested(hideOverlay);
  }

  @override
  void handleMenuOpen({ui.Offset? position}) {
    _menuPosition = position;
    _overlayController.show();
    if (_isRootOverlayAnchor) {
      widget.childFocusNode?.requestFocus();
    }
    widget.onOpen?.call();
  }

  @override
  void didRequestMenuOpen(ui.Offset? position, ui.VoidCallback showOverlay) {
    widget.onOpenRequested(position, showOverlay);
  }

  Widget _buildOverlay(BuildContext context, OverlayChildLayoutInfo layoutInfo) {
    final Matrix4 transform = layoutInfo.childPaintTransform;
    final Size anchorSize = layoutInfo.childSize;

    // Transform the anchor rectangle using the full transform matrix.
    final Rect anchorRect = MatrixUtils.transformRect(transform, Offset.zero & anchorSize);

    final info = RawMenuOverlayInfo(
      anchorRect: anchorRect,
      overlaySize: layoutInfo.overlaySize,
      position: _menuPosition,
      tapRegionGroupId: MenuController.maybeTapRegionGroupIdOf(context)!,
    );

    return widget.overlayBuilder(context, info);
  }

  /// Handles taps outside of the menu surface.
  ///
  /// By default, this closes this submenu's children.
  @protected
  void handleOutsideTap(PointerDownEvent pointerDownEvent) {
    assert(_debugMenuInfo('Tapped Outside ${widget.controller}'));
    if (isOpen) {
      widget.controller.closeChildren();
    }
  }

  Widget _buildAnchor(BuildContext context) {
    // A dependency on MenuController.isOpen is established to ensure the
    // anchor child is rebuilt when the menu opens and closes.
    MenuController.maybeIsOpenOf(context);
    return TapRegion(
      groupId: MenuController.maybeTapRegionGroupIdOf(context),
      consumeOutsideTaps: isOpen && widget.consumeOutsideTaps,
      onTapOutside: handleOutsideTap,
      child:
          widget.builder?.call(context, widget.controller, widget.child) ??
          widget.child ??
          const SizedBox(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget child = Shortcuts(
      includeSemantics: false,
      shortcuts: _kMenuTraversalShortcuts,
      child: Builder(builder: _buildAnchor),
    );

    return RawMenuNode(
      controller: widget.controller,
      delegate: this,
      child: Builder(
        builder: (BuildContext context) {
          return OverlayPortal.overlayChildLayoutBuilder(
            controller: _overlayController,
            overlayChildBuilder: _buildOverlay,
            overlayLocation: useRootOverlay
                ? OverlayChildLocation.rootOverlay
                : OverlayChildLocation.nearestOverlay,
            child: child,
          );
        },
      ),
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

class _RawMenuAnchorGroupState extends State<RawMenuAnchorGroup> implements RawMenuNodeDelegate {
  @override
  bool get isOpen =>
      widget.controller._anchor?._anchorChildren.any((child) => child.isOpen) ?? false;

  @override
  void handleMenuClose() {}

  @override
  void handleMenuCloseRequest(ui.VoidCallback hideOverlay) {}

  @override
  void handleMenuOpen({ui.Offset? position}) {
    // Menu groups are always open, so this is a no-op.
  }

  @override
  void didRequestMenuOpen(ui.Offset? position, ui.VoidCallback showOverlay) {
    // RawMenuAnchorGroup cannot be opened directly, so we don't call showOverlay.
  }

  void handleOutsideTap(PointerDownEvent pointerDownEvent) {
    assert(_debugMenuInfo('Tapped Outside ${widget.controller}'));
    if (isOpen) {
      widget.controller.closeChildren();
    }
  }

  Widget _buildChild(BuildContext context) {
    return TapRegion(
      groupId: MenuController.maybeTapRegionGroupIdOf(context),
      onTapOutside: handleOutsideTap,
      child: widget.child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return RawMenuNode(
      controller: widget.controller,
      delegate: this,
      child: Builder(builder: _buildChild),
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
  _RawMenuNodeState? _anchor;

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
    _anchor!.requestChildrenClose();
  }

  // ignore: use_setters_to_change_properties
  void _attach(_RawMenuNodeState anchor) {
    _anchor = anchor;
  }

  void _detach(_RawMenuNodeState anchor) {
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

  /// Returns the [TapRegion.groupId] used by the ancestor [RawMenuNode] nearest
  /// to the given `context`, if one exists. Otherwise, returns null.
  ///
  /// This method will establish a dependency relationship, so the calling
  /// widget will rebuild when the menu's [TapRegion.groupId] changes.
  static Object? maybeTapRegionGroupIdOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_MenuControllerScope>()?.tapRegionGroupId;
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

/// Invokes a `callback` immediately if the scheduler is idle, or schedules
/// it for the next frame if the scheduler is currently processing a build.
void _scheduleSafeCallback(VoidCallback callback, {String? debugLabel}) {
  if (SchedulerBinding.instance.schedulerPhase != SchedulerPhase.persistentCallbacks) {
    callback();
  } else {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      callback();
    }, debugLabel: debugLabel ?? '_scheduleSafeCallback');
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
