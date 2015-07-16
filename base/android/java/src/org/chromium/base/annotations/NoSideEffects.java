// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base.annotations;

import java.lang.annotation.ElementType;
import java.lang.annotation.Target;

/**
 * Annotation used to indicate to proguard methods that have no side effects and can be
 * safely removed if their return value is not used. This is to be used with
 * {@link org.chromium.base.Log}'s method, that can also be removed by proguard. That way
 * expensive calls can be left in debug builds but removed in release.
 */
@Target({ElementType.METHOD, ElementType.CONSTRUCTOR})
public @interface NoSideEffects {}
