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

  OverlayLocation? _overlayLocation;

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

class _OverlayLocationWidget extends StatelessWidget {
  const _OverlayLocationWidget({
    required this.overlayLocation,
    required this.child,
  });

  final OverlayLocation overlayLocation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _OverlayLocationInheritedWidget(
      overlayLocation: overlayLocation,
      //child: _OverlayLocationParentData(overlayLocation: overlayLocation, child: child),
      child: child,
    );
  }
}

class _OverlayLocationInheritedWidget extends InheritedWidget {
  const _OverlayLocationInheritedWidget({
    required this.overlayLocation,
    required super.child,
  });

  final OverlayLocation overlayLocation;

  @override
  bool updateShouldNotify(_OverlayLocationInheritedWidget oldWidget) => oldWidget.overlayLocation != overlayLocation;
}

class _LocationOccupants {
  _LocationOccupants();

  late final Set<RenderBox> _debugMembers = <RenderBox>{ };

  _RenderDeferredLayoutBox? _firstChild;
  _RenderDeferredLayoutBox? _lastChild;

  void add(_RenderDeferredLayoutBox child) {
    assert(_debugMembers.add(child), '$child was already in $_debugMembers');
    final StackParentData childParentData = child.parentData! as StackParentData;
    assert(childParentData.previousSibling == null);
    assert(childParentData.nextSibling == null);
    final StackParentData? prevParentData = _lastChild?.parentData! as StackParentData?;
    prevParentData?.nextSibling = child;
    childParentData.previousSibling = _lastChild;
    _firstChild ??= child;
    _lastChild = child;
  }

  void remove(_RenderDeferredLayoutBox child) {
    assert(_debugMembers.remove(child), 'Attempt to remove a non-existent member $child from $_debugMembers');
    final StackParentData childParentData = child.parentData! as StackParentData;
    final StackParentData? prevParentData = childParentData.previousSibling?.parentData as StackParentData?;
    final StackParentData? nextParentData = childParentData.nextSibling?.parentData as StackParentData?;
    if (prevParentData != null) {
      prevParentData.nextSibling = childParentData.nextSibling;
    } else {
      _firstChild = childParentData.nextSibling! as _RenderDeferredLayoutBox;
    }
    if (nextParentData != null) {
      nextParentData.previousSibling = childParentData.previousSibling;
    } else {
      _lastChild = childParentData.previousSibling! as _RenderDeferredLayoutBox;
    }
    childParentData.previousSibling = null;
    childParentData.nextSibling = null;
  }

  RenderBox? childAfter(RenderBox child) {
    assert(_debugMembers.contains(child));
    final StackParentData childParentData = child.parentData! as StackParentData;
    return childParentData.nextSibling;
  }

  RenderBox? childBefore(RenderBox child) {
    assert(_debugMembers.contains(child));
    final StackParentData childParentData = child.parentData! as StackParentData;
    return childParentData.previousSibling;
  }
}

//class _OverlayChildIterator extends Iterator<_RenderDeferredLayoutBox> {
//  _OverlayChildIterator(this.location, this.currentChild);
//
//  OverlayLocation location;
//  _RenderDeferredLayoutBox currentChild;
//
//  @override
//  _RenderDeferredLayoutBox get current => currentChild;
//
//  @override
//  bool moveNext() {
//    final StackParentData childParentData = currentChild.parentData! as StackParentData;
//    final _RenderDeferredLayoutBox? localNext = childParentData.nextSibling as _RenderDeferredLayoutBox?;
//    if (localNext != null) {
//      currentChild = localNext;
//      return true;
//    }
//    OverlayLocation? nextLocation = location._links.next;
//    while (nextLocation != null && nextLocation._children == null) {
//      nextLocation = nextLocation._links.next;
//    }
//    final _LocationOccupants? nextLocationChildren = nextLocation?._children;
//    if (nextLocation != null && nextLocationChildren != null) {
//      location = nextLocation;
//      currentChild = nextLocationChildren._firstChild;
//      return true;
//    }
//    return false;
//  }
//
//  bool movePrev() {
//    final StackParentData childParentData = currentChild.parentData! as StackParentData;
//    final _RenderDeferredLayoutBox? localPrev = childParentData.previousSibling as _RenderDeferredLayoutBox?;
//    if (localPrev != null) {
//      currentChild = localPrev;
//      return true;
//    }
//    OverlayLocation? prevLocation = location._before;
//    while (prevLocation != null && prevLocation._children == null) {
//      prevLocation = prevLocation._before;
//    }
//    final _LocationOccupants? prevLocationChildren = prevLocation?._children;
//    if (prevLocation != null && prevLocationChildren != null) {
//      location = prevLocation;
//      currentChild = prevLocationChildren._lastChild;
//      return true;
//    }
//    return false;
//  }
//}

