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

typedef _ChildIterator = _Iterator<RenderBox>;
typedef _Iterator<T> = T? Function();

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

  //_RootOverlayLocation? _overlayLocation;
  _OverlayEntryLocation? _renderChildModel;

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
  bool get mounted => _overlayStateMounted.value;

  /// Whether the `_OverlayState`s built using this [OverlayEntry] is currently
  /// mounted.
  final ValueNotifier<bool> _overlayStateMounted = ValueNotifier<bool>(false);

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

class _OverlayLocationWidget extends StatefulWidget {
  const _OverlayLocationWidget({
    required this.referenceLocation,
    required this.child,
  });

  // This widget ensures that the `referenceLocation` it uses will never be
  // disposed when still being used by OverlayPortals. Once all OverlayPortals
  // stop using referenceLocation, unlink and dispose the location.
  //
  // For root locations owned by OverlayEntries no ref counting is needed.
  final _DoublyLinkedOverlayLocation referenceLocation;
  final Widget child;

  @override
  _OverlayLocationState createState() => _OverlayLocationState();
}

class _OverlayLocationState extends State<_OverlayLocationWidget> {
  _DoublyLinkedOverlayLocation get location => widget.referenceLocation.createNextIfAbsent(_OverlayLocation.new);

  @override
  void initState() {
    super.initState();
    widget.referenceLocation.attach();
  }

  @override
  void didUpdateWidget(_OverlayLocationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.referenceLocation != oldWidget.referenceLocation) {
      oldWidget.referenceLocation.detach();
      widget.referenceLocation.attach();
    }
  }

  @override
  void dispose() {
    widget.referenceLocation.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _OverlayLocationInheritedWidget(
      state: this,
      rootLocation: null,
      child: widget.child,
    );
  }
}

class _OverlayLocationInheritedWidget extends InheritedWidget {
  const _OverlayLocationInheritedWidget({
    required this.state,
    required this.rootLocation,
    required super.child,
  }) : assert(state != null || rootLocation != null),
       assert(state == null || rootLocation == null);

  final _OverlayLocationState? state;
  final _RootOverlayLocation? rootLocation;

  OverlayLocation get location {
    final _DoublyLinkedOverlayLocation location = rootLocation ?? state!.location;
    assert(!location._debugDisposed);
    return location;
  }

  @override
  bool updateShouldNotify(_OverlayLocationInheritedWidget oldWidget) {
    final _RootOverlayLocation? rootLocation = this.rootLocation;
    if (rootLocation != null && (oldWidget.rootLocation?._isTheSameLocation(rootLocation) ?? false)) {
      return true;
    }
    final _DoublyLinkedOverlayLocation? referenceLocation = state?.widget.referenceLocation;
    if (referenceLocation != null && (oldWidget.state?.widget.referenceLocation._isTheSameLocation(referenceLocation) ?? false)) {
      return true;
    }
    return false;
  }
}

