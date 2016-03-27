// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'basic.dart';
import 'framework.dart';

/// A place in the overlay that can contain a widget.
class OverlayEntry {
  OverlayEntry({
    this.builder,
    bool opaque: false
  }) : _opaque = opaque;

  /// This entry will include the widget built by this builder in the overlay at the entry's position.
  final WidgetBuilder builder;

  /// Whether this entry occludes the entire overlay.
  ///
  /// If an entry claims to be opaque, the overlay will skip building all the
  /// entries below that entry for efficiency.
  bool get opaque => _opaque;
  bool _opaque;
  void set opaque (bool value) {
    if (_opaque == value)
      return;
    assert(_overlay != null);
    _overlay.setState(() {
      _opaque = value;
    });
  }

  OverlayState _overlay;
  final GlobalKey _key = new GlobalKey();

  /// Remove this entry from the overlay.
  void remove() {
    _overlay?._remove(this);
    _overlay = null;
  }

  /// Cause this entry to rebuild during the next pipeline flush.
  ///
  /// You need to call this function if the output of [builder] has changed.
  void markNeedsBuild() {
    _key.currentState?.setState(() { /* the state that changed is in the builder */ });
  }

  @override
  String toString() => '$runtimeType@$hashCode(opaque: $opaque)';
}

class _OverlayEntry extends StatefulWidget {
  _OverlayEntry(OverlayEntry entry) : entry = entry, super(key: entry._key);

  final OverlayEntry entry;

  @override
  _OverlayEntryState createState() => new _OverlayEntryState();
}

class _OverlayEntryState extends State<_OverlayEntry> {
  @override
  Widget build(BuildContext context) => config.entry.builder(context);
}

/// A [Stack] of entries that can be managed independently.
class Overlay extends StatefulWidget {
  Overlay({
    Key key,
    this.initialEntries: const <OverlayEntry>[]
  }) : super(key: key) {
    assert(initialEntries != null);
  }

  /// The entries to include in the overlay initially.
  final List<OverlayEntry> initialEntries;

  /// The state from the closest instance of this class that encloses the given context.
  ///
  /// In checked mode, if the [debugRequiredFor] argument is provided then this
  /// function will assert that an overlay was found and will throw an exception
  /// if not. The exception attempts to explain that the calling [Widget] (the
  /// one given by the [debugRequiredFor] argument) needs an [Overlay] to be
  /// present to function.
  static OverlayState of(BuildContext context, { Widget debugRequiredFor }) {
    OverlayState result = context.ancestorStateOfType(const TypeMatcher<OverlayState>());
    assert(() {
      if (debugRequiredFor != null && result == null) {
        String additional = context.widget != debugRequiredFor
          ? '\nThe context from which that widget was searching for an overlay was:\n  $context'
          : '';
        throw new FlutterError(
          'No Overlay widget found.\n'
          '${debugRequiredFor.runtimeType} widgets require an Overlay widget ancestor for correct operation.\n'
          'The most common way to add an Overlay to an application is to include a MaterialApp or Navigator widget in the runApp() call.\n'
          'The specific widget that failed to find an overlay was:\n'
          '  $debugRequiredFor'
          '$additional'
        );
      }
      return true;
    });
    return result;
  }

  @override
  OverlayState createState() => new OverlayState();
}

/// The current state of an [Overlay].
class OverlayState extends State<Overlay> {
  final List<OverlayEntry> _entries = new List<OverlayEntry>();

  @override
  void initState() {
    super.initState();
    insertAll(config.initialEntries);
  }

  /// Insert the given entry into the overlay.
  ///
  /// If [above] is non-null, the entry is inserted just above [above].
  /// Otherwise, the entry is inserted on top.
  void insert(OverlayEntry entry, { OverlayEntry above }) {
    assert(entry._overlay == null);
    assert(above == null || (above._overlay == this && _entries.contains(above)));
    entry._overlay = this;
    setState(() {
      int index = above == null ? _entries.length : _entries.indexOf(above) + 1;
      _entries.insert(index, entry);
    });
  }

  /// Insert all the entries in the given iterable.
  ///
  /// If [above] is non-null, the entries are inserted just above [above].
  /// Otherwise, the entries are inserted on top.
  void insertAll(Iterable<OverlayEntry> entries, { OverlayEntry above }) {
    assert(above == null || (above._overlay == this && _entries.contains(above)));
    if (entries.isEmpty)
      return;
    for (OverlayEntry entry in entries) {
      assert(entry._overlay == null);
      entry._overlay = this;
    }
    setState(() {
      int index = above == null ? _entries.length : _entries.indexOf(above) + 1;
      _entries.insertAll(index, entries);
    });
  }

  void _remove(OverlayEntry entry) {
    setState(() {
      _entries.remove(entry);
    });
  }

  /// (DEBUG ONLY) Check whether a given entry is visible (i.e., not behind an opaque entry).
  ///
  /// This is an O(N) algorithm, and should not be necessary except for debug
  /// asserts. To avoid people depending on it, this function is implemented
  /// only in checked mode.
  bool debugIsVisible(OverlayEntry entry) {
    bool result = false;
    assert(_entries.contains(entry));
    assert(() {
      for (int i = _entries.length - 1; i > 0; i -= 1) {
        OverlayEntry candidate = _entries[i];
        if (candidate == entry) {
          result = true;
          break;
        }
        if (candidate.opaque)
          break;
      }
      return true;
    });
    return result;
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> backwardsChildren = <Widget>[];

    for (int i = _entries.length - 1; i >= 0; --i) {
      OverlayEntry entry = _entries[i];
      backwardsChildren.add(new _OverlayEntry(entry));
      if (entry.opaque)
        break;
    }

    return new Stack(children: backwardsChildren.reversed.toList(growable: false));
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('entries: $_entries');
  }
}
