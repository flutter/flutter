// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import 'basic.dart';
import 'framework.dart';
import 'ticker_provider.dart';

// Examples can assume:
// late BuildContext context;

/// Signature of a function that iterates through a non-null collection of
/// elements of type `T`.
///
/// Each invocation of one such function returns the next element in the
/// collection. When the collection is exhausted the function returns null.
typedef _Iterator<T extends Object> = T? Function();
/// Signature of a specialized _Iterator where T == RenderBox.
typedef _ChildIterator = _Iterator<RenderBox>;

BoxHitTest _toBoxHitTest(bool Function(BoxHitTestResult result, { required Offset position }) hitTest) {
  return (BoxHitTestResult result, Offset transform) => hitTest(result, position: transform);
}

/// A place in an [Overlay] that can contain a widget.
///
/// Overlay entries are inserted into an [Overlay] using the
/// [OverlayState.insert] or [OverlayState.insertAll] functions. To find the
/// closest enclosing overlay for a given [BuildContext], use the [Overlay.of]
/// function.
///
/// An overlay entry can be in at most one overlay at a time. To remove an entry
/// from its overlay, call the [remove] function on the overlay entry.
///
/// Because an [Overlay] uses a [Stack] layout, overlay entries can use
/// [Positioned] and [AnimatedPositioned] to position themselves within the
/// overlay.
///
/// For example, [Draggable] uses an [OverlayEntry] to show the drag avatar that
/// follows the user's finger across the screen after the drag begins. Using the
/// overlay to display the drag avatar lets the avatar float over the other
/// widgets in the app. As the user's finger moves, draggable calls
/// [markNeedsBuild] on the overlay entry to cause it to rebuild. In its build,
/// the entry includes a [Positioned] with its top and left property set to
/// position the drag avatar near the user's finger. When the drag is over,
/// [Draggable] removes the entry from the overlay to remove the drag avatar
/// from view.
///
/// By default, if there is an entirely [opaque] entry over this one, then this
/// one will not be included in the widget tree (in particular, stateful widgets
/// within the overlay entry will not be instantiated). To ensure that your
/// overlay entry is still built even if it is not visible, set [maintainState]
/// to true. This is more expensive, so should be done with care. In particular,
/// if widgets in an overlay entry with [maintainState] set to true repeatedly
/// call [State.setState], the user's battery will be drained unnecessarily.
///
/// [OverlayEntry] is a [Listenable] that notifies when the widget built by
/// [builder] is mounted or unmounted, whose exact state can be queried by
/// [mounted]. After the owner of the [OverlayEntry] calls [remove] and then
/// [dispose], the widget may not be immediately removed from the widget tree.
/// As a result listeners of the [OverlayEntry] can get notified for one last
/// time after the [dispose] call, when the widget is eventually unmounted.
///
/// See also:
///
///  * [Overlay]
///  * [OverlayState]
///  * [WidgetsApp]
///  * [MaterialApp]
class OverlayEntry implements Listenable {
  /// Creates an overlay entry.
  ///
  /// To insert the entry into an [Overlay], first find the overlay using
  /// [Overlay.of] and then call [OverlayState.insert]. To remove the entry,
  /// call [remove] on the overlay entry itself.
  OverlayEntry({
    required this.builder,
    bool opaque = false,
    bool maintainState = false,
  }) : assert(builder != null),
       assert(opaque != null),
       assert(maintainState != null),
       _opaque = opaque,
       _maintainState = maintainState;

  /// This entry will include the widget built by this builder in the overlay at
  /// the entry's position.
  ///
  /// To cause this builder to be called again, call [markNeedsBuild] on this
  /// overlay entry.
  final WidgetBuilder builder;

  /// Whether this entry occludes the entire overlay.
  ///
  /// If an entry claims to be opaque, then, for efficiency, the overlay will
  /// skip building entries below that entry unless they have [maintainState]
  /// set.
  bool get opaque => _opaque;
  bool _opaque;
  set opaque(bool value) {
    assert(!_disposedByOwner);
    if (_opaque == value) {
      return;
    }
    _opaque = value;
    _overlay?._didChangeEntryOpacity();
  }

  /// Whether this entry must be included in the tree even if there is a fully
  /// [opaque] entry above it.
  ///
  /// By default, if there is an entirely [opaque] entry over this one, then this
  /// one will not be included in the widget tree (in particular, stateful widgets
  /// within the overlay entry will not be instantiated). To ensure that your
  /// overlay entry is still built even if it is not visible, set [maintainState]
  /// to true. This is more expensive, so should be done with care. In particular,
  /// if widgets in an overlay entry with [maintainState] set to true repeatedly
  /// call [State.setState], the user's battery will be drained unnecessarily.
  ///
  /// This is used by the [Navigator] and [Route] objects to ensure that routes
  /// are kept around even when in the background, so that [Future]s promised
  /// from subsequent routes will be handled properly when they complete.
  bool get maintainState => _maintainState;
  bool _maintainState;
  set maintainState(bool value) {
    assert(!_disposedByOwner);
    assert(_maintainState != null);
    if (_maintainState == value) {
      return;
    }
    _maintainState = value;
    assert(_overlay != null);
    _overlay!._didChangeEntryOpacity();
  }

  /// Whether the [OverlayEntry] is currently mounted in the widget tree.
  ///
  /// The [OverlayEntry] notifies its listeners when this value changes.
  bool get mounted => _overlayStateMounted.value != null;

  /// The currently mounted `_OverlayEntryWidgetState` built using this [OverlayEntry].
  final ValueNotifier<_OverlayEntryWidgetState?> _overlayStateMounted = ValueNotifier<_OverlayEntryWidgetState?>(null);

  @override
  void addListener(VoidCallback listener) {
    assert(!_disposedByOwner);
    _overlayStateMounted.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _overlayStateMounted.removeListener(listener);
  }

  OverlayState? _overlay;
  final GlobalKey<_OverlayEntryWidgetState> _key = GlobalKey<_OverlayEntryWidgetState>();

  /// Remove this entry from the overlay.
  ///
  /// This should only be called once.
  ///
  /// This method removes this overlay entry from the overlay immediately. The
  /// UI will be updated in the same frame if this method is called before the
  /// overlay rebuild in this frame; otherwise, the UI will be updated in the
  /// next frame. This means that it is safe to call during builds, but	also
  /// that if you do call this after the overlay rebuild, the UI will not update
  /// until	the next frame (i.e. many milliseconds later).
  void remove() {
    assert(_overlay != null);
    assert(!_disposedByOwner);
    final OverlayState overlay = _overlay!;
    _overlay = null;
    if (!overlay.mounted) {
      return;
    }

    overlay._entries.remove(this);
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((Duration duration) {
        overlay._markDirty();
      });
    } else {
      overlay._markDirty();
    }
  }

  /// Cause this entry to rebuild during the next pipeline flush.
  ///
  /// You need to call this function if the output of [builder] has changed.
  void markNeedsBuild() {
    assert(!_disposedByOwner);
    _key.currentState?._markNeedsBuild();
  }

  void _didUnmount() {
    assert(!mounted);
    if (_disposedByOwner) {
      _overlayStateMounted.dispose();
    }
  }

  bool _disposedByOwner = false;

  /// Discards any resources used by this [OverlayEntry].
  ///
  /// This method must be called after [remove] if the [OverlayEntry] is
  /// inserted into an [Overlay].
  ///
  /// After this is called, the object is not in a usable state and should be
  /// discarded (calls to [addListener] will throw after the object is disposed).
  /// However, the listeners registered may not be immediately released until
  /// the widget built using this [OverlayEntry] is unmounted from the widget
  /// tree.
  ///
  /// This method should only be called by the object's owner.
  void dispose() {
    assert(!_disposedByOwner);
    assert(_overlay == null, 'An OverlayEntry must first be removed from the Overlay before dispose is called.');
    _disposedByOwner = true;
    if (!mounted) {
      _overlayStateMounted.dispose();
    }
  }

  @override
  String toString() => '${describeIdentity(this)}(opaque: $opaque; maintainState: $maintainState)';
}

class _RenderTheatreMarker extends InheritedWidget {
  const _RenderTheatreMarker({
    required this.theatre,
    required super.child,
  });

  final _RenderTheatre theatre;

  @override
  bool updateShouldNotify(_RenderTheatreMarker oldWidget) => oldWidget.theatre != theatre;

  @override
  InheritedElement createElement() => _RenderTheatreMarkerElement(this);

  static _RenderTheatre? of(BuildContext context, { bool targetRootOverlay = false }) {
    final _RenderTheatreMarkerElement? element = context.getElementForInheritedWidgetOfExactType<_RenderTheatreMarker>() as _RenderTheatreMarkerElement?;
    if (element == null) {
      return null;
    }
    final _RenderTheatreMarkerElement dependency = targetRootOverlay ? element._topRenderTheatre : element;
    return (context.dependOnInheritedElement(dependency) as _RenderTheatreMarker).theatre;
  }
}

