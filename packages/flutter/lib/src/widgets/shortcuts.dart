// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:flutter/cupertino.dart';
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
  /// The same [KeyboardKey] may not be appear more than once in the set.
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
  /// The `keys` set must not be empty.
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

/// An interface to define the keyboard key combination to trigger a shortcut.
///
/// A [Shortcuts] widget maps [ShortcutPrompt]s to [Intent]s to define the
/// behavior that a key combination should trigger. When a [Shortcuts] widget
/// receives a key event, it checks the following conditions for every registered
/// prompt in insertion order and chooses the first `Intent` whose prompt matches
/// all conditions, if any:
///
///  * The event's [RawKeyEvent.logicalKey] is one of [triggers].
///  * The [accepts] returns true.
///
/// See also:
///
///  * [LogicalKeySet], an implementation that requires one or more
///    [LogicalKeyboardKey]s to be pressed at the same time.
abstract class ShortcutPrompt {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const ShortcutPrompt();

  /// All the keys that might be the final event to trigger this shortcut.
  ///
  /// For example, for `Ctrl-A`, the KeyA is the only trigger, while Ctrl is not,
  /// because the shortcut should only work by pressing KeyA *after* Ctrl, but
  /// not before. For `Ctrl-A-E`, on the other hand, both KeyA and KeyE should be
  /// triggers, since either of them is allowed to trigger.
  ///
  /// The trigger keys are used as the first-pass filter for incoming events, as
  /// [Intent]s are stored in a [Map] and indexed by trigger keys. Subclasses
  /// should make sure that the return value of this method does not change
  /// throughout the lifespan of this object.
  Iterable<LogicalKeyboardKey>? get triggers;

  /// Whether the triggering `event` and the keyboard `state` at the time of the
  /// event meet required conditions, providing that the event is a triggering
  /// event.
  ///
  /// For example, for `Ctrl-A`, it has to check if the event is a
  /// [RawKeyDownEvent], if either side of the Ctrl key is pressed, and none of
  /// the Shift keys, Alt keys, or Meta keys are pressed; it doesn't have to
  /// check if KeyA is pressed, since it's already guaranteed.
  ///
  /// This method must not cause any side effect to `state`. Typically
  /// this is only used to query whether [RawKeyboard.keysPressed] contains
  /// a key.
  ///
  /// See also:
  ///
  ///  * [LogicalKeyboardKey.collapseSynonyms], which helps deciding whether a
  ///    modifier key is pressed when the side variation is not important.
  bool accepts(RawKeyEvent event, RawKeyboard state);

  /// Returns a description of the key set that is short and readable.
  ///
  /// Intended to be used in debug mode for logging purposes.
  String debugDescribeKeys();
}

@immutable
class _StandardPromptCore {
  const _StandardPromptCore({
    required this.control,
    required this.shift,
    required this.alt,
    required this.meta,
    required this.triggeringKeys,
    required this.stateKeys,
  });

  final bool? control;
  final bool? shift;
  final bool? alt;
  final bool? meta;
  final Set<LogicalKeyboardKey> triggeringKeys;
  final Set<LogicalKeyboardKey> stateKeys;

  bool requiresState(RawKeyboard state) {
    final Set<LogicalKeyboardKey> pressed = LogicalKeyboardKey.collapseSynonyms(state.keysPressed)
      ..addAll(state.keysPressed);
    return (control == null || control == pressed.contains(LogicalKeyboardKey.control))
        && (shift == null || shift == pressed.contains(LogicalKeyboardKey.shift))
        && (alt == null || alt == pressed.contains(LogicalKeyboardKey.alt))
        && (meta == null || meta == pressed.contains(LogicalKeyboardKey.meta))
        && stateKeys.every((LogicalKeyboardKey key) => pressed.contains(key));
  }
}

