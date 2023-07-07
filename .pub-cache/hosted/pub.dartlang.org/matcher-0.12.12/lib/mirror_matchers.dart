// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Deprecated('Check properties on known types')
library mirror_matchers;

/// The mirror matchers library provides some additional matchers that
/// make use of `dart:mirrors`.
import 'dart:mirrors';

import 'matcher.dart';

/// Returns a matcher that checks if a class instance has a property
/// with name [name], and optionally, if that property in turn satisfies
/// a [matcher].
Matcher hasProperty(String name, [Object? matcher]) =>
    _HasProperty(name, matcher == null ? null : wrapMatcher(matcher));

class _HasProperty extends Matcher {
  final String _name;
  final Matcher? _matcher;

  const _HasProperty(this._name, [this._matcher]);

  @override
  bool matches(Object? item, Map matchState) {
    var mirror = reflect(item);
    var classMirror = mirror.type;
    var symbol = Symbol(_name);
    var candidate = classMirror.declarations[symbol];
    if (candidate == null) {
      addStateInfo(matchState, {'reason': 'has no property named "$_name"'});
      return false;
    }
    var isInstanceField = candidate is VariableMirror && !candidate.isStatic;
    var isInstanceGetter =
        candidate is MethodMirror && candidate.isGetter && !candidate.isStatic;
    if (!(isInstanceField || isInstanceGetter)) {
      addStateInfo(matchState, {
        'reason':
            'has a member named "$_name", but it is not an instance property'
      });
      return false;
    }
    var matcher = _matcher;
    if (matcher == null) return true;
    var result = mirror.getField(symbol);
    var resultMatches = matcher.matches(result.reflectee, matchState);
    if (!resultMatches) {
      addStateInfo(matchState, {'value': result.reflectee});
    }
    return resultMatches;
  }

  @override
  Description describe(Description description) {
    description.add('has property "$_name"');
    if (_matcher != null) {
      description.add(' which matches ').addDescriptionOf(_matcher);
    }
    return description;
  }

  @override
  Description describeMismatch(Object? item, Description mismatchDescription,
      Map matchState, bool verbose) {
    var reason = matchState['reason'];
    if (reason != null) {
      mismatchDescription.add(reason as String);
    } else {
      mismatchDescription
          .add('has property "$_name" with value ')
          .addDescriptionOf(matchState['value']);
      var innerDescription = StringDescription();
      matchState['state'] ??= {};
      _matcher?.describeMismatch(matchState['value'], innerDescription,
          matchState['state'] as Map, verbose);
      if (innerDescription.length > 0) {
        mismatchDescription.add(' which ').add(innerDescription.toString());
      }
    }
    return mismatchDescription;
  }
}
