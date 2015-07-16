// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base.annotations;

import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;

/**
 *  @SuppressFBWarnings is used to suppress FindBugs warnings.
 *
 *  The long name of FindBugs warnings can be found at
 *  http://findbugs.sourceforge.net/bugDescriptions.html
 */
@Retention(RetentionPolicy.CLASS)
public @interface SuppressFBWarnings {
    String[] value() default {};
    String justification() default "";
}
