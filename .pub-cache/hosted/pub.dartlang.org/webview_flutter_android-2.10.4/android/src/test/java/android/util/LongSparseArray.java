// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package android.util;

import java.util.HashMap;

// Creates an implementation of LongSparseArray that can be used with unittests and the JVM.
// Typically android.util.LongSparseArray does nothing when not used with an Android environment.
public class LongSparseArray<E> {
  private final HashMap<Long, E> mHashMap;

  public LongSparseArray() {
    mHashMap = new HashMap<>();
  }

  public void append(long key, E value) {
    mHashMap.put(key, value);
  }

  public E get(long key) {
    return mHashMap.get(key);
  }

  public void remove(long key) {
    mHashMap.remove(key);
  }
}
