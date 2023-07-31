// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'mini_types.dart';

main() {
  group('parse', () {
    var throwsParseError = throwsA(TypeMatcher<ParseError>());

    group('primary type:', () {
      test('no type args', () {
        var t = Type('int') as PrimaryType;
        expect(t.name, 'int');
        expect(t.args, isEmpty);
      });

      test('type arg', () {
        var t = Type('List<int>') as PrimaryType;
        expect(t.name, 'List');
        expect(t.args, hasLength(1));
        expect(t.args[0].type, 'int');
      });

      test('type args', () {
        var t = Type('Map<int, String>') as PrimaryType;
        expect(t.name, 'Map');
        expect(t.args, hasLength(2));
        expect(t.args[0].type, 'int');
        expect(t.args[1].type, 'String');
      });

      test('invalid type arg separator', () {
        expect(() => Type('Map<int) String>'), throwsParseError);
      });
    });

    test('invalid initial token', () {
      expect(() => Type('<'), throwsParseError);
    });

    test('unknown type', () {
      var t = Type('?');
      expect(t, TypeMatcher<UnknownType>());
    });

    test('question type', () {
      var t = Type('int?') as QuestionType;
      expect(t.innerType.type, 'int');
    });

    test('star type', () {
      var t = Type('int*') as StarType;
      expect(t.innerType.type, 'int');
    });

    test('promoted type variable', () {
      var t = Type('T&int') as PromotedTypeVariableType;
      expect(t.innerType.type, 'T');
      expect(t.promotion.type, 'int');
    });

    test('parenthesized type', () {
      var t = Type('(int)');
      expect(t.type, 'int');
    });

    test('invalid token terminating parenthesized type', () {
      expect(() => Type('(?<'), throwsParseError);
    });

    group('function type:', () {
      test('no parameters', () {
        var t = Type('int Function()') as FunctionType;
        expect(t.returnType.type, 'int');
        expect(t.positionalParameters, isEmpty);
      });

      test('positional parameter', () {
        var t = Type('int Function(String)') as FunctionType;
        expect(t.returnType.type, 'int');
        expect(t.positionalParameters, hasLength(1));
        expect(t.positionalParameters[0].type, 'String');
      });

      test('positional parameters', () {
        var t = Type('int Function(String, double)') as FunctionType;
        expect(t.returnType.type, 'int');
        expect(t.positionalParameters, hasLength(2));
        expect(t.positionalParameters[0].type, 'String');
        expect(t.positionalParameters[1].type, 'double');
      });

      test('invalid parameter separator', () {
        expect(() => Type('int Function(String Function()< double)'),
            throwsParseError);
      });

      test('invalid token after Function', () {
        expect(() => Type('int Function&)'), throwsParseError);
      });
    });

    group('record type:', () {
      test('no fields', () {
        var t = Type('()') as RecordType;
        expect(t.positional, isEmpty);
        expect(t.named, isEmpty);
      });

      test('named field', () {
        var t = Type('({int x})') as RecordType;
        expect(t.positional, isEmpty);
        expect(t.named, hasLength(1));
        expect(t.named['x']!.type, 'int');
      });

      test('named field followed by comma', () {
        var t = Type('({int x,})') as RecordType;
        expect(t.positional, isEmpty);
        expect(t.named, hasLength(1));
        expect(t.named['x']!.type, 'int');
      });

      test('named field followed by invalid token', () {
        expect(() => Type('({int x))'), throwsParseError);
      });

      test('named field name is not an identifier', () {
        expect(() => Type('({int )})'), throwsParseError);
      });

      test('named fields', () {
        var t = Type('({int x, String y})') as RecordType;
        expect(t.positional, isEmpty);
        expect(t.named, hasLength(2));
        expect(t.named['x']!.type, 'int');
        expect(t.named['y']!.type, 'String');
      });

      test('curly braces followed by invalid token', () {
        expect(() => Type('({int x}&'), throwsParseError);
      });

      test('curly braces but no named fields', () {
        expect(() => Type('({})'), throwsParseError);
      });

      test('positional field', () {
        var t = Type('(int,)') as RecordType;
        expect(t.named, isEmpty);
        expect(t.positional, hasLength(1));
        expect(t.positional[0].type, 'int');
      });

      group('positional fields:', () {
        test('two', () {
          var t = Type('(int, String)') as RecordType;
          expect(t.named, isEmpty);
          expect(t.positional, hasLength(2));
          expect(t.positional[0].type, 'int');
          expect(t.positional[1].type, 'String');
        });

        test('three', () {
          var t = Type('(int, String, double)') as RecordType;
          expect(t.named, isEmpty);
          expect(t.positional, hasLength(3));
          expect(t.positional[0].type, 'int');
          expect(t.positional[1].type, 'String');
          expect(t.positional[2].type, 'double');
        });
      });

      test('named and positional fields', () {
        var t = Type('(int, {String x})') as RecordType;
        expect(t.positional, hasLength(1));
        expect(t.positional[0].type, 'int');
        expect(t.named, hasLength(1));
        expect(t.named['x']!.type, 'String');
      });

      test('terminated by invalid token', () {
        expect(() => Type('(int, String('), throwsParseError);
      });
    });

    group('invalid token:', () {
      test('before other tokens', () {
        expect(() => Type('#int'), throwsParseError);
      });

      test('at end', () {
        expect(() => Type('int#'), throwsParseError);
      });
    });

    test('extra token after type', () {
      expect(() => Type('int)'), throwsParseError);
    });
  });

  group('recursivelyDemote:', () {
    group('FunctionType:', () {
      group('return type:', () {
        test('unchanged', () {
          expect(Type('int Function()').recursivelyDemote(covariant: true),
              isNull);
          expect(Type('int Function()').recursivelyDemote(covariant: false),
              isNull);
        });

        test('covariant', () {
          expect(
              Type('T&int Function()').recursivelyDemote(covariant: true)!.type,
              'T Function()');
        });

        test('contravariant', () {
          expect(
              Type('T&int Function()')
                  .recursivelyDemote(covariant: false)!
                  .type,
              'Never Function()');
        });
      });

      group('positional parameters:', () {
        test('unchanged', () {
          expect(
              Type('void Function(int, String)')
                  .recursivelyDemote(covariant: true),
              isNull);
          expect(
              Type('void Function(int, String)')
                  .recursivelyDemote(covariant: false),
              isNull);
        });

        test('covariant', () {
          expect(
              Type('void Function(T&int, String)')
                  .recursivelyDemote(covariant: true)!
                  .type,
              'void Function(Never, String)');
        });

        test('contravariant', () {
          expect(
              Type('void Function(T&int, String)')
                  .recursivelyDemote(covariant: false)!
                  .type,
              'void Function(T, String)');
        });
      });
    });

    group('NonFunctionType', () {
      test('unchanged', () {
        expect(Type('int').recursivelyDemote(covariant: true), isNull);
        expect(Type('int').recursivelyDemote(covariant: false), isNull);
      });

      group('type parameters:', () {
        test('unchanged', () {
          expect(Type('Map<int, String>').recursivelyDemote(covariant: true),
              isNull);
          expect(Type('Map<int, String>').recursivelyDemote(covariant: false),
              isNull);
        });

        test('covariant', () {
          expect(
              Type('Map<T&int, String>')
                  .recursivelyDemote(covariant: true)!
                  .type,
              'Map<T, String>');
        });

        test('contravariant', () {
          expect(
              Type('Map<T&int, String>')
                  .recursivelyDemote(covariant: false)!
                  .type,
              'Map<Never, String>');
        });
      });
    });

    group('QuestionType:', () {
      test('unchanged', () {
        expect(Type('int?').recursivelyDemote(covariant: true), isNull);
        expect(Type('int?').recursivelyDemote(covariant: false), isNull);
      });

      test('covariant', () {
        expect(Type('(T&int)?').recursivelyDemote(covariant: true)!.type, 'T?');
      });

      test('contravariant', () {
        // Note: we don't normalize `Never?` to `Null`.
        expect(Type('(T&int)?').recursivelyDemote(covariant: false)!.type,
            'Never?');
      });
    });

    group('RecordType:', () {
      test('unchanged', () {
        var type = RecordType(positional: [
          Type('int'),
        ], named: {
          'a': Type('double')
        });
        expect(type.recursivelyDemote(covariant: true), isNull);
        expect(type.recursivelyDemote(covariant: false), isNull);
      });

      group('changed:', () {
        group('positional:', () {
          var type = RecordType(positional: [
            Type('T&int'),
          ], named: {
            'a': Type('double')
          });
          test('covariant', () {
            expect(
              type.recursivelyDemote(covariant: true)!.type,
              '(T, {double a})',
            );
          });
          test('contravariant', () {
            expect(
              type.recursivelyDemote(covariant: false)!.type,
              '(Never, {double a})',
            );
          });
        });
        group('named:', () {
          var type = RecordType(positional: [
            Type('double'),
          ], named: {
            'a': Type('T&int')
          });
          test('covariant', () {
            expect(
              type.recursivelyDemote(covariant: true)!.type,
              '(double, {T a})',
            );
          });
          test('contravariant', () {
            expect(
              type.recursivelyDemote(covariant: false)!.type,
              '(double, {Never a})',
            );
          });
        });
      });
    });

    group('StarType:', () {
      test('unchanged', () {
        expect(Type('int*').recursivelyDemote(covariant: true), isNull);
        expect(Type('int*').recursivelyDemote(covariant: false), isNull);
      });

      test('covariant', () {
        expect(Type('(T&int)*').recursivelyDemote(covariant: true)!.type, 'T*');
      });

      test('contravariant', () {
        expect(Type('(T&int)*').recursivelyDemote(covariant: false)!.type,
            'Never*');
      });
    });

    test('UnknownType:', () {
      expect(Type('?').recursivelyDemote(covariant: true), isNull);
      expect(Type('?').recursivelyDemote(covariant: false), isNull);
    });
  });
}
