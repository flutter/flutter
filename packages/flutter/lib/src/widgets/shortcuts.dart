// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'actions.dart';
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
///  * [ShortcutManager], which uses [LogicalKeySet] (a [KeySet] subclass) to
///    define its key map.
@immutable
class KeySet<T extends KeyboardKey> {
  /// A constructor for making a [KeySet] of up to four keys.
  ///
  /// If you need a set of more than four keys, use [KeySet.fromSet].
  ///
  /// The `key1` parameter must not be null. The same [KeyboardKey] may
  /// not be appear more than once in the set.
  KeySet(
    T key1, [
    T? key2,
    T? key3,
    T? key4,
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

  /// Returns a copy of the [KeyboardKey]s in this [KeySet].
  Set<T> get keys => _keys.toSet();
  final HashSet<T> _keys;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is KeySet<T>
        && setEquals<T>(other._keys, _keys);
  }


  // Cached hash code value. Improves [hashCode] performance by 27%-900%,
  // depending on key set size and read/write ratio.
  @override
  late final int hashCode = _computeHashCode(_keys);

  // Arrays used to temporarily store hash codes for sorting.
  static final List<int> _tempHashStore3 = <int>[0, 0, 0]; // used to sort exactly 3 keys
  static final List<int> _tempHashStore4 = <int>[0, 0, 0, 0]; // used to sort exactly 4 keys
  static int _computeHashCode<T>(Set<T> keys) {
    // Compute order-independent hash and cache it.
    final int length = keys.length;
    final Iterator<T> iterator = keys.iterator;

    // There's always at least one key. Just extract it.
    iterator.moveNext();
    final int h1 = iterator.current.hashCode;

    if (length == 1) {
      // Don't do anything fancy if there's exactly one key.
      return h1;
    }

    iterator.moveNext();
    final int h2 = iterator.current.hashCode;
    if (length == 2) {
      // No need to sort if there's two keys, just compare them.
      return h1 < h2
        ? hashValues(h1, h2)
        : hashValues(h2, h1);
    }

    // Sort key hash codes and feed to hashList to ensure the aggregate
    // hash code does not depend on the key order.
    final List<int> sortedHashes = length == 3
      ? _tempHashStore3
      : _tempHashStore4;
    sortedHashes[0] = h1;
    sortedHashes[1] = h2;
    iterator.moveNext();
    sortedHashes[2] = iterator.current.hashCode;
    if (length == 4) {
      iterator.moveNext();
      sortedHashes[3] = iterator.current.hashCode;
    }
    sortedHashes.sort();
    return hashList(sortedHashes);
  }
}

/// A set of [LogicalKeyboardKey]s that can be used as the keys in a map.
///
/// A key set contains the keys that are down simultaneously to represent a
/// shortcut.
///
/// This is mainly used by [ShortcutManager] and [Shortcuts] widget to allow the
/// definition of shortcut mappings.
///
/// This is a thin wrapper around a [Set], but changes the equality comparison
/// from an identity comparison to a contents comparison so that non-identical
/// sets with the same keys in them will compare as equal.
class LogicalKeySet extends KeySet<LogicalKeyboardKey> with Diagnosticable {
  /// A constructor for making a [LogicalKeySet] of up to four keys.
  ///
  /// If you need a set of more than four keys, use [LogicalKeySet.fromSet].
  ///
  /// The `key1` parameter must not be null. The same [LogicalKeyboardKey] may
  /// not be appear more than once in the set.
  LogicalKeySet(
    LogicalKeyboardKey key1, [
    LogicalKeyboardKey? key2,
    LogicalKeyboardKey? key3,
    LogicalKeyboardKey? key4,
  ]) : super(key1, key2, key3, key4);

  /// Create  a [LogicalKeySet] from a set of [LogicalKeyboardKey]s.
  ///
  /// Do not mutate the `keys` set after passing it to this object.
  ///
  /// The `keys` must not be null.
  LogicalKeySet.fromSet(Set<LogicalKeyboardKey> keys) : super.fromSet(keys);

  static final Set<LogicalKeyboardKey> _modifiers = <LogicalKeyboardKey>{
    LogicalKeyboardKey.alt,
    LogicalKeyboardKey.control,
    LogicalKeyboardKey.meta,
    LogicalKeyboardKey.shift,
  };