class _RenderTheatreMarkerElement extends InheritedElement {
  _RenderTheatreMarkerElement(super.widget);

  _RenderTheatreMarkerElement get _topRenderTheatre {
    _RenderTheatreMarkerElement? ancestor;
    visitAncestorElements((Element element) {
      assert(ancestor == null);
      ancestor = element.getElementForInheritedWidgetOfExactType<_RenderTheatreMarker>() as _RenderTheatreMarkerElement?;
      return false;
    });
    return ancestor?._topRenderTheatre ?? this;
  }
}

/// A class to show, hide and bring to top an [OverlayPortal]'s overlay child
/// in the target [Overlay].
///
/// A [OverlayPortalController] can only be given to at most one [OverlayPortal]
/// at a time. When an [OverlayPortalController] is moved from one
/// [OverlayPortal] to another, its [isShowing] state does not carry over.
///
/// The [show] and [hide] methods typically should not be called when the widget
/// tree is being rebuilt. However it's allowed to call [show] or [hide] when
/// the associated [OverlayPortal] widget is yet to be inflated into the widget
/// tree.
class OverlayPortalController {
  /// Creates an [OverlayPortalController].
  OverlayPortalController({ String? debugLabel }) : _debugLabel = debugLabel;

  _OverlayPortalTopState? _attachTarget;
  int? _showTimestamp;
  final String? _debugLabel;

  /// Show the overlay child of the [OverlayPortal] this controller is attached
  /// to, at the top of the target [Overlay].
  ///
  /// When there are more than one [OverlayPortal]s that target the same
  /// [Overlay], the overlay child of the last [OverlayPortal] to have called
  /// [show] appears at the top level, unobstructed.
  ///
  /// If [isShowing] is already true, calling this method brings the overlay
  /// child it controls to the top.
  ///
  /// This method should typically not be called when the widget tree is being
  /// rebuilt.
  void show() {
    final _OverlayPortalTopState? state = _attachTarget;
    if (state != null) {
      state.show();
    } else {
      _showTimestamp = _OverlayPortalTopState.wallTime += 1;
    }
  }

  /// Hide the [OverlayPortal]'s overlay child.
  ///
  /// Once hidden, the overlay child will be removed from the widget tree the
  /// next time the widget tree rebuilds, and stateful widgets in the overlay
  /// child may lose states as a result.
  ///
  /// This method should typically not be called when the widget tree is being
  /// rebuilt.
  void hide() {
    final _OverlayPortalTopState? state = _attachTarget;
    if (state != null) {
      state.hide();
    } else {
      assert(_showTimestamp != null);
      _showTimestamp = null;
    }
  }

  /// Whether the associated [OverlayPortal] should build and show its overlay
  /// child, using its `overlayChildBuilder`.
  bool get isShowing {
    final _OverlayPortalTopState? state = _attachTarget;
    return state != null
      ? state._showTimestamp != null
      : _showTimestamp != null;
  }

  /// Conventience method for toggling the current [isShowing] status.
  ///
  /// This method should typically not be called when the widget tree is being
  /// rebuilt.
  void toggle() => isShowing ? hide() : show();

  @override
  String toString() {
    final String? debugLabel = _debugLabel;
    final String label = debugLabel == null ? '' : '($debugLabel)';
    final String isDetached = _attachTarget != null ? '' : ' DETACHED';
    return '${objectRuntimeType(this, 'OverlayPortalController')}$label$isDetached';
  }
}

/// A widget that renders its overlay child on the root [Overlay].
///
/// The overlay child is initially hidden until [OverlayPortalController.show]
/// is called on the associated [controller]. The [OverlayPortal] uses
/// [overlayChildBuilder] to build its overlay child and renders it on the
/// root [Overlay] as if it was inserted using an [OverlayEntry], while it
/// can depend on the same set of [InheritedWidget]s (such as [Theme]) that this
/// widget can depend on.
///
/// This widget requires an [Overlay] ancestor in the widget tree when its
/// overlay child is showing. When there are more than one [OverlayPortal]s in
/// the same [Overlay], the overlay child of the last [OverlayPortal] to have
/// called `show` appears at the top level unobstructed.
///
/// When [OverlayPortalController.hide] is called, the widget built using
/// [overlayChildBuilder] will be removed from the widget tree the next time the
/// widget rebuilds. Stateful descendants in the overlay child subtree may lose
/// states as a result.
///
/// {@tool dartpad}
/// This example uses an [OverlayPortal] to build a tooltip that becomes visible
/// when the user taps on the [child] widget. There's a [DefaultTextStyle] above
/// the [OverlayPortal] controlling the [TextStyle] of both the [child] widget
/// and the widget [overlayChildBuilder] builds, which isn't otherwise doable if
/// the tooltip was added as an [OverlayEntry].
///
/// ** See code in examples/api/lib/widgets/overlay/overlay_portal.0.dart **
/// {@end-tool}
///
/// ### Differences between [OverlayPortal] and [OverlayEntry]
///
/// The main difference between [OverlayEntry] and [OverlayPortal] is that
/// [OverlayEntry] builds its widget subtree as a child of the target [Overlay],
/// while [OverlayPortal] uses [overlayChildBuilder] to build a child widget of
/// itself. This allows [OverlayPortal]'s overlay child to depend on the same
/// set of [InheritedWidget]s as [OverlayPortal], and it's also guaranteed that
/// the overlay child will not outlive its [OverlayPortal].
///
/// On the other hand [OverlayPortal] has a more complex implementation. For
/// instance, it does a bit more work than a regular widget during global key
/// reparenting. If the content to be shown on the [Overlay] doesn't benefit
/// from being a part of [OverlayPortal]'s subtree, consider using an
/// [OverlayEntry] instead.
///
/// See also:
///
///  * [OverlayEntry], an alternative API for inserting widgets into an
///    [Overlay].
///  * [Positioned], which can be used to size and position the overlay child in
///    relation to the target [Overlay]'s boundaries.
///  * [CompositedTransformFollower], which can be used to position the overlay
///    child in relation to the linked [CompositedTransformTarget] widget.
class OverlayPortal extends StatefulWidget {
  /// Creates an [OverlayPortal] that renders the widget [overlayChildBuilder]
  /// builds on the root [Overlay], when [OverlayPortalController.show] is
  /// called.
  const OverlayPortal.top({
    super.key,
    required this.controller,
    required this.overlayChildBuilder,
    required this.child,
  });

  /// The controller to show, hide and bring to top the overlay child.
  final OverlayPortalController controller;

  /// A [WidgetBuilder] used to build a widget below this widget in the tree,
  /// that renders on the root [Overlay].
  ///
  /// The said widget will only be built and shown at the topmost level of the
  /// root [Overlay] once [OverlayPortalController.show] is called on the
  /// associated [controller].
  ///
  /// The built overlay child widget, is inserted below this widget in the
  /// widget tree, allowing it to depend on [InheritedWidget]s above it, and
  /// be notified when the [InheritedWidget]s change.
  ///
  /// Unlike [child], the built overlay child can visually extend outside the
  /// bounds of this widget without being clipped, and receive hit-test events
  /// outside of this widget's bounds, as long as it does not extend outside of
  /// the [Overlay] on which it is rendered.
  final WidgetBuilder overlayChildBuilder;

  /// A widget below this widget in the tree.
  final Widget? child;

  @override
  State<OverlayPortal> createState() => _OverlayPortalTopState();
}

class _TopmostLocation extends OverlayLocation with LinkedListEntry<_TopmostLocation> {
  _TopmostLocation(this._showTimestamp, this._theatreChildModel) : super._();

  final int _showTimestamp;
  final _EventOrderChildModel _theatreChildModel;
  _RenderDeferredLayoutBox? _overlayChildRenderBox;

  @override
  _RenderTheatre get _theatre => _theatreChildModel._theatre;

  @override
  void _addToChildModel(_RenderDeferredLayoutBox child) {
    assert(_overlayChildRenderBox == null, 'Failed to add $child. $_overlayChildRenderBox is attached to $this');
    assert(_showTimestamp != null);
    _overlayChildRenderBox = child;
    _theatreChildModel._add(this);
  }

  @override
  void _removeFromChildModel(_RenderDeferredLayoutBox child) {
    assert(child == _overlayChildRenderBox);
    _overlayChildRenderBox = null;
    assert(_theatreChildModel._sortedChildren.contains(this));
    _theatreChildModel._remove(this);
  }

  @override
  void _activate(_RenderDeferredLayoutBox child) {
    assert(_debugNotDisposed());
    assert(_overlayChildRenderBox == null, '$_overlayChildRenderBox');
    super._activate(child);
    _overlayChildRenderBox = child;
  }

  @override
  void _deactivate(_RenderDeferredLayoutBox child) {
    assert(_debugNotDisposed());
    super._deactivate(child);
    _overlayChildRenderBox = null;
  }

  @override
  String toString() => '$_showTimestamp';
}

