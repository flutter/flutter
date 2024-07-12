// Copyright 2018 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

/// A minimal, dependency-free emulation layer for a subset of the
/// unittest/test API used by the language and core library.
///
/// Compared with `minitest.dart`, this library supports and expects
/// asynchronous tests. It uses a `Zone` per test to associate a test name with
/// the failure.
///
/// It does not support `setUp` or `tearDown` methods,
/// and matchers are severely restricted.
///
/// A number of our language and core library tests were written against the
/// unittest package, which is now deprecated in favor of the new test package.
/// The latter is much better feature-wise, but is also quite complex and has
/// many dependencies. For low-level language and core library tests, we don't
/// want to have to pull in a large number of dependencies and be able to run
/// them correctly in order to run a test, so we want to test them against
/// something simpler.
///
/// When possible, we just use the tiny expect library. But to avoid rewriting
/// all of the existing tests that use unittest, they can instead use this,
/// which shims the unittest API with as little code as possible and calls into
/// expect.
///
/// Eventually, it would be good to refactor those tests to use the expect
/// package directly and remove this.
library;

import 'dart:async';

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

void group(String name, void Function() body) {
  final oldName = _pushName(name);
  try {
    body();
  } finally {
    _popName(oldName);
  }
}

void test(String name, dynamic Function() body) {
  final oldName = _pushName(name);

  asyncStart();
  final result = runZoned(body, zoneValues: {_testToken: _currentName});
  if (result is Future<dynamic>) {
    result.then((_) {
      asyncEnd();
    });
  } else {
    // Ensure all tests get to be set up first.
    scheduleMicrotask(asyncEnd);
  }

  _popName(oldName);
}

void expect(dynamic value, dynamic matcher, {String reason = ''}) {
  Matcher m;
  if (matcher is _Matcher) {
    m = matcher.call;
  } else if (matcher is! Matcher) {
    m = equals(matcher);
  } else {
    m = matcher;
  }
  m(value);
}

R Function() expectAsync0<R>(R Function() f, {int count = 1}) {
  asyncStart(count);
  return () {
    final result = f();
    asyncEnd();
    return result;
  };
}

R Function(A) expectAsync1<R, A>(R Function(A) f, {int count = 1}) {
  asyncStart(count);
  return (A a) {
    final result = f(a);
    asyncEnd();
    return result;
  };
}

R Function(A, B) expectAsync2<R, A, B>(R Function(A, B) f, {int count = 1}) {
  asyncStart(count);
  return (A a, B b) {
    final result = f(a, b);
    asyncEnd();
    return result;
  };
}

dynamic expectAsync(Function f, {int count = 1}) {
  final f2 = f; // Avoid type-promoting f, we want dynamic invocations.
  if (f2 is void Function(Never, Never, Never, Never, Never)) {
    asyncStart(count);
    return ([Object? a, Object? b, Object? c, Object? d, Object? e]) {
      final result = f(a, b, c, d, e); // ignore: avoid_dynamic_calls
      asyncEnd();
      return result;
    };
  }
  if (f2 is void Function(Never, Never, Never, Never)) {
    asyncStart(count);
    return ([Object? a, Object? b, Object? c, Object? d]) {
      final result = f(a, b, c, d); // ignore: avoid_dynamic_calls
      asyncEnd();
      return result;
    };
  }
  if (f2 is void Function(Never, Never, Never)) {
    asyncStart(count);
    return ([Object? a, Object? b, Object? c]) {
      final result = f(a, b, c); // ignore: avoid_dynamic_calls
      asyncEnd();
      return result;
    };
  }
  if (f2 is void Function(Never, Never)) {
    asyncStart(count);
    return ([Object? a, Object? b]) {
      final result = f(a, b); // ignore: avoid_dynamic_calls
      asyncEnd();
      return result;
    };
  }
  if (f2 is void Function(Never)) {
    asyncStart(count);
    return ([Object? a]) {
      final result = f(a); // ignore: avoid_dynamic_calls
      asyncEnd();
      return result;
    };
  }
  if (f2 is void Function()) {
    asyncStart(count);
    return () {
      final result = f2();
      asyncEnd();
      return result;
    };
  }
  throw UnsupportedError(
      'expectAsync only accepts up to five argument functions');
}

// Matchers
typedef Matcher = void Function(dynamic);

Matcher same(dynamic o) => (v) {
      Expect.identical(o, v);
    };