T Function(T) _fix<T>(T Function(T) Function(T Function(T)) f) => f(_fix(f));

abstract class _DoublyLinked<T extends _DoublyLinked<T, V>, V extends _LinksBase<T, V>  > {
  _DoublyLinked();

  V get _links;

  U _fold<U>(U initial, U Function(U, T) f) {
    final U newValue = f(initial, this as T);
    final T? next = _links.next;
    return next == null
      ? newValue
      : next._fold(newValue, f);
  }

  bool _any(bool Function(T) f) {
    return f(this as T) || (_links.prev?._any(f) ?? false);
  }

  // Override this to manage the start and the end of the linked list.
  //void _insertAfter(T newEntry) {
  //  assert(_links.linked);
  //  assert(!newEntry._links.linked);
  //  final T? next = _links.next;
  //  newEntry._links.prev = this as T;
  //  newEntry._links.next = next;
  //  _links.next = newEntry;
  //  next?._links.prev = newEntry;
  //}

  //// Override this to manage the start and the end of the linked list.
  //void _unlink() {
  //  assert(_links.linked);
  //  final T? next = _links.next;
  //  final T? prev = _links.prev;
  //  prev?._links.next = next;
  //  next?._links.prev = prev;
  //}
}

abstract class _LinksBase<T extends _DoublyLinked<T, V>, V extends _LinksBase<T, V>> {
  T? get prev;
  T? next;

  bool get linked => prev != null || next != null;
}

class _Links<T extends _DoublyLinked<T, V>, V extends _Links<T, V>> extends _LinksBase<T, V> {
  _Links(this.prev);
  @override
  T? prev;
}

class _LocationLinks extends _LinksBase<OverlayLocation, _LocationLinks> {
  _LocationLinks(this.prev);
  @override
  final OverlayLocation? prev;
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
class OverlayLocation extends _DoublyLinked<OverlayLocation, _LocationLinks> {
  OverlayLocation._above({
    required OverlayLocation referenceLocation,
  }) : //_overlayEntryIdentifier = referenceLocation._overlayEntryIdentifier,
       _overlayRenderObject = referenceLocation._overlayRenderObject,
       _relativeZIndex = referenceLocation._relativeZIndex + 1,
       _links = _LocationLinks(referenceLocation);

  OverlayLocation._root(
    //this._overlayEntryIdentifier,
    this._overlayRenderObject, {
    String? debugLabel,
  }) : _relativeZIndex = 0,
       _links = _LocationLinks(null) {
    assert(() {
      _debugLabel = debugLabel;
      return true;
    }());
  }

  String? _debugLabel;

  /// The distance from the [OverlayEntry] that this [OverlayLocation] uses as
  /// the reference, to the current topmost [OverlayEntry] in the [Overlay].
  ///
  /// Must be greater than or equal to 0. A value of 0 means this
  /// [OverlayLocation] will be painted above the current topmost [OverlayEntry].
  // int get _reversedPaintOrderIndex => _overlayEntryState.widget.reversedIndex;

  //final Key _overlayEntryIdentifier;
  /// The underlying [RenderObject] of the [Overlay].
  final _RenderTheatre _overlayRenderObject;

  /// The z-index relative to the render object of an [OverlayEntry] in the
  /// [Overlay].
  ///
  /// Must be greater than or equal to 0. The larger the number is, the later in
  /// paint order (and the earlier in hit-test order) the [OverlayLocation] is.
  final int _relativeZIndex;