  /// Returns a description of the key set that is short and readable.
  ///
  /// Intended to be used in debug mode for logging purposes.
  String debugDescribeKeys() {
    final List<LogicalKeyboardKey> sortedKeys = keys.toList()..sort(
            (LogicalKeyboardKey a, LogicalKeyboardKey b) {
          // Put the modifiers first. If it has a synonym, then it's something
          // like shiftLeft, altRight, etc.
          final bool aIsModifier = a.synonyms.isNotEmpty || _modifiers.contains(a);
          final bool bIsModifier = b.synonyms.isNotEmpty || _modifiers.contains(b);
          if (aIsModifier && !bIsModifier) {
            return -1;
          } else if (bIsModifier && !aIsModifier) {
            return 1;
          }
          return a.debugName!.compareTo(b.debugName!);
        },
    );
    return sortedKeys.map<String>((LogicalKeyboardKey key) => key.debugName.toString()).join(' + ');
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Set<LogicalKeyboardKey>>('keys', _keys, description: debugDescribeKeys()));
  }
}

/// A [DiagnosticsProperty] which handles formatting a `Map<LogicalKeySet,
/// Intent>` (the same type as the [Shortcuts.shortcuts] property) so that its
/// diagnostic output is human-readable.
class ShortcutMapProperty extends DiagnosticsProperty<Map<LogicalKeySet, Intent>> {
  /// Create a diagnostics property for `Map<LogicalKeySet, Intent>` objects,
  /// which are the same type as the [Shortcuts.shortcuts] property.
  ///
  /// The [showName] and [level] arguments must not be null.
  ShortcutMapProperty(
    String name,
    Map<LogicalKeySet, Intent> value, {
    bool showName = true,
    Object defaultValue = kNoDefaultValue,
    DiagnosticLevel level = DiagnosticLevel.info,
    String? description,
  }) : assert(showName != null),
       assert(level != null),
       super(
         name,
         value,
         showName: showName,
         defaultValue: defaultValue,
         level: level,
         description: description,
       );

  @override
  Map<LogicalKeySet, Intent> get value => super.value!;

  @override
  String valueToString({ TextTreeConfiguration? parentConfiguration }) {
    return '{${value.keys.map<String>((LogicalKeySet keySet) => '{${keySet.debugDescribeKeys()}}: ${value[keySet]}').join(', ')}}';
  }
}

/// A manager of keyboard shortcut bindings.
///
/// A [ShortcutManager] is obtained by calling [Shortcuts.of] on the context of
/// the widget that you want to find a manager for.
class ShortcutManager extends ChangeNotifier with Diagnosticable {
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
  /// Setting [modal] to true will prevent any key event given to this manager
  /// from being given to any ancestor managers, even if that key doesn't appear
  /// in the [shortcuts] map.
  ///
  /// The net effect of setting `modal` to true is to return
  /// [KeyEventResult.skipRemainingHandlers] from [handleKeypress] if it does
  /// not exist in the shortcut map, instead of returning
  /// [KeyEventResult.ignored].
  final bool modal;

  /// Returns the shortcut map.
  ///
  /// When the map is changed, listeners to this manager will be notified.
  ///
  /// The returned map should not be modified.
  Map<LogicalKeySet, Intent> get shortcuts => _shortcuts;
  Map<LogicalKeySet, Intent> _shortcuts;
  set shortcuts(Map<LogicalKeySet, Intent> value) {
    assert(value != null);
    if (!mapEquals<LogicalKeySet, Intent>(_shortcuts, value)) {
      _shortcuts = value;
      notifyListeners();
    }
  }

