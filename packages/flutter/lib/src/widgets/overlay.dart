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
/// [OverlayEntry] is a [ChangeNotifier] that notifies when the widget built by
/// [builder] is mounted or unmounted, whose exact state can be queried by
/// [mounted].
///
/// See also:
///
///  * [Overlay]
///  * [OverlayState]
///  * [WidgetsApp]
///  * [MaterialApp]
class OverlayEntry extends ChangeNotifier {
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
    if (_opaque == value)
      return;
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
    assert(_maintainState != null);
    if (_maintainState == value)
      return;
    _maintainState = value;
    assert(_overlay != null);
    _overlay!._didChangeEntryOpacity();
  }

  /// Whether the [OverlayEntry] is currently mounted in the widget tree.
  ///
  /// The [OverlayEntry] notifies its listeners when this value changes.
  bool get mounted => _mounted;
  bool _mounted = false;
  void _updateMounted(bool value) {
    if (value == _mounted) {
      return;
    }
    _mounted = value;
    notifyListeners();
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
    final OverlayState overlay = _overlay!;
    _overlay = null;
    if (!overlay.mounted)
      return;

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
    _key.currentState?._markNeedsBuild();
  }

  @override
  String toString() => '${describeIdentity(this)}(opaque: $opaque; maintainState: $maintainState)';
}

class _OverlayEntryWidget extends StatefulWidget {
  const _OverlayEntryWidget({
    required Key key,
    required this.entry,
    this.tickerEnabled = true,
  }) : assert(key != null),
       assert(entry != null),
       assert(tickerEnabled != null),
       super(key: key);

  final OverlayEntry entry;
  final bool tickerEnabled;

  @override
  _OverlayEntryWidgetState createState() => _OverlayEntryWidgetState();
}

class _OverlayEntryWidgetState extends State<_OverlayEntryWidget> {
  @override
  void initState() {
    super.initState();
    widget.entry._updateMounted(true);
  }

  @override
  void dispose() {
    widget.entry._updateMounted(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TickerMode(
      enabled: widget.tickerEnabled,
      child: widget.entry.builder(context),
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
    Key? key,
    this.initialEntries = const <OverlayEntry>[],
    this.clipBehavior = Clip.hardEdge,
  }) : assert(initialEntries != null),
       assert(clipBehavior != null),
       super(key: key);

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
    if (below != null)
      return _entries.indexOf(below);
    if (above != null)
      return _entries.indexOf(above) + 1;
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
    if (entries.isEmpty)
      return;
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
    if (newEntriesList.isEmpty)
      return;
    if (listEquals(_entries, newEntriesList))
      return;
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
        if (candidate.opaque)
          break;
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
    for (int i = _entries.length - 1; i >= 0; i -= 1) {
      final OverlayEntry entry = _entries[i];
      if (onstage) {
        onstageCount += 1;
        children.add(_OverlayEntryWidget(
          key: entry._key,
          entry: entry,
        ));
        if (entry.opaque)
          onstage = false;
      } else if (entry.maintainState) {
        children.add(_OverlayEntryWidget(
          key: entry._key,
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
    Key? key,
    this.skipCount = 0,
    this.clipBehavior = Clip.hardEdge,
    List<Widget> children = const <Widget>[],
  }) : assert(skipCount != null),
       assert(skipCount >= 0),
       assert(children != null),
       assert(children.length >= skipCount),
       assert(clipBehavior != null),
       super(key: key, children: children);

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
  _TheatreElement(_Theatre widget) : super(widget);

  @override
  _RenderTheatre get renderObject => super.renderObject as _RenderTheatre;

  @override
  void debugVisitOnstageChildren(ElementVisitor visitor) {
    final _Theatre theatre = widget as _Theatre;
    assert(children.length >= theatre.skipCount);
    children.skip(theatre.skipCount).forEach(visitor);
  }
}

class _RenderTheatre extends RenderBox with ContainerRenderObjectMixin<RenderBox, StackParentData> {
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

  bool _hasVisualOverflow = false;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! StackParentData)
      child.parentData = StackParentData();
  }

  Alignment? _resolvedAlignment;

  void _resolve() {
    if (_resolvedAlignment != null)
      return;
    _resolvedAlignment = AlignmentDirectional.topStart.resolve(textDirection);
  }

  void _markNeedResolution() {
    _resolvedAlignment = null;
    markNeedsLayout();
  }

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection == value)
      return;
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

  RenderBox? get _lastOnstageChild => skipCount == super.childCount ? null : lastChild;

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
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    assert(constraints.biggest.isFinite);
    return constraints.biggest;
  }

  @override
  void performLayout() {
    _hasVisualOverflow = false;

    if (_onstageChildCount == 0) {
      return;
    }

    _resolve();
    assert(_resolvedAlignment != null);

    // Same BoxConstraints as used by RenderStack for StackFit.expand.
    final BoxConstraints nonPositionedConstraints = BoxConstraints.tight(constraints.biggest);

    RenderBox? child = _firstOnstageChild;
    while (child != null) {
      final StackParentData childParentData = child.parentData! as StackParentData;

      if (!childParentData.isPositioned) {
        child.layout(nonPositionedConstraints, parentUsesSize: true);
        childParentData.offset = _resolvedAlignment!.alongOffset(size - child.size as Offset);
      } else {
        _hasVisualOverflow = RenderStack.layoutPositionedChild(child, childParentData, size, _resolvedAlignment!) || _hasVisualOverflow;
      }

      assert(child.parentData == childParentData);
      child = childParentData.nextSibling;
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, { required Offset position }) {
    RenderBox? child = _lastOnstageChild;
    for (int i = 0; i < _onstageChildCount; i++) {
      assert(child != null);
      final StackParentData childParentData = child!.parentData! as StackParentData;
      final bool isHit = result.addWithPaintOffset(
        offset: childParentData.offset,
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) {
          assert(transformed == position - childParentData.offset);
          return child!.hitTest(result, position: transformed);
        },
      );
      if (isHit)
        return true;
      child = childParentData.previousSibling;
    }
    return false;
  }

  @protected
  void paintStack(PaintingContext context, Offset offset) {
    RenderBox? child = _firstOnstageChild;
    while (child != null) {
      final StackParentData childParentData = child.parentData! as StackParentData;
      context.paintChild(child, childParentData.offset + offset);
      child = childParentData.nextSibling;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_hasVisualOverflow && clipBehavior != Clip.none) {
      _clipRectLayer.layer = context.pushClipRect(
        needsCompositing,
        offset,
        Offset.zero & size,
        paintStack,
        clipBehavior: clipBehavior,
        oldLayer: _clipRectLayer.layer,
      );
    } else {
      _clipRectLayer.layer = null;
      paintStack(context, offset);
    }
  }

  final LayerHandle<ClipRectLayer> _clipRectLayer = LayerHandle<ClipRectLayer>();

  @override
  void dispose() {
    _clipRectLayer.layer = null;
    super.dispose();
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    RenderBox? child = _firstOnstageChild;
    while (child != null) {
      visitor(child);
      final StackParentData childParentData = child.parentData! as StackParentData;
      child = childParentData.nextSibling;
    }
  }

  @override
  Rect? describeApproximatePaintClip(RenderObject child) => _hasVisualOverflow ? Offset.zero & size : null;

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
