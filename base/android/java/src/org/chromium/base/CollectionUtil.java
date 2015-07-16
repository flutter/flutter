// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;

/**
 * Functions used for easier initialization of Java collections. Inspired by
 * functionality in com.google.common.collect in Guava but cherry-picked to
 * bare-minimum functionality to avoid bloat. (http://crbug.com/272790 provides
 * further details)
 */
public final class CollectionUtil {
    private CollectionUtil() {}

    @SafeVarargs
    public static <E> HashSet<E> newHashSet(E... elements) {
        HashSet<E> set = new HashSet<E>(elements.length);
        Collections.addAll(set, elements);
        return set;
    }

    @SafeVarargs
    public static <E> ArrayList<E> newArrayList(E... elements) {
        ArrayList<E> list = new ArrayList<E>(elements.length);
        Collections.addAll(list, elements);
        return list;
    }

    public static <E> ArrayList<E> newArrayList(Iterable<E> iterable) {
        ArrayList<E> list = new ArrayList<E>();
        for (E element : iterable) {
            list.add(element);
        }
        return list;
    }
}