  @override
  final _LocationLinks _links;

  OverlayLocation get _next => _links.next ??= OverlayLocation._above(referenceLocation: this);

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
  static OverlayLocation? above(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_OverlayLocationInheritedWidget>()?.overlayLocation;
  }

  bool _debugDisposed = false;
  final _LocationOccupants _children = _LocationOccupants();

  void _add(_RenderDeferredLayoutBox child) {
    assert(!_debugDisposed);
    _overlayRenderObject.addDeferredChild(child, this);
    print('$this adding $child');
    _children.add(child);
  }

  void _move(_RenderDeferredLayoutBox child, OverlayLocation oldLocation) {
    print('$child moved to $this from $oldLocation');
    assert(!_debugDisposed);
    if (oldLocation._overlayRenderObject != _overlayRenderObject) {
      // Moving to a different Overlay.
      oldLocation._remove(child);
      _add(child);
      return;
    }

    assert(oldLocation._children != null);
    oldLocation._children.remove(child);
    _children.add(child);
  }

  void _remove(_RenderDeferredLayoutBox child) {
    print('REMOVED: $child from $this');
    assert(!_debugDisposed);
    assert(_children != null);
    _children.remove(child);
    _overlayRenderObject.removeDeferredChild(child, this);
  }

  _RenderDeferredLayoutBox? Function() _forwardIterator() {
    _RenderDeferredLayoutBox? box = _children._firstChild;
    if (box == null) {
      return _links.next?._forwardIterator() ?? () => null;
    }
    return () {
      final _RenderDeferredLayoutBox? currentBox = box;
      if (currentBox != null) {
        final StackParentData childParentData = currentBox.parentData! as StackParentData;
        box = childParentData.nextSibling as _RenderDeferredLayoutBox?;
        return currentBox;
      } else {
        return _links.next?._forwardIterator()();
      }
    };
  }

  _RenderDeferredLayoutBox? Function() _backwardIterator() {
    _RenderDeferredLayoutBox? box = _children._lastChild;
    if (box == null) {
      return _links.prev?._backwardIterator() ?? () => null;
    }
    return () {
      final _RenderDeferredLayoutBox? currentBox = box;
      if (currentBox != null) {
        final StackParentData childParentData = currentBox.parentData! as StackParentData;
        box = childParentData.previousSibling as _RenderDeferredLayoutBox?;
        return currentBox;
      } else {
        return _links.prev?._backwardIterator()();
      }
    };
  }

  T _foldl<T>(T initialValue, T Function(_RenderDeferredLayoutBox Function(), T) combine) {
    combine( initialValue, )
  }

  //_OverlayChildIterator? get _forwardIterator {
  //  final _LocationOccupants? children = _children;
  //  return children == null ? _after?._forwardIterator : _OverlayChildIterator(this, children._firstChild);
  //}

  //_OverlayChildIterator? get _backwardIterator {
  //  final _LocationOccupants? children = _children;
  //  return children == null ? _before?._backwardIterator : _OverlayChildIterator(this, children._lastChild);
  //}

  void activate(_RenderDeferredLayoutBox child) {
    assert(!_debugDisposed);
  }

  void deactivate(_RenderDeferredLayoutBox child) {
    assert(!_debugDisposed);
  }

  void _dispose() {
    _links.next?._dispose();
    _debugDisposed = true;
  }

  //static int _compare(OverlayLocation location, OverlayLocation other) {
  //  assert(other._overlayRenderObject == location._overlayRenderObject);
  //  return location._reversedPaintOrderIndex == other._reversedPaintOrderIndex
  //    ? location._relativeZIndex.compareTo(other._relativeZIndex)
  //    : other._reversedPaintOrderIndex.compareTo(location._reversedPaintOrderIndex);
  //}

