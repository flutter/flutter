// ignore_for_file: prefer_const_constructors
// ignore_for_file: unrelated_type_equality_checks
// ignore_for_file: prefer_collection_literals
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:equatable/src/equatable_utils.dart';
import 'package:test/test.dart';

import 'custom_list.dart';

class NonEquatable {}

class EmptyEquatable extends Equatable {
  const EmptyEquatable();

  @override
  List<Object> get props => [];
}

class SimpleEquatable<T extends Object> extends Equatable {
  const SimpleEquatable(this.data);

  final T data;

  @override
  List<Object> get props => [data];
}

class MultipartEquatable<T extends Object> extends Equatable {
  MultipartEquatable(this.d1, this.d2);

  final T d1;
  final T d2;

  @override
  List<Object> get props => [d1, d2];
}

class OtherEquatable extends Equatable {
  const OtherEquatable(this.data);

  final String data;

  @override
  List<Object> get props => [data];
}

enum Color { blonde, black, brown }

class ComplexEquatable extends Equatable {
  const ComplexEquatable({this.name, this.age, this.hairColor, this.children});

  final String? name;
  final int? age;
  final Color? hairColor;
  final List<String>? children;

  @override
  List<Object?> get props => [name, age, hairColor, children];
}

class EquatableData extends Equatable {
  const EquatableData({required this.key, required this.value});

  final String key;
  final Object value;

  @override
  List<Object> get props => [key, value];
}

class Credentials extends Equatable {
  const Credentials({required this.username, required this.password});

  factory Credentials.fromJson(Map<String, dynamic> json) {
    return Credentials(
      username: json['username'] as String,
      password: json['password'] as String,
    );
  }

  final String username;
  final String password;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'username': username,
      'password': password,
    };
  }

  @override
  List<Object> get props => [username, password];
}

class ComplexStringify extends Equatable {
  ComplexStringify({this.name, this.age, this.hairColor});

  final String? name;
  final int? age;
  final Color? hairColor;

  @override
  List<Object?> get props => [name, age, hairColor];

  @override
  bool get stringify => true;
}

class SuperLongPropertiesStringify extends Equatable {
  SuperLongPropertiesStringify(this.a, this.b, this.c, this.d, this.e, this.f);

  final String a;
  final String b;
  final String c;
  final String d;
  final String e;
  final String f;

  @override
  List<Object> get props => [a, b, c, d, e, f];

  @override
  bool get stringify => true;
}

class ExplicitStringifyFalse extends Equatable {
  ExplicitStringifyFalse({this.name, this.age, this.hairColor});

  final String? name;
  final int? age;
  final Color? hairColor;

  @override
  List<Object?> get props => [name, age, hairColor];

  @override
  bool get stringify => false;
}

