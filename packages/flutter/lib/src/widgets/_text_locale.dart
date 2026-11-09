// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'basic.dart';
/// @docImport 'editable_text.dart';
library;

import 'dart:ui' show Locale;

import 'framework.dart';
import 'localizations.dart';

// This file is intentionally not exported from the widgets library. It shares
// the logic for picking the default text locale between [RichText] and
// [EditableText].
//
// See https://github.com/flutter/flutter/issues/194931.

/// Returns the locale that text widgets should use for rendering (font
/// fallback, shaping) when they are not given an explicit locale.
///
/// This is [Localizations.maybeLocaleOf], unless that locale is a default the
/// app did not choose ([Localizations.isDefaultLocaleOf]). In that case this
/// returns null, so the platform's default locale is used.
Locale? textLocaleOf(BuildContext context) {
  if (Localizations.isDefaultLocaleOf(context)) {
    return null;
  }
  return Localizations.maybeLocaleOf(context);
}
