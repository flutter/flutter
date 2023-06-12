// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:isolate/isolate_runner.dart';
import 'package:isolate/registry.dart';
import 'package:test/test.dart';

const _ms = Duration(milliseconds: 1);

void main() {
  group('lookup', testLookup);
  group('AddLookup', testAddLookup);
  group('AddRemoveTags', testAddRemoveTags);
  group('Remove', testRemove);
  group('CrossIsolate', testCrossIsolate);
  group('Timeout', testTimeout);
  group('MultiRegistry', testMultiRegistry);
  group('ObjectsAndTags', testObjectsAndTags);
}

abstract class Oddity {
  static const int even = 0;
  static const int odd = 1;
}

Future<List> waitAll(int n, Future Function(int n) action) {
  return Future.wait(Iterable.generate(n, action));
}

void testLookup() {
  test('All', () {
    var regman = RegistryManager();
    var registry = regman.registry;
    return waitAll(10, (i) {
      var element = Element(i);
      var tag = i.isEven ? Oddity.even : Oddity.odd;
      return registry.add(element, tags: [tag]);
    }).then((_) {
      return registry.lookup();
    }).then<void>((all) {
      expect(all.length, 10);
      expect(all.map((v) => v.id).toList()..sort(),
          [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
    }).whenComplete(regman.close);
  });

  test('Odd', () {
    var regman = RegistryManager();
    var registry = regman.registry;
    return waitAll(10, (i) {
      var element = Element(i);
      var tag = i.isEven ? Oddity.even : Oddity.odd;
      return registry.add(element, tags: [tag]);
    }).then((_) {
      return registry.lookup(tags: [Oddity.odd]);
    }).then<void>((all) {
      expect(all.length, 5);
      expect(all.map((v) => v.id).toList()..sort(), [1, 3, 5, 7, 9]);
    }).whenComplete(regman.close);
  });

  test('Max', () {
    var regman = RegistryManager();
    var registry = regman.registry;
    return waitAll(10, (i) {
      var element = Element(i);
      var tag = i.isEven ? Oddity.even : Oddity.odd;
      return registry.add(element, tags: [tag]);
    }).then((_) {
      return registry.lookup(max: 5);
    }).then<void>((all) {
      expect(all.length, 5);
    }).whenComplete(regman.close);
  });

  test('MultiTag', () {
    var regman = RegistryManager();
    var registry = regman.registry;
    return waitAll(25, (i) {
      var element = Element(i);
      // Collect all numbers dividing i.
      var tags = [i];
      for (var j = 2; j < 25; j++) {
        if (i % j == 0) tags.add(j);
      }
      return registry.add(element, tags: tags);
    }).then((_) {
      return registry.lookup(tags: [2, 3]);
    }).then<void>((all) {
      expect(all.length, 5);
      expect(all.map((v) => v.id).toList()..sort(), [0, 6, 12, 18, 24]);
    }).whenComplete(regman.close);
  });

  test('MultiTagMax', () {
    var regman = RegistryManager();
    var registry = regman.registry;
    return waitAll(25, (i) {
      var element = Element(i);
      // Collect all numbers dividing i.
      var tags = [i];
      for (var j = 2; j < 25; j++) {
        if (i % j == 0) tags.add(j);
      }
      return registry.add(element, tags: tags);
    }).then((_) {
      return registry.lookup(tags: [2, 3], max: 3);
    }).then<void>((all) {
      expect(all.length, 3);
      expect(all.every((v) => (v.id % 6) == 0), isTrue);
    }).whenComplete(regman.close);
  });
}

void testAddLookup() {
  test('Add-lookup-identical', () {
    var regman = RegistryManager();
    var registry = regman.registry;
    var object = Object();
    return registry.add(object).then((_) {
      return registry.lookup();
    }).then<void>((entries) {
      expect(entries, hasLength(1));
      expect(entries.first, same(object));
    }).whenComplete(regman.close);
  });

  test('Add-multiple-identical', () {
    var regman = RegistryManager();
    var registry = regman.registry;
    var object1 = Object();
    var object2 = Object();
    var object3 = Object();
    var objects = [object1, object2, object3];
    return Future.wait(objects.map(registry.add)).then((_) {
      return registry.lookup();
    }).then<void>((entries) {
      expect(entries, hasLength(3));
      for (var entry in entries) {
        expect(entry, isIn(objects));
      }
    }).whenComplete(regman.close);
  });

  test('Add-twice', () {
    var regman = RegistryManager();
    var registry = regman.registry;
    var object = Object();
    return registry.add(object).then((_) {
      return registry.add(object);
    }).then<void>((_) {
      fail('Unreachable');
    }, onError: (e, s) {
      expect(e, isStateError);
    }).whenComplete(regman.close);
  });

  test('Add-lookup-add-lookup', () {
    var regman = RegistryManager();
    var registry = regman.registry;
    var object = Object();
    var object2 = Object();
    return registry.add(object).then((_) {
      return registry.lookup();
    }).then((entries) {
      expect(entries, hasLength(1));
      expect(entries.first, same(object));
      return registry.add(object2);
    }).then((_) {
      return registry.lookup();
    }).then<void>((entries) {
      expect(entries, hasLength(2));
      var entry1 = entries.first;
      var entry2 = entries.last;
      if (object == entry1) {
        expect(entry2, same(object2));
      } else {
        expect(entry1, same(object));
      }
    }).whenComplete(regman.close);
  });

  test('lookup-add-lookup', () {
    var regman = RegistryManager();
    var registry = regman.registry;
    var object = Object();
    return registry.lookup().then((entries) {
      expect(entries, isEmpty);
      return registry.add(object);
    }).then((_) {
      return registry.lookup();
    }).then<void>((entries) {
      expect(entries, hasLength(1));
      expect(entries.first, same(object));
    }).whenComplete(regman.close);
  });

  test('Add-multiple-tags', () {
    var regman = RegistryManager();
    var registry = regman.registry;
    var object1 = Object();
    var object2 = Object();
    var object3 = Object();
    return registry.add(object1, tags: [1, 3, 5, 7]).then((_) {
      return registry.add(object2, tags: [2, 3, 6, 7]);
    }).then((_) {
      return registry.add(object3, tags: [4, 5, 6, 7]);
    }).then((_) {
      return registry.lookup(tags: [3]);
    }).then<void>((entries) {
      expect(entries, hasLength(2));
      expect(entries.first == object1 || entries.last == object1, isTrue);
      expect(entries.first == object2 || entries.last == object2, isTrue);
    }).then((_) {
      return registry.lookup(tags: [2]);
    }).then<void>((entries) {
      expect(entries, hasLength(1));
      expect(entries.first, same(object2));
    }).then((_) {
      return registry.lookup(tags: [3, 6]);
    }).then<void>((entries) {
      expect(entries, hasLength(1));
      expect(entries.first, same(object2));
    }).whenComplete(regman.close);
  });
}

void testRemove() {
  test('Add-remove', () {
    var regman = RegistryManager();
    var registry = regman.registry;
    var object = Object();
    return registry.add(object).then((removeCapability) {
      return registry.lookup().then((entries) {
        expect(entries, hasLength(1));
        expect(entries.first, same(object));
        return registry.remove(object, removeCapability);
      });
    }).then((removeSuccess) {
      expect(removeSuccess, isTrue);
      return registry.lookup();
    }).then<void>((entries) {
      expect(entries, isEmpty);
    }).whenComplete(regman.close);
  });

  test('Add-remove-fail', () {
    var regman = RegistryManager();
    var registry = regman.registry;
    var object = Object();
    return registry.add(object).then((removeCapability) {
      return registry.lookup().then((entries) {
        expect(entries, hasLength(1));
        expect(entries.first, same(object));
        return registry.remove(object, Capability());
      });
    }).then<void>((removeSuccess) {
      expect(removeSuccess, isFalse);
    }).whenComplete(regman.close);
  });
}

void testAddRemoveTags() {
  test('Add-remove-tag', () {
    var regman = RegistryManager();
    var registry = regman.registry;
    var object = Object();
    return registry.add(object).then((removeCapability) {
      return registry.lookup(tags: ['x']);
    }).then((entries) {
      expect(entries, isEmpty);
      return registry.addTags([object], ['x']);
    }).then((_) {
      return registry.lookup(tags: ['x']);
    }).then((entries) {
      expect(entries, hasLength(1));
      expect(entries.first, same(object));
      return registry.removeTags([object], ['x']);
    }).then((_) {
      return registry.lookup(tags: ['x']);
    }).then<void>((entries) {
      expect(entries, isEmpty);
    }).whenComplete(regman.close);
  });

  test('Tag-twice', () {
    var regman = RegistryManager();
    var registry = regman.registry;
    var object = Object();
    return registry.add(object, tags: ['x']).then((removeCapability) {
      return registry.lookup(tags: ['x']);
    }).then((entries) {
      expect(entries, hasLength(1));
      expect(entries.first, same(object));
      // Adding the same tag twice is allowed, but does nothing.
      return registry.addTags([object], ['x']);
    }).then((_) {
      return registry.lookup(tags: ['x']);
    }).then((entries) {
      expect(entries, hasLength(1));
      expect(entries.first, same(object));
      // Removing the tag once is enough to remove it.
      return registry.removeTags([object], ['x']);
    }).then((_) {
      return registry.lookup(tags: ['x']);
    }).then((entries) {
      expect(entries, isEmpty);
    }).whenComplete(regman.close);
  });

  test('Add-remove-multiple', () {
    var regman = RegistryManager();
    var registry = regman.registry;
    var object1 = Object();
    var object2 = Object();
    var object3 = Object();
    var objects = [object1, object2, object3];
    return Future.wait(objects.map(registry.add)).then((_) {
      return registry.addTags([object1, object2], ['x', 'y']);
    }).then((_) {
      return registry.addTags([object1, object3], ['z', 'w']);
    }).then((_) {
      return registry.lookup(tags: ['x', 'z']);
    }).then((entries) {
      expect(entries, hasLength(1));
      expect(entries.first, same(object1));
      return registry.removeTags([object1, object2], ['x', 'z']);
    }).then((_) {
      return registry.lookup(tags: ['z']);
    }).then((entries) {
      expect(entries, hasLength(1));
      expect(entries.first, same(object3));
    }).whenComplete(regman.close);
  });

  test('Remove-wrong-object', () {
    var regman = RegistryManager();
    var registry = regman.registry;
    expect(() => registry.removeTags([Object()], ['x']), throwsStateError);
    regman.close();
  });
}

var _regmen = {};

Registry createRegMan(id) {
  var regman = RegistryManager();
  _regmen[id] = regman;
  return regman.registry;
}

void closeRegMan(id) {
  _regmen.remove(id).close();
}

void testCrossIsolate() {
  var object = Object();
  test('regman-other-isolate', () {
    // Add, lookup and remove object in other isolate.
    return IsolateRunner.spawn().then((isolate) {
      isolate.run(createRegMan, 1).then((registry) {
        return registry.add(object, tags: ['a', 'b']).then((removeCapability) {
          return registry.lookup(tags: ['a']).then((entries) {
            expect(entries, hasLength(1));
            expect(entries.first, same(object));
            return registry.remove(entries.first, removeCapability);
          }).then<void>((removeSuccess) {
            expect(removeSuccess, isTrue);
          });
        });
      }).whenComplete(() {
        return isolate.run(closeRegMan, 1);
      }).whenComplete(() {
        return isolate.close();
      });
    });
  });
}

void testTimeout() {
  test('Timeout-add', () {
    var regman = RegistryManager(timeout: _ms * 500);
    var registry = regman.registry;
    regman.close();
    return registry.add(Object()).then<void>((_) {
      fail('unreachable');
    }, onError: (e, s) {
      expect(e is TimeoutException, isTrue);
    });
  });

  test('Timeout-remove', () {
    var regman = RegistryManager(timeout: _ms * 500);
    var registry = regman.registry;
    var object = Object();
    return registry.add(object).then((rc) {
      regman.close();
      return registry.remove(object, rc).then<void>((_) {
        fail('unreachable');
      }, onError: (e, s) {
        expect(e is TimeoutException, isTrue);
      });
    });
  });

  test('Timeout-addTags', () {
    var regman = RegistryManager(timeout: _ms * 500);
    var registry = regman.registry;
    var object = Object();
    return registry.add(object).then((rc) {
      regman.close();
      return registry.addTags([object], ['x']).then<void>((_) {
        fail('unreachable');
      }, onError: (e, s) {
        expect(e is TimeoutException, isTrue);
      });
    });
  });

  test('Timeout-removeTags', () {
    var regman = RegistryManager(timeout: _ms * 500);
    var registry = regman.registry;
    var object = Object();
    return registry.add(object).then((rc) {
      regman.close();
      return registry.removeTags([object], ['x']).then<void>((_) {
        fail('unreachable');
      }, onError: (e, s) {
        expect(e is TimeoutException, isTrue);
      });
    });
  });

  test('Timeout-lookup', () {
    var regman = RegistryManager(timeout: _ms * 500);
    var registry = regman.registry;
    regman.close();
    registry.lookup().then<void>((_) {
      fail('unreachable');
    }, onError: (e, s) {
      expect(e is TimeoutException, isTrue);
    });
  });
}

void testMultiRegistry() {
  test('dual-registry', () {
    var regman = RegistryManager();
    var registry1 = regman.registry;
    var registry2 = regman.registry;
    var l1 = ['x'];
    dynamic l2;
    return registry1.add(l1, tags: ['y']).then((removeCapability) {
      return registry2.lookup().then((entries) {
        expect(entries, hasLength(1));
        l2 = entries.first;
        expect(l2, equals(l1));
        // The object for registry2 is not identical the one for registry1.
        expect(!identical(l1, l2), isTrue);
        // Removing the registry1 object through registry2 doesn't work.
        return registry2.remove(l1, removeCapability);
      }).then((removeSuccess) {
        expect(removeSuccess, isFalse);
        return registry2.remove(l2, removeCapability);
      }).then((removeSuccess) {
        expect(removeSuccess, isTrue);
        return registry1.lookup();
      }).then<void>((entries) {
        expect(entries, isEmpty);
      });
    }).whenComplete(regman.close);
  });
}

void testObjectsAndTags() {
  void testObject(object) {
    var name = 'Transfer-${object.runtimeType}';
    test(name, () {
      var regman = RegistryManager();
      var registry1 = regman.registry;
      var registry2 = regman.registry;
      return registry1.add(object, tags: [object]).then((removeCapability) {
        return registry2.lookup().then((entries) {
          expect(entries, hasLength(1));
          expect(entries.first, equals(object));
          return registry2.lookup(tags: [object]);
        }).then((entries) {
          expect(entries, hasLength(1));
          expect(entries.first, equals(object));
          return registry2.removeTags([entries.first], [object]);
        }).then((_) {
          return registry2.lookup();
        }).then((entries) {
          expect(entries, hasLength(1));
          expect(entries.first, equals(object));
          return registry2.remove(entries.first, removeCapability);
        }).then((removeSuccess) {
          expect(removeSuccess, isTrue);
          return registry2.lookup();
        }).then<void>((entries) {
          expect(entries, isEmpty);
        });
      }).whenComplete(regman.close);
    });
  }

  // Test objects that are sendable between equivalent isolates and
  // that has an operator== that works after cloning (for use as tags).
  testObject(42);
  testObject(3.14);
  testObject('string');
  testObject(true);
  testObject(null);
  testObject(Element(42));
  testObject(#symbol);
  testObject(#_privateSymbol);
  testObject(Capability());
  testObject(topLevelFunction);
}

class Element {
  final int id;

  Element(this.id);

  @override
  int get hashCode => id;

  @override
  bool operator ==(Object other) => other is Element && id == other.id;
}

void topLevelFunction() {}
