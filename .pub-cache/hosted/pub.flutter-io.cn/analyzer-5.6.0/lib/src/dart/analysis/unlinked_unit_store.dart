// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/unlinked_data.dart';

abstract class UnlinkedUnitStore {
  void clear();
  AnalysisDriverUnlinkedUnit? get(String key);
  void put(String key, AnalysisDriverUnlinkedUnit value);
  void release(String key);
}

class UnlinkedUnitStoreImpl implements UnlinkedUnitStore {
  // TODO(jensj): Could we use finalizers and automatically clean up
  // this map?
  final Map<String, _UnlinkedUnitStoreData> _deserializedUnlinked = {};

  @override
  void clear() {
    _deserializedUnlinked.clear();
  }

  @override
  AnalysisDriverUnlinkedUnit? get(String key) {
    var lookup = _deserializedUnlinked[key];
    if (lookup != null) {
      lookup.usageCount++;
      return lookup.value.target;
    }
    return null;
  }

  @override
  void put(String key, AnalysisDriverUnlinkedUnit value) {
    _deserializedUnlinked[key] = _UnlinkedUnitStoreData(WeakReference(value));
  }

  @override
  void release(String key) {
    var lookup = _deserializedUnlinked[key];
    if (lookup != null) {
      lookup.usageCount--;
      if (lookup.usageCount <= 0) {
        _deserializedUnlinked.remove(key);
      }
    }
  }
}

class _UnlinkedUnitStoreData {
  final WeakReference<AnalysisDriverUnlinkedUnit> value;
  int usageCount = 1;

  _UnlinkedUnitStoreData(this.value);
}