/// A [ShortcutPrompt] that requires one or more [LogicalKeyboardKey]s
/// to be pressed at the same time.
///
/// More restrictions might be given to approach the typical expectation for
/// shorcut combinations, depending on whether the given set of keys contain any
/// non-modifier keys, where modifier keys are defined as both side of Ctrl keys,
/// Shift keys, Alt keys, and Meta keys.
///
/// If the keys contains non-modifier keys, then the non-modifier keys are used
/// as trigger keys, and requires all of the following conditions:
///
///  * All non-modifier keys are pressed.
///  * *Either* side of the mentioned modifier keys, even if side-specific
///    variations are given, are pressed.
///  * No other modifier keys are pressed.
///
/// {@tool snippet}
/// The following object can be used for shorcut Ctrl-A. It:
///
///  * Accepts pressing ContrlLeft then KeyA.
///  * Accepts pressing ContrlRight then KeyA.
///  * Rejects pressing KeyA then ContrlLeft.
///  * Rejects pressing ShiftLeft, ContrlLeft, then KeyA.
/// ```dart
/// const LogicalKeySet set1 = LogicalKeySet(
///   LogicalKeyboardKey.controlLeft,
///   LogicalKeyboardKey.keyA,
/// );
/// ```
/// {@end-tool}
///
/// If the keys contains only modifier keys, then all modifier keys are used
/// as trigger keys, and their given variations (side-specific or any side)
/// are required to be held at the event, and it doesn't check the state of other
/// modifiers.
///
/// {@tool snippet}
/// The following object can be used for shorcut CtrlLeft-Shift. It:
///
///  * Accepts pressing ContrlLeft then ShiftLeft.
///  * Accepts pressing ContrlLeft then ShiftRight.
///  * Accepts pressing ShiftLeft then ContrlLeft.
///  * Rejects pressing ControlLeft then ShiftRight.
///  * Accepts pressing ShiftLeft, AltLeft, then ContrlLeft.
/// ```
/// const LogicalKeySet set2 = LogicalKeySet(
///   LogicalKeyboardKey.controlLeft,
///   LogicalKeyboardKey.shift,
/// );
/// ```
/// {@end-tool}
///
/// This class is also a thin wrapper around a [Set], but changes the equality
/// comparison from an identity comparison to a contents comparison so that
/// non-identical sets with the same keys in them will compare as equal.
class LogicalKeySet extends KeySet<LogicalKeyboardKey> with Diagnosticable
    implements ShortcutPrompt {
  /// A constructor for making a [LogicalKeySet] of up to four keys.
  ///
  /// If you need a set of more than four keys, use [LogicalKeySet.fromSet].
  ///
  /// The same [LogicalKeyboardKey] may not be appear more than once in the set.
  LogicalKeySet(
    LogicalKeyboardKey key1, [
    LogicalKeyboardKey? key2,
    LogicalKeyboardKey? key3,
    LogicalKeyboardKey? key4,
  ]) : super(key1, key2, key3, key4);

  /// Create  a [LogicalKeySet] from a set of [LogicalKeyboardKey]s.
  ///
  /// Do not mutate the `keys` set after passing it to this object.
  LogicalKeySet.fromSet(Set<LogicalKeyboardKey> keys) : super.fromSet(keys);

  late final _StandardPromptCore _promptCore = _computePromptCore(keys);

  @override
  Iterable<LogicalKeyboardKey>? get triggers => _promptCore.triggeringKeys;

  @override
  bool accepts(RawKeyEvent event, RawKeyboard state) {
    return event is RawKeyDownEvent && _promptCore.requiresState(state);
  }

  static const Set<LogicalKeyboardKey> _modifiers = <LogicalKeyboardKey>{
    LogicalKeyboardKey.alt,
    LogicalKeyboardKey.control,
    LogicalKeyboardKey.meta,
    LogicalKeyboardKey.shift,
  };
  static const Map<LogicalKeyboardKey, List<LogicalKeyboardKey>> _unmapSynonyms = <LogicalKeyboardKey, List<LogicalKeyboardKey>>{
    LogicalKeyboardKey.control: <LogicalKeyboardKey>[LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.controlRight],
    LogicalKeyboardKey.shift: <LogicalKeyboardKey>[LogicalKeyboardKey.shiftLeft, LogicalKeyboardKey.shiftRight],
    LogicalKeyboardKey.alt: <LogicalKeyboardKey>[LogicalKeyboardKey.altLeft, LogicalKeyboardKey.altRight],
    LogicalKeyboardKey.meta: <LogicalKeyboardKey>[LogicalKeyboardKey.metaLeft, LogicalKeyboardKey.metaRight],
  };

  /// Returns a description of the key set that is short and readable.
  ///
  /// Intended to be used in debug mode for logging purposes.
  @override
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
        }
    );
    return sortedKeys.map<String>((LogicalKeyboardKey key) => key.debugName.toString()).join(' + ');
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Set<LogicalKeyboardKey>>('keys', _keys, description: debugDescribeKeys()));
  }

  static _StandardPromptCore _computePromptCore(Set<LogicalKeyboardKey> keys) {
    final Set<LogicalKeyboardKey> collapsed = LogicalKeyboardKey.collapseSynonyms(keys);
    assert(collapsed.isNotEmpty);
    final Set<LogicalKeyboardKey> nonModifierKeys = collapsed.difference(_modifiers);
    if (nonModifierKeys.isEmpty) {
      // If there are no keys left with all modifiers excluded, consider
      // modifier keys as normal triggering keys.
      final Set<LogicalKeyboardKey> triggeringKeys = keys.expand(
        (LogicalKeyboardKey key) => _unmapSynonyms[key] ?? <LogicalKeyboardKey>[key],
      ).toSet();
      return _StandardPromptCore(
        control: null,
        shift: null,
        alt: null,
        meta: null,
        triggeringKeys: triggeringKeys,
        stateKeys: keys,
      );
    }
    return _StandardPromptCore(
      control: collapsed.contains(LogicalKeyboardKey.control),
      shift: collapsed.contains(LogicalKeyboardKey.shift),
      alt: collapsed.contains(LogicalKeyboardKey.alt),
      meta: collapsed.contains(LogicalKeyboardKey.meta),
      triggeringKeys: nonModifierKeys,
      stateKeys: nonModifierKeys,
    );
  }
}

