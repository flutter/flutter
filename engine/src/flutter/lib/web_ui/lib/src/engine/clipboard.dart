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

  /// Helper to handle copy to clipboard functionality.
  CopyToClipboardStrategy _copyToClipboardStrategy = CopyToClipboardStrategy();

  /// Helper to handle copy to clipboard functionality.
  PasteFromClipboardStrategy _pasteFromClipboardStrategy = PasteFromClipboardStrategy();

  /// Handles the platform message which copies the given text to the clipboard.
  void setDataMethodCall(ui.PlatformMessageResponseCallback? callback, String? text) {
    const MethodCodec codec = JSONMethodCodec();
    _copyToClipboardStrategy
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

    _pasteFromClipboardStrategy
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
    _pasteFromClipboardStrategy
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

  /// Overrides the default paste from clipboard strategy.
  @visibleForTesting
  set pasteFromClipboardStrategy(PasteFromClipboardStrategy strategy) {
    _pasteFromClipboardStrategy = strategy;
  }

  /// Overrides the default copy to clipboard strategy.
  @visibleForTesting
  set copyToClipboardStrategy(CopyToClipboardStrategy strategy) {
    _copyToClipboardStrategy = strategy;
  }
}

/// Provides functionality for writing text to clipboard.
abstract class CopyToClipboardStrategy {
  factory CopyToClipboardStrategy() {
    return ClipboardAPICopyStrategy();
  }

  /// Places the text onto the browser clipboard.
  Future<void> setData(String? text);
}

/// Provides functionality for reading text from clipboard.
abstract class PasteFromClipboardStrategy {
  factory PasteFromClipboardStrategy() {
    return ClipboardAPIPasteStrategy();
  }

  /// Returns text from the browser clipboard.
  Future<String> getData();
}

/// Provides functionality for writing text to clipboard using Clipboard API.
///
/// See: https://developer.mozilla.org/en-US/docs/Web/API/Clipboard_API
class ClipboardAPICopyStrategy implements CopyToClipboardStrategy {
  @override
  Future<void> setData(String? text) async {
    final clipboard = domWindow.navigator.clipboard;

    if (clipboard == null) {
      // This can happen when the browser is outdated or the context is not
      // secure.
      // See: https://developer.mozilla.org/en-US/docs/Web/API/Clipboard
      // See: https://developer.mozilla.org/en-US/docs/Web/Security/Secure_Contexts
      throw StateError('Clipboard is not available in the context.');
    }

    await clipboard.writeText(text!);
  }
}

/// Provides functionality for reading text from clipboard using Clipboard API.
///
/// See: https://developer.mozilla.org/en-US/docs/Web/API/Clipboard_API
class ClipboardAPIPasteStrategy implements PasteFromClipboardStrategy {
  @override
  Future<String> getData() async {
    final clipboard = domWindow.navigator.clipboard;

    if (clipboard == null) {
      // This can happen when the browser is outdated or the context is not
      // secure.
      // See: https://developer.mozilla.org/en-US/docs/Web/API/Clipboard
      // See: https://developer.mozilla.org/en-US/docs/Web/Security/Secure_Contexts
      throw StateError('Clipboard is not available in the context.');
    }

    return clipboard.readText();
  }
}
