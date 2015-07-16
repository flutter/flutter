// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.testing.local;

import org.junit.Assert;
import org.junit.Test;
import org.junit.runner.Description;
import org.junit.runner.RunWith;
import org.junit.runner.manipulation.Filter;
import org.junit.runners.BlockJUnit4ClassRunner;

/**
 *  Unit tests for PackageFilter.
 */
@RunWith(BlockJUnit4ClassRunner.class)
public class PackageFilterTest {

    @Test
    public void testDescription() {
        Filter filterUnderTest = new PackageFilter("test.package");
        Assert.assertEquals("package-filter: test.package", filterUnderTest.describe());
    }

    @Test
    public void testNoFilter() {
        Filter filterUnderTest = new PackageFilter("");
        Assert.assertFalse(filterUnderTest.shouldRun(
                Description.createTestDescription(PackageFilterTest.class, "testNoFilter")));
    }

    @Test
    public void testFilterHit() {
        Filter filterUnderTest = new PackageFilter("org.chromium.testing.local");
        Assert.assertTrue(filterUnderTest.shouldRun(
                Description.createTestDescription(PackageFilterTest.class, "testWithFilter")));
    }

    @Test
    public void testFilterMiss() {
        Filter filterUnderTest = new PackageFilter("org.chromium.native_test");
        Assert.assertFalse(filterUnderTest.shouldRun(
                Description.createTestDescription(PackageFilterTest.class, "testWithFilter")));
    }

}
