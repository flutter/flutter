// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/material.dart';
/// @docImport 'package:flutter/services.dart';
///
/// @docImport 'text_selection.dart';
library;

import 'framework.dart';

/// The buttons that can appear in a context menu by default.
///
/// This enum is deprecated because adding a value to a Dart enum is a breaking
/// change for any code that switches on it exhaustively. Use
/// [ContextMenuButtonKind] instead, which can gain new values without breaking
/// existing code.
///
/// See also:
///
///  * [ContextMenuButtonItem], which uses this enum to describe a button in a
///    context menu.
@Deprecated(
  'Use ContextMenuButtonKind instead. '
  'ContextMenuButtonType cannot gain new values without breaking exhaustive switches. '
  'This feature was deprecated after v3.49.0-1.0.pre.',
)
enum ContextMenuButtonType {
  /// A button that cuts the current text selection.
  cut,

  /// A button that copies the current text selection.
  copy,

  /// A button that pastes the clipboard contents into the focused text field.
  paste,

  /// A button that selects all the contents of the focused text field.
  selectAll,

  /// A button that deletes the current text selection.
  delete,

  /// A button that looks up the current text selection.
  lookUp,

  /// A button that launches a web search for the current text selection.
  searchWeb,

  /// A button that displays the share screen for the current text selection.
  share,

  /// A button for starting Live Text input.
  ///
  /// See also:
  ///  * [LiveText], where the availability of Live Text input can be obtained.
  ///  * [LiveTextInputStatusNotifier], where the status of Live Text can be listened to.
  liveTextInput,

  /// Anything other than the default button types.
  custom,
}

/// The kinds of buttons that can appear in a context menu by default.
///
/// This is an enum-like class rather than a Dart `enum` so that new kinds can
/// be added without breaking code that switches on it. Switches on
/// [ContextMenuButtonKind] can't be exhaustive, so they must include a
/// wildcard (`_`) case that handles kinds added in the future.
///
/// {@tool snippet}
///
/// ```dart
/// String describe(ContextMenuButtonItem item) {
///   return switch (item.kind) {
///     ContextMenuButtonKind.copy => 'Copy',
///     ContextMenuButtonKind.paste => 'Paste',
///     _ => item.label ?? '',
///   };
/// }
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [ContextMenuButtonItem], which uses this class to describe a button in a
///    context menu.
@immutable
final class ContextMenuButtonKind {
  // ignore: deprecated_member_use_from_same_package
  const ContextMenuButtonKind._(this.name, this._legacyType);

  /// A name for this kind, useful for debugging.
  final String name;

  // The closest ContextMenuButtonType for this kind, used to keep the
  // deprecated ContextMenuButtonItem.type working. Kinds with no matching
  // ContextMenuButtonType map to ContextMenuButtonType.custom.
  // ignore: deprecated_member_use_from_same_package
  final ContextMenuButtonType _legacyType;

  /// A button that cuts the current text selection.
  // ignore: deprecated_member_use_from_same_package
  static const ContextMenuButtonKind cut = ContextMenuButtonKind._(
    'cut',
    ContextMenuButtonType.cut,
  );

  /// A button that copies the current text selection.
  static const ContextMenuButtonKind copy = ContextMenuButtonKind._(
    'copy',
    // ignore: deprecated_member_use_from_same_package
    ContextMenuButtonType.copy,
  );

  /// A button that pastes the clipboard contents into the focused text field.
  static const ContextMenuButtonKind paste = ContextMenuButtonKind._(
    'paste',
    // ignore: deprecated_member_use_from_same_package
    ContextMenuButtonType.paste,
  );

  /// A button that selects all the contents of the focused text field.
  static const ContextMenuButtonKind selectAll = ContextMenuButtonKind._(
    'selectAll',
    // ignore: deprecated_member_use_from_same_package
    ContextMenuButtonType.selectAll,
  );

  /// A button that deletes the current text selection.
  static const ContextMenuButtonKind delete = ContextMenuButtonKind._(
    'delete',
    // ignore: deprecated_member_use_from_same_package
    ContextMenuButtonType.delete,
  );

  /// A button that looks up the current text selection.
  static const ContextMenuButtonKind lookUp = ContextMenuButtonKind._(
    'lookUp',
    // ignore: deprecated_member_use_from_same_package
    ContextMenuButtonType.lookUp,
  );

  /// A button that launches a web search for the current text selection.
  static const ContextMenuButtonKind searchWeb = ContextMenuButtonKind._(
    'searchWeb',
    // ignore: deprecated_member_use_from_same_package
    ContextMenuButtonType.searchWeb,
  );

  /// A button that displays the share screen for the current text selection.
  static const ContextMenuButtonKind share = ContextMenuButtonKind._(
    'share',
    // ignore: deprecated_member_use_from_same_package
    ContextMenuButtonType.share,
  );

  /// A button for starting Live Text input.
  ///
  /// See also:
  ///  * [LiveText], where the availability of Live Text input can be obtained.
  ///  * [LiveTextInputStatusNotifier], where the status of Live Text can be listened to.
  static const ContextMenuButtonKind liveTextInput = ContextMenuButtonKind._(
    'liveTextInput',
    // ignore: deprecated_member_use_from_same_package
    ContextMenuButtonType.liveTextInput,
  );

  /// A button that launches a translation popup for the current text selection.
  ///
  /// This kind has no equivalent [ContextMenuButtonType], so
  /// [ContextMenuButtonItem.type] reports it as [ContextMenuButtonType.custom].
  static const ContextMenuButtonKind translate = ContextMenuButtonKind._(
    'translate',
    // ignore: deprecated_member_use_from_same_package
    ContextMenuButtonType.custom,
  );