void main() {
  late bool globalStringify;

  setUp(() {
    globalStringify = EquatableConfig.stringify;
  });

  tearDown(() {
    EquatableConfig.stringify = globalStringify;
  });

  group('Empty Equatable', () {
    test('should correct toString', () {
      final instance = EmptyEquatable();
      expect(instance.toString(), 'EmptyEquatable()');
    });

    test('should return true when instance is the same', () {
      final instance = EmptyEquatable();
      expect(instance == instance, true);
    });

    test('should return correct hashCode', () {
      final instance = EmptyEquatable();
      expect(
        instance.hashCode,
        instance.runtimeType.hashCode ^ mapPropsToHashCode(instance.props),
      );
    });

    test('should return true when instances are different', () {
      final instanceA = EmptyEquatable();
      final instanceB = EmptyEquatable();
      expect(instanceA == instanceB, true);
      expect(instanceA.hashCode == instanceB.hashCode, true);
    });

    test('should return false when compared to non-equatable', () {
      final instanceA = EmptyEquatable();
      final instanceB = NonEquatable();
      expect(instanceA == instanceB, false);
    });
  });

  group('Simple Equatable (string)', () {
    test('should correct toString', () {
      final instance = SimpleEquatable('simple');
      expect(instance.toString(), 'SimpleEquatable<String>(simple)');
    });

    test('should correct toString when EquatableConfig.stringify is false', () {
      EquatableConfig.stringify = false;
      final instance = SimpleEquatable('simple');
      expect(instance.toString(), 'SimpleEquatable<String>');
    });

    test('should return true when instance is the same', () {
      final instance = SimpleEquatable('simple');
      expect(instance == instance, true);
    });

    test('should return correct hashCode', () {
      final instance = SimpleEquatable('simple');
      expect(
        instance.hashCode,
        instance.runtimeType.hashCode ^ mapPropsToHashCode(instance.props),
      );
    });

    test('should return correct toString', () {
      final instance = SimpleEquatable('simple');
      expect(instance.toString(), 'SimpleEquatable<String>(simple)');
    });

    test('should return true when instances are different', () {
      final instanceA = SimpleEquatable('simple');
      final instanceB = SimpleEquatable('simple');
      expect(instanceA == instanceB, true);
      expect(instanceA.hashCode == instanceB.hashCode, true);
    });

    test('should return false when compared to non-equatable', () {
      final instanceA = SimpleEquatable('simple');
      final instanceB = NonEquatable();
      expect(instanceA == instanceB, false);
    });

    test('should return false when compared to different equatable', () {
      final instanceA = SimpleEquatable('simple');
      final instanceB = OtherEquatable('simple');
      expect(instanceA == instanceB, false);
    });

    test('should return false when values are different', () {
      final instanceA = SimpleEquatable('simple');
      final instanceB = SimpleEquatable('Simple');
      expect(instanceA == instanceB, false);
    });
  });

  group('Simple Equatable (number)', () {
    test('should return correct toString', () {
      final instance = SimpleEquatable(0);
      expect(instance.toString(), 'SimpleEquatable<int>(0)');
    });

    test('should return true when instance is the same', () {
      final instance = SimpleEquatable(0);
      expect(instance == instance, true);
    });

    test('should return correct hashCode', () {
      final instance = SimpleEquatable(0);
      expect(
        instance.hashCode,
        instance.runtimeType.hashCode ^ mapPropsToHashCode(instance.props),
      );
    });

    test('should return true when instances are different', () {
      final instanceA = SimpleEquatable(0);
      final instanceB = SimpleEquatable(0);
      expect(instanceA == instanceB, true);
      expect(instanceA.hashCode == instanceB.hashCode, true);
    });

    test('should return false when compared to non-equatable', () {
      final instanceA = SimpleEquatable(0);
      final instanceB = NonEquatable();
      expect(instanceA == instanceB, false);
    });

    test('should return false when values are different', () {
      final instanceA = SimpleEquatable(0);
      final instanceB = SimpleEquatable(1);
      expect(instanceA == instanceB, false);
    });
  });

  group('Simple Equatable (bool)', () {
    test('should correct toString', () {
      final instance = SimpleEquatable(true);
      expect(instance.toString(), 'SimpleEquatable<bool>(true)');
    });

    test('should return true when instance is the same', () {
      final instance = SimpleEquatable(true);
      expect(instance == instance, true);
    });

    test('should return correct hashCode', () {
      final instance = SimpleEquatable(true);
      expect(
        instance.hashCode,
        instance.runtimeType.hashCode ^ mapPropsToHashCode(instance.props),
      );
    });

    test('should return true when instances are different', () {
      final instanceA = SimpleEquatable(true);
      final instanceB = SimpleEquatable(true);
      expect(instanceA == instanceB, true);
      expect(instanceA.hashCode == instanceB.hashCode, true);
    });

    test('should return false when compared to non-equatable', () {
      final instanceA = SimpleEquatable(true);
      final instanceB = NonEquatable();
      expect(instanceA == instanceB, false);
    });

    test('should return false when values are different', () {
      final instanceA = SimpleEquatable(true);
      final instanceB = SimpleEquatable(false);
      expect(instanceA == instanceB, false);
    });
  });

  group('Simple Equatable (map)', () {
    test('should correct toString', () {
      final instance = SimpleEquatable(<String, dynamic>{});
      expect(instance.toString(), 'SimpleEquatable<Map<String, dynamic>>({})');
    });

    test('should return true when instance is the same', () {
      final instance = SimpleEquatable({'a': 1, 'b': 2, 'c': 3});
      expect(instance == instance, true);
    });

    test('should return correct hashCode', () {
      final instance = SimpleEquatable({'a': 1, 'b': 2, 'c': 3});
      expect(
        instance.hashCode,
        instance.runtimeType.hashCode ^ mapPropsToHashCode(instance.props),
      );
    });

    test('should have same hashCode when values are equal', () {
      final instanceA = SimpleEquatable({'a': 1, 'b': 2, 'c': 3});
      final instanceB = SimpleEquatable({'b': 2, 'a': 1, 'c': 3});
      expect(instanceA == instanceB, true);
      expect(instanceA.hashCode, instanceB.hashCode);
    });

    test('should return true when instances are different', () {
      final instanceA = SimpleEquatable({'a': 1, 'b': 2, 'c': 3});
      final instanceB = SimpleEquatable({'a': 1, 'b': 2, 'c': 3});
      expect(instanceA == instanceB, true);
      expect(instanceA.hashCode == instanceB.hashCode, true);
    });

    test('should return false when compared to non-equatable', () {
      final instanceA = SimpleEquatable({'a': 1, 'b': 2, 'c': 3});
      final instanceB = NonEquatable();
      expect(instanceA == instanceB, false);
    });

    test('should return false when values are different', () {
      final instanceA = SimpleEquatable({'a': 1, 'b': 2, 'c': 3});
      final instanceB = SimpleEquatable({'a': 1, 'b': 2, 'c': 4});
      expect(instanceA == instanceB, false);
    });
  });

  group('Simple Equatable (map custom key)', () {
    test('should correct toString', () {
      final instance = SimpleEquatable(<SimpleEquatable<String>, dynamic>{});
      expect(
        instance.toString(),
        'SimpleEquatable<Map<SimpleEquatable<String>, dynamic>>({})',
      );
    });

    test('should return true when instance is the same', () {
      final instance = SimpleEquatable(
        {
          SimpleEquatable<String>('a'): 1,
          SimpleEquatable<String>('b'): 2,
          SimpleEquatable<String>('c'): 3
        },
      );
      expect(instance == instance, true);
    });

    test('should return correct hashCode', () {
      final instance = SimpleEquatable(
        {
          SimpleEquatable<String>('a'): 1,
          SimpleEquatable<String>('b'): 2,
          SimpleEquatable<String>('c'): 3
        },
      );
      expect(
        instance.hashCode,
        instance.runtimeType.hashCode ^ mapPropsToHashCode(instance.props),
      );
    });

    test('should have same hashCode when values are equal', () {
      final instanceA = SimpleEquatable(
        {
          SimpleEquatable<String>('a'): 1,
          SimpleEquatable<String>('b'): 2,
          SimpleEquatable<String>('c'): 3
        },
      );
      final instanceB = SimpleEquatable(
        {
          SimpleEquatable<String>('b'): 2,
          SimpleEquatable<String>('a'): 1,
          SimpleEquatable<String>('c'): 3
        },
      );
      expect(instanceA == instanceB, true);
      expect(instanceA.hashCode, instanceB.hashCode);
    });

    test('should return true when instances are different', () {
      final instanceA = SimpleEquatable(
        {
          SimpleEquatable<String>('a'): 1,
          SimpleEquatable<String>('b'): 2,
          SimpleEquatable<String>('c'): 3
        },
      );
      final instanceB = SimpleEquatable(
        {
          SimpleEquatable<String>('a'): 1,
          SimpleEquatable<String>('b'): 2,
          SimpleEquatable<String>('c'): 3
        },
      );
      expect(instanceA == instanceB, true);
      expect(instanceA.hashCode == instanceB.hashCode, true);
    });

    test('should return false when compared to non-equatable', () {
      final instanceA = SimpleEquatable(
        {
          SimpleEquatable<String>('a'): 1,
          SimpleEquatable<String>('b'): 2,
          SimpleEquatable<String>('c'): 3
        },
      );
      final instanceB = NonEquatable();
      expect(instanceA == instanceB, false);
    });

    test('should return false when values are different', () {
      final instanceA = SimpleEquatable(
        {
          SimpleEquatable<String>('a'): 1,
          SimpleEquatable<String>('b'): 2,
          SimpleEquatable<String>('c'): 3
        },
      );
      final instanceB = SimpleEquatable(
        {
          SimpleEquatable<String>('a'): 1,
          SimpleEquatable<String>('b'): 2,
          SimpleEquatable<String>('c'): 2
        },
      );
      expect(instanceA == instanceB, false);
    });
  });

  group('Simple Equatable (Equatable)', () {
    test('should correct toString', () {
      final instance = SimpleEquatable(EquatableData(
        key: 'foo',
        value: 'bar',
      ));
      expect(
        instance.toString(),
        'SimpleEquatable<EquatableData>(EquatableData(foo, bar))',
      );
    });
    test('should return true when instance is the same', () {
      final instance = SimpleEquatable(EquatableData(
        key: 'foo',
        value: 'bar',
      ));
      expect(instance == instance, true);
    });

    test('should return correct hashCode', () {
      final instance = SimpleEquatable(EquatableData(
        key: 'foo',
        value: 'bar',
      ));
      expect(
        instance.hashCode,
        instance.runtimeType.hashCode ^ mapPropsToHashCode(instance.props),
      );
    });

    test('should return true when instances are different', () {
      final instanceA = SimpleEquatable(EquatableData(
        key: 'foo',
        value: 'bar',
      ));
      final instanceB = SimpleEquatable(EquatableData(
        key: 'foo',
        value: 'bar',
      ));
      expect(instanceA == instanceB, true);
      expect(instanceA.hashCode == instanceB.hashCode, true);
    });

    test('should return false when compared to non-equatable', () {
      final instanceA = SimpleEquatable(EquatableData(
        key: 'foo',
        value: 'bar',
      ));
      final instanceB = NonEquatable();
      expect(instanceA == instanceB, false);
    });

    test('should return false when values are different', () {
      final instanceA = SimpleEquatable(EquatableData(
        key: 'foo',
        value: 'bar',
      ));
      final instanceB = SimpleEquatable(EquatableData(
        key: 'foo',
        value: 'barz',
      ));
      expect(instanceA == instanceB, false);
    });
  });

  group('Multipart Equatable', () {
    test('should correct toString', () {
      final instance = MultipartEquatable('s1', 's2');
      expect(instance.toString(), 'MultipartEquatable<String>(s1, s2)');
    });

    test('should return true when instance is the same', () {
      final instance = MultipartEquatable('s1', 's2');
      expect(instance == instance, true);
    });

    test('should return correct hashCode', () {
      final instance = MultipartEquatable('s1', 's2');
      expect(
        instance.hashCode,
        instance.runtimeType.hashCode ^ mapPropsToHashCode(instance.props),
      );
    });

    test('should return different hashCodes when property order has changed',
        () {
      final instance1 = MultipartEquatable('s1', 's2');
      final instance2 = MultipartEquatable('s2', 's1');
      expect(instance1.hashCode == instance2.hashCode, isFalse);
    });

    test('should return true when instances are different', () {
      final instanceA = MultipartEquatable('s1', 's2');
      final instanceB = MultipartEquatable('s1', 's2');
      expect(instanceA == instanceB, true);
      expect(instanceA.hashCode == instanceB.hashCode, true);
    });

    test('should return false when compared to non-equatable', () {
      final instanceA = MultipartEquatable('s1', 's2');
      final instanceB = NonEquatable();
      expect(instanceA == instanceB, false);
    });

    test('should return false when values are different', () {
      final instanceA = MultipartEquatable('s1', 's2');
      final instanceB = MultipartEquatable('s2', 's1');
      expect(instanceA == instanceB, false);

      final instanceC = MultipartEquatable('s1', 's1');
      final instanceD = MultipartEquatable('s2', 's1');
      expect(instanceC == instanceD, false);
    });
  });

  group('Complex Equatable', () {
    test('should correct toString', () {
      final instance = ComplexEquatable(
        name: 'Joe',
        age: 40,
        hairColor: Color.black,
        children: ['Bob'],
      );
      expect(
        instance.toString(),
        'ComplexEquatable(Joe, 40, Color.black, [Bob])',
      );
    });
    test('should return true when instance is the same', () {
      final instance = ComplexEquatable(
        name: 'Joe',
        age: 40,
        hairColor: Color.black,
        children: ['Bob'],
      );
      expect(instance == instance, true);
    });

    test('should return correct hashCode', () {
      final instance = ComplexEquatable(
        name: 'Joe',
        age: 40,
        hairColor: Color.black,
        children: ['Bob'],
      );
      expect(
        instance.hashCode,
        instance.runtimeType.hashCode ^ mapPropsToHashCode(instance.props),
      );
    });

    test('should return true when instances are different', () {
      final instanceA = ComplexEquatable(
        name: 'Joe',
        age: 40,
        hairColor: Color.black,
        children: ['Bob'],
      );
      final instanceB = ComplexEquatable(
        name: 'Joe',
        age: 40,
        hairColor: Color.black,
        children: ['Bob'],
      );
      expect(instanceA == instanceB, true);
      expect(instanceA.hashCode == instanceB.hashCode, true);
    });

    test('should return false when compared to non-equatable', () {
      final instanceA = ComplexEquatable(
        name: 'Joe',
        age: 40,
        hairColor: Color.black,
        children: ['Bob'],
      );
      final instanceB = NonEquatable();
      expect(instanceA == instanceB, false);
    });

    test('should return false when values are different', () {
      final instanceA = ComplexEquatable(
        name: 'Joe',
        age: 40,
        hairColor: Color.black,
        children: ['Bob'],
      );
      final instanceB = ComplexEquatable(
        name: 'John',
        age: 40,
        hairColor: Color.brown,
        children: ['Bobby'],
      );
      expect(instanceA == instanceB, false);
    });

    test('should return false when values only differ in list', () {
      final instanceA = ComplexEquatable(
        name: 'Joe',
        age: 40,
        hairColor: Color.black,
        children: ['Bob'],
      );
      final instanceB = ComplexEquatable(
        name: 'Joe',
        age: 40,
        hairColor: Color.black,
        children: ['Bobby'],
      );
      expect(instanceA == instanceB, false);
    });

    test('should return false when values only differ in single property', () {
      final instanceA = ComplexEquatable(
        name: 'Joe',
        age: 40,
        hairColor: Color.black,
        children: ['Bob'],
      );
      final instanceB = ComplexEquatable(
        name: 'Joe',
        age: 41,
        hairColor: Color.black,
        children: ['Bob'],
      );
      expect(instanceA == instanceB, false);
    });
  });

  group('Json Equatable', () {
    test('should correct toString', () {
      final instance = Credentials.fromJson(json.decode(
        '''
        {
          "username":"Admin",
          "password":"admin"
        }
        ''',
      ) as Map<String, dynamic>);
      expect(instance.toString(), 'Credentials(Admin, admin)');
    });

    test('should return true when instance is the same', () {
      final instance = Credentials.fromJson(json.decode(
        '''
        {
          "username":"Admin",
          "password":"admin"
        }
        ''',
      ) as Map<String, dynamic>);
      expect(instance == instance, true);
    });

    test('should return correct hashCode', () {
      final instance = Credentials.fromJson(json.decode(
        '''
        {
          "username":"Admin",
          "password":"admin"
        }
        ''',
      ) as Map<String, dynamic>);
      expect(
        instance.hashCode,
        instance.runtimeType.hashCode ^ mapPropsToHashCode(instance.props),
      );
    });

    test('should return true when instances are different', () {
      final instanceA = Credentials.fromJson(json.decode(
        '''
        {
          "username":"Admin",
          "password":"admin"
        }
        ''',
      ) as Map<String, dynamic>);
      final instanceB = Credentials.fromJson(json.decode(
        '''
        {
          "username":"Admin",
          "password":"admin"
        }
        ''',
      ) as Map<String, dynamic>);
      expect(instanceA == instanceB, true);
      expect(instanceA.hashCode == instanceB.hashCode, true);
    });

    test('should return false when compared to non-equatable', () {
      final instanceA = Credentials.fromJson(json.decode(
        '''
        {
          "username":"Admin",
          "password":"admin"
        }
        ''',
      ) as Map<String, dynamic>);
      final instanceB = NonEquatable();
      expect(instanceA == instanceB, false);
    });

    test('should return false when values are different', () {
      final instanceA = Credentials.fromJson(json.decode(
        '''
        {
          "username":"Admin",
          "password":"admin"
        }
        ''',
      ) as Map<String, dynamic>);
      final instanceB = Credentials.fromJson(json.decode(
        '''
        {
          "username":"Admin",
          "password":"password"
        }
        ''',
      ) as Map<String, dynamic>);
      expect(instanceA == instanceB, false);
    });
  });

  group('Collection Equatable', () {
    group('Iterable Equatable', () {
      test('list of zeros same hashcode check', () {
        final s0 = SimpleEquatable([0, 0]);
        final s1 = SimpleEquatable([0, 0, 0]);
        expect(s0.hashCode != s1.hashCode, true);
      });

      test('should return when values are same', () {
        final instanceA = SimpleEquatable<Iterable>(<String>['A', 'B']);
        final instanceB = SimpleEquatable<Iterable>(<String>['A', 'B']);
        expect(instanceA == instanceB, true);
        expect(instanceA.hashCode == instanceB.hashCode, true);
      });

      test('should return when values are different', () {
        final instanceA = SimpleEquatable<Iterable>(<String>['A', 'B']);
        final instanceB = SimpleEquatable<Iterable>(<String>['a', 'b']);
        expect(instanceA != instanceB, true);
        expect(instanceA.hashCode != instanceB.hashCode, true);
      });

      test('should return when values are different', () {
        final instanceA = SimpleEquatable<Iterable>(<String>['A', 'B']);
        final instanceB = SimpleEquatable<Iterable>(<String>['C', 'D']);
        expect(instanceA != instanceB, true);
        expect(instanceA.hashCode != instanceB.hashCode, true);
      });
    });

    group('List Equatable', () {
      test('should return when values are same', () {
        final instanceA = SimpleEquatable<List>(<String>['A', 'B']);
        final instanceB = SimpleEquatable<List>(<String>['A', 'B']);
        expect(instanceA == instanceB, true);
        expect(instanceA.hashCode == instanceB.hashCode, true);
      });

      test('should return when values are different', () {
        final instanceA = SimpleEquatable<List>(<String>['A', 'B']);
        final instanceB = SimpleEquatable<List>(<String>['a', 'b']);
        expect(instanceA != instanceB, true);
        expect(instanceA.hashCode != instanceB.hashCode, true);
      });

      test('should return when values are different', () {
        final instanceA = SimpleEquatable<List>(<String>['A', 'B']);
        final instanceB = SimpleEquatable<List>(<String>['C', 'D']);
        expect(instanceA != instanceB, true);
        expect(instanceA.hashCode != instanceB.hashCode, true);
      });

      test('should return when contents are same but different kind of List',
          () {
        final instanceA = SimpleEquatable<List>(
          CustomList<String>(['A', 'B'], growable: true),
        );
        final instanceB = SimpleEquatable<List>(<String>['A', 'B']);
        expect(instanceA == instanceB, true);
        expect(instanceA.hashCode == instanceB.hashCode, true);
      });

      test(
          'should return different hashCode '
          'when instance properties are different', () {
        final instanceA = SimpleEquatable<List>(<String>['A', 'B']);
        final instanceB = SimpleEquatable<List>(<String>['B']);

        expect(instanceA != instanceB, true);
        expect(instanceA.hashCode != instanceB.hashCode, true);
      });

      test(
          'should return different hashCode '
          'when instance properties are modified', () {
        final list = ['A', 'B'];
        final instanceA = SimpleEquatable<List>(list);
        final hashCodeA = instanceA.hashCode;
        list.removeLast();
        final hashCodeB = instanceA.hashCode;
        expect(hashCodeA != hashCodeB, true);
      });
    });

    group('Map Equatable', () {
      test('should return true when values are same', () {
        final instanceA = SimpleEquatable<Map<int, String>>({1: 'A', 2: 'B'});
        final instanceB = SimpleEquatable<Map<int, String>>({1: 'A', 2: 'B'});
        expect(instanceA == instanceB, true);
        expect(instanceA.hashCode == instanceB.hashCode, true);
      });

      test('should return false when values are different', () {
        final instanceA = SimpleEquatable<Map<int, String>>({1: 'A', 2: 'B'});
        final instanceB = SimpleEquatable<Map<int, String>>({1: 'a', 2: 'b'});
        expect(instanceA != instanceB, true);
        expect(instanceA.hashCode != instanceB.hashCode, true);
      });

      test('should return false when values are different', () {
        final instanceA = SimpleEquatable<Map<int, String>>({1: 'A', 2: 'B'});
        final instanceB = SimpleEquatable<Map<int, String>>({1: 'C', 2: 'D'});
        expect(instanceA != instanceB, true);
        expect(instanceA.hashCode != instanceB.hashCode, true);
      });

      test(
          'should return different hashCode '
          'when instance properties are different', () {
        final instanceA = SimpleEquatable<Map<int, String>>({1: 'A', 2: 'B'});
        final instanceB = SimpleEquatable<Map<int, String>>({2: 'B'});

        expect(instanceA != instanceB, true);
        expect(instanceA.hashCode != instanceB.hashCode, true);
      });

      test(
          'should return different hashCode '
          'when instance properties are modified', () {
        final map = {1: 'A', 2: 'B'};
        final instanceA = SimpleEquatable<Map>(map);
        final hashCodeA = instanceA.hashCode;
        map.remove(1);
        final hashCodeB = instanceA.hashCode;
        expect(hashCodeA != hashCodeB, true);
      });
    });

    group('Set Equatable', () {
      test('should return when values are same', () {
        final instanceA = SimpleEquatable<Set<String>>(
          Set.from(<String>['A', 'B']),
        );
        final instanceB = SimpleEquatable<Set<String>>(
          Set.from(<String>['A', 'B']),
        );
        expect(instanceA == instanceB, true);
        expect(instanceA.hashCode == instanceB.hashCode, true);
      });

      test('should return when values are same', () {
        final instanceA = SimpleEquatable<Set<String>>(
          Set.from(<String>['A', 'B', 'A']),
        );
        final instanceB = SimpleEquatable<Set<String>>(
          Set.from(<String>['A', 'B']),
        );
        expect(instanceA == instanceB, true);
        expect(instanceA.hashCode == instanceB.hashCode, true);
      });

      test('should return when values are different', () {
        final instanceA = SimpleEquatable<Set<String>>(
          Set.from(<String>['A', 'B']),
        );
        final instanceB = SimpleEquatable<Set<String>>(
          Set.from(<String>['a', 'b']),
        );
        expect(instanceA != instanceB, true);
        expect(instanceA.hashCode != instanceB.hashCode, true);
      });

      test('should return when values are different', () {
        final instanceA = SimpleEquatable<Set<String>>(
          Set.from(<String>['A', 'B']),
        );
        final instanceB = SimpleEquatable<Set<String>>(
          Set.from(<String>['C', 'D']),
        );
        expect(instanceA != instanceB, true);
        expect(instanceA.hashCode != instanceB.hashCode, true);
      });
    });
  });

  group('To String Equatable', () {
    test('with Complex stringify', () {
      final instanceA = ComplexStringify();
      final instanceB = ComplexStringify(name: 'Bob', hairColor: Color.black);
      final instanceC =
          ComplexStringify(name: 'Joe', age: 50, hairColor: Color.blonde);
      expect(instanceA.toString(), 'ComplexStringify(null, null, null)');
      expect(instanceB.toString(), 'ComplexStringify(Bob, null, Color.black)');
      expect(instanceC.toString(), 'ComplexStringify(Joe, 50, Color.blonde)');
    });

    test('with SuperLongProperties stringify', () {
      final instance = SuperLongPropertiesStringify(
        'aaaaaaaaaaaaaaa',
        'aaaaaaaaaaaaaaa',
        'aaaaaaaaaaaaaaa',
        'aaaaaaaaaaaaaaa',
        'aaaaaaaaaaaaaaa',
        'aaaaaaaaaaaaaaa',
      );
      expect(
        instance.toString(),
        'SuperLongPropertiesStringify(aaaaaaaaaaaaaaa, aaaaaaaaaaaaaaa, '
        'aaaaaaaaaaaaaaa, aaaaaaaaaaaaaaa, aaaaaaaaaaaaaaa, '
        'aaaaaaaaaaaaaaa)',
      );
    });

    test('with ExplicitStringifyFalse stringify', () {
      final instanceA = ExplicitStringifyFalse();
      final instanceB =
          ExplicitStringifyFalse(name: 'Bob', hairColor: Color.black);
      final instanceC =
          ExplicitStringifyFalse(name: 'Joe', age: 50, hairColor: Color.blonde);
      expect(instanceA.toString(), 'ExplicitStringifyFalse');
      expect(instanceB.toString(), 'ExplicitStringifyFalse');
      expect(instanceC.toString(), 'ExplicitStringifyFalse');
    });
  });
}

// test that subclasses of `Equatable` can have const constructors
class ConstTest extends Equatable {
  const ConstTest(this.a);

  final int a;

  @override
  List<Object> get props => [a];
}
