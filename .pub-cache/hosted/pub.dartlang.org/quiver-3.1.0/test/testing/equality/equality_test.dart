// Copyright 2014 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the 'License');
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an 'AS IS' BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

library quiver.testing.util.equalstester;

import 'package:quiver/testing/src/equality/equality.dart';
import 'package:test/test.dart';

void main() {
  group('expectEquals', () {
    late _ValidTestObject reference;
    late _ValidTestObject equalObject1;
    late _ValidTestObject equalObject2;
    late _ValidTestObject notEqualObject1;

    setUp(() {
      reference = _ValidTestObject(1, 2);
      equalObject1 = _ValidTestObject(1, 2);
      equalObject2 = _ValidTestObject(1, 2);
      notEqualObject1 = _ValidTestObject(0, 2);
    });

    test('Test null reference yields error', () {
      try {
        expect(null, areEqualityGroups);
        fail('Should fail with null reference');
      } catch (e) {
        expect(e.toString(), contains('Equality Group must not be null'));
      }
    });

    test('Test null group name yields error', () {
      try {
        expect({
          'null': [reference],
          null: [reference]
        }, areEqualityGroups);
        fail('Should fail with null group name');
      } catch (e) {
        expect(e.toString(), contains('Group name must not be null'));
      }
    });

    test('Test null group yields error', () {
      try {
        expect({'bad group': null}, areEqualityGroups);
        fail('Should fail with null group');
      } catch (e) {
        expect(e.toString(), contains('Group must not be null'));
      }
    });

    test('Test after adding multiple instances at once with a null', () {
      try {
        expect({
          'bad group': <dynamic>[reference, equalObject1, null]
        }, areEqualityGroups);
        fail('Should fail with null group');
      } catch (e) {
        expect(
            e.toString(),
            contains("$reference [group 'bad group', item 1]"
                " must be equal to null [group 'bad group', item 3]"));
      }
    });

    test('Test adding non-equal objects only in single group.', () {
      try {
        expect({
          'not equal': [equalObject1, notEqualObject1]
        }, areEqualityGroups);
        fail('Should get not equal to equal object error');
      } catch (e) {
        expect(
            e.toString(),
            contains("$equalObject1 [group 'not equal', item"
                " 1] must be equal to $notEqualObject1 [group 'not equal'"
                ', item 2]'));
      }
    });

    test(
        'Test with no equals or not equals objects. This checks'
        ' proper handling of null, incompatible class and reflexive tests', () {
      expect({
        'single object': [reference]
      }, areEqualityGroups);
    });

    test(
        'Test after populating equal objects. This checks proper'
        ' handling of equality and verifies hashCode for valid objects', () {
      expect({
        'all equal': [reference, equalObject1, equalObject2]
      }, areEqualityGroups);
    });

    test('Test proper handling of case where an object is not equal to itself',
        () {
      Object obj = _NonReflexiveObject();
      try {
        expect({
          'non-reflexive': [obj]
        }, areEqualityGroups);
        fail('Should get non-reflexive error');
      } catch (e) {
        expect(e.toString(), contains('$obj must be equal to itself'));
      }
    });

    test('Test proper handling of case where hashcode is not idempotent', () {
      Object obj = _InconsistentHashCodeObject(1, 2);
      try {
        expect({
          'non-reflexive': [obj]
        }, areEqualityGroups);
        fail('Should get non-reflexive error');
      } catch (e) {
        expect(
            e.toString(),
            contains(
                'the implementation of hashCode of $obj must be idempotent'));
      }
    });

    test(
        'Test proper handling where an object incorrectly tests for an '
        'incompatible class', () {
      Object obj = _InvalidEqualsIncompatibleClassObject();
      try {
        expect({
          'equals method broken': [obj]
        }, areEqualityGroups);
        fail('Should get equal to incompatible class error');
      } catch (e) {
        expect(
            e.toString(),
            contains('$obj must not be equal to an '
                'arbitrary object of another class'));
      }
    });

    test(
        'Test proper handling where an object is not equal to one the user '
        'has said should be equal', () {
      try {
        expect({
          'non-equal': [reference, notEqualObject1]
        }, areEqualityGroups);
        fail('Should get not equal to equal object error');
      } catch (e) {
        expect(
            e.toString(), contains("$reference [group 'non-equal', item 1]"));
        expect(e.toString(),
            contains("$notEqualObject1 [group 'non-equal', item 2]"));
      }
    });

    test(
        'Test for an invalid hashCode method, i.e., one that returns '
        'different value for objects that are equal according to the equals '
        'method', () {
      Object a = _InvalidHashCodeObject(1, 2);
      Object b = _InvalidHashCodeObject(1, 2);
      try {
        expect({
          'invalid hashcode': [a, b]
        }, areEqualityGroups);
        fail('Should get invalid hashCode error');
      } catch (e) {
        expect(
            e.toString(),
            contains('the hashCode (${a.hashCode}) of $a'
                " [group 'invalid hashcode', item 1] must be equal to the"
                ' hashCode (${b.hashCode}) of $b'));
      }
    });

    test('Symmetry Broken', () {
      try {
        expect({
          'broken symmetry': [
            named('foo')..addPeers(['bar']),
            named('bar')
          ]
        }, areEqualityGroups);
        fail('should fail because symmetry is broken');
      } catch (e) {
        expect(
            e.toString(),
            contains("bar [group 'broken symmetry', item 2] "
                "must be equal to foo [group 'broken symmetry', item 1]"));
      }
    });

    test('Transitivity Broken In EqualityGroup', () {
      try {
        expect({
          'transitivity broken': [
            named('foo')..addPeers(['bar', 'baz']),
            named('bar')..addPeers(['foo']),
            named('baz')..addPeers(['foo'])
          ]
        }, areEqualityGroups);
        fail('should fail because transitivity is broken');
      } catch (e) {
        expect(
            e.toString(),
            contains("bar [group 'transitivity broken', "
                "item 2] must be equal to baz [group 'transitivity "
                "broken', item 3]"));
      }
    });

    test('Unequal Objects In EqualityGroup', () {
      try {
        expect({
          'unequal objects': [named('foo'), named('bar')]
        }, areEqualityGroups);
        fail('should fail because of unequal objects in the same equality '
            'group');
      } catch (e) {
        expect(
            e.toString(),
            contains("foo [group 'unequal objects', item 1] "
                "must be equal to bar [group 'unequal objects', item 2]"));
      }
    });

    test('Transitivity Broken Across EqualityGroups', () {
      try {
        expect({
          'transitivity one': [
            named('foo')..addPeers(['bar']),
            named('bar')..addPeers(['foo', 'x'])
          ],
          'transitivity two': [
            named('baz')..addPeers(['x']),
            named('x')..addPeers(['baz', 'bar'])
          ]
        }, areEqualityGroups);
        fail('should fail because transitivity is broken');
      } catch (e) {
        expect(
            e.toString(),
            contains("bar [group 'transitivity one', item 2]"
                " must not be equal to x [group 'transitivity two',"
                ' item 2]'));
      }
    });

    test('EqualityGroups', () {
      expect({
        'valid groups one': [
          named('foo')..addPeers(['bar']),
          named('bar')..addPeers(['foo'])
        ],
        'valid groups two': [named('baz'), named('baz')]
      }, areEqualityGroups);
    });
  });
}

