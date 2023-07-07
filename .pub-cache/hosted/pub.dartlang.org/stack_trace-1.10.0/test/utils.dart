// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

/// Returns a matcher that runs [matcher] against a [Frame]'s `member` field.
Matcher frameMember(matcher) =>
    transform((frame) => frame.member, matcher, 'member');

/// Returns a matcher that runs [matcher] against a [Frame]'s `library` field.
Matcher frameLibrary(matcher) =>
    transform((frame) => frame.library, matcher, 'library');

/// Returns a matcher that runs [transformation] on its input, then matches
/// the output against [matcher].
///
/// [description] should be a noun phrase that describes the relation of the
/// output of [transformation] to its input.
Matcher transform(
        void Function(dynamic) transformation, matcher, String description) =>
    _TransformMatcher(transformation, wrapMatcher(matcher), description);

class _TransformMatcher extends Matcher {
  final Function _transformation;
  final Matcher _matcher;
  final String _description;

  _TransformMatcher(this._transformation, this._matcher, this._description);

  @override
  bool matches(item, Map matchState) =>
      _matcher.matches(_transformation(item), matchState);

  @override
  Description describe(Description description) =>
      description.add(_description).add(' ').addDescriptionOf(_matcher);
}
