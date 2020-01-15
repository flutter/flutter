// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of engine;

/// Handles clipboard related platform messages.
class ClipboardMessageHandler {
  /// Helper to handle copy to clipboard functionality.
  final CopyToClipboardStrategy _copyToClipboardStrategy =
      CopyToClipboardStrategy();

  /// Helper to handle copy to clipboard functionality.
  final PasteFromClipboardStrategy _pasteFromClipboardStrategy =
      PasteFromClipboardStrategy();

  /// Handles the platform message which stores the given text to the clipboard.
  void setDataMethodCall(MethodCall methodCall) {
    _copyToClipboardStrategy.setData(methodCall.arguments['text']);
  }

  /// Handles the platform message which retrieves text data from the clipboard.
  void getDataMethodCall(ui.PlatformMessageResponseCallback callback) {
    _pasteFromClipboardStrategy.getData().then((String data) {
      const MethodCodec codec = JSONMethodCodec();
      final Map<String, dynamic> map = {'text': data};
      callback(codec.encodeSuccessEnvelope(map));
    }).catchError(
        (error) => print('Could not get text from clipboard: $error'));
  }
}

/// Provides functionality for writing text to clipboard.
///
/// A concrete implementation is picked at runtime based on the available
/// APIs and the browser.
abstract class CopyToClipboardStrategy {
  factory CopyToClipboardStrategy() {
    return (html.window.navigator.clipboard?.writeText != null)
        ? ClipboardAPICopyStrategy()
        : ExecCommandCopyStrategy();
  }

  /// Places the text onto the browser Clipboard.
  void setData(String text);
}

/// Provides functionality for reading text from clipboard.
///
/// A concrete implementation is picked at runtime based on the available
/// APIs and the browser.
abstract class PasteFromClipboardStrategy {
  factory PasteFromClipboardStrategy() {
    return (browserEngine == BrowserEngine.firefox ||
            html.window.navigator.clipboard?.readText == null)
        ? ExecCommandPasteStrategy()
        : ClipboardAPIPasteStrategy();
  }

  /// Returns text from the system Clipboard.
  Future<String> getData();
}

/// Provides copy functionality for browsers which supports ClipboardAPI.
///
/// Works on Chrome and Firefox browsers.
/// See: https://developer.mozilla.org/en-US/docs/Web/API/Clipboard_API
class ClipboardAPICopyStrategy implements CopyToClipboardStrategy {
  @override
  void setData(String text) {
    html.window.navigator.clipboard
        .writeText(text)
        .catchError((error) => print('Could not copy text: $error'));
  }
}

/// Provides paste functionality for browsers which supports `clipboard.readText`.
///
/// Works on Chrome. Firefox only supports `readText` if the target element is
/// in content editable mode.
/// See: https://developer.mozilla.org/en-US/docs/Web/Guide/HTML/Editable_content
/// See: https://developer.mozilla.org/en-US/docs/Web/API/Clipboard_API
class ClipboardAPIPasteStrategy implements PasteFromClipboardStrategy {
  @override
  Future<String> getData() async {
    return html.window.navigator.clipboard.readText();
  }
}

/// Provides a fallback strategy for browsers which does not support ClipboardAPI.
class ExecCommandCopyStrategy implements CopyToClipboardStrategy {
  @override
  void setData(String text) {
    // Copy content to clipboard with execCommand.
    // See: https://developers.google.com/web/updates/2015/04/cut-and-copy-commands
    final html.TextAreaElement tempTextArea = _appendTemporaryTextArea();
    tempTextArea.value = text;
    tempTextArea.focus();
    tempTextArea.select();
    try {
      final bool result = html.document.execCommand('copy');
      if (!result) {
        print('copy is not successful');
      }
    } catch (e) {
      print('copy is not successful ${e.message}');
    } finally {
      _removeTemporaryTextArea(tempTextArea);
    }
  }

  html.TextAreaElement _appendTemporaryTextArea() {
    final html.TextAreaElement tempElement = html.TextAreaElement();
    final html.CssStyleDeclaration elementStyle = tempElement.style;
    elementStyle
      ..position = 'absolute'
      ..top = '-99999px'
      ..left = '-99999px'
      ..opacity = '0'
      ..color = 'transparent'
      ..backgroundColor = 'transparent'
      ..background = 'transparent';

    html.document.body.append(tempElement);

    return tempElement;
  }

  void _removeTemporaryTextArea(html.HtmlElement element) {
    element?.remove();
  }
}

/// Provides a fallback strategy for browsers which does not support ClipboardAPI.
class ExecCommandPasteStrategy implements PasteFromClipboardStrategy {
  @override
  Future<String> getData() {
    // TODO(nurhan): https://github.com/flutter/flutter/issues/48581
    // TODO(nurhan): https://github.com/flutter/flutter/issues/48580
    print('Paste is not implemented for this browser.');
    throw UnimplementedError();
  }
}
