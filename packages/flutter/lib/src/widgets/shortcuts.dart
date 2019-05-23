// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'actions.dart';
import 'framework.dart';

/// A set of [LogicalKeyboardKey]s that can be used as the keys in a map.
///
/// This is mainly used by [ShortcutManager] to allow definition of shortcut
/// mappings.
class LogicalKeySet {
  /// A constructor for making a [LogicalKeySet] of up to four keys.
  ///
  /// If you need a set of more than four keys, use [LogicalKeySet.fromSet].
  ///
  /// The `key1` parameter must not be null.
  LogicalKeySet(
    LogicalKeyboardKey key1, [
    LogicalKeyboardKey key2,
    LogicalKeyboardKey key3,
    LogicalKeyboardKey key4,
  ])  : assert(key1 != null),
        _logicalSet = <LogicalKeyboardKey>{} {
    _logicalSet.add(key1);
    if (key2 != null) {
      _logicalSet.add(key2);
    }
    if (key3 != null) {
      _logicalSet.add(key3);
    }
    if (key4 != null) {
      _logicalSet.add(key4);
    }
  }

  /// Create  a [LogicalKeySet] from a set of [LogicalKeyboardKey]s.
  ///
  /// The `keys` must not be null or empty.
  LogicalKeySet.fromSet(Set<LogicalKeyboardKey> keys)
      : assert(keys != null),
        assert(keys.isNotEmpty),
        _logicalSet = keys;

  final Set<LogicalKeyboardKey> _logicalSet;

  /// Convert the [LogicalKeySet] to a set of [LogicalKeyboardKey]s and return a
  /// copy.
  Set<LogicalKeyboardKey> toSet() => _logicalSet.toSet();

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    final LogicalKeySet typedOther = other;
    if (_logicalSet.length != typedOther._logicalSet.length) {
      return false;
    }
    return _logicalSet.difference(typedOther._logicalSet).isEmpty;
  }

  @override
  int get hashCode {
    return hashList(_logicalSet);
  }
}

/// A manager of keyboard shortcut bindings.
///
/// A [ShortcutManager] is obtained by calling [Shortcuts.of] on
/// the context of the widget that you want to find a manager for.
class ShortcutManager extends ChangeNotifier {
  /// Constructs a [ShortcutManager].
  ///
  /// The [shortcuts] argument must not  be null.
  ShortcutManager({
    Map<LogicalKeySet, ActionTag> shortcuts = const <LogicalKeySet, ActionTag>{},
    this.modal = false,
  })  : assert(shortcuts != null),
        _shortcuts = shortcuts;

  /// True if this shortcut map should not pass on keys that it doesn't handle
  /// to any [ShortcutManager]s that are ancestors to this one.
  bool modal;

  /// Returns a copy of the shortcut map.
  ///
  /// Returns a copy so that modifying the copy will not modified the stored map.
  ///
  /// When the map is changed, listeners to this manager will be notified.
  Map<LogicalKeySet, ActionTag> get shortcuts {
    return _shortcuts;
  }

  set shortcuts(Map<LogicalKeySet, ActionTag> value) {
    if (value != _shortcuts) {
      _shortcuts = value;
      notifyListeners();
    }
  }

  Map<LogicalKeySet, ActionTag> _shortcuts;

  /// Adds a shortcut mapping to the map.
  ///
  /// It the mapping is changed, then the listeners to this manager will be
  /// notified.
  void addShortcut(LogicalKeySet keySet, ActionTag action) {
    if (!_shortcuts.containsKey(keySet) || _shortcuts[keySet] != action) {
      _shortcuts[keySet] = action;
      notifyListeners();
    }
  }

  /// Removes a shortcut mapping to the map.
  ///
  /// It the mapping is changed, then the listeners to this manager will be
  /// notified.
  void removeShortcut(LogicalKeySet keySet) {
    if (!_shortcuts.containsKey(keySet)) {
      return;
    }
    _shortcuts.remove(keySet);
    notifyListeners();
  }

