// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

/// An abstract class representing a particular configuration of an [Action].
///
/// This class is what the [Shortcuts.shortcuts] map has as values, and is used
/// by an [ActionDispatcher] to look up an action and invoke it, giving it this
/// object to extract configuration information from.
///
/// See also:
///
///  * [Actions.invoke], which invokes the action associated with a specified
///    [Intent] using the [Actions] widget that most tightly encloses the given
///    [BuildContext].
@immutable
abstract class Intent with Diagnosticable {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const Intent();

  /// An intent that is mapped to a [DoNothingAction], which, as the name
  /// implies, does nothing.
  ///
  /// This Intent is mapped to an action in the [WidgetsApp] that does nothing,
  /// so that it can be bound to a key in a [Shortcuts] widget in order to
  /// disable a key binding made above it in the hierarchy.
  static const DoNothingIntent doNothing = DoNothingIntent._();
}

/// An [Intent], that is bound to a [DoNothingAction].
///
/// Attaching a [DoNothingIntent] to a [Shortcuts] mapping is one way to disable
/// a keyboard shortcut defined by a widget higher in the widget hierarchy and
/// consume any key event that triggers it via a shortcut.
///
/// This intent cannot be subclassed.
///
/// See also:
///
///  * [DoNothingAndStopPropagationIntent], a similar intent that will not
///    handle the key event, but will still keep it from being passed to other key
///    handlers in the focus chain.
class DoNothingIntent extends Intent {
  /// Creates a const [DoNothingIntent].
  factory DoNothingIntent() => const DoNothingIntent._();

  // Make DoNothingIntent constructor private so it can't be subclassed.
  const DoNothingIntent._();
}
