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
/// Deprecated in favor of [ContextMenuButtonKind].
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
/// New kinds may be added in the future, so switches on this class should
/// include a wildcard (`_`) case.
///
/// See also:
///
///  * [ContextMenuButtonItem], which uses this class to describe a button in a
///    context menu.
@immutable
final class ContextMenuButtonKind {
  const ContextMenuButtonKind._(this.name, this._legacyType);

  /// A name for this kind, useful for debugging.
  final String name;

  // The closest ContextMenuButtonType for this kind, used to keep the
  // deprecated ContextMenuButtonItem.type working. Kinds with no matching
  // ContextMenuButtonType map to ContextMenuButtonType.custom.
  final ContextMenuButtonType _legacyType;

  /// A button that cuts the current text selection.
  static const ContextMenuButtonKind cut = ContextMenuButtonKind._(
    'cut',
    ContextMenuButtonType.cut,
  );

  /// A button that copies the current text selection.
  static const ContextMenuButtonKind copy = ContextMenuButtonKind._(
    'copy',
    ContextMenuButtonType.copy,
  );

  /// A button that pastes the clipboard contents into the focused text field.
  static const ContextMenuButtonKind paste = ContextMenuButtonKind._(
    'paste',
    ContextMenuButtonType.paste,
  );

  /// A button that selects all the contents of the focused text field.
  static const ContextMenuButtonKind selectAll = ContextMenuButtonKind._(
    'selectAll',
    ContextMenuButtonType.selectAll,
  );

  /// A button that deletes the current text selection.
  static const ContextMenuButtonKind delete = ContextMenuButtonKind._(
    'delete',
    ContextMenuButtonType.delete,
  );

  /// A button that looks up the current text selection.
  static const ContextMenuButtonKind lookUp = ContextMenuButtonKind._(
    'lookUp',
    ContextMenuButtonType.lookUp,
  );

  /// A button that launches a web search for the current text selection.
  static const ContextMenuButtonKind searchWeb = ContextMenuButtonKind._(
    'searchWeb',
    ContextMenuButtonType.searchWeb,
  );

  /// A button that displays the share screen for the current text selection.
  static const ContextMenuButtonKind share = ContextMenuButtonKind._(
    'share',
    ContextMenuButtonType.share,
  );

  /// A button for starting Live Text input.
  ///
  /// See also:
  ///  * [LiveText], where the availability of Live Text input can be obtained.
  ///  * [LiveTextInputStatusNotifier], where the status of Live Text can be listened to.
  static const ContextMenuButtonKind liveTextInput = ContextMenuButtonKind._(
    'liveTextInput',
    ContextMenuButtonType.liveTextInput,
  );

  /// A button that launches a translation popup for the current text selection.
  static const ContextMenuButtonKind translate = ContextMenuButtonKind._(
    'translate',
    ContextMenuButtonType.custom,
  );

  /// Anything other than the default button kinds.
  static const ContextMenuButtonKind custom = ContextMenuButtonKind._(
    'custom',
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
  static ContextMenuButtonKind _fromLegacyType(ContextMenuButtonType type) {
    return switch (type) {
      ContextMenuButtonType.cut => cut,
      ContextMenuButtonType.copy => copy,
      ContextMenuButtonType.paste => paste,
      ContextMenuButtonType.selectAll => selectAll,
      ContextMenuButtonType.delete => delete,
      ContextMenuButtonType.lookUp => lookUp,
      ContextMenuButtonType.searchWeb => searchWeb,
      ContextMenuButtonType.share => share,
      ContextMenuButtonType.liveTextInput => liveTextInput,
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
    ContextMenuButtonType? type,
    ContextMenuButtonKind? kind,
    this.label,
  }) : assert(type == null || kind == null, 'Only one of type and kind may be given.'),
       _type = type,
       _kind = kind;

  /// The callback to be called when the button is pressed.
  final VoidCallback? onPressed;

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
