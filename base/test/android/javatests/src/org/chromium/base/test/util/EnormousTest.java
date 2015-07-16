// Copyright 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base.test.util;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * This annotation is for enormous tests.
 * <p>
 * Examples of enormous tests are tests that depend on external web sites or
 * tests that are long running.
 * <p>
 * Such tests are likely NOT reliable enough to run on tree closing bots and
 * should only be run on FYI bots.
 */
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
public @interface EnormousTest {
}
