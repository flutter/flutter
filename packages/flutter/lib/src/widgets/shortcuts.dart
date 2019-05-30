// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'actions.dart';
import 'binding.dart';
import 'focus_manager.dart';
import 'focus_scope.dart';
import 'framework.dart';
import 'inherited_notifier.dart';

/// A set of [LogicalKeyboardKey]s that can be used as the keys in a map.
///
/// A key set represents the keys that are down simultaneously that represent a
/// shortcut.
///
/// This is mainly used by [ShortcutManager] to allow definition of shortcut
/// mappings.
class LogicalKeySet extends Diagnosticable {
  /// A constructor for making a [LogicalKeySet] of up to four keys.
  ///
  /// If you need a set of more than four keys, use [LogicalKeySet.fromSet].
  ///
  /// The `key1` parameter must not be null. The same [LogicalKeyboardKey] may
  /// not be appear more than once in the set.
  LogicalKeySet(
    LogicalKeyboardKey key1, [
    LogicalKeyboardKey key2,
    LogicalKeyboardKey key3,
    LogicalKeyboardKey key4,
  ])  : assert(key1 != null),
        _keys = <LogicalKeyboardKey>{ key1 } {
    int count = 1;
    if (key2 != null) {
      _keys.add(key2);
      assert((){
        count++;
        return true;
      }());
    }
    if (key3 != null) {
      _keys.add(key3);
      assert((){
        count++;
        return true;
      }());
    }
    if (key4 != null) {
      _keys.add(key4);
      assert((){
        count++;
        return true;
      }());
    }
    assert(_keys.length == count,
      'Two or more provided keys are identical. Each key can appear only once.');
  }

  /// Create  a [LogicalKeySet] from a set of [LogicalKeyboardKey]s.
  ///
  /// Do not mutate the `keys` set after passing it to this object.
  ///
  /// The `keys` must not be null or empty.
  LogicalKeySet.fromSet(Set<LogicalKeyboardKey> keys)
      : assert(keys != null),
        assert(keys.isNotEmpty),
        _keys = keys;

  final Set<LogicalKeyboardKey> _keys;

  /// Convert the [LogicalKeySet] to a set of [LogicalKeyboardKey]s and return a
  /// copy.
  Set<LogicalKeyboardKey> toSet() => _keys.toSet();

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    final LogicalKeySet typedOther = other;
    if (_keys.length != typedOther._keys.length) {
      return false;
    }
    return _keys.difference(typedOther._keys).isEmpty;
  }

  @override
  int get hashCode {
    return hashList(_keys);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Set<LogicalKeyboardKey>>('keys', _keys));
  }
}

/// A manager of keyboard shortcut bindings.
///
/// A [ShortcutManager] is obtained by calling [Shortcuts.of] on the context of
/// the widget that you want to find a manager for.
class ShortcutManager extends ChangeNotifier with DiagnosticableMixin {
  /// Constructs a [ShortcutManager].
  ///
  /// The [shortcuts] argument must not  be null.
  ShortcutManager({
    Map<LogicalKeySet, Intent> shortcuts = const <LogicalKeySet, Intent>{},
    this.modal = false,
  })  : assert(shortcuts != null),
        _shortcuts = shortcuts;

  /// True if this shortcut map should not pass on keys that it doesn't handle
  /// to any key-handling widgets that are ancestors to this one.
  ///
  /// Setting [modal] to true is the equivalent of always handling any key given
  /// to it, even if that key doesn't appear in the [shortcuts] map.
  final bool modal;

  /// Returns a copy of the shortcut map.
  ///
  /// Returns a copy so that modifying the copy will not modified the stored
  /// map.
  ///
  /// When the map is changed, listeners to this manager will be notified.
  Map<LogicalKeySet, Intent> get shortcuts => _shortcuts;
  final Map<LogicalKeySet, Intent> _shortcuts;
  set shortcuts(Map<LogicalKeySet, Intent> value) {
    if (value != _shortcuts) {
      _shortcuts.clear();
      _shortcuts.addAll(value);
      notifyListeners();
    }
  }

  /// Adds a shortcut mapping to the map.
  ///
  /// It the mapping is changed, then the listeners to this manager will be
  /// notified.
  void addShortcut(LogicalKeySet keySet, Intent action) {
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
      final BuildContext primaryContext = WidgetsBinding.instance.focusManager.primaryFocus?.context;
      if (primaryContext == null) {
        return false;
      }
      return Actions.invoke(primaryContext, _shortcuts[keySet], nullOk: true);
    }
    return false;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Map<LogicalKeySet, Intent>>('shortcuts', _shortcuts));
    properties.add(FlagProperty('modal', value: modal, ifTrue: 'modal', defaultValue: false));
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
  const Shortcuts({
    Key key,
    this.manager,
    this.shortcuts,
    this.child,
  })  : super(key: key);

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
  final Map<LogicalKeySet, Intent> shortcuts;

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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ShortcutManager>('manager', manager));
    properties.add(DiagnosticsProperty<Map<LogicalKeySet, Intent>>('shortcuts', shortcuts));
  }
}

class _ShortcutsState extends State<Shortcuts> {
  ShortcutManager _internalManager;
  ShortcutManager get manager => widget.manager ?? _internalManager;

  @override
  void dispose() {
    _internalManager?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.manager == null) {
      _internalManager = ShortcutManager();
    }
    manager.shortcuts = widget.shortcuts;
  }

  @override
  void didUpdateWidget(Shortcuts oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.manager != oldWidget.manager || widget.shortcuts != oldWidget.shortcuts) {
      if (widget.manager != null) {
        _internalManager?.dispose();
        _internalManager = null;
      } else {
        _internalManager ??= ShortcutManager();
      }
      manager.shortcuts = widget.shortcuts;
    }
  }

  bool _handleOnKey(FocusNode node, RawKeyEvent event) {
    if (node.context == null) {
      return false;
    }
    return manager.handleKeypress(node.context, event) || manager.modal;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      skipTraversal: true,
      onKey: _handleOnKey,
      child: _ShortcutsMarker(
        manager: manager,
        child: widget.child,
      ),
    );
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
