// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'basic.dart';
import 'framework.dart';

class OverlayEntry {
  OverlayEntry({
    this.builder,
    bool opaque: false
  }) : _opaque = opaque;

  final WidgetBuilder builder;

  bool get opaque => _opaque;
  bool _opaque;
  void set opaque (bool value) {
    if (_opaque == value)
      return;
    _opaque = value;
    markNeedsBuild();
  }

  OverlayState _state;

  /// Remove the entry from the overlay.
  void remove() {
    _state?._remove(this);
    _state = null;
  }

  void markNeedsBuild() {
    // TODO(ianh): find a way to make this not rebuild the entire overlay
    _state?.setState(() {});
  }
}

class Overlay extends StatefulComponent {
  Overlay({
    Key key,
    this.initialEntries
  }) : super(key: key);

  final List<OverlayEntry> initialEntries;

  static OverlayState of(BuildContext context) => context.ancestorStateOfType(OverlayState);

  OverlayState createState() => new OverlayState();
}

class OverlayState extends State<Overlay> {
  final List<OverlayEntry> _entries = new List<OverlayEntry>();

  void initState() {
    super.initState();
    insertAll(config.initialEntries);
  }

  void insert(OverlayEntry entry, { OverlayEntry above }) {
    assert(entry._state == null);
    assert(above == null || (above._state == this && _entries.contains(above)));
    entry._state = this;
    setState(() {
      int index = above == null ? _entries.length : _entries.indexOf(above) + 1;
      _entries.insert(index, entry);
    });
  }

  void insertAll(Iterable<OverlayEntry> entries, { OverlayEntry above }) {
    assert(above == null || (above._state == this && _entries.contains(above)));
    for (OverlayEntry entry in entries) {
      assert(entry._state == null);
      entry._state = this;
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

  bool debugIsVisible(OverlayEntry entry) {
    bool result = false;
    assert(_entries.contains(entry));
    assert(() {
      // This is an O(N) algorithm, and should not be necessary except for debug asserts.
      // To avoid people depending on it, we only implement it in checked mode.
      for (int i = _entries.length - 1; i > 0; i -= 1) {
        OverlayEntry candidate = _entries[i];
        if (candidate == entry) {
          result = true;
          break;
        }
        if (entry.opaque)
          break;
      }
      return true;
    });
    return result;
  }

  Widget build(BuildContext context) {
    List<Widget> backwardsChildren = <Widget>[];

    for (int i = _entries.length - 1; i >= 0; --i) {
      OverlayEntry entry = _entries[i];
      backwardsChildren.add(new KeyedSubtree(
        key: new ObjectKey(entry),
        child: entry.builder(context)
      ));
      if (entry.opaque)
        break;
    }

    return new Stack(backwardsChildren.reversed.toList(growable: false));
  }
}
