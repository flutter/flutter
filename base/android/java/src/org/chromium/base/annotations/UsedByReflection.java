// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base.annotations;

import java.lang.annotation.ElementType;
import java.lang.annotation.Target;

/**
 * Annotation used for marking methods and fields that are called by reflection.
 * Useful for keeping components that would otherwise be removed by Proguard.
 * Use the value parameter to mention a file that calls this method.
 *
 * Note that adding this annotation to a method is not enough to guarantee that
 * it is kept - either its class must be referenced elsewhere in the program, or
 * the class must be annotated with this as well.
 */
@Target({
        ElementType.METHOD, ElementType.FIELD, ElementType.TYPE,
        ElementType.CONSTRUCTOR })
public @interface UsedByReflection {
    String value();
}
