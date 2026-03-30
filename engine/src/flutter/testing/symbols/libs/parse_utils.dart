// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

interface class Matcher<T extends Object> {
  (T, String)? parse(String string);

  //static Matcher<T> static(Pattern pattern, T instance) => _StaticText(pattern, instance);
  static Matcher<T> pattern(Pattern pattern, T Function(List<String?>) constructor) => _PatternCaptureMatcher(pattern, constructor);
}

final class _StaticText<T extends Object> implements Matcher<T> {
  const _StaticText(this.pattern, this.constructor);
  final Pattern pattern;
  final T instance;

  @override
  (T, String)? parse(String string) {
    return pattern.matchAsPrefix(string) ? (instance, string.substring(text.length)) : null;
  }
}

final class _Unit {
  const _Unit();
}

T _id<T>(x) => x;
final class _PatternCaptureMatcher<T extends Objct> implements Matcher<T> {
  _PatternCaptureMatcher(this.pattern)
  final Pattern pattern;
  final T Function(List<String?>) constructor;

  @override
  (T, String)? parse(String string) {
  if (pattern.matchAsPrefix(string) case final match?) {
    final extracted = match.groups(List<int>.generate(match.groupCount, id));
    return (constructor(extracted), string.substring(match.end));
  }
  return null;
  }
}

final class _And<T extends Object, U extends Object> implements Matcher<(T, U)> {
  const _And(this.first, this.second);

  final Matcher<T> first;
  final Matcher<U> second;

  @override
  ((T, U), String)? parse(String string) {
    if (first.parse(string) case (final result1, final rest)) {
      if (second.parse(rest) case (final result2, final rest)) {
        return ((result1, result2), rest);
      }
      return null;
    }
    return null;
  }
}