  @override
  String toString() {
    return '${describeIdentity(this)}[$_children] -> ${describeIdentity(_links.next)}';
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
    widget.entry._overlayLocation = OverlayLocation._root(context.findAncestorRenderObjectOfType<_RenderTheatre>()!);
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
      widget.entry._overlayLocation = OverlayLocation._root(context.findAncestorRenderObjectOfType<_RenderTheatre>()!);
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
      child: _OverlayLocationWidget(
        overlayLocation: widget.entry._overlayLocation!,
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

class _OverlayLocationParentData extends ParentDataWidget<_TheatreParentData> {
  const _OverlayLocationParentData({
    required this.overlayLocation,
    required super.child,
  });

  final OverlayLocation overlayLocation;

  @override
  void applyParentData(RenderObject renderObject) {
    assert(renderObject.parentData is _TheatreParentData);
    final _TheatreParentData parentData = renderObject.parentData! as _TheatreParentData;
    if (parentData.location == overlayLocation) {
      return;
    }
    parentData.location = overlayLocation;
    final AbstractNode? targetParent = renderObject.parent;
    if (targetParent is RenderObject) {
      targetParent.markNeedsPaint();
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => _Theatre;
}

class _TheatreParentData extends StackParentData {
  OverlayLocation? location;
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
      final _OverlayChildIterator? forwardIterator = childParentData.location!._forwardIterator;
      if (forwardIterator != null) {
        do {
          forwardIterator.current.attach(owner);
        } while (forwardIterator.moveNext());
      }
      child = childParentData.nextSibling;
    }
  }

  @override
  void detach() {
    super.detach();
    RenderBox? child = firstChild;
    while (child != null) {
      final _TheatreParentData childParentData = child.parentData! as _TheatreParentData;
      final _OverlayChildIterator? forwardIterator = childParentData.location!._forwardIterator;
      if (forwardIterator != null) {
        do {
          forwardIterator.current.detach();
        } while (forwardIterator.moveNext());
      }
      child = childParentData.nextSibling;
    }
  }

  @override
  void redepthChildren() => visitChildren(redepthChild);

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
    markNeedsPaint();

    // When child has never been laid out before, mark its layout surrogate as
    // needing layout so it's reachable via tree walk.
    child._layoutSurrogate.markNeedsLayout();

    _skipMarkNeedsLayout = false;
  }

  void moveDeferredChild(_RenderDeferredLayoutBox child, OverlayLocation oldLocation, OverlayLocation newLocation) {
    markNeedsPaint();
    markNeedsCompositingBitsUpdate();
    markNeedsSemanticsUpdate();
    throw UnimplementedError();
  }

  void removeDeferredChild(_RenderDeferredLayoutBox child, OverlayLocation location) {
    assert(!_skipMarkNeedsLayout);
    _skipMarkNeedsLayout = true;
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
    final Alignment alignment = theatre._resolvedAlignment;
    while (child != null) {
      final _TheatreParentData childParentData = child.parentData! as _TheatreParentData;
      layoutChild(child, nonPositionedChildConstraints);
      final _OverlayChildIterator? forwardIterator = childParentData.location!._forwardIterator;
      if (forwardIterator != null) {
        do {
          layoutChild(forwardIterator.current, nonPositionedChildConstraints);
        } while (forwardIterator.moveNext());
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
      final _OverlayChildIterator? forwardIterator = childParentData.location!._forwardIterator;
      if (forwardIterator != null) {
        do {
          //print('> painting: ${forwardIterator.current}');
          context.paintChild(forwardIterator.current, childParentData.offset + offset);
        } while (forwardIterator.moveNext());
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
    RenderBox? child = _lastOnstageChild;
    int childCount = _onstageChildCount;
    while (child != null) {
      final _TheatreParentData childParentData = child.parentData! as _TheatreParentData;

      final _OverlayChildIterator? backwardIterator = childParentData.location!._backwardIterator;
      print('backwardIter: ${childParentData.location}, ${childParentData.location}');
      if (backwardIterator != null) {
        do {
          final _TheatreParentData childParentData = backwardIterator.current.parentData! as _TheatreParentData;
          final bool isHit = result.addWithPaintOffset(
            offset: childParentData.offset,
            position: position,
            hitTest: _toBoxHitTest(backwardIterator.current.hitTest),
          );
          print('> ${isHit ? 'HIT' : 'NOT HIT'} @ $position == ${backwardIterator.current} (${childParentData.offset})');
          if (isHit) {
            return true;
          }
        } while (backwardIterator.movePrev());

      }
      final bool isHit = result.addWithPaintOffset(
        offset: childParentData.offset,
        position: position,
        hitTest: _toBoxHitTest(child.hitTest),
      );
      print('${isHit ? 'HIT' : 'NOT HIT'} @ $position == ${child} (${childParentData.offset})');
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
      final _OverlayChildIterator? forwardIterator = childParentData.location!._forwardIterator;
      if (forwardIterator != null) {
        do {
          //print('visitor => ${forwardIterator.current}');
          visitor(forwardIterator.current);
        } while (forwardIterator.moveNext());
      }
      child = childParentData.nextSibling;
    }
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    RenderBox? child = _firstOnstageChild;
    while (child != null) {
      visitor(child);
      final _TheatreParentData childParentData = child.parentData! as _TheatreParentData;
      final _OverlayChildIterator? forwardIterator = childParentData.location!._forwardIterator;
      if (forwardIterator != null) {
        do {
          visitor(forwardIterator.current);
        } while (forwardIterator.moveNext());
      }
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
/// [overlayLocation].
///
/// The [overlayChild] will be rendered on the [Overlay] as if it was inserted
/// using an [OverlayEntry], while it can depend on the same set of
/// [InheritedWidget]s (such as [Theme]) that this widget can depend on.
///
/// This widget must be placed below the [Overlay] [overlayLocation] points to, and
/// [overlayLocation] must not be null when [overlayChild] is not null.
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
class OverlayPortal extends RenderObjectWidget {
  /// Creates a widget that renders the given [overlayChild] in the closest
  /// ancestor [Overlay].
  const OverlayPortal({
    super.key,
    required this.overlayChild,
    required this.child,
  }) : _overlayLocation = null,
       _overlayLocationGetter = OverlayLocation.above;

  /// Creates a widget that renders the given [overlayChild] in the [Overlay]
  /// specified by `overlayLocation`.
  ///
  /// The `overlayLocation` parameter must not be null when [overlayChild] is not
  /// null.
  const OverlayPortal.forOverlay({
    super.key,
    required OverlayLocation? overlayLocation,
    required this.overlayChild,
    required this.child,
  }) : _overlayLocation = overlayLocation,
       _overlayLocationGetter = _neverGetter,
       assert(overlayChild == null || overlayLocation != null);

  static Never _neverGetter(BuildContext context) => throw FlutterError('Unreachable!');

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

  final OverlayLocation? Function(BuildContext) _overlayLocationGetter;
  final OverlayLocation? _overlayLocation;
  OverlayLocation? _overlayLocationFrom(BuildContext context) {
    final OverlayLocation? overlayLocation = _overlayLocation ?? _overlayLocationGetter(context);
    assert(overlayLocation != null || overlayChild == null);
    return overlayLocation;
  }

  @override
  RenderObjectElement createElement() => _OverlayPortalElement(this);

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderLayoutSurrogateProxyBox();
}

@immutable
class _OverlayChild {
  const _OverlayChild(this.element, this.slot, this.widget, this.overlayChildWidget);

  final Element element;
  final OverlayLocation slot;
  final _OverlayLocationWidget widget;
  final Widget overlayChildWidget;
}

class _OverlayPortalElement extends RenderObjectElement {
  _OverlayPortalElement(OverlayPortal super.widget);

  @override
  _RenderLayoutSurrogateProxyBox get renderObject => super.renderObject as _RenderLayoutSurrogateProxyBox;

  _OverlayChild? _overlayChild;
  Element? _child;


  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    final OverlayPortal widget = this.widget as OverlayPortal;
    _child = updateChild(_child, widget.child, null);
    _overlayChild = updateOverlayChild(_overlayChild, widget.overlayChild, widget._overlayLocationFrom(this));
  }

  @override
  void update(OverlayPortal newWidget) {
    super.update(newWidget);

    _child = updateChild(_child, newWidget.child, null);
    _overlayChild = updateOverlayChild(_overlayChild, newWidget.overlayChild, newWidget._overlayLocationFrom(this));
  }

  _OverlayChild? updateOverlayChild(_OverlayChild? overlayChild, Widget? newOverlayChild, OverlayLocation? newSlot) {
    if (overlayChild?.overlayChildWidget == newOverlayChild) {
      if (overlayChild != null && newSlot != overlayChild.slot) {
        assert(newSlot != null);
        updateSlotForChild(overlayChild.element, newSlot);
        return _OverlayChild(overlayChild.element, newSlot!, overlayChild.widget, overlayChild.overlayChildWidget);
      }
      // Skip updating and returns the current _overlayChild.
      return overlayChild;
    }

    if (newSlot != null && newOverlayChild != null) {
      final _OverlayLocationWidget wrappedWidget = _OverlayLocationWidget(
        overlayLocation: newSlot.afterLocation,
        child: _DeferredLayout(layoutSurrogate: renderObject, child: newOverlayChild),
      );
      final Element newElement = updateChild(overlayChild?.element, wrappedWidget, newSlot)!;
      return _OverlayChild(newElement, newSlot, wrappedWidget, newOverlayChild);
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
      overlayChild.slot.activate(box);
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
      overlayChild.slot.deactivate(box);
    }
    super.deactivate();
  }

  @override
  void insertRenderObjectChild(RenderBox child, OverlayLocation? slot) {
    assert(child.parent == null, "$child's parent is not null: ${child.parent}");
    if (slot != null) {
      renderObject._deferredLayoutChild = child as _RenderDeferredLayoutBox;
      slot._add(child);
      //slot._overlayRenderObject.addDeferredChild(child, slot);
    } else {
      renderObject.child = child;
    }
  }

  // The [_DeferredLayout] widget does not have a key so there will be no
  // reparenting between _overlayChild and _child, thus the non-null-typed slots.
  @override
  void moveRenderObjectChild(RenderBox child, OverlayLocation oldSlot, OverlayLocation newSlot) {
    newSlot._move(child as _RenderDeferredLayoutBox, oldSlot);
    //if (oldSlot._overlayRenderObject != newSlot._overlayRenderObject) {
    //  oldSlot._overlayRenderObject.removeDeferredChild(child as _RenderDeferredLayoutBox, oldSlot);
    //  insertRenderObjectChild(child, newSlot);
    //} else {
    //  newSlot._overlayRenderObject.moveDeferredChild(child as _RenderDeferredLayoutBox, oldSlot, newSlot);
    //}
  }

  @override
  void removeRenderObjectChild(RenderBox child, OverlayLocation? slot) {
    if (slot == null) {
      renderObject.child = null;
      return;
    }
    assert(renderObject._deferredLayoutChild == child);
    slot._remove(child as _RenderDeferredLayoutBox);
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
    required this.layoutSurrogate,
    required Widget child,
  }) : super(child: child);

  final _RenderLayoutSurrogateProxyBox layoutSurrogate;

  @override
  _RenderDeferredLayoutBox createRenderObject(BuildContext context) {
    final _RenderDeferredLayoutBox renderObject = _RenderDeferredLayoutBox(layoutSurrogate);
    layoutSurrogate._deferredLayoutChild = renderObject;
    return renderObject;
  }

  @override
  void updateRenderObject(BuildContext context, _RenderDeferredLayoutBox renderObject) {
    assert(renderObject._layoutSurrogate == layoutSurrogate);
    layoutSurrogate._deferredLayoutChild = renderObject;
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
class _RenderDeferredLayoutBox extends RenderProxyBox with _RenderTheatreMixin {
  _RenderDeferredLayoutBox(this._layoutSurrogate);

  StackParentData get stackParentData => parentData! as StackParentData;
  final _RenderLayoutSurrogateProxyBox _layoutSurrogate;
  OverlayLocation? _location;

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
