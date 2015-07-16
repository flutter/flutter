// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base.test.util;

import java.lang.annotation.ElementType;
import java.lang.annotation.Inherited;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * Provides annotations related to command-line flag handling.
 *
 * Uses of these annotations on a derived class will take precedence over uses on its base classes,
 * so a derived class can add a command-line flag that a base class has removed (or vice versa).
 * Similarly, uses of these annotations on a test method will take precedence over uses on the
 * containing class.
 *
 * Note that this class should never be instantiated.
 */
public final class CommandLineFlags {

    /**
     * Adds command-line flags to the {@link org.chromium.base.CommandLine} for this test.
     */
    @Inherited
    @Retention(RetentionPolicy.RUNTIME)
    @Target({ElementType.METHOD, ElementType.TYPE})
    public @interface Add {
        String[] value();
    }

    /**
     * Removes command-line flags from the {@link org.chromium.base.CommandLine} from this test.
     *
     * Note that this can only remove flags added via {@link Add} above.
     */
    @Inherited
    @Retention(RetentionPolicy.RUNTIME)
    @Target({ElementType.METHOD, ElementType.TYPE})
    public @interface Remove {
        String[] value();
    }

    private CommandLineFlags() {}
}
