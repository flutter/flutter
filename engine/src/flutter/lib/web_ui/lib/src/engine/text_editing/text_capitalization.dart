// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.10
part of engine;

/// Controls the capitalization of the text.
///
/// This corresponds to Flutter's [TextCapitalization].
///
/// Uses `text-transform` css property.
/// See: https://developer.mozilla.org/en-US/docs/Web/CSS/text-transform
enum TextCapitalization {
  /// Uppercase for the first letter of each word.
  words,

  /// Currently not implemented on Flutter Web. Uppercase for the first letter
  /// of each sentence.
  sentences,

  /// Uppercase for each letter.
  characters,

  /// Lowercase for each letter.
  none,
}

/// Helper class for text capitalization.
///
/// Uses `autocapitalize` attribute on input element.
/// See: https://developers.google.com/web/updates/2015/04/autocapitalize
/// https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes/autocapitalize
class TextCapitalizationConfig {
  final TextCapitalization textCapitalization;

  const TextCapitalizationConfig.defaultCapitalization()
      : textCapitalization = TextCapitalization.none;

  TextCapitalizationConfig.fromInputConfiguration(String inputConfiguration)
      : this.textCapitalization =
            inputConfiguration == 'TextCapitalization.words'
                ? TextCapitalization.words
                : inputConfiguration == 'TextCapitalization.characters'
                    ? TextCapitalization.characters
                    : inputConfiguration == 'TextCapitalization.sentences'
                        ? TextCapitalization.sentences
                        : TextCapitalization.none;

  /// Sets `autocapitalize` attribute on input elements.
  ///
  /// This attribute is only available for mobile browsers.
  ///
  /// Note that in mobile browsers the onscreen keyboards provide sentence
  /// level capitalization as default as apposed to no capitalization on desktop
  /// browser.
  ///
  /// See: https://developers.google.com/web/updates/2015/04/autocapitalize
  /// https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes/autocapitalize
  void setAutocapitalizeAttribute(html.HtmlElement domElement) {
    String autocapitalize = '';
    switch (textCapitalization) {
      case TextCapitalization.words:
        // TODO: There is a bug for `words` level capitalization in IOS now.
        // For now go back to default. Remove the check after bug is resolved.
        // https://bugs.webkit.org/show_bug.cgi?id=148504
        if (browserEngine == BrowserEngine.webkit) {
          autocapitalize = 'sentences';
        } else {
          autocapitalize = 'words';
        }
        break;
      case TextCapitalization.characters:
        autocapitalize = 'characters';
        break;
      case TextCapitalization.sentences:
        autocapitalize = 'sentences';
        break;
      case TextCapitalization.none:
      default:
        autocapitalize = 'off';
        break;
    }
    if (domElement is html.InputElement) {
      html.InputElement element = domElement;
      element.setAttribute('autocapitalize', autocapitalize);
    } else if (domElement is html.TextAreaElement) {
      html.TextAreaElement element = domElement;
      element.setAttribute('autocapitalize', autocapitalize);
    }
  }
}
