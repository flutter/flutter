// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/cupertino.dart';
/// @docImport 'package:flutter/material.dart';
/// @docImport 'package:flutter/rendering.dart';
///
/// @docImport 'live_text.dart';
/// @docImport 'scribe.dart';
/// @docImport 'text_formatter.dart';
library;

import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui' show FlutterView, FontWeight, Locale, Offset, Rect, Size, TextAlign, TextDirection;

import 'package:flutter/foundation.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4;

import 'autofill.dart';
import 'binding.dart';
import 'clipboard.dart' show Clipboard;
import 'content_insertion_channel.dart';
import 'keyboard_inserted_content.dart';
import 'message_codec.dart';
import 'platform_channel.dart';
import 'system_channels.dart';
import 'text_editing.dart';
import 'text_editing_delta.dart';

export 'dart:ui'
    show
        Brightness,
        FontWeight,
        Offset,
        Rect,
        Size,
        TextAlign,
        TextDirection,
        TextPosition,
        TextRange;

export 'package:vector_math/vector_math_64.dart' show Matrix4;

export 'autofill.dart' show AutofillConfiguration, AutofillScope;
export 'text_editing.dart' show TextSelection;

// TODO(a14n): the following export leads to Segmentation fault, see https://github.com/flutter/flutter/issues/106332
// export 'text_editing_delta.dart' show TextEditingDelta;
