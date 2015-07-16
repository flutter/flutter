// Copyright 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * @NativeClassQualifiedName is used by the JNI generator to create the necessary JNI
 * bindings to call into the specified native class name.
 */
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
public @interface NativeClassQualifiedName {
    /*
     * Tells which native class the method is going to be bound to.
     * The first parameter of the annotated method must be an int nativePtr pointing to
     * an instance of this class.
     */
    public String value();
}