  /// Anything other than the default button kinds.
  static const ContextMenuButtonKind custom = ContextMenuButtonKind._(
    'custom',
    // ignore: deprecated_member_use_from_same_package
    ContextMenuButtonType.custom,
  );

  /// All of the kinds currently known to this version of Flutter.
  ///
  /// New kinds may be added to this list in the future.
  static const List<ContextMenuButtonKind> values = <ContextMenuButtonKind>[
    cut,
    copy,
    paste,
    selectAll,
    delete,
    lookUp,
    searchWeb,
    share,
    liveTextInput,
    translate,
    custom,
  ];

  // Returns the kind that corresponds to a deprecated ContextMenuButtonType.
  // ignore: deprecated_member_use_from_same_package
  static ContextMenuButtonKind _fromLegacyType(ContextMenuButtonType type) {
    return switch (type) {
      // ignore: deprecated_member_use_from_same_package
      ContextMenuButtonType.cut => cut,
      // ignore: deprecated_member_use_from_same_package
      ContextMenuButtonType.copy => copy,
      // ignore: deprecated_member_use_from_same_package
      ContextMenuButtonType.paste => paste,
      // ignore: deprecated_member_use_from_same_package
      ContextMenuButtonType.selectAll => selectAll,
      // ignore: deprecated_member_use_from_same_package
      ContextMenuButtonType.delete => delete,
      // ignore: deprecated_member_use_from_same_package
      ContextMenuButtonType.lookUp => lookUp,
      // ignore: deprecated_member_use_from_same_package
      ContextMenuButtonType.searchWeb => searchWeb,
      // ignore: deprecated_member_use_from_same_package
      ContextMenuButtonType.share => share,
      // ignore: deprecated_member_use_from_same_package
      ContextMenuButtonType.liveTextInput => liveTextInput,
      // ignore: deprecated_member_use_from_same_package
      ContextMenuButtonType.custom => custom,
    };
  }

  @override
  String toString() => 'ContextMenuButtonKind.$name';
}

/// The kind and callback for a context menu button.
///
/// See also:
///
///  * [AdaptiveTextSelectionToolbar], which can take a list of
///    ContextMenuButtonItems and create a platform-specific context menu with
///    the indicated buttons.
///  * [IOSSystemContextMenuItem], which serves a similar role but for
///    system-drawn context menu items on iOS.
@immutable
class ContextMenuButtonItem {
  /// Creates a const instance of [ContextMenuButtonItem].
  ///
  /// At most one of [kind] and the deprecated `type` may be given. If neither
  /// is given, the button is a [ContextMenuButtonKind.custom] button.
  const ContextMenuButtonItem({
    required this.onPressed,
    @Deprecated(
      'Use kind instead. '
      'ContextMenuButtonType cannot gain new values without breaking exhaustive switches. '
      'This feature was deprecated after v3.49.0-1.0.pre.',
    )
    // ignore: deprecated_member_use_from_same_package
    ContextMenuButtonType? type,
    ContextMenuButtonKind? kind,
    this.label,
  }) : assert(type == null || kind == null, 'Only one of type and kind may be given.'),
       _type = type,
       _kind = kind;

  /// The callback to be called when the button is pressed.
  final VoidCallback? onPressed;

  // ignore: deprecated_member_use_from_same_package
  final ContextMenuButtonType? _type;
  final ContextMenuButtonKind? _kind;

  /// The kind of button this represents.
  ContextMenuButtonKind get kind {
    if (_kind != null) {
      return _kind;
    }
    if (_type != null) {
      return ContextMenuButtonKind._fromLegacyType(_type);
    }
    return ContextMenuButtonKind.custom;
  }

  /// The type of button this represents.
  ///
  /// Kinds that have no equivalent [ContextMenuButtonType], such as
  /// [ContextMenuButtonKind.translate], are reported as
  /// [ContextMenuButtonType.custom].
  @Deprecated(
    'Use kind instead. '
    'ContextMenuButtonType cannot gain new values without breaking exhaustive switches. '
    'This feature was deprecated after v3.49.0-1.0.pre.',
  )
  // ignore: deprecated_member_use_from_same_package
  ContextMenuButtonType get type => _type ?? kind._legacyType;

  /// The label to display on the button.
  ///
  /// If a [kind] other than [ContextMenuButtonKind.custom] is given
  /// and a label is not provided, then the default label for that kind for the
  /// platform will be looked up.
  final String? label;

  /// Creates a new [ContextMenuButtonItem] with the provided parameters
  /// overridden.
  ContextMenuButtonItem copyWith({
    VoidCallback? onPressed,
    @Deprecated(
      'Use kind instead. '
      'ContextMenuButtonType cannot gain new values without breaking exhaustive switches. '
      'This feature was deprecated after v3.49.0-1.0.pre.',
    )
    // ignore: deprecated_member_use_from_same_package
    ContextMenuButtonType? type,
    ContextMenuButtonKind? kind,
    String? label,
  }) {
    assert(type == null || kind == null, 'Only one of type and kind may be given.');
    return ContextMenuButtonItem(
      onPressed: onPressed ?? this.onPressed,
      kind: kind ?? (type != null ? ContextMenuButtonKind._fromLegacyType(type) : this.kind),
      label: label ?? this.label,
    );
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is ContextMenuButtonItem &&
        other.label == label &&
        other.onPressed == onPressed &&
        other.kind == kind;
  }

  @override
  int get hashCode => Object.hash(label, onPressed, kind);

  @override
  String toString() => 'ContextMenuButtonItem $kind, $label';
}
