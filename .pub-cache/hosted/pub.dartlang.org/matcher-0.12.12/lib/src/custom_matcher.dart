// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:stack_trace/stack_trace.dart';

import 'description.dart';
import 'interfaces.dart';
import 'util.dart';

/// A useful utility class for implementing other matchers through inheritance.
/// Derived classes should call the base constructor with a feature name and
/// description, and an instance matcher, and should implement the
/// [featureValueOf] abstract method.
///
/// The feature description will typically describe the item and the feature,
/// while the feature name will just name the feature. For example, we may
/// have a Widget class where each Widget has a price; we could make a
/// [CustomMatcher] that can make assertions about prices with:
///
/// ```dart
/// class HasPrice extends CustomMatcher {
///   HasPrice(matcher) : super("Widget with price that is", "price", matcher);
///   featureValueOf(actual) => (actual as Widget).price;
/// }
/// ```
///
/// and then use this for example like:
///
/// ```dart
/// expect(inventoryItem, HasPrice(greaterThan(0)));
/// ```
class CustomMatcher extends Matcher {
  final String _featureDescription;
  final String _featureName;
  final Matcher _matcher;

  CustomMatcher(
      this._featureDescription, this._featureName, Object? valueOrMatcher)
      : _matcher = wrapMatcher(valueOrMatcher);

  /// Override this to extract the interesting feature.
  Object? featureValueOf(dynamic actual) => actual;

  @override
  bool matches(Object? item, Map matchState) {
    try {
      var f = featureValueOf(item);
      if (_matcher.matches(f, matchState)) return true;
      addStateInfo(matchState, {'custom.feature': f});
    } catch (exception, stack) {
      addStateInfo(matchState, {
        'custom.exception': exception.toString(),
        'custom.stack': Chain.forTrace(stack)
            .foldFrames(
                (frame) =>
                    frame.package == 'test' ||
                    frame.package == 'stream_channel' ||
                    frame.package == 'matcher',
                terse: true)
            .toString()
      });
    }
    return false;
  }

  @override
  Description describe(Description description) =>
      description.add(_featureDescription).add(' ').addDescriptionOf(_matcher);

  @override
  Description describeMismatch(Object? item, Description mismatchDescription,
      Map matchState, bool verbose) {
    if (matchState['custom.exception'] != null) {
      mismatchDescription
          .add('threw ')
          .addDescriptionOf(matchState['custom.exception'])
          .add('\n')
          .add(matchState['custom.stack'].toString());
      return mismatchDescription;
    }

    mismatchDescription
        .add('has ')
        .add(_featureName)
        .add(' with value ')
        .addDescriptionOf(matchState['custom.feature']);
    var innerDescription = StringDescription();

    _matcher.describeMismatch(matchState['custom.feature'], innerDescription,
        matchState['state'] as Map, verbose);

    if (innerDescription.length > 0) {
      mismatchDescription.add(' which ').add(innerDescription.toString());
    }
    return mismatchDescription;
  }
}
