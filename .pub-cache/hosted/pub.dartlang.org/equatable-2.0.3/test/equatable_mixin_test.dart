// ignore_for_file: unrelated_type_equality_checks
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:equatable/src/equatable_utils.dart';
import 'package:test/test.dart';

class NonEquatable {}

abstract class EquatableBase with EquatableMixin {}

class EmptyEquatable extends EquatableBase {
  @override
  List<Object> get props => const [];
}

class SimpleEquatable<T extends Object> extends EquatableBase {
  SimpleEquatable(this.data);

  final T data;

  @override
  List<Object> get props => [data];
}

class MultipartEquatable<T extends Object> extends EquatableBase {
  MultipartEquatable(this.d1, this.d2);

  final T d1;
  final T d2;

  @override
  List<Object> get props => [d1, d2];
}

class OtherEquatable extends EquatableBase {
  OtherEquatable(this.data);

  final String data;

  @override
  List<Object> get props => [data];
}

enum Color { blonde, black, brown }

class ComplexEquatable extends EquatableBase {
  ComplexEquatable({this.name, this.age, this.hairColor, this.children});

  final String? name;
  final int? age;
  final Color? hairColor;
  final List<String>? children;

  @override
  List<Object?> get props => [name, age, hairColor, children];
}

class EquatableData extends EquatableBase {
  EquatableData({this.key, this.value});

  final String? key;
  final dynamic value;

  @override
  List<Object?> get props => [key, value];
}

class Credentials extends EquatableBase {
  Credentials({required this.username, required this.password});

  factory Credentials.fromJson(Map<String, dynamic> json) {
    return Credentials(
      username: json['username'] as String,
      password: json['password'] as String,
    );
  }

  final String username;
  final String password;

  @override
  List<Object> get props => [username, password];

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'username': username,
      'password': password,
    };
  }
}

class ComplexStringify extends ComplexEquatable {
  ComplexStringify({String? name, int? age, Color? hairColor})
      : super(name: name, age: age, hairColor: hairColor);

  @override
  bool get stringify => true;
}

class ExplicitStringifyFalse extends ComplexEquatable {
  ExplicitStringifyFalse({String? name, int? age, Color? hairColor})
      : super(name: name, age: age, hairColor: hairColor);

  @override
  List<Object?> get props => [name, age, hairColor];

  @override
  bool get stringify => false;
}

class IterableWithFlag<T> extends Iterable<T> with EquatableMixin {
  IterableWithFlag({required this.list, required this.flag});

  final bool flag;
  final List<T> list;

  @override
  List<Object> get props => [flag, list];

  @override
  Iterator<T> get iterator => list.iterator;
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
    test('should correct toString', () {
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

    test('should return different hashCode even for empty list', () {
      final instance = ComplexEquatable(
        name: 'Joe',
        age: 40,
        hairColor: Color.black,
        children: [],
      );
      final instance2 = ComplexEquatable(
        name: 'John',
        age: 40,
        hairColor: Color.black,
        children: [],
      );
      expect(instance.hashCode != instance2.hashCode, true);
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

  group('To String Equatable', () {
    test('Complex stringify', () {
      final instanceA = ComplexStringify();
      final instanceB = ComplexStringify(name: 'Bob', hairColor: Color.black);
      final instanceC =
          ComplexStringify(name: 'Joe', age: 50, hairColor: Color.blonde);
      expect(
        instanceA.toString(),
        'ComplexStringify(null, null, null, null)',
      );
      expect(
        instanceB.toString(),
        'ComplexStringify(Bob, null, Color.black, null)',
      );
      expect(
        instanceC.toString(),
        'ComplexStringify(Joe, 50, Color.blonde, null)',
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

  group('Iterable Equatable', () {
    test('should be equal when different instances have same values', () {
      final instanceA = IterableWithFlag(flag: true, list: [1, 2]);
      final instanceB = IterableWithFlag(flag: true, list: [1, 2]);

      expect(instanceA == instanceB, isTrue);
    });

    test('should not be equal when different instances have different values',
        () {
      final instanceA = IterableWithFlag(flag: false, list: [1, 2]);
      final instanceB = IterableWithFlag(flag: true, list: [1, 2]);

      expect(instanceA == instanceB, isFalse);
    });

    test('wrapper should be equal when different instances have same values',
        () {
      final instanceA = SimpleEquatable(
        IterableWithFlag(flag: true, list: [1, 2]),
      );
      final instanceB = SimpleEquatable(
        IterableWithFlag(flag: true, list: [1, 2]),
      );

      expect(instanceA == instanceB, isTrue);
    });

    test(
        'wrapper should not be equal '
        'when different instances have different values', () {
      final instanceA = SimpleEquatable(
        IterableWithFlag(flag: true, list: [1, 2]),
      );
      final instanceB = SimpleEquatable(
        IterableWithFlag(flag: false, list: [1, 2]),
      );

      expect(instanceA == instanceB, isFalse);
    });
  });
}
