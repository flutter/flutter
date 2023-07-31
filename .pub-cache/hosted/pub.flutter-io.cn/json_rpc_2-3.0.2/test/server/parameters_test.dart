// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  group('with named parameters', () {
    late json_rpc.Parameters parameters;
    setUp(() {
      parameters = json_rpc.Parameters('foo', {
        'num': 1.5,
        'int': 1,
        'bool': true,
        'string': 'zap',
        'list': [1, 2, 3],
        'date-time': '1990-01-01 00:00:00.000',
        'uri': 'https://dart.dev',
        'invalid-uri': 'http://[::1',
        'map': {'num': 4.2, 'bool': false}
      });
    });

    test('value returns the wrapped value', () {
      expect(
          parameters.value,
          equals({
            'num': 1.5,
            'int': 1,
            'bool': true,
            'string': 'zap',
            'list': [1, 2, 3],
            'date-time': '1990-01-01 00:00:00.000',
            'uri': 'https://dart.dev',
            'invalid-uri': 'http://[::1',
            'map': {'num': 4.2, 'bool': false}
          }));
    });

    test('[int] throws a parameter error', () {
      expect(
          () => parameters[0],
          throwsInvalidParams('Parameters for method "foo" must be passed by '
              'position.'));
    });

    test('[].value returns existing parameters', () {
      expect(parameters['num'].value, equals(1.5));
    });

    test('[].valueOr returns existing parameters', () {
      expect(parameters['num'].valueOr(7), equals(1.5));
    });

    test('[].value fails for absent parameters', () {
      expect(
          () => parameters['fblthp'].value,
          throwsInvalidParams('Request for method "foo" is missing required '
              'parameter "fblthp".'));
    });

    test('[].valueOr succeeds for absent parameters', () {
      expect(parameters['fblthp'].valueOr(7), equals(7));
    });

    test('[].exists returns true for existing parameters', () {
      expect(parameters['num'].exists, isTrue);
    });

    test('[].exists returns false for missing parameters', () {
      expect(parameters['fblthp'].exists, isFalse);
    });

    test('[].asNum returns numeric parameters', () {
      expect(parameters['num'].asNum, equals(1.5));
      expect(parameters['int'].asNum, equals(1));
    });

    test('[].asNumOr returns numeric parameters', () {
      expect(parameters['num'].asNumOr(7), equals(1.5));
    });

    test('[].asNum fails for non-numeric parameters', () {
      expect(
          () => parameters['bool'].asNum,
          throwsInvalidParams('Parameter "bool" for method "foo" must be a '
              'number, but was true.'));
    });

    test('[].asNumOr fails for non-numeric parameters', () {
      expect(
          () => parameters['bool'].asNumOr(7),
          throwsInvalidParams('Parameter "bool" for method "foo" must be a '
              'number, but was true.'));
    });

    test('[].asNum fails for absent parameters', () {
      expect(
          () => parameters['fblthp'].asNum,
          throwsInvalidParams('Request for method "foo" is missing required '
              'parameter "fblthp".'));
    });

    test('[].asNumOr succeeds for absent parameters', () {
      expect(parameters['fblthp'].asNumOr(7), equals(7));
    });

    test('[].asInt returns integer parameters', () {
      expect(parameters['int'].asInt, equals(1));
    });

    test('[].asIntOr returns integer parameters', () {
      expect(parameters['int'].asIntOr(7), equals(1));
    });

    test('[].asInt fails for non-integer parameters', () {
      expect(
          () => parameters['bool'].asInt,
          throwsInvalidParams('Parameter "bool" for method "foo" must be an '
              'integer, but was true.'));
    });

    test('[].asIntOr succeeds for absent parameters', () {
      expect(parameters['fblthp'].asIntOr(7), equals(7));
    });

    test('[].asBool returns boolean parameters', () {
      expect(parameters['bool'].asBool, isTrue);
    });

    test('[].asBoolOr returns boolean parameters', () {
      expect(parameters['bool'].asBoolOr(false), isTrue);
    });

    test('[].asBoolOr fails for non-boolean parameters', () {
      expect(
          () => parameters['int'].asBool,
          throwsInvalidParams('Parameter "int" for method "foo" must be a '
              'boolean, but was 1.'));
    });

    test('[].asBoolOr succeeds for absent parameters', () {
      expect(parameters['fblthp'].asBoolOr(false), isFalse);
    });

    test('[].asString returns string parameters', () {
      expect(parameters['string'].asString, equals('zap'));
    });

    test('[].asStringOr returns string parameters', () {
      expect(parameters['string'].asStringOr('bap'), equals('zap'));
    });

    test('[].asString fails for non-string parameters', () {
      expect(
          () => parameters['int'].asString,
          throwsInvalidParams('Parameter "int" for method "foo" must be a '
              'string, but was 1.'));
    });

    test('[].asStringOr succeeds for absent parameters', () {
      expect(parameters['fblthp'].asStringOr('bap'), equals('bap'));
    });

    test('[].asList returns list parameters', () {
      expect(parameters['list'].asList, equals([1, 2, 3]));
    });

    test('[].asListOr returns list parameters', () {
      expect(parameters['list'].asListOr([5, 6, 7]), equals([1, 2, 3]));
    });

    test('[].asList fails for non-list parameters', () {
      expect(
          () => parameters['int'].asList,
          throwsInvalidParams('Parameter "int" for method "foo" must be an '
              'Array, but was 1.'));
    });

    test('[].asListOr succeeds for absent parameters', () {
      expect(parameters['fblthp'].asListOr([5, 6, 7]), equals([5, 6, 7]));
    });

    test('[].asMap returns map parameters', () {
      expect(parameters['map'].asMap, equals({'num': 4.2, 'bool': false}));
    });

    test('[].asMapOr returns map parameters', () {
      expect(
          parameters['map'].asMapOr({}), equals({'num': 4.2, 'bool': false}));
    });

    test('[].asMap fails for non-map parameters', () {
      expect(
          () => parameters['int'].asMap,
          throwsInvalidParams('Parameter "int" for method "foo" must be an '
              'Object, but was 1.'));
    });

    test('[].asMapOr succeeds for absent parameters', () {
      expect(parameters['fblthp'].asMapOr({}), equals({}));
    });

    test('[].asDateTime returns date/time parameters', () {
      expect(parameters['date-time'].asDateTime, equals(DateTime(1990)));
    });

    test('[].asDateTimeOr returns date/time parameters', () {
      expect(parameters['date-time'].asDateTimeOr(DateTime(2014)),
          equals(DateTime(1990)));
    });

    test('[].asDateTime fails for non-date/time parameters', () {
      expect(
          () => parameters['int'].asDateTime,
          throwsInvalidParams('Parameter "int" for method "foo" must be a '
              'string, but was 1.'));
    });

    test('[].asDateTimeOr succeeds for absent parameters', () {
      expect(parameters['fblthp'].asDateTimeOr(DateTime(2014)),
          equals(DateTime(2014)));
    });

    test('[].asDateTime fails for non-date/time parameters', () {
      expect(
          () => parameters['int'].asDateTime,
          throwsInvalidParams('Parameter "int" for method "foo" must be a '
              'string, but was 1.'));
    });

    test('[].asDateTime fails for invalid date/times', () {
      expect(
          () => parameters['string'].asDateTime,
          throwsInvalidParams('Parameter "string" for method "foo" must be a '
              'valid date/time, but was "zap".\n'
              'Invalid date format'));
    });

    test('[].asUri returns URI parameters', () {
      expect(parameters['uri'].asUri, equals(Uri.parse('https://dart.dev')));
    });

    test('[].asUriOr returns URI parameters', () {
      expect(parameters['uri'].asUriOr(Uri.parse('http://google.com')),
          equals(Uri.parse('https://dart.dev')));
    });

    test('[].asUri fails for non-URI parameters', () {
      expect(
          () => parameters['int'].asUri,
          throwsInvalidParams('Parameter "int" for method "foo" must be a '
              'string, but was 1.'));
    });

    test('[].asUriOr succeeds for absent parameters', () {
      expect(parameters['fblthp'].asUriOr(Uri.parse('http://google.com')),
          equals(Uri.parse('http://google.com')));
    });

    test('[].asUri fails for non-URI parameters', () {
      expect(
          () => parameters['int'].asUri,
          throwsInvalidParams('Parameter "int" for method "foo" must be a '
              'string, but was 1.'));
    });

    test('[].asUri fails for invalid URIs', () {
      expect(
          () => parameters['invalid-uri'].asUri,
          throwsInvalidParams('Parameter "invalid-uri" for method "foo" must '
              'be a valid URI, but was "http://[::1".\n'
              'Missing end `]` to match `[` in host'));
    });

    group('with a nested parameter map', () {
      late json_rpc.Parameter nested;
      setUp(() => nested = parameters['map']);

      test('[int] fails with a type error', () {
        expect(
            () => nested[0],
            throwsInvalidParams('Parameter "map" for method "foo" must be an '
                'Array, but was {"num":4.2,"bool":false}.'));
      });

      test('[].value returns existing parameters', () {
        expect(nested['num'].value, equals(4.2));
        expect(nested['bool'].value, isFalse);
      });

      test('[].value fails for absent parameters', () {
        expect(
            () => nested['fblthp'].value,
            throwsInvalidParams('Request for method "foo" is missing required '
                'parameter map.fblthp.'));
      });

      test('typed getters return correctly-typed parameters', () {
        expect(nested['num'].asNum, equals(4.2));
      });

      test('typed getters fail for incorrectly-typed parameters', () {
        expect(
            () => nested['bool'].asNum,
            throwsInvalidParams('Parameter map.bool for method "foo" must be '
                'a number, but was false.'));
      });
    });

    group('with a nested parameter list', () {
      late json_rpc.Parameter nested;

      setUp(() => nested = parameters['list']);

      test('[string] fails with a type error', () {
        expect(
            () => nested['foo'],
            throwsInvalidParams('Parameter "list" for method "foo" must be an '
                'Object, but was [1,2,3].'));
      });

      test('[].value returns existing parameters', () {
        expect(nested[0].value, equals(1));
        expect(nested[1].value, equals(2));
      });

      test('[].value fails for absent parameters', () {
        expect(
            () => nested[5].value,
            throwsInvalidParams('Request for method "foo" is missing required '
                'parameter list[5].'));
      });

      test('typed getters return correctly-typed parameters', () {
        expect(nested[0].asInt, equals(1));
      });

      test('typed getters fail for incorrectly-typed parameters', () {
        expect(
            () => nested[0].asBool,
            throwsInvalidParams('Parameter list[0] for method "foo" must be '
                'a boolean, but was 1.'));
      });
    });
  });

  group('with positional parameters', () {
    late json_rpc.Parameters parameters;
    setUp(() => parameters = json_rpc.Parameters('foo', [1, 2, 3, 4, 5]));

    test('value returns the wrapped value', () {
      expect(parameters.value, equals([1, 2, 3, 4, 5]));
    });

    test('[string] throws a parameter error', () {
      expect(
          () => parameters['foo'],
          throwsInvalidParams('Parameters for method "foo" must be passed by '
              'name.'));
    });

    test('[].value returns existing parameters', () {
      expect(parameters[2].value, equals(3));
    });

    test('[].value fails for out-of-range parameters', () {
      expect(
          () => parameters[10].value,
          throwsInvalidParams('Request for method "foo" is missing required '
              'parameter 11.'));
    });

    test('[].exists returns true for existing parameters', () {
      expect(parameters[0].exists, isTrue);
    });

    test('[].exists returns false for missing parameters', () {
      expect(parameters[10].exists, isFalse);
    });
  });

  test('with a complex parameter path', () {
    var parameters = json_rpc.Parameters('foo', {
      'bar baz': [
        0,
        1,
        2,
        {
          'bang.zap': {'\n': 'qux'}
        }
      ]
    });

    expect(
        () => parameters['bar baz'][3]['bang.zap']['\n']['bip'],
        throwsInvalidParams('Parameter "bar baz"[3]."bang.zap"."\\n" for '
            'method "foo" must be an Object, but was "qux".'));
  });
}