class _OverlayPortalTopState extends State<OverlayPortal> {
  // The developer must call `show` to reveal the overlay so we can get the
  // timestamp of the user interaction for sorting.
  _TopmostLocation? _location;
  int? _showTimestamp;
  // See https://github.com/dart-lang/sdk/issues/41717.
  static int wallTime = kIsWeb
    ? -9007199254740992 // -2^53
    : -1 << 63;

  @override
  void initState() {
    super.initState();
    _setupController(widget.controller);
  }

  void _setupController(OverlayPortalController controller) {
    assert(
      controller._attachTarget == null || controller._attachTarget == this,
      'Failed to attach $controller to $this. It is already attached to ${controller._attachTarget}'
    );
    final int? controllerTimeStamp = controller._showTimestamp;
    final int? timeStamp = _showTimestamp;
    if (timeStamp == null || (controllerTimeStamp != null && controllerTimeStamp > timeStamp)) {
      _showTimestamp = controllerTimeStamp;
    }
    controller._showTimestamp = null;
    controller._attachTarget = this;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _location?._dispose();
    _location = null;
  }

  @override
  void didUpdateWidget(OverlayPortal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller._attachTarget = null;
      _setupController(widget.controller);
    }
  }

  @override
  void dispose() {
    widget.controller._attachTarget = null;
    super.dispose();
  }

  void show() {
    assert(SchedulerBinding.instance.schedulerPhase != SchedulerPhase.persistentCallbacks);
    final int now = wallTime += 1;
    assert(_showTimestamp == null || _showTimestamp! < now);
    setState(() { _showTimestamp = now; });
    _location?._dispose();
    _location = null;
  }

  void toggle() => _showTimestamp == null ? show() : hide();

  void hide() {
    assert(SchedulerBinding.instance.schedulerPhase != SchedulerPhase.persistentCallbacks);
    setState(() { _showTimestamp = null; });
    _location = null;
    _location?._dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int? timestamp = _showTimestamp;
    if (timestamp == null) {
      return _OverlayPortal(
        overlayLocation: null,
        overlayChild: null,
        child: widget.child,
      );
    }
    final _RenderTheatre? theatre = _RenderTheatreMarker.of(context, targetRootOverlay: true);
    assert(theatre != null);
    _location ??= _TopmostLocation(timestamp, theatre!._topChildren);

    return _OverlayPortal(
      overlayLocation: _location,
      overlayChild: _DeferredLayout(child: widget.overlayChildBuilder(context)),
      child: widget.child,
    );
  }
}

// An interface for storing render children of a _RenderTheatre that should be
// painted together.
abstract class _RenderTheatreChildModel {
  // Returns an iterator that traverse the children in the child model in paint
  // order (from farthest to the user to the closest to the user).
  //
  // The returned iterator must be used immediately, before any changes can be
  // made to the child model. Also the iterator should be safe to use even when
  // the child model is being mutated. The reason for that is it's allowed to
  // add/remove/move deferred children to a _RenderTheatre during performLayout,
  // but the affected children don't have to be laid out in the same
  // performLayout call.
  _ChildIterator? _paintOrderIterator();

  // Returns an iterator that traverse the children in the child model in
  // hit-test order (from closest to the user to the farthest to the user).
  _ChildIterator? _hitTestOrderIterator();

  void visitChildren(RenderObjectVisitor visitor) {
    final _ChildIterator? iterator = _paintOrderIterator();
    if (iterator == null) {
      return;
    }
    RenderBox? child = iterator();
    while (child != null) {
      visitor(child);
      child = iterator();
    }
  }

  bool hitTestChildren(BoxHitTestResult result, Offset position) {
    final _ChildIterator? iterator = _hitTestOrderIterator();
    if (iterator == null) {
      return false;
    }
    RenderBox? child = iterator();
    while (child != null) {
      final StackParentData childParentData = child.parentData! as StackParentData;
      final bool isHit = result.addWithPaintOffset(
        offset: childParentData.offset,
        position: position,
        hitTest: _toBoxHitTest(child.hitTest)
      );
      if (isHit) {
        return true;
      }
      child = iterator();
    }
    return false;
  }

  void paintChildren(PaintingContext context, Offset offset) {
    final _ChildIterator? iterator = _paintOrderIterator();
    if (iterator == null) {
      return;
    }
    RenderBox? child = iterator();
    while(child != null) {
      final StackParentData parentData = child.parentData! as StackParentData;
      context.paintChild(child, parentData.offset + offset);
      child = iterator();
    }
  }
}

// The data structure for managing the stack of theatre children that are sorted
// by their _showTimestamp.
//
// The children with more recent timestamps (i.e. those called `show` recently)
// will be painted last.
class _EventOrderChildModel extends _RenderTheatreChildModel {
  _EventOrderChildModel(this._theatre);

  final _RenderTheatre _theatre;
  final LinkedList<_TopmostLocation> _sortedChildren = LinkedList<_TopmostLocation>();

  // Worst-case O(N), N being the number of children added to the top spot in
  // the same frame. This can be a bit expensive when there's a lot of global
  // key reparenting in the same frame but N is usually a small number.
  void _add(_TopmostLocation child) {
    assert(!_sortedChildren.contains(child));
    _TopmostLocation? insertPosition = _sortedChildren.isEmpty ? null : _sortedChildren.last;
    while (insertPosition != null && insertPosition._showTimestamp > child._showTimestamp) {
      insertPosition = insertPosition.previous;
    }
    if (insertPosition == null) {
      _sortedChildren.addFirst(child);
    } else {
      insertPosition.insertAfter(child);
    }
    assert(_sortedChildren.contains(child));

    if (child._overlayChildRenderBox != null) {
      _theatre.markNeedsPaint();
      _theatre.markNeedsCompositingBitsUpdate();
      _theatre.markNeedsSemanticsUpdate();
    }
  }

  void _remove(_TopmostLocation child) {
    final bool wasInCollection = _sortedChildren.remove(child);
    assert(wasInCollection);
    if (child._overlayChildRenderBox != null) {
      _theatre.markNeedsPaint();
      _theatre.markNeedsCompositingBitsUpdate();
      _theatre.markNeedsSemanticsUpdate();
    }
  }

  _TopmostLocation? _childAfter(_TopmostLocation? child) {
    if (_sortedChildren.isEmpty) {
      return null;
    }
    final _TopmostLocation? candidate = child == null ? _sortedChildren.first : child.next;
    return candidate != null ? candidate._overlayChildRenderBox != null ? candidate : _childAfter(candidate) : null;
  }

  _TopmostLocation? _childBefore(_TopmostLocation? child) {
    if (_sortedChildren.isEmpty) {
      return null;
    }
    final _TopmostLocation? candidate = child == null ? _sortedChildren.last : child.previous;
    return candidate != null ? candidate._overlayChildRenderBox != null ? candidate : _childBefore(candidate) : null;
  }

  static _ChildIterator? _mapIterator(_Iterator<_TopmostLocation>? fromIterator) {
    if (fromIterator == null) {
      return null;
    }

    _RenderDeferredLayoutBox? iter() {
      final _TopmostLocation? location = fromIterator();
      if (location == null) {
        return null;
      }
      return location._overlayChildRenderBox ?? iter();
    }

    return iter;
  }

  _Iterator<_TopmostLocation>? _forwardIterator() {
    _TopmostLocation? child = _childAfter(null);
    if (child == null) {
      return null;
    }
    bool isInitial = true;
    return () {
      if (isInitial) {
        assert(child != null);
        isInitial = false;
        return child;
      }
      return child == null ? null : child = _childAfter(child);
    };
  }

  _Iterator<_TopmostLocation>? _backwardIterator() {
    _TopmostLocation? child = _childBefore(null);
    if (child == null) {
      return null;
    }
    bool isInitial = true;
    return () {
      if (isInitial) {
        assert(child != null);
        isInitial = false;
        return child;
      }
      return child == null ? null : child = _childBefore(child);
    };
  }

  @override
  _ChildIterator? _paintOrderIterator() => _mapIterator(_forwardIterator());
  @override
  _ChildIterator? _hitTestOrderIterator() => _mapIterator(_backwardIterator());

  bool _debugNotDisposed() {
    if (!_debugDisposed) {
      return true;
    }
    throw StateError('$this is already disposed');
  }
  bool _debugDisposed = false;
  @mustCallSuper
  void _dispose() {
    assert(!_debugDisposed);
    assert(() {
      _debugDisposed = true;
      return true;
    }());
  }
}

