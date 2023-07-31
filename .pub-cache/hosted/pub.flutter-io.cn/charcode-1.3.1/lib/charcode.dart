// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Defines symbolic names for character code points.
///
/// Includes all ASCII and Latin-1 characters.
///
/// Exports the libraries `ascii.dart` and `html_entity.dart`.
///
/// Hides the characters `$minus`, `$sub` and `$tilde` from
/// `html_entities.dart`, since other characters have the same name in
/// `ascii.dart`.
library charcode;

export "ascii.dart";
export "html_entity.dart" hide $minus, $tilde, $sub;
