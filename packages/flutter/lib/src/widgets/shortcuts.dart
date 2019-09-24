// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'actions.dart';
import 'binding.dart';
import 'focus_manager.dart';
import 'focus_scope.dart';
import 'framework.dart';
import 'inherited_notifier.dart';

/// A set of [KeyboardKey]s that can be used as the keys in a [Map].
///
/// A key set contains the keys that are down simultaneously to represent a
/// shortcut.
///
/// This is a thin wrapper around a [Set], but changes the equality comparison
/// from an identity comparison to a contents comparison so that non-identical
/// sets with the same keys in them will compare as equal.
///
/// See also:
///
///  - [ShortcutManager], which uses [LogicalKeySet] (a [KeySet] subclass) to
///    define its key map.
class KeySet<T extends KeyboardKey> extends Diagnosticable {
  /// A constructor for making a [KeySet] of up to four keys.
  ///
  /// If you need a set of more than four keys, use [KeySet.fromSet].
  ///
  /// The `key1` parameter must not be null. The same [KeyboardKey] may
  /// not be appear more than once in the set.
  KeySet(
    T key1, [
    T key2,
    T key3,
    T key4,
  ])  : assert(key1 != null),
        _keys = HashSet<T>()..add(key1) {
    int count = 1;
    if (key2 != null) {
      _keys.add(key2);
      assert(() {
        count++;
        return true;
      }());
    }
    if (key3 != null) {
      _keys.add(key3);
      assert(() {
        count++;
        return true;
      }());
    }
    if (key4 != null) {
      _keys.add(key4);
      assert(() {
        count++;
        return true;
      }());
    }
    assert(_keys.length == count, 'Two or more provided keys are identical. Each key must appear only once.');
  }

  /// Create  a [KeySet] from a set of [KeyboardKey]s.
  ///
  /// Do not mutate the `keys` set after passing it to this object.
  ///
  /// The `keys` set must not be null, contain nulls, or be empty.
  KeySet.fromSet(Set<T> keys)
      : assert(keys != null),
        assert(keys.isNotEmpty),
        assert(!keys.contains(null)),
        _keys = HashSet<T>.from(keys);

  /// Returns an unmodifiable view of the [KeyboardKey]s in this [KeySet].
  Set<T> get keys => UnmodifiableSetView<T>(_keys);
  // This needs to be a hash set to be sure that the hashCode accessor returns
  // consistent results. LinkedHashSet (the default Set implementation) depends
  // upon insertion order, and HashSet does not.
  final HashSet<T> _keys;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    final KeySet<T> typedOther = other;
    return _keys.length == typedOther._keys.length && _keys.containsAll(typedOther._keys);
  }

  @override
  int get hashCode {
    return hashList(_keys);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Set<T>>('keys', _keys));
  }
}

/// A set of [LogicalKeyboardKey]s that can be used as the keys in a map.
///
/// A key set contains the keys that are down simultaneously to represent a
/// shortcut.
///
/// This is mainly used by [ShortcutManager] to allow the definition of shortcut
/// mappings.
///
/// This is a thin wrapper around a [Set], but changes the equality comparison
/// from an identity comparison to a contents comparison so that non-identical
/// sets with the same keys in them will compare as equal.
class LogicalKeySet extends KeySet<LogicalKeyboardKey> {
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
  ]) : super(key1, key2, key3, key4);

  /// Create  a [LogicalKeySet] from a set of [LogicalKeyboardKey]s.
  ///
  /// Do not mutate the `keys` set after passing it to this object.
  ///
  /// The `keys` must not be null.
  LogicalKeySet.fromSet(Set<LogicalKeyboardKey> keys) : super.fromSet(keys);
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

  /// True if the [ShortcutManager] should not pass on keys that it doesn't
  /// handle to any key-handling widgets that are ancestors to this one.
  ///
  /// Setting [modal] to true is the equivalent of always handling any key given
  /// to it, even if that key doesn't appear in the [shortcuts] map. Keys that
  /// don't appear in the map will be dropped.
  final bool modal;

  /// Returns the shortcut map.
  ///
  /// When the map is changed, listeners to this manager will be notified.
  ///
  /// The returned [LogicalKeyMap] should not be modified.
  Map<LogicalKeySet, Intent> get shortcuts => _shortcuts;
  Map<LogicalKeySet, Intent> _shortcuts;
  set shortcuts(Map<LogicalKeySet, Intent> value) {
    if (_shortcuts == value) {
      return;
    }
    if (_shortcuts != value) {
      _shortcuts = value;
      notifyListeners();
    }
  }

  /// Handles a key pressed `event` in the given `context`.
  ///
  /// The optional `keysPressed` argument provides an override to keys that the
  /// [RawKeyboard] reports. If not specified, uses [RawKeyboard.keysPressed]
  /// instead.
  @protected
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
    Intent matchedIntent = _shortcuts[keySet];
    if (matchedIntent == null) {
      // If there's not a more specific match, We also look for any keys that
      // have synonyms in the map.  This is for things like left and right shift
      // keys mapping to just the "shift" pseudo-key.
      final Set<LogicalKeyboardKey> pseudoKeys = <LogicalKeyboardKey>{};
      for (LogicalKeyboardKey setKey in keySet.keys) {
        final Set<LogicalKeyboardKey> synonyms = setKey.synonyms;
        if (synonyms.isNotEmpty) {
          // There currently aren't any synonyms that match more than one key.
          pseudoKeys.add(synonyms.first);
        } else {
          pseudoKeys.add(setKey);
        }
      }
      matchedIntent = _shortcuts[LogicalKeySet.fromSet(pseudoKeys)];
    }
    if (matchedIntent != null) {
      final BuildContext primaryContext = WidgetsBinding.instance.focusManager.primaryFocus?.context;
      if (primaryContext == null) {
        return false;
      }
      return Actions.invoke(primaryContext, matchedIntent, nullOk: true);
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

/// A widget that establishes an [ShortcutManager] to be used by its descendants
/// when invoking an [Action] via a keyboard key combination that maps to an
/// [Intent].
///
/// See also:
///
///   * [Intent], a class for containing a description of a user
///     action to be invoked.
///   * [Action], a class for defining an invocation of a user action.
class Shortcuts extends StatefulWidget {
  /// Creates a ActionManager object.
  ///
  /// The [child] argument must not be null.
  const Shortcuts({
    Key key,
    this.manager,
    this.shortcuts,
    this.child,
  }) : super(key: key);

  /// The [ShortcutManager] that will manage the mapping between key
  /// combinations and [Action]s.
  ///
  /// If not specified, uses a default-constructed [ShortcutManager].
  ///
  /// This manager will be given new [shortcuts] to manage whenever the
  /// [shortcuts] change materially.
  final ShortcutManager manager;

  /// The map of shortcuts that the [manager] will be given to manage.
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
            '$Shortcuts widget.\n'
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
      canRequestFocus: false,
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