/// A location in an [Overlay].
///
/// An [OverlayLocation] dictates the [Overlay] an [OverlayPortal] should put
/// its overlay child onto, as well as the overlay child's paint order in
/// relation to other contents painted on the [Overlay].
// An _OverlayLocation is a cursor pointing to a location in a particular
// Overlay's child model, and provides methods to insert/remove/move a
// _RenderDeferredLayoutBox to/from its target _theatre.
//
// Additionally, `_activate` and `_deactivate` will be called when the overlay
// child's `_OverlayPortalElement` activates/deactivates.
// `_OverlayPortalElement` removes its overlay child's render object from the
// target `_RenderTheatre` when it deactivates and puts it back on `activated`.
// These 2 methods can be used to "hide" a child in the child model without
// removing it, when the child is expensive/difficult to re-insert on
// `activated`.
//
// An `_OverlayLocation` will be used as an Element's slot. Since it won't be
// able to implement operator== (since it's mutable), the same
// `_OverlayLocation` instance must not be used to represent more than one
// locations.
abstract class OverlayLocation {
  OverlayLocation._();

  _RenderTheatre get _theatre;

  @protected
  void _addToChildModel(_RenderDeferredLayoutBox child);
  @protected
  void _removeFromChildModel(_RenderDeferredLayoutBox child);

  void _addChild(_RenderDeferredLayoutBox child) {
    assert(_debugNotDisposed());
    _addToChildModel(child);
    _theatre._addDeferredChild(child);
    assert(child.parent == _theatre);
  }

  void _removeChild(_RenderDeferredLayoutBox child) {
    assert(_debugNotDisposed());
    _removeFromChildModel(child);
    _theatre._removeDeferredChild(child);
    assert(child.parent == null);
  }

  void _moveChild(_RenderDeferredLayoutBox child, OverlayLocation fromLocation) {
    assert(fromLocation != this);
    assert(_debugNotDisposed());
    final _RenderTheatre fromTheatre = fromLocation._theatre;
    if (fromTheatre != _theatre) {
      fromTheatre._removeDeferredChild(child);
      _theatre._addDeferredChild(child);
    }
    fromLocation._removeFromChildModel(child);
    _addToChildModel(child);
  }

  void _activate(_RenderDeferredLayoutBox child) {
    assert(_debugNotDisposed());
    _theatre.adoptChild(child);
  }
  void _deactivate(_RenderDeferredLayoutBox child) {
    assert(_debugNotDisposed());
    _theatre.dropChild(child);
  }

  bool _debugNotDisposed() {
    if (!_debugDisposed) {
      return true;
    }
    throw StateError('$this is already disposed');
  }
  bool _debugDisposed = false;
  @mustCallSuper
  void _dispose() {
    assert(!_debugDisposed);
    assert(() {
      _debugDisposed = true;
      return true;
    }());
  }
}

class _OverlayEntryWidget extends StatefulWidget {
  const _OverlayEntryWidget({
    required Key key,
    required this.entry,
    required this.overlayState,
    this.tickerEnabled = true,
  }) : assert(key != null),
       assert(entry != null),
       assert(tickerEnabled != null),
       super(key: key);

  final OverlayEntry entry;
  final bool tickerEnabled;
  final OverlayState overlayState;

  @override
  _OverlayEntryWidgetState createState() => _OverlayEntryWidgetState();
}

class _OverlayEntryWidgetState extends State<_OverlayEntryWidget> {
  late _RenderTheatre theatre;
  _EventOrderChildModel? _overlayEntryTopChildModel;
  _EventOrderChildModel get overlayEntryTopChildModel => _overlayEntryTopChildModel ??= _EventOrderChildModel(theatre);

  @override
  void initState() {
    super.initState();
    widget.entry._overlayStateMounted.value = this;
    theatre = context.findAncestorRenderObjectOfType<_RenderTheatre>()!;
    _overlayEntryTopChildModel?._dispose();
    _overlayEntryTopChildModel = null;
  }

  @override
  void didUpdateWidget(_OverlayEntryWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // OverlayState's build method always returns a RenderObjectWidget _Theatre,
    // so it's safe to assume that state equality implies render object equality.
    if (oldWidget.overlayState != widget.overlayState) {
      assert(oldWidget.entry == widget.entry);
      theatre = context.findAncestorRenderObjectOfType<_RenderTheatre>()!;
      _overlayEntryTopChildModel?._dispose();
      _overlayEntryTopChildModel = null;
    }
  }

  @override
  void dispose() {
    widget.entry._overlayStateMounted.value = null;
    widget.entry._didUnmount();
    _overlayEntryTopChildModel?._dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TickerMode(
      enabled: widget.tickerEnabled,
      child: _RenderTheatreMarker(
        theatre: theatre,
        child: Builder(builder: widget.entry.builder),
      ),
    );
  }

  void _markNeedsBuild() {
    setState(() { /* the state that changed is in the builder */ });
  }
}

/// A stack of entries that can be managed independently.
///
/// Overlays let independent child widgets "float" visual elements on top of
/// other widgets by inserting them into the overlay's stack. The overlay lets
/// each of these widgets manage their participation in the overlay using
/// [OverlayEntry] objects.
///
/// Although you can create an [Overlay] directly, it's most common to use the
/// overlay created by the [Navigator] in a [WidgetsApp] or a [MaterialApp]. The
/// navigator uses its overlay to manage the visual appearance of its routes.
///
/// The [Overlay] widget uses a custom stack implementation, which is very
/// similar to the [Stack] widget. The main use case of [Overlay] is related to
/// navigation and being able to insert widgets on top of the pages in an app.
/// To simply display a stack of widgets, consider using [Stack] instead.
///
/// An [Overlay] widget requires a [Directionality] widget to be in scope, so
/// that it can resolve direction-sensitive coordinates of any
/// [Positioned.directional] children.
///
/// {@tool dartpad}
/// This example shows how to use the [Overlay] to highlight the [NavigationBar]
/// destination.
///
/// ** See code in examples/api/lib/widgets/overlay/overlay.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [OverlayEntry], the class that is used for describing the overlay entries.
///  * [OverlayState], which is used to insert the entries into the overlay.
///  * [WidgetsApp], which inserts an [Overlay] widget indirectly via its [Navigator].
///  * [MaterialApp], which inserts an [Overlay] widget indirectly via its [Navigator].
///  * [Stack], which allows directly displaying a stack of widgets.
class Overlay extends StatefulWidget {
  /// Creates an overlay.
  ///
  /// The initial entries will be inserted into the overlay when its associated
  /// [OverlayState] is initialized.
  ///
  /// Rather than creating an overlay, consider using the overlay that is
  /// created by the [Navigator] in a [WidgetsApp] or a [MaterialApp] for the application.
  const Overlay({
    super.key,
    this.initialEntries = const <OverlayEntry>[],
    this.clipBehavior = Clip.hardEdge,
  }) : assert(initialEntries != null),
       assert(clipBehavior != null);

  /// The entries to include in the overlay initially.
  ///
  /// These entries are only used when the [OverlayState] is initialized. If you
  /// are providing a new [Overlay] description for an overlay that's already in
  /// the tree, then the new entries are ignored.
  ///
  /// To add entries to an [Overlay] that is already in the tree, use
  /// [Overlay.of] to obtain the [OverlayState] (or assign a [GlobalKey] to the
  /// [Overlay] widget and obtain the [OverlayState] via
  /// [GlobalKey.currentState]), and then use [OverlayState.insert] or
  /// [OverlayState.insertAll].
  ///
  /// To remove an entry from an [Overlay], use [OverlayEntry.remove].
  final List<OverlayEntry> initialEntries;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.hardEdge], and must not be null.
  final Clip clipBehavior;

  /// The state from the closest instance of this class that encloses the given context.
  ///
  /// In debug mode, if the `debugRequiredFor` argument is provided then this
  /// function will assert that an overlay was found and will throw an exception
  /// if not. The exception attempts to explain that the calling [Widget] (the
  /// one given by the `debugRequiredFor` argument) needs an [Overlay] to be
  /// present to function.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// OverlayState overlay = Overlay.of(context)!;
  /// ```
  ///
  /// If `rootOverlay` is set to true, the state from the furthest instance of
  /// this class is given instead. Useful for installing overlay entries
  /// above all subsequent instances of [Overlay].
  ///
  /// This method can be expensive (it walks the element tree).
  static OverlayState? of(
    BuildContext context, {
    bool rootOverlay = false,
    Widget? debugRequiredFor,
  }) {
    final OverlayState? result = rootOverlay
        ? context.findRootAncestorStateOfType<OverlayState>()
        : context.findAncestorStateOfType<OverlayState>();
    assert(() {
      if (debugRequiredFor != null && result == null) {
        final List<DiagnosticsNode> information = <DiagnosticsNode>[
          ErrorSummary('No Overlay widget found.'),
          ErrorDescription('${debugRequiredFor.runtimeType} widgets require an Overlay widget ancestor for correct operation.'),
          ErrorHint('The most common way to add an Overlay to an application is to include a MaterialApp or Navigator widget in the runApp() call.'),
          DiagnosticsProperty<Widget>('The specific widget that failed to find an overlay was', debugRequiredFor, style: DiagnosticsTreeStyle.errorProperty),
          if (context.widget != debugRequiredFor)
            context.describeElement('The context from which that widget was searching for an overlay was'),
        ];

        throw FlutterError.fromParts(information);
      }
      return true;
    }());
    return result;
  }

  @override
  OverlayState createState() => OverlayState();
}

