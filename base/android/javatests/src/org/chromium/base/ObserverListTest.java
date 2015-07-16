// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base;

import android.test.InstrumentationTestCase;
import android.test.suitebuilder.annotation.SmallTest;

import org.chromium.base.test.util.Feature;

import java.util.Iterator;
import java.util.NoSuchElementException;

/**
 * Tests for (@link ObserverList}.
 */
public class ObserverListTest extends InstrumentationTestCase {
    interface Observer {
        void observe(int x);
    }

    private static class Foo implements Observer {
        private final int mScalar;
        private int mTotal = 0;

        Foo(int scalar) {
            mScalar = scalar;
        }

        @Override
        public void observe(int x) {
            mTotal += x * mScalar;
        }
    }

    /**
     * An observer which add a given Observer object to the list when observe is called.
     */
    private static class FooAdder implements Observer {
        private final ObserverList<Observer> mList;
        private final Observer mLucky;

        FooAdder(ObserverList<Observer> list, Observer oblivious) {
            mList = list;
            mLucky = oblivious;
        }

        @Override
        public void observe(int x) {
            mList.addObserver(mLucky);
        }
    }

    /**
     * An observer which removes a given Observer object from the list when observe is called.
     */
    private static class FooRemover implements Observer {
        private final ObserverList<Observer> mList;
        private final Observer mDoomed;

        FooRemover(ObserverList<Observer> list, Observer innocent) {
            mList = list;
            mDoomed = innocent;
        }

        @Override
        public void observe(int x) {
            mList.removeObserver(mDoomed);
        }
    }

    private static <T> int getSizeOfIterable(Iterable<T> iterable) {
        int num = 0;
        for (T el : iterable) num++;
        return num;
    }

    @SmallTest
    @Feature({"Android-AppBase"})
    public void testRemoveWhileIteration() {
        ObserverList<Observer> observerList = new ObserverList<Observer>();
        Foo a = new Foo(1);
        Foo b = new Foo(-1);
        Foo c = new Foo(1);
        Foo d = new Foo(-1);
        Foo e = new Foo(-1);
        FooRemover evil = new FooRemover(observerList, c);

        observerList.addObserver(a);
        observerList.addObserver(b);

        for (Observer obs : observerList) obs.observe(10);

        // Removing an observer not in the list should do nothing.
        observerList.removeObserver(e);

        observerList.addObserver(evil);
        observerList.addObserver(c);
        observerList.addObserver(d);

        for (Observer obs : observerList) obs.observe(10);

        // observe should be called twice on a.
        assertEquals(20, a.mTotal);
        // observe should be called twice on b.
        assertEquals(-20, b.mTotal);
        // evil removed c from the observerList before it got any callbacks.
        assertEquals(0, c.mTotal);
        // observe should be called once on d.
        assertEquals(-10, d.mTotal);
        // e was never added to the list, observe should not be called.
        assertEquals(0, e.mTotal);
    }

    @SmallTest
    @Feature({"Android-AppBase"})
    public void testAddWhileIteration() {
        ObserverList<Observer> observerList = new ObserverList<Observer>();
        Foo a = new Foo(1);
        Foo b = new Foo(-1);
        Foo c = new Foo(1);
        FooAdder evil = new FooAdder(observerList, c);

        observerList.addObserver(evil);
        observerList.addObserver(a);
        observerList.addObserver(b);

        for (Observer obs : observerList) obs.observe(10);

        assertTrue(observerList.hasObserver(c));
        assertEquals(10, a.mTotal);
        assertEquals(-10, b.mTotal);
        assertEquals(0, c.mTotal);
    }

    @SmallTest
    @Feature({"Android-AppBase"})
    public void testIterator() {
        ObserverList<Integer> observerList = new ObserverList<Integer>();
        observerList.addObserver(5);
        observerList.addObserver(10);
        observerList.addObserver(15);
        assertEquals(3, getSizeOfIterable(observerList));

        observerList.removeObserver(10);
        assertEquals(2, getSizeOfIterable(observerList));

        Iterator<Integer> it = observerList.iterator();
        assertTrue(it.hasNext());
        assertTrue(5 == it.next());
        assertTrue(it.hasNext());
        assertTrue(15 == it.next());
        assertFalse(it.hasNext());

        boolean removeExceptionThrown = false;
        try {
            it.remove();
            fail("Expecting UnsupportedOperationException to be thrown here.");
        } catch (UnsupportedOperationException e) {
            removeExceptionThrown = true;
        }
        assertTrue(removeExceptionThrown);
        assertEquals(2, getSizeOfIterable(observerList));

        boolean noElementExceptionThrown = false;
        try {
            it.next();
            fail("Expecting NoSuchElementException to be thrown here.");
        } catch (NoSuchElementException e) {
            noElementExceptionThrown = true;
        }
        assertTrue(noElementExceptionThrown);
    }

