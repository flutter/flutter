// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base.test.util;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * This annotation is for integration tests.
 * <p>
 * Examples of integration tests are tests that rely on real instances of the
 * application's services and components (e.g. Search) to test the system as
 * a whole. These tests may use additional command-line flags to configure the
 * existing backends to use.
 * <p>
 * Such tests are likely NOT reliable enough to run on tree closing bots and
 * should only be run on FYI bots.
 */
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
public @interface IntegrationTest {
}