  /// Returns the [Intent], if any, that matches the current set of pressed
  /// keys.
  ///
  /// Returns null if no intent matches the current set of pressed keys.
  ///
  /// Defaults to a set derived from [RawKeyboard.keysPressed] if `keysPressed`
  /// is not supplied.
  Intent? _find({ LogicalKeySet? keysPressed }) {
    if (keysPressed == null && RawKeyboard.instance.keysPressed.isEmpty) {
      return null;
    }
    keysPressed ??= LogicalKeySet.fromSet(RawKeyboard.instance.keysPressed);
    Intent? matchedIntent = _shortcuts[keysPressed];
    if (matchedIntent == null) {
      // If there's not a more specific match, We also look for any keys that
      // have synonyms in the map.  This is for things like left and right shift
      // keys mapping to just the "shift" pseudo-key.
      final Set<LogicalKeyboardKey> pseudoKeys = <LogicalKeyboardKey>{};
      for (final KeyboardKey setKey in keysPressed.keys) {
        if (setKey is LogicalKeyboardKey) {
          final Set<LogicalKeyboardKey> synonyms = setKey.synonyms;
          if (synonyms.isNotEmpty) {
            // There currently aren't any synonyms that match more than one key.
            assert(synonyms.length == 1, 'Unexpectedly encountered a key synonym with more than one key.');
            pseudoKeys.add(synonyms.first);
          } else {
            pseudoKeys.add(setKey);
          }
        }
      }
      matchedIntent = _shortcuts[LogicalKeySet.fromSet(pseudoKeys)];
    }
    return matchedIntent;
  }

  /// Handles a key press `event` in the given `context`.
  ///
  /// The optional `keysPressed` argument is used as the set of currently
  /// pressed keys. Defaults to a set derived from [RawKeyboard.keysPressed] if
  /// `keysPressed` is not supplied.
  ///
  /// If a key mapping is found, then the associated action will be invoked
  /// using the [Intent] that the `keysPressed` maps to, and the currently
  /// focused widget's context (from [FocusManager.primaryFocus]).
  ///
  /// Returns a [KeyEventResult.handled] if an action was invoked, otherwise a
  /// [KeyEventResult.skipRemainingHandlers] if [modal] is true, or if it maps
  /// to a [DoNothingAction] with [DoNothingAction.consumesKey] set to false,
  /// and in all other cases returns [KeyEventResult.ignored].
  ///
  /// In order for an action to be invoked (and [KeyEventResult.handled]
  /// returned), a pressed [KeySet] must be mapped to an [Intent], the [Intent]
  /// must be mapped to an [Action], and the [Action] must be enabled.
  @protected
  KeyEventResult handleKeypress(
    BuildContext context,
    RawKeyEvent event, {
    LogicalKeySet? keysPressed,
  }) {
    if (event is! RawKeyDownEvent) {
      return KeyEventResult.ignored;
    }
    assert(context != null);
    assert(
      keysPressed != null || RawKeyboard.instance.keysPressed.isNotEmpty,
      'Received a key down event when no keys are in keysPressed. '
      "This state can occur if the key event being sent doesn't properly "
      'set its modifier flags. This was the event: $event and its data: '
      '${event.data}',
    );
    final Intent? matchedIntent = _find(keysPressed: keysPressed);
    if (matchedIntent != null) {
      final BuildContext primaryContext = primaryFocus!.context!;
      assert (primaryContext != null);
      final Action<Intent>? action = Actions.maybeFind<Intent>(
        primaryContext,
        intent: matchedIntent,
      );
      if (action != null && action.isEnabled(matchedIntent)) {
        Actions.of(primaryContext).invokeAction(action, matchedIntent, primaryContext);
        return action.consumesKey(matchedIntent)
            ? KeyEventResult.handled
            : KeyEventResult.skipRemainingHandlers;
      }
    }
    return modal ? KeyEventResult.skipRemainingHandlers : KeyEventResult.ignored;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Map<LogicalKeySet, Intent>>('shortcuts', _shortcuts));
    properties.add(FlagProperty('modal', value: modal, ifTrue: 'modal', defaultValue: false));
  }
}

