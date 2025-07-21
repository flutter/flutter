// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:ui/ui.dart' as ui;

import 'dom.dart';
import 'services.dart';

/// Handles clipboard related platform messages.
class ClipboardMessageHandler {
  /// Clipboard plain text format.
  @visibleForTesting
  static const String kTextPlainFormat = 'text/plain';

  /// Helper to handle clipboard functionality.
  ClipboardStrategy _clipboardStrategy = ClipboardStrategy();

  /// Handles the platform message which copies the given text to the clipboard.
  void setDataMethodCall(ui.PlatformMessageResponseCallback? callback, String? text) {
    const MethodCodec codec = JSONMethodCodec();
    _clipboardStrategy
        .setData(text)
        .then((_) => callback!(codec.encodeSuccessEnvelope(null)))
        .catchError((Object error) {
          final message = (error is StateError) ? error.message : 'Clipboard.setData failed.';
          callback!(codec.encodeErrorEnvelope(code: 'copy_fail', message: message));
        });
  }

  /// Handles the platform message which pastes text data from the clipboard.
  void getDataMethodCall(ui.PlatformMessageResponseCallback? callback, String? format) {
    const MethodCodec codec = JSONMethodCodec();

    if (format != null && format != kTextPlainFormat) {
      callback!(codec.encodeSuccessEnvelope(null));
      return;
    }

    _clipboardStrategy
        .getData()
        .then((String data) {
          final Map<String, Object?> map = <String, Object?>{'text': data};
          callback!(codec.encodeSuccessEnvelope(map));
        })
        .catchError((Object error) {
          final message = (error is StateError) ? error.message : 'Clipboard.getData failed.';
          callback!(codec.encodeErrorEnvelope(code: 'paste_fail', message: message));
        });
  }

  /// Handles the platform message which asks if the clipboard contains
  /// pasteable strings.
  void hasStringsMethodCall(ui.PlatformMessageResponseCallback? callback) {
    const MethodCodec codec = JSONMethodCodec();
    _clipboardStrategy
        .getData()
        .then((String data) {
          final Map<String, Object?> map = <String, Object?>{'value': data.isNotEmpty};
          callback!(codec.encodeSuccessEnvelope(map));
        })
        .catchError((Object error) {
          final message = (error is StateError) ? error.message : 'Clipboard.hasStrings failed.';
          callback!(codec.encodeErrorEnvelope(code: 'has_strings_fail', message: message));
        });
  }

  /// Overrides the default clipboard strategy.
  @visibleForTesting
  set clipboardStrategy(ClipboardStrategy strategy) {
    _clipboardStrategy = strategy;
  }
}

/// Provides functionality for writing and reading text from the clipboard
/// using the Clipboard API.
///
/// See: https://developer.mozilla.org/en-US/docs/Web/API/Clipboard_API
class ClipboardStrategy {
  DomClipboard get _clipboard {
    final DomClipboard? clipboard = domWindow.navigator.clipboard;

    if (clipboard == null) {
      // This can happen when the browser is outdated or the context is not
      // secure.
      // See: https://developer.mozilla.org/en-US/docs/Web/API/Clipboard
      // See: https://developer.mozilla.org/en-US/docs/Web/Security/Secure_Contexts
      throw StateError('Clipboard is not available in the context.');
    }

    return clipboard;
  }

  /// Places the text onto the browser clipboard.
  Future<void> setData(String? text) async {
    await _clipboard.writeText(text!);
  }

  /// Returns text from the browser clipboard.
  Future<String> getData() async {
    return _clipboard.readText();
  }
}
