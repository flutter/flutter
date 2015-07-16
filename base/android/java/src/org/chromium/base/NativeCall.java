// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * @NativeCall is used by the JNI generator to create the necessary JNI bindings
 * so a native function can be bound to a Java inner class. The native class for
 * which the JNI method will be generated is specified by the first parameter.
 */
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.CLASS)
public @interface NativeCall {
    /*
     * Value determines which native class the method should map to.
     */
    public String value() default "";
}