  /// Handles a key pressed `event` in the given `context`.
  ///
  /// The optional `keysPressed` argument provides an override to keys that the
  /// [RawKeyboard] reports. If not specified, uses [RawKeyboard.keysPressed]
  /// instead.
  bool handleKeypress(
    BuildContext context,
    RawKeyEvent event, {
    LogicalKeySet keysPressed,
  }) {
    if (event is! RawKeyDownEvent) {
      return false;
    }
    assert(context != null);
    final LogicalKeySet keySet = keysPressed ?? LogicalKeySet.fromSet(RawKeyboard.instance.keysPressed);
    if (_shortcuts.containsKey(keySet)) {
      final ActionDispatcher dispatcher = Actions.of(context, nullOk: true);
      return dispatcher.invokeFocusedAction(_shortcuts[keySet]) != null;
    }
    return false;
  }
}

/// A widget that establishes an [ActionDispatcher] to be used by its descendants
/// when invoking an [Action].
///
/// See also:
///
///   * [Action], a class for containing and defining an invocation of a user
///     action.
///   * [UndoableAction], a class for containing and defining an invocation of
///     an undoable user action.
class Shortcuts extends StatefulWidget {
  /// Creates a ActionManager object.
  ///
  /// The [child] argument must not be null.
  Shortcuts({
    Key key,
    ShortcutManager manager,
    this.shortcuts,
    this.child,
  })  : manager = manager ?? ShortcutManager(),
        super(key: key);

  /// The shortcut manager that will manage the mapping between key combinations
  /// and [Action]s.
  ///
  /// If not specified, uses an empty [ShortcutManager].
  ///
  /// See also:
  ///
  ///  * [FocusTraversalPolicy] for the API used to impose traversal order
  ///    policy.
  ///  * [WidgetOrderFocusTraversalPolicy] for a traversal policy that traverses
  ///    nodes in the order they are added to the widget tree.
  ///  * [ReadingOrderTraversalPolicy] for a traversal policy that traverses
  ///    nodes in the reading order defined in the widget tree, and then top to
  ///    bottom.
  final ShortcutManager manager;

  /// The map of shortcuts that the manager will be given to manage.
  final Map<LogicalKeySet, ActionTag> shortcuts;

  /// The child widget for this [Shortcuts] widget.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  /// Returns the [ActionDispatcher] that most tightly encloses the given
  /// [BuildContext].
  ///
  /// The [context] argument must not be null.
  static ShortcutManager of(BuildContext context, {bool nullOk = false}) {
    assert(context != null);
    final _ShortcutsMarker inherited = context.inheritFromWidgetOfExactType(_ShortcutsMarker);
    assert(() {
      if (nullOk) {
        return true;
      }
      if (inherited == null) {
        throw FlutterError('Unable to find a $Shortcuts widget in the context.\n'
            '$Shortcuts.of() was called with a context that does not contain a '
            '$Shortcuts.\n'
            'No $Shortcuts ancestor could be found starting from the context that was '
            'passed to $Shortcuts.of().\n'
            'The context used was:\n'
            '  $context');
      }
      return true;
    }());
    return inherited?.notifier;
  }

  @override
  _ShortcutsState createState() => _ShortcutsState();
}

class _ShortcutsState extends State<Shortcuts> {
  @override
  void initState() {
    super.initState();
    widget.manager.shortcuts = widget.shortcuts;
  }

  @override
  Widget build(BuildContext context) {
    return _ShortcutsMarker(manager: widget.manager, child: widget.child);
  }

  @override
  void didUpdateWidget(Shortcuts oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.manager != oldWidget.manager || widget.shortcuts != oldWidget.shortcuts) {
      widget.manager.shortcuts = widget.shortcuts;
    }
  }
}

class _ShortcutsMarker extends InheritedNotifier<ShortcutManager> {
  const _ShortcutsMarker({
    @required ShortcutManager manager,
    @required Widget child,
  })  : assert(manager != null),
        assert(child != null),
        super(notifier: manager, child: child);
}