/// The current state of an [Overlay].
///
/// Used to insert [OverlayEntry]s into the overlay using the [insert] and
/// [insertAll] functions.
class OverlayState extends State<Overlay> with TickerProviderStateMixin {
  final List<OverlayEntry> _entries = <OverlayEntry>[];

  @override
  void initState() {
    super.initState();
    insertAll(widget.initialEntries);
  }

  int _insertionIndex(OverlayEntry? below, OverlayEntry? above) {
    assert(above == null || below == null);
    if (below != null) {
      return _entries.indexOf(below);
    }
    if (above != null) {
      return _entries.indexOf(above) + 1;
    }
    return _entries.length;
  }

  /// Insert the given entry into the overlay.
  ///
  /// If `below` is non-null, the entry is inserted just below `below`.
  /// If `above` is non-null, the entry is inserted just above `above`.
  /// Otherwise, the entry is inserted on top.
  ///
  /// It is an error to specify both `above` and `below`.
  void insert(OverlayEntry entry, { OverlayEntry? below, OverlayEntry? above }) {
    assert(_debugVerifyInsertPosition(above, below));
    assert(!_entries.contains(entry), 'The specified entry is already present in the Overlay.');
    assert(entry._overlay == null, 'The specified entry is already present in another Overlay.');
    entry._overlay = this;
    setState(() {
      _entries.insert(_insertionIndex(below, above), entry);
    });
  }

  /// Insert all the entries in the given iterable.
  ///
  /// If `below` is non-null, the entries are inserted just below `below`.
  /// If `above` is non-null, the entries are inserted just above `above`.
  /// Otherwise, the entries are inserted on top.
  ///
  /// It is an error to specify both `above` and `below`.
  void insertAll(Iterable<OverlayEntry> entries, { OverlayEntry? below, OverlayEntry? above }) {
    assert(_debugVerifyInsertPosition(above, below));
    assert(
      entries.every((OverlayEntry entry) => !_entries.contains(entry)),
      'One or more of the specified entries are already present in the Overlay.',
    );
    assert(
      entries.every((OverlayEntry entry) => entry._overlay == null),
      'One or more of the specified entries are already present in another Overlay.',
    );
    if (entries.isEmpty) {
      return;
    }
    for (final OverlayEntry entry in entries) {
      assert(entry._overlay == null);
      entry._overlay = this;
    }
    setState(() {
      _entries.insertAll(_insertionIndex(below, above), entries);
    });
  }

  bool _debugVerifyInsertPosition(OverlayEntry? above, OverlayEntry? below, { Iterable<OverlayEntry>? newEntries }) {
    assert(
      above == null || below == null,
      'Only one of `above` and `below` may be specified.',
    );
    assert(
      above == null || (above._overlay == this && _entries.contains(above) && (newEntries?.contains(above) ?? true)),
      'The provided entry used for `above` must be present in the Overlay${newEntries != null ? ' and in the `newEntriesList`' : ''}.',
    );
    assert(
      below == null || (below._overlay == this && _entries.contains(below) && (newEntries?.contains(below) ?? true)),
      'The provided entry used for `below` must be present in the Overlay${newEntries != null ? ' and in the `newEntriesList`' : ''}.',
    );
    return true;
  }

  /// Remove all the entries listed in the given iterable, then reinsert them
  /// into the overlay in the given order.
  ///
  /// Entries mention in `newEntries` but absent from the overlay are inserted
  /// as if with [insertAll].
  ///
  /// Entries not mentioned in `newEntries` but present in the overlay are
  /// positioned as a group in the resulting list relative to the entries that
  /// were moved, as specified by one of `below` or `above`, which, if
  /// specified, must be one of the entries in `newEntries`:
  ///
  /// If `below` is non-null, the group is positioned just below `below`.
  /// If `above` is non-null, the group is positioned just above `above`.
  /// Otherwise, the group is left on top, with all the rearranged entries
  /// below.
  ///
  /// It is an error to specify both `above` and `below`.
  void rearrange(Iterable<OverlayEntry> newEntries, { OverlayEntry? below, OverlayEntry? above }) {
    final List<OverlayEntry> newEntriesList = newEntries is List<OverlayEntry> ? newEntries : newEntries.toList(growable: false);
    assert(_debugVerifyInsertPosition(above, below, newEntries: newEntriesList));
    assert(
      newEntriesList.every((OverlayEntry entry) => entry._overlay == null || entry._overlay == this),
      'One or more of the specified entries are already present in another Overlay.',
    );
    assert(
      newEntriesList.every((OverlayEntry entry) => _entries.indexOf(entry) == _entries.lastIndexOf(entry)),
      'One or more of the specified entries are specified multiple times.',
    );
    if (newEntriesList.isEmpty) {
      return;
    }
    if (listEquals(_entries, newEntriesList)) {
      return;
    }
    final LinkedHashSet<OverlayEntry> old = LinkedHashSet<OverlayEntry>.of(_entries);
    for (final OverlayEntry entry in newEntriesList) {
      entry._overlay ??= this;
    }
    setState(() {
      _entries.clear();
      _entries.addAll(newEntriesList);
      old.removeAll(newEntriesList);
      _entries.insertAll(_insertionIndex(below, above), old);
    });
  }

  void _markDirty() {
    if (mounted) {
      setState(() {});
    }
  }

  /// (DEBUG ONLY) Check whether a given entry is visible (i.e., not behind an
  /// opaque entry).
  ///
  /// This is an O(N) algorithm, and should not be necessary except for debug
  /// asserts. To avoid people depending on it, this function is implemented
  /// only in debug mode, and always returns false in release mode.
  bool debugIsVisible(OverlayEntry entry) {
    bool result = false;
    assert(_entries.contains(entry));
    assert(() {
      for (int i = _entries.length - 1; i > 0; i -= 1) {
        final OverlayEntry candidate = _entries[i];
        if (candidate == entry) {
          result = true;
          break;
        }
        if (candidate.opaque) {
          break;
        }
      }
      return true;
    }());
    return result;
  }

  void _didChangeEntryOpacity() {
    setState(() {
      // We use the opacity of the entry in our build function, which means we
      // our state has changed.
    });
  }

  @override
  Widget build(BuildContext context) {
    // This list is filled backwards and then reversed below before
    // it is added to the tree.
    final List<Widget> children = <Widget>[];
    bool onstage = true;
    int onstageCount = 0;
    for (final OverlayEntry entry in _entries.reversed) {
      if (onstage) {
        onstageCount += 1;
        children.add(_OverlayEntryWidget(
          key: entry._key,
          overlayState: this,
          entry: entry,
        ));
        if (entry.opaque) {
          onstage = false;
        }
      } else if (entry.maintainState) {
        children.add(_OverlayEntryWidget(
          key: entry._key,
          overlayState: this,
          entry: entry,
          tickerEnabled: false,
        ));
      }
    }
    return _Theatre(
      skipCount: children.length - onstageCount,
      clipBehavior: widget.clipBehavior,
      children: children.reversed.toList(growable: false),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    // TODO(jacobr): use IterableProperty instead as that would
    // provide a slightly more consistent string summary of the List.
    properties.add(DiagnosticsProperty<List<OverlayEntry>>('entries', _entries));
  }
}

/// Special version of a [Stack], that doesn't layout and render the first
/// [skipCount] children.
///
/// The first [skipCount] children are considered "offstage".
class _Theatre extends MultiChildRenderObjectWidget {
  _Theatre({
    this.skipCount = 0,
    this.clipBehavior = Clip.hardEdge,
    super.children,
  }) : assert(skipCount != null),
       assert(skipCount >= 0),
       assert(children != null),
       assert(children.length >= skipCount),
       assert(clipBehavior != null);

  final int skipCount;

  final Clip clipBehavior;

  @override
  _TheatreElement createElement() => _TheatreElement(this);

  @override
  _RenderTheatre createRenderObject(BuildContext context) {
    return _RenderTheatre(
      skipCount: skipCount,
      textDirection: Directionality.of(context),
      clipBehavior: clipBehavior,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderTheatre renderObject) {
    renderObject
      ..skipCount = skipCount
      ..textDirection = Directionality.of(context)
      ..clipBehavior = clipBehavior;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('skipCount', skipCount));
  }
}

class _TheatreElement extends MultiChildRenderObjectElement {
  _TheatreElement(_Theatre super.widget);

  @override
  _RenderTheatre get renderObject => super.renderObject as _RenderTheatre;

  @override
  void insertRenderObjectChild(RenderBox child, IndexedSlot<Element?> slot) {
    super.insertRenderObjectChild(child, slot);
    final _TheatreParentData parentData = child.parentData! as _TheatreParentData;
    parentData.overlayEntry = ((widget as _Theatre).children[slot.index] as _OverlayEntryWidget).entry;
    assert(parentData.overlayEntry != null);
  }

