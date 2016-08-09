// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.testing.local;

import org.junit.runners.model.InitializationError;

import org.robolectric.AndroidManifest;
import org.robolectric.DependencyResolver;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.SdkConfig;
import org.robolectric.annotation.Config;

/**
 * A custom Robolectric Junit4 Test Runner. This test runner will load the
 * "real" android jars from a local directory rather than use Maven to fetch
 * them from the Maven Central repository. Additionally, it will ignore the
 * API level written in the AndroidManifest as that can cause issues if
 * robolectric does not support that API level.
 */
public class LocalRobolectricTestRunner extends RobolectricTestRunner {

    private static final int ANDROID_API_LEVEL = 18;

    public LocalRobolectricTestRunner(Class<?> testClass) throws InitializationError {
        super(testClass);
    }

    @Override
    protected final DependencyResolver getJarResolver() {
        return new RobolectricClasspathDependencyResolver();
    }

    @Override
    protected SdkConfig pickSdkVersion(AndroidManifest appManifest, Config config) {
        // Pulling from the manifest is dangerous as the apk might target a version of
        // android that robolectric does not yet support. We still allow the API level to
        // be overridden with the Config annotation.
        return config.emulateSdk() < 0
                ? new SdkConfig(ANDROID_API_LEVEL) : super.pickSdkVersion(null, config);
    }

    @Override
    protected int pickReportedSdkVersion(Config config, AndroidManifest appManifest) {
        return config.reportSdk() < 0
                ? ANDROID_API_LEVEL : super.pickReportedSdkVersion(config, appManifest);
    }
}