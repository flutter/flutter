// Copyright 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base.annotations;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 *  @AccessedByNative is used to ensure proguard will keep this field, since it's
 *  only accessed by native.
 */
@Target(ElementType.FIELD)
@Retention(RetentionPolicy.CLASS)
public @interface AccessedByNative {
    public String value() default "";
}