  @override
  void moveRenderObjectChild(RenderBox child, IndexedSlot<Element?> oldSlot, IndexedSlot<Element?> newSlot) {
    super.moveRenderObjectChild(child, oldSlot, newSlot);
    assert(() {
      final _TheatreParentData parentData = child.parentData! as _TheatreParentData;
      return parentData.overlayEntry == ((widget as _Theatre).children[newSlot.index] as _OverlayEntryWidget).entry;
    }());
  }

  @override
  void debugVisitOnstageChildren(ElementVisitor visitor) {
    final _Theatre theatre = widget as _Theatre;
    assert(children.length >= theatre.skipCount);
    children.skip(theatre.skipCount).forEach(visitor);
  }
}

// A `RenderBox` that sizes itself to its parent's size, implements the stack
// layout algorithm and renders its children in the given `theatre`.
mixin _RenderTheatreMixin on RenderBox {
  _RenderTheatre get theatre;

  RenderBox? get _firstOnstageChild;
  RenderBox? get _lastOnstageChild;
  int get _onstageChildCount;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! StackParentData) {
      child.parentData = StackParentData();
    }
  }

  bool _layoutChild(RenderBox child, StackParentData childParentData, BoxConstraints nonPositionedChildConstraints, Alignment alignment) {
    if (!childParentData.isPositioned) {
      child.layout(nonPositionedChildConstraints, parentUsesSize: true);
      childParentData.offset = alignment.alongOffset(size - child.size as Offset);
      return false;
    } else {
      assert(child is! _RenderDeferredLayoutBox);
      return RenderStack.layoutPositionedChild(child, childParentData, size, alignment);
    }
  }

  @override
  bool get sizedByParent => true;

  @protected
  void layoutChild(RenderBox child, BoxConstraints constraints) {
    final StackParentData childParentData = child.parentData! as StackParentData;
    final bool hasVisualOverflow = _layoutChild(child, childParentData, constraints, theatre._resolvedAlignment);
    theatre._hasVisualOverflow = theatre._hasVisualOverflow || hasVisualOverflow;
  }

  @override
  void performLayout() {
    // `theatre` must override this method to reset _hasVisualOverflow.
    RenderBox? child = _firstOnstageChild;
    if (child == null) {
      return;
    }
    // Same BoxConstraints as used by RenderStack for StackFit.expand.
    final BoxConstraints nonPositionedChildConstraints = BoxConstraints.tight(constraints.biggest);
    while (child != null) {
      final StackParentData childParentData = child.parentData! as StackParentData;
      layoutChild(child, nonPositionedChildConstraints);
      assert(child.parentData == childParentData);
      child = childParentData.nextSibling;
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, { required Offset position }) {
    RenderBox? child = _lastOnstageChild;
    int childCount = _onstageChildCount;
    while (child != null) {
      final StackParentData childParentData = child.parentData! as StackParentData;
      final bool isHit = result.addWithPaintOffset(
        offset: childParentData.offset,
        position: position,
        hitTest: _toBoxHitTest(child.hitTest),
      );
      if (isHit) {
        return true;
      }
      childCount -= 1;
      child = childCount > 0 ? childParentData.previousSibling : null;
    }
    return false;
  }

  // `theatre` must override this method to handle clipping.
  @override
  void paint(PaintingContext context, Offset offset) {
    RenderBox? child = _firstOnstageChild;
    while (child != null) {
      final StackParentData childParentData = child.parentData! as StackParentData;
      context.paintChild(child, childParentData.offset + offset);
      child = childParentData.nextSibling;
    }
  }
}

class _TheatreParentData extends StackParentData {
  // Only RenderObjects created by OverlayEntries make use of this.
  late OverlayEntry overlayEntry;

  // _overlayStateMounted is set to null in _OverlayEntryWidgetState's dispose
  // method. This property is only accessed during layout, paint and hit-test so
  // the `value!` should be safe.
  _RenderTheatreChildModel? get topmostChildModel => overlayEntry._overlayStateMounted.value!._overlayEntryTopChildModel;
}

class _RenderTheatre extends RenderBox with ContainerRenderObjectMixin<RenderBox, StackParentData>, _RenderTheatreMixin {
  _RenderTheatre({
    List<RenderBox>? children,
    required TextDirection textDirection,
    int skipCount = 0,
    Clip clipBehavior = Clip.hardEdge,
  }) : assert(skipCount != null),
       assert(skipCount >= 0),
       assert(textDirection != null),
       assert(clipBehavior != null),
       _textDirection = textDirection,
       _skipCount = skipCount,
       _clipBehavior = clipBehavior {
    addAll(children);
  }