    @SmallTest
    @Feature({"Android-AppBase"})
    public void testRewindableIterator() {
        ObserverList<Integer> observerList = new ObserverList<Integer>();
        observerList.addObserver(5);
        observerList.addObserver(10);
        observerList.addObserver(15);
        assertEquals(3, getSizeOfIterable(observerList));

        ObserverList.RewindableIterator<Integer> it = observerList.rewindableIterator();
        assertTrue(it.hasNext());
        assertTrue(5 == it.next());
        assertTrue(it.hasNext());
        assertTrue(10 == it.next());
        assertTrue(it.hasNext());
        assertTrue(15 == it.next());
        assertFalse(it.hasNext());

        it.rewind();

        assertTrue(it.hasNext());
        assertTrue(5 == it.next());
        assertTrue(it.hasNext());
        assertTrue(10 == it.next());
        assertTrue(it.hasNext());
        assertTrue(15 == it.next());
        assertEquals(5, (int) observerList.mObservers.get(0));
        observerList.removeObserver(5);
        assertEquals(null, observerList.mObservers.get(0));

        it.rewind();

        assertEquals(10, (int) observerList.mObservers.get(0));
        assertTrue(it.hasNext());
        assertTrue(10 == it.next());
        assertTrue(it.hasNext());
        assertTrue(15 == it.next());
    }

    @SmallTest
    @Feature({"Android-AppBase"})
    public void testAddObserverReturnValue() {
        ObserverList<Object> observerList = new ObserverList<Object>();

        Object a = new Object();
        assertTrue(observerList.addObserver(a));
        assertFalse(observerList.addObserver(a));

        Object b = new Object();
        assertTrue(observerList.addObserver(b));
        assertFalse(observerList.addObserver(null));
    }

    @SmallTest
    @Feature({"Android-AppBase"})
    public void testRemoveObserverReturnValue() {
        ObserverList<Object> observerList = new ObserverList<Object>();

        Object a = new Object();
        Object b = new Object();
        observerList.addObserver(a);
        observerList.addObserver(b);

        assertTrue(observerList.removeObserver(a));
        assertFalse(observerList.removeObserver(a));
        assertFalse(observerList.removeObserver(new Object()));
        assertTrue(observerList.removeObserver(b));
        assertFalse(observerList.removeObserver(null));

        // If we remove an object while iterating, it will be replaced by 'null'.
        observerList.addObserver(a);
        assertTrue(observerList.removeObserver(a));
        assertFalse(observerList.removeObserver(null));
    }

    @SmallTest
    @Feature({"Android-AppBase"})
    public void testSize() {
        ObserverList<Object> observerList = new ObserverList<Object>();

        assertEquals(0, observerList.size());
        assertTrue(observerList.isEmpty());

        observerList.addObserver(null);
        assertEquals(0, observerList.size());
        assertTrue(observerList.isEmpty());

        Object a = new Object();
        observerList.addObserver(a);
        assertEquals(1, observerList.size());
        assertFalse(observerList.isEmpty());

        observerList.addObserver(a);
        assertEquals(1, observerList.size());
        assertFalse(observerList.isEmpty());

        observerList.addObserver(null);
        assertEquals(1, observerList.size());
        assertFalse(observerList.isEmpty());

        Object b = new Object();
        observerList.addObserver(b);
        assertEquals(2, observerList.size());
        assertFalse(observerList.isEmpty());

        observerList.removeObserver(null);
        assertEquals(2, observerList.size());
        assertFalse(observerList.isEmpty());

        observerList.removeObserver(new Object());
        assertEquals(2, observerList.size());
        assertFalse(observerList.isEmpty());

        observerList.removeObserver(b);
        assertEquals(1, observerList.size());
        assertFalse(observerList.isEmpty());

        observerList.removeObserver(b);
        assertEquals(1, observerList.size());
        assertFalse(observerList.isEmpty());

        observerList.removeObserver(a);
        assertEquals(0, observerList.size());
        assertTrue(observerList.isEmpty());

        observerList.removeObserver(a);
        observerList.removeObserver(b);
        observerList.removeObserver(null);
        observerList.removeObserver(new Object());
        assertEquals(0, observerList.size());
        assertTrue(observerList.isEmpty());

        observerList.addObserver(new Object());
        observerList.addObserver(new Object());
        observerList.addObserver(new Object());
        observerList.addObserver(a);
        assertEquals(4, observerList.size());
        assertFalse(observerList.isEmpty());

        observerList.clear();
        assertEquals(0, observerList.size());
        assertTrue(observerList.isEmpty());

        observerList.removeObserver(a);
        observerList.removeObserver(b);
        observerList.removeObserver(null);
        observerList.removeObserver(new Object());
        assertEquals(0, observerList.size());
        assertTrue(observerList.isEmpty());
    }
}
