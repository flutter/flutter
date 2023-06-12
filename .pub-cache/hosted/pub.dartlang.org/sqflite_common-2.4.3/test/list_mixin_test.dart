import 'dart:collection';

import 'package:test/test.dart';

class MyList1 extends Object with ListMixin<Map<String, Object?>> {
  MyList1.from(this._list);

  final List<dynamic> _list;

  @override
  Map<String, Object?> operator [](int index) {
    final value = _list[index] as Map<dynamic, dynamic>;
    return value.cast<String, Object?>();
  }

  @override
  void operator []=(int index, Map<String, Object?> value) {
    throw 'read-only';
  }

  @override
  set length(int newLength) {
    throw 'read-only';
  }

  @override
  int get length => _list.length;
}

class MyList2 extends ListBase<Map<String, Object?>> {
  MyList2.from(this._list);

  final List<dynamic> _list;

  @override
  Map<String, Object?> operator [](int index) {
    final value = _list[index] as Map<dynamic, dynamic>;
    return value.cast<String, Object?>();
  }

  @override
  void operator []=(int index, Map<String, Object?> value) {
    throw 'read-only';
  }

  @override
  set length(int newLength) {
    throw 'read-only';
  }

  @override
  int get length => _list.length;
}

void main() {
  group('mixin', () {
    // This fails on beta 1, should work now
    test('ListMixin', () {
      final raw = <dynamic>[
        <dynamic, dynamic>{'col': 1}
      ];
      final rows = MyList1.from(raw);
      expect(rows, raw);
    });

    test('ListBase', () {
      final raw = <dynamic>[
        <dynamic, dynamic>{'col': 1}
      ];
      final rows = MyList2.from(raw);
      expect(rows, raw);
    });
  });
}
