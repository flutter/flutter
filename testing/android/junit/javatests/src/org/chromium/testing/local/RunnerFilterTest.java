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
import org.junit.runners.Suite;

/**
 *  Unit tests for RunnerFilter.
 */
@RunWith(BlockJUnit4ClassRunner.class)
public class RunnerFilterTest {

    private class FakeTestClass {}

    @Test
    public void testDescription() {
        Filter filterUnderTest = new RunnerFilter(BlockJUnit4ClassRunner.class);
        Assert.assertEquals("runner-filter: org.junit.runners.BlockJUnit4ClassRunner",
                filterUnderTest.describe());
    }

    @Test
    public void testNoFilter() {
        Filter filterUnderTest = new RunnerFilter(null);
        Assert.assertFalse(filterUnderTest.shouldRun(
                Description.createTestDescription(RunnerFilterTest.class, "testNoFilter")));
    }

    @Test
    public void testFilterHit() {
        Filter filterUnderTest = new RunnerFilter(BlockJUnit4ClassRunner.class);
        Assert.assertTrue(filterUnderTest.shouldRun(
                Description.createTestDescription(RunnerFilterTest.class, "testFilterHit")));
    }

    @Test
    public void testFilterMiss() {
        Filter filterUnderTest = new RunnerFilter(Suite.class);
        Assert.assertFalse(filterUnderTest.shouldRun(
                Description.createTestDescription(RunnerFilterTest.class, "testFilterMiss")));
    }

    @Test
    public void testClassNotFound() {
        Filter filterUnderTest = new RunnerFilter(BlockJUnit4ClassRunner.class);
        Assert.assertFalse(filterUnderTest.shouldRun(
                Description.createTestDescription(FakeTestClass.class, "fakeTestMethod")));
    }
}

