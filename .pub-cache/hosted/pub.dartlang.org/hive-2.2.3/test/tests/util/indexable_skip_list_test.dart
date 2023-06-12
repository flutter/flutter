import 'dart:math';

import 'package:hive/src/util/indexable_skip_list.dart';
import 'package:test/test.dart';

void main() {
  group('IndexableSkipList', () {
    List<int> getRandomList() {
      var rand = Random();
      var data = List.generate(1000, (i) => i);
      data.addAll(List.generate(500, (i) => rand.nextInt(1000)));
      data.addAll(List.generate(250, (i) => 1000 - i % 50));
      data.addAll(List.generate(250, (i) => i));
      data.shuffle();
      return data;
    }

    void checkList(IndexableSkipList list, List<Comparable> keys) {
      var sortedKeys = keys.toSet().toList()..sort();
      expect(list.keys, sortedKeys);
      for (var n = 0; n < sortedKeys.length; n++) {
        var key = sortedKeys[n];
        expect(list.get(key), '$key');
        expect(list.getAt(n), '$key');
      }
    }

    test('.insert() puts value at the correct position', () {
      var list = IndexableSkipList(Comparable.compare);
      var data = getRandomList();

      for (var i = 0; i < data.length; i++) {
        list.insert(data[i], '${data[i]}');
        var alreadyAdded = data.sublist(0, i + 1);
        checkList(list, alreadyAdded);
      }
    });

    test('.delete() removes key', () {
      var list = IndexableSkipList(Comparable.compare);
      var data = getRandomList();
      for (var key in data) {
        list.insert(key, '$key');
      }

      var keys = data.toSet().toList()..shuffle();
      while (keys.isNotEmpty) {
        var key = keys.first;
        expect(list.delete(key), '$key');
        keys.remove(key);
        checkList(list, keys);
      }
    });
  });
}