Matcher equals(dynamic o) => (v) {
      Expect.deepEquals(o, v);
    };

Matcher greaterThan(num n) => (dynamic v) {
      Expect.type<num>(v);
      final num value = v as num;
      if (value > n) {
        return;
      }
      Expect.fail('$v is not greater than $n');
    };

Matcher greaterThanOrEqualTo(num n) => (dynamic v) {
      Expect.type<num>(v);
      final num value = v as num;
      if (value >= n) {
        return;
      }
      Expect.fail('$v is not greater than $n');
    };

Matcher lessThan(num n) => (dynamic v) {
      Expect.type<num>(v);
      final num value = v as num;
      if (value < n) {
        return;
      }
      Expect.fail('$v is not less than $n');
    };

Matcher lessThanOrEqualTo(num n) => (dynamic v) {
      Expect.type<num>(v);
      final num value = v as num;
      if (value <= n) {
        return;
      }
      Expect.fail('$v is not less than $n');
    };

Matcher predicate(bool Function(dynamic value) fn, [String description = '']) =>
    (dynamic v) {
      Expect.isTrue(fn(v), description);
    };

Matcher anyOf(List<String> expected) => (dynamic actual) {
      for (final string in expected) {
        if (actual == string) {
          return;
        }
      }

      Expect.fail('Expected $actual to be one of $expected.');
    };

void isTrue(dynamic v) {
  Expect.isTrue(v);
}

void isFalse(dynamic v) {
  Expect.isFalse(v);
}

void isNull(dynamic o) {
  Expect.isNull(o);
}

void _checkThrow<T extends Object>(
    dynamic v, void Function(dynamic error) onError) {
  if (v is Future) {
    asyncStart();
    v.then((_) {
      Expect.fail('Did not throw');
    }, onError: (Object e, s) {
      if (e is! T) {
        throw e;
      }
      onError(e);
      asyncEnd();
    });
    return;
  }
  Expect.throws<T>(v as void Function(), (dynamic e) {
    onError(e);
    return true;
  });
}

void returnsNormally(dynamic o) {
  try {
    Expect.type<void Function()>(o);
    (o as void Function())();
  } catch (error, trace) {
    Expect.fail(
        'Expected function to return normally, but threw:\n$error\n\n$trace');
  }
}

void throws(dynamic v) {
  _checkThrow<Object>(v, (_) {});
}

Matcher throwsA(dynamic matcher) => (dynamic o) {
      _checkThrow<Object>(o, (error) {
        expect(error, matcher);
      });
    };

Matcher completion(dynamic matcher) => (dynamic o) {
      Expect.type<Future<dynamic>>(o);
      final Future<dynamic> future = o as Future<dynamic>;
      asyncStart();
      future.then((value) {
        expect(value, matcher);
        asyncEnd();
      });
    };

void completes(dynamic o) {
  Expect.type<Future<dynamic>>(o);
  final Future<dynamic> future = o as Future<dynamic>;
  asyncStart();
  future.then<void>(asyncSuccess);
}

void isMap(dynamic o) {
  Expect.type<Map<dynamic, dynamic>>(o);
}

void isList(dynamic o) {
  Expect.type<List<dynamic>>(o);
}

void isNotNull(dynamic o) {
  Expect.isNotNull(o);
}

abstract class _Matcher {
  void call(dynamic o);
}

// ignore: camel_case_types
class isInstanceOf<T> implements _Matcher {
  @override
  void call(dynamic o) {
    Expect.type<T>(o);
  }
}

void throwsArgumentError(dynamic v) {
  _checkThrow<ArgumentError>(v, (_) {});
}

void throwsStateError(dynamic v) {
  _checkThrow<StateError>(v, (_) {});
}

void fail(String message) {
  Expect.fail(message);
}

/// Key for zone value holding current test name.
final _testToken = Object();

bool _initializedTestNameCallback = false;

/// The current combined name of the nesting [group] or [test].
String _currentName = '';

String _pushName(String newName) {
  // Look up the current test name from the zone created for the test.
  if (!_initializedTestNameCallback) {
    ExpectException.setTestNameCallback(
        () => Zone.current[_testToken] as String);
    _initializedTestNameCallback = true;
  }

  final oldName = _currentName;
  if (oldName == '') {
    _currentName = newName;
  } else {
    _currentName = '$oldName $newName';
  }
  return oldName;
}

void _popName(String oldName) {
  _currentName = oldName;
}
