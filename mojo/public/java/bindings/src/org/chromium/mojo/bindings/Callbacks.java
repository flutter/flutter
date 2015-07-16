// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file was generated using
//     mojo/tools/generate_java_callback_interfaces.py

package org.chromium.mojo.bindings;

/**
 * Contains a generic interface for callbacks.
 */
public interface Callbacks {

    /**
     * A generic callback.
     */
    interface Callback0 {
        /**
         * Call the callback.
         */
        public void call();
    }

    /**
     * A generic 1-argument callback.
     *
     * @param <T1> the type of argument 1.
     */
    interface Callback1<T1> {
        /**
         * Call the callback.
         */
        public void call(T1 arg1);
    }

    /**
     * A generic 2-argument callback.
     *
     * @param <T1> the type of argument 1.
      * @param <T2> the type of argument 2.
     */
    interface Callback2<T1, T2> {
        /**
         * Call the callback.
         */
        public void call(T1 arg1, T2 arg2);
    }

    /**
     * A generic 3-argument callback.
     *
     * @param <T1> the type of argument 1.
      * @param <T2> the type of argument 2.
      * @param <T3> the type of argument 3.
     */
    interface Callback3<T1, T2, T3> {
        /**
         * Call the callback.
         */
        public void call(T1 arg1, T2 arg2, T3 arg3);
    }

    /**
     * A generic 4-argument callback.
     *
     * @param <T1> the type of argument 1.
      * @param <T2> the type of argument 2.
      * @param <T3> the type of argument 3.
      * @param <T4> the type of argument 4.
     */
    interface Callback4<T1, T2, T3, T4> {
        /**
         * Call the callback.
         */
        public void call(T1 arg1, T2 arg2, T3 arg3, T4 arg4);
    }

    /**
     * A generic 5-argument callback.
     *
     * @param <T1> the type of argument 1.
      * @param <T2> the type of argument 2.
      * @param <T3> the type of argument 3.
      * @param <T4> the type of argument 4.
      * @param <T5> the type of argument 5.
     */
    interface Callback5<T1, T2, T3, T4, T5> {
        /**
         * Call the callback.
         */
        public void call(T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5);
    }

    /**
     * A generic 6-argument callback.
     *
     * @param <T1> the type of argument 1.
      * @param <T2> the type of argument 2.
      * @param <T3> the type of argument 3.
      * @param <T4> the type of argument 4.
      * @param <T5> the type of argument 5.
      * @param <T6> the type of argument 6.
     */
    interface Callback6<T1, T2, T3, T4, T5, T6> {
        /**
         * Call the callback.
         */
        public void call(T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5, T6 arg6);
    }

    /**
     * A generic 7-argument callback.
     *
     * @param <T1> the type of argument 1.
      * @param <T2> the type of argument 2.
      * @param <T3> the type of argument 3.
      * @param <T4> the type of argument 4.
      * @param <T5> the type of argument 5.
      * @param <T6> the type of argument 6.
      * @param <T7> the type of argument 7.
     */
    interface Callback7<T1, T2, T3, T4, T5, T6, T7> {
        /**
         * Call the callback.
         */
        public void call(T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5, T6 arg6, T7 arg7);
    }

}