  @override
  _RenderTheatre get theatre => this;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _TheatreParentData) {
      child.parentData = _TheatreParentData();
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    RenderBox? child = firstChild;
    while (child != null) {
      final _TheatreParentData childParentData = child.parentData! as _TheatreParentData;
      childParentData.topmostChildModel?.visitChildren((RenderObject child) => child.attach(owner));
      child = childParentData.nextSibling;
    }
  }

  static void _detachChild(RenderObject child) => child.detach();
  @override
  void detach() {
    super.detach();
    RenderBox? child = firstChild;
    while (child != null) {
      final _TheatreParentData childParentData = child.parentData! as _TheatreParentData;
      childParentData.topmostChildModel?.visitChildren(_detachChild);
      child = childParentData.nextSibling;
    }
  }

  @override
  void redepthChild(AbstractNode child) => visitChildren(redepthChild);

  Alignment? _alignmentCache;
  Alignment get _resolvedAlignment => _alignmentCache ??= AlignmentDirectional.topStart.resolve(textDirection);

  void _markNeedResolution() {
    _alignmentCache = null;
    markNeedsLayout();
  }

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection == value) {
      return;
    }
    _textDirection = value;
    _markNeedResolution();
  }

  int get skipCount => _skipCount;
  int _skipCount;
  set skipCount(int value) {
    assert(value != null);
    if (_skipCount != value) {
      _skipCount = value;
      markNeedsLayout();
    }
  }

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.hardEdge], and must not be null.
  Clip get clipBehavior => _clipBehavior;
  Clip _clipBehavior = Clip.hardEdge;
  set clipBehavior(Clip value) {
    assert(value != null);
    if (value != _clipBehavior) {
      _clipBehavior = value;
      markNeedsPaint();
      markNeedsSemanticsUpdate();
    }
  }

  //late final _EventOrderChildModel _topChildren = _EventOrderChildModel(this);

  // Adding/removing deferred child does not affect the layout of other children,
  // or that of the Overlay, so there's no need to invalidate the layout of the
  // Overlay.
  //
  // When _skipMarkNeedsLayout is true, markNeedsLayout does not do anything.
  bool _skipMarkNeedsLayout = false;
  void _addDeferredChild(_RenderDeferredLayoutBox child) {
    assert(!_skipMarkNeedsLayout);
    _skipMarkNeedsLayout = true;

    adoptChild(child);
    // When child has never been laid out before, mark its layout surrogate as
    // needing layout so it's reachable via tree walk.
    child._layoutSurrogate.markNeedsLayout();
    _skipMarkNeedsLayout = false;
  }

  void _removeDeferredChild(_RenderDeferredLayoutBox child) {
    assert(!_skipMarkNeedsLayout);
    _skipMarkNeedsLayout = true;
    dropChild(child);
    _skipMarkNeedsLayout = false;
  }

  @override
  void markNeedsLayout() {
    if (_skipMarkNeedsLayout) {
      return;
    }
    super.markNeedsLayout();
  }

  @override
  RenderBox? get _firstOnstageChild {
    if (skipCount == super.childCount) {
      return null;
    }
    RenderBox? child = super.firstChild;
    for (int toSkip = skipCount; toSkip > 0; toSkip--) {
      final StackParentData childParentData = child!.parentData! as StackParentData;
      child = childParentData.nextSibling;
      assert(child != null);
    }
    return child;
  }

  @override
  RenderBox? get _lastOnstageChild => skipCount == super.childCount ? null : lastChild;

  @override
  int get _onstageChildCount => childCount - skipCount;

  @override
  double computeMinIntrinsicWidth(double height) {
    return RenderStack.getIntrinsicDimension(_firstOnstageChild, (RenderBox child) => child.getMinIntrinsicWidth(height));
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return RenderStack.getIntrinsicDimension(_firstOnstageChild, (RenderBox child) => child.getMaxIntrinsicWidth(height));
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return RenderStack.getIntrinsicDimension(_firstOnstageChild, (RenderBox child) => child.getMinIntrinsicHeight(width));
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return RenderStack.getIntrinsicDimension(_firstOnstageChild, (RenderBox child) => child.getMaxIntrinsicHeight(width));
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    assert(!debugNeedsLayout);
    double? result;
    RenderBox? child = _firstOnstageChild;
    while (child != null) {
      assert(!child.debugNeedsLayout);
      final StackParentData childParentData = child.parentData! as StackParentData;
      double? candidate = child.getDistanceToActualBaseline(baseline);
      if (candidate != null) {
        candidate += childParentData.offset.dy;
        if (result != null) {
          result = math.min(result, candidate);
        } else {
          result = candidate;
        }
      }
      child = childParentData.nextSibling;
    }
    return result;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    assert(constraints.biggest.isFinite);
    return constraints.biggest;
  }

  @override
  void performLayout() {
    _hasVisualOverflow = false;

    RenderBox? child = _firstOnstageChild;
    if (child == null) {
      return;
    }
    // Same BoxConstraints as used by RenderStack for StackFit.expand.
    final BoxConstraints nonPositionedChildConstraints = BoxConstraints.tight(constraints.biggest);
    while (child != null) {
      final _TheatreParentData childParentData = child.parentData! as _TheatreParentData;
      layoutChild(child, nonPositionedChildConstraints);
      assert(child.parentData == childParentData);
      final _ChildIterator? iterator = childParentData.topmostChildModel?._paintOrderIterator();
      if (iterator != null) {
        child = iterator();
        while (child != null) {
          layoutChild(child, nonPositionedChildConstraints);
          child = iterator();
        }
      }
      child = childParentData.nextSibling;
    }
  }

  bool _hasVisualOverflow = false;
  final LayerHandle<ClipRectLayer> _clipRectLayer = LayerHandle<ClipRectLayer>();

  void paintStack(PaintingContext context, Offset offset) {
    RenderBox? child = _firstOnstageChild;
    while (child != null) {
      final _TheatreParentData childParentData = child.parentData! as _TheatreParentData;
      context.paintChild(child, childParentData.offset + offset);
      childParentData.topmostChildModel?.paintChildren(context, offset);
      child = childParentData.nextSibling;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final bool shouldClip = _hasVisualOverflow && clipBehavior != Clip.none;
    final LayerHandle<ClipRectLayer> clipRectLayer = _clipRectLayer;
    if (shouldClip) {
      clipRectLayer.layer = context.pushClipRect(
        needsCompositing,
        offset,
        Offset.zero & size,
        paintStack,
        clipBehavior: clipBehavior,
        oldLayer: clipRectLayer.layer,
      );
    } else {
      clipRectLayer.layer = null;
      paintStack(context, offset);
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, { required Offset position }) {
    RenderBox? child = _lastOnstageChild;
    int childCount = _onstageChildCount;
    while (child != null) {
      final _TheatreParentData childParentData = child.parentData! as _TheatreParentData;
      final bool overlayChildrenHit = childParentData.topmostChildModel?.hitTestChildren(result, position) ?? false;
      final bool isHit = overlayChildrenHit || result.addWithPaintOffset(
        offset: childParentData.offset,
        position: position,
        hitTest: _toBoxHitTest(child.hitTest),
      );

      if (isHit) {
        return true;
      }

      childCount -= 1;
      child = childCount > 0 ? childParentData.previousSibling : null;
    }
    return false;
  }

  @override
  void dispose() {
    _clipRectLayer.layer = null;
    super.dispose();
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    RenderBox? child = firstChild;
    while (child != null) {
      visitor(child);
      final _TheatreParentData childParentData = child.parentData! as _TheatreParentData;
      childParentData.topmostChildModel?.visitChildren(_detachChild);
      child = childParentData.nextSibling;
    }

    while (child != null) {
      final StackParentData childParentData = child.parentData! as StackParentData;
      child = childParentData.nextSibling;
    }
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    RenderBox? child = _firstOnstageChild;
    while (child != null) {
      visitor(child);
      final _TheatreParentData childParentData = child.parentData! as _TheatreParentData;
      childParentData.topmostChildModel?.visitChildren(_detachChild);
      child = childParentData.nextSibling;
    }
  }

  @override
  Rect? describeApproximatePaintClip(RenderObject child) {
    switch (clipBehavior) {
      case Clip.none:
        return null;
      case Clip.hardEdge:
      case Clip.antiAlias:
      case Clip.antiAliasWithSaveLayer:
        return _hasVisualOverflow ? Offset.zero & size : null;
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('skipCount', skipCount));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection));
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    final List<DiagnosticsNode> offstageChildren = <DiagnosticsNode>[];
    final List<DiagnosticsNode> onstageChildren = <DiagnosticsNode>[];

    int count = 1;
    bool onstage = false;
    RenderBox? child = firstChild;
    final RenderBox? firstOnstageChild = _firstOnstageChild;
    while (child != null) {
      final _TheatreParentData childParentData = child.parentData! as _TheatreParentData;
      if (child == firstOnstageChild) {
        onstage = true;
        count = 1;
      }

      if (onstage) {
        onstageChildren.add(
          child.toDiagnosticsNode(
            name: 'onstage $count',
          ),
        );
      } else {
        offstageChildren.add(
          child.toDiagnosticsNode(
            name: 'offstage $count',
            style: DiagnosticsTreeStyle.offstage,
          ),
        );
      }

      int subcount = 1;
      childParentData.topmostChildModel?.visitChildren((RenderObject renderObject) {
        final RenderBox child = renderObject as RenderBox;
        if (onstage) {
          onstageChildren.add(
            child.toDiagnosticsNode(
              name: 'onstage $count - $subcount',
            ),
          );
        } else {
          offstageChildren.add(
            child.toDiagnosticsNode(
              name: 'offstage $count - $subcount',
              style: DiagnosticsTreeStyle.offstage,
            ),
          );
        }
        subcount += 1;
      });

      child = childParentData.nextSibling;
      count += 1;
    }

    return <DiagnosticsNode>[
      ...onstageChildren,
      if (offstageChildren.isNotEmpty)
        ...offstageChildren
      else
        DiagnosticsNode.message(
          'no offstage children',
          style: DiagnosticsTreeStyle.offstage,
        ),
    ];
  }
}

class _OverlayPortal extends RenderObjectWidget {
  /// Creates a widget that renders the given [overlayChild] in the [Overlay]
  /// specified by `overlayLocation`.
  ///
  /// The `overlayLocation` parameter must not be null when [overlayChild] is not
  /// null.
  _OverlayPortal({
    required this.overlayLocation,
    required this.overlayChild,
    required this.child,
  }) : assert(overlayChild == null || overlayLocation != null),
       assert(overlayLocation == null || overlayLocation._debugNotDisposed());

  final Widget? overlayChild;

  /// A widget below this widget in the tree.
  final Widget? child;

  final OverlayLocation? overlayLocation;

  @override
  RenderObjectElement createElement() => _OverlayPortalElement(this);

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderLayoutSurrogateProxyBox();
}

@immutable
class _OverlayChild {
  const _OverlayChild(this.element, this.slot, this.overlayChildWidget);

  final Element element;
  final OverlayLocation slot;
  final Widget overlayChildWidget;
}

class _OverlayPortalElement extends RenderObjectElement {
  _OverlayPortalElement(_OverlayPortal super.widget);

  @override
  _RenderLayoutSurrogateProxyBox get renderObject => super.renderObject as _RenderLayoutSurrogateProxyBox;