/// A widget to that creates key bindings to specific actions for its
/// descendants.
///
/// This widget establishes a [ShortcutManager] to be used by its descendants
/// when invoking an [Action] via a keyboard key combination that maps to an
/// [Intent].
///
/// {@tool dartpad --template=stateful_widget_scaffold_center}
///
/// Here, we will use the [Shortcuts] and [Actions] widgets to add and subtract
/// from a counter. When the child widget has keyboard focus, and a user presses
/// the keys that have been defined in [Shortcuts], the action that is bound
/// to the appropriate [Intent] for the key is invoked.
///
/// It also shows the use of a [CallbackAction] to avoid creating a new [Action]
/// subclass.
///
/// ```dart imports
/// import 'package:flutter/services.dart';
/// ```
///
/// ```dart preamble
/// class IncrementIntent extends Intent {
///   const IncrementIntent();
/// }
///
/// class DecrementIntent extends Intent {
///   const DecrementIntent();
/// }
/// ```
///
/// ```dart
/// int count = 0;
///
/// @override
/// Widget build(BuildContext context) {
///   return Shortcuts(
///     shortcuts: <LogicalKeySet, Intent>{
///       LogicalKeySet(LogicalKeyboardKey.arrowUp): const IncrementIntent(),
///       LogicalKeySet(LogicalKeyboardKey.arrowDown): const DecrementIntent(),
///     },
///     child: Actions(
///       actions: <Type, Action<Intent>>{
///         IncrementIntent: CallbackAction<IncrementIntent>(
///           onInvoke: (IncrementIntent intent) => setState(() {
///             count = count + 1;
///           }),
///         ),
///         DecrementIntent: CallbackAction<DecrementIntent>(
///           onInvoke: (DecrementIntent intent) => setState(() {
///             count = count - 1;
///           }),
///         ),
///       },
///       child: Focus(
///         autofocus: true,
///         child: Column(
///           children: <Widget>[
///             const Text('Add to the counter by pressing the up arrow key'),
///             const Text(
///                 'Subtract from the counter by pressing the down arrow key'),
///             Text('count: $count'),
///           ],
///         ),
///       ),
///     ),
///   );
/// }
/// ```
/// {@end-tool}
///
/// {@tool dartpad --template=stateful_widget_scaffold_center}
///
/// This slightly more complicated, but more flexible, example creates a custom
/// [Action] subclass to increment and decrement within a widget (a [Column])
/// that has keyboard focus. When the user presses the up and down arrow keys,
/// the counter will increment and decrement a data model using the custom
/// actions.
///
/// One thing that this demonstrates is passing arguments to the [Intent] to be
/// carried to the [Action]. This shows how actions can get data either from
/// their own construction (like the `model` in this example), or from the
/// intent passed to them when invoked (like the increment `amount` in this
/// example).
///
/// ```dart imports
/// import 'package:flutter/services.dart';
/// ```
///
/// ```dart preamble
/// class Model with ChangeNotifier {
///   int count = 0;
///   void incrementBy(int amount) {
///     count += amount;
///     notifyListeners();
///   }
///
///   void decrementBy(int amount) {
///     count -= amount;
///     notifyListeners();
///   }
/// }
///
/// class IncrementIntent extends Intent {
///   const IncrementIntent(this.amount);
///
///   final int amount;
/// }
///
/// class DecrementIntent extends Intent {
///   const DecrementIntent(this.amount);
///
///   final int amount;
/// }
///
/// class IncrementAction extends Action<IncrementIntent> {
///   IncrementAction(this.model);
///
///   final Model model;
///
///   @override
///   void invoke(covariant IncrementIntent intent) {
///     model.incrementBy(intent.amount);
///   }
/// }
///
/// class DecrementAction extends Action<DecrementIntent> {
///   DecrementAction(this.model);
///
///   final Model model;
///
///   @override
///   void invoke(covariant DecrementIntent intent) {
///     model.decrementBy(intent.amount);
///   }
/// }
/// ```
///
/// ```dart
/// Model model = Model();
///
/// @override
/// Widget build(BuildContext context) {
///   return Shortcuts(
///     shortcuts: <LogicalKeySet, Intent>{
///       LogicalKeySet(LogicalKeyboardKey.arrowUp): const IncrementIntent(2),
///       LogicalKeySet(LogicalKeyboardKey.arrowDown): const DecrementIntent(2),
///     },
///     child: Actions(
///       actions: <Type, Action<Intent>>{
///         IncrementIntent: IncrementAction(model),
///         DecrementIntent: DecrementAction(model),
///       },
///       child: Focus(
///         autofocus: true,
///         child: Column(
///           children: <Widget>[
///             const Text('Add to the counter by pressing the up arrow key'),
///             const Text(
///                 'Subtract from the counter by pressing the down arrow key'),
///             AnimatedBuilder(
///               animation: model,
///               builder: (BuildContext context, Widget? child) {
///                 return Text('count: ${model.count}');
///               },
///             ),
///           ],
///         ),
///       ),
///     ),
///   );
/// }
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [Intent], a class for containing a description of a user action to be
///    invoked.
///  * [Action], a class for defining an invocation of a user action.
///  * [CallbackAction], a class for creating an action from a callback.
class Shortcuts extends StatefulWidget {
  /// Creates a const [Shortcuts] widget.
  ///
  /// The [child] and [shortcuts] arguments are required and must not be null.
  const Shortcuts({
    Key? key,
    this.manager,
    required this.shortcuts,
    required this.child,
    this.debugLabel,
  }) : assert(shortcuts != null),
       assert(child != null),
       super(key: key);

