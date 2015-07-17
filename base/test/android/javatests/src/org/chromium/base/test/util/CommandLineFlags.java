// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base.test.util;

import android.content.Context;

import junit.framework.Assert;

import org.chromium.base.BaseChromiumApplication;
import org.chromium.base.CommandLine;

import java.lang.annotation.ElementType;
import java.lang.annotation.Inherited;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;
import java.lang.reflect.AnnotatedElement;
import java.lang.reflect.Method;
import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

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

    /**
     * Sets up the CommandLine with the appropriate flags.
     *
     * This will add the difference of the sets of flags specified by {@link CommandLineFlags.Add}
     * and {@link CommandLineFlags.Remove} to the {@link org.chromium.base.CommandLine}. Note that
     * trying to remove a flag set externally, i.e. by the command-line flags file, will not work.
     */
    public static void setUp(Context targetContext, AnnotatedElement element) {
        Assert.assertNotNull("Unable to get a non-null target context.", targetContext);
        CommandLine.reset();
        BaseChromiumApplication.initCommandLine(targetContext);
        Set<String> flags = getFlags(element);
        for (String flag : flags) {
            CommandLine.getInstance().appendSwitch(flag);
        }
    }

    private static Set<String> getFlags(AnnotatedElement element) {
        AnnotatedElement parent = (element instanceof Method)
                ? ((Method) element).getDeclaringClass()
                : ((Class) element).getSuperclass();
        Set<String> flags = (parent == null) ? new HashSet<String>() : getFlags(parent);

        if (element.isAnnotationPresent(CommandLineFlags.Add.class)) {
            flags.addAll(
                    Arrays.asList(element.getAnnotation(CommandLineFlags.Add.class).value()));
        }

        if (element.isAnnotationPresent(CommandLineFlags.Remove.class)) {
            List<String> flagsToRemove =
                    Arrays.asList(element.getAnnotation(CommandLineFlags.Remove.class).value());
            for (String flagToRemove : flagsToRemove) {
                // If your test fails here, you have tried to remove a command-line flag via
                // CommandLineFlags.Remove that was loaded into CommandLine via something other
                // than CommandLineFlags.Add (probably the command-line flag file).
                Assert.assertFalse("Unable to remove command-line flag \"" + flagToRemove + "\".",
                        CommandLine.getInstance().hasSwitch(flagToRemove));
            }
            flags.removeAll(flagsToRemove);
        }

        return flags;
    }

    private CommandLineFlags() {}
}
