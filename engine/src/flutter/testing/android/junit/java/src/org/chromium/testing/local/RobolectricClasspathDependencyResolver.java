// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.testing.local;

import org.robolectric.DependencyJar;
import org.robolectric.DependencyResolver;

import java.io.File;
import java.net.MalformedURLException;
import java.net.URL;
import java.util.regex.Pattern;

/**
 * A Robolectric dependency resolver that looks for the Robolectric dependencies
 * in the Java classpath.
 */
public class RobolectricClasspathDependencyResolver implements DependencyResolver {
    private static final Pattern COLON = Pattern.compile(":");
    private final String[] mClassPathJars;

    /**
     * Creates a {@link ClasspathDependencyResolver}.
     */
    public RobolectricClasspathDependencyResolver() {
        mClassPathJars = COLON.split(System.getProperty("java.class.path"));
    }

    /**
     * Returns the {@link URL} for a Robolectric dependency. It looks through the jars
     * in the classpath to find the dependency's filepath.
     */
    @Override
    public URL getLocalArtifactUrl(DependencyJar dependency) {
        // Jar filenames are constructed identically to how they are built in Robolectric's
        // own LocalDependencyResolver.
        String dependencyJar = dependency.getArtifactId() + "-" + dependency.getVersion() + "."
                + dependency.getType();

        for (String jarPath : mClassPathJars) {
            if (jarPath.endsWith(dependencyJar)) {
                return fileToUrl(new File(jarPath));
            }
        }
        throw new IllegalStateException(
                String.format("Robolectric jar %s was not found in classpath.", dependencyJar));
    }

    /**
     * Returns the {@link URL} for a list of Robolectric dependencies.
     */
    @Override
    public URL[] getLocalArtifactUrls(DependencyJar... dependencies) {
        URL[] urls = new URL[dependencies.length];

        for (int i = 0; i < dependencies.length; i++) {
            urls[i] = getLocalArtifactUrl(dependencies[i]);
        }

        return urls;
    }

    private static URL fileToUrl(File file) {
        try {
            return file.toURI().toURL();
        } catch (MalformedURLException e) {
            throw new IllegalArgumentException(
                    String.format("File \"%s\" cannot be represented as a URL: %s", file, e));
        }
    }
}