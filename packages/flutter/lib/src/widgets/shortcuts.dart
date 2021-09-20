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
/// [ShortcutActivator]s are used by [Shortcuts] widgets, and are mapped to
/// [Intent]s, the intended behavior that the key combination should trigger.
/// When a [Shortcuts] widget receives a key event, its [ShortcutManager] looks
/// up the first matching [ShortcutActivator], and signals the corresponding
/// [Intent], which might trigger an action as defined by a hierarchy of
/// [Actions] widgets. For a detailed introduction on the mechanism and use of
/// the shortcut-action system, see [Actions].
///
/// The matching [ShortcutActivator] is looked up in the following way:
///
///  * Find the registered [ShortcutActivator]s whose [triggers] contain the
///    incoming event.
///  * Of the previous list, finds the first activator whose [accepts] returns
///    true in the order of insertion.
///
/// See also:
///
///  * [SingleActivator], an implementation that represents a single key combined
///    with modifiers (control, shift, alt, meta).
///  * [CharacterActivator], an implementation that represents key combinations
///    that result in the specified character, such as question mark.
///  * [LogicalKeySet], an implementation that requires one or more
///    [LogicalKeyboardKey]s to be pressed at the same time. Prefer
///    [SingleActivator] when possible.
abstract class ShortcutActivator {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const ShortcutActivator();

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
  ///
  /// This method might also return null, which means this activator declares
  /// all keys as the trigger key. All activators whose [triggers] returns null
  /// will be tested with [accepts] on every event. Since this becomes a
  /// linear search, and having too many might impact performance, it is
  /// preferred to return non-null [triggers] whenever possible.
  Iterable<LogicalKeyboardKey>? get triggers;

