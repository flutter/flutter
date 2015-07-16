// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo.system;


/**
 * A pair of object.
 *
 * @param <F> Type of the first element.
 * @param <S> Type of the second element.
 */
public class Pair<F, S> {

    public final F first;
    public final S second;

    /**
     * Dedicated constructor.
     *
     * @param first the first element of the pair.
     * @param second the second element of the pair.
     */
    public Pair(F first, S second) {
        this.first = first;
        this.second = second;
    }

    /**
     * equals() that handles null values.
     */
    private boolean equals(Object o1, Object o2) {
        return o1 == null ? o2 == null : o1.equals(o2);
    }

    /**
     * @see Object#equals(Object)
     */
    @Override
    public boolean equals(Object o) {
        if (!(o instanceof Pair)) {
            return false;
        }
        Pair<?, ?> p = (Pair<?, ?>) o;
        return equals(first, p.first) && equals(second, p.second);
    }

    /**
     * @see Object#hashCode()
     */
    @Override
    public int hashCode() {
        return (first == null ? 0 : first.hashCode()) ^ (second == null ? 0 : second.hashCode());
    }

    /**
     * Helper method for creating a pair.
     *
     * @param a the first element of the pair.
     * @param b the second element of the pair.
     * @return the pair containing a and b.
     */
    public static <A, B> Pair<A, B> create(A a, B b) {
        return new Pair<A, B>(a, b);
    }
}
