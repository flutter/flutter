// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'selection.dart';

/// Signature for the callback that intercepts copy operations.
typedef CopyInterceptorCallback = String Function(List<SelectedContent> selections);

/// A handler for intercepting copy operations.
///
/// Used by [SelectionArea], [SelectableRegion], and other selectable widgets
/// to intercept the copy operations of their children.
abstract class CopyInterceptor {
  /// Creates a [CopyInterceptor].
  const CopyInterceptor();

  /// Creates a [CopyInterceptor] that joins selections with the given [separator].
  const factory CopyInterceptor.separator(String separator) = _SeparatorCopyInterceptor;

  /// Creates a [CopyInterceptor] that uses the given [intercept] callback.
  const factory CopyInterceptor.inline(CopyInterceptorCallback intercept) = _InlineCopyInterceptor;

  /// A [CopyInterceptor] that joins selections with an empty string.
  static const CopyInterceptor none = CopyInterceptor.separator('');

  /// A [CopyInterceptor] that joins selections with a newline character.
  static const CopyInterceptor newline = CopyInterceptor.separator('\n');

  /// A [CopyInterceptor] that joins selections with a space character.
  static const CopyInterceptor space = CopyInterceptor.separator(' ');

  /// Convert the given [selections] to a single string.
  String intercept(List<SelectedContent> selections);
}

class _SeparatorCopyInterceptor extends CopyInterceptor {
  const _SeparatorCopyInterceptor(this.separator);

  final String separator;

  @override
  String intercept(List<SelectedContent> selections) {
    return selections.map((SelectedContent selection) => selection.plainText).join(separator);
  }
}

class _InlineCopyInterceptor extends CopyInterceptor {
  const _InlineCopyInterceptor(this._interceptInline);

  final CopyInterceptorCallback _interceptInline;

  @override
  String intercept(List<SelectedContent> selections) => _interceptInline(selections);
}