  _OverlayChild? _overlayChild;
  Element? _child;

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    final _OverlayPortal widget = this.widget as _OverlayPortal;
    _child = updateChild(_child, widget.child, null);
    _overlayChild = updateOverlayChild(_overlayChild, widget.overlayChild, widget.overlayLocation);
  }

  @override
  void update(_OverlayPortal newWidget) {
    super.update(newWidget);
    _child = updateChild(_child, newWidget.child, null);
    _overlayChild = updateOverlayChild(_overlayChild, newWidget.overlayChild, newWidget.overlayLocation);
  }

  _OverlayChild? updateOverlayChild(_OverlayChild? overlayChild, Widget? newOverlayChild, OverlayLocation? newSlot) {
    if (overlayChild?.overlayChildWidget == newOverlayChild) {
      if (overlayChild != null && newSlot != overlayChild.slot) {
        assert(newSlot != null);
        updateSlotForChild(overlayChild.element, newSlot);
        return _OverlayChild(overlayChild.element, newSlot!, overlayChild.overlayChildWidget);
      }
      // Skip updating and returns the current _overlayChild.
      return overlayChild;
    }

    if (newSlot != null && newOverlayChild != null) {
      final Element newElement = updateChild(overlayChild?.element, newOverlayChild, newSlot)!;
      return _OverlayChild(newElement, newSlot, newOverlayChild);
    } else {
      assert(newOverlayChild == null);
      final Element? newElement = updateChild(overlayChild?.element, null, null);
      assert(newElement == null);
      return null;
    }
  }

  @override
  void forgetChild(Element child) {
    // The _overlayChild Element does not have a key because the _DeferredLayout
    // widget does not take a Key, so only the regular _child can be taken
    // during global key reparenting.
    assert(child == _child);
    _child = null;
    super.forgetChild(child);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    final Element? child = _child;
    final Element? overlayChild = _overlayChild?.element;
    if (child != null) {
      visitor(child);
    }
    if (overlayChild != null) {
      visitor(overlayChild);
    }
  }

  @override
  void activate() {
    super.activate();
    final _OverlayChild? overlayChild = _overlayChild;
    final _RenderDeferredLayoutBox? box = _overlayChild?.element.renderObject as _RenderDeferredLayoutBox?;
    if (overlayChild != null && box != null) {
      assert(!box.attached);
      assert(renderObject._deferredLayoutChild == box);
      overlayChild.slot._activate(box);
    }
  }

  @override
  void deactivate() {
    final _OverlayChild? overlayChild = _overlayChild;
    final _RenderDeferredLayoutBox? box = _overlayChild?.element.renderObject as _RenderDeferredLayoutBox?;
    // Instead of just detaching the render objects, removing them from the
    // render subtree entirely such that if the widget gets reparented to a
    // different overlay entry, the overlay child is inserted in the right
    // position in the overlay's child list.
    //
    // This is also a workaround for the !renderObject.attached assert in the
    // `RenderObjectElement.deactive()` method.
    if (overlayChild != null && box != null) {
      overlayChild.slot._deactivate(box);
    }
    super.deactivate();
  }

  @override
  void insertRenderObjectChild(RenderBox child, OverlayLocation? slot) {
    assert(child.parent == null, "$child's parent is not null: ${child.parent}");
    if (slot != null) {
      renderObject._deferredLayoutChild = child as _RenderDeferredLayoutBox;
      slot._addChild(child);
    } else {
      renderObject.child = child;
    }
  }

  // The [_DeferredLayout] widget does not have a key so there will be no
  // reparenting between _overlayChild and _child, thus the non-null-typed slots.
  @override
  void moveRenderObjectChild(_RenderDeferredLayoutBox child, OverlayLocation oldSlot, OverlayLocation newSlot) {
    assert(newSlot._debugNotDisposed());
    newSlot._moveChild(child, oldSlot);
  }

  @override
  void removeRenderObjectChild(RenderBox child, OverlayLocation? slot) {
    if (slot == null) {
      renderObject.child = null;
      return;
    }
    assert(renderObject._deferredLayoutChild == child);
    slot._removeChild(child as _RenderDeferredLayoutBox);
    renderObject._deferredLayoutChild = null;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Element>('child', _child, defaultValue: null));
    properties.add(DiagnosticsProperty<Element>('overlayChild', _overlayChild?.element, defaultValue: null));
    properties.add(DiagnosticsProperty<OverlayLocation>('overlayLocation', _overlayChild?.slot, defaultValue: null));
  }
}

class _DeferredLayout extends SingleChildRenderObjectWidget {
  const _DeferredLayout({
    required Widget child,
  }) : super(child: child);

  _RenderLayoutSurrogateProxyBox getLayoutParent(BuildContext context) {
    return context.findAncestorRenderObjectOfType<_RenderLayoutSurrogateProxyBox>()!;
  }

  @override
  _RenderDeferredLayoutBox createRenderObject(BuildContext context) {
    final _RenderLayoutSurrogateProxyBox parent = getLayoutParent(context);
    final _RenderDeferredLayoutBox renderObject = _RenderDeferredLayoutBox(parent);
    parent._deferredLayoutChild = renderObject;
    return renderObject;
  }

  @override
  void updateRenderObject(BuildContext context, _RenderDeferredLayoutBox renderObject) {
    assert(renderObject._layoutSurrogate == getLayoutParent(context));
    assert(getLayoutParent(context)._deferredLayoutChild == renderObject);
  }
}

// A `RenderProxyBox` that defers its layout until its `_layoutSurrogate` is
// laid out.
//
// This `RenderObject` must be a child of a `_RenderTheatre`. It guarantees that:
//
// 1. It's a relayout boundary, and `markParentNeedsLayout` is overridden such
//    that it never dirties its `_RenderTheatre`.
//
// 2. Its `layout` implementation is overridden such that `performLayout` does
//    not do anything when its called from `layout`, preventing the parent
//    `_RenderTheatre` from laying out this subtree prematurely (but this
//    `RenderObject` may still be resized). Instead, `markNeedsLayout` will be
//    called from within `layout` to schedule a layout update for this relayout
//    boundary when needed.
//
// 3. When invoked from `PipelineOwner.flushLayout`, or
//    `_layoutSurrogate.performLayout`, this `RenderObject` behaves like an
//    `Overlay` that has only one entry.
class _RenderDeferredLayoutBox extends RenderProxyBox with _RenderTheatreMixin, LinkedListEntry<_RenderDeferredLayoutBox> {
  _RenderDeferredLayoutBox(this._layoutSurrogate);

  StackParentData get stackParentData => parentData! as StackParentData;
  final _RenderLayoutSurrogateProxyBox _layoutSurrogate;

  @override
  RenderBox? get _firstOnstageChild => child;

  @override
  RenderBox? get _lastOnstageChild => child;

  @override
  int get _onstageChildCount => child == null ? 0 : 1;

  @override
  _RenderTheatre get theatre {
    final AbstractNode? parent = this.parent;
    return parent is _RenderTheatre
      ? parent
      : throw FlutterError('$parent of $this is not a _RenderTheatre');
  }

  @override
  void redepthChildren() {
    _layoutSurrogate.redepthChild(this);
    super.redepthChildren();
  }

  bool _callingMarkParentNeedsLayout = false;
  @override
  void markParentNeedsLayout() {
    // No re-entrant calls.
    if (_callingMarkParentNeedsLayout) {
      return;
    }
    _callingMarkParentNeedsLayout = true;
    markNeedsLayout();
    _layoutSurrogate.markNeedsLayout();
    _callingMarkParentNeedsLayout = false;
  }

  bool _needsLayout = true;
  @override
  void markNeedsLayout() {
    _needsLayout = true;
    super.markNeedsLayout();
  }

  @override
  RenderObject? get debugLayoutParent => _layoutSurrogate;

  void layoutByLayoutSurrogate() {
    assert(!_parentDoingLayout);
    final _RenderTheatre? theatre = parent as _RenderTheatre?;
    if (theatre == null || !attached) {
      assert(false, '$this is not attached to parent');
      return;
    }
    super.layout(BoxConstraints.tight(theatre.constraints.biggest));
  }

  bool _parentDoingLayout = false;
  @override
  void layout(Constraints constraints, { bool parentUsesSize = false }) {
    assert(_needsLayout == debugNeedsLayout);
    // Only _RenderTheatre calls this implementation.
    assert(parent != null);
    final bool scheduleDeferredLayout = _needsLayout || this.constraints != constraints;
    assert(!_parentDoingLayout);
    _parentDoingLayout = true;
    super.layout(constraints, parentUsesSize: parentUsesSize);
    assert(_parentDoingLayout);
    _parentDoingLayout = false;
    _needsLayout = false;
    assert(!debugNeedsLayout);
    if (scheduleDeferredLayout) {
      final _RenderTheatre parent = this.parent! as _RenderTheatre;
      // Invoking markNeedsLayout as a layout callback allows this node to be
      // merged back to the `PipelineOwner` if it's not already dirty. Otherwise
      // this may cause some dirty descendants to performLayout a second time.
      parent.invokeLayoutCallback((BoxConstraints constraints) { markNeedsLayout(); });
    }
  }

  @override
  void performResize() {
    size = constraints.biggest;
  }

  bool _debugMutationsLocked = false;
  @override
  void performLayout() {
    assert(!_debugMutationsLocked);
    if (_parentDoingLayout) {
      _needsLayout = false;
      return;
    }
    assert(() {
      _debugMutationsLocked = true;
      return true;
    }());
    // This method is directly being invoked from `PipelineOwner.flushLayout`,
    // or from `_layoutSurrogate`'s performLayout.
    assert(parent != null);
    final RenderBox? child = this.child;
    if (child == null) {
      _needsLayout = false;
      return;
    }
    super.performLayout();
    assert(() {
      _debugMutationsLocked = false;
      return true;
    }());
    _needsLayout = false;
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final BoxParentData childParentData = child.parentData! as BoxParentData;
    final Offset offset = childParentData.offset;
    transform.translate(offset.dx, offset.dy);
  }
}

// A RenderProxyBox that makes sure its `deferredLayoutChild` has a greater
// depth than itself.
class _RenderLayoutSurrogateProxyBox extends RenderProxyBox {
  _RenderDeferredLayoutBox? _deferredLayoutChild;

  @override
  void redepthChildren() {
    super.redepthChildren();
    final _RenderDeferredLayoutBox? child = _deferredLayoutChild;
    // If child is not attached, this method will be invoked by child's real
    // parent when it's attached.
    if (child != null && child.attached) {
      assert(child.attached);
      redepthChild(child);
    }
  }

  @override
  void performLayout() {
    super.performLayout();
    // Try to layout `_deferredLayoutChild` here now that its configuration
    // and constraints are up-to-date. Additionally, during the very first
    // layout, this makes sure that _deferredLayoutChild is reachable via tree
    // walk.
    _deferredLayoutChild?.layoutByLayoutSurrogate();
  }
}