mixin _SortedLinkedListChildModel<T extends Object> {
  T? _childAfter(T? child);
  T? _childBefore(T? child);

  _Iterator<T>? _forwardIterator() {
    T? child = _childAfter(null);
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

  _Iterator<T>? _backwardIterator() {
    T? child = _childBefore(null);
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
}

class _LocationOccupants extends LinkedList<_RenderDeferredLayoutBox> with _SortedLinkedListChildModel<_RenderDeferredLayoutBox>, _RenderTheatreChildModel {
  _LocationOccupants(this._theatre);

  @override
  final _RenderTheatre _theatre;

  @override
  void add(_RenderDeferredLayoutBox entry) {
    if (contains(entry)) {
      return;
    }
    super.add(entry);
  }

  @override
  _RenderDeferredLayoutBox? _childAfter(_RenderDeferredLayoutBox? child) {
    if (isEmpty) {
      return null;
    }
    final _RenderDeferredLayoutBox? next = child == null ? first : child.next;
    return next != null && next.parent == null ? _childAfter(next) : next;
  }

  @override
  _RenderDeferredLayoutBox? _childBefore(_RenderDeferredLayoutBox? child) {
    if (isEmpty) {
      return null;
    }
    final _RenderDeferredLayoutBox? prev = child == null ? last : child.previous;
    return prev != null && prev.parent == null ? _childBefore(prev) : prev;
  }

  @override
  _ChildIterator? _paintOrderIterator() => _forwardIterator();
  @override
  _ChildIterator? _hitTestOrderIterator() => _backwardIterator();
}

class _RootOverlayLocation extends _DoublyLinkedOverlayLocation {
  _RootOverlayLocation(
    _RenderTheatreChildModel childModel,
  ) : super(null, childModel);

  late _DoublyLinkedOverlayLocation first = this;
  late _DoublyLinkedOverlayLocation last = this;

  @override
  _RootOverlayLocation get root => this;

  @override
  String toString() {
    final String base = '${describeIdentity(this)}[$_children](root)';
    final _DoublyLinkedOverlayLocation? next = this.next;
    if (next == null) {
      return base;
    }
    return '$base -> ${describeIdentity(next)}';
  }
}

class _OverlayLocation extends _DoublyLinkedOverlayLocation {
  _OverlayLocation(_DoublyLinkedOverlayLocation referenceLocation)
    : root = referenceLocation.root,
      assert(referenceLocation._debugNotDisposed()),
      super(referenceLocation, referenceLocation._theatreChildModel);

  @override
  final _RootOverlayLocation root;

  @override
  void _dispose() {
    final _DoublyLinkedOverlayLocation? next = this.next;
    final _DoublyLinkedOverlayLocation? prev = this.prev;
    prev?.next = null;

    assert(linked);
    assert(next == null || next._debugNotDisposed());

    if (prev == null) {
      root.first = next!;
    } else if (next == null) {
      root.last = prev;
    }
    this.next = null;
    super._dispose();
    next?._dispose();
    assert(prev?.next == null);
  }

  @override
  String toString() {
    return _debugDisposed
      ? describeIdentity(this)
      : '${describeIdentity(this)}(disposed: $_debugDisposed)';
  }
}

abstract class _DoublyLinkedOverlayLocation extends OverlayLocation {
  _DoublyLinkedOverlayLocation(this.prev, this._theatreChildModel)
    : super._();

  final _DoublyLinkedOverlayLocation? prev;
  _DoublyLinkedOverlayLocation? next;
  _RootOverlayLocation get root;

  @override
  final _RenderTheatreChildModel _theatreChildModel;

  _DoublyLinkedOverlayLocation createNextIfAbsent(_DoublyLinkedOverlayLocation Function(_DoublyLinkedOverlayLocation) f) {
    assert(_debugNotDisposed());
    final _DoublyLinkedOverlayLocation? next = this.next;
    if (next != null) {
      assert(next._debugNotDisposed());
      return next;
    }
    final _DoublyLinkedOverlayLocation value = this.next = f(this);
    root.last = value;
    return value;
  }

  bool get linked => prev != null || next != null;

  int refCount = 0;
  void attach() {
    assert(_debugNotDisposed());
    refCount += 1;
  }

  void detach() {
    assert(_debugNotDisposed());
    refCount -= 1;
    assert(refCount >= 0);
    if (refCount > 0) {
      return;
    }

    // Clean up if the node is unused.
    _DoublyLinkedOverlayLocation? location = this;
    while (location != null && location.refCount <= 0 && location.next == null) {
      print('>>> $location(already disposed? ${location._debugDisposed}) refCount reaches 0, disposing.');
      location._dispose();
      location = location.prev;
    }
  }

  @override
  void _activate(_RenderDeferredLayoutBox child) {
    assert(_debugNotDisposed());
  }

  @override
  void _deactivate(_RenderDeferredLayoutBox child) {
  }

  @override
  _ChildIterator? _paintOrderIterator() {
    _ChildIterator? currentIterator = _children._forwardIterator();
    bool lastIterator = false;
    if (currentIterator == null) {
      return next?._paintOrderIterator();
    }
    return () {
      final _ChildIterator? iter = currentIterator;
      if (iter == null) {
        return null;
      }
      final RenderBox? child = iter();
      if (child != null) {
        return child;
      }
      currentIterator = lastIterator ? null : next?._paintOrderIterator();
      lastIterator = true;
      return currentIterator?.call();
    };
  }

  @override
  _ChildIterator? _hitTestOrderIterator() {
    _ChildIterator? currentIterator = _children._backwardIterator();
    if (currentIterator == null) {
      return prev?._hitTestOrderIterator();
    }
    bool lastIterator = false;
    return () {
      final _ChildIterator? iter = currentIterator;
      if (iter == null) {
        return null;
      }
      final RenderBox? child = iter();
      if (child != null) {
        return child;
      }
      currentIterator = lastIterator ? null : prev?._hitTestOrderIterator();
      lastIterator = true;
      return currentIterator?.call();
    };
  }

  late final _LocationOccupants _children = _LocationOccupants(_theatreChildModel._theatre);

  @override
  void _addToChildModel(_RenderDeferredLayoutBox child) {
    _children.add(child);
  }

  @override
  void _removeFromChildModel(_RenderDeferredLayoutBox child) {
    _children.remove(child);
  }

  @override
  bool _isTheSameLocation(OverlayLocation other) => identical(other, this);
}

class TopmostOverlayChildController {
  _TopmostOverlayChildState? _attachTarget;
  void show() {
    _attachTarget!.show();
  }
  void hide() {
    assert(SchedulerBinding.instance.schedulerPhase != SchedulerPhase.persistentCallbacks);
    _attachTarget!.hide();
  }
}

class TopmostOverlayChildWidget extends StatefulWidget {
  const TopmostOverlayChildWidget({
    super.key,
    required this.controller,
    required this.overlayChildBuilder,
    required this.child,
  });

  final TopmostOverlayChildController controller;

  final WidgetBuilder overlayChildBuilder;
  final Widget? child;

  @override
  State<TopmostOverlayChildWidget> createState() => _TopmostOverlayChildState();
}

class _TopmostLocation extends LinkedListEntry<_TopmostLocation> implements OverlayLocation {
  _TopmostLocation(this._showTimestamp, this._theatreChildModel);

  final DateTime _showTimestamp;
  @override
  final _TopOfTheatreChildModel _theatreChildModel;
  _RenderDeferredLayoutBox? _overlayChildRenderBox;

  @override
  void _addToChildModel(_RenderDeferredLayoutBox child) {
    assert(_overlayChildRenderBox == null, 'Failed to add $child. $_overlayChildRenderBox is attached to $this');
    _overlayChildRenderBox = child;
    assert(_showTimestamp != null);
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
    _overlayChildRenderBox = null;
  }

  @override
  void _deactivate(_RenderDeferredLayoutBox child) {
    assert(_overlayChildRenderBox == null);
    _overlayChildRenderBox = child;
  }

  @override
  bool _debugNotDisposed() {
    if (!_debugDisposed) {
      return true;
    }
    throw FlutterError('$this is already disposed');
  }
  @override
  bool _debugDisposed = false;
  @override
  void _dispose() {
    assert(!_debugDisposed);
    assert(() {
      _debugDisposed = true;
      return true;
    }());
  }

  @override
  bool _isTheSameLocation(OverlayLocation other) {
    if (identical(other, this)) {
      return true;
    }
    return other is _TopmostLocation
        && other._showTimestamp == _showTimestamp
        && other._theatreChildModel == _theatreChildModel;
  }
}

class _TopmostOverlayChildState extends State<TopmostOverlayChildWidget> {
  // The developer must call `show` to reveal the overlay so we can get the
  // timestamp of the user interaction for sorting.
  _TopmostLocation? _location;
  DateTime? _showTimestamp;

  @override
  void initState() {
    super.initState();
    widget.controller._attachTarget = this;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _location = null;
  }

  @override
  void didUpdateWidget(TopmostOverlayChildWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller._attachTarget = null;
      widget.controller._attachTarget = this;
    }
  }

  @override
  void dispose() {
    widget.controller._attachTarget = null;
    super.dispose();
  }

  /// "bringToTop" is O(1) but insert could be O(n) where n is the number of new
  /// children inserted in the same frame at baseLocation.
  void show() {
    assert(SchedulerBinding.instance.schedulerPhase != SchedulerPhase.persistentCallbacks);
    final DateTime now = DateTime.now();
    final DateTime? lastTimeStampe = _showTimestamp;
    if (lastTimeStampe != null) {
      // Bring to the front.
      assert(lastTimeStampe.isBefore(now));
    } else {
      setState(() { _showTimestamp = now; });
    }
    _location = null;
  }

  /// O(1);
  void hide() {
    assert(_showTimestamp != null);
    assert(SchedulerBinding.instance.schedulerPhase != SchedulerPhase.persistentCallbacks);
    _showTimestamp = null;
    _location = null;
  }

  @override
  Widget build(BuildContext context) {
    final DateTime? timestamp = _showTimestamp;
    if (timestamp == null) {
      return OverlayPortal.withLocation(
        overlayLocation: null,
        overlayChild: null,
        child: widget.child,
      );
    }
    final _TopOfTheatreChildModel? top = context.dependOnInheritedWidgetOfExactType<_OverlayLocationInheritedWidget>()?.location._theatreChildModel._theatre._topChildren;
    _location ??= _TopmostLocation(timestamp, top!);
    return OverlayPortal.withLocation(
      overlayLocation: _location,
      overlayChild: Builder(builder: widget.overlayChildBuilder),
      child: widget.child,
    );
  }
}

abstract class _RenderTheatreChildModel {
  /// The underlying [RenderObject] of the [Overlay] this [OverlayLocation]
  /// targets.
  _RenderTheatre get _theatre;

  _ChildIterator? _paintOrderIterator();
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
}

// The data structure for managing the stack of theatre children that claim the
// topmost position in terms of paint order.
//
// The children with more recent timestamps (i.e. those called `show` recently)
// will be painted last.
class _TopOfTheatreChildModel extends _RenderTheatreChildModel with _SortedLinkedListChildModel<_TopmostLocation> {
  _TopOfTheatreChildModel(this._theatre);

  final LinkedList<_TopmostLocation> _sortedChildren = LinkedList<_TopmostLocation>();

  @override
  final _RenderTheatre _theatre;

  // Worst-case O(N) where N is the number of children added to the top spot
  // in the same frame.
  void _add(_TopmostLocation child) {
    assert(!_sortedChildren.contains(child));
    _TopmostLocation? insertPosition;
    while (insertPosition != null && insertPosition._showTimestamp.isAfter(child._showTimestamp)) {
      insertPosition = insertPosition.previous;
    }
    if (insertPosition == null) {
      _sortedChildren.addFirst(child);
    } else {
      insertPosition.insertAfter(child);
    }

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

  @override
  _TopmostLocation? _childAfter(_TopmostLocation? child) {
    if (_sortedChildren.isEmpty) {
      return null;
    }
    final _TopmostLocation? candidate = child == null ? _sortedChildren.first : child.next;
    return candidate?._overlayChildRenderBox != null ? candidate : _childAfter(candidate);
  }

  @override
  _TopmostLocation? _childBefore(_TopmostLocation? child) {
    if (_sortedChildren.isEmpty) {
      return null;
    }
    final _TopmostLocation? candidate = child == null ? _sortedChildren.last : child.previous;
    return candidate?._overlayChildRenderBox != null ? candidate : _childBefore(candidate);
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

  @override
  _ChildIterator? _paintOrderIterator() => _TopOfTheatreChildModel._mapIterator(_forwardIterator());
  @override
  _ChildIterator? _hitTestOrderIterator() => _TopOfTheatreChildModel._mapIterator(_backwardIterator());
}

class _OverlayEntryLocation extends OverlayLocation with LinkedListEntry<_OverlayEntryLocation> {
  _OverlayEntryLocation(this._theatreChildModel) : super._();

  @override
  final LinkedList<LocationOccupants> _theatreChildModel;

  @override
  void _activate(_RenderDeferredLayoutBox child) {
  }

  @override
  void _deactivate(_RenderDeferredLayoutBox child) {
  }

  @override
  void _addToChildModel(_RenderDeferredLayoutBox child) {
  }

  @override
  void _removeFromChildModel(_RenderDeferredLayoutBox child) {
  }

  @override
  bool _isTheSameLocation(OverlayLocation other) => identical(this, other);
}

class _OverlayEntryChildModel extends _RenderTheatreChildModel with _SortedLinkedListChildModel<_OverlayEntryLocation> {
  _OverlayEntryChildModel(this._theatre);

  final LinkedList<_OverlayEntryLocation> _children = LinkedList<_OverlayEntryLocation>();

  @override
  final _RenderTheatre _theatre;

  @override
  _OverlayEntryLocation? _childAfter(_OverlayEntryLocation? child) {
    assert(child == null || child.list == _children);
    return child == null ? _children.first : child.next;
  }

  @override
  _OverlayEntryLocation? _childBefore(_OverlayEntryLocation? child) {
    assert(child == null || child.list == _children);
    return child == null ? _children.last : child.previous;
  }

  @override
  _ChildIterator? _paintOrderIterator() => _forwardIterator();

  @override
  _ChildIterator? _hitTestOrderIterator() => _backwardIterator();
}


/// A location in a particular [Overlay].
///
/// An [OverlayLocation] is an immutable object that contains information about
/// an [Overlay] and the relative paint order (as well as its relative hit-test
/// order) to another child in the [Overlay].
///
/// An [OverlayLocation] created for one [Overlay] can not be used in another
/// [Overlay]. If multiple children in the same [Overlay] occupy the same
/// [OverlayLocation], their paint order relative to one another is undefined.
abstract class OverlayLocation {
  OverlayLocation._();

  _RenderTheatreChildModel get _theatreChildModel;

  /// Returns an [OverlayLocation] that represents a location in the same
  /// [Overlay] as the enclosing [OverlayEntry] or [OverlayPortal], but later in
  /// paint order than the [OverlayEntry] or [OverlayPortal]'s `overlayChild'.
  ///
  /// In other words, this method returns the [afterLocation] of the enclosing
  /// [OverlayLocation].
  ///
  /// The widget subtree associated with the given `context` will be notified
  /// when the enclosing [OverlayLocation] changes.
  ///
  /// This method returns null when no enclosing [Overlay] can be found in the
  /// given [context].
  static OverlayLocation? _above(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_OverlayLocationInheritedWidget>()?.location;
  }

  void _addToChildModel(_RenderDeferredLayoutBox child);
  void _removeFromChildModel(_RenderDeferredLayoutBox child);
  void _activate(_RenderDeferredLayoutBox child);
  void _deactivate(_RenderDeferredLayoutBox child);

  bool _isTheSameLocation(OverlayLocation other);

  bool _debugNotDisposed() {
    if (!_debugDisposed) {
      return true;
    }
    throw FlutterError('$this is already disposed');
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
    required this.reversedIndex,
    this.tickerEnabled = true,
  }) : assert(key != null),
       assert(entry != null),
       assert(tickerEnabled != null),
       super(key: key);

  final OverlayEntry entry;
  final bool tickerEnabled;
  final OverlayState overlayState;

  final int reversedIndex;

  @override
  _OverlayEntryWidgetState createState() => _OverlayEntryWidgetState();
}

class _OverlayEntryWidgetState extends State<_OverlayEntryWidget> {

  @override
  void initState() {
    super.initState();
    widget.entry._overlayStateMounted.value = true;
    //widget.entry._overlayLocation = _RootOverlayLocation(context.findAncestorRenderObjectOfType<_RenderTheatre>()!)..attach();
    widget.entry._renderChildModel = _OverlayEntryLocation(_theatreChildModel)
  }

  @override
  void didUpdateWidget(_OverlayEntryWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // OverlayState's build method always returns a RenderObjectWidget _Theatre,
    // so it's safe to assume that state equality implies render object equality.
    if (oldWidget.overlayState != widget.overlayState) {
      assert(oldWidget.entry == widget.entry);
      oldWidget.entry._overlayLocation?._dispose();
      oldWidget.entry._overlayLocation = null;
      widget.entry._overlayLocation = _RootOverlayLocation(context.findAncestorRenderObjectOfType<_RenderTheatre>()!)..attach();
    }
  }

  @override
  void dispose() {
    widget.entry._overlayLocation?._dispose();
    widget.entry._overlayLocation = null;
    widget.entry._overlayStateMounted.value = false;
    widget.entry._didUnmount();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TickerMode(
      enabled: widget.tickerEnabled,
      child: _OverlayLocationInheritedWidget(
        state: null,
        rootLocation: widget.entry._overlayLocation,
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
  /// OverlayState overlay = Overlay.of(context);
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
          reversedIndex: children.length,
        ));
        if (entry.opaque) {
          onstage = false;
        }
      } else if (entry.maintainState) {
        children.add(_OverlayEntryWidget(
          key: entry._key,
          overlayState: this,
          entry: entry,
          reversedIndex: children.length,
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
  void debugVisitOnstageChildren(ElementVisitor visitor) {
    final _Theatre theatre = widget as _Theatre;
    assert(children.length >= theatre.skipCount);
    children.skip(theatre.skipCount).forEach(visitor);
  }

  @override
  void insertRenderObjectChild(RenderBox child, IndexedSlot<Element?> slot) {
    super.insertRenderObjectChild(child, slot);
    final _TheatreParentData parentData = child.parentData! as _TheatreParentData;
    parentData.location = ((widget as _Theatre).children[slot.index] as _OverlayEntryWidget).entry._overlayLocation;
    assert(parentData.location != null);
  }

  @override
  void moveRenderObjectChild(RenderBox child, IndexedSlot<Element?> oldSlot, IndexedSlot<Element?> newSlot) {
    super.moveRenderObjectChild(child, oldSlot, newSlot);
    assert(() {
      final _TheatreParentData parentData = child.parentData! as _TheatreParentData;
      return parentData.location == ((widget as _Theatre).children[newSlot.index] as _OverlayEntryWidget).entry._overlayLocation;
    }());
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
    final Alignment alignment = theatre._resolvedAlignment;
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
  _RootOverlayLocation? location;
}

class _RenderTheatre extends RenderBox with ContainerRenderObjectMixin<RenderBox, _TheatreParentData>, _RenderTheatreMixin {
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
      final _ChildIterator? forwardIterator = childParentData.location!._paintOrderIterator();
      RenderBox? deferredChild = forwardIterator?.call();
      while (deferredChild != null) {
        print('> attaching $deferredChild');
        deferredChild.attach(owner);
        deferredChild = forwardIterator!();
      }
      // The super implementation already attaches `child`.
      child = childParentData.nextSibling;
    }
  }

  @override
  void detach() {
    super.detach();
    RenderBox? child = firstChild;
    while (child != null) {
      final _TheatreParentData childParentData = child.parentData! as _TheatreParentData;
      final _ChildIterator? forwardIterator = childParentData.location!._paintOrderIterator();
      RenderBox? deferredChild = forwardIterator?.call();
      while (deferredChild != null) {
        print('< detaching $deferredChild');
        deferredChild.detach();
        deferredChild = forwardIterator!();
      }
      // The super implementation already detaches `child`.
      child = childParentData.nextSibling;
    }
  }

  @override
  void redepthChildren() => visitChildren(redepthChild);

  late final _TopOfTheatreChildModel _topChildren = _TopOfTheatreChildModel(this);

  // Adding/removing deferred child does not affect the layout of other children,
  // or that of the Overlay, so there's no need to invalidate the layout of the
  // Overlay.
  //
  // When _skipMarkNeedsLayout is true, markNeedsLayout does not do anything.
  bool _skipMarkNeedsLayout = false;
  void addDeferredChild(_RenderDeferredLayoutBox child, OverlayLocation location) {
    assert(!_skipMarkNeedsLayout);
    _skipMarkNeedsLayout = true;

    adoptChild(child);
    location._addToChildModel(child);
    markNeedsPaint();

    // When child has never been laid out before, mark its layout surrogate as
    // needing layout so it's reachable via tree walk.
    child._layoutSurrogate.markNeedsLayout();

    _skipMarkNeedsLayout = false;
  }

  void moveDeferredChild(_RenderDeferredLayoutBox child, OverlayLocation oldLocation, OverlayLocation newLocation) {
    //throw UnimplementedError();
  }

  void removeDeferredChild(_RenderDeferredLayoutBox child, OverlayLocation location) {
    assert(!_skipMarkNeedsLayout);
    _skipMarkNeedsLayout = true;
    location._removeFromChildModel(child);
    dropChild(child);
    markNeedsPaint();
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
      final _ChildIterator? forwardIterator = childParentData.location!._paintOrderIterator();
      RenderBox? deferredChild = forwardIterator?.call();
      //print('Deferred child > $deferredChild');
      while (deferredChild != null) {
        print('laying out deferred child > $deferredChild');
        layoutChild(deferredChild, nonPositionedChildConstraints);
        deferredChild = forwardIterator!();
      }
      assert(child.parentData == childParentData);
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
      //print('painting: $child ${childParentData.location!}, ${childParentData.location!._children}');
      final _ChildIterator? forwardIterator = childParentData.location!.first._paintOrderIterator();
      RenderBox? deferredLayoutBox = forwardIterator?.call();
      while(deferredLayoutBox != null) {
        context.paintChild(deferredLayoutBox, childParentData.offset + offset);
        deferredLayoutBox = forwardIterator?.call();
      }
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
    _topChildren.hitTestChildren(result, position);
    RenderBox? child = _lastOnstageChild;
    int childCount = _onstageChildCount;
    bool hitTest(bool currentValue, _ChildIterator iterator) {
      if (currentValue) {
        return true;
      }
      final RenderBox? child = iterator();
      if (child == null) {
        return false;
      }
      final _TheatreParentData childParentData = child.parentData! as _TheatreParentData;
      final bool newValue = result.addWithPaintOffset(offset: childParentData.offset, position: position, hitTest: _toBoxHitTest(child.hitTest));
      return hitTest(newValue, iterator);
    }
    while (child != null) {
      final _TheatreParentData childParentData = child.parentData! as _TheatreParentData;
      final _ChildIterator? iterator = childParentData.location!.last._hitTestOrderIterator();
      final bool isHit = (iterator != null && hitTest(false, iterator))
                      || result.addWithPaintOffset(
                           offset: childParentData.offset,
                           position: position,
                           hitTest: _toBoxHitTest(child.hitTest),
                         );

      print('${isHit ? 'HIT' : 'NOT HIT'} @ $position == $child (${childParentData.offset})');
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
      //print('-- visiting child (entry): $child');
      final _TheatreParentData childParentData = child.parentData! as _TheatreParentData;
      final _ChildIterator? forwardIterator = childParentData.location!.first._paintOrderIterator();
      RenderBox? renderChild = forwardIterator?.call();
      while (renderChild != null) {
        visitor(renderChild);
        //print('   visiting child: $renderChild');
        renderChild = forwardIterator!();
      }
      child = childParentData.nextSibling;
    }
    _topChildren.visitChildren(visitor);
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    RenderBox? child = _firstOnstageChild;
    while (child != null) {
      visitor(child);
      final _TheatreParentData childParentData = child.parentData! as _TheatreParentData;
      final _ChildIterator? forwardIterator = childParentData.location!.first._paintOrderIterator();
      RenderBox? renderChild = forwardIterator?.call();
      while (renderChild != null) {
        visitor(renderChild);
        renderChild = forwardIterator!();
      }
      child = childParentData.nextSibling;
    }
    _topChildren.visitChildren(visitor);
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

      final StackParentData childParentData = child.parentData! as StackParentData;
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

/// A widget that renders its [overlayChild] in the [Overlay] specified by
/// [referenceLocation].
///
/// The [overlayChild] will be rendered on the [Overlay] as if it was inserted
/// using an [OverlayEntry], while it can depend on the same set of
/// [InheritedWidget]s (such as [Theme]) that this widget can depend on.
///
/// This widget must be placed below the [Overlay] [referenceLocation] points to, and
/// [referenceLocation] must not be null when [overlayChild] is not null.
///
/// {@tool dartpad}
/// This example uses an [OverlayPortal] to build a tooltip that becomes visible
/// when the user taps on the [child] widget. There's a [DefaultTextStyle] above
/// the [OverlayPortal] controlling the [TextStyle] of both the [child] widget
/// and the [overlayChild] widget, which isn't otherwise doable if the tooltip
/// was added as an [OverlayEntry].
///
/// ** See code in examples/api/lib/widgets/overlay/overlay_portal.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [OverlayEntry], the imperative API for inserting a widget to an [Overlay].
class OverlayPortal extends StatelessWidget {
  /// Creates a widget that renders the given [overlayChild] in the closest
  /// ancestor [Overlay].
  const OverlayPortal.closest({
    super.key,
    required this.overlayChild,
    required this.child,
  }) : _overlayLocation = null,
       _overlayLocationGetter = _above;

  /// Creates a widget that renders the given [overlayChild] in the [Overlay]
  /// specified by `overlayLocation`.
  ///
  /// The `overlayLocation` parameter must not be null when [overlayChild] is not
  /// null.
  const OverlayPortal.withLocation({
    super.key,
    required OverlayLocation? overlayLocation,
    required this.overlayChild,
    required this.child,
  }) : _overlayLocation = overlayLocation,
       _overlayLocationGetter = _bottom;

  /// A widget below this widget in the tree, that renders on the [Overlay]
  /// given by the [OverlayLocation] specified.
  ///
  /// The [overlayChild] widget, if not null, is inserted below this widget in
  /// the widget tree, allowing it to depend on [InheritedWidget]s above it, and
  /// be notified when the [InheritedWidget]s change.
  ///
  /// Unlike [child], [overlayChild] can visually extend outside the bounds
  /// of this widget without being clipped, and receive hit-test events outside
  /// of this widget's bounds, as long as it does not extend outside of the
  /// [Overlay] on which it is rendered.
  final Widget? overlayChild;

  /// A widget below this widget in the tree.
  final Widget? child;

  final OverlayLocation Function(BuildContext) _overlayLocationGetter;
  final OverlayLocation? _overlayLocation;

  static Never _bottom<T>(T idc) => throw FlutterError('Unreachable!');
  static OverlayLocation _above(BuildContext context) => OverlayLocation._above(context)!;

  @override
  Widget build(BuildContext context) {
    final Widget? overlayChild = this.overlayChild;
    if (overlayChild == null) {
      return _OverlayPortal(overlayLocation: null, overlayChild: null, child: child);
    }

    final OverlayLocation location = _overlayLocation ?? _overlayLocationGetter(context);
    return _OverlayPortal(
      overlayLocation: location,
      overlayChild: _OverlayLocationWidget(
        referenceLocation: location,
        child: _DeferredLayout(child: overlayChild),
      ),
      child: child,
    );
  }
}

class _OverlayPortal extends RenderObjectWidget {
  _OverlayPortal({
    required this.overlayLocation,
    required this.overlayChild,
    required this.child,
  }) : assert(overlayChild == null || overlayLocation != null),
       assert(overlayLocation == null || overlayLocation._debugNotDisposed());

  /// A widget below this widget in the tree, that renders on the [Overlay]
  /// given by the [OverlayLocation] specified.
  ///
  /// The [overlayChild] widget, if not null, is inserted below this widget in
  /// the widget tree, allowing it to depend on [InheritedWidget]s above it, and
  /// be notified when the [InheritedWidget]s change.
  ///
  /// Unlike [child], [overlayChild] can visually extend outside the bounds
  /// of this widget without being clipped, and receive hit-test events outside
  /// of this widget's bounds, as long as it does not extend outside of the
  /// [Overlay] on which it is rendered.
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
      overlayChild.slot._theatreChildModel._theatre.adoptChild(box);
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
      overlayChild.slot._theatreChildModel._theatre.dropChild(box);
      overlayChild.slot._deactivate(box);
    }
    super.deactivate();
  }

  @override
  void unmount() {
    final _OverlayChild? overlayChild = _overlayChild;
    if (overlayChild != null) {
      final _RenderDeferredLayoutBox? child = overlayChild.element.renderObject as _RenderDeferredLayoutBox?;
      if (child != null) {
        overlayChild.slot._removeFromChildModel(child);
      }
    }
    super.unmount();
  }

  @override
  void insertRenderObjectChild(RenderBox child, OverlayLocation? slot) {
    assert(child.parent == null, "$child's parent is not null: ${child.parent}");
    if (slot != null) {
      renderObject._deferredLayoutChild = child as _RenderDeferredLayoutBox;
      slot._theatreChildModel._theatre.addDeferredChild(child, slot);
    } else {
      renderObject.child = child;
    }
  }

  // The [_DeferredLayout] widget does not have a key so there will be no
  // reparenting between _overlayChild and _child, thus the non-null-typed slots.
  @override
  void moveRenderObjectChild(_RenderDeferredLayoutBox child, OverlayLocation oldSlot, OverlayLocation newSlot) {
    assert(newSlot._debugNotDisposed());
    final _RenderTheatre oldTheatre = oldSlot._theatreChildModel._theatre;
    if (oldTheatre != newSlot._theatreChildModel._theatre) {
      // Moving to a different Overlay.
      oldSlot._theatreChildModel._theatre.removeDeferredChild(child, oldSlot);
      newSlot._theatreChildModel._theatre.addDeferredChild(child, newSlot);
      return;
    }
    oldSlot._removeFromChildModel(child);
    newSlot._addToChildModel(child);
  }

  @override
  void removeRenderObjectChild(RenderBox child, OverlayLocation? slot) {
    if (slot == null) {
      renderObject.child = null;
      return;
    }
    assert(renderObject._deferredLayoutChild == child);
    slot._theatreChildModel._theatre.removeDeferredChild(child as _RenderDeferredLayoutBox, slot);
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