/// A [DiagnosticsProperty] which handles formatting a `Map<LogicalKeySet,
/// Intent>` (the same type as the [Shortcuts.shortcuts] property) so that its
/// diagnostic output is human-readable.
class ShortcutMapProperty extends DiagnosticsProperty<Map<ShortcutPrompt, Intent>> {
  /// Create a diagnostics property for `Map<LogicalKeySet, Intent>` objects,
  /// which are the same type as the [Shortcuts.shortcuts] property.
  ShortcutMapProperty(
    String name,
    Map<ShortcutPrompt, Intent> value, {
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
  Map<ShortcutPrompt, Intent> get value => super.value!;

  @override
  String valueToString({ TextTreeConfiguration? parentConfiguration }) {
    return '{${value.keys.map<String>((ShortcutPrompt keySet) => '{${keySet.debugDescribeKeys()}}: ${value[keySet]}').join(', ')}}';
  }
}

class _PromptIntent with Diagnosticable {
  const _PromptIntent(this.prompt, this.intent);
  final ShortcutPrompt prompt;
  final Intent intent;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<String>('prompt', prompt.debugDescribeKeys()));
    properties.add(DiagnosticsProperty<Intent>('intent', intent));
  }
}

/// A manager of keyboard shortcut bindings.
///
/// A [ShortcutManager] is obtained by calling [Shortcuts.of] on the context of
/// the widget that you want to find a manager for.
class ShortcutManager extends ChangeNotifier with Diagnosticable {
  /// Constructs a [ShortcutManager].
  ShortcutManager({
    Map<ShortcutPrompt, Intent> shortcuts = const <ShortcutPrompt, Intent>{},
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
  Map<ShortcutPrompt, Intent> get shortcuts => _shortcuts;
  Map<ShortcutPrompt, Intent> _shortcuts = <ShortcutPrompt, Intent>{};
  set shortcuts(Map<ShortcutPrompt, Intent> value) {
    assert(value != null);
    if (!mapEquals<ShortcutPrompt, Intent>(_shortcuts, value)) {
      _shortcuts = value;
      _indexedShortcutsCache = null;
      notifyListeners();
    }
  }

  static Map<LogicalKeyboardKey?, List<_PromptIntent>> _indexShortcuts(Map<ShortcutPrompt, Intent> source) {
    final Map<LogicalKeyboardKey?, List<_PromptIntent>> result = <LogicalKeyboardKey?, List<_PromptIntent>>{};
    source.forEach((ShortcutPrompt prompt, Intent intent) {
      final Iterable<LogicalKeyboardKey?>? triggeringKeys = prompt.triggers;
      for (final LogicalKeyboardKey? trigger in triggeringKeys ?? <LogicalKeyboardKey?>[null]) {
        result.putIfAbsent(trigger, () => <_PromptIntent>[])
          .add(_PromptIntent(prompt, intent));
      }
    });
    return result;
  }
  Map<LogicalKeyboardKey?, List<_PromptIntent>> get _indexedShortcuts {
    return _indexedShortcutsCache ??= _indexShortcuts(_shortcuts);
  }
  Map<LogicalKeyboardKey?, List<_PromptIntent>>? _indexedShortcutsCache;

  /// Returns the [Intent], if any, that matches the current set of pressed
  /// keys.
  ///
  /// Returns null if no intent matches the current set of pressed keys.
  ///
  /// Defaults to a set derived from [RawKeyboard.keysPressed] if `keysPressed`
  /// is not supplied.
  Intent? _find(RawKeyEvent event, RawKeyboard state) {
    final List<_PromptIntent>? candidates = _indexedShortcuts[event.logicalKey];
    if (candidates == null)
      return null;
    for (final _PromptIntent promptIntent in candidates) {
      if (promptIntent.prompt.accepts(event, state)) {
        return promptIntent.intent;
      }
    }
    return null;
  }

  /// Handles a key press `event` in the given `context`.
  ///
  /// If a key mapping is found, then the associated action will be invoked
  /// using the [Intent], and the currently focused widget's context (from
  /// [FocusManager.primaryFocus]).
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
  KeyEventResult handleKeypress(BuildContext context, RawKeyEvent event) {
    if (event is! RawKeyDownEvent) {
      return KeyEventResult.ignored;
    }
    assert(context != null);
    assert(RawKeyboard.instance.keysPressed.isNotEmpty,
      'Received a key down event when no keys are in keysPressed. '
      "This state can occur if the key event being sent doesn't properly "
      'set its modifier flags. This was the event: $event and its data: '
      '${event.data}');
    final Intent? matchedIntent = _find(event, RawKeyboard.instance);
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
    properties.add(DiagnosticsProperty<Map<ShortcutPrompt, Intent>>('shortcuts', _shortcuts));
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
///     shortcuts: <ShortcutPrompt, Intent>{
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
///     shortcuts: <ShortcutPrompt, Intent>{
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
  /// The [child] and [shortcuts] arguments are required.
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
  final Map<ShortcutPrompt, Intent> shortcuts;

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
    return inherited!.manager;
  }

  /// Returns the [ShortcutManager] that most tightly encloses the given
  /// [BuildContext].
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