  /// The [ShortcutManager] that will manage the mapping between key
  /// combinations and [Action]s.
  ///
  /// If not specified, uses a default-constructed [ShortcutManager].
  ///
  /// This manager will be given new [shortcuts] to manage whenever the
  /// [shortcuts] change materially.
  final ShortcutManager? manager;

  /// {@template flutter.widgets.shortcuts.shortcuts}
  /// The map of shortcuts that the [ShortcutManager] will be given to manage.
  ///
  /// For performance reasons, it is recommended that a pre-built map is passed
  /// in here (e.g. a final variable from your widget class) instead of defining
  /// it inline in the build function.
  /// {@endtemplate}
  final Map<LogicalKeySet, Intent> shortcuts;

  /// The child widget for this [Shortcuts] widget.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  /// The debug label that is printed for this node when logged.
  ///
  /// If this label is set, then it will be displayed instead of the shortcut
  /// map when logged.
  ///
  /// This allows simplifying the diagnostic output to avoid cluttering it
  /// unnecessarily with large default shortcut maps.
  final String? debugLabel;

  /// Returns the [ShortcutManager] that most tightly encloses the given
  /// [BuildContext].
  ///
  /// The [context] argument must not be null.
  ///
  /// If no [Shortcuts] widget encloses the context given, will assert in debug
  /// mode and throw an exception in release mode.
  ///
  /// See also:
  ///
  ///  * [maybeOf], which is similar to this function, but will return null if
  ///    it doesn't find a [Shortcuts] ancestor.
  static ShortcutManager of(BuildContext context) {
    assert(context != null);
    final _ShortcutsMarker? inherited = context.dependOnInheritedWidgetOfExactType<_ShortcutsMarker>();
    assert(() {
      if (inherited == null) {
        throw FlutterError(
          'Unable to find a $Shortcuts widget in the context.\n'
          '$Shortcuts.of() was called with a context that does not contain a '
          '$Shortcuts widget.\n'
          'No $Shortcuts ancestor could be found starting from the context that was '
          'passed to $Shortcuts.of().\n'
          'The context used was:\n'
          '  $context',
        );
      }
      return true;
    }());
    return inherited!.manager;
  }

  /// Returns the [ShortcutManager] that most tightly encloses the given
  /// [BuildContext].
  ///
  /// The [context] argument must not be null.
  ///
  /// If no [Shortcuts] widget encloses the context given, will return null.
  ///
  /// See also:
  ///
  ///  * [of], which is similar to this function, but returns a non-nullable
  ///    result, and will throw an exception if it doesn't find a [Shortcuts]
  ///    ancestor.
  static ShortcutManager? maybeOf(BuildContext context) {
    assert(context != null);
    final _ShortcutsMarker? inherited = context.dependOnInheritedWidgetOfExactType<_ShortcutsMarker>();
    return inherited?.manager;
  }

  @override
  _ShortcutsState createState() => _ShortcutsState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ShortcutManager>('manager', manager, defaultValue: null));
    properties.add(ShortcutMapProperty('shortcuts', shortcuts, description: debugLabel?.isNotEmpty ?? false ? debugLabel : null));
  }
}

class _ShortcutsState extends State<Shortcuts> {
  ShortcutManager? _internalManager;
  ShortcutManager get manager => widget.manager ?? _internalManager!;

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
    if (widget.manager != oldWidget.manager) {
      if (widget.manager != null) {
        _internalManager?.dispose();
        _internalManager = null;
      } else {
        _internalManager ??= ShortcutManager();
      }
    }
    manager.shortcuts = widget.shortcuts;
  }

  KeyEventResult _handleOnKey(FocusNode node, RawKeyEvent event) {
    if (node.context == null) {
      return KeyEventResult.ignored;
    }
    return manager.handleKeypress(node.context!, event);
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      debugLabel: '$Shortcuts',
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
    required ShortcutManager manager,
    required Widget child,
  })  : assert(manager != null),
        assert(child != null),
        super(notifier: manager, child: child);

  ShortcutManager get manager => super.notifier!;
}
