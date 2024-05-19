// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'selection.dart';

/// Signature for the callback that intercepts copy operations.
typedef CopyInterceptorCallback = String Function(List<SelectedContent> selections);

/// A handler for intercepting copy operations.
///
/// Used by [SelectionArea], [SelectableRegion], and other selectable widgets
/// to intercept the copy operations of their children.
abstract class CopyIntercept {
  /// Creates a [CopyIntercept].
  const CopyIntercept();

  /// Creates a [CopyIntercept] that joins selections with the given [separator].
  const factory CopyIntercept.separator(String separator) = _SeparatorCopyInterceptor;

  /// Creates a [CopyIntercept] that uses the given [intercept] callback.
  const factory CopyIntercept.inline(CopyInterceptorCallback intercept) = _InlineCopyInterceptor;

  /// A [CopyIntercept] that joins selections with an empty string.
  static const CopyIntercept none = CopyIntercept.separator('');

  /// A [CopyIntercept] that joins selections with a newline character.
  static const CopyIntercept newline = CopyIntercept.separator('\n');

  /// A [CopyIntercept] that joins selections with a space character.
  static const CopyIntercept space = CopyIntercept.separator(' ');

  /// Convert the given [selections] to a single string.
  String intercept(List<SelectedContent> selections);
}

class _SeparatorCopyInterceptor extends CopyIntercept {
  const _SeparatorCopyInterceptor(this.separator);

  final String separator;

  @override
  String intercept(List<SelectedContent> selections) {
    return selections.map((SelectedContent selection) => selection.plainText).join(separator);
  }
}

class _InlineCopyInterceptor extends CopyIntercept {
  const _InlineCopyInterceptor(this._interceptInline);

  final CopyInterceptorCallback _interceptInline;

  @override
  String intercept(List<SelectedContent> selections) => _interceptInline(selections);
}

class CopyInterceptor extends StatelessWidget {
  const CopyInterceptor({
    super.key,
    required this.intercept,
    required this.child,
  });

  static CopyInterceptor? maybeOf(BuildContext context) {
    return context.findAncestorWidgetOfExactType<CopyInterceptor>();
  }

  final CopyIntercept intercept;
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