  /// Whether the triggering `event` and the keyboard `state` at the time of the
  /// event meet required conditions, providing that the event is a triggering
  /// event.
  ///
  /// For example, for `Ctrl-A`, it has to check if the event is a
  /// [KeyDownEvent], if either side of the Ctrl key is pressed, and none of
  /// the Shift keys, Alt keys, or Meta keys are pressed; it doesn't have to
  /// check if KeyA is pressed, since it's already guaranteed.
  ///
  /// This method must not cause any side effects for the `state`. Typically
  /// this is only used to query whether [HardwareKeyboard.logicalKeysPressed]
  /// contains a key.
  ///
  /// Since [ShortcutActivator] accepts all event types, subclasses might want
  /// to check the event type in [accepts].
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

/// A set of [LogicalKeyboardKey]s that can be used as the keys in a map.
///
/// [LogicalKeySet] can be used as a [ShortcutActivator]. It is not recommended
/// to use [LogicalKeySet] for a common shortcut such as `Delete` or `Ctrl+C`,
/// prefer [SingleActivator] when possible, whose behavior more closely resembles
/// that of typical platforms.
///
/// When used as a [ShortcutActivator], [LogicalKeySet] will activate the intent
/// when all [keys] are pressed, and no others, except that modifier keys are
/// considered without considering sides (e.g. control left and control right are
/// considered the same).
///
/// {@tool dartpad --template=stateful_widget_scaffold_center}
/// In the following example, the counter is increased when the following key
/// sequences are pressed:
///
///  * Control left, then C.
///  * Control right, then C.
///  * C, then Control left.
///
/// But not when:
///
///  * Control left, then A, then C.
///
/// ** See code in examples/api/lib/widgets/shortcuts/logical_key_set.0.dart **
/// {@end-tool}
///
/// This is also a thin wrapper around a [Set], but changes the equality
/// comparison from an identity comparison to a contents comparison so that
/// non-identical sets with the same keys in them will compare as equal.

class LogicalKeySet extends KeySet<LogicalKeyboardKey> with Diagnosticable
    implements ShortcutActivator {
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

  @override
  Iterable<LogicalKeyboardKey> get triggers => _triggers;
  late final Set<LogicalKeyboardKey> _triggers = keys.expand(
    (LogicalKeyboardKey key) => _unmapSynonyms[key] ?? <LogicalKeyboardKey>[key],
  ).toSet();

  @override
  bool accepts(RawKeyEvent event, RawKeyboard state) {
    if (event is! RawKeyDownEvent)
      return false;
    final Set<LogicalKeyboardKey> collapsedRequired = LogicalKeyboardKey.collapseSynonyms(keys);
    final Set<LogicalKeyboardKey> collapsedPressed = LogicalKeyboardKey.collapseSynonyms(state.keysPressed);
    final bool keysEqual = collapsedRequired.difference(collapsedPressed).isEmpty
      && collapsedRequired.length == collapsedPressed.length;
    return keysEqual;
  }

  static final Set<LogicalKeyboardKey> _modifiers = <LogicalKeyboardKey>{
    LogicalKeyboardKey.alt,
    LogicalKeyboardKey.control,
    LogicalKeyboardKey.meta,
    LogicalKeyboardKey.shift,
  };
  static final Map<LogicalKeyboardKey, List<LogicalKeyboardKey>> _unmapSynonyms = <LogicalKeyboardKey, List<LogicalKeyboardKey>>{
    LogicalKeyboardKey.control: <LogicalKeyboardKey>[LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.controlRight],
    LogicalKeyboardKey.shift: <LogicalKeyboardKey>[LogicalKeyboardKey.shiftLeft, LogicalKeyboardKey.shiftRight],
    LogicalKeyboardKey.alt: <LogicalKeyboardKey>[LogicalKeyboardKey.altLeft, LogicalKeyboardKey.altRight],
    LogicalKeyboardKey.meta: <LogicalKeyboardKey>[LogicalKeyboardKey.metaLeft, LogicalKeyboardKey.metaRight],
  };

  @override
  String debugDescribeKeys() {
    final List<LogicalKeyboardKey> sortedKeys = keys.toList()
      ..sort((LogicalKeyboardKey a, LogicalKeyboardKey b) {
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
        });
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
class ShortcutMapProperty extends DiagnosticsProperty<Map<ShortcutActivator, Intent>> {
  /// Create a diagnostics property for `Map<ShortcutActivator, Intent>` objects,
  /// which are the same type as the [Shortcuts.shortcuts] property.
  ShortcutMapProperty(
    String name,
    Map<ShortcutActivator, Intent> value, {
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
  Map<ShortcutActivator, Intent> get value => super.value!;

  @override
  String valueToString({TextTreeConfiguration? parentConfiguration}) {
    return '{${value.keys.map<String>((ShortcutActivator keySet) => '{${keySet.debugDescribeKeys()}}: ${value[keySet]}').join(', ')}}';
  }
}

/// A shortcut key combination of a single key and modifiers.
///
/// The [SingleActivator] implements typical shortcuts such as:
///
///  * ArrowLeft
///  * Shift + Delete
///  * Control + Alt + Meta + Shift + A
///
/// More specifically, it creates shortcut key combinations that are composed of a
/// [trigger] key, and zero, some, or all of the four modifiers (control, shift,
/// alt, meta). The shortcut is activated when the following conditions are met:
///
///  * The incoming event is a down event for a [trigger] key.
///  * If [control] is true, then at least one control key must be held.
///    Otherwise, no control keys must be held.
///  * Similar conditions apply for the [alt], [shift], and [meta] keys.
///
/// This resembles the typical behavior of most operating systems, and handles
/// modifier keys differently from [LogicalKeySet] in the following way:
///
///  * [SingleActivator]s allow additional non-modifier keys being pressed in
///    order to activate the shortcut. For example, pressing key X while holding
///    ControlLeft *and key A* will be accepted by
///    `SingleActivator(LogicalKeyboardKey.keyX, control: true)`.
///  * [SingleActivator]s do not consider modifiers to be a trigger key. For
///    example, pressing ControlLeft while holding key X *will not* activate a
///    `SingleActivator(LogicalKeyboardKey.keyX, control: true)`.
///
/// See also:
///
///  * [CharacterActivator], an activator that represents key combinations
///    that result in the specified character, such as question mark.
class SingleActivator with Diagnosticable implements ShortcutActivator {
  /// Triggered when the [trigger] key is pressed or repeated when the
  /// modifiers are held.
  ///
  /// The `trigger` should be the non-modifier key that is pressed after all the
  /// modifiers, such as [LogicalKeyboardKey.keyC] as in `Ctrl+C`. It must not be
  /// a modifier key (sided or unsided).
  ///
  /// The `control`, `shift`, `alt`, and `meta` flags represent whether
  /// the respect modifier keys should be held (true) or released (false)
  ///
  /// On each [RawKeyDownEvent] of the [trigger] key, this activator checks
  /// whether the specified modifier conditions are met.
  ///
  /// {@tool dartpad --template=stateful_widget_scaffold_center}
  /// In the following example, the shortcut `Control + C` increases the counter:
  ///
  /// ** See code in examples/api/lib/widgets/shortcuts/single_activator.single_activator.0.dart **
  /// {@end-tool}
  const SingleActivator(
    this.trigger, {
    this.control = false,
    this.shift = false,
    this.alt = false,
    this.meta = false,
  }) : // The enumerated check with `identical` is cumbersome but the only way
       // since const constructors can not call functions such as `==` or
       // `Set.contains`. Checking with `identical` might not work when the
       // key object is created from ID, but it covers common cases.
       assert(
         !identical(trigger, LogicalKeyboardKey.control) &&
         !identical(trigger, LogicalKeyboardKey.controlLeft) &&
         !identical(trigger, LogicalKeyboardKey.controlRight) &&
         !identical(trigger, LogicalKeyboardKey.shift) &&
         !identical(trigger, LogicalKeyboardKey.shiftLeft) &&
         !identical(trigger, LogicalKeyboardKey.shiftRight) &&
         !identical(trigger, LogicalKeyboardKey.alt) &&
         !identical(trigger, LogicalKeyboardKey.altLeft) &&
         !identical(trigger, LogicalKeyboardKey.altRight) &&
         !identical(trigger, LogicalKeyboardKey.meta) &&
         !identical(trigger, LogicalKeyboardKey.metaLeft) &&
         !identical(trigger, LogicalKeyboardKey.metaRight),
       );

  /// The non-modifier key of the shortcut that is pressed after all modifiers
  /// to activate the shortcut.
  ///
  /// For example, for `Control + C`, [trigger] should be
  /// [LogicalKeyboardKey.keyC].
  final LogicalKeyboardKey trigger;

  /// Whether either (or both) control keys should be held for [trigger] to
  /// activate the shortcut.
  ///
  /// If false, then all control keys must be released when the event is received
  /// in order to activate the shortcut.
  ///
  /// See also:
  ///
  ///  * [LogicalKeyboardKey.controlLeft], [LogicalKeyboardKey.controlRight].
  final bool control;

  /// Whether either (or both) shift keys should be held for [trigger] to
  /// activate the shortcut.
  ///
  /// If false, then all shift keys must be released when the event is received
  /// in order to activate the shortcut.
  ///
  /// See also:
  ///
  ///  * [LogicalKeyboardKey.shiftLeft], [LogicalKeyboardKey.shiftRight].
  final bool shift;

  /// Whether either (or both) alt keys should be held for [trigger] to
  /// activate the shortcut.
  ///
  /// If false, then all alt keys must be released when the event is received
  /// in order to activate the shortcut.
  ///
  /// See also:
  ///
  ///  * [LogicalKeyboardKey.altLeft], [LogicalKeyboardKey.altRight].
  final bool alt;

  /// Whether either (or both) meta keys should be held for [trigger] to
  /// activate the shortcut.
  ///
  /// If false, then all meta keys must be released when the event is received
  /// in order to activate the shortcut.
  ///
  /// See also:
  ///
  ///  * [LogicalKeyboardKey.metaLeft], [LogicalKeyboardKey.metaRight].
  final bool meta;

  @override
  Iterable<LogicalKeyboardKey> get triggers sync* {
    yield trigger;
  }

  @override
  bool accepts(RawKeyEvent event, RawKeyboard state) {
    final Set<LogicalKeyboardKey> pressed = state.keysPressed;
    return event is RawKeyDownEvent
      && (control == (pressed.contains(LogicalKeyboardKey.controlLeft) || pressed.contains(LogicalKeyboardKey.controlRight)))
      && (shift == (pressed.contains(LogicalKeyboardKey.shiftLeft) || pressed.contains(LogicalKeyboardKey.shiftRight)))
      && (alt == (pressed.contains(LogicalKeyboardKey.altLeft) || pressed.contains(LogicalKeyboardKey.altRight)))
      && (meta == (pressed.contains(LogicalKeyboardKey.metaLeft) || pressed.contains(LogicalKeyboardKey.metaRight)));
  }

  /// Returns a short and readable description of the key combination.
  ///
  /// Intended to be used in debug mode for logging purposes. In release mode,
  /// [debugDescribeKeys] returns an empty string.
  @override
  String debugDescribeKeys() {
    String result = '';
    assert(() {
      final List<String> keys = <String>[
        if (control) 'Control',
        if (alt) 'Alt',
        if (meta) 'Meta',
        if (shift) 'Shift',
        trigger.debugName ?? trigger.toStringShort(),
      ];
      result = keys.join(' + ');
      return true;
    }());
    return result;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<String>('keys', debugDescribeKeys()));
  }
}

/// A shortcut combination that is triggered by a key event that produces a
/// specific character.
///
/// Keys often produce different characters when combined with modifiers. For
/// example, it might be helpful for the user to bring up a help menu by
/// pressing the question mark ('?'). However, there is no logical key that
/// directly represents a question mark. Althouh 'Shift+Slash' produces a '?'
/// character on a US keyboard, its logical key is still considered a Slash key,
/// and hard-coding 'Shift+Slash' in this situation is unfriendly to other
/// keyboard layouts.
///
/// For example, `CharacterActivator('?')` is triggered when a key combination
/// results in a question mark, which is 'Shift+Slash' on a US keyboard, but
/// 'Shift+Comma' on a French keyboard.
///
/// {@tool dartpad --template=stateful_widget_scaffold_center}
/// In the following example, when a key combination results in a question mark,
/// the counter is increased:
///
/// ** See code in examples/api/lib/widgets/shortcuts/character_activator.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [SingleActivator], an activator that represents a single key combined
///    with modifiers, such as `Ctrl+C`.
class CharacterActivator with Diagnosticable implements ShortcutActivator {
  /// Create a [CharacterActivator] from the triggering character.
  const CharacterActivator(this.character);

  /// The character of the triggering event.
  ///
  /// This is typically a single-character string, such as '?' or 'œ', although
  /// [CharacterActivator] doesn't check the length of [character] or whether it
  /// can be matched by any key combination at all. It is case-sensitive, since
  /// the [character] is directly compared by `==` to the character reported by
  /// the platform.
  ///
  /// See also:
  ///
  ///  * [RawKeyEvent.character], the character of a key event.
  final String character;

  @override
  Iterable<LogicalKeyboardKey>? get triggers => null;

  @override
  bool accepts(RawKeyEvent event, RawKeyboard state) {
    return event is RawKeyDownEvent
        && event.character == character;
  }

  @override
  String debugDescribeKeys() {
    String result = '';
    assert(() {
      result = "'$character'";
      return true;
    }());
    return result;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('character', character));
  }
}

class _ActivatorIntentPair with Diagnosticable {
  const _ActivatorIntentPair(this.activator, this.intent);
  final ShortcutActivator activator;
  final Intent intent;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<String>('activator', activator.debugDescribeKeys()));
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
    Map<ShortcutActivator, Intent> shortcuts = const <ShortcutActivator, Intent>{},
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
  Map<ShortcutActivator, Intent> get shortcuts => _shortcuts;
  Map<ShortcutActivator, Intent> _shortcuts = <ShortcutActivator, Intent>{};
  set shortcuts(Map<ShortcutActivator, Intent> value) {
    assert(value != null);
    if (!mapEquals<ShortcutActivator, Intent>(_shortcuts, value)) {
      _shortcuts = value;
      _indexedShortcutsCache = null;
      notifyListeners();
    }
  }

  static Map<LogicalKeyboardKey?, List<_ActivatorIntentPair>> _indexShortcuts(Map<ShortcutActivator, Intent> source) {
    final Map<LogicalKeyboardKey?, List<_ActivatorIntentPair>> result = <LogicalKeyboardKey?, List<_ActivatorIntentPair>>{};
    source.forEach((ShortcutActivator activator, Intent intent) {
      // This intermediate variable is necessary to comply with Dart analyzer.
      final Iterable<LogicalKeyboardKey?>? nullableTriggers = activator.triggers;
      for (final LogicalKeyboardKey? trigger in nullableTriggers ?? <LogicalKeyboardKey?>[null]) {
        result.putIfAbsent(trigger, () => <_ActivatorIntentPair>[])
          .add(_ActivatorIntentPair(activator, intent));
      }
    });
    return result;
  }
  Map<LogicalKeyboardKey?, List<_ActivatorIntentPair>> get _indexedShortcuts {
    return _indexedShortcutsCache ??= _indexShortcuts(_shortcuts);
  }
  Map<LogicalKeyboardKey?, List<_ActivatorIntentPair>>? _indexedShortcutsCache;

  /// Returns the [Intent], if any, that matches the current set of pressed
  /// keys.
  ///
  /// Returns null if no intent matches the current set of pressed keys.
  ///
  /// Defaults to a set derived from [RawKeyboard.keysPressed] if `keysPressed`
  /// is not supplied.
  Intent? _find(RawKeyEvent event, RawKeyboard state) {
    final List<_ActivatorIntentPair>? candidatesByKey = _indexedShortcuts[event.logicalKey];
    final List<_ActivatorIntentPair>? candidatesByNull = _indexedShortcuts[null];
    final List<_ActivatorIntentPair> candidates = <_ActivatorIntentPair>[
      if (candidatesByKey != null) ...candidatesByKey,
      if (candidatesByNull != null) ...candidatesByNull,
    ];
    for (final _ActivatorIntentPair activatorIntent in candidates) {
      if (activatorIntent.activator.accepts(event, state)) {
        return activatorIntent.intent;
      }
    }
    return null;
  }

  /// Handles a key press `event` in the given `context`.
  ///
  /// If a key mapping is found, then the associated action will be invoked using
  /// the [Intent] activated by the [ShortcutActivator] in the [shortcuts] map,
  /// and the currently focused widget's context (from
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
    assert(context != null);
    final Intent? matchedIntent = _find(event, RawKeyboard.instance);
    if (matchedIntent != null) {
      final BuildContext? primaryContext = primaryFocus?.context;
      if (primaryContext != null) {
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
    }
    return modal ? KeyEventResult.skipRemainingHandlers : KeyEventResult.ignored;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Map<ShortcutActivator, Intent>>('shortcuts', _shortcuts));
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
/// Here, we will use the [Shortcuts] and [Actions] widgets to add and subtract
/// from a counter. When the child widget has keyboard focus, and a user presses
/// the keys that have been defined in [Shortcuts], the action that is bound
/// to the appropriate [Intent] for the key is invoked.
///
/// It also shows the use of a [CallbackAction] to avoid creating a new [Action]
/// subclass.
///
/// ** See code in examples/api/lib/widgets/shortcuts/shortcuts.0.dart **
/// {@end-tool}
///
/// {@tool dartpad --template=stateful_widget_scaffold_center}
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
/// ** See code in examples/api/lib/widgets/shortcuts/shortcuts.1.dart **
/// {@end-tool}
///
/// See also:
///
///  * [CallbackShortcuts], a less complicated (but less flexible) way of
///    defining key bindings that just invoke callbacks.
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
  final Map<ShortcutActivator, Intent> shortcuts;

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
  State<Shortcuts> createState() => _ShortcutsState();

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

/// A widget that provides an uncomplicated mechanism for binding a key
/// combination to a specific callback.
///
/// This is similar to the functionality provided by the [Shortcuts] widget, but
/// instead of requiring a mapping to an [Intent], and an [Actions] widget
/// somewhere in the widget tree to bind the [Intent] to, it just takes a set of
/// bindings that bind the key combination directly to a [VoidCallback].
///
/// Because it is a simpler mechanism, it doesn't provide the ability to disable
/// the callbacks, or to separate the definition of the shortcuts from the
/// definition of the code that is triggered by them (the role that actions play
/// in the [Shortcuts]/[Actions] system).
///
/// However, for some applications the complexity and flexibility of the
/// [Shortcuts] and [Actions] mechanism is overkill, and this widget is here for
/// those apps.
///
/// [Shortcuts] and [CallbackShortcuts] can both be used in the same app. As
/// with any key handling widget, if this widget handles a key event then
/// widgets above it in the focus chain will not receive the event. This means
/// that if this widget handles a key, then an ancestor [Shortcuts] widget (or
/// any other key handling widget) will not receive that key, and similarly, if
/// a descendant of this widget handles the key, then the key event will not
/// reach this widget for handling.
///
/// See also:
///  * [Focus], a widget that defines which widgets can receive keyboard focus.
class CallbackShortcuts extends StatelessWidget {
  /// Creates a const [CallbackShortcuts] widget.
  const CallbackShortcuts({
    Key? key,
    required this.bindings,
    required this.child,
  }) : super(key: key);

  /// A map of key combinations to callbacks used to define the shortcut
  /// bindings.
  ///
  /// If a descendant of this widget has focus, and a key is pressed, the
  /// activator keys of this map will be asked if they accept the key event. If
  /// they do, then the corresponding callback is invoked, and the key event
  /// propagation is halted. If none of the activators accept the key event,
  /// then the key event continues to be propagated up the focus chain.
  ///
  /// If more than one activator accepts the key event, then all of the
  /// callbacks associated with activators that accept the key event are
  /// invoked.
  ///
  /// Some examples of [ShortcutActivator] subclasses that can be used to define
  /// the key combinations here are [SingleActivator], [CharacterActivator], and
  /// [LogicalKeySet].
  final Map<ShortcutActivator, VoidCallback> bindings;

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  // A helper function to make the stack trace more useful if the callback
  // throws, by providing the activator and event as arguments that will appear
  // in the stack trace.
  bool _applyKeyBinding(ShortcutActivator activator, RawKeyEvent event) {
    if (activator.accepts(event, RawKeyboard.instance)) {
      bindings[activator]!.call();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKey: (FocusNode node, RawKeyEvent event) {
        KeyEventResult result = KeyEventResult.ignored;
        // Activates all key bindings that match, returns "handled" if any handle it.
        for (final ShortcutActivator activator in bindings.keys) {
          result = _applyKeyBinding(activator, event) ? KeyEventResult.handled : result;
        }
        return result;
      },
      child: child,
    );
  }
}
