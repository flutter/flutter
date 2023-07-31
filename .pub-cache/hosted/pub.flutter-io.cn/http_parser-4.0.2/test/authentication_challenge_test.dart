// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:http_parser/http_parser.dart';
import 'package:test/test.dart';

void main() {
  group('parse', () {
    _singleChallengeTests(
        (challenge) => AuthenticationChallenge.parse(challenge));
  });

  group('parseHeader', () {
    group('with a single challenge', () {
      _singleChallengeTests((challenge) {
        final challenges = AuthenticationChallenge.parseHeader(challenge);
        expect(challenges, hasLength(1));
        return challenges.single;
      });
    });

    test('parses multiple challenges', () {
      final challenges = AuthenticationChallenge.parseHeader(
          'scheme1 realm=fblthp, scheme2 realm=asdfg');
      expect(challenges, hasLength(2));
      expect(challenges.first.scheme, equals('scheme1'));
      expect(challenges.first.parameters, equals({'realm': 'fblthp'}));
      expect(challenges.last.scheme, equals('scheme2'));
      expect(challenges.last.parameters, equals({'realm': 'asdfg'}));
    });

    test('parses multiple challenges with multiple parameters', () {
      final challenges = AuthenticationChallenge.parseHeader(
          'scheme1 realm=fblthp, foo=bar, scheme2 realm=asdfg, baz=bang');
      expect(challenges, hasLength(2));

      expect(challenges.first.scheme, equals('scheme1'));
      expect(challenges.first.parameters,
          equals({'realm': 'fblthp', 'foo': 'bar'}));

      expect(challenges.last.scheme, equals('scheme2'));
      expect(challenges.last.parameters,
          equals({'realm': 'asdfg', 'baz': 'bang'}));
    });
  });
}

/// Tests to run for parsing a single challenge.
///
/// These are run on both [AuthenticationChallenge.parse] and
/// [AuthenticationChallenge.parseHeader], since they use almost entirely
/// separate code paths.
void _singleChallengeTests(
    AuthenticationChallenge Function(String challenge) parseChallenge) {
  test('parses a simple challenge', () {
    final challenge = parseChallenge('scheme realm=fblthp');
    expect(challenge.scheme, equals('scheme'));
    expect(challenge.parameters, equals({'realm': 'fblthp'}));
  });

  test('parses multiple parameters', () {
    final challenge = parseChallenge('scheme realm=fblthp, foo=bar, baz=qux');
    expect(challenge.scheme, equals('scheme'));
    expect(challenge.parameters,
        equals({'realm': 'fblthp', 'foo': 'bar', 'baz': 'qux'}));
  });

  test('parses quoted string parameters', () {
    final challenge =
        parseChallenge('scheme realm="fblthp, foo=bar", baz="qux"');
    expect(challenge.scheme, equals('scheme'));
    expect(challenge.parameters,
        equals({'realm': 'fblthp, foo=bar', 'baz': 'qux'}));
  });

  test('normalizes the case of the scheme', () {
    final challenge = parseChallenge('ScHeMe realm=fblthp');
    expect(challenge.scheme, equals('scheme'));
    expect(challenge.parameters, equals({'realm': 'fblthp'}));
  });

  test('normalizes the case of the parameter name', () {
    final challenge = parseChallenge('scheme ReAlM=fblthp');
    expect(challenge.scheme, equals('scheme'));
    expect(challenge.parameters, containsPair('realm', 'fblthp'));
  });

  test("doesn't normalize the case of the parameter value", () {
    final challenge = parseChallenge('scheme realm=FbLtHp');
    expect(challenge.scheme, equals('scheme'));
    expect(challenge.parameters, containsPair('realm', 'FbLtHp'));
    expect(challenge.parameters, isNot(containsPair('realm', 'fblthp')));
  });

  test('allows extra whitespace', () {
    final challenge = parseChallenge(
        '  scheme\t \trealm\t = \tfblthp\t, \tfoo\t\r\n =\tbar\t');
    expect(challenge.scheme, equals('scheme'));
    expect(challenge.parameters, equals({'realm': 'fblthp', 'foo': 'bar'}));
  });

  test('allows an empty parameter', () {
    final challenge = parseChallenge('scheme realm=fblthp, , foo=bar');
    expect(challenge.scheme, equals('scheme'));
    expect(challenge.parameters, equals({'realm': 'fblthp', 'foo': 'bar'}));
  });

  test('allows a leading comma', () {
    final challenge = parseChallenge('scheme , realm=fblthp, foo=bar,');
    expect(challenge.scheme, equals('scheme'));
    expect(challenge.parameters, equals({'realm': 'fblthp', 'foo': 'bar'}));
  });

  test('allows a trailing comma', () {
    final challenge = parseChallenge('scheme realm=fblthp, foo=bar, ,');
    expect(challenge.scheme, equals('scheme'));
    expect(challenge.parameters, equals({'realm': 'fblthp', 'foo': 'bar'}));
  });

  test('disallows only a scheme', () {
    expect(() => parseChallenge('scheme'), throwsFormatException);
  });

  test('disallows a valueless parameter', () {
    expect(() => parseChallenge('scheme realm'), throwsFormatException);
    expect(() => parseChallenge('scheme realm='), throwsFormatException);
    expect(
        () => parseChallenge('scheme realm, foo=bar'), throwsFormatException);
  });

  test('requires a space after the scheme', () {
    expect(() => parseChallenge('scheme\trealm'), throwsFormatException);
    expect(() => parseChallenge('scheme\r\n\trealm='), throwsFormatException);
  });

  test('disallows junk after the parameters', () {
    expect(
        () => parseChallenge('scheme realm=fblthp foo'), throwsFormatException);
    expect(() => parseChallenge('scheme realm=fblthp, foo=bar baz'),
        throwsFormatException);
  });
}