/// Test class that violates reflexitivity.  It is not equal to itself.
class _NonReflexiveObject {
  @override
  bool operator ==(Object o) => false;

  @override
  int get hashCode => 0;
}

/// Test class with valid equals and hashCode methods. Testers created
/// with instances of this class should always pass.
class _ValidTestObject {
  _ValidTestObject(this.aspect1, this.aspect2);

  int aspect1;
  int aspect2;

  @override
  bool operator ==(Object o) {
    if (!(o is _ValidTestObject)) {
      return false;
    }
    final _ValidTestObject other = o;
    if (aspect1 != other.aspect1) {
      return false;
    }
    if (aspect2 != other.aspect2) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode {
    int result = 17;
    result = 37 * result + aspect1;
    result = 37 * result + aspect2;
    return result;
  }
}

///Test class that returns true even if the test object is of the wrong class.
class _InvalidEqualsIncompatibleClassObject {
  @override
  bool operator ==(Object o) {
    return true;
  }

  @override
  int get hashCode => 0;
}

/// Test class with inconsistent hashCode method.
class _InconsistentHashCodeObject {
  _InconsistentHashCodeObject(this._aspect1, this._aspect2);

  final int _aspect1;
  final int _aspect2;
  int _hashCode = 0;

  @override
  int get hashCode => _hashCode++;

  @override
  bool operator ==(Object o) {
    if (!(o is _InconsistentHashCodeObject)) {
      return false;
    }
    final _InconsistentHashCodeObject other = o;
    if (_aspect1 != other._aspect1) return false;
    if (_aspect2 != other._aspect2) return false;
    return true;
  }
}

/// Test class with invalid hashCode method.
class _InvalidHashCodeObject {
  _InvalidHashCodeObject(this._aspect1, this._aspect2);

  static int hashCodeSource = 0;
  final int _aspect1;
  final int _aspect2;
  final int _hashCode = hashCodeSource++;

  @override
  int get hashCode => _hashCode;

  @override
  bool operator ==(Object o) {
    if (!(o is _InvalidHashCodeObject)) {
      return false;
    }
    final _InvalidHashCodeObject other = o;
    if (_aspect1 != other._aspect1) return false;
    if (_aspect2 != other._aspect2) return false;
    return true;
  }
}

_NamedObject named(String name) => _NamedObject(name);

class _NamedObject {
  _NamedObject(this.name);

  final Set<String> peerNames = Set();
  final String name;

  void addPeers(List<String> names) {
    peerNames.addAll(names);
  }

  @override
  bool operator ==(Object obj) {
    if (obj is _NamedObject) {
      _NamedObject that = obj;
      return name == that.name || peerNames.contains(that.name);
    }
    return false;
  }

  @override
  int get hashCode => 0;

  @override
  String toString() => name;
